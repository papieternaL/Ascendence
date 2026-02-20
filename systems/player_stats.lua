-- systems/player_stats.lua
-- Tracks player stats with base values and modifiers from upgrades/buffs

local PlayerStats = {}
PlayerStats.__index = PlayerStats

-- Element upgrade IDs (switching element removes the other elements' upgrades)
PlayerStats.elementUpgradeIds = {
  fire = { "arch_c_fire_attunement", "arch_r_fire_intensity" },
  ice = { "arch_c_ice_attunement", "arch_r_ice_depth", "arch_r_freeze_spread", "arch_r_ice_blast_radius" },
  lightning = { "arch_c_lightning_attunement", "arch_r_lightning_reach" },
}

-- Default base stats for archer
PlayerStats.baseDefaults = {
  -- Damage
  primary_damage = 10,
  crit_chance = 0.05,
  crit_damage = 1.5,
  
  -- Attack
  attack_speed = 1.0,  -- attacks per second multiplier
  range = 350,
  
  -- Movement
  move_speed = 224,
  roll_cooldown = 1.0,
  
  -- Utility
  xp_pickup_radius = 63,
  hp_regen_per_sec = 0,
  
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
    buffs = {},  -- active buffs with duration/charges
    acquiredUpgrades = {},  -- { [upgradeId] = true }
    acquiredUpgradeLog = {}, -- ordered list: { {id,name,rarity,tags,effects,at}, ... }
    activePrimaryElement = nil,  -- "fire" | "ice" | "lightning"
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

function PlayerStats:getBase(stat)
  return self.base[stat] or 0
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

-- Get a weapon mod value
function PlayerStats:getWeaponMod(modName)
  return self.weaponMods[modName] or 0
end

-- Apply an upgrade's effects permanently (allows stacking same upgrade multiple times)
function PlayerStats:applyUpgrade(upgrade)
  -- Element switch: when picking a base element upgrade, remove other elements' upgrades
  local elementForUpgrade = nil
  for elem, ids in pairs(PlayerStats.elementUpgradeIds) do
    for _, id in ipairs(ids) do
      if id == upgrade.id then elementForUpgrade = elem break end
    end
    if elementForUpgrade then break end
  end

  if elementForUpgrade and elementForUpgrade ~= self.activePrimaryElement then
    -- Switching element: remove other elements' upgrades and recompute
    local toRemove = {}
    for elem, ids in pairs(PlayerStats.elementUpgradeIds) do
      if elem ~= elementForUpgrade then
        for _, id in ipairs(ids) do toRemove[id] = true end
      end
    end
    local newLog = {}
    for _, entry in ipairs(self.acquiredUpgradeLog) do
      if not toRemove[entry.id] then
        newLog[#newLog+1] = entry
      else
        self.acquiredUpgrades[entry.id] = nil
      end
    end
    self.acquiredUpgradeLog = newLog
    self.activePrimaryElement = elementForUpgrade
    self:recomputeFromUpgrades()
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

  if elementForUpgrade == self.activePrimaryElement or not elementForUpgrade then
    for _, effect in ipairs(upgrade.effects or {}) do
      self:applyEffect(effect)
    end
  else
    self:recomputeFromUpgrades()
  end

  return true
end

-- Recompute all stats from acquired upgrades (used after element switch)
function PlayerStats:recomputeFromUpgrades()
  self.additive = {}
  self.multipliers = {}
  self.weaponMods = {}
  self.elementMods = {}
  for _, entry in ipairs(self.acquiredUpgradeLog) do
    for _, effect in ipairs(entry.effects or {}) do
      self:applyEffect(effect)
    end
  end
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
    -- Attunement procs: only one per element/status to avoid duplicate chain/burn/freeze on repeat picks
    local apply = effect.apply
    if effect.trigger == "on_primary_hit" and apply then
      local key = nil
      if apply.kind == "chain_damage" and apply.element then key = "chain_" .. (apply.element or "") end
      if apply.kind == "status_apply" and (apply.status == "burn" or apply.status == "freeze") then key = "status_" .. (apply.status or "") end
      if key then
        for _, p in ipairs(self.weaponMods.procs) do
          local pa = p.apply
          if p.trigger == effect.trigger and pa then
            local pk = nil
            if pa.kind == "chain_damage" and pa.element then pk = "chain_" .. pa.element end
            if pa.kind == "status_apply" and (pa.status == "burn" or pa.status == "freeze") then pk = "status_" .. pa.status end
            if pk == key then return end -- already have this attunement proc
          end
        end
      end
    end
    table.insert(self.weaponMods.procs, effect)

  elseif effect.kind == "ability_mod" then
    -- Store ability modifications keyed by ability name
    self.weaponMods.abilityMods = self.weaponMods.abilityMods or {}
    local ability = effect.ability or "unknown"
    self.weaponMods.abilityMods[ability] = self.weaponMods.abilityMods[ability] or {}
    table.insert(self.weaponMods.abilityMods[ability], effect)

  elseif effect.kind == "element_mod" then
    -- Element-specific modifiers (only active when activePrimaryElement matches)
    self.elementMods = self.elementMods or {}
    self.elementMods[effect.element] = self.elementMods[effect.element] or {}
    -- Mods ending with _add stack additively; others overwrite
    if effect.mod and effect.mod:match("_add$") then
      self.elementMods[effect.element][effect.mod] = (self.elementMods[effect.element][effect.mod] or 0) + (effect.value or 0)
    else
      self.elementMods[effect.element][effect.mod] = effect.value
    end
  end
end

-- Get all ability modifications for a specific ability
-- Alias: arrow_volley and entangle are the same ability (different keys in different scenes)
function PlayerStats:getAbilityMods(abilityName)
  if not self.weaponMods.abilityMods then return {} end
  local key = (abilityName == "arrow_volley") and "entangle" or abilityName
  return self.weaponMods.abilityMods[key] or {}
end

-- Return the first ability mod matching modType (or nil)
function PlayerStats:getAbilityMod(abilityName, modType)
  local mods = self:getAbilityMods(abilityName)
  for _, mod in ipairs(mods) do
    if mod.mod == modType then
      return mod
    end
  end
  return nil
end

-- Compute a final ability stat by applying all matching mods
-- Returns the modified value after applying all cooldown_add, cooldown_mul, damage_mul, range_mul, etc.
function PlayerStats:getAbilityValue(abilityName, modType, baseValue)
  local mods = self:getAbilityMods(abilityName)
  local value = baseValue
  for _, mod in ipairs(mods) do
    if mod.mod == modType then
      if modType == "cooldown_add" then
        value = value + (mod.value or 0)
      elseif modType == "cooldown_mul" then
        value = value * (mod.value or 1)
      elseif modType == "damage_mul" then
        value = value * (mod.value or 1)
      elseif modType == "range_mul" then
        value = value * (mod.value or 1)
      elseif modType == "charge_gain_mul" then
        value = value * (mod.value or 1)
      elseif modType == "duration_add" then
        value = value + (mod.value or 0)
      elseif modType == "crit_chance_add" then
        value = value + (mod.value or 0)
      elseif modType == "move_speed_mul" then
        value = value * (mod.value or 1)
      elseif modType == "roll_cooldown_mul" then
        value = value * (mod.value or 1)
      elseif modType == "extra_zone_add" then
        value = value + (mod.value or 0)
      else
        -- Generic additive for unknown mods
        value = value + (mod.value or 0)
      end
    end
  end
  return value
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

-- Get element modifier (only if that element is active)
function PlayerStats:getElementMod(element, modName, default)
  if self.activePrimaryElement ~= element then return default end
  if not self.elementMods or not self.elementMods[element] then return default end
  return self.elementMods[element][modName] or default
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


