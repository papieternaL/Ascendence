-- systems/status_component.lua
-- Component that manages status effects on entities

local StatusEffects = require("data.status_effects")

local StatusComponent = {}
StatusComponent.__index = StatusComponent

function StatusComponent:new()
  local sc = {
    active_statuses = {},
    dot_timers = {},
    previous_statuses = {}
  }
  setmetatable(sc, StatusComponent)
  return sc
end

function StatusComponent:applyStatus(status_name, stacks, duration, source_data)
  local def = StatusEffects[status_name]
  if not def then
    print("Warning: Unknown status effect: " .. status_name)
    return
  end
  
  local existing = self.active_statuses[status_name]
  local is_new = not existing
  
  if existing then
    existing.stacks = math.min(existing.stacks + stacks, def.max_stacks or 999)
    existing.duration = math.max(existing.duration, duration)
    existing.source_data = source_data or existing.source_data
  else
    self.active_statuses[status_name] = {
      stacks = math.min(stacks, def.max_stacks or 999),
      duration = duration,
      charges = def.charges,
      source_data = source_data,
      max_duration = duration
    }
    
    if def.type == "dot" then
      self.dot_timers[status_name] = 0
    end
  end
  
  return is_new
end

function StatusComponent:removeStatus(status_name)
  self.active_statuses[status_name] = nil
  self.dot_timers[status_name] = nil
end

function StatusComponent:hasStatus(status_name)
  return self.active_statuses[status_name] ~= nil
end

function StatusComponent:getStacks(status_name)
  local status = self.active_statuses[status_name]
  return status and status.stacks or 0
end

function StatusComponent:consumeCharge(status_name)
  local status = self.active_statuses[status_name]
  if not status or not status.charges then return end
  
  status.charges = status.charges - 1
  if status.charges <= 0 then
    self:removeStatus(status_name)
    return true
  end
  return false
end

function StatusComponent:update(dt, owner)
  local statuses_to_remove = {}
  
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    
    status.duration = status.duration - dt
    if status.duration <= 0 then
      table.insert(statuses_to_remove, status_name)
      goto continue
    end
    
    if def.type == "dot" then
      self.dot_timers[status_name] = self.dot_timers[status_name] + dt
      if self.dot_timers[status_name] >= def.tick_interval then
        self.dot_timers[status_name] = self.dot_timers[status_name] - def.tick_interval
        
        local tick_damage = def.damage_per_tick(status.source_data.damage)
        local total_damage = tick_damage * status.stacks
        
        if owner.takeDamage then
          owner:takeDamage(total_damage, "dot")
        end
        if owner.spawnDamageNumber then
          owner:spawnDamageNumber(total_damage, false, true)
        end
      end
    end
    
    ::continue::
  end
  
  for _, status_name in ipairs(statuses_to_remove) do
    self:removeStatus(status_name)
  end
end

function StatusComponent:getActiveBuffs()
  local buffs = {}
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    if def.target == "player" then
      table.insert(buffs, {
        name = status_name,
        display_name = def.display_name,
        icon = def.icon,
        color = def.color,
        duration = status.duration,
        max_duration = status.max_duration,
        stacks = status.stacks,
        charges = status.charges
      })
    end
  end
  return buffs
end

function StatusComponent:getActiveDebuffs()
  local debuffs = {}
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    if def.target == "enemy" then
      table.insert(debuffs, {
        name = status_name,
        display_name = def.display_name,
        icon = def.icon,
        color = def.color,
        duration = status.duration,
        stacks = status.stacks
      })
    end
  end
  return debuffs
end

function StatusComponent:getDamageMultiplier()
  local multiplier = 1.0
  
  if self:hasStatus("marked") then
    local def = StatusEffects.marked
    multiplier = multiplier * def.damage_multiplier
  end
  
  return multiplier
end

function StatusComponent:getStatModifications()
  local mods = {
    primary_damage = { mul = 1.0, add = 0 },
    move_speed = { mul = 1.0, add = 0 },
    attack_speed = { mul = 1.0, add = 0 },
    crit_chance = { mul = 1.0, add = 0 }
  }
  
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    if def.stat_mods then
      for stat, mod in pairs(def.stat_mods) do
        if not mods[stat] then
          mods[stat] = { mul = 1.0, add = 0 }
        end
        if mod.mul then
          mods[stat].mul = mods[stat].mul * mod.mul
        end
        if mod.add then
          mods[stat].add = mods[stat].add + mod.add
        end
      end
    end
  end
  
  return mods
end

function StatusComponent:getWeaponModifications()
  local mods = {
    primary_ghosting = 0
  }
  
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    if def.weapon_mods then
      for mod_name, value in pairs(def.weapon_mods) do
        mods[mod_name] = (mods[mod_name] or 0) + value
      end
    end
  end
  
  return mods
end

function StatusComponent:checkBreakConditions(condition_type)
  local statuses_to_remove = {}
  
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    if def.rules then
      if condition_type == "hit_taken" and def.rules.break_on_hit_taken then
        table.insert(statuses_to_remove, status_name)
      end
      if condition_type == "roll" and def.rules.break_on_roll then
        table.insert(statuses_to_remove, status_name)
      end
    end
  end
  
  for _, status_name in ipairs(statuses_to_remove) do
    self:removeStatus(status_name)
  end
  
  return #statuses_to_remove > 0
end

function StatusComponent:handleFrenzyState(is_in_frenzy)
  if not is_in_frenzy then return end
  
  local statuses_to_remove = {}
  for status_name, status in pairs(self.active_statuses) do
    local def = StatusEffects[status_name]
    if def.rules and def.rules.disabled_during_frenzy then
      table.insert(statuses_to_remove, status_name)
    end
  end
  
  for _, status_name in ipairs(statuses_to_remove) do
    self:removeStatus(status_name)
  end
end

function StatusComponent:getNewStatuses()
  local new_statuses = {}
  for status_name, _ in pairs(self.active_statuses) do
    if not self.previous_statuses[status_name] then
      table.insert(new_statuses, status_name)
    end
  end
  
  self.previous_statuses = {}
  for status_name, _ in pairs(self.active_statuses) do
    self.previous_statuses[status_name] = true
  end
  
  return new_statuses
end

return StatusComponent
