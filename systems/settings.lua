-- systems/settings.lua
-- Persistent user settings (audio + graphics).

local Settings = {}
Settings.__index = Settings

local SETTINGS_FILE = "settings.lua"

local DEFAULTS = {
    audio = {
        musicVolume = 0.35,
        sfxVolume = 0.50,
    },
    graphics = {
        screenShake = 1.0, -- 0..1 multiplier
    },
}

local function clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function deepCopy(src)
    local out = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            out[k] = deepCopy(v)
        else
            out[k] = v
        end
    end
    return out
end

local function serializeTable(t, indent)
    indent = indent or 0
    local pad = string.rep(" ", indent)
    local lines = {"{"}
    for k, v in pairs(t) do
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            key = k
        else
            key = "[" .. string.format("%q", tostring(k)) .. "]"
        end

        local value
        if type(v) == "table" then
            value = serializeTable(v, indent + 2)
        elseif type(v) == "string" then
            value = string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            value = tostring(v)
        else
            value = "nil"
        end
        table.insert(lines, string.format("%s  %s = %s,", pad, key, value))
    end
    table.insert(lines, pad .. "}")
    return table.concat(lines, "\n")
end

function Settings:new()
    local s = {
        values = deepCopy(DEFAULTS),
        audioRef = nil,
    }
    setmetatable(s, Settings)
    return s
end

function Settings:get()
    return self.values
end

function Settings:setAudio(audio)
    self.audioRef = audio
    self:apply()
end

function Settings:apply()
    if self.audioRef then
        self.audioRef:setMusicVolume(self.values.audio.musicVolume or DEFAULTS.audio.musicVolume)
        self.audioRef:setSFXVolume(self.values.audio.sfxVolume or DEFAULTS.audio.sfxVolume)
    end
    _G.GameSettings = self.values
end

function Settings:load()
    if not love.filesystem.getInfo(SETTINGS_FILE) then
        self:apply()
        return
    end

    local okLoad, chunk = pcall(love.filesystem.load, SETTINGS_FILE)
    if not okLoad or not chunk then
        self:apply()
        return
    end

    local okRun, loaded = pcall(chunk)
    if okRun and type(loaded) == "table" then
        self.values.audio.musicVolume = clamp(tonumber(loaded.audio and loaded.audio.musicVolume) or self.values.audio.musicVolume, 0, 1)
        self.values.audio.sfxVolume = clamp(tonumber(loaded.audio and loaded.audio.sfxVolume) or self.values.audio.sfxVolume, 0, 1)
        self.values.graphics.screenShake = clamp(tonumber(loaded.graphics and loaded.graphics.screenShake) or self.values.graphics.screenShake, 0, 1)
    end

    self:apply()
end

function Settings:save()
    local text = "return " .. serializeTable(self.values) .. "\n"
    love.filesystem.write(SETTINGS_FILE, text)
end

function Settings:setMusicVolume(v)
    self.values.audio.musicVolume = clamp(v, 0, 1)
    self:apply()
    self:save()
end

function Settings:setSFXVolume(v)
    self.values.audio.sfxVolume = clamp(v, 0, 1)
    self:apply()
    self:save()
end

function Settings:setScreenShake(v)
    self.values.graphics.screenShake = clamp(v, 0, 1)
    self:apply()
    self:save()
end

return Settings
