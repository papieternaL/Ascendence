-- Menu UI System
local Menu = {}
Menu.__index = Menu

local Palette = {
    title = {0.95, 0.80, 0.52, 1},
    subtitle = {0.76, 0.70, 0.62, 0.95},
    text = {0.90, 0.92, 0.96, 1},
    section = {0.72, 0.64, 0.50, 0.9},
    panelBg = {0.06, 0.08, 0.14, 0.96},
    panelBorder = {0.42, 0.50, 0.68, 1},
    sliderFill = {0.45, 0.92, 0.95, 1},
    sliderFillSelected = {1.0, 0.82, 0.46, 1},
}

local CHARACTER_CLASSES = {"ARCHER", "WIZARD", "KNIGHT"}

local SETTINGS_SECTION_TEMPLATES = {
    {
        title = "AUDIO",
        column = 1,
        items = {
            { kind = "slider", id = "master_volume", label = "Master" },
            { kind = "slider", id = "music_volume", label = "Music" },
            { kind = "slider", id = "sfx_volume", label = "Sound" },
        },
    },
    {
        title = "GRAPHICS",
        column = 1,
        items = {
            { kind = "slider", id = "screen_shake", label = "Shake" },
            { kind = "slider", id = "brightness", label = "Brightness" },
            { kind = "toggle", id = "fullscreen", label = "Fullscreen" },
            { kind = "toggle", id = "vsync", label = "VSync" },
        },
    },
    {
        title = "GAMEPLAY",
        column = 2,
        items = {
            { kind = "toggle", id = "reduced_flashes", label = "Reduced Flashes" },
            { kind = "toggle", id = "show_damage_numbers", label = "Damage Numbers" },
            { kind = "toggle", id = "show_fps", label = "FPS Counter" },
        },
    },
    {
        title = "KEYBINDS",
        column = 2,
        items = {
            { kind = "keybind", id = "dash", label = "Dash" },
            { kind = "keybind", id = "multi_shot", label = "Multi Shot" },
            { kind = "keybind", id = "arrow_volley", label = "Arrow Volley" },
            { kind = "keybind", id = "frenzy", label = "Frenzy" },
        },
    },
}

local function countSettingsItems()
    local count = 1 -- Back button
    for _, section in ipairs(SETTINGS_SECTION_TEMPLATES) do
        count = count + #section.items
    end
    return count
end

local SETTINGS_ITEM_COUNT = countSettingsItems()

function Menu:new(gameState)
    local menu = {
        gameState = gameState,
        -- Button states
        hoveredButton = nil,
        selectedIndex = 1,
        hoveredSkillIndex = nil,
        -- Animation
        titleBob = 0,
        titleBobSpeed = 2,
        particleTime = 0,
        particles = {},
        -- Fonts (will be set in init)
        titleFont = nil,
        headerFont = nil,
        bodyFont = nil,
        smallFont = nil,
        -- Keybind rebinding state
        rebindingIndex = nil,
        -- Visual layer assets for cosmic-style menus
        visual = {
            bgPanX = 0,
            bgPanY = 0,
            bgRot = 0,
        },
    }
    setmetatable(menu, Menu)
    menu:init()
    return menu
end

function Menu:init()
    local fontNarrow = "assets/Other/Fonts/Kenney Future Square.ttf"
    local fontBold   = "assets/Other/Fonts/Kenney Bold.ttf"
    local function loadFont(path, size)
        local ok, f = pcall(love.graphics.newFont, path, size)
        if ok then
            f:setFilter("linear", "linear")
            return f
        end
        f = love.graphics.newFont(size)
        f:setFilter("linear", "linear")
        return f
    end
    self.titleFont  = loadFont(fontBold, 50)
    self.headerFont = loadFont(fontBold, 32)
    self.bodyFont   = loadFont(fontNarrow, 20)
    self.smallFont  = loadFont(fontNarrow, 15)
    
    -- Initialize floating particles
    for i = 1, 30 do
        table.insert(self.particles, {
            x = math.random() * love.graphics.getWidth(),
            y = math.random() * love.graphics.getHeight(),
            speed = math.random() * 20 + 10,
            size = math.random() * 3 + 1,
            alpha = math.random() * 0.5 + 0.2
        })
    end

    -- Optional menu art pass assets (falls back to procedural if missing)
    local function safeImage(path)
        if love.filesystem.getInfo(path) then
            return love.graphics.newImage(path)
        end
        return nil
    end

    self.visual.background = safeImage("assets/ui/backgrounds/cosmic_space_ripple.png")
    self.visual.titleImage = safeImage("assets/ui/menu/title_ascendence.png")
    self.visual.menuButtonImage = safeImage("assets/ui/menu/button_main.png")
    self.visual.settingsFrameImage = safeImage("assets/ui/settings/settings_frame.png")
    self.visual.backButtonImage = safeImage("assets/ui/settings/button_back.png")
    self.visual.heroArt = {
        archerSprite = safeImage("assets/Archer/spr_ArcherIdle_strip_NoBkg.png"),
        bow = safeImage("assets/2D assets/Scribble Dungeons/PNG/Double (128px)/Items/weapon_bow.png"),
        staff = safeImage("assets/2D assets/Scribble Dungeons/PNG/Double (128px)/Items/weapon_staff.png"),
        sword = safeImage("assets/2D assets/Scribble Dungeons/PNG/Double (128px)/Items/weapon_longsword.png"),
        shield = safeImage("assets/2D assets/Scribble Dungeons/PNG/Double (128px)/Items/shield_curved.png"),
    }

    if self.visual.heroArt.archerSprite then
        local sprite = self.visual.heroArt.archerSprite
        local frameSize = sprite:getHeight()
        self.visual.heroArt.archerQuad = love.graphics.newQuad(0, 0, frameSize, frameSize, sprite:getWidth(), sprite:getHeight())
    end
end

-- Helper: draw text with subtle shadow for readability
local function drawTextWithShadow(text, x, y)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.print(text, x + 1, y + 1)
    love.graphics.setColor(r, g, b, a)
    love.graphics.print(text, x, y)
end

-- Helper function to check if a point is inside a button
function Menu:isPointInButton(px, py, cx, cy, w, h)
    local x = cx - w/2
    local y = cy - h/2
    return px >= x and px <= x + w and py >= y and py <= y + h
end

-- Helper: check if point is inside a rectangle (left-aligned x, y)
function Menu:isPointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

function Menu:update(dt)
    -- Title bobbing animation
    self.titleBob = math.sin(love.timer.getTime() * self.titleBobSpeed) * 5

    -- Subtle cosmic drift so menu layers feel alive and integrated.
    self.visual.bgPanX = self.visual.bgPanX + dt * 3.0
    self.visual.bgPanY = self.visual.bgPanY + dt * 1.4
    self.visual.bgRot = self.visual.bgRot + dt * 0.05
    
    -- Update particles
    self.particleTime = self.particleTime + dt
    for i, p in ipairs(self.particles) do
        p.y = p.y - p.speed * dt
        if p.y < -10 then
            p.y = love.graphics.getHeight() + 10
            p.x = math.random() * love.graphics.getWidth()
        end
    end
    
    -- Update hover state for main menu button
    local state = self.gameState:getState()
    local States = self.gameState.States
    local mx, my = love.mouse.getPosition()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    if state == States.MENU then
        if self:isPointInButton(mx, my, w/2, h * 0.50, 200, 40) then
            self.selectedIndex = 1; self.hoveredButton = "begin"
        elseif self:isPointInButton(mx, my, w/2, h * 0.56, 200, 40) then
            self.selectedIndex = 2; self.hoveredButton = "tutorial"
        elseif self:isPointInButton(mx, my, w/2, h * 0.62, 200, 40) then
            self.selectedIndex = 3; self.hoveredButton = "boss_test"
        elseif self:isPointInButton(mx, my, w/2, h * 0.68, 200, 40) then
            self.selectedIndex = 4; self.hoveredButton = "settings"
        elseif self:isPointInButton(mx, my, w/2, h * 0.74, 200, 40) then
            self.selectedIndex = 5; self.hoveredButton = "quit"
        else
            self.hoveredButton = nil
        end
    elseif state == States.SETTINGS and not self.rebindingIndex then
        local L = self:getSettingsLayout(w, h)
        local hoveredItem = self:getSettingsItemAtPoint(L, mx, my)
        if hoveredItem then
            self.selectedIndex = hoveredItem.index
        end
    end
end

function Menu:draw()
    local state = self.gameState:getState()
    local States = self.gameState.States
    
    -- First operation: shared background for all menu-family states.
    self:drawBackground()

    -- Draw appropriate screen
    if state == States.MENU then
        self:drawMainMenu()
    elseif state == States.SETTINGS then
        self:drawSettings()
    elseif state == States.CHARACTER_SELECT then
        self:drawCharacterSelect()
    elseif state == States.BIOME_SELECT then
        self:drawBiomeSelect()
    elseif state == States.GAME_OVER then
        self:drawGameOver()
    elseif state == States.VICTORY then
        self:drawVictory()
    end
    
    -- Draw transition overlay
    if self.gameState.transitionAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.gameState.transitionAlpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

