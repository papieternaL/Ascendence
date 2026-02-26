-- scenes/tutorial_scene.lua
-- Phased tutorial: introduces player to each ability in a small arena.

local Player = require("entities.player")
local Arrow = require("entities.arrow")
local Slime = require("entities.slime")
local Particles = require("systems.particles")
local ScreenShake = require("systems.screen_shake")
local Camera = require("systems.camera")
local DamageNumbers = require("systems.damage_numbers")
local Config = require("data.config")

local TutorialScene = {}
TutorialScene.__index = TutorialScene

local ARENA_W = 800
local ARENA_H = 600

-- Phase definitions
local PHASES = {
    {
        id = "movement",
        title = "MOVEMENT",
        body = "Use WASD to move around the arena.",
        hint = "Move in all 4 directions to continue.",
        condition = "move_all_dirs",
    },
    {
        id = "primary",
        title = "PRIMARY ATTACK",
        body = "Your bow auto-fires at the nearest enemy.",
        hint = "Kill 2 slimes to continue.",
        condition = "kill_2",
        spawnEnemies = 3,
    },
    {
        id = "multi_shot",
        title = "MULTI SHOT (Q)",
        body = "Fires a cone of 3 arrows at the nearest enemy. Auto-casts when off cooldown.",
        hint = "Watch Multi Shot fire automatically!",
        condition = "wait_ability_fire",
        abilityId = "multi_shot",
        highlight = "Q",
        spawnEnemies = 4,
    },
    {
        id = "dash",
        title = "DASH (SPACE)",
        body = "Press SPACE to dash in your movement direction. Grants invincibility frames.",
        hint = "Press SPACE to dash!",
        condition = "press_key",
        waitKey = "space",
        highlight = "SPACE",
    },
    {
        id = "arrow_volley",
        title = "ARROW VOLLEY (E)",
        body = "Rains arrows on the largest enemy cluster. Auto-casts when off cooldown.",
        hint = "Watch Arrow Volley target a group!",
        condition = "wait_ability_fire",
        abilityId = "entangle",
        highlight = "E",
        spawnEnemies = 6,
    },
    {
        id = "frenzy",
        title = "FRENZY (R)",
        body = "Press R when fully charged to activate. Grants crit chance and move speed. Charges from combat.",
        hint = "Your Frenzy is fully charged! Press R!",
        condition = "press_key",
        waitKey = "r",
        highlight = "R",
        grantFrenzy = true,
    },
    {
        id = "complete",
        title = "TUTORIAL COMPLETE!",
        body = "You're ready to begin your ascent. Good luck!",
        hint = "Press ENTER to return to the menu.",
        condition = "press_key",
        waitKey = "return",
    },
}

function TutorialScene:new(gameState)
    local scene = {
        gameState = gameState,
        player = nil,
        particles = nil,
        screenShake = nil,
        camera = nil,
        damageNumbers = nil,
        arrows = {},
        enemies = {},
        fireCooldown = 0,
        fireRate = 0.4,
        attackRange = 350,

        -- Dash
        isDashing = false,
        dashTime = 0,
        dashDirX = 0,
        dashDirY = 0,
        dashDuration = 0.2,
        dashSpeed = 800,
        dashCooldown = 0,

        -- Tutorial state
        currentPhase = 1,
        phaseTimer = 0,
        phaseComplete = false,
        killCount = 0,
        movedDirs = {},
        abilityFiredThisPhase = false,
        keyPressedThisPhase = false,

        -- Frenzy (simplified for tutorial)
        frenzyCharge = 0,
        frenzyChargeMax = 100,
        frenzyActive = false,
    }
    setmetatable(scene, TutorialScene)
    return scene
end

function TutorialScene:load()
    self.player = Player:new(ARENA_W / 2, ARENA_H / 2)
    self.player.maxHealth = 999
    self.player.health = 999

    self.particles = Particles:new()
    self.screenShake = ScreenShake:new()
    self.camera = Camera:new(0, 0, ARENA_W, ARENA_H)
    self.damageNumbers = DamageNumbers:new()

    self.player.abilities.frenzy.charge = 0
    self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax

    self:startPhase(1)
end

