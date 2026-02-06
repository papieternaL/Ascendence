-- systems/upgrade_application.lua
-- Handles applying upgrade effects to the player

local UpgradeApplication = {}

function UpgradeApplication.apply(player, upgrade, playerStats)
  if not upgrade or not upgrade.effects then
    print("Warning: Invalid upgrade data")
    return
  end
  
  print("Applying upgrade: " .. upgrade.name)
  
  for _, effect in ipairs(upgrade.effects) do
    UpgradeApplication.applyEffect(player, effect, upgrade, playerStats)
  end
  
  if not player.ownedUpgrades then
    player.ownedUpgrades = {}
  end
  table.insert(player.ownedUpgrades, upgrade.id)
end

function UpgradeApplication.applyEffect(player, effect, upgrade, playerStats)
  local kind = effect.kind
  
  -- Use PlayerStats.applyEffect for stat/weapon/ability effects if available
  if playerStats and (kind == "stat_mul" or kind == "stat_add" or kind == "weapon_mod" or kind == "ability_mod") then
    playerStats:applyEffect(effect)
  elseif kind == "proc" then
    -- Register procs on the player for combat system to check
    UpgradeApplication.registerProc(player, effect, upgrade)
    -- Also register in playerStats if available
    if playerStats then
      playerStats:applyEffect(effect)
    end
  end
end

function UpgradeApplication.registerProc(player, effect, upgrade)
  if not player.procs then
    player.procs = {}
  end
  
  local proc = {
    trigger = effect.trigger,
    apply = effect.apply,
    upgrade_id = upgrade.id,
    upgrade_name = upgrade.name
  }
  
  if effect.trigger == "every_n_primary_shots" then
    proc.n = effect.n
    proc.shot_counter = 0
  elseif effect.trigger == "while_enemy_within" then
    proc.range = effect.range
  elseif effect.trigger == "on_crit_hit" then
    proc.chance = effect.chance or 1.0
  elseif effect.trigger == "on_primary_hit" then
    proc.chance = effect.chance or 1.0
  elseif effect.trigger == "after_roll" then
    -- No additional data needed
  elseif effect.trigger == "on_kill_target_with_status" then
    proc.status = effect.status
    proc.chance = effect.chance or 1.0
  end
  
  table.insert(player.procs, proc)
end

function UpgradeApplication.hasUpgrade(player, upgrade_id)
  if not player.ownedUpgrades then return false end
  
  for _, id in ipairs(player.ownedUpgrades) do
    if id == upgrade_id then return true end
  end
  
  return false
end

function UpgradeApplication.checkProcs(player, trigger_type, context)
  if not player.procs then return end
  
  for _, proc in ipairs(player.procs) do
    if proc.trigger == trigger_type then
      UpgradeApplication.evaluateProc(player, proc, context)
    end
  end
end

function UpgradeApplication.evaluateProc(player, proc, context)
  local trigger = proc.trigger
  local apply = proc.apply
  
  if trigger == "on_primary_hit" then
    if math.random() <= (proc.chance or 1.0) then
      UpgradeApplication.executeApply(player, apply, context)
    end
  elseif trigger == "on_crit_hit" then
    if context.is_crit and math.random() <= (proc.chance or 1.0) then
      UpgradeApplication.executeApply(player, apply, context)
    end
  elseif trigger == "after_roll" then
    UpgradeApplication.executeApply(player, apply, context)
  elseif trigger == "every_n_primary_shots" then
    proc.shot_counter = (proc.shot_counter or 0) + 1
    if proc.shot_counter >= proc.n then
      proc.shot_counter = 0
      UpgradeApplication.executeApply(player, apply, context)
    end
  elseif trigger == "on_kill_target_with_status" then
    if context.status == proc.status and math.random() <= (proc.chance or 1.0) then
      UpgradeApplication.executeApply(player, apply, context)
    end
  end
end

function UpgradeApplication.executeApply(player, apply, context)
  local kind = apply.kind
  
  if kind == "status_apply" then
    if context.target and context.target.statusComponent then
      context.target.statusComponent:applyStatus(
        apply.status,
        apply.stacks,
        apply.duration,
        { damage = context.damage }
      )
    end
  elseif kind == "buff" then
    if player.statusComponent then
      player.statusComponent:applyStatus(
        apply.name,
        1,
        apply.duration
      )
    end
  elseif kind == "weapon_mod" then
    -- Handle temporary weapon mods (e.g., bonus projectiles)
    if context.apply_weapon_mod then
      context.apply_weapon_mod(apply)
    end
  elseif kind == "chain_damage" then
    if context.deal_chain_damage then
      context.deal_chain_damage(apply, context)
    end
  elseif kind == "aoe_explosion" then
    if context.trigger_aoe_explosion then
      context.trigger_aoe_explosion(apply, context)
    end
  elseif kind == "aoe_projectile_burst" then
    if context.spawn_projectile_burst then
      context.spawn_projectile_burst(apply, context)
    end
  end
end

return UpgradeApplication