function Menu:drawBackground()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    -- Preferred cosmic sheet if available.
    local bg = self.visual.background
    if bg then
        local bw, bh = bg:getWidth(), bg:getHeight()
        local sx = (w / bw) * 1.08
        local sy = (h / bh) * 1.08

        love.graphics.push()
        love.graphics.translate(w * 0.5, h * 0.5)
        love.graphics.rotate(math.sin(self.visual.bgRot) * 0.012)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            bg,
            -w * 0.5 - (self.visual.bgPanX % 22),
            -h * 0.5 - (self.visual.bgPanY % 14),
            0,
            sx,
            sy
        )
        love.graphics.pop()
    else
        -- Dark gradient fallback
        love.graphics.setColor(0.02, 0.02, 0.05, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
    
    -- Radial gradient overlay
    for i = 10, 1, -1 do
        local alpha = 0.02 * i
        local radius = (w * 0.4) * (i / 10)
        love.graphics.setColor(0.08, 0.12, 0.18, alpha)
        love.graphics.circle("fill", w/2, h/2, radius)
    end
    
    -- Floating ember particles
    for i, p in ipairs(self.particles) do
        local glow = (math.sin(self.particleTime * 2 + i) + 1) / 2
        love.graphics.setColor(0.45 + glow * 0.25, 0.95, 0.92, p.alpha * (0.45 + glow * 0.45))
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

function Menu:drawMainMenu()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local v = self.visual
    
    -- Title
    love.graphics.setFont(self.titleFont)
    local title = "ASCENDENCE"
    local titleW = self.titleFont:getWidth(title)
    
    -- Title glow
    for i = 3, 1, -1 do
        love.graphics.setColor(0.95, 0.75, 0.45, 0.1 * i)
        love.graphics.print(title, w/2 - titleW/2 - i, h * 0.25 + self.titleBob - i)
    end
    
    -- Main title image (fallback to text)
    if v.titleImage then
        local img = v.titleImage
        local tw, th = img:getWidth(), img:getHeight()
        local x = w * 0.5 - tw * 0.5
        local y = h * 0.20 + self.titleBob
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, x, y)
    else
        love.graphics.setColor(Palette.title)
        drawTextWithShadow(title, w/2 - titleW/2, h * 0.25 + self.titleBob)
    end
    
    -- Menu buttons
    local labels = {"BEGIN TRIAL", "TUTORIAL", "BOSS TEST", "SETTINGS", "QUIT"}
    local startY = h * 0.50
    local stepY = h * 0.06
    for i, label in ipairs(labels) do
        local y = startY + (i - 1) * stepY
        local selected = self.selectedIndex == i
        if v.menuButtonImage then
            local img = v.menuButtonImage
            local iw, ih = img:getWidth(), img:getHeight()
            local x = w * 0.5 - iw * 0.5
            love.graphics.setColor(1, 1, 1, selected and 1 or 0.95)
            love.graphics.draw(img, x, y - ih * 0.5)

            if selected then
                love.graphics.setBlendMode("add", "alphamultiply")
                love.graphics.setColor(0.60, 1.0, 0.95, 0.16)
                love.graphics.rectangle("fill", x, y - ih * 0.5, iw, ih, 10, 10)
                love.graphics.setBlendMode("alpha")
            end

            love.graphics.setFont(self.bodyFont)
            love.graphics.setColor(Palette.title)
            drawTextWithShadow(label, w * 0.5 - self.bodyFont:getWidth(label) * 0.5, y - self.bodyFont:getHeight() * 0.32)
        else
            self:drawButton(label, w/2, y, 200, 40, selected)
        end
    end
    
    -- Instructions
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.subtitle)
    local instr = "Press ENTER or Click to Continue"
    local instrW = self.smallFont:getWidth(instr)
    drawTextWithShadow(instr, w/2 - instrW/2, h * 0.85)
end

function Menu:drawSlider(label, value, labelX, controlX, y, width, isSelected)
    local clamped = math.max(0, math.min(1, value or 0))
    local barY = y + 6

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.text)
    drawTextWithShadow(label, labelX, y + 1)

    love.graphics.setColor(0.15, 0.18, 0.25, 0.98)
    love.graphics.rectangle("fill", controlX, barY, width, 16, 6, 6)

    local fillW = math.floor((width - 4) * clamped)
    if isSelected then
        love.graphics.setColor(Palette.sliderFillSelected)
    else
        love.graphics.setColor(Palette.sliderFill)
    end
    love.graphics.rectangle("fill", controlX + 2, barY + 2, fillW, 12, 5, 5)

    love.graphics.setColor(Palette.text)
    drawTextWithShadow(string.format("%d%%", math.floor(clamped * 100)), controlX + width + 12, y + 1)
end

function Menu:getSettingsFrameRect(w, h)
    local frameW = math.min(780, w - 120)
    local frameH = math.min(680, h - 48)
    local frameX = w * 0.5 - frameW * 0.5
    local frameY = h * 0.5 - frameH * 0.5 - 8
    return frameX, frameY, frameW, frameH
end

function Menu:getSettingsValueForItem(item, settings)
    settings = settings or {}
    local audio = settings.audio or {}
    local graphics = settings.graphics or {}
    local gameplay = settings.gameplay or {}

    if item.id == "master_volume" then
        return audio.masterVolume or 1.0
    elseif item.id == "music_volume" then
        return audio.musicVolume or 0.35
    elseif item.id == "sfx_volume" then
        return audio.sfxVolume or 0.5
    elseif item.id == "screen_shake" then
        return graphics.screenShake or 1.0
    elseif item.id == "brightness" then
        return graphics.brightness or 0.58
    elseif item.id == "fullscreen" then
        return graphics.fullscreen == true
    elseif item.id == "vsync" then
        return graphics.vsync == true
    elseif item.id == "reduced_flashes" then
        return gameplay.reducedFlashes == true
    elseif item.id == "show_damage_numbers" then
        return gameplay.showDamageNumbers ~= false
    elseif item.id == "show_fps" then
        return gameplay.showFPS == true
    end
    return nil
end

function Menu:applySettingsSliderValue(mgr, item, value)
    if not mgr or not item then return end
    if item.id == "master_volume" then
        mgr:setMasterVolume(value)
    elseif item.id == "music_volume" then
        mgr:setMusicVolume(value)
    elseif item.id == "sfx_volume" then
        mgr:setSFXVolume(value)
    elseif item.id == "screen_shake" then
        mgr:setScreenShake(value)
    elseif item.id == "brightness" then
        mgr:setBrightness(value)
    end
end

function Menu:setSettingsToggleValue(mgr, item, enabled)
    if not mgr or not item then return end
    if item.id == "fullscreen" then
        local current = mgr:get().graphics.fullscreen == true
        if current ~= enabled then
            mgr:toggleFullscreen()
        end
    elseif item.id == "vsync" then
        local current = mgr:get().graphics.vsync == true
        if current ~= enabled then
            mgr:toggleVsync()
        end
    elseif item.id == "reduced_flashes" then
        mgr:setReducedFlashes(enabled)
    elseif item.id == "show_damage_numbers" then
        mgr:setShowDamageNumbers(enabled)
    elseif item.id == "show_fps" then
        mgr:setShowFPS(enabled)
    end
end

function Menu:toggleSettingsItem(mgr, item)
    if not mgr or not item then return end
    local current = self:getSettingsValueForItem(item, mgr:get())
    self:setSettingsToggleValue(mgr, item, not current)
end

