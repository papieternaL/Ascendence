-- systems/audio.lua
-- Audio system for background music and sound effects.
-- Targets a medieval/fantasy adventure tone (early RuneScape OST inspiration).
-- Uses Kenney audio assets (royalty-free, CC0).

local Audio = {}
Audio.__index = Audio

-- Track configuration: maps logical names to file paths
Audio.tracks = {
  -- Gameplay music (atmospheric, looping)
  gameplay_mystic  = "assets/Audio/Music Loops/Retro/Retro Mystic.ogg",
  gameplay_flowing = "assets/Audio/Music Loops/Loops/Flowing Rocks.ogg",
  gameplay_descent = "assets/Audio/Music Loops/Loops/Infinite Descent.ogg",
  gameplay_stroll  = "assets/Audio/Music Loops/Loops/Mishief Stroll.ogg",

  -- Menu / ambient
  menu_sad_town    = "assets/Audio/Music Loops/Loops/Sad Town.ogg",
  menu_sad_descent = "assets/Audio/Music Loops/Loops/Sad Descent.ogg",

  -- Jingles
  game_over        = "assets/Audio/Music Loops/Loops/Game Over.ogg",
}

-- SFX configuration
Audio.sfx = {
  hit_light     = "assets/Audio/Impact Sounds/Audio/impactGeneric_light_000.ogg",
  hit_light_alt = "assets/Audio/Impact Sounds/Audio/impactGeneric_light_001.ogg",
  hit_heavy     = "assets/Audio/Impact Sounds/Audio/impactBell_heavy_000.ogg",
  draw_knife    = "assets/Audio/RPG Audio/Audio/drawKnife1.ogg",
  book_open     = "assets/Audio/RPG Audio/Audio/bookOpen.ogg",
  shoot_arrow   = "assets/2D assets/Desert Shooter Pack/Sounds/shoot-f.ogg",
  primary_shot  = "assets/2D assets/Desert Shooter Pack/Sounds/shoot-a.ogg",
  power_shot    = "assets/2D assets/Desert Shooter Pack/Sounds/shoot-g.ogg",
  arrow_volley  = "assets/2D assets/Desert Shooter Pack/Sounds/explosion-a.ogg",
  frenzy        = "assets/Audio/Impact Sounds/Audio/impactBell_heavy_000.ogg",
  dash          = "assets/2D assets/Desert Shooter Pack/Sounds/jump-a.ogg",
  portal_open   = "assets/Audio/RPG Audio/Audio/doorOpen_1.ogg",
}

function Audio:new()
  local a = setmetatable({
    musicVolume = 0.35,
    sfxVolume = 0.5,
    currentMusic = nil,
    currentTrackName = nil,
    loadedSources = {},  -- cache of loaded Source objects
    fadeTarget = nil,
    fadeSpeed = 0,
    muted = false,
  }, Audio)
  return a
end

-- Load and cache a source (stream for music, static for sfx)
function Audio:loadSource(path, sourceType)
  if self.loadedSources[path] then
    return self.loadedSources[path]
  end

  local success, source = pcall(love.audio.newSource, path, sourceType or "stream")
  if success and source then
    self.loadedSources[path] = source
    return source
  end

  return nil
end

-- Play a music track by logical name (loops by default)
function Audio:playMusic(trackName, options)
  options = options or {}
  local path = Audio.tracks[trackName]
  if not path then return end

  -- Don't restart the same track
  if self.currentTrackName == trackName and self.currentMusic and self.currentMusic:isPlaying() then
    return
  end

  -- Stop current music
  if self.currentMusic then
    self.currentMusic:stop()
  end

  local source = self:loadSource(path, "stream")
  if not source then return end

  source:setLooping(options.loop ~= false)  -- loop by default
  source:setVolume(self.muted and 0 or (options.volume or self.musicVolume))
  source:play()

  self.currentMusic = source
  self.currentTrackName = trackName
end

-- Stop current music
function Audio:stopMusic()
  if self.currentMusic then
    self.currentMusic:stop()
    self.currentMusic = nil
    self.currentTrackName = nil
  end
end

-- Fade music volume over time (call in update loop)
function Audio:fadeOut(duration)
  if self.currentMusic then
    self.fadeTarget = 0
    self.fadeSpeed = self.currentMusic:getVolume() / math.max(duration, 0.01)
  end
end

function Audio:fadeIn(trackName, duration, options)
  options = options or {}
  self:playMusic(trackName, { volume = 0, loop = options.loop })
  if self.currentMusic then
    self.fadeTarget = options.volume or self.musicVolume
    self.fadeSpeed = self.fadeTarget / math.max(duration, 0.01)
  end
end

-- Play a one-shot SFX by logical name
function Audio:playSFX(sfxName, options)
  options = options or {}
  local path = Audio.sfx[sfxName]
  if not path then return end

  -- For SFX we clone to allow overlapping plays
  local source = self:loadSource(path, "static")
  if not source then return end

  local clone = source:clone()
  clone:setVolume(self.muted and 0 or (options.volume or self.sfxVolume))
  if options.pitch then
    clone:setPitch(options.pitch)
  end
  clone:play()
end

-- Set master music volume
function Audio:setMusicVolume(vol)
  self.musicVolume = math.max(0, math.min(1, vol))
  if self.currentMusic and not self.muted then
    self.currentMusic:setVolume(self.musicVolume)
  end
end

-- Set master SFX volume
function Audio:setSFXVolume(vol)
  self.sfxVolume = math.max(0, math.min(1, vol))
end

-- Toggle mute
function Audio:toggleMute()
  self.muted = not self.muted
  if self.currentMusic then
    self.currentMusic:setVolume(self.muted and 0 or self.musicVolume)
  end
end

-- Update (handles fading)
function Audio:update(dt)
  if self.fadeTarget ~= nil and self.currentMusic then
    local currentVol = self.currentMusic:getVolume()
    if self.fadeTarget > currentVol then
      currentVol = math.min(self.fadeTarget, currentVol + self.fadeSpeed * dt)
    else
      currentVol = math.max(self.fadeTarget, currentVol - self.fadeSpeed * dt)
    end
    self.currentMusic:setVolume(self.muted and 0 or currentVol)

    if math.abs(currentVol - self.fadeTarget) < 0.01 then
      if self.fadeTarget <= 0 then
        self.currentMusic:stop()
        self.currentMusic = nil
        self.currentTrackName = nil
      end
      self.fadeTarget = nil
    end
  end
end

-- Pick a random gameplay track and play it
function Audio:playGameplayMusic()
  local tracks = { "gameplay_mystic", "gameplay_flowing", "gameplay_descent", "gameplay_stroll" }
  local pick = tracks[math.random(#tracks)]
  self:fadeIn(pick, 2.0)
end

-- Play menu music
function Audio:playMenuMusic()
  self:fadeIn("menu_sad_town", 1.5)
end

-- Play game over jingle
function Audio:playGameOverMusic()
  self:playMusic("game_over", { loop = false, volume = self.musicVolume * 0.8 })
end

-- Play boss fight music (more intense track)
function Audio:playBossMusic()
  self:fadeIn("gameplay_descent", 1.5)
end

return Audio
