-- systems/status_effects.lua
-- Shared status effect system for any entity with a .statuses table.
-- Supported statuses: bleed, marked, shattered_armor

local StatusEffects = {}

-- Initialize status tracking on an entity
function StatusEffects.init(entity)
  entity.statuses = entity.statuses or {}
end

-- Apply a status to an entity. Stacks refresh duration; bleed stacks accumulate.
function StatusEffects.apply(entity, statusName, stacks, duration)
  if not entity.statuses then entity.statuses = {} end
  local s = entity.statuses[statusName]
  if s then
    if statusName == "bleed" then
      s.stacks = s.stacks + (stacks or 1)
    else
      s.stacks = math.max(s.stacks, stacks or 1)
    end
    s.duration = math.max(s.duration, duration or 3.0)
  else
    entity.statuses[statusName] = {
      stacks = stacks or 1,
      duration = duration or 3.0,
      tickTimer = 0, -- for DoT
    }
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

-- Update statuses: tick durations, apply bleed DoT damage.
-- Returns a table of bleed damage ticks: { {entity, damage}, ... }
function StatusEffects.update(entity, dt, baseDamagePerBleedStack)
  if not entity.statuses then return {} end
  baseDamagePerBleedStack = baseDamagePerBleedStack or 2

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
    end
  end

  for _, name in ipairs(toRemove) do
    entity.statuses[name] = nil
  end

  return ticks
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