function Menu:getSettingsLayout(w, h)
    local frameX, frameY, frameW, frameH = self:getSettingsFrameRect(w, h)
    local contentX = frameX + 42
    local contentY = frameY + 104
    local contentW = frameW - 84
    local contentH = frameH - 178
    local colGap = 36
    local colW = math.floor((contentW - colGap) / 2)
    local rowH = 28
    local rowGap = 12
    local sectionGap = 18
    local headerGap = 18
    local sliderW = math.min(156, math.floor(colW * 0.48))
    local toggleW = math.min(108, math.floor(colW * 0.34))
    local columns = {
        { x = contentX, y = contentY, w = colW },
        { x = contentX + colW + colGap, y = contentY, w = colW },
    }
    local cursors = { contentY, contentY }
    local sections = {}
    local items = {}
    local index = 1

    for _, template in ipairs(SETTINGS_SECTION_TEMPLATES) do
        local column = columns[template.column]
        local sectionY = cursors[template.column]
        local rows = {}

        for rowIdx, itemTemplate in ipairs(template.items) do
            local rowY = sectionY + headerGap + (rowIdx - 1) * (rowH + rowGap)
            local controlW = itemTemplate.kind == "slider" and sliderW or toggleW
            local controlX
            local controlH
            local controlY
            if itemTemplate.kind == "slider" then
                controlX = column.x + column.w - controlW - 40
                controlH = 16
                controlY = rowY + 6
            else
                controlX = column.x + column.w - controlW
                controlH = rowH
                controlY = rowY
            end

            local item = {
                index = index,
                kind = itemTemplate.kind,
                id = itemTemplate.id,
                label = itemTemplate.label,
                hitX = column.x,
                hitY = rowY,
                hitW = column.w,
                hitH = rowH,
                labelX = column.x,
                controlX = controlX,
                controlY = controlY,
                controlW = controlW,
                controlH = controlH,
                y = rowY,
            }
            rows[#rows + 1] = item
            items[index] = item
            index = index + 1
        end

        sections[#sections + 1] = {
            title = template.title,
            x = column.x,
            y = sectionY,
            rows = rows,
        }

        cursors[template.column] = sectionY + headerGap + (#rows * rowH) + math.max(0, (#rows - 1) * rowGap) + sectionGap
    end

    local backW, backH = 176, 36
    if self.visual and self.visual.backButtonImage then
        backW = self.visual.backButtonImage:getWidth()
        backH = self.visual.backButtonImage:getHeight()
    end
    local backCx = frameX + frameW * 0.5
    local backCy = frameY + frameH - 52
    items[index] = {
        index = index,
        kind = "back",
        id = "back",
        hitX = backCx - backW * 0.5,
        hitY = backCy - backH * 0.5,
        hitW = backW,
        hitH = backH,
    }

    return {
        frameX = frameX,
        frameY = frameY,
        frameW = frameW,
        frameH = frameH,
        contentX = contentX,
        contentY = contentY,
        contentW = contentW,
        contentH = contentH,
        sections = sections,
        items = items,
        backCx = backCx,
        backCy = backCy,
        backW = backW,
        backH = backH,
    }
end

function Menu:getSettingsItemAtPoint(layout, px, py)
    for _, item in ipairs(layout.items) do
        if self:isPointInRect(px, py, item.hitX, item.hitY, item.hitW, item.hitH) then
            return item
        end
    end
    return nil
end

function Menu:drawSettings()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local v = self.visual
    local L = self:getSettingsLayout(w, h)
    local frameX, frameY = L.frameX, L.frameY
    local frameW, frameH = L.frameW, L.frameH

    if v.settingsFrameImage then
        local fw, fh = v.settingsFrameImage:getWidth(), v.settingsFrameImage:getHeight()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(v.settingsFrameImage, frameX, frameY, 0, frameW / fw, frameH / fh)
    else
        love.graphics.setColor(Palette.panelBg)
        love.graphics.rectangle("fill", frameX, frameY, frameW, frameH, 16, 16)
        love.graphics.setColor(Palette.panelBorder)
        love.graphics.rectangle("line", frameX, frameY, frameW, frameH, 16, 16)
    end

    love.graphics.setFont(self.headerFont)
    love.graphics.setColor(Palette.title)
    local title = "SETTINGS"
    drawTextWithShadow(title, w / 2 - self.headerFont:getWidth(title) / 2, frameY + 26)

    local mgr = _G.settings
    local settings = mgr and mgr:get() or {}

    for _, section in ipairs(L.sections) do
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(Palette.section)
        drawTextWithShadow(section.title, section.x, section.y)

        for _, item in ipairs(section.rows) do
            local isSelected = self.selectedIndex == item.index
            if item.kind == "slider" then
                self:drawSlider(
                    item.label,
                    self:getSettingsValueForItem(item, settings),
                    item.labelX,
                    item.controlX,
                    item.y,
                    item.controlW,
                    isSelected
                )
            elseif item.kind == "toggle" then
                self:drawToggle(
                    item.label,
                    self:getSettingsValueForItem(item, settings),
                    item.labelX,
                    item.controlX,
                    item.y,
                    item.controlW,
                    isSelected
                )
            elseif item.kind == "keybind" then
                local key = mgr and mgr:getKeybind(item.id) or item.id
                self:drawKeybindRow(
                    item.label,
                    key,
                    item.labelX,
                    item.controlX,
                    item.y,
                    item.controlW,
                    isSelected,
                    self.rebindingIndex == item.index
                )
            end
        end
    end

    if v.backButtonImage then
        local img = v.backButtonImage
        local iw, ih = img:getWidth(), img:getHeight()
        local bx, by = L.backCx - iw * 0.5, L.backCy - ih * 0.5
        local isBackSelected = self.selectedIndex == SETTINGS_ITEM_COUNT
        love.graphics.setColor(1, 1, 1, isBackSelected and 1 or 0.96)
        love.graphics.draw(img, bx, by)
        if isBackSelected then
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.setColor(0.90, 0.72, 0.36, 0.12)
            love.graphics.rectangle("fill", bx, by, iw, ih, 8, 8)
            love.graphics.setBlendMode("alpha")
        end
        love.graphics.setFont(self.bodyFont)
        love.graphics.setColor(Palette.title)
        drawTextWithShadow("BACK", w * 0.5 - self.bodyFont:getWidth("BACK") * 0.5, by + ih * 0.25)
    else
        self:drawButton("BACK", L.backCx, L.backCy, L.backW, L.backH, self.selectedIndex == SETTINGS_ITEM_COUNT)
    end

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.subtitle)
    local hint = self.rebindingIndex and "Press any key to bind..." or "UP/DOWN: select  LEFT/RIGHT: adjust  ENTER: toggle/rebind"
    local hw = self.smallFont:getWidth(hint)
    drawTextWithShadow(hint, w / 2 - hw / 2, frameY + frameH + 12)
end

function Menu:drawToggle(label, value, labelX, controlX, y, width, isSelected)
    local f = self.smallFont or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.setColor(Palette.text)
    drawTextWithShadow(label, labelX, y + 1)

    love.graphics.setColor(0.12, 0.15, 0.22, 0.98)
    love.graphics.rectangle("fill", controlX, y, width, 28, 6, 6)

    if isSelected then
        love.graphics.setColor(Palette.title)
    else
        love.graphics.setColor(Palette.panelBorder)
    end
    love.graphics.rectangle("line", controlX, y, width, 28, 6, 6)

    local valText = value and "ON" or "OFF"
    local valColor = value and {0.42, 0.92, 0.56, 1} or {0.85, 0.46, 0.46, 1}
    if isSelected then
        love.graphics.setColor(Palette.title)
    else
        love.graphics.setColor(valColor)
    end
    drawTextWithShadow(valText, controlX + width / 2 - f:getWidth(valText) / 2, y + 5)
end

function Menu:drawKeybindRow(label, key, labelX, controlX, y, width, isSelected, isBinding)
    local f = self.smallFont or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.setColor(Palette.text)
    drawTextWithShadow(label, labelX, y + 1)

    local displayKey = isBinding and "..." or string.upper(key or "?")
    love.graphics.setColor(0.12, 0.15, 0.22, 0.98)
    love.graphics.rectangle("fill", controlX, y, width, 28, 6, 6)

    if isSelected then
        love.graphics.setColor(Palette.title)
    else
        love.graphics.setColor(0.55, 0.62, 0.76, 1)
    end
    love.graphics.rectangle("line", controlX, y, width, 28, 6, 6)
    drawTextWithShadow(displayKey, controlX + width / 2 - f:getWidth(displayKey) / 2, y + 5)
end

function Menu:getCharacterSelectLayout(w, h)
    local panelX = math.floor(w * 0.06)
    local panelY = 102
    local panelW = w - panelX * 2
    local panelH = h - panelY - 58
    local pad = 24
    local selectorH = 112
    local portraitW = math.floor(panelW * 0.30)
    local portraitX = panelX + pad
    local portraitY = panelY + pad
    local portraitH = panelH - selectorH - pad * 3
    local infoX = portraitX + portraitW + 28
    local infoY = portraitY
    local infoW = panelX + panelW - pad - infoX
    local skillY = infoY + 200
    local skillGap = 12
    local skillW = math.floor((infoW - skillGap * 3) / 4)
    local skillH = 60
    local tooltipY = skillY + skillH + 18
    local selectorY = panelY + panelH - selectorH - pad
    local tooltipH = selectorY - 18 - tooltipY
    local confirmW = 208
    local confirmH = 54
    local confirmX = panelX + panelW - pad - confirmW
    local confirmY = selectorY + selectorH - confirmH
    local cardGap = 16
    local cardAreaX = panelX + pad
    local cardAreaW = confirmX - 20 - cardAreaX
    local cardW = math.floor((cardAreaW - cardGap * 2) / 3)
    local cardH = 92
    local cardY = selectorY + selectorH - cardH

    local cards = {}
    for i = 1, #CHARACTER_CLASSES do
        cards[i] = {
            x = cardAreaX + (i - 1) * (cardW + cardGap),
            y = cardY,
            w = cardW,
            h = cardH,
        }
    end

    local skillRects = {}
    for i = 1, 4 do
        skillRects[i] = {
            x = infoX + (i - 1) * (skillW + skillGap),
            y = skillY,
            w = skillW,
            h = skillH,
        }
    end

    return {
        panelX = panelX,
        panelY = panelY,
        panelW = panelW,
        panelH = panelH,
        portraitX = portraitX,
        portraitY = portraitY,
        portraitW = portraitW,
        portraitH = portraitH,
        infoX = infoX,
        infoY = infoY,
        infoW = infoW,
        selectorY = selectorY,
        selectorH = selectorH,
        cards = cards,
        skillRects = skillRects,
        tooltipX = infoX,
        tooltipY = tooltipY,
        tooltipW = infoW,
        tooltipH = tooltipH,
        confirmX = confirmX,
        confirmY = confirmY,
        confirmW = confirmW,
        confirmH = confirmH,
    }
end

function Menu:setSelectedCharacterIndex(index)
    local clamped = math.max(1, math.min(#CHARACTER_CLASSES, index))
    if self.selectedIndex ~= clamped then
        self.hoveredSkillIndex = 1
    end
    self.selectedIndex = clamped
end

function Menu:getSelectedCharacterKey()
    return CHARACTER_CLASSES[math.max(1, math.min(#CHARACTER_CLASSES, self.selectedIndex))]
end

function Menu:getCharacterSkillFocusIndex(classData)
    local skills = classData and classData.skills or {}
    if #skills == 0 then
        return nil
    end
    local idx = self.hoveredSkillIndex or 1
    return math.max(1, math.min(#skills, idx))
end

function Menu:confirmSelectedCharacter()
    local States = self.gameState.States
    self.gameState:selectHeroClass(self:getSelectedCharacterKey())
    self.gameState:transitionTo(States.BIOME_SELECT)
    self.selectedIndex = 1
    self.hoveredSkillIndex = nil
end

function Menu:drawCharacterSkillIcon(skill, cx, cy, size, color)
    local r, g, b = color[1], color[2], color[3]
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.setLineWidth(2.4)
    love.graphics.setColor(r, g, b, 1)

    if skill.icon == "multi_shot" then
        for i = -1, 1 do
            local offset = i * size * 0.18
            love.graphics.line(-size * 0.26, offset, size * 0.12, offset)
            love.graphics.line(size * 0.12, offset, size * 0.30, offset - size * 0.10)
            love.graphics.line(size * 0.12, offset, size * 0.30, offset + size * 0.10)
        end
    elseif skill.icon == "dash" or skill.icon == "bulwark_rush" then
        for i = 0, 2 do
            local ox = -size * 0.28 + i * size * 0.14
            love.graphics.line(ox, size * 0.18, ox + size * 0.18, 0)
            love.graphics.line(ox, -size * 0.18, ox + size * 0.18, 0)
        end
    elseif skill.icon == "arrow_volley" then
        love.graphics.circle("line", 0, size * 0.14, size * 0.24)
        for i = -1, 1 do
            local ox = i * size * 0.16
            love.graphics.line(ox, -size * 0.30, ox, size * 0.02)
            love.graphics.line(ox, -size * 0.02, ox - size * 0.07, -size * 0.10)
            love.graphics.line(ox, -size * 0.02, ox + size * 0.07, -size * 0.10)
        end
    elseif skill.icon == "frenzy" then
        love.graphics.polygon("line",
            -size * 0.06, -size * 0.30,
            size * 0.12, -size * 0.08,
            size * 0.04, 0,
            size * 0.20, size * 0.28,
            -size * 0.02, size * 0.10,
            -size * 0.12, size * 0.30,
            -size * 0.16, size * 0.04,
            -size * 0.30, -size * 0.02
        )
    elseif skill.icon == "fireball" then
        love.graphics.circle("line", size * 0.06, 0, size * 0.20)
        love.graphics.line(-size * 0.30, 0, -size * 0.02, 0)
        love.graphics.line(-size * 0.16, -size * 0.14, 0, 0)
        love.graphics.line(-size * 0.16, size * 0.14, 0, 0)
    elseif skill.icon == "ice_nova" then
        for i = 0, 3 do
            local angle = i * math.pi / 2
            local dx = math.cos(angle) * size * 0.28
            local dy = math.sin(angle) * size * 0.28
            love.graphics.line(-dx, -dy, dx, dy)
        end
        love.graphics.circle("line", 0, 0, size * 0.08)
    elseif skill.icon == "teleport" then
        love.graphics.arc("line", "open", 0, 0, size * 0.28, math.pi * 0.2, math.pi * 1.8)
        love.graphics.line(size * 0.12, -size * 0.28, size * 0.28, -size * 0.10)
        love.graphics.line(size * 0.12, size * 0.28, size * 0.28, size * 0.10)
    elseif skill.icon == "starfall" then
        love.graphics.polygon("line",
            0, -size * 0.32,
            size * 0.10, -size * 0.08,
            size * 0.32, 0,
            size * 0.10, size * 0.08,
            0, size * 0.32,
            -size * 0.10, size * 0.08,
            -size * 0.32, 0,
            -size * 0.10, -size * 0.08
        )
    elseif skill.icon == "shield_bash" then
        love.graphics.polygon("line",
            -size * 0.18, -size * 0.26,
            size * 0.18, -size * 0.26,
            size * 0.24, -size * 0.04,
            0, size * 0.30,
            -size * 0.24, -size * 0.04
        )
        love.graphics.line(size * 0.12, 0, size * 0.32, 0)
    elseif skill.icon == "whirlwind" then
        love.graphics.arc("line", "open", -size * 0.06, 0, size * 0.24, -math.pi * 0.4, math.pi * 1.2)
        love.graphics.arc("line", "open", size * 0.08, 0, size * 0.16, math.pi * 0.2, math.pi * 1.8)
    elseif skill.icon == "fortress" then
        love.graphics.rectangle("line", -size * 0.22, -size * 0.08, size * 0.44, size * 0.28)
        love.graphics.line(-size * 0.28, size * 0.20, size * 0.28, size * 0.20)
        love.graphics.line(-size * 0.18, -size * 0.08, -size * 0.18, -size * 0.24)
        love.graphics.line(0, -size * 0.08, 0, -size * 0.28)
        love.graphics.line(size * 0.18, -size * 0.08, size * 0.18, -size * 0.24)
    else
        love.graphics.circle("line", 0, 0, size * 0.24)
    end

    love.graphics.pop()
    love.graphics.setLineWidth(1)
end

function Menu:drawCharacterPortrait(classData, x, y, w, h)
    local accent = classData.color
    local secondary = classData.secondaryColor or classData.color
    local art = self.visual.heroArt or {}

    love.graphics.setColor(0.04, 0.06, 0.12, 0.96)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.20)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, 54, 18, 18)
    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.10)
    for i = 0, 6 do
        love.graphics.rectangle("line", x + 18 + i * 18, y + h - 72, 10, 46, 4, 4)
    end
    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.18)
    love.graphics.circle("fill", x + w * 0.52, y + h * 0.42, math.min(w, h) * 0.28)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.12)
    love.graphics.circle("line", x + w * 0.52, y + h * 0.42, math.min(w, h) * 0.36)
    love.graphics.setColor(0.22, 0.28, 0.38, 0.75)
    love.graphics.rectangle("fill", x + 28, y + h - 72, w - 56, 20, 10, 10)

    local function drawItemImage(img, cx, cy, boxW, boxH, alpha, rot)
        if not img then return end
        local iw, ih = img:getWidth(), img:getHeight()
        local scale = math.min(boxW / iw, boxH / ih)
        love.graphics.setColor(1, 1, 1, alpha or 1)
        love.graphics.draw(img, cx, cy, rot or 0, scale, scale, iw * 0.5, ih * 0.5)
    end

    love.graphics.setScissor(x, y, w, h)
    if classData.id == "archer" and art.archerSprite and art.archerQuad then
        local sprite = art.archerSprite
        local frameSize = sprite:getHeight()
        local scale = math.min((w * 0.66) / frameSize, (h * 0.74) / frameSize)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sprite, art.archerQuad, x + w * 0.52, y + h * 0.56, 0, scale, scale, frameSize * 0.5, frameSize * 0.56)
        drawItemImage(art.bow, x + w * 0.66, y + h * 0.54, w * 0.26, h * 0.26, 0.92, -0.22)
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.30)
        love.graphics.line(x + w * 0.18, y + h * 0.24, x + w * 0.74, y + h * 0.18)
        love.graphics.line(x + w * 0.18, y + h * 0.30, x + w * 0.78, y + h * 0.24)
    elseif classData.id == "wizard" then
        love.graphics.setColor(0.14, 0.09, 0.24, 0.92)
        love.graphics.polygon("fill",
            x + w * 0.52, y + h * 0.22,
            x + w * 0.34, y + h * 0.52,
            x + w * 0.42, y + h * 0.80,
            x + w * 0.62, y + h * 0.80,
            x + w * 0.70, y + h * 0.52
        )
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.95)
        love.graphics.circle("fill", x + w * 0.52, y + h * 0.26, w * 0.09)
        love.graphics.setColor(accent[1], accent[2], accent[3], 1)
        love.graphics.line(x + w * 0.69, y + h * 0.38, x + w * 0.80, y + h * 0.76)
        love.graphics.circle("fill", x + w * 0.66, y + h * 0.34, w * 0.04)
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.25)
        love.graphics.circle("line", x + w * 0.66, y + h * 0.34, w * 0.12)
        drawItemImage(art.staff, x + w * 0.78, y + h * 0.56, w * 0.26, h * 0.40, 0.90, -0.18)
    else
        love.graphics.setColor(0.20, 0.23, 0.28, 0.96)
        love.graphics.circle("fill", x + w * 0.52, y + h * 0.24, w * 0.08)
        love.graphics.polygon("fill",
            x + w * 0.36, y + h * 0.48,
            x + w * 0.68, y + h * 0.48,
            x + w * 0.62, y + h * 0.78,
            x + w * 0.42, y + h * 0.78
        )
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.95)
        love.graphics.polygon("fill",
            x + w * 0.38, y + h * 0.48,
            x + w * 0.66, y + h * 0.48,
            x + w * 0.62, y + h * 0.62,
            x + w * 0.42, y + h * 0.62
        )
        love.graphics.setColor(accent[1], accent[2], accent[3], 1)
        love.graphics.line(x + w * 0.70, y + h * 0.34, x + w * 0.78, y + h * 0.76)
        love.graphics.line(x + w * 0.78, y + h * 0.76, x + w * 0.72, y + h * 0.72)
        love.graphics.line(x + w * 0.78, y + h * 0.76, x + w * 0.84, y + h * 0.72)
        drawItemImage(art.shield, x + w * 0.32, y + h * 0.58, w * 0.26, h * 0.32, 0.92, -0.10)
        drawItemImage(art.sword, x + w * 0.76, y + h * 0.58, w * 0.24, h * 0.36, 0.92, 0.16)
    end
    love.graphics.setScissor()

    love.graphics.setColor(accent[1], accent[2], accent[3], 1)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.title)
    drawTextWithShadow((classData.role or "Hero"):upper(), x + 18, y + 18)
