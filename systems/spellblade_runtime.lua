local SpellbladeConfig = require("data.spellblade_config")
local SpellbladeWave = require("entities.spellblade_wave")
local SpellbladeMirror = require("entities.spellblade_mirror")
local SpellbladeArcaneSwords = require("entities.spellblade_arcane_swords")
local SpellbladePrismRift = require("entities.spellblade_prism_rift")
local Config = require("data.config")

local SpellbladeRuntime = {}
SpellbladeRuntime.__index = SpellbladeRuntime

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function cloneTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            copy[key] = cloneTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

local function normalize(dx, dy, fallbackX, fallbackY)
    local mag = math.sqrt(dx * dx + dy * dy)
    if mag <= 0.0001 then
        dx = fallbackX or 1
        dy = fallbackY or 0
        mag = math.sqrt(dx * dx + dy * dy)
    end

    return dx / mag, dy / mag
end

local function segmentDistanceSquared(px, py, ax, ay, bx, by)
    local abx = bx - ax
    local aby = by - ay
    local abLenSq = abx * abx + aby * aby
    if abLenSq <= 0.0001 then
        return distanceSquared(px, py, ax, ay)
    end

    local apx = px - ax
    local apy = py - ay
    local t = clamp((apx * abx + apy * aby) / abLenSq, 0, 1)
    local closestX = ax + abx * t
    local closestY = ay + aby * t
    return distanceSquared(px, py, closestX, closestY)
end

local function makeAbility(name, key, icon, cooldown, description)
    return {
        name = name,
        key = key,
        icon = icon,
        cooldown = cooldown,
        currentCooldown = 0,
        unlocked = true,
        description = description,
        castType = "manual",
    }
end

function SpellbladeRuntime:new()
    return setmetatable({
        waves = {},
        mirrors = {},
        rifts = {},
        swords = nil,
        primaryCooldown = 0,
        astralActive = false,
        astralTimeRemaining = 0,
    }, SpellbladeRuntime)
end

function SpellbladeRuntime:isActive(player)
    return player and player.heroClass == "spellblade"
end

function SpellbladeRuntime:setupPlayer(player)
    if not player then
        return
    end

    player.heroClass = "spellblade"
    player.weaponHidden = true
    player.attackVisualStyle = "spellblade"
    player.bodyColor = {0.34, 0.82, 1.0}
    player.secondaryColor = {0.76, 0.62, 1.0}
    player.abilities = {
        arcane_swords = makeAbility(
            "Arcane Swords",
            "Q",
            "SW",
            SpellbladeConfig.arcaneSwords.cooldown,
            "Summon orbiting blades that punish anything entering your close range."
        ),
        mirror_blink = makeAbility(
            "Mirror Blink",
            "SPACE",
            "MB",
            SpellbladeConfig.mirrorBlink.cooldown,
            "Blink in your movement or facing direction and leave behind a mirror slash."
        ),
        prism_rift = makeAbility(
            "Prism Rift",
            "E",
            "PR",
            SpellbladeConfig.prismRift.cooldown,
            "Create a rift that drags enemies inward before collapsing in an arcane burst."
        ),
        astral_ascension = makeAbility(
            "Astral Ascension",
            "R",
            "AA",
            SpellbladeConfig.astral.cooldown,
            "Transform into an astral duelist and temporarily amplify every core skill."
        ),
    }
    player.abilityOrder = {
        "arcane_swords",
        "mirror_blink",
        "prism_rift",
        "astral_ascension",
    }
    player.astralActive = false
    player.astralTimeRemaining = 0
    player.formStatusText = nil
end

function SpellbladeRuntime:getAbilityValue(scene, abilityId, modType, baseValue)
    if scene.playerStats then
        return scene.playerStats:getAbilityValue(abilityId, modType, baseValue)
    end
    return baseValue
end

function SpellbladeRuntime:isAstralActive()
    return self.astralActive and self.astralTimeRemaining > 0
end

