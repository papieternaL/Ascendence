-- Menu UI System
local Menu = {}
Menu.__index = Menu

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
    }
    setmetatable(menu, Menu)
    menu:init()
    return menu
end

function Menu:init()
    local fontNarrow = "assets/Other/Fonts/Kenney Future Narrow.ttf"
    local fontBold   = "assets/Other/Fonts/Kenney Future.ttf"
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
    self.titleFont  = loadFont(fontBold, 48)
    self.headerFont = loadFont(fontBold, 30)
    self.bodyFont   = loadFont(fontNarrow, 18)
    self.smallFont  = loadFont(fontNarrow, 14)
    
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

function Menu:update(dt)
    -- Title bobbing animation
    self.titleBob = math.sin(love.timer.getTime() * self.titleBobSpeed) * 5
    
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
    end
end

function Menu:draw()
    local state = self.gameState:getState()
    local States = self.gameState.States
    
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
    
    -- Dark gradient background
    love.graphics.setColor(0.02, 0.02, 0.05, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Radial gradient overlay
    for i = 10, 1, -1 do
        local alpha = 0.02 * i
        local radius = (w * 0.4) * (i / 10)
        love.graphics.setColor(0.1, 0.05, 0.15, alpha)
        love.graphics.circle("fill", w/2, h/2, radius)
    end
    
    -- Floating ember particles
    for i, p in ipairs(self.particles) do
        local glow = (math.sin(self.particleTime * 2 + i) + 1) / 2
        love.graphics.setColor(1, 0.6 + glow * 0.3, 0.2, p.alpha * (0.5 + glow * 0.5))
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

function Menu:drawMainMenu()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    self:drawBackground()
    
    -- Title
    love.graphics.setFont(self.titleFont)
    local title = "ASCENDENCE"
    local titleW = self.titleFont:getWidth(title)
    
    -- Title glow
    for i = 3, 1, -1 do
        love.graphics.setColor(0.8, 0.4, 0.1, 0.1 * i)
        love.graphics.print(title, w/2 - titleW/2 - i, h * 0.25 + self.titleBob - i)
    end
    
    -- Main title
    love.graphics.setColor(1, 0.85, 0.6, 1)
    drawTextWithShadow(title, w/2 - titleW/2, h * 0.25 + self.titleBob)
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local subtitle = "A Descent Into Darkness"
    local subW = self.bodyFont:getWidth(subtitle)
    love.graphics.setColor(0.7, 0.6, 0.5, 0.9)
    drawTextWithShadow(subtitle, w/2 - subW/2, h * 0.25 + 60 + self.titleBob)
    
    -- Menu buttons
    self:drawButton("BEGIN TRIAL", w/2, h * 0.50, 200, 40, self.selectedIndex == 1)
    self:drawButton("TUTORIAL", w/2, h * 0.56, 200, 40, self.selectedIndex == 2)
    self:drawButton("BOSS TEST", w/2, h * 0.62, 200, 40, self.selectedIndex == 3)
    self:drawButton("SETTINGS", w/2, h * 0.68, 200, 40, self.selectedIndex == 4)
    self:drawButton("QUIT", w/2, h * 0.74, 200, 40, self.selectedIndex == 5)
    
    -- Instructions
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.65, 0.6, 0.55, 0.9)
    local instr = "Press ENTER or Click to Continue"
    local instrW = self.smallFont:getWidth(instr)
    drawTextWithShadow(instr, w/2 - instrW/2, h * 0.85)
end

function Menu:drawSlider(label, value, x, y, width, isSelected)
    local clamped = math.max(0, math.min(1, value or 0))
    love.graphics.setColor(0.2, 0.2, 0.26, 0.95)
    love.graphics.rectangle("fill", x, y, width, 16, 6, 6)

    local fillW = math.floor((width - 4) * clamped)
    if isSelected then
        love.graphics.setColor(0.95, 0.75, 0.35, 1)
    else
        love.graphics.setColor(0.65, 0.72, 0.95, 1)
    end
    love.graphics.rectangle("fill", x + 2, y + 2, fillW, 12, 5, 5)

    love.graphics.setColor(0.9, 0.9, 0.95, 1)
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