end

function Menu:drawCharacterSelectorCard(classData, x, y, w, h, isSelected)
    local accent = classData.color
    local secondary = classData.secondaryColor or accent
    if isSelected then
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.12)
        love.graphics.rectangle("fill", x - 4, y - 4, w + 8, h + 8, 14, 14)
    end

    love.graphics.setColor(0.06, 0.09, 0.15, 0.96)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)
    love.graphics.setColor(accent[1], accent[2], accent[3], isSelected and 1 or 0.55)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)

    love.graphics.setColor(accent[1], accent[2], accent[3], 0.18)
    love.graphics.circle("fill", x + 44, y + h * 0.5, 26)

    if classData.id == "wizard" then
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.95)
        love.graphics.circle("fill", x + 44, y + h * 0.5 - 2, 9)
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.95)
        love.graphics.line(x + 44, y + h * 0.5 + 8, x + 44, y + h * 0.5 + 20)
        love.graphics.line(x + 32, y + h * 0.5 + 6, x + 56, y + h * 0.5 + 6)
    elseif classData.id == "knight" then
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.95)
        love.graphics.polygon("fill",
            x + 36, y + h * 0.5 - 12,
            x + 52, y + h * 0.5 - 12,
            x + 58, y + h * 0.5,
            x + 44, y + h * 0.5 + 16,
            x + 30, y + h * 0.5
        )
    else
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.95)
        love.graphics.line(x + 28, y + h * 0.5 + 10, x + 56, y + h * 0.5 - 4)
        love.graphics.line(x + 50, y + h * 0.5 - 16, x + 50, y + h * 0.5 + 10)
    end

    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(Palette.text)
    drawTextWithShadow(classData.name, x + 82, y + 16)
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.subtitle)
    drawTextWithShadow((classData.role or "Hero"):upper(), x + 82, y + 40)
    love.graphics.setColor(0.82, 0.86, 0.92, 0.92)
    drawTextWithShadow(string.format("HP %d   ATK %d   SPD %d", classData.baseHP, classData.baseATK, classData.baseSpeed), x + 82, y + 62)
