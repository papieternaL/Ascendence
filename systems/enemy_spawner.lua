-- systems/enemy_spawner.lua
-- Continuous enemy spawning system

local Config = require("data.config")
local cfg = Config.enemy_spawner or {}

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

function EnemySpawner:new(game_scene)
  local spawner = {
    game_scene = game_scene,
    spawn_timer = 0,
    base_spawn_interval = cfg.base_spawn_interval or 1.8,
    current_enemy_count = 0,
    max_enemies = cfg.max_enemies or 80,
    min_enemies = cfg.min_enemies or 18,
    min_enemies_start = cfg.min_enemies_start or 4,
    min_enemies_max = cfg.min_enemies_max or 24,
    min_enemies_ramp_seconds = cfg.min_enemies_ramp_seconds or 120,
    time_alive = 0,
    difficulty_multiplier = 1.0,
    difficulty_scale_rate = cfg.difficulty_scale_rate or 0.008,
    
    enemy_weights = {
      slime = 10,
      bat = 6,
      skeleton = 5,
      imp = 4,
      wolf = 4,
      lunger = 1.5,
      small_treent = 1.5,
      wizard = 1.0,
      treent = 0.5
    },
    
    map_width = 2000,
    map_height = 2000,
    spawn_margin = cfg.spawn_margin or 250,  -- Off-screen; enemies always move toward player
    
    active = true,
    paused = false
  }
  setmetatable(spawner, EnemySpawner)
  return spawner
end

function EnemySpawner:update(dt)
  if not self.active or self.paused then return end
  
  -- #region agent log
  local logfile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
  if logfile then
    logfile:write(string.format('{"sessionId":"debug-session","runId":"spawn-debug","hypothesisId":"H1","location":"enemy_spawner.lua:update","message":"Spawner update tick","data":{"current_enemy_count":%d,"max_enemies":%d,"min_enemies":%d,"spawn_timer":%.2f},"timestamp":%d}\n', self.current_enemy_count, self.max_enemies, self.min_enemies, self.spawn_timer, os.time() * 1000))
    logfile:close()
  end
  -- #endregion
  
  self.time_alive = self.time_alive + dt
  self.difficulty_multiplier = 1.0 + (self.time_alive * self.difficulty_scale_rate)
  
  -- Steady increase: effective min ramps from start to max over ramp_seconds
  local ramp_t = math.min(1, self.time_alive / self.min_enemies_ramp_seconds)
  local effective_min = self.min_enemies_start + (self.min_enemies_max - self.min_enemies_start) * ramp_t
  
  self.spawn_timer = self.spawn_timer + dt
  local scaled_interval = self.base_spawn_interval / math.min(self.difficulty_multiplier, 2.5)
  
  if self.spawn_timer >= scaled_interval then
    self.spawn_timer = 0
    if self.current_enemy_count < self.max_enemies then
      -- #region agent log
      local logfile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
      if logfile then
        logfile:write(string.format('{"sessionId":"debug-session","runId":"spawn-debug","hypothesisId":"H1","location":"enemy_spawner.lua:spawnBatch","message":"Attempting spawn batch","data":{"current_enemy_count":%d,"max_enemies":%d},"timestamp":%d}\n', self.current_enemy_count, self.max_enemies, os.time() * 1000))
        logfile:close()
      end
      -- #endregion
      self:spawnBatch()
    end
  end
  
  if self.current_enemy_count < effective_min then
    -- #region agent log
    local logfile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
    if logfile then
      logfile:write(string.format('{"sessionId":"debug-session","runId":"spawn-debug","hypothesisId":"H2","location":"enemy_spawner.lua:minEnemies","message":"Below min enemies, forcing spawn","data":{"current_enemy_count":%d,"effective_min":%d},"timestamp":%d}\n', self.current_enemy_count, math.floor(effective_min), os.time() * 1000))
      logfile:close()
    end
    -- #endregion
    self:spawnBatch()
  end
end