function Menu:drawSettings()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self:drawBackground()

    love.graphics.setFont(self.headerFont)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    local title = "SETTINGS"
    drawTextWithShadow(title, w/2 - self.headerFont:getWidth(title)/2, h * 0.08)

    local mgr = _G.settings
    local s = mgr and mgr:get() or nil
    local music = s and s.audio and s.audio.musicVolume or 0.35
    local sfx = s and s.audio and s.audio.sfxVolume or 0.5
    local shake = s and s.graphics and s.graphics.screenShake or 1.0
    local fullscreen = s and s.graphics and s.graphics.fullscreen or false
    local vsync = s and s.graphics and s.graphics.vsync or false

    local barX = w/2 - 100
    local barW = 220
    local y0 = h * 0.20
    local gap = 38

    -- Section: Audio
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.6, 0.55, 0.45, 0.8)
    love.graphics.print("AUDIO", barX - 160, y0 - 4)
    self:drawSlider("Music", music, barX, y0, barW, self.selectedIndex == 1)
    self:drawSlider("Sound", sfx, barX, y0 + gap, barW, self.selectedIndex == 2)
    self:drawSlider("Shake", shake, barX, y0 + gap * 2, barW, self.selectedIndex == 3)

    -- Section: Graphics
    local gfxY = y0 + gap * 3 + 16
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.6, 0.55, 0.45, 0.8)
    love.graphics.print("GRAPHICS", barX - 160, gfxY - 4)
    self:drawToggle("Fullscreen", fullscreen, barX, gfxY, barW, self.selectedIndex == 4)
    self:drawToggle("VSync", vsync, barX, gfxY + gap, barW, self.selectedIndex == 5)

    -- Section: Keybinds
    local kbY = gfxY + gap * 2 + 16
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.6, 0.55, 0.45, 0.8)
    love.graphics.print("KEYBINDS", barX - 160, kbY - 4)

    local keybindActions = {"dash", "multi_shot", "arrow_volley", "frenzy"}
    local keybindLabels = {"Dash", "Multi Shot", "Arrow Volley", "Frenzy"}
    for i, action in ipairs(keybindActions) do
        local key = mgr and mgr:getKeybind(action) or action
        local isSelected = self.selectedIndex == 5 + i
        local isBinding = self.rebindingIndex == 5 + i
        self:drawKeybindRow(keybindLabels[i], key, barX, kbY + (i - 1) * gap, barW, isSelected, isBinding)
    end

    -- Back button
    self:drawButton("BACK", w/2, h * 0.92, 160, 36, self.selectedIndex == SETTINGS_ITEM_COUNT)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.6, 0.58, 0.52, 0.8)
    local hint = self.rebindingIndex and "Press any key to bind..." or "UP/DOWN: select  LEFT/RIGHT: adjust  ENTER: toggle/rebind"
    local hw = self.smallFont:getWidth(hint)
    drawTextWithShadow(hint, w/2 - hw/2, h * 0.97)
end

function Menu:drawToggle(label, value, x, y, width, isSelected)
    love.graphics.setColor(0.9, 0.9, 0.95, 1)
    local f = self.smallFont or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.print(label, x - 160, y - 3)
    local valText = value and "ON" or "OFF"
    local valColor = value and {0.4, 0.9, 0.5} or {0.6, 0.4, 0.4}
    if isSelected then
        love.graphics.setColor(1, 0.9, 0.5, 1)
    else
        love.graphics.setColor(valColor[1], valColor[2], valColor[3], 1)
    end
    love.graphics.print(valText, x + width / 2 - f:getWidth(valText) / 2, y - 3)
end

function Menu:drawKeybindRow(label, key, x, y, width, isSelected, isBinding)
    local f = self.smallFont or love.graphics.getFont()
    love.graphics.setFont(f)
    love.graphics.setColor(0.9, 0.9, 0.95, 1)
    love.graphics.print(label, x - 160, y - 3)

    local displayKey = isBinding and "..." or string.upper(key or "?")
    if isSelected then
        love.graphics.setColor(1, 0.9, 0.5, 1)
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
    local cardWidth = 180
    local cardHeight = 280
    local spacing = 30
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
    love.graphics.setFont(self.headerFont)
    local nameW = self.headerFont:getWidth(classData.name)
    love.graphics.setColor(1, 1, 1, 1)
    drawTextWithShadow(classData.name, x + w/2 - nameW/2, y + 90)
    
    -- Description
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.78, 0.78, 0.75, 0.95)
    local descLines = self:wrapText(classData.description, w - 20)
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        drawTextWithShadow(line, x + w/2 - lineW/2, y + 125 + (i-1) * 18)
    end
    
    -- Stats
    local statsY = y + 180
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
    local cardWidth = 200
    local cardHeight = 150
    local spacing = 40
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
    
    -- Biome name
    love.graphics.setFont(self.headerFont)
    local nameW = self.headerFont:getWidth(biomeData.name)
    love.graphics.setColor(biomeData.accentColor[1], biomeData.accentColor[2], biomeData.accentColor[3], 1)
    drawTextWithShadow(biomeData.name, x + w/2 - nameW/2, y + 20)
    
    -- Subtitle
    love.graphics.setFont(self.smallFont)
    local subW = self.smallFont:getWidth(biomeData.subtitle)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.print(biomeData.subtitle, x + w/2 - subW/2, y + 55)
    
    -- Description
    love.graphics.setColor(0.72, 0.72, 0.68, 0.95)
    local descLines = self:wrapText(biomeData.description, w - 20)
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        drawTextWithShadow(line, x + w/2 - lineW/2, y + 85 + (i-1) * 18)
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
        if key == "up" or key == "down" then
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
                self.gameState:transitionTo(States.PLAYING)
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
        elseif key == "escape" then
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
            self.gameState:transitionTo(States.PLAYING)
            self.selectedIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.68, 200, 40) then
            self.gameState:transitionTo(States.SETTINGS)
            self.selectedIndex = 1
        elseif self:isPointInButton(x, y, w/2, h * 0.74, 200, 40) then
            love.event.quit()
        end
    elseif state == States.SETTINGS then
        if self:isPointInButton(x, y, w/2, h * 0.78, 180, 50) then
            self.gameState:transitionTo(States.MENU)
            self.selectedIndex = 2
        end
        
    elseif state == States.CHARACTER_SELECT then
        -- Check character cards
        local classes = {"ARCHER", "WIZARD", "KNIGHT"}
        local cardWidth = 180
        local cardHeight = 280
        local spacing = 30
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
        local cardWidth = 200
        local cardHeight = 150
        local spacing = 40
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

    if state == States.GAME_OVER then
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
        local cardWidth = 180
        local cardHeight = 280
        local spacing = 30
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
        local cardWidth = 200
        local cardHeight = 150
        local spacing = 40
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