end

function Menu:drawCharacterSelect()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local L = self:getCharacterSelectLayout(w, h)
    local classKey = self:getSelectedCharacterKey()
    local classData = self.gameState.HeroClasses[classKey]
    local accent = classData.color
    local secondary = classData.secondaryColor or accent
    local focusedSkillIndex = self:getCharacterSkillFocusIndex(classData)
    local focusedSkill = focusedSkillIndex and classData.skills[focusedSkillIndex] or nil
    local mx, my = love.mouse.getPosition()
    local confirmHovered = self:isPointInRect(mx, my, L.confirmX, L.confirmY, L.confirmW, L.confirmH)

    love.graphics.setFont(self.headerFont)
    local header = "CHOOSE YOUR HERO"
    love.graphics.setColor(Palette.title)
    drawTextWithShadow(header, w * 0.5 - self.headerFont:getWidth(header) * 0.5, 34)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.subtitle)
    local helper = "Hover skills to inspect the kit. Click a hero, then continue."
    drawTextWithShadow(helper, w * 0.5 - self.smallFont:getWidth(helper) * 0.5, 70)

    love.graphics.setColor(0.03, 0.05, 0.10, 0.95)
    love.graphics.rectangle("fill", L.panelX, L.panelY, L.panelW, L.panelH, 22, 22)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.16)
    love.graphics.rectangle("fill", L.panelX + 1, L.panelY + 1, L.panelW - 2, 70, 22, 22)
    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.10)
    love.graphics.rectangle("fill", L.panelX + 18, L.selectorY - 12, L.panelW - 36, 2)
    love.graphics.setColor(0.22, 0.30, 0.42, 1)
    love.graphics.rectangle("line", L.panelX, L.panelY, L.panelW, L.panelH, 22, 22)

    self:drawCharacterPortrait(classData, L.portraitX, L.portraitY, L.portraitW, L.portraitH)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(accent[1], accent[2], accent[3], 1)
    drawTextWithShadow((classData.role or "Hero"):upper(), L.infoX, L.infoY + 2)

    love.graphics.setFont(self.headerFont)
    love.graphics.setColor(Palette.text)
    drawTextWithShadow(classData.name:upper(), L.infoX, L.infoY + 20)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.subtitle)
    local descLines = self:wrapText(classData.description or "", L.infoW - 8)
    for i = 1, math.min(#descLines, 2) do
        drawTextWithShadow(descLines[i], L.infoX, L.infoY + 70 + (i - 1) * 18)
    end
    local loreLines = self:wrapText(classData.lore or "", L.infoW - 8)
    love.graphics.setColor(0.72, 0.80, 0.92, 0.90)
    for i = 1, math.min(#loreLines, 2) do
        drawTextWithShadow(loreLines[i], L.infoX, L.infoY + 112 + (i - 1) * 18)
    end

    local statY = L.infoY + 150
    local statGap = 12
    local statW = math.floor((L.infoW - statGap * 3) / 4)
    local stats = {
        { label = "HP", value = classData.baseHP, color = {0.92, 0.38, 0.38} },
        { label = "ATK", value = classData.baseATK, color = {0.96, 0.72, 0.34} },
        { label = "SPD", value = classData.baseSpeed, color = {0.42, 0.90, 0.96} },
        { label = "RNG", value = classData.attackRange, color = {0.74, 0.80, 0.98} },
    }
    for i, stat in ipairs(stats) do
        local sx = L.infoX + (i - 1) * (statW + statGap)
        love.graphics.setColor(0.07, 0.10, 0.17, 0.96)
        love.graphics.rectangle("fill", sx, statY, statW, 52, 10, 10)
        love.graphics.setColor(stat.color[1], stat.color[2], stat.color[3], 0.80)
        love.graphics.rectangle("line", sx, statY, statW, 52, 10, 10)
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(stat.color[1], stat.color[2], stat.color[3], 1)
        drawTextWithShadow(stat.label, sx + 12, statY + 8)
        love.graphics.setFont(self.bodyFont)
        love.graphics.setColor(Palette.text)
        drawTextWithShadow(tostring(stat.value or 0), sx + 12, statY + 24)
    end

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.section)
    drawTextWithShadow("SIGNATURE SKILLS", L.infoX, L.infoY + 196)

    for i, skill in ipairs(classData.skills or {}) do
        local rect = L.skillRects[i]
        if rect then
            local isHovered = focusedSkillIndex == i
            love.graphics.setColor(0.08, 0.11, 0.18, 0.98)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 12, 12)
            love.graphics.setColor(accent[1], accent[2], accent[3], isHovered and 1 or 0.45)
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 12, 12)
            love.graphics.setColor(accent[1], accent[2], accent[3], isHovered and 0.18 or 0.08)
            love.graphics.rectangle("fill", rect.x + 1, rect.y + 1, rect.w - 2, rect.h - 2, 12, 12)

            love.graphics.setColor(0.04, 0.06, 0.10, 0.95)
            love.graphics.circle("fill", rect.x + 28, rect.y + rect.h * 0.5, 18)
            self:drawCharacterSkillIcon(skill, rect.x + 28, rect.y + rect.h * 0.5, 24, isHovered and secondary or accent)

            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(Palette.title)
            drawTextWithShadow(skill.key, rect.x + rect.w - self.smallFont:getWidth(skill.key) - 12, rect.y + 10)
            love.graphics.setColor(Palette.text)
            drawTextWithShadow(self:truncateText(self.smallFont, skill.name, rect.w - 108), rect.x + 56, rect.y + 12)
            love.graphics.setColor(Palette.subtitle)
            drawTextWithShadow(self:truncateText(self.smallFont, skill.summary or "", rect.w - 108), rect.x + 56, rect.y + 30)
        end
    end

    if focusedSkill then
        love.graphics.setColor(0.06, 0.09, 0.15, 0.98)
        love.graphics.rectangle("fill", L.tooltipX, L.tooltipY, L.tooltipW, L.tooltipH, 14, 14)
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.68)
        love.graphics.rectangle("line", L.tooltipX, L.tooltipY, L.tooltipW, L.tooltipH, 14, 14)
        love.graphics.setColor(0.04, 0.06, 0.10, 0.94)
        love.graphics.circle("fill", L.tooltipX + 36, L.tooltipY + 36, 24)
        self:drawCharacterSkillIcon(focusedSkill, L.tooltipX + 36, L.tooltipY + 36, 30, secondary)

        love.graphics.setFont(self.bodyFont)
        love.graphics.setColor(Palette.text)
        drawTextWithShadow(focusedSkill.name, L.tooltipX + 72, L.tooltipY + 14)

        local modeText = string.upper(focusedSkill.mode or "Skill")
        local modeW = self.smallFont:getWidth(modeText) + 18
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.18)
        love.graphics.rectangle("fill", L.tooltipX + L.tooltipW - modeW - 14, L.tooltipY + 12, modeW, 24, 8, 8)
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.85)
        love.graphics.rectangle("line", L.tooltipX + L.tooltipW - modeW - 14, L.tooltipY + 12, modeW, 24, 8, 8)
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(Palette.title)
        drawTextWithShadow(modeText, L.tooltipX + L.tooltipW - modeW - 14 + 9, L.tooltipY + 17)

        love.graphics.setColor(Palette.subtitle)
        drawTextWithShadow((focusedSkill.summary or ""):upper(), L.tooltipX + 72, L.tooltipY + 40)
        love.graphics.setColor(0.86, 0.89, 0.95, 0.96)
        local skillDescLines = self:wrapText(focusedSkill.description or "", L.tooltipW - 92)
        for i = 1, math.min(#skillDescLines, 4) do
            drawTextWithShadow(skillDescLines[i], L.tooltipX + 72, L.tooltipY + 60 + (i - 1) * 18)
        end
    end

    for i, className in ipairs(CHARACTER_CLASSES) do
        self:drawCharacterSelectorCard(
            self.gameState.HeroClasses[className],
            L.cards[i].x,
            L.cards[i].y,
            L.cards[i].w,
            L.cards[i].h,
            self.selectedIndex == i
        )
    end

    love.graphics.setColor(confirmHovered and accent[1] or 0.10, confirmHovered and accent[2] or 0.16, confirmHovered and accent[3] or 0.24, 0.95)
    love.graphics.rectangle("fill", L.confirmX, L.confirmY, L.confirmW, L.confirmH, 12, 12)
    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 1)
    love.graphics.rectangle("line", L.confirmX, L.confirmY, L.confirmW, L.confirmH, 12, 12)
    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(Palette.title)
    local continueLabel = "CONTINUE"
    drawTextWithShadow(continueLabel, L.confirmX + L.confirmW * 0.5 - self.bodyFont:getWidth(continueLabel) * 0.5, L.confirmY + 15)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.65, 0.6, 0.55, 0.9)
    drawTextWithShadow("ESC to go back | ENTER to continue | Arrow keys to change hero", 20, h - 30)
