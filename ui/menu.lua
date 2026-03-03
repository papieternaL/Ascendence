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

function Menu:new(gameState)
    local menu = {
        gameState = gameState,
        -- Button states
        hoveredButton = nil,
        selectedIndex = 1,
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
        local barX, barW, y0, gap, gfxY, kbY = L.barX, L.barW, L.y0, L.gap, L.gfxY, L.kbY
        local rowH = 24
        if self:isPointInRect(mx, my, barX, y0, barW, 16) then
            self.selectedIndex = 1
        elseif self:isPointInRect(mx, my, barX, y0 + gap, barW, 16) then
            self.selectedIndex = 2
        elseif self:isPointInRect(mx, my, barX, y0 + gap * 2, barW, 16) then
            self.selectedIndex = 3
        elseif self:isPointInRect(mx, my, barX, gfxY, barW, rowH) then
            self.selectedIndex = 4
        elseif self:isPointInRect(mx, my, barX, gfxY + gap, barW, rowH) then
            self.selectedIndex = 5
        elseif self:isPointInRect(mx, my, barX, kbY, barW, rowH) then
            self.selectedIndex = 6
        elseif self:isPointInRect(mx, my, barX, kbY + gap, barW, rowH) then
            self.selectedIndex = 7
        elseif self:isPointInRect(mx, my, barX, kbY + gap * 2, barW, rowH) then
            self.selectedIndex = 8
        elseif self:isPointInRect(mx, my, barX, kbY + gap * 3, barW, rowH) then
            self.selectedIndex = 9
        elseif self:isPointInButton(mx, my, L.backCx, L.backCy, 160, 36) then
            self.selectedIndex = SETTINGS_ITEM_COUNT
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
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local subtitle = "A Descent Into Darkness"
    local subW = self.bodyFont:getWidth(subtitle)
    love.graphics.setColor(Palette.subtitle)
    drawTextWithShadow(subtitle, w/2 - subW/2, h * 0.25 + 60 + self.titleBob)
    
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

function Menu:drawSlider(label, value, x, y, width, isSelected)
    local clamped = math.max(0, math.min(1, value or 0))
    love.graphics.setColor(0.16, 0.18, 0.24, 0.95)
    love.graphics.rectangle("fill", x, y, width, 16, 6, 6)

    local fillW = math.floor((width - 4) * clamped)
    if isSelected then
        love.graphics.setColor(Palette.sliderFillSelected)
    else
        love.graphics.setColor(Palette.sliderFill)
    end
    love.graphics.rectangle("fill", x + 2, y + 2, fillW, 12, 5, 5)

    love.graphics.setColor(Palette.text)
    love.graphics.setFont(self.bodyFont)
    drawTextWithShadow(label, x - 220, y - 7)
    love.graphics.setFont(self.smallFont)
    drawTextWithShadow(string.format("%d%%", math.floor(clamped * 100)), x + width + 20, y - 3)
end

-- Settings menu items layout:
-- 1: Music Volume (slider)
-- 2: Sound Volume (slider)
-- 3: Screen Shake (slider)
-- 4: Fullscreen (toggle)
-- 5: VSync (toggle)
-- 6: Dash keybind
-- 7: Multi Shot keybind
-- 8: Arrow Volley keybind
-- 9: Frenzy keybind
-- 10: BACK button
local SETTINGS_ITEM_COUNT = 10

function Menu:getSettingsFrameRect(w, h)
    local frameW = math.min(640, w - 160)
    local frameH = math.min(640, h - 80)
    local frameX = w * 0.5 - frameW * 0.5
    local frameY = h * 0.5 - frameH * 0.5
    return frameX, frameY, frameW, frameH
end

function Menu:getSettingsLayout(w, h)
    local frameX, frameY, frameW, frameH = self:getSettingsFrameRect(w, h)
    local barX = frameX + 220
    local barW = 220
    local y0 = frameY + 86
    local gap = 42
    local gfxY = y0 + gap * 3 + 30
    local kbY = gfxY + gap * 2 + 30
    local backCx = frameX + frameW * 0.5
    local backCy = frameY + frameH - 34
    return {
        frameX = frameX,
        frameY = frameY,
        frameW = frameW,
        frameH = frameH,
        barX = barX,
        barW = barW,
        y0 = y0,
        gap = gap,
        gfxY = gfxY,
        kbY = kbY,
        backCx = backCx,
        backCy = backCy,
    }
end

function Menu:drawSettings()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local v = self.visual

    -- Settings frame image if available (fallback to procedural panel)
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
    drawTextWithShadow(title, w/2 - self.headerFont:getWidth(title)/2, frameY + 30)

    local mgr = _G.settings
    local s = mgr and mgr:get() or nil
    local music = s and s.audio and s.audio.musicVolume or 0.35
    local sfx = s and s.audio and s.audio.sfxVolume or 0.5
    local shake = s and s.graphics and s.graphics.screenShake or 1.0
    local fullscreen = s and s.graphics and s.graphics.fullscreen or false
    local vsync = s and s.graphics and s.graphics.vsync or false

    local barX, barW, y0, gap, gfxY, kbY = L.barX, L.barW, L.y0, L.gap, L.gfxY, L.kbY

    -- Section: Audio (header Y offset -20 to avoid overlap with first item)
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.section)
    love.graphics.print("AUDIO", barX - 160, y0 - 20)
    self:drawSlider("Music", music, barX, y0, barW, self.selectedIndex == 1)
    self:drawSlider("Sound", sfx, barX, y0 + gap, barW, self.selectedIndex == 2)
    self:drawSlider("Shake", shake, barX, y0 + gap * 2, barW, self.selectedIndex == 3)

    -- Section: Graphics
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.section)
    love.graphics.print("GRAPHICS", barX - 160, gfxY - 20)
    self:drawToggle("Fullscreen", fullscreen, barX, gfxY, barW, self.selectedIndex == 4)
    self:drawToggle("VSync", vsync, barX, gfxY + gap, barW, self.selectedIndex == 5)

    -- Section: Keybinds
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.section)
    love.graphics.print("KEYBINDS", barX - 160, kbY - 20)

    local keybindActions = {"dash", "multi_shot", "arrow_volley", "frenzy"}
    local keybindLabels = {"Dash", "Multi Shot", "Arrow Volley", "Frenzy"}
    for i, action in ipairs(keybindActions) do
        local key = mgr and mgr:getKeybind(action) or action
        local isSelected = self.selectedIndex == 5 + i
        local isBinding = self.rebindingIndex == 5 + i
        self:drawKeybindRow(keybindLabels[i], key, barX, kbY + (i - 1) * gap, barW, isSelected, isBinding)
    end

    -- Back button
    if v.backButtonImage then
        local img = v.backButtonImage
        local iw, ih = img:getWidth(), img:getHeight()
        local bx, by = L.backCx - iw * 0.5, L.backCy - ih * 0.5
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, bx, by)
        love.graphics.setColor(Palette.title)
        drawTextWithShadow("BACK", w * 0.5 - self.bodyFont:getWidth("BACK") * 0.5, by + ih * 0.25)
    else
        self:drawButton("BACK", L.backCx, L.backCy, 160, 36, self.selectedIndex == SETTINGS_ITEM_COUNT)
    end

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(Palette.subtitle)
    local hint = self.rebindingIndex and "Press any key to bind..." or "UP/DOWN: select  LEFT/RIGHT: adjust  ENTER: toggle/rebind"
    local hw = self.smallFont:getWidth(hint)
    drawTextWithShadow(hint, w/2 - hw/2, frameY + frameH + 14)
