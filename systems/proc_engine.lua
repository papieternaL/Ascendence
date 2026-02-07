-- systems/proc_engine.lua
-- Evaluates proc triggers from upgrade data and returns actions for the combat loop.

local StatusEffects = require("systems.status_effects")

local ProcEngine = {}
ProcEngine.__index = ProcEngine

function ProcEngine:new()
  local pe = {
    primaryShotCount = 0,
    continuousFiringTime = 0,
    noDamageTakenTime = 0,
    isFiring = false,
  }
  setmetatable(pe, ProcEngine)
  return pe
end

-- Get the proc list from playerStats
local function getProcs(playerStats)
  if not playerStats or not playerStats.weaponMods then return {} end
  return playerStats.weaponMods.procs or {}
end

---------------------------------------------------------------------------
-- EVENT TRIGGERS (called once when the event happens)
---------------------------------------------------------------------------

-- Called when a primary shot is fired. Returns actions for every_n_primary_shots.
function ProcEngine:onPrimaryFired(playerStats)
  self.primaryShotCount = self.primaryShotCount + 1
  self.isFiring = true
  local actions = {}
  for _, proc in ipairs(getProcs(playerStats)) do
    if proc.trigger == "every_n_primary_shots" then
      if self.primaryShotCount % (proc.n or 5) == 0 then
        actions[#actions + 1] = { apply = proc.apply }
      end
    end
  end
  return actions
end

-- Called when an arrow hits an enemy (before kill check).
-- context: { isCrit, target, arrow, playerX, playerY, maxRange }
function ProcEngine:onHit(playerStats, context)
  local actions = {}
  for _, proc in ipairs(getProcs(playerStats)) do
    -- on_primary_hit: fires on any primary arrow hit
    if proc.trigger == "on_primary_hit" and context.arrow and context.arrow.kind == "primary" then
      local chance = proc.chance or 1.0
      if love.math.random() <= chance then
        actions[#actions + 1] = { apply = proc.apply, target = context.target }
      end
    end

    -- on_crit_hit: fires when a crit lands
    if proc.trigger == "on_crit_hit" and context.isCrit then
      local chance = proc.chance or 1.0
      if love.math.random() <= chance then
        actions[#actions + 1] = { apply = proc.apply, target = context.target }
      end
    end

    -- while_target_has_status: conditional damage boost per-hit
    if proc.trigger == "while_target_has_status" then
      if context.target and context.target.statuses and context.target.statuses[proc.status] then
        actions[#actions + 1] = { apply = proc.apply, target = context.target, conditional = true }
      end
    end

    -- while_target_beyond_range_pct: conditional damage boost per-hit
    if proc.trigger == "while_target_beyond_range_pct" then
      if context.target and context.maxRange then
        local tx, ty = context.target:getPosition()
        local dx = tx - context.playerX
        local dy = ty - context.playerY
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > context.maxRange * (proc.pct or 0.55) then
          actions[#actions + 1] = { apply = proc.apply, target = context.target, conditional = true }
        end
      end
    end
  end
  return actions
end

-- Called when an enemy is killed.
-- context: { isCrit, target }
function ProcEngine:onKill(playerStats, context)
  local actions = {}
  for _, proc in ipairs(getProcs(playerStats)) do
    if proc.trigger == "on_crit_kill" and context.isCrit then
      local chance = proc.chance or 1.0
      if love.math.random() <= chance then
        actions[#actions + 1] = { apply = proc.apply, target = context.target }
      end
    end

    if proc.trigger == "on_kill_target_with_status" then
      if context.target and context.target.statuses and context.target.statuses[proc.status] then
        local chance = proc.chance or 1.0
        if love.math.random() <= chance then
          actions[#actions + 1] = { apply = proc.apply, target = context.target }
        end
      end
    end
  end
  return actions
end

-- Called when the player dashes/rolls.
function ProcEngine:onRoll(playerStats)
  local actions = {}
  for _, proc in ipairs(getProcs(playerStats)) do
    if proc.trigger == "after_roll" then
      actions[#actions + 1] = { apply = proc.apply }
    end
  end
  return actions
end

---------------------------------------------------------------------------
-- PASSIVE / CONDITIONAL TRIGGERS (evaluated each frame)
---------------------------------------------------------------------------

-- Called each frame. Updates timers and evaluates passive proc conditions.
-- context: { enemyLists, playerX, playerY, wasFiring, wasHit, dt }
-- Returns a table of conditional buff descriptors that should be active.
function ProcEngine:updatePassive(dt, playerStats, context)
  -- Update continuous firing timer
  if context.wasFiring then
    self.continuousFiringTime = self.continuousFiringTime + dt
  else
    self.continuousFiringTime = 0
  end
  -- Reset firing flag for next frame
  self.isFiring = false

  -- Update no-damage timer
  if context.wasHit then
    self.noDamageTakenTime = 0
  else
    self.noDamageTakenTime = self.noDamageTakenTime + dt
  end

  local actions = {}
  for _, proc in ipairs(getProcs(playerStats)) do
    if proc.trigger == "while_enemy_within" then
      local inRange = false
      for _, list in ipairs(context.enemyLists) do
        for _, e in ipairs(list) do
          if e.isAlive then
            local ex, ey = e:getPosition()
            local dx = ex - context.playerX
            local dy = ey - context.playerY
            if math.sqrt(dx * dx + dy * dy) < (proc.range or 140) then
              inRange = true
              break
            end
          end
        end
        if inRange then break end
      end
      if inRange then
        actions[#actions + 1] = { apply = proc.apply, conditional = true, id = "while_enemy_within" }
      end
    end

    if proc.trigger == "while_enemies_bleeding" then
      local bleedCount, totalStacks = StatusEffects.countBleedingEnemies(context.enemyLists)
      if bleedCount > 0 then
        actions[#actions + 1] = {
          apply = proc.apply,
          conditional = true,
          id = "while_enemies_bleeding",
          bleedStacks = totalStacks,
        }
      end
    end

    if proc.trigger == "firing_continuously_for" then
      if self.continuousFiringTime >= (proc.seconds or 2.0) then
        actions[#actions + 1] = { apply = proc.apply, conditional = true, id = "firing_continuously_for" }
      end
    end

    if proc.trigger == "no_damage_taken_for" then
      if self.noDamageTakenTime >= (proc.seconds or 5.0) then
        actions[#actions + 1] = { apply = proc.apply, conditional = true, id = "no_damage_taken_for" }
      end
    end
  end

  return actions
end

-- Reset all tracking state (e.g. on new floor)
function ProcEngine:reset()
  self.primaryShotCount = 0
  self.continuousFiringTime = 0
  self.noDamageTakenTime = 0
  self.isFiring = false
end

return ProcEngine