end

function Menu:drawBiomeSelect()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    self:drawBackground()
    
    -- Header
    love.graphics.setFont(self.headerFont)
    local header = "SELECT YOUR DOMAIN"
    local headerW = self.headerFont:getWidth(header)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    drawTextWithShadow(header, w/2 - headerW/2, 40)
    
    -- Biome cards
    local biomes = {"DEEPWOOD", "GREY_HALLS", "ASH_CRAG"}
    local cardWidth = 220
    local cardHeight = 170
    local spacing = 28
    local totalWidth = #biomes * cardWidth + (#biomes - 1) * spacing
    local startX = w/2 - totalWidth/2
    
    for i, biomeKey in ipairs(biomes) do
        local biomeData = self.gameState.Biomes[biomeKey]
        local x = startX + (i - 1) * (cardWidth + spacing)
        local y = h/2 - cardHeight/2
        local isSelected = self.selectedIndex == i
        
        self:drawBiomeCard(biomeData, x, y, cardWidth, cardHeight, isSelected)
    end
    
    -- Instructions
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.65, 0.6, 0.55, 0.9)
    drawTextWithShadow("ESC to go back | ENTER to select | Arrow keys to navigate", 20, h - 30)
end

function Menu:drawBiomeCard(biomeData, x, y, w, h, isSelected)
    -- Card glow if selected
    if isSelected then
        for i = 3, 1, -1 do
            love.graphics.setColor(biomeData.accentColor[1], biomeData.accentColor[2], biomeData.accentColor[3], 0.15 * i)
            love.graphics.rectangle("fill", x - i * 4, y - i * 4, w + i * 8, h + i * 8, 10, 10)
        end
    end
    
    -- Card background with biome color tint
    love.graphics.setColor(biomeData.bgColor[1] * 2, biomeData.bgColor[2] * 2, biomeData.bgColor[3] * 2, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    
    -- Card border
    if isSelected then
        love.graphics.setColor(biomeData.accentColor[1], biomeData.accentColor[2], biomeData.accentColor[3], 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.3, 0.3, 0.35, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Biome name kept inside the card instead of using the oversized header font.
    local displayName = tostring(biomeData.name or "")
    local words = {}
    for word in displayName:gmatch("%S+") do
        words[#words + 1] = word
    end
    if #words == 0 then
        words[1] = displayName
    end

    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(biomeData.accentColor[1], biomeData.accentColor[2], biomeData.accentColor[3], 1)
    local nameLines = {}
    if #words >= 2 then
        nameLines[1] = words[1]
        nameLines[2] = table.concat(words, " ", 2)
    else
        nameLines[1] = displayName
    end

    local nameY = y + 18
    local nameLineH = self.bodyFont:getHeight() - 2
    for i, line in ipairs(nameLines) do
        local nameW = self.bodyFont:getWidth(line)
        drawTextWithShadow(line, x + w/2 - nameW/2, nameY + (i - 1) * nameLineH)
    end

    -- Subtitle
    love.graphics.setFont(self.smallFont)
    local subtitleY = nameY + (#nameLines * nameLineH) + 8
    local subW = self.smallFont:getWidth(biomeData.subtitle)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.print(biomeData.subtitle, x + w/2 - subW/2, subtitleY)
    
    -- Description
    love.graphics.setColor(0.72, 0.72, 0.68, 0.95)
    local descLines = self:wrapText(biomeData.description, w - 24)
    local descY = subtitleY + self.smallFont:getHeight() + 12
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        drawTextWithShadow(line, x + w/2 - lineW/2, descY + (i-1) * 18)
    end
end

function Menu:drawDifficultySelect()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    self:drawBackground()
    
    -- Header
    love.graphics.setFont(self.headerFont)
    local header = "CHOOSE YOUR TRIAL"
    local headerW = self.headerFont:getWidth(header)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    drawTextWithShadow(header, w/2 - headerW/2, 40)
    
    -- Difficulty options
    local difficulties = {"ADEPT", "VETERAN", "ASCENDANT"}
    local cardWidth = 200
    local cardHeight = 120
    local spacing = 40
    local totalWidth = #difficulties * cardWidth + (#difficulties - 1) * spacing
    local startX = w/2 - totalWidth/2
    
    local diffColors = {
        {0.4, 0.7, 0.4}, -- Green for easy
        {0.7, 0.6, 0.2}, -- Yellow for medium
        {0.8, 0.2, 0.2}  -- Red for hard
    }
    
    for i, diffKey in ipairs(difficulties) do
        local diffData = self.gameState.Difficulties[diffKey]
        local x = startX + (i - 1) * (cardWidth + spacing)
        local y = h/2 - cardHeight/2
        local isSelected = self.selectedIndex == i
        
        self:drawDifficultyCard(diffData, x, y, cardWidth, cardHeight, isSelected, diffColors[i])
    end
    
    -- Instructions
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.65, 0.6, 0.55, 0.9)
    drawTextWithShadow("ESC to go back | ENTER to begin your ascent", 20, h - 30)
end

function Menu:drawDifficultyCard(diffData, x, y, w, h, isSelected, color)
    -- Card glow if selected
    if isSelected then
        for i = 3, 1, -1 do
            love.graphics.setColor(color[1], color[2], color[3], 0.15 * i)
            love.graphics.rectangle("fill", x - i * 4, y - i * 4, w + i * 8, h + i * 8, 10, 10)
        end
    end
    
    -- Card background
    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    
    -- Card border
    if isSelected then
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.3, 0.3, 0.35, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Difficulty name
    love.graphics.setFont(self.headerFont)
    local nameW = self.headerFont:getWidth(diffData.name)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.print(diffData.name, x + w/2 - nameW/2, y + 15)
    
    -- Subtitle
    love.graphics.setFont(self.smallFont)
    local subW = self.smallFont:getWidth(diffData.subtitle)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.print(diffData.subtitle, x + w/2 - subW/2, y + 50)
    
    -- Description
    love.graphics.setColor(0.65, 0.65, 0.6, 0.95)
    local descLines = self:wrapText(diffData.description, w - 20)
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        drawTextWithShadow(line, x + w/2 - lineW/2, y + 75 + (i-1) * 18)
    end
end

function Menu:drawGameOver()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Game Over text
    love.graphics.setFont(self.titleFont)
    local text = "FALLEN"
    local textW = self.titleFont:getWidth(text)
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    drawTextWithShadow(text, w/2 - textW/2, h * 0.3)
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local sub = "Your journey ends here..."
    local subW = self.bodyFont:getWidth(sub)
    love.graphics.setColor(0.75, 0.5, 0.5, 0.95)
    drawTextWithShadow(sub, w/2 - subW/2, h * 0.3 + 60)
    
    -- Retry button
    self:drawButton("TRY AGAIN", w/2, h * 0.6, 180, 50, self.selectedIndex == 1)
    self:drawButton("MAIN MENU", w/2, h * 0.7, 180, 50, self.selectedIndex == 2)
end

function Menu:drawVictory()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Dark overlay with golden tint
    love.graphics.setColor(0.1, 0.08, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Victory text
    love.graphics.setFont(self.titleFont)
    local text = "ASCENDED"
    local textW = self.titleFont:getWidth(text)
    
    -- Golden glow
    for i = 3, 1, -1 do
        love.graphics.setColor(1, 0.8, 0.3, 0.1 * i)
        love.graphics.print(text, w/2 - textW/2 - i, h * 0.3 + self.titleBob - i)
    end
    love.graphics.setColor(1, 0.9, 0.5, 1)
    drawTextWithShadow(text, w/2 - textW/2, h * 0.3 + self.titleBob)
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local sub = "You have conquered the darkness!"
    local subW = self.bodyFont:getWidth(sub)
    love.graphics.setColor(0.85, 0.75, 0.45, 0.95)
    drawTextWithShadow(sub, w/2 - subW/2, h * 0.3 + 60)
    
    -- Menu button
    self:drawButton("MAIN MENU", w/2, h * 0.6, 180, 50, self.selectedIndex == 1)
end

function Menu:drawButton(text, cx, cy, w, h, isSelected)
    local x = cx - w/2
    local y = cy - h/2
    
    -- Button glow if selected
    if isSelected then
        for i = 3, 1, -1 do
            love.graphics.setColor(0.8, 0.6, 0.3, 0.1 * i)
            love.graphics.rectangle("fill", x - i * 3, y - i * 3, w + i * 6, h + i * 6, 6, 6)
        end
    end
    
    -- Button background
    if isSelected then
        love.graphics.setColor(0.3, 0.25, 0.15, 0.95)
    else
        love.graphics.setColor(0.15, 0.15, 0.18, 0.9)
    end
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    
    -- Button border
    if isSelected then
        love.graphics.setColor(0.9, 0.7, 0.4, 1)
        love.graphics.setLineWidth(2)
    else
        love.graphics.setColor(0.4, 0.4, 0.45, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", x, y, w, h, 6, 6)
    love.graphics.setLineWidth(1)
    
    -- Button text
    love.graphics.setFont(self.bodyFont)
    local textW = self.bodyFont:getWidth(text)
    local textH = self.bodyFont:getHeight()
    if isSelected then
        love.graphics.setColor(1, 0.9, 0.7, 1)
    else
        love.graphics.setColor(0.75, 0.75, 0.7, 1)
    end
    drawTextWithShadow(text, cx - textW/2, cy - textH/2)
end

function Menu:wrapText(text, maxWidth)
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local currentLine = ""
    for i, word in ipairs(words) do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        if self.smallFont:getWidth(testLine) <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines
end

function Menu:truncateText(font, text, maxWidth)
    text = tostring(text or "")
    if font:getWidth(text) <= maxWidth then
        return text
    end

    local truncated = text
    while #truncated > 0 and font:getWidth(truncated .. "...") > maxWidth do
        truncated = truncated:sub(1, -2)
    end

    if truncated == "" then
        return "..."
    end
    return truncated .. "..."
end

function Menu:keypressed(key)
    local state = self.gameState:getState()
    local States = self.gameState.States
    
    if state == States.MENU then
        if key == "s" then
            self.gameState:transitionTo(States.SETTINGS)
            self.selectedIndex = 1
        elseif key == "up" or key == "down" then
            if key == "up" then
                self.selectedIndex = self.selectedIndex - 1
                if self.selectedIndex < 1 then self.selectedIndex = 5 end
            else
                self.selectedIndex = self.selectedIndex + 1
                if self.selectedIndex > 5 then self.selectedIndex = 1 end
            end
        elseif key == "return" or key == "space" then
            if self.selectedIndex == 1 then
                self.gameState:transitionTo(States.CHARACTER_SELECT)
                self.selectedIndex = 1
                self.hoveredSkillIndex = 1
            elseif self.selectedIndex == 2 then
                self.gameState:selectHeroClass("ARCHER")
                self.gameState:transitionTo(States.TUTORIAL)
                self.selectedIndex = 1
            elseif self.selectedIndex == 3 then
                self.gameState:selectHeroClass("ARCHER")
                self.gameState:selectBiome("DEEPWOOD")
                self.gameState:setDefaultDifficulty()
                self.gameState:initFloor(1)
                self.gameState.bossTestMode = true
                self.gameState:transitionTo(States.PLAYING, true)
                self.selectedIndex = 1
            elseif self.selectedIndex == 4 then
                self.gameState:transitionTo(States.SETTINGS)
                self.selectedIndex = 1
            else
                love.event.quit()
            end
        end
    elseif state == States.SETTINGS then
        local mgr = _G.settings
        local step = 0.05
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local L = self:getSettingsLayout(w, h)

        -- If rebinding a key, capture the next keypress
        if self.rebindingIndex then
            local rebindItem = L.items[self.rebindingIndex]
            if key ~= "escape" then
                if rebindItem and rebindItem.kind == "keybind" and mgr then
                    mgr:setKeybind(rebindItem.id, key)
                end
            end
            self.rebindingIndex = nil
            return
        end

        if key == "up" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = SETTINGS_ITEM_COUNT end
        elseif key == "down" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > SETTINGS_ITEM_COUNT then self.selectedIndex = 1 end
        elseif key == "left" or key == "right" then
            local dir = (key == "right") and 1 or -1
            local selectedItem = L.items[self.selectedIndex]
            if mgr then
                if selectedItem and selectedItem.kind == "slider" then
                    local current = self:getSettingsValueForItem(selectedItem, mgr:get()) or 0
                    self:applySettingsSliderValue(mgr, selectedItem, current + step * dir)
                elseif selectedItem and selectedItem.kind == "toggle" then
                    self:setSettingsToggleValue(mgr, selectedItem, dir > 0)
                end
            end
        elseif key == "return" or key == "space" then
            local selectedItem = L.items[self.selectedIndex]
            if selectedItem and selectedItem.kind == "toggle" and mgr then
                self:toggleSettingsItem(mgr, selectedItem)
            elseif selectedItem and selectedItem.kind == "keybind" then
                self.rebindingIndex = self.selectedIndex
            elseif selectedItem and selectedItem.kind == "back" then
                self.rebindingIndex = nil
                self.gameState:transitionTo(States.MENU)
                self.selectedIndex = 4
            end
        elseif key == "escape" or key == "backspace" then
            self.rebindingIndex = nil
            self.gameState:transitionTo(States.MENU)
            self.selectedIndex = 4
        end
    elseif state == States.CHARACTER_SELECT then
        if key == "left" then
            local nextIndex = self.selectedIndex - 1
            if nextIndex < 1 then nextIndex = #CHARACTER_CLASSES end
            self:setSelectedCharacterIndex(nextIndex)
        elseif key == "right" then
            local nextIndex = self.selectedIndex + 1
            if nextIndex > #CHARACTER_CLASSES then nextIndex = 1 end
            self:setSelectedCharacterIndex(nextIndex)
        elseif key == "return" or key == "space" then
            self:confirmSelectedCharacter()
        elseif key == "escape" then
            self.gameState:transitionTo(States.MENU)
            self.selectedIndex = 1
            self.hoveredSkillIndex = nil
        end
    elseif state == States.BIOME_SELECT then
        local biomes = {"DEEPWOOD", "GREY_HALLS", "ASH_CRAG"}
        if key == "left" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = #biomes end
        elseif key == "right" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #biomes then self.selectedIndex = 1 end
        elseif key == "return" or key == "space" then
            self.gameState:selectBiome(biomes[self.selectedIndex])
            self.gameState:setDefaultDifficulty()
            self.gameState:initFloor(1)
            self.gameState:transitionTo(States.PLAYING)
            self.selectedIndex = 1
        elseif key == "escape" then
            self.gameState:transitionTo(States.CHARACTER_SELECT)
            self.selectedIndex = 1
        end
    elseif state == States.GAME_OVER then
        if key == "up" or key == "down" then
            self.selectedIndex = self.selectedIndex == 1 and 2 or 1
        elseif key == "return" or key == "space" then
            if self.selectedIndex == 1 then
                -- Try again - keep selections, restart floor
                self.gameState:initFloor(1)
                self.gameState:transitionTo(States.PLAYING)
            else
                -- Main menu
                self.gameState:reset()
            end
        end
    elseif state == States.VICTORY then
        if key == "return" or key == "space" then
            self.gameState:reset()
        end
    end
end

function Menu:mousepressed(x, y, button)
    if button ~= 1 then return end -- Only left click
    
    local state = self.gameState:getState()
    local States = self.gameState.States
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    if state == States.MENU then
        if self:isPointInButton(x, y, w/2, h * 0.50, 200, 40) then
            self.gameState:transitionTo(States.CHARACTER_SELECT)
            self.selectedIndex = 1
            self.hoveredSkillIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.56, 200, 40) then
            self.gameState:selectHeroClass("ARCHER")
            self.gameState:transitionTo(States.TUTORIAL)
            self.selectedIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.62, 200, 40) then
            self.gameState:selectHeroClass("ARCHER")
            self.gameState:selectBiome("DEEPWOOD")
            self.gameState:setDefaultDifficulty()
            self.gameState:initFloor(1)
            self.gameState.bossTestMode = true
            self.gameState:transitionTo(States.PLAYING, true)
            self.selectedIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.68, 200, 40) then
            self.gameState:transitionTo(States.SETTINGS)
            self.selectedIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.74, 200, 40) then
            love.event.quit()
        end
    elseif state == States.SETTINGS then
        if self.rebindingIndex then return end -- Wait for keypress when rebinding
        local mgr = _G.settings
        local L = self:getSettingsLayout(w, h)
        local hitItem = self:getSettingsItemAtPoint(L, x, y)
        if not hitItem then
            return
        end

        self.selectedIndex = hitItem.index
        if hitItem.kind == "slider" and mgr then
            if self:isPointInRect(x, y, hitItem.controlX, hitItem.controlY, hitItem.controlW, hitItem.controlH) then
                local t = math.max(0, math.min(1, (x - hitItem.controlX) / hitItem.controlW))
                self:applySettingsSliderValue(mgr, hitItem, t)
            end
            return
        end
        if hitItem.kind == "toggle" and mgr then
            self:toggleSettingsItem(mgr, hitItem)
            return
        end
        if hitItem.kind == "keybind" then
            self.rebindingIndex = hitItem.index
            return
        end
        if hitItem.kind == "back" then
            self.gameState:transitionTo(States.MENU)
            self.selectedIndex = 4
        end
    elseif state == States.CHARACTER_SELECT then
        local L = self:getCharacterSelectLayout(w, h)
        for i, rect in ipairs(L.cards) do
            if self:isPointInRect(x, y, rect.x, rect.y, rect.w, rect.h) then
                self:setSelectedCharacterIndex(i)
                return
            end
        end

        local classData = self.gameState.HeroClasses[self:getSelectedCharacterKey()]
        for i, rect in ipairs(L.skillRects) do
            if classData and classData.skills and classData.skills[i] and self:isPointInRect(x, y, rect.x, rect.y, rect.w, rect.h) then
                self.hoveredSkillIndex = i
                return
            end
        end

        if self:isPointInRect(x, y, L.confirmX, L.confirmY, L.confirmW, L.confirmH) then
            self:confirmSelectedCharacter()
            return
        end
    elseif state == States.BIOME_SELECT then
        -- Check biome cards
        local biomes = {"DEEPWOOD", "GREY_HALLS", "ASH_CRAG"}
        local cardWidth = 220
        local cardHeight = 170
        local spacing = 28
        local totalWidth = #biomes * cardWidth + (#biomes - 1) * spacing
        local startX = w/2 - totalWidth/2
        
        for i, biomeKey in ipairs(biomes) do
            local cardX = startX + (i - 1) * (cardWidth + spacing)
            local cardY = h/2 - cardHeight/2
            
            if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + cardHeight then
                self.gameState:selectBiome(biomeKey)
                self.gameState:setDefaultDifficulty()
                self.gameState:initFloor(1)
                self.gameState:transitionTo(States.PLAYING)
                self.selectedIndex = 1
                return
            end
        end
        
    elseif state == States.GAME_OVER then
        -- Check buttons
        if self:isPointInButton(x, y, w/2, h * 0.6, 180, 50) then
            -- Try again
            self.gameState:initFloor(1)
            self.gameState:transitionTo(States.PLAYING)
        elseif self:isPointInButton(x, y, w/2, h * 0.7, 180, 50) then
            -- Main menu
            self.gameState:reset()
        end
        
    elseif state == States.VICTORY then
        if self:isPointInButton(x, y, w/2, h * 0.6, 180, 50) then
            self.gameState:reset()
        end
    end
end

function Menu:mousemoved(x, y)
    -- Update hovered selection based on mouse position
    local state = self.gameState:getState()
    local States = self.gameState.States
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if state == States.SETTINGS and not self.rebindingIndex then
        local L = self:getSettingsLayout(w, h)
        local hoveredItem = self:getSettingsItemAtPoint(L, x, y)
        if hoveredItem then
            self.selectedIndex = hoveredItem.index
        end
    elseif state == States.GAME_OVER then
        if self:isPointInButton(x, y, w/2, h * 0.6, 180, 50) then
            self.selectedIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.7, 180, 50) then
            self.selectedIndex = 2
        end
    elseif state == States.VICTORY then
        if self:isPointInButton(x, y, w/2, h * 0.6, 180, 50) then
            self.selectedIndex = 1
        end
    elseif state == States.CHARACTER_SELECT then
        local L = self:getCharacterSelectLayout(w, h)
        self.hoveredSkillIndex = nil

        for i, rect in ipairs(L.cards) do
            if self:isPointInRect(x, y, rect.x, rect.y, rect.w, rect.h) then
                self:setSelectedCharacterIndex(i)
                return
            end
        end

        local classData = self.gameState.HeroClasses[self:getSelectedCharacterKey()]
        for i, rect in ipairs(L.skillRects) do
            if classData and classData.skills and classData.skills[i] and self:isPointInRect(x, y, rect.x, rect.y, rect.w, rect.h) then
                self.hoveredSkillIndex = i
                return
            end
        end
    elseif state == States.BIOME_SELECT then
        local biomes = {"DEEPWOOD", "GREY_HALLS", "ASH_CRAG"}
        local cardWidth = 220
        local cardHeight = 170
        local spacing = 28
        local totalWidth = #biomes * cardWidth + (#biomes - 1) * spacing
        local startX = w/2 - totalWidth/2
        
        for i, biomeKey in ipairs(biomes) do
            local cardX = startX + (i - 1) * (cardWidth + spacing)
            local cardY = h/2 - cardHeight/2
            
            if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + cardHeight then
                self.selectedIndex = i
                return
            end
        end
    end
end

return Menu