function SpellbladeRuntime:getPrimaryState(scene)
    local base = SpellbladeConfig.primary
    local astral = SpellbladeConfig.astral
    local attackSpeed = scene.playerStats and scene.playerStats:get("attack_speed") or 1.0
    local cooldown = self:getAbilityValue(scene, "energy_wave", "cooldown_add", base.cooldown / math.max(0.01, attackSpeed))
    cooldown = self:getAbilityValue(scene, "energy_wave", "cooldown_mul", cooldown)

    local damage = self:getAbilityValue(scene, "energy_wave", "damage_add", scene.player.attackDamage or base.damage)
    damage = self:getAbilityValue(scene, "energy_wave", "damage_mul", damage)
    local width = self:getAbilityValue(scene, "energy_wave", "width_add", base.width)
    local length = self:getAbilityValue(scene, "energy_wave", "length_add", base.length)
    local speed = self:getAbilityValue(scene, "energy_wave", "speed_add", base.speed)
    local maxDistance = self:getAbilityValue(scene, "energy_wave", "max_distance_add", base.maxDistance)
    local lifetime = self:getAbilityValue(scene, "energy_wave", "duration_add", base.lifetime)

    if self:isAstralActive() then
        cooldown = cooldown * astral.primaryCooldownMul
        damage = damage * astral.primaryDamageMul
        width = width * astral.primaryWidthMul
        length = length * astral.primaryLengthMul
        speed = speed * astral.primarySpeedMul
        maxDistance = maxDistance * astral.primaryMaxDistanceMul
    end

    return {
        damage = damage,
        width = width,
        length = length,
        speed = speed,
        maxDistance = maxDistance,
        lifetime = lifetime,
        cooldown = math.max(0.06, cooldown),
        knockback = base.knockback,
        color = base.color,
        edgeColor = base.edgeColor,
    }
end

function SpellbladeRuntime:getMirrorBlinkState(scene)
    local base = SpellbladeConfig.mirrorBlink
    local astral = SpellbladeConfig.astral

    local cooldown = self:getAbilityValue(scene, "mirror_blink", "cooldown_add", base.cooldown)
    cooldown = self:getAbilityValue(scene, "mirror_blink", "cooldown_mul", cooldown)
    local blinkDistance = self:getAbilityValue(scene, "mirror_blink", "blink_distance_add", base.blinkDistance)
    local mirrorDuration = self:getAbilityValue(scene, "mirror_blink", "duration_add", base.mirrorDuration)
    local mirrorDamageMultiplier = self:getAbilityValue(scene, "mirror_blink", "mirror_damage_mul", base.mirrorDamageMultiplier)
    local contactDamage = self:getAbilityValue(scene, "mirror_blink", "contact_damage_add", base.contactDamage)

    if self:isAstralActive() then
        cooldown = cooldown * astral.blinkCooldownMul
        blinkDistance = blinkDistance * astral.blinkDistanceMul
        contactDamage = contactDamage * astral.blinkContactDamageMul
        mirrorDamageMultiplier = mirrorDamageMultiplier * astral.blinkMirrorDamageMul
    end

    return {
        cooldown = math.max(0.2, cooldown),
        blinkDistance = blinkDistance,
        mirrorDuration = mirrorDuration,
        mirrorDamageMultiplier = mirrorDamageMultiplier,
        contactRadius = base.contactRadius,
        contactDamage = contactDamage,
        pathWidth = base.pathWidth,
        color = base.color,
    }
end

function SpellbladeRuntime:getSwordState(scene)
    local base = SpellbladeConfig.arcaneSwords
    local astral = SpellbladeConfig.astral

    local cooldown = self:getAbilityValue(scene, "arcane_swords", "cooldown_add", base.cooldown)
    cooldown = self:getAbilityValue(scene, "arcane_swords", "cooldown_mul", cooldown)
    local swordCount = math.floor(self:getAbilityValue(scene, "arcane_swords", "sword_count_add", base.swordCount))
    local orbitRadius = self:getAbilityValue(scene, "arcane_swords", "orbit_radius_add", base.orbitRadius)
    local orbitSpeed = self:getAbilityValue(scene, "arcane_swords", "orbit_speed_mul", base.orbitSpeed)
    local damage = self:getAbilityValue(scene, "arcane_swords", "damage_add", base.damage)
    damage = self:getAbilityValue(scene, "arcane_swords", "damage_mul", damage)
    local duration = self:getAbilityValue(scene, "arcane_swords", "duration_add", base.duration)

    if self:isAstralActive() then
        swordCount = swordCount + astral.swordsCountAdd
        orbitRadius = orbitRadius + astral.swordsOrbitRadiusAdd
        orbitSpeed = orbitSpeed * astral.swordsOrbitSpeedMul
        damage = damage * astral.swordsDamageMul
        duration = duration * astral.swordsDurationMul
    end

    return {
        cooldown = math.max(1.0, cooldown),
        swordCount = math.max(1, swordCount),
        orbitRadius = orbitRadius,
        orbitSpeed = orbitSpeed,
        damage = damage,
        duration = duration,
        hitInterval = base.hitInterval,
        swordSize = base.swordSize,
        color = base.color,
    }
