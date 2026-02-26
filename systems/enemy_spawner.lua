-- systems/enemy_spawner.lua
-- Continuous enemy spawning system

local Config = require("data.config")
local cfg = Config.enemy_spawner or {}
local density_mult = cfg.density_multiplier or 1.0
local global_spawn_rate_mult = cfg.global_spawn_rate_mult or 0.85

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

function EnemySpawner:new(game_scene)
  local spawner = {
    game_scene = game_scene,
    spawn_timer = 0,
    base_spawn_interval = (cfg.base_spawn_interval or 1.8) / density_mult,
    current_enemy_count = 0,
    max_enemies = math.floor((cfg.max_enemies or 80) * density_mult),
    min_enemies = math.floor((cfg.min_enemies or 18) * density_mult),
    min_enemies_start = math.max(1, math.floor((cfg.min_enemies_start or 4) * density_mult)),
    min_enemies_max = math.max(1, math.floor((cfg.min_enemies_max or 24) * density_mult)),
    min_enemies_ramp_seconds = cfg.min_enemies_ramp_seconds or 120,
    late_wave_reduction = cfg.late_wave_reduction or 0.25,
    late_wave_start_seconds = cfg.late_wave_start_seconds or 120,
    late_wave_ramp_seconds = cfg.late_wave_ramp_seconds or 90,
    time_alive = 0,
    difficulty_multiplier = 1.0,
    difficulty_scale_rate = cfg.difficulty_scale_rate or 0.008,
    
    enemy_weights = {
      slime = 10,
      bat = 6,
      skeleton = 5,
      wolf = 4,
      small_treent = 1.5,
      wizard = 1.0,
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

function EnemySpawner:getLateWaveDensityMultiplier()
  local start_sec = self.late_wave_start_seconds or 120
  local ramp_sec = math.max(1, self.late_wave_ramp_seconds or 90)
  local reduction = math.max(0, math.min(0.9, self.late_wave_reduction or 0.25))
  if self.time_alive <= start_sec then
    return 1.0
  end
  local t = math.min(1, (self.time_alive - start_sec) / ramp_sec)
  return 1.0 - (reduction * t)
end

function EnemySpawner:update(dt)
  if not self.active or self.paused then return end
  
  self.time_alive = self.time_alive + dt
  self.difficulty_multiplier = 1.0 + (self.time_alive * self.difficulty_scale_rate)
  
  -- Steady increase: effective min ramps from start to max over ramp_seconds
  local ramp_t = math.min(1, self.time_alive / self.min_enemies_ramp_seconds)
  local late_wave_mult = self:getLateWaveDensityMultiplier()
  local effective_min = (self.min_enemies_start + (self.min_enemies_max - self.min_enemies_start) * ramp_t) * late_wave_mult
  local effective_max = math.max(1, math.floor(self.max_enemies * late_wave_mult))
  
  self.spawn_timer = self.spawn_timer + dt
  local scaled_interval = (self.base_spawn_interval / math.min(self.difficulty_multiplier, 2.5)) / global_spawn_rate_mult

  if self.spawn_timer >= scaled_interval then
    self.spawn_timer = 0
    if self.current_enemy_count < effective_max then
      self:spawnBatch(effective_max)
    end
  end
  
  if self.current_enemy_count < effective_min then
    self:spawnBatch(effective_max)
  end
end

function EnemySpawner:spawnBatch(max_enemies_override)
  local base_batch_size = math.random(2, 4)
  local late_wave_mult = self:getLateWaveDensityMultiplier()
  local scaled_batch_size = math.floor(base_batch_size * math.min(self.difficulty_multiplier, 2.0) * density_mult * late_wave_mult)
  scaled_batch_size = math.max(1, scaled_batch_size)
  local max_enemies_cap = max_enemies_override or self.max_enemies
  local batch_size = math.min(scaled_batch_size, max_enemies_cap - self.current_enemy_count)
  if batch_size <= 0 then return end
  
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
    
    if enemy_type == "small_treent" or enemy_type == "wizard" then
      weight = weight * (1.0 + self.difficulty_multiplier * 0.3)
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

function EnemySpawner:syncCountFromScene()
  local count = 0
  if self.game_scene.getAllEnemyLists then
    for _, list in ipairs(self.game_scene:getAllEnemyLists()) do
      for _, e in ipairs(list) do
        if e.isAlive then count = count + 1 end
      end
    end
  end
  self.current_enemy_count = count
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
