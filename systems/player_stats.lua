-- systems/player_stats.lua
-- Tracks player stats with base values and modifiers from upgrades/buffs

local PlayerStats = {}
PlayerStats.__index = PlayerStats

-- Default base stats for archer
PlayerStats.baseDefaults = {
  -- Survivability
  max_health = 100,
  -- Damage
  primary_damage = 10,
  crit_chance = 0.05,
  crit_damage = 1.5,
  
  -- Attack
  attack_speed = 1.0,  -- attacks per second multiplier
  range = 350,
  
  -- Movement
  move_speed = 200,
  roll_cooldown = 1.0,
  
  -- Utility
  xp_pickup_radius = 60,
  
  -- Weapon mods (additive)
  pierce = 0,
  ricochet_bounces = 0,
  bonus_projectiles = 0,
  
  -- Special flags
  primary_ghosting = 0, -- projectiles pass through enemies
}

function PlayerStats:new(baseOverrides)
  local stats = setmetatable({
    base = {},
    additive = {},  -- from stat_add effects
    multipliers = {},  -- from stat_mul effects
    weaponMods = {},  -- from weapon_mod effects
    abilityMods = {},  -- from ability_mod effects: { [abilityName] = { [modType] = value/data } }
    buffs = {},  -- active buffs with duration/charges
    acquiredUpgrades = {},  -- { [upgradeId] = true }
    acquiredUpgradeLog = {}, -- ordered list: { {id,name,rarity,tags,effects,at}, ... }
  }, PlayerStats)
  
  -- Initialize base stats
  for stat, value in pairs(PlayerStats.baseDefaults) do
    stats.base[stat] = value
  end
  
  -- Apply any base overrides (from class selection)
  if baseOverrides then
    for stat, value in pairs(baseOverrides) do
      stats.base[stat] = value
    end
  end
  
  return stats
end

-- Get the final computed value for a stat
function PlayerStats:get(stat)
  local base = self.base[stat] or 0
  local add = self.additive[stat] or 0
  local mul = self.multipliers[stat] or 1.0
  
  -- Also factor in active buffs
  for _, buff in pairs(self.buffs) do
    if buff.stats then
      for _, statMod in ipairs(buff.stats) do
        if statMod.stat == stat then
          if statMod.add then
            add = add + statMod.add
          end
          if statMod.mul then
            mul = mul * statMod.mul
          end
        end
      end
    end
  end
  
  return (base + add) * mul
end

-- Get stat value excluding temporary buffs (base + permanent upgrade modifiers only)
function PlayerStats:getPermanent(stat)
  local base = self.base[stat] or 0
  local add = self.additive[stat] or 0
  local mul = self.multipliers[stat] or 1.0
  return (base + add) * mul
end

-- Get base stat value (before any modifiers)
function PlayerStats:getBase(stat)
  return self.base[stat] or 0
end

-- Get a weapon mod value
function PlayerStats:getWeaponMod(modName)
  return self.weaponMods[modName] or 0
end

-- Get an ability mod value
-- Returns the stored value/data, or a default based on mod type
function PlayerStats:getAbilityMod(abilityName, modType)
  if not self.abilityMods[abilityName] then
    return nil
  end
  return self.abilityMods[abilityName][modType]
end

-- Get computed ability mod with proper defaults for additive/multiplicative mods
function PlayerStats:getAbilityModValue(abilityName, modType, default)
  local val = self:getAbilityMod(abilityName, modType)
  if val == nil then
    return default
  end
  return val
end

-- Check if an ability has a specific mod flag (for boolean mods like fires_twice)
function PlayerStats:hasAbilityMod(abilityName, modType)
  local mod = self:getAbilityMod(abilityName, modType)
  return mod ~= nil
end

-- Apply an ability mod effect
function PlayerStats:applyAbilityMod(effect)
  local ability = effect.ability
  local mod = effect.mod
  
  -- Initialize ability mod table if needed
  if not self.abilityMods[ability] then
    self.abilityMods[ability] = {}
  end
  
  -- Handle different mod types based on suffix convention
  if mod:match("_add$") then
    -- Additive mods: accumulate
    self.abilityMods[ability][mod] = (self.abilityMods[ability][mod] or 0) + effect.value
  elseif mod:match("_mul$") then
    -- Multiplicative mods: chain multiply
    self.abilityMods[ability][mod] = (self.abilityMods[ability][mod] or 1.0) * effect.value
  else
    -- Flag/complex mods: store entire effect data
    -- This includes: fires_twice, applies_status, double_strike, extend_on_kill, etc.
    self.abilityMods[ability][mod] = effect
  end