end

function SpellbladeRuntime:getRiftState(scene)
    local base = SpellbladeConfig.prismRift
    local astral = SpellbladeConfig.astral

    local cooldown = self:getAbilityValue(scene, "prism_rift", "cooldown_add", base.cooldown)
    cooldown = self:getAbilityValue(scene, "prism_rift", "cooldown_mul", cooldown)
    local radius = self:getAbilityValue(scene, "prism_rift", "radius_add", base.radius)
    local pullStrength = self:getAbilityValue(scene, "prism_rift", "pull_strength_add", base.pullStrength)
    local duration = self:getAbilityValue(scene, "prism_rift", "duration_add", base.duration)
    local collapseDamage = self:getAbilityValue(scene, "prism_rift", "collapse_damage_add", base.collapseDamage)
    collapseDamage = self:getAbilityValue(scene, "prism_rift", "damage_mul", collapseDamage)

    if self:isAstralActive() then
        radius = radius * astral.riftRadiusMul
        pullStrength = pullStrength * astral.riftPullStrengthMul
        duration = duration * astral.riftDurationMul
        collapseDamage = collapseDamage * astral.riftCollapseDamageMul
    end

    return {
        cooldown = math.max(1.0, cooldown),
        castRange = base.castRange,
        spawnOffset = base.spawnOffset,
        radius = radius,
        pullStrength = pullStrength,
        duration = duration,
        collapseDamage = collapseDamage,
        color = base.color,
        collapseColor = base.collapseColor,
    }
end

function SpellbladeRuntime:getAstralState(scene)
    local base = SpellbladeConfig.astral
    local cooldown = self:getAbilityValue(scene, "astral_ascension", "cooldown_add", base.cooldown)
    cooldown = self:getAbilityValue(scene, "astral_ascension", "cooldown_mul", cooldown)
    local duration = self:getAbilityValue(scene, "astral_ascension", "duration_add", base.duration)
    duration = self:getAbilityValue(scene, "astral_ascension", "duration_mul", duration)

    return {
        cooldown = math.max(6.0, cooldown),
        duration = duration,
        auraColor = base.auraColor,
        debugInstantActivation = base.debugInstantActivation,
    }
end

function SpellbladeRuntime:getFacingDirection(scene)
    local player = scene.player
    if not player then
        return 1, 0
    end

    local mouseDx = (scene.mouseX or player.x) - player.x
    local mouseDy = (scene.mouseY or player.y) - player.y
    local faceX, faceY = normalize(mouseDx, mouseDy, player.lastMoveX, player.lastMoveY)
    return faceX, faceY
end

function SpellbladeRuntime:getBlinkDirection(scene)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left", "a") then dx = dx - 1 end
    if love.keyboard.isDown("right", "d") then dx = dx + 1 end
    if love.keyboard.isDown("up", "w") then dy = dy - 1 end
    if love.keyboard.isDown("down", "s") then dy = dy + 1 end

    local player = scene.player
    return normalize(dx, dy, math.cos(player:getBowAngle()), math.sin(player:getBowAngle()))
end

function SpellbladeRuntime:clampPosition(scene, x, y)
    local player = scene.player
    local radius = player and player:getSize() or 18

    if scene.camera then
        local worldW = Config.World and Config.World.width or love.graphics.getWidth()
        local worldH = Config.World and Config.World.height or love.graphics.getHeight()
        return clamp(x, radius, worldW - radius), clamp(y, radius, worldH - radius)
    end

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    return clamp(x, radius, w - radius), clamp(y, radius, h - radius)
end