function TutorialScene:startPhase(idx)
    self.currentPhase = idx
    self.phaseTimer = 0
    self.phaseComplete = false
    self.killCount = 0
    self.abilityFiredThisPhase = false
    self.keyPressedThisPhase = false

    local phase = PHASES[idx]
    if not phase then return end

    if phase.spawnEnemies then
        self.enemies = {}
        for i = 1, phase.spawnEnemies do
            local angle = (i / phase.spawnEnemies) * math.pi * 2
            local dist = 150 + math.random(0, 80)
            local sx = ARENA_W / 2 + math.cos(angle) * dist
            local sy = ARENA_H / 2 + math.sin(angle) * dist
            local slime = Slime:new(sx, sy)
            slime.health = 30
            slime.maxHealth = 30
            slime.damage = 0
            slime.speed = 15
            table.insert(self.enemies, slime)
        end
    end

    if phase.grantFrenzy then
        self.frenzyCharge = self.frenzyChargeMax
        self.player.abilities.frenzy.charge = self.frenzyChargeMax
    end
end

function TutorialScene:update(dt)
    dt = math.min(dt, 1 / 30)

    self.phaseTimer = self.phaseTimer + dt
    self.particles:update(dt)
    self.screenShake:update(dt)
    if self.damageNumbers then self.damageNumbers:update(dt) end

    if self.camera and self.player then
        self.camera:update(dt, self.player.x, self.player.y)
    end

    -- Dash
    self.dashCooldown = math.max(0, self.dashCooldown - dt)
    if self.isDashing then
        self.dashTime = self.dashTime - dt
        if self.dashTime <= 0 then
            self.isDashing = false
        else
            self.player.x = self.player.x + self.dashDirX * self.dashSpeed * dt
            self.player.y = self.player.y + self.dashDirY * self.dashSpeed * dt
            self.particles:createDashTrail(self.player.x, self.player.y)
        end
    end

    self.player.isDashing = self.isDashing
    self.player:update(dt)

    -- Clamp to arena
    self.player.x = math.max(self.player.size, math.min(ARENA_W - self.player.size, self.player.x))
    self.player.y = math.max(self.player.size, math.min(ARENA_H - self.player.size, self.player.y))

    -- Track movement directions
    if love.keyboard.isDown("w") then self.movedDirs["w"] = true end
    if love.keyboard.isDown("a") then self.movedDirs["a"] = true end
    if love.keyboard.isDown("s") then self.movedDirs["s"] = true end
    if love.keyboard.isDown("d") then self.movedDirs["d"] = true end

    -- Update cooldowns
    self.fireCooldown = math.max(0, self.fireCooldown - dt)

    -- Frenzy charge display
    self.player.abilities.frenzy.charge = math.floor(self.frenzyCharge)
    self.player.abilities.frenzy.chargeMax = self.frenzyChargeMax

    -- Auto-fire primary at nearest enemy
    local px, py = self.player:getPosition()
    local nearest, nearDist = nil, self.attackRange
    for _, e in ipairs(self.enemies) do
        if e.isAlive then
            local ex, ey = e:getPosition()
            local d = math.sqrt((px - ex)^2 + (py - ey)^2)
            if d < nearDist then
                nearest = e
                nearDist = d
            end
        end
    end

    if nearest then
        local ex, ey = nearest:getPosition()
        self.player:aimAt(ex, ey)
        if self.fireCooldown <= 0 and not self.isDashing then
            local sx, sy = self.player:getBowTip()
            local arrow = Arrow:new(sx, sy, ex, ey, { damage = 15, kind = "primary", knockback = 100 })
            table.insert(self.arrows, arrow)
            self.fireCooldown = self.fireRate
            if self.player.triggerBowRecoil then self.player:triggerBowRecoil() end
        end
    end

    -- Multi Shot auto-cast (phase 3+)
    if self.currentPhase >= 3 and self.player:isAbilityReady("multi_shot") and nearest and not self.isDashing then
        local ex, ey = nearest:getPosition()
        self.player:useAbility("multi_shot")
        self.abilityFiredThisPhase = true
        local sx, sy = self.player:getBowTip()
        local baseAngle = math.atan2(ey - sy, ex - sx)
        local spread = math.rad(15)
        for off = -1, 1 do
            local a = baseAngle + off * spread / 2
            local tx = sx + math.cos(a) * 400
            local ty = sy + math.sin(a) * 400
            table.insert(self.arrows, Arrow:new(sx, sy, tx, ty, { damage = 15, kind = "multi_shot", knockback = 80 }))
        end
        self.screenShake:add(2, 0.08)
    end

    -- Arrow Volley auto-cast (phase 5+) — simplified visual
    if self.currentPhase >= 5 and self.player:isAbilityReady("entangle") and nearest and not self.isDashing then
        self.player:useAbility("entangle")
        self.abilityFiredThisPhase = true
        local ex, ey = nearest:getPosition()
        for i = 1, 8 do
            local a = (i / 8) * math.pi * 2
            local ox = ex + math.cos(a) * 30
            local oy = ey + math.sin(a) * 30
            table.insert(self.arrows, Arrow:new(ox, oy - 100, ox, oy, { damage = 8, kind = "entangle", knockback = 40 }))
        end
        self.screenShake:add(3, 0.12)
    end

    -- Update arrows + collision
    for i = #self.arrows, 1, -1 do
        local arrow = self.arrows[i]
        arrow:update(dt)
        local ax, ay = arrow:getPosition()
        local hit = false
        for _, e in ipairs(self.enemies) do
            if e.isAlive then
                local ex, ey = e:getPosition()
                local dx = ax - ex
                local dy = ay - ey
                local sumR = e:getSize() + arrow:getSize()
                if dx * dx + dy * dy < sumR * sumR and arrow:canHit(e) then
                    arrow:markHit(e)
                    local died = e:takeDamage(arrow.damage)
                    self.particles:createHitSpark(ex, ey, {1, 1, 0.6})
                    if self.damageNumbers then
                        self.damageNumbers:add(ex, ey - e:getSize(), arrow.damage, {})
                    end
                    if died then
                        self.killCount = self.killCount + 1
                        self.particles:createExplosion(ex, ey, {0.3, 0.6, 0.3})
                        self.screenShake:add(4, 0.15)
                    end
                    if not arrow:consumePierce() then hit = true end
                    break
                end
            end
        end
        if hit or arrow:isExpired() then
            table.remove(self.arrows, i)
        end
    end

    -- Update enemies
    for _, e in ipairs(self.enemies) do
        if e.isAlive then e:update(dt, px, py) end
    end

    -- Check phase completion
    self:checkPhaseCondition()
