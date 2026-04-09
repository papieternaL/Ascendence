# SpriteCook HTTP Helper

This repo includes a small HTTP-based SpriteCook MCP helper so we can bypass the flaky in-session MCP bridge and still call SpriteCook directly.

It reads the remote SpriteCook config from `C:\Users\steven\.cursor\mcp.json` by default and opens a fresh MCP session for each command.

## Commands

```powershell
node scripts/spritecook_http.mjs tools
node scripts/spritecook_http.mjs balance
node scripts/spritecook_http.mjs call get_credit_balance
node scripts/spritecook_http.mjs call generate_game_art "{\"prompt\":\"top-down mana potion\",\"width\":64,\"height\":64}"
```

You can also pass tool arguments from a JSON file:

```powershell
node scripts/spritecook_http.mjs call generate_game_art @spritecook_request.json
```

## Optional overrides

- `SPRITECOOK_API_KEY`: API key without the `Bearer ` prefix
- `SPRITECOOK_AUTH_HEADER`: full `Authorization` header value
- `SPRITECOOK_MCP_URL`: override the MCP URL
- `CURSOR_MCP_CONFIG`: override the Cursor MCP config path

## Notes

- `tools` lists the current tool schemas exposed by SpriteCook.
- `balance` is a safe read-only verification call.
- `call generate_game_art ...` and `call animate_game_art ...` can spend credits.