function SpellbladeRuntime:refreshAbilityCooldowns(scene)
    local player = scene.player
    if not player or not player.abilities then
        return
    end

    local blinkState = self:getMirrorBlinkState(scene)
    local swordsState = self:getSwordState(scene)
    local riftState = self:getRiftState(scene)
    local astralState = self:getAstralState(scene)

    player.abilities.arcane_swords.cooldown = swordsState.cooldown
    player.abilities.mirror_blink.cooldown = blinkState.cooldown
    player.abilities.prism_rift.cooldown = riftState.cooldown
    player.abilities.astral_ascension.cooldown = astralState.cooldown
end

function SpellbladeRuntime:applyStats(scene)
    local player = scene.player
    if not player or not scene.playerStats then
        return
    end

    local playerMoveScale = (Config.World and Config.World.playerMoveSpeedScale) or 1.0
    player.attackDamage = scene.playerStats:get("primary_damage")
    player.speed = scene.playerStats:get("move_speed") * playerMoveScale
    scene.attackRange = scene.playerStats:get("range")
    scene.fireRate = self:getPrimaryState(scene).cooldown
    player.activeElement = nil
    player.isFrenzyActive = false
    self:refreshAbilityCooldowns(scene)
end

function SpellbladeRuntime:syncPlayerState(player)
    if not player then
        return
    end

    player.astralActive = self:isAstralActive()
    player.astralTimeRemaining = math.max(0, self.astralTimeRemaining)
    player.formStatusText = player.astralActive and string.format("ASTRAL %.1fs", player.astralTimeRemaining) or nil
    player.weaponHidden = true
end