end

function TutorialScene:checkPhaseCondition()
    local phase = PHASES[self.currentPhase]
    if not phase or self.phaseComplete then return end

    if phase.condition == "move_all_dirs" then
        if self.movedDirs["w"] and self.movedDirs["a"] and self.movedDirs["s"] and self.movedDirs["d"] then
            self:completePhase()
        end
    elseif phase.condition == "kill_2" then
        if self.killCount >= 2 then
            self:completePhase()
        end
    elseif phase.condition == "wait_ability_fire" then
        if self.abilityFiredThisPhase and self.phaseTimer > 2.0 then
            self:completePhase()
        end
    elseif phase.condition == "press_key" then
        if self.keyPressedThisPhase then
            self:completePhase()
        end
    end
end

function TutorialScene:completePhase()
    self.phaseComplete = true
    local next = self.currentPhase + 1
    if next <= #PHASES then
        self:startPhase(next)
    end
end

function TutorialScene:draw()
    if self.camera then self.camera:attach() end

    local shakeX, shakeY = self.screenShake:getOffset()
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)

    -- Arena floor
    love.graphics.setColor(0.12, 0.18, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, ARENA_W, ARENA_H)
    -- Arena border
    love.graphics.setColor(0.3, 0.4, 0.3, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 0, 0, ARENA_W, ARENA_H, 4, 4)
    love.graphics.setLineWidth(1)

    -- Draw enemies
    for _, e in ipairs(self.enemies) do
        if e.isAlive then e:draw() end
    end

    -- Draw player
    if self.player then
        if self.isDashing then love.graphics.setColor(1, 1, 1, 0.3) end
        self.player:draw()
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Arrows
    for _, arrow in ipairs(self.arrows) do arrow:draw() end

    -- Damage numbers
    if self.damageNumbers then self.damageNumbers:draw() end

    -- Particles
    self.particles:draw()

    love.graphics.pop()
    if self.camera then self.camera:detach() end

    -- Draw tutorial HUD (screen space)
    self:drawTutorialHUD()
    self:drawBottomHUD()
end