end

function Menu:drawToggle(label, value, x, y, width, isSelected)
    love.graphics.setColor(Palette.text)
    local f = self.smallFont or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.print(label, x - 160, y - 3)
    local valText = value and "ON" or "OFF"
    local valColor = value and {0.4, 0.9, 0.5} or {0.6, 0.4, 0.4}
    if isSelected then
        love.graphics.setColor(Palette.title)
    else
        love.graphics.setColor(valColor[1], valColor[2], valColor[3], 1)
    end
    love.graphics.print(valText, x + width / 2 - f:getWidth(valText) / 2, y - 3)
end

function Menu:drawKeybindRow(label, key, x, y, width, isSelected, isBinding)
    local f = self.smallFont or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.setColor(Palette.text)
    love.graphics.print(label, x - 160, y - 3)

    local displayKey = isBinding and "..." or string.upper(key or "?")
    if isSelected then
        love.graphics.setColor(Palette.title)
    else
        love.graphics.setColor(0.7, 0.75, 0.85, 1)
    end

    -- Key box
    local kw = math.max(60, f:getWidth(displayKey) + 16)
    local kx = x + width / 2 - kw / 2
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", kx, y - 5, kw, f:getHeight() + 6, 4, 4)
    love.graphics.print(displayKey, kx + kw / 2 - f:getWidth(displayKey) / 2, y - 2)
end