function SpellbladeRuntime:spawnWave(scene, x, y, dirX, dirY, damageMultiplier, overrides)
    local waveState = self:getPrimaryState(scene)
    local wave = SpellbladeWave:new(x, y, dirX, dirY, {
        damage = waveState.damage * (damageMultiplier or 1.0),
        width = overrides and overrides.width or waveState.width,
        length = overrides and overrides.length or waveState.length,
        speed = overrides and overrides.speed or waveState.speed,
        maxDistance = overrides and overrides.maxDistance or waveState.maxDistance,
        lifetime = overrides and overrides.lifetime or waveState.lifetime,
        knockback = overrides and overrides.knockback or waveState.knockback,
        color = overrides and overrides.color or waveState.color,
        edgeColor = overrides and overrides.edgeColor or waveState.edgeColor,
    })

    self.waves[#self.waves + 1] = wave

    if scene.particles then
        scene.particles:createCastBurst(x, y, wave.color, damageMultiplier or 1.0)
    end
    if scene.screenShake then
        scene.screenShake:add(2, 0.06)
    end
end

function SpellbladeRuntime:startPrimary(scene)
    local player = scene.player
    if not player then
        return
    end

    local dirX, dirY = self:getFacingDirection(scene)
    player:aimAt(player.x + dirX * 50, player.y + dirY * 50)
    self:spawnWave(scene, player.x + dirX * 16, player.y + dirY * 16, dirX, dirY, 1.0)
    self.primaryCooldown = self:getPrimaryState(scene).cooldown

    if scene.particles then
        scene.particles:createHitSpark(player.x + dirX * 12, player.y + dirY * 12, {0.62, 0.95, 1.0})
    end
    if scene.hitFreeze then
        scene:hitFreeze(0.02)
    end
    if _G.audio then
        _G.audio:playSFX("shoot_arrow", { pitch = self:isAstralActive() and 1.18 or 1.0 })
    end
end

function SpellbladeRuntime:getTargets(scene)
    local targets = {}

    if scene.getAllEnemyLists then
        for _, list in ipairs(scene:getAllEnemyLists()) do
            for _, target in ipairs(list) do
                if target and target.isAlive then
                    targets[#targets + 1] = target
                end
            end
        end
    end

    if scene.bossAdds then
        for _, add in ipairs(scene.bossAdds) do
            if add and add.isAlive then
                targets[#targets + 1] = add
            end
        end
    end

    if scene.boss and scene.boss.isAlive then
        targets[#targets + 1] = scene.boss
    end

    return targets
end

function SpellbladeRuntime:applyDamage(scene, target, damage, sourceX, sourceY, opts)
    opts = opts or {}
    if not target or not target.isAlive or damage <= 0 then
        return false
    end

    if target.isInvulnerable then
        return false
    end

    local tx, ty
    if target.getPosition then
        tx, ty = target:getPosition()
    else
        tx, ty = target.x or 0, target.y or 0
    end
    local died
    if target.isBoss then
        died = target:takeDamage(damage)
    else
        died = target:takeDamage(damage, sourceX, sourceY, opts.knockback or 0)
    end

    if scene.damageNumbers then
        local size = target.getSize and target:getSize() or 18
        scene.damageNumbers:add(tx, ty - size, damage, { isCrit = false })
    end
    if scene.particles then
        scene.particles:createHitSpark(tx, ty, opts.color or {0.58, 0.92, 1.0})
    end
    if scene.screenShake then
        scene.screenShake:add(opts.shake or 2, opts.shakeTime or 0.06)
    end

    if died and not target.isBoss then
        if scene.enemySpawner and scene.enemySpawner.onEnemyDeath then
            scene.enemySpawner:onEnemyDeath()
        end
        if scene.spawnEnemyXpDrop then
            scene:spawnEnemyXpDrop(tx, ty, opts.xpValue or (10 + math.random(0, 8)))
        end
        if scene.addMajorProgress and scene.majorProgressPerKill then
            scene:addMajorProgress(scene.majorProgressPerKill)
        end
    end

    return true
end

function SpellbladeRuntime:damageTargetsAlongSegment(scene, ax, ay, bx, by, width, damage)
    local hitAny = false
    local widthSq = width * width
    for _, target in ipairs(self:getTargets(scene)) do
        local tx, ty = target:getPosition()
        local radius = target.getSize and target:getSize() or 18
        if segmentDistanceSquared(tx, ty, ax, ay, bx, by) <= (widthSq + radius * radius) then
            if self:applyDamage(scene, target, damage, bx, by, {
                knockback = 90,
                color = {0.8, 0.66, 1.0},
                shake = 3,
            }) then
                hitAny = true
            end
        end
    end
    return hitAny
end

function SpellbladeRuntime:castMirrorBlink(scene)
    local player = scene.player
    if not player or not player:isAbilityReady("mirror_blink") then
        return false
    end

    local blinkState = self:getMirrorBlinkState(scene)
    local dirX, dirY = self:getBlinkDirection(scene)
    local startX, startY = player:getPosition()
    local endX = startX + dirX * blinkState.blinkDistance
    local endY = startY + dirY * blinkState.blinkDistance
    endX, endY = self:clampPosition(scene, endX, endY)

    player:useAbility("mirror_blink")
    player:setPosition(endX, endY)
    player.invincibleTime = math.max(player.invincibleTime or 0, 0.12)
    player:aimAt(endX + dirX * 60, endY + dirY * 60)

    self.mirrors[#self.mirrors + 1] = SpellbladeMirror:new(
        startX,
        startY,
        math.atan2(dirY, dirX),
        blinkState.mirrorDuration,
        blinkState.color
    )
    self:spawnWave(scene, startX, startY, dirX, dirY, blinkState.mirrorDamageMultiplier, {
        color = {0.72, 0.58, 1.0},
        edgeColor = {0.96, 0.9, 1.0},
        maxDistance = self:getPrimaryState(scene).maxDistance * 0.72,
    })

    if self:isAstralActive() then
        self:damageTargetsAlongSegment(scene, startX, startY, endX, endY, blinkState.pathWidth, blinkState.contactDamage)
        self:spawnWave(scene, endX, endY, dirX, dirY, 0.7, {
            color = {0.96, 0.72, 1.0},
            edgeColor = {1.0, 0.96, 1.0},
            length = self:getPrimaryState(scene).length * 0.72,
        })
    end

    if scene.resolvePlayerBlockers then
        scene:resolvePlayerBlockers()
    end
    if scene.particles then
        scene.particles:createCastBurst(startX, startY, blinkState.color, 1.1)
        scene.particles:createCastBurst(endX, endY, {0.96, 0.84, 1.0}, 1.0)
    end
    if scene.hitFreeze then
        scene:hitFreeze(0.03)
    end
    if _G.audio then
        _G.audio:playSFX("hit_light", { pitch = self:isAstralActive() and 1.22 or 1.05 })
    end

    return true
end

function SpellbladeRuntime:castArcaneSwords(scene)
    local player = scene.player
    if not player or not player:isAbilityReady("arcane_swords") then
        return false
    end

    local swordsState = self:getSwordState(scene)
    player:useAbility("arcane_swords")
    self.swords = SpellbladeArcaneSwords:new(swordsState)

    if scene.particles then
        scene.particles:createCastBurst(player.x, player.y, swordsState.color, 1.15)
    end
    if scene.screenShake then
        scene.screenShake:add(3, 0.08)
    end
    if _G.audio then
        _G.audio:playSFX("hit_light", { pitch = 1.1 })
    end

    return true
end

function SpellbladeRuntime:castPrismRift(scene)
    local player = scene.player
    if not player or not player:isAbilityReady("prism_rift") then
        return false
    end

    local riftState = self:getRiftState(scene)
    local dirX, dirY = self:getFacingDirection(scene)
    local targetX, targetY = player.x + dirX * riftState.spawnOffset, player.y + dirY * riftState.spawnOffset
    local mouseX, mouseY = scene.mouseX or targetX, scene.mouseY or targetY
    if distanceSquared(player.x, player.y, mouseX, mouseY) <= riftState.castRange * riftState.castRange then
        targetX, targetY = mouseX, mouseY
    end
    targetX, targetY = self:clampPosition(scene, targetX, targetY)

    player:useAbility("prism_rift")
    self.rifts[#self.rifts + 1] = SpellbladePrismRift:new(targetX, targetY, riftState)

    if scene.particles then
        scene.particles:createCastBurst(targetX, targetY, riftState.color, 1.1)
    end
    if scene.screenShake then
        scene.screenShake:add(2, 0.08)
    end
    if _G.audio then
        _G.audio:playSFX("portal_open", { pitch = self:isAstralActive() and 1.1 or 0.96 })
    end

    return true
end

function SpellbladeRuntime:castAstralAscension(scene)
    local player = scene.player
    if not player or self:isAstralActive() or not player:isAbilityReady("astral_ascension") then
        return false
    end

    local astralState = self:getAstralState(scene)
    if not astralState.debugInstantActivation then
        return false
    end

    player:useAbility("astral_ascension")
    self.astralActive = true
    self.astralTimeRemaining = astralState.duration
    self:refreshAbilityCooldowns(scene)
    self:syncPlayerState(player)

    if scene.particles then
        scene.particles:createCastBurst(player.x, player.y, astralState.auraColor, 1.4)
        scene.particles:createUpgradeBurst(player.x, player.y, astralState.auraColor)
    end
    if scene.screenShake then
        scene.screenShake:add(5, 0.16)
    end
    if scene.hitFreeze then
        scene:hitFreeze(0.05)
    end
    if _G.audio then
        _G.audio:playSFX("hit_heavy", { pitch = 1.12 })
    end

    return true
end

function SpellbladeRuntime:updateMirrors(dt)
    for i = #self.mirrors, 1, -1 do
        local mirror = self.mirrors[i]
        mirror:update(dt)
        if not mirror:isAlive() then
            table.remove(self.mirrors, i)
        end
    end
end

function SpellbladeRuntime:updateWaves(scene, dt)
    for i = #self.waves, 1, -1 do
        local wave = self.waves[i]
        wave:update(dt)

        if wave:isAlive() then
            for _, target in ipairs(self:getTargets(scene)) do
                if wave:canHit(target) then
                    local tx, ty = target:getPosition()
                    local radius = target.getSize and target:getSize() or 18
                    if wave:intersectsCircle(tx, ty, radius) then
                        wave:markHit(target)
                        self:applyDamage(scene, target, wave.damage, wave.x, wave.y, {
                            knockback = wave.knockback,
                            color = wave.color,
                            shake = 2,
                        })
                    end
                end
            end
        end

        if not wave:isAlive() then
            table.remove(self.waves, i)
        end
    end
end

function SpellbladeRuntime:updateSwords(scene, dt)
    if not self.swords or not self.swords:isAlive() then
        self.swords = nil
        return
    end

    self.swords:update(dt)
    self.swords:tickHitTimers(dt)

    local player = scene.player
    for _, sword in ipairs(self.swords:getSwordPositions(player)) do
        for _, target in ipairs(self:getTargets(scene)) do
            if self.swords:canHit(target) then
                local tx, ty = target:getPosition()
                local radius = (target.getSize and target:getSize() or 18) + self.swords.swordSize * 0.5
                if distanceSquared(sword.x, sword.y, tx, ty) <= radius * radius then
                    self.swords:markHit(target)
                    self:applyDamage(scene, target, self.swords.damage, sword.x, sword.y, {
                        knockback = 80,
                        color = self.swords.color,
                        shake = 2,
                    })
                end
            end
        end
    end

    if not self.swords:isAlive() then
        self.swords = nil
    end
end

function SpellbladeRuntime:updateRifts(scene, dt)
    for i = #self.rifts, 1, -1 do
        local rift = self.rifts[i]

        if rift:shouldPull() then
            for _, target in ipairs(self:getTargets(scene)) do
                if not target.isBoss then
                    local tx, ty = target:getPosition()
                    local distSq = distanceSquared(tx, ty, rift.x, rift.y)
                    if distSq < rift.radius * rift.radius and distSq > 4 then
                        local dist = math.sqrt(distSq)
                        local pull = math.min(dist - 2, rift.pullStrength * dt)
                        local dirX = (rift.x - tx) / dist
                        local dirY = (rift.y - ty) / dist
                        target.x = target.x + dirX * pull
                        target.y = target.y + dirY * pull
                    end
                end
            end
        end

        local collapsed = rift:update(dt)
        if collapsed then
            for _, target in ipairs(self:getTargets(scene)) do
                local tx, ty = target:getPosition()
                local radius = target.getSize and target:getSize() or 18
                local totalRadius = rift.radius + radius
                if distanceSquared(tx, ty, rift.x, rift.y) <= totalRadius * totalRadius then
                    self:applyDamage(scene, target, rift.collapseDamage, rift.x, rift.y, {
                        knockback = 120,
                        color = rift.collapseColor,
                        shake = 4,
                    })
                end
            end
            if scene.particles then
                scene.particles:createExplosion(rift.x, rift.y, rift.collapseColor)
            end
            if scene.hitFreeze then
                scene:hitFreeze(0.04)
            end
        end

        if not rift:isAlive() then
            table.remove(self.rifts, i)
        end
    end
end

function SpellbladeRuntime:update(scene, dt)
    local player = scene.player
    if not self:isActive(player) then
        return
    end

    self.primaryCooldown = math.max(0, self.primaryCooldown - dt)
    self:refreshAbilityCooldowns(scene)

    if scene.mouseX and scene.mouseY then
        player:aimAt(scene.mouseX, scene.mouseY)
    end

    if self.astralActive then
        self.astralTimeRemaining = self.astralTimeRemaining - dt
        if self.astralTimeRemaining <= 0 then
            self.astralActive = false
            self.astralTimeRemaining = 0
            self:refreshAbilityCooldowns(scene)
        end
    end

    self:updateMirrors(dt)
    self:updateRifts(scene, dt)
    self:updateSwords(scene, dt)
    self:updateWaves(scene, dt)
    self:syncPlayerState(player)

    if player:isDead() or scene.typingTestActive or scene.isDashing then
        return
    end

    if (love.mouse.isDown(1) or love.keyboard.isDown("j")) and self.primaryCooldown <= 0 then
        self:startPrimary(scene)
    end
end

function SpellbladeRuntime:keypressed(scene, key)
    if key == "space" then
        return self:castMirrorBlink(scene)
    end
    if key == "q" then
        return self:castArcaneSwords(scene)
    end
    if key == "e" then
        return self:castPrismRift(scene)
    end
    if key == "r" then
        return self:castAstralAscension(scene)
    end
    return false
end

function SpellbladeRuntime:drawGround(_scene)
    for _, mirror in ipairs(self.mirrors) do
        mirror:draw()
    end
    for _, rift in ipairs(self.rifts) do
        rift:draw()
    end
end

function SpellbladeRuntime:drawForeground(scene)
    if self.swords then
        self.swords:draw(scene.player)
    end
    for _, wave in ipairs(self.waves) do
        wave:draw()
    end
end

return SpellbladeRuntime