function TutorialScene:drawTutorialHUD()
    local w = love.graphics.getWidth()
    local phase = PHASES[self.currentPhase]
    if not phase then return end

    local titleFont = _G.PixelFonts and _G.PixelFonts.header or love.graphics.getFont()
    local bodyFont = _G.PixelFonts and _G.PixelFonts.uiSmall or love.graphics.getFont()
    local hintFont = _G.PixelFonts and _G.PixelFonts.uiTiny or bodyFont

    -- Top panel
    local panelW = 600
    local panelH = 90
    local panelX = (w - panelW) / 2
    local panelY = 20

    love.graphics.setColor(0.04, 0.04, 0.08, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setColor(0.5, 0.7, 1.0, 0.5)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Phase counter
    love.graphics.setFont(hintFont)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    local counter = string.format("PHASE %d/%d", self.currentPhase, #PHASES)
    love.graphics.print(counter, panelX + 10, panelY + 6)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.9, 0.6, 1)
    local tw = titleFont:getWidth(phase.title)
    love.graphics.print(phase.title, w / 2 - tw / 2, panelY + 8)

    -- Body text
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    local bw = bodyFont:getWidth(phase.body)
    love.graphics.print(phase.body, w / 2 - bw / 2, panelY + 38)

    -- Hint (pulsing)
    love.graphics.setFont(hintFont)
    local pulse = 0.6 + 0.4 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(0.4, 0.8, 1.0, pulse)
    local hw = hintFont:getWidth(phase.hint)
    love.graphics.print(phase.hint, w / 2 - hw / 2, panelY + 62)

    -- Highlight indicator on the relevant ability diamond
    if phase.highlight then
        self:drawAbilityHighlight(phase.highlight)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function TutorialScene:drawAbilityHighlight(key)
    if not self.player then return end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local diamondR = 28
    local diamondSpacing = 76
    local numAbilities = #self.player.abilityOrder
    local abilitiesWidth = (numAbilities - 1) * diamondSpacing
    local startX = w / 2 - abilitiesWidth / 2

    for i, abilityId in ipairs(self.player.abilityOrder) do
        local ability = self.player.abilities[abilityId]
        if ability and ability.key == key then
            local cx = startX + (i - 1) * diamondSpacing
            local cy = h - 110 - 8 + 14 + 18 + 10 + diamondR + 2
            local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 5)
            love.graphics.setColor(1, 0.9, 0.3, 0.3 * pulse)
            love.graphics.circle("fill", cx, cy, diamondR + 14)
            love.graphics.setColor(1, 0.9, 0.3, 0.7 * pulse)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", cx, cy, diamondR + 10)
            love.graphics.setLineWidth(1)
            -- Arrow pointing at diamond
            love.graphics.setColor(1, 0.9, 0.3, pulse)
            local arrowY = cy - diamondR - 20
            love.graphics.polygon("fill", cx, arrowY + 8, cx - 6, arrowY, cx + 6, arrowY)
            break
        end
    end
end

function TutorialScene:drawBottomHUD()
    if self.player then
        drawBottomHUD(self.player)
    end
end

function TutorialScene:keypressed(key)
    local phase = PHASES[self.currentPhase]

    if phase and phase.condition == "press_key" and key == phase.waitKey then
        self.keyPressedThisPhase = true

        if key == "space" then
            self:startDash()
        elseif key == "r" and self.frenzyCharge >= self.frenzyChargeMax then
            self.frenzyCharge = 0
            self.frenzyActive = true
            self.screenShake:add(4, 0.15)
            if self.player then
                local px, py = self.player:getPosition()
                self.particles:createFrenzyBurst(px, py)
            end
        end
    elseif key == "space" then
        self:startDash()
    end

    if phase and phase.id == "complete" and key == "return" then
        self.gameState:reset()
    end
end

function TutorialScene:startDash()
    if self.dashCooldown > 0 or self.isDashing then return end
    self.isDashing = true
    self.dashTime = self.dashDuration
    self.dashCooldown = self.player.abilities.dash.cooldown
    self.player.abilities.dash.currentCooldown = self.player.abilities.dash.cooldown
    self.player.invincibleTime = self.dashDuration

    local dx, dy = 0, 0
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        self.dashDirX = dx / len
        self.dashDirY = dy / len
    else
        self.dashDirX = math.cos(self.player:getBowAngle())
        self.dashDirY = math.sin(self.player:getBowAngle())
    end
    self.screenShake:add(2, 0.1)
end

function TutorialScene:mousepressed(x, y, button) end
function TutorialScene:mousemoved(x, y) end

return TutorialScene