function Menu:drawCharacterSelect()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    self:drawBackground()
    
    -- Header
    love.graphics.setFont(self.headerFont)
    local header = "CHOOSE YOUR HERO"
    local headerW = self.headerFont:getWidth(header)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    drawTextWithShadow(header, w/2 - headerW/2, 40)
    
    -- Character cards
    local classes = {"ARCHER", "WIZARD", "KNIGHT"}
    local cardWidth = 200
    local cardHeight = 300
    local spacing = 24
    local totalWidth = #classes * cardWidth + (#classes - 1) * spacing
    local startX = w/2 - totalWidth/2
    
    for i, classKey in ipairs(classes) do
        local classData = self.gameState.HeroClasses[classKey]
        local x = startX + (i - 1) * (cardWidth + spacing)
        local y = h/2 - cardHeight/2
        local isSelected = self.selectedIndex == i
        
        self:drawHeroCard(classData, x, y, cardWidth, cardHeight, isSelected)
    end
    
    -- Back button hint
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.65, 0.6, 0.55, 0.9)
    drawTextWithShadow("ESC to go back | ENTER to select | Arrow keys to navigate", 20, h - 30)
end

function Menu:drawHeroCard(classData, x, y, w, h, isSelected)
    -- Card background with glow if selected
    if isSelected then
        -- Glow effect
        for i = 3, 1, -1 do
            love.graphics.setColor(classData.color[1], classData.color[2], classData.color[3], 0.1 * i)
            love.graphics.rectangle("fill", x - i * 3, y - i * 3, w + i * 6, h + i * 6, 10, 10)
        end
    end
    
    -- Card background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    
    -- Card border
    if isSelected then
        love.graphics.setColor(classData.color[1], classData.color[2], classData.color[3], 1)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.3, 0.3, 0.35, 1)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    love.graphics.setLineWidth(1)
    
    -- Class icon (colored circle for now)
    local iconY = y + 50
    love.graphics.setColor(classData.color[1], classData.color[2], classData.color[3], 1)
    love.graphics.circle("fill", x + w/2, iconY, 30)
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.circle("fill", x + w/2 - 8, iconY - 8, 8)
    
    -- Class name
    love.graphics.setFont(self.bodyFont)
    local nameW = self.bodyFont:getWidth(classData.name)
    love.graphics.setColor(1, 1, 1, 1)
    drawTextWithShadow(classData.name, x + w/2 - nameW/2, y + 90)
    
    -- Description constrained to a few lines so stats stay inside the card.
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.78, 0.78, 0.75, 0.95)
    local descLineHeight = 18
    local descLines = self:wrapText(classData.description, w - 24)
    local maxDescLines = 4
    for i, line in ipairs(descLines) do
        if i > maxDescLines then break end
        if i == maxDescLines and #descLines > maxDescLines then
            line = line:gsub("%s+$", "") .. "..."
        end
        local lineW = self.smallFont:getWidth(line)
        drawTextWithShadow(line, x + w/2 - lineW/2, y + 125 + (i - 1) * descLineHeight)
    end
    
    -- Stats (positioned below description with clear separation)
    local statsY = y + 125 + math.min(#descLines, maxDescLines) * descLineHeight + 14
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.line(x + 20, statsY, x + w - 20, statsY)
    
    love.graphics.setFont(self.smallFont)
    -- HP
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.print("HP", x + 20, statsY + 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(classData.baseHP), x + 60, statsY + 10)
    
    -- ATK
    love.graphics.setColor(0.9, 0.6, 0.2, 1)
    love.graphics.print("ATK", x + 20, statsY + 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(classData.baseATK), x + 60, statsY + 30)
    
    -- Speed
    love.graphics.setColor(0.3, 0.7, 0.9, 1)
    love.graphics.print("SPD", x + 20, statsY + 50)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(classData.baseSpeed), x + 60, statsY + 50)
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

        -- If rebinding a key, capture the next keypress
        if self.rebindingIndex then
            if key ~= "escape" then
                local keybindActions = {"dash", "multi_shot", "arrow_volley", "frenzy"}
                local actionIdx = self.rebindingIndex - 5
                if actionIdx >= 1 and actionIdx <= #keybindActions and mgr then
                    mgr:setKeybind(keybindActions[actionIdx], key)
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
            if mgr then
                local s = mgr:get()
                if self.selectedIndex == 1 then
                    mgr:setMusicVolume((s.audio.musicVolume or 0.35) + step * dir)
                elseif self.selectedIndex == 2 then
                    mgr:setSFXVolume((s.audio.sfxVolume or 0.5) + step * dir)
                elseif self.selectedIndex == 3 then
                    mgr:setScreenShake((s.graphics.screenShake or 1.0) + step * dir)
                end
            end
        elseif key == "return" or key == "space" then
            if self.selectedIndex == 4 and mgr then
                mgr:toggleFullscreen()
            elseif self.selectedIndex == 5 and mgr then
                mgr:toggleVsync()
            elseif self.selectedIndex >= 6 and self.selectedIndex <= 9 then
                self.rebindingIndex = self.selectedIndex
            elseif self.selectedIndex == SETTINGS_ITEM_COUNT then
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
        local classes = {"ARCHER", "WIZARD", "KNIGHT"}
        if key == "left" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = #classes end
        elseif key == "right" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #classes then self.selectedIndex = 1 end
        elseif key == "return" or key == "space" then
            self.gameState:selectHeroClass(classes[self.selectedIndex])
            self.gameState:transitionTo(States.BIOME_SELECT)
            self.selectedIndex = 1
        elseif key == "escape" then
            self.gameState:transitionTo(States.MENU)
            self.selectedIndex = 1
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
        local barX, barW, y0, gap, gfxY, kbY = L.barX, L.barW, L.y0, L.gap, L.gfxY, L.kbY
        local rowH = 24

        -- Sliders 1-3: click to set value
        if mgr then
            for i = 1, 3 do
                local sy = (i == 1) and y0 or (i == 2) and (y0 + gap) or (y0 + gap * 2)
                if self:isPointInRect(x, y, barX, sy, barW, 16) then
                    local t = math.max(0, math.min(1, (x - barX) / barW))
                    if i == 1 then mgr:setMusicVolume(t)
                    elseif i == 2 then mgr:setSFXVolume(t)
                    else mgr:setScreenShake(t) end
                    return
                end
            end
            -- Toggles 4-5
            if self:isPointInRect(x, y, barX, gfxY, barW, rowH) then
                mgr:toggleFullscreen()
                return
            end
            if self:isPointInRect(x, y, barX, gfxY + gap, barW, rowH) then
                mgr:toggleVsync()
                return
            end
        end
        -- Keybinds 6-9
        for i = 1, 4 do
            if self:isPointInRect(x, y, barX, kbY + (i - 1) * gap, barW, rowH) then
                self.rebindingIndex = 5 + i
                return
            end
        end
        -- BACK
        if self:isPointInButton(x, y, L.backCx, L.backCy, 160, 36) then
            self.gameState:transitionTo(States.MENU)
            self.selectedIndex = 4
        end
    elseif state == States.CHARACTER_SELECT then
        -- Check character cards
        local classes = {"ARCHER", "WIZARD", "KNIGHT"}
        local cardWidth = 200
        local cardHeight = 300
        local spacing = 24
        local totalWidth = #classes * cardWidth + (#classes - 1) * spacing
        local startX = w/2 - totalWidth/2
        
        for i, classKey in ipairs(classes) do
            local cardX = startX + (i - 1) * (cardWidth + spacing)
            local cardY = h/2 - cardHeight/2
            
            if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + cardHeight then
                self.gameState:selectHeroClass(classKey)
                self.gameState:transitionTo(States.BIOME_SELECT)
                self.selectedIndex = 1
                return
            end
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
        local barX, barW, y0, gap, gfxY, kbY = L.barX, L.barW, L.y0, L.gap, L.gfxY, L.kbY
        local rowH = 24
        if self:isPointInRect(x, y, barX, y0, barW, 16) then
            self.selectedIndex = 1
        elseif self:isPointInRect(x, y, barX, y0 + gap, barW, 16) then
            self.selectedIndex = 2
        elseif self:isPointInRect(x, y, barX, y0 + gap * 2, barW, 16) then
            self.selectedIndex = 3
        elseif self:isPointInRect(x, y, barX, gfxY, barW, rowH) then
            self.selectedIndex = 4
        elseif self:isPointInRect(x, y, barX, gfxY + gap, barW, rowH) then
            self.selectedIndex = 5
        elseif self:isPointInRect(x, y, barX, kbY, barW, rowH) then
            self.selectedIndex = 6
        elseif self:isPointInRect(x, y, barX, kbY + gap, barW, rowH) then
            self.selectedIndex = 7
        elseif self:isPointInRect(x, y, barX, kbY + gap * 2, barW, rowH) then
            self.selectedIndex = 8
        elseif self:isPointInRect(x, y, barX, kbY + gap * 3, barW, rowH) then
            self.selectedIndex = 9
        elseif self:isPointInButton(x, y, L.backCx, L.backCy, 160, 36) then
            self.selectedIndex = SETTINGS_ITEM_COUNT
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
        local classes = {"ARCHER", "WIZARD", "KNIGHT"}
        local cardWidth = 200
        local cardHeight = 300
        local spacing = 24
        local totalWidth = #classes * cardWidth + (#classes - 1) * spacing
        local startX = w/2 - totalWidth/2
        
        for i, classKey in ipairs(classes) do
            local cardX = startX + (i - 1) * (cardWidth + spacing)
            local cardY = h/2 - cardHeight/2
            
            if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + cardHeight then
                self.selectedIndex = i
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