end

-- Apply an upgrade's effects permanently
function PlayerStats:applyUpgrade(upgrade)
  if self.acquiredUpgrades[upgrade.id] then
    return false -- Already have this upgrade
  end
  
  self.acquiredUpgrades[upgrade.id] = true

  -- Record for run-stats UI (ordered history)
  local at = nil
  if love and love.timer and love.timer.getTime then
    at = love.timer.getTime()
  end
  self.acquiredUpgradeLog[#self.acquiredUpgradeLog+1] = {
    id = upgrade.id,
    name = upgrade.name,
    rarity = upgrade.rarity or "common",
    tags = upgrade.tags,
    effects = upgrade.effects,
    at = at,
  }
  
  for _, effect in ipairs(upgrade.effects or {}) do
    self:applyEffect(effect)
  end
  
  return true
end

-- Apply a single effect
function PlayerStats:applyEffect(effect)
  if effect.kind == "stat_add" then
    self.additive[effect.stat] = (self.additive[effect.stat] or 0) + effect.value
    
  elseif effect.kind == "stat_mul" then
    self.multipliers[effect.stat] = (self.multipliers[effect.stat] or 1.0) * effect.value
    
  elseif effect.kind == "weapon_mod" then
    -- Handle various weapon mods
    if effect.mod == "pierce_add" then
      self.weaponMods.pierce = (self.weaponMods.pierce or 0) + effect.value
    elseif effect.mod == "ricochet" then
      self.weaponMods.ricochet = true
      self.weaponMods.ricochet_bounces = (self.weaponMods.ricochet_bounces or 0) + effect.bounces
      self.weaponMods.ricochet_range = effect.range or 220
    elseif effect.mod == "bonus_projectiles" then
      self.weaponMods.bonus_projectiles = (self.weaponMods.bonus_projectiles or 0) + effect.value
      self.weaponMods.projectile_spread = effect.spread_deg or 10
    end
    
  elseif effect.kind == "proc" then
    -- Store proc effects for the combat system to check
    self.weaponMods.procs = self.weaponMods.procs or {}
    table.insert(self.weaponMods.procs, effect)
    
  elseif effect.kind == "ability_mod" then
    -- Apply ability-specific modifiers
    self:applyAbilityMod(effect)
  end
end

-- Add a temporary buff
function PlayerStats:addBuff(name, duration, stats, rules)
  self.buffs[name] = {
    name = name,
    duration = duration,
    timeRemaining = duration,
    stats = stats,
    rules = rules or {},
    charges = rules and rules.charges or nil,
  }
end

-- Remove a buff by name
function PlayerStats:removeBuff(name)
  self.buffs[name] = nil
end

-- Check if a buff is active
function PlayerStats:hasBuff(name)
  return self.buffs[name] ~= nil
end

-- Update buffs (tick down durations)
function PlayerStats:update(dt, context)
  context = context or {}
  
  local toRemove = {}
  
  for name, buff in pairs(self.buffs) do
    -- Check break conditions
    if buff.rules then
      if buff.rules.break_on_hit_taken and context.wasHit then
        toRemove[#toRemove+1] = name
      elseif buff.rules.break_on_roll and context.didRoll then
        toRemove[#toRemove+1] = name
      elseif buff.rules.disabled_during_frenzy and context.inFrenzy then
        toRemove[#toRemove+1] = name
      end
    end
    
    -- Tick down duration
    buff.timeRemaining = buff.timeRemaining - dt
    if buff.timeRemaining <= 0 then
      toRemove[#toRemove+1] = name
    end
  end
  
  for _, name in ipairs(toRemove) do
    self.buffs[name] = nil
  end
end

-- Get list of active buff names (for UI)
function PlayerStats:getActiveBuffs()
  local list = {}
  for name, buff in pairs(self.buffs) do
    list[#list+1] = {
      name = name,
      timeRemaining = buff.timeRemaining,
      duration = buff.duration,
    }
  end
  return list
end

-- Check if player has a specific upgrade
function PlayerStats:hasUpgrade(upgradeId)
  return self.acquiredUpgrades[upgradeId] == true
end

-- Get count of acquired upgrades by rarity
function PlayerStats:getUpgradeCount()
  local count = { common = 0, rare = 0, epic = 0, total = 0 }
  for id, _ in pairs(self.acquiredUpgrades) do
    count.total = count.total + 1
    -- Would need access to upgrade data to count by rarity
  end
  return count
end

-- Get ordered list of acquired upgrades (for UI)
function PlayerStats:getUpgradeLog()
  return self.acquiredUpgradeLog
end

return PlayerStats


