#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const DEFAULT_CONFIG_PATH = path.join(os.homedir(), ".cursor", "mcp.json");
const DEFAULT_PROTOCOL_VERSION = "2025-03-26";

function printUsage() {
  console.log(`SpriteCook MCP HTTP helper

Usage:
  node scripts/spritecook_http.mjs tools
  node scripts/spritecook_http.mjs balance
  node scripts/spritecook_http.mjs call <tool_name> [json_args_or_@file]
  node scripts/spritecook_http.mjs raw <method> [json_params_or_@file]

Examples:
  node scripts/spritecook_http.mjs tools
  node scripts/spritecook_http.mjs balance
  node scripts/spritecook_http.mjs call get_credit_balance
  node scripts/spritecook_http.mjs call generate_game_art "{\"prompt\":\"top-down health potion\",\"width\":64,\"height\":64}"
  node scripts/spritecook_http.mjs call generate_game_art @spritecook_request.json

Optional env:
  SPRITECOOK_API_KEY      API key without Bearer prefix
  SPRITECOOK_AUTH_HEADER  Full Authorization header value
  SPRITECOOK_MCP_URL      Override MCP URL
  CURSOR_MCP_CONFIG       Override Cursor MCP config path
`);
}

function fail(message, details = null) {
  console.error(message);
  if (details) {
    console.error(details);
  }
  process.exit(1);
}

function parseOptions(argv) {
  const options = {
    configPath: process.env.CURSOR_MCP_CONFIG || DEFAULT_CONFIG_PATH,
    url: process.env.SPRITECOOK_MCP_URL || null,
    authHeader: process.env.SPRITECOOK_AUTH_HEADER || null,
  };
  const args = [];

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === "--config") {
      index += 1;
      options.configPath = argv[index] || fail("Missing value for --config.");
      continue;
    }
    if (token === "--url") {
      index += 1;
      options.url = argv[index] || fail("Missing value for --url.");
      continue;
    }
    if (token === "--auth") {
      index += 1;
      options.authHeader = argv[index] || fail("Missing value for --auth.");
      continue;
    }
    args.push(token);
  }

  return { options, args };
}

function readJsonFile(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    fail(`Failed to read JSON from ${filePath}.`, error.message);
  }
}

function loadSpriteCookConfig(configPath) {
  const config = readJsonFile(configPath);
  const server = config?.mcpServers?.spritecook;
  if (!server) {
    fail(`No spritecook entry found in ${configPath}.`);
  }
  return server;
}

function resolveAuthHeader(options) {
  if (options.authHeader) {
    return options.authHeader;
  }

  if (process.env.SPRITECOOK_API_KEY) {
    const apiKey = process.env.SPRITECOOK_API_KEY.trim();
    return apiKey.startsWith("Bearer ") ? apiKey : `Bearer ${apiKey}`;
  }

  const server = loadSpriteCookConfig(options.configPath);
  const header = server?.headers?.Authorization;
  if (!header) {
    fail(
      `No Authorization header found for spritecook in ${options.configPath}. ` +
        "Set SPRITECOOK_API_KEY or SPRITECOOK_AUTH_HEADER to override.",
    );
  }
  return header;
}

function resolveUrl(options) {
  if (options.url) {
    return options.url;
  }

  const server = loadSpriteCookConfig(options.configPath);
  if (!server.url) {
    fail(
      `The spritecook entry in ${options.configPath} is not using the remote HTTP form. ` +
        "Set SPRITECOOK_MCP_URL or update the config to the HTTP route.",
    );
  }
  return server.url;
}

function loadJsonArg(value, emptyFallback = {}) {
  if (!value) {
    return emptyFallback;
  }

  if (value.startsWith("@")) {
    const filePath = path.resolve(process.cwd(), value.slice(1));
    return readJsonFile(filePath);
  }

  try {
    return JSON.parse(value);
  } catch (error) {
    fail(
      `Failed to parse JSON argument: ${value}`,
      "Pass inline JSON or @path/to/file.json.",
    );
  }
}

function parseEventStreamBody(bodyText) {
  const trimmed = bodyText.trim();
  if (!trimmed) {
    return [];
  }

  if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
    return [JSON.parse(trimmed)];
  }

  const events = [];
  let dataLines = [];
  for (const line of bodyText.split(/\r?\n/)) {
    if (line.startsWith("data:")) {
      dataLines.push(line.slice(5).trimStart());
      continue;
    }
    if (line.trim() === "" && dataLines.length > 0) {
      events.push(JSON.parse(dataLines.join("\n")));
      dataLines = [];
    }
  }

  if (dataLines.length > 0) {
    events.push(JSON.parse(dataLines.join("\n")));
  }

  return events;
}

