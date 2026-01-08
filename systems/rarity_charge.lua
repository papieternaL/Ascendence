-- systems/rarity_charge.lua
-- Tracks "rarity charge" from MCM kills. Expires after a short window.

local RarityCharge = {}
RarityCharge.__index = RarityCharge

RarityCharge.defaults = {
  maxCharges = 14,          -- hard cap on stored charges
  chargeExpirySec = 60.0,   -- charges expire if you don't level in time

  -- how charges convert into rarity boosts (consumed on level-up)
  -- tuned to feel noticeable but not broken:
  -- max +10% rare, max +4% epic
  rarePerCharge = 0.01,     -- +1% rare per charge
  epicPerCharge = 0.004,    -- +0.4% epic per charge
  maxRareBonus = 0.10,
  maxEpicBonus = 0.04,
}

function RarityCharge:new(opts)
  opts = opts or {}
  local d = RarityCharge.defaults
  local self = setmetatable({
    charges = 0,
    lastChargeTime = 0,
    cfg = {
      maxCharges = opts.maxCharges or d.maxCharges,
      chargeExpirySec = opts.chargeExpirySec or d.chargeExpirySec,
      rarePerCharge = opts.rarePerCharge or d.rarePerCharge,
      epicPerCharge = opts.epicPerCharge or d.epicPerCharge,
      maxRareBonus = opts.maxRareBonus or d.maxRareBonus,
      maxEpicBonus = opts.maxEpicBonus or d.maxEpicBonus,
    }
  }, RarityCharge)
  return self
end

function RarityCharge:add(now, amount)
  amount = amount or 1
  self:tick(now)
  self.charges = math.min(self.charges + amount, self.cfg.maxCharges)
  self.lastChargeTime = now
end

function RarityCharge:tick(now)
  if self.charges > 0 then
    if (now - self.lastChargeTime) >= self.cfg.chargeExpirySec then
      self.charges = 0
    end
  end
end

-- Consumed on level-up. Returns rarity bonuses and clears charges.
function RarityCharge:consume(now)
  self:tick(now)
  local c = self.charges
  self.charges = 0

  local rareBonus = math.min(c * self.cfg.rarePerCharge, self.cfg.maxRareBonus)
  local epicBonus = math.min(c * self.cfg.epicPerCharge, self.cfg.maxEpicBonus)

  return {
    charges = c,
    rareBonus = rareBonus,
    epicBonus = epicBonus
  }
end

function RarityCharge:getCharges()
  return self.charges
end

return RarityCharge












