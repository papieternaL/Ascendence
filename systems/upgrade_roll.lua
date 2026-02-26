-- systems/upgrade_roll.lua
-- Rolls level-up upgrade options from pools with rarity logic + MCM rarity charges.

local UpgradeRoll = {}

-- Base rarity weights (sum doesn't need to be 1; we normalize)
UpgradeRoll.baseRarityWeights = {
  common = 0.60,
  rare   = 0.35,
  epic   = 0.05,
}

-- Utility: shallow copy
local function copy(t)
  local out = {}
  for k,v in pairs(t) do out[k] = v end
  return out
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function normalizeWeights(w)
  local sum = 0
  for _,v in pairs(w) do sum = sum + v end
  if sum <= 0 then return w end
  for k,v in pairs(w) do w[k] = v / sum end
  return w
end

local function weightedChoice(rng, items)
  -- items: { {key="common", w=0.7}, ... } already normalized or not
  local total = 0
  for _,it in ipairs(items) do total = total + it.w end
  local r = rng() * total
  local acc = 0
  for _,it in ipairs(items) do
    acc = acc + it.w
    if r <= acc then return it.key end
  end
  return items[#items].key
end

-- Slight bias for specific upgrades when picking from main pool (bounded, doesn't break global rarity)
local PICK_BIAS = {}

local function chooseOneFromList(rng, list, excludeSet, weightMap)
  -- list: array of upgrade tables
  -- excludeSet: { [id]=true } cannot be picked
  -- weightMap: optional { [id]=weight } for weighted selection
  local candidates = {}
  local weights = {}
  for _,u in ipairs(list) do
    if not excludeSet[u.id] then
      candidates[#candidates+1] = u
      weights[#weights+1] = (weightMap and weightMap[u.id]) or 1
    end
  end
  if #candidates == 0 then return nil end
  if weightMap then
    local total = 0
    for _,w in ipairs(weights) do total = total + w end
    local r = rng() * total
    local acc = 0
    for i, w in ipairs(weights) do
      acc = acc + w
      if r <= acc then return candidates[i] end
    end
    return candidates[#candidates]
  end
  return candidates[math.floor(rng() * #candidates) + 1]
end

-- Build indexed pools: poolsByRarity[rarity] = {upgrade, ...}
local function indexByRarity(upgradeList)
  local pools = { common={}, rare={}, epic={} }
  for _,u in ipairs(upgradeList) do
    if pools[u.rarity] then
      pools[u.rarity][#pools[u.rarity]+1] = u
    end
  end
  return pools
end

-- Optional gate hook (level locks, prerequisites, etc.)
-- Return true if upgrade allowed.
local function defaultIsAllowed(_ctx, _upgrade)
  return true
end

-- Filters a list by ctx with an isAllowed predicate.
local function filterAllowed(ctx, list, isAllowed)
  local out = {}
  for _,u in ipairs(list) do
    if isAllowed(ctx, u) then
      out[#out+1] = u
    end
  end
  return out
end

-- Core: compute rarity weights with charge bonuses.
-- Charge bonuses push probability from Common into Rare/Epic (keeps sum = 1).
local function computeRarityWeights(base, chargeBonus)
  local w = copy(base)

  local addRare = chargeBonus.rareBonus or 0
  local addEpic = chargeBonus.epicBonus or 0

  -- Take from common primarily, but never below a floor.
  local commonFloor = 0.40 -- keeps early game from becoming all rares
  local commonTake = math.min(w.common - commonFloor, addRare + addEpic)
  commonTake = math.max(commonTake, 0)

  -- Scale down bonuses if we hit the floor
  local bonusTotal = addRare + addEpic
  if bonusTotal > 0 and commonTake < bonusTotal then
    local scale = commonTake / bonusTotal
    addRare = addRare * scale
    addEpic = addEpic * scale
  end

  w.common = w.common - (addRare + addEpic)
  w.rare   = w.rare + addRare
  w.epic   = w.epic + addEpic

  -- Clamp safety
  w.common = clamp(w.common, 0.01, 0.98)
  w.rare   = clamp(w.rare,   0.01, 0.70)
  w.epic   = clamp(w.epic,   0.00, 0.25)

  return normalizeWeights(w)
end

-- Public API:
-- UpgradeRoll.rollOptions({
--   rng = function() return love.math.random() end,
--   now = timeSeconds,
--   player = playerRef,
--   classUpgrades = require("data/upgrades_archer").list,
--   abilityPaths = require("data/ability_paths_archer"), -- optional
--   rarityCharge = rarityChargeObj, -- from RarityCharge.new()
--   count = 3,
--   pickBias = { [upgradeId]=weight }, -- optional weighted preference map
--   isAllowed = customGateFn -- optional
-- })
function UpgradeRoll.rollOptions(args)
  local rng = args.rng
  local now = args.now or 0
  local player = args.player
  local count = args.count or 3
  local isAllowed = args.isAllowed or defaultIsAllowed
  local pickBias = args.pickBias or PICK_BIAS

  -- 1) consume rarity charges on level-up roll
  local chargeBonus = { rareBonus=0, epicBonus=0, charges=0 }
  if args.rarityCharge then
    chargeBonus = args.rarityCharge:consume(now)
  end

  -- 2) build rarity weights
  local rarityWeights = computeRarityWeights(UpgradeRoll.baseRarityWeights, chargeBonus)

  -- 3) Build pools
  local classList = args.classUpgrades or {}
  local poolsMain = indexByRarity(filterAllowed({player=player, now=now}, classList, isAllowed))

  -- 4) Optional: ability path injection
  --     Rule: these are "side pools" we can occasionally replace a slot with.
  local abilityPaths = args.abilityPaths
  local inject = {
    enabled = abilityPaths ~= nil,
    -- Tune these. Keep it modest so main pool still defines the run.
    -- After midboss you can raise these.
    chance = 0.18, -- 18% chance each slot becomes an ability-path roll
  }

  local function pickAbilityPathPool()
    -- Choose which ability pool is eligible based on player state.
    -- Adjust these checks to your actual ability systems.
    local eligible = {}
    if player and player.abilities then
      if player.abilities.multi_shot then eligible[#eligible+1] = "multi_shot" end
      if player.abilities.arrow_volley then eligible[#eligible+1] = "arrow_volley" end
      if player.abilities.frenzy then eligible[#eligible+1] = "frenzy" end
    end
    if #eligible == 0 then return nil end
    return eligible[math.floor(rng() * #eligible) + 1]
  end

  local function getAbilityRarityPools(abilityKey)
    if not abilityPaths or not abilityPaths[abilityKey] then return nil end
    local list = abilityPaths[abilityKey]
    local ctx = { player=player, now=now, ability=abilityKey }
    local allowed = filterAllowed(ctx, list, isAllowed)
    return indexByRarity(allowed)
  end

  -- 5) Roll N distinct options
  local chosen = {}
  local chosenIds = {}

  for _=1,count do
    local useAbility = false
    local abilityKey, poolsAbility

    if inject.enabled and (rng() < inject.chance) then
      abilityKey = pickAbilityPathPool()
      if abilityKey then
        poolsAbility = getAbilityRarityPools(abilityKey)
        if poolsAbility then
          useAbility = true
        end
      end
    end

    -- roll rarity
    local rarity = weightedChoice(rng, {
      { key="common", w=rarityWeights.common },
      { key="rare",   w=rarityWeights.rare },
      { key="epic",   w=rarityWeights.epic },
    })

    -- choose from pool; fallback if empty
    local poolSource = useAbility and poolsAbility or poolsMain
    local weightMap = (not useAbility) and pickBias or nil
    local pick = chooseOneFromList(rng, poolSource[rarity], chosenIds, weightMap)

    -- fallback down rarity if empty
    if not pick and rarity == "epic" then
      pick = chooseOneFromList(rng, poolSource["rare"], chosenIds)
    end
    if not pick and (rarity == "epic" or rarity == "rare") then
      pick = chooseOneFromList(rng, poolSource["common"], chosenIds)
    end

    -- fallback to main pool if ability pool failed
    if not pick and useAbility then
      pick = chooseOneFromList(rng, poolsMain[rarity], chosenIds)
        or chooseOneFromList(rng, poolsMain["rare"], chosenIds)
        or chooseOneFromList(rng, poolsMain["common"], chosenIds)
    end

    if not pick then
      -- Nothing left (extreme edge case). Stop early.
      break
    end

    chosen[#chosen+1] = pick
    chosenIds[pick.id] = true
  end

  return {
    options = chosen,
    rarityWeights = rarityWeights,
    chargeConsumed = chargeBonus,
  }
end

return UpgradeRoll