function findPrimaryMessage(messages, id = null) {
  if (messages.length === 0) {
    return null;
  }
  if (id === null) {
    return messages[messages.length - 1];
  }
  return (
    messages.find((message) => message && typeof message === "object" && message.id === id) ||
    messages[messages.length - 1]
  );
}

async function postMcpRequest({ url, authHeader, sessionId, body }) {
  const headers = {
    Authorization: authHeader,
    Accept: "application/json, text/event-stream",
    "Content-Type": "application/json",
  };
  if (sessionId) {
    headers["mcp-session-id"] = sessionId;
  }

  const response = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });

  const responseText = await response.text();
  if (!response.ok) {
    fail(
      `SpriteCook MCP request failed with HTTP ${response.status}.`,
      responseText || response.statusText,
    );
  }

  let messages = [];
  try {
    messages = parseEventStreamBody(responseText);
  } catch (error) {
    fail("Failed to parse SpriteCook MCP response.", responseText);
  }

  return {
    sessionId: response.headers.get("mcp-session-id") || sessionId,
    messages,
    raw: responseText,
  };
}

async function createSession(url, authHeader) {
  const initializeBody = {
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {
      protocolVersion: DEFAULT_PROTOCOL_VERSION,
      capabilities: {},
      clientInfo: {
        name: "spritecook-http-helper",
        version: "1.0.0",
      },
    },
  };

  const initializeResponse = await postMcpRequest({
    url,
    authHeader,
    body: initializeBody,
  });

  const initializeMessage = findPrimaryMessage(initializeResponse.messages, 1);
  if (!initializeMessage?.result) {
    fail("SpriteCook MCP initialize did not return a result.", initializeResponse.raw);
  }

  const sessionId = initializeResponse.sessionId;
  if (!sessionId) {
    fail("SpriteCook MCP did not return an mcp-session-id header.");
  }

  await postMcpRequest({
    url,
    authHeader,
    sessionId,
    body: {
      jsonrpc: "2.0",
      method: "notifications/initialized",
      params: {},
    },
  });

  return {
    sessionId,
    serverInfo: initializeMessage.result.serverInfo || null,
  };
}

async function run() {
  const { options, args } = parseOptions(process.argv.slice(2));
  const command = args[0];

  if (!command || command === "help" || command === "--help" || command === "-h") {
    printUsage();
    return;
  }

  const authHeader = resolveAuthHeader(options);
  const url = resolveUrl(options);
  const { sessionId, serverInfo } = await createSession(url, authHeader);

  if (command === "tools") {
    const response = await postMcpRequest({
      url,
      authHeader,
      sessionId,
      body: {
        jsonrpc: "2.0",
        id: 2,
        method: "tools/list",
        params: {},
      },
    });

    const message = findPrimaryMessage(response.messages, 2);
    const tools = message?.result?.tools || [];
    console.log(
      JSON.stringify(
        {
          server: serverInfo,
          tools,
        },
        null,
        2,
      ),
    );
    return;
  }

  if (command === "balance") {
    const response = await postMcpRequest({
      url,
      authHeader,
      sessionId,
      body: {
        jsonrpc: "2.0",
        id: 3,
        method: "tools/call",
        params: {
          name: "get_credit_balance",
          arguments: {},
        },
      },
    });

    const message = findPrimaryMessage(response.messages, 3);
    console.log(JSON.stringify(message?.result || message, null, 2));
    return;
  }

  if (command === "call") {
    const toolName = args[1];
    if (!toolName) {
      fail("Missing tool name. Usage: call <tool_name> [json_args_or_@file]");
    }

    const toolArgs = loadJsonArg(args[2], {});
    const response = await postMcpRequest({
      url,
      authHeader,
      sessionId,
      body: {
        jsonrpc: "2.0",
        id: 4,
        method: "tools/call",
        params: {
          name: toolName,
          arguments: toolArgs,
        },
      },
    });

    const message = findPrimaryMessage(response.messages, 4);
    console.log(JSON.stringify(message?.result || message, null, 2));
    return;
  }

  if (command === "raw") {
    const method = args[1];
    if (!method) {
      fail("Missing MCP method. Usage: raw <method> [json_params_or_@file]");
    }

    const params = loadJsonArg(args[2], {});
    const response = await postMcpRequest({
      url,
      authHeader,
      sessionId,
      body: {
        jsonrpc: "2.0",
        id: 5,
        method,
        params,
      },
    });

    const message = findPrimaryMessage(response.messages, 5);
    console.log(JSON.stringify(message?.result || message, null, 2));
    return;
  }

  fail(`Unknown command: ${command}`);
}

run().catch((error) => {
  fail("SpriteCook helper failed unexpectedly.", error?.stack || error?.message || String(error));
});
