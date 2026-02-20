-- systems/status_effects.lua
-- Shared status effect system for any entity with a .statuses table.
-- Supported statuses: bleed, marked, shattered_armor, burn, chill, freeze

local StatusEffects = {}

-- Initialize status tracking on an entity
function StatusEffects.init(entity)
  entity.statuses = entity.statuses or {}
end

-- Apply a status to an entity. Stacks refresh duration; bleed stacks accumulate.
-- options: { slowMul = 1.10 } for chill (extra slow from ice_depth)
function StatusEffects.apply(entity, statusName, stacks, duration, options)
  if not entity.statuses then entity.statuses = {} end
  local s = entity.statuses[statusName]
  if s then
    if statusName == "bleed" or statusName == "burn" then
      s.stacks = s.stacks + (stacks or 1)
    else
      s.stacks = math.max(s.stacks, stacks or 1)
    end
    s.duration = math.max(s.duration, duration or 3.0)
    if options then
      for k, v in pairs(options) do s[k] = v end
    end
  else
    s = {
      stacks = stacks or 1,
      duration = duration or 3.0,
      tickTimer = 0, -- for DoT
    }
    if options then
      for k, v in pairs(options) do s[k] = v end
    end
    entity.statuses[statusName] = s
  end
end

-- Check if entity has a specific status
function StatusEffects.has(entity, statusName)
  if not entity.statuses then return false end
  return entity.statuses[statusName] ~= nil
end

-- Get stacks of a status (0 if not present)
function StatusEffects.getStacks(entity, statusName)
  if not entity.statuses then return 0 end
  local s = entity.statuses[statusName]
  return s and s.stacks or 0
end

-- Count total bleed stacks across a list of entities
function StatusEffects.countBleedingEnemies(entityLists)
  local totalStacks = 0
  local bleedingCount = 0
  for _, list in ipairs(entityLists) do
    for _, e in ipairs(list) do
      if e.isAlive and e.statuses and e.statuses.bleed then
        bleedingCount = bleedingCount + 1
        totalStacks = totalStacks + e.statuses.bleed.stacks
      end
    end
  end
  return bleedingCount, totalStacks
end

-- Update statuses: tick durations, apply bleed/burn DoT damage.
-- Returns a table of damage ticks: { {entity, damage, status}, ... }
-- baseDamagePerBleedStack: for bleed. burnDamagePerStack: for burn (default 20% of hit, use config).
function StatusEffects.update(entity, dt, baseDamagePerBleedStack, burnDamagePerStack)
  if not entity.statuses then return {} end
  baseDamagePerBleedStack = baseDamagePerBleedStack or 2
  burnDamagePerStack = burnDamagePerStack or 2

  local ticks = {}
  local toRemove = {}

  for name, s in pairs(entity.statuses) do
    s.duration = s.duration - dt
    if s.duration <= 0 then
      toRemove[#toRemove + 1] = name
    else
      -- Bleed DoT: tick every 0.5s
      if name == "bleed" then
        s.tickTimer = s.tickTimer + dt
        while s.tickTimer >= 0.5 do
          s.tickTimer = s.tickTimer - 0.5
          local bleedDmg = s.stacks * baseDamagePerBleedStack
          ticks[#ticks + 1] = { entity = entity, damage = bleedDmg, status = "bleed" }
        end
      end
      -- Burn DoT: tick every 0.5s
      if name == "burn" then
        s.tickTimer = s.tickTimer + dt
        while s.tickTimer >= 0.5 do
          s.tickTimer = s.tickTimer - 0.5
          local burnDmg = s.stacks * burnDamagePerStack
          ticks[#ticks + 1] = { entity = entity, damage = burnDmg, status = "burn" }
        end
      end
    end
  end

  for _, name in ipairs(toRemove) do
    entity.statuses[name] = nil
  end

  return ticks
end

-- Get speed multiplier from chill/freeze (1.0 = normal, 0.5 = 50% speed, 0 = frozen)
function StatusEffects.getSpeedMul(entity)
  if not entity.statuses then return 1.0 end
  if entity.statuses.freeze then return 0 end
  if entity.statuses.chill then
    local base = 0.6  -- 40% slow
    local slowMul = entity.statuses.chill.slowMul or 1.0  -- ice_depth: 1.10 = 10% more slow
    return base / slowMul  -- 0.6/1.1 = 0.545
  end
  return 1.0
end

-- Check if entity is frozen (cannot move)
function StatusEffects.isFrozen(entity)
  return entity.statuses and entity.statuses.freeze ~= nil
end

-- Get the damage taken multiplier from statuses (marked, shattered_armor stack)
function StatusEffects.getDamageTakenMul(entity)
  if not entity.statuses then return 1.0 end
  local mul = 1.0
  if entity.statuses.marked then
    mul = mul * 1.20
  end
  if entity.statuses.shattered_armor then
    mul = mul * 1.12
  end
  return mul
end

-- Remove a specific status
function StatusEffects.remove(entity, statusName)
  if entity.statuses then
    entity.statuses[statusName] = nil
  end
end

-- Clear all statuses
function StatusEffects.clear(entity)
  entity.statuses = {}
end

return StatusEffects