function EnemySpawner:spawnBatch()
  local base_batch_size = math.random(2, 4)
  local scaled_batch_size = math.floor(base_batch_size * math.min(self.difficulty_multiplier, 2.0))
  local batch_size = math.min(scaled_batch_size, self.max_enemies - self.current_enemy_count)
  
  -- #region agent log
  local logfile = io.open("c:\\Users\\steven\\Desktop\\Cursor\\Shooter\\.cursor\\debug.log", "a")
  if logfile then
    logfile:write(string.format('{"sessionId":"debug-session","runId":"spawn-debug","hypothesisId":"H1","location":"enemy_spawner.lua:spawnBatch","message":"Spawning batch","data":{"batch_size":%d,"base_batch_size":%d,"current_count":%d},"timestamp":%d}\n', batch_size, base_batch_size, self.current_enemy_count, os.time() * 1000))
    logfile:close()
  end
  -- #endregion
  
  for i = 1, batch_size do
    local enemy_type = self:selectEnemyType()
    local x, y = self:getRandomSpawnPosition()
    self:spawnEnemy(enemy_type, x, y)
  end
end

function EnemySpawner:selectEnemyType()
  local adjusted_weights = {}
  
  for enemy_type, base_weight in pairs(self.enemy_weights) do
    local weight = base_weight
    
    if enemy_type == "lunger" or enemy_type == "small_treent" or enemy_type == "wizard" then
      weight = weight * (1.0 + self.difficulty_multiplier * 0.3)
    end
    if enemy_type == "treent" then
      weight = weight * (1.0 + self.difficulty_multiplier * 0.5)
    end
    
    adjusted_weights[enemy_type] = weight
  end
  
  return self:weightedRandom(adjusted_weights)
end

function EnemySpawner:weightedRandom(weights)
  local total_weight = 0
  for _, weight in pairs(weights) do
    total_weight = total_weight + weight
  end
  
  local random = math.random() * total_weight
  local cumulative = 0
  
  for enemy_type, weight in pairs(weights) do
    cumulative = cumulative + weight
    if random <= cumulative then
      return enemy_type
    end
  end
  
  return "slime"
end

function EnemySpawner:getRandomSpawnPosition()
  local player = self.game_scene.player
  local camera = self.game_scene.camera
  
  local cam_left = camera.x - love.graphics.getWidth() / 2
  local cam_right = camera.x + love.graphics.getWidth() / 2
  local cam_top = camera.y - love.graphics.getHeight() / 2
  local cam_bottom = camera.y + love.graphics.getHeight() / 2
  
  local side = math.random(1, 4)
  local x, y
  
  if side == 1 then
    x = math.random(cam_left - self.spawn_margin, cam_right + self.spawn_margin)
    y = cam_top - self.spawn_margin
  elseif side == 2 then
    x = cam_right + self.spawn_margin
    y = math.random(cam_top - self.spawn_margin, cam_bottom + self.spawn_margin)
  elseif side == 3 then
    x = math.random(cam_left - self.spawn_margin, cam_right + self.spawn_margin)
    y = cam_bottom + self.spawn_margin
  else
    x = cam_left - self.spawn_margin
    y = math.random(cam_top - self.spawn_margin, cam_bottom + self.spawn_margin)
  end
  
  x = math.max(0, math.min(x, self.map_width))
  y = math.max(0, math.min(y, self.map_height))
  
  return x, y
end

function EnemySpawner:spawnEnemy(enemy_type, x, y)
  if self.game_scene.spawnEnemy then
    self.game_scene:spawnEnemy(enemy_type, x, y)
    self.current_enemy_count = self.current_enemy_count + 1
  end
end

function EnemySpawner:onEnemyDeath()
  self.current_enemy_count = math.max(0, self.current_enemy_count - 1)
end

function EnemySpawner:stop()
  self.active = false
end

function EnemySpawner:pause()
  self.paused = true
end

function EnemySpawner:resume()
  self.paused = false
end

return EnemySpawner
