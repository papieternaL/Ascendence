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
        smallFont = nil
    }
    setmetatable(menu, Menu)
    menu:init()
    return menu
end

function Menu:init()
    -- Create fonts at different sizes
    self.titleFont = love.graphics.newFont(48)
    self.headerFont = love.graphics.newFont(28)
    self.bodyFont = love.graphics.newFont(18)
    self.smallFont = love.graphics.newFont(14)
    
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
        -- Check if hovering over BEGIN TRIAL button
        if self:isPointInButton(mx, my, w/2, h * 0.6, 200, 50) then
            self.selectedIndex = 1
            self.hoveredButton = "begin"
        -- Check if hovering over BOSS TEST button
        elseif self:isPointInButton(mx, my, w/2, h * 0.7, 200, 50) then
            self.selectedIndex = 2
            self.hoveredButton = "boss_test"
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
    elseif state == States.CHARACTER_SELECT then
        self:drawCharacterSelect()
    elseif state == States.BIOME_SELECT then
        self:drawBiomeSelect()
    elseif state == States.DIFFICULTY_SELECT then
        self:drawDifficultySelect()
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
    love.graphics.print(title, w/2 - titleW/2, h * 0.25 + self.titleBob)
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local subtitle = "A Descent Into Darkness"
    local subW = self.bodyFont:getWidth(subtitle)
    love.graphics.setColor(0.6, 0.5, 0.4, 0.8)
    love.graphics.print(subtitle, w/2 - subW/2, h * 0.25 + 60 + self.titleBob)
    
    -- Begin button
    self:drawButton("BEGIN TRIAL", w/2, h * 0.6, 200, 50, self.selectedIndex == 1)
    
    -- Boss Test button (debug/test mode)
    self:drawButton("BOSS TEST", w/2, h * 0.7, 200, 50, self.selectedIndex == 2)
    
    -- Instructions
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    local instr = "Press ENTER or Click to Continue"
    local instrW = self.smallFont:getWidth(instr)
    love.graphics.print(instr, w/2 - instrW/2, h * 0.85)
end

function Menu:drawCharacterSelect()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    self:drawBackground()
    
    -- Header
    love.graphics.setFont(self.headerFont)
    local header = "CHOOSE YOUR HERO"
    local headerW = self.headerFont:getWidth(header)
    love.graphics.setColor(1, 0.9, 0.7, 1)
    love.graphics.print(header, w/2 - headerW/2, 40)
    
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
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print("ESC to go back | ENTER to select | Arrow keys to navigate", 20, h - 30)
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
    love.graphics.print(classData.name, x + w/2 - nameW/2, y + 90)
    
    -- Description
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.9)
    local descLines = self:wrapText(classData.description, w - 20)
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        love.graphics.print(line, x + w/2 - lineW/2, y + 125 + (i-1) * 16)
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
    love.graphics.print(header, w/2 - headerW/2, 40)
    
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
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print("ESC to go back | ENTER to select | Arrow keys to navigate", 20, h - 30)
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
    love.graphics.print(biomeData.name, x + w/2 - nameW/2, y + 20)
    
    -- Subtitle
    love.graphics.setFont(self.smallFont)
    local subW = self.smallFont:getWidth(biomeData.subtitle)
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.print(biomeData.subtitle, x + w/2 - subW/2, y + 55)
    
    -- Description
    love.graphics.setColor(0.6, 0.6, 0.6, 0.9)
    local descLines = self:wrapText(biomeData.description, w - 20)
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        love.graphics.print(line, x + w/2 - lineW/2, y + 85 + (i-1) * 16)
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
    love.graphics.print(header, w/2 - headerW/2, 40)
    
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
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print("ESC to go back | ENTER to begin your ascent", 20, h - 30)
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
    love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
    local descLines = self:wrapText(diffData.description, w - 20)
    for i, line in ipairs(descLines) do
        local lineW = self.smallFont:getWidth(line)
        love.graphics.print(line, x + w/2 - lineW/2, y + 75 + (i-1) * 16)
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
    love.graphics.print(text, w/2 - textW/2, h * 0.3)
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local sub = "Your journey ends here..."
    local subW = self.bodyFont:getWidth(sub)
    love.graphics.setColor(0.6, 0.4, 0.4, 0.9)
    love.graphics.print(sub, w/2 - subW/2, h * 0.3 + 60)
    
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
    love.graphics.print(text, w/2 - textW/2, h * 0.3 + self.titleBob)
    
    -- Subtitle
    love.graphics.setFont(self.bodyFont)
    local sub = "You have conquered the darkness!"
    local subW = self.bodyFont:getWidth(sub)
    love.graphics.setColor(0.8, 0.7, 0.4, 0.9)
    love.graphics.print(sub, w/2 - subW/2, h * 0.3 + 60)
    
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
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
    end
    love.graphics.print(text, cx - textW/2, cy - textH/2)
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
        if key == "up" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = 2 end
        elseif key == "down" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > 2 then self.selectedIndex = 1 end
        elseif key == "return" or key == "space" then
            if self.selectedIndex == 1 then
                -- Normal game start
                self.gameState:transitionTo(States.CHARACTER_SELECT)
                self.selectedIndex = 1
            elseif self.selectedIndex == 2 then
                -- BOSS TEST MODE - skip straight to boss
                -- Hot-reload boss modules before entering
                if reloadBossModules then
                    reloadBossModules()
                end
                self.gameState.bossTestMode = true
                self.gameState:selectHeroClass("ARCHER")
                self.gameState:selectBiome("DEEPWOOD")
                self.gameState:selectDifficulty("VETERAN")
                self.gameState:initFloor(5)
                self.gameState:transitionTo(States.BOSS_FIGHT)
            end
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
            self.gameState:transitionTo(States.DIFFICULTY_SELECT)
            self.selectedIndex = 1
        elseif key == "escape" then
            self.gameState:transitionTo(States.CHARACTER_SELECT)
            self.selectedIndex = 1
        end
    elseif state == States.DIFFICULTY_SELECT then
        local difficulties = {"ADEPT", "VETERAN", "ASCENDANT"}
        if key == "left" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then self.selectedIndex = #difficulties end
        elseif key == "right" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #difficulties then self.selectedIndex = 1 end
        elseif key == "return" or key == "space" then
            self.gameState:selectDifficulty(difficulties[self.selectedIndex])
            self.gameState:initFloor(1)
            self.gameState:transitionTo(States.PLAYING)
        elseif key == "escape" then
            self.gameState:transitionTo(States.BIOME_SELECT)
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
    
    -- Debug: print click info
    print("Mouse clicked at:", x, y, "State:", state)
    
    if state == States.MENU then
        -- Check "BEGIN TRIAL" button
        local inBeginButton = self:isPointInButton(x, y, w/2, h * 0.6, 200, 50)
        local inBossButton = self:isPointInButton(x, y, w/2, h * 0.7, 200, 50)
        print("In BEGIN button:", inBeginButton, "In BOSS button:", inBossButton)
        
        if inBeginButton then
            print("Transitioning to CHARACTER_SELECT")
            self.gameState:transitionTo(States.CHARACTER_SELECT)
            self.selectedIndex = 1
        elseif inBossButton then
            print("Launching BOSS TEST MODE")
            -- BOSS TEST MODE - skip straight to boss
            -- Hot-reload boss modules before entering
            if reloadBossModules then
                reloadBossModules()
            end
            self.gameState.bossTestMode = true
            self.gameState:selectHeroClass("ARCHER")
            self.gameState:selectBiome("DEEPWOOD")
            self.gameState:selectDifficulty("VETERAN")
            self.gameState:initFloor(5)
            self.gameState:transitionTo(States.BOSS_FIGHT)
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
                self.gameState:transitionTo(States.DIFFICULTY_SELECT)
                self.selectedIndex = 1
                return
            end
        end
        
    elseif state == States.DIFFICULTY_SELECT then
        -- Check difficulty cards
        local difficulties = {"ADEPT", "VETERAN", "ASCENDANT"}
        local cardWidth = 200
        local cardHeight = 120
        local spacing = 40
        local totalWidth = #difficulties * cardWidth + (#difficulties - 1) * spacing
        local startX = w/2 - totalWidth/2
        
        for i, diffKey in ipairs(difficulties) do
            local cardX = startX + (i - 1) * (cardWidth + spacing)
            local cardY = h/2 - cardHeight/2
            
            if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + cardHeight then
                self.gameState:selectDifficulty(diffKey)
                self.gameState:initFloor(1)
                self.gameState:transitionTo(States.PLAYING)
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
    
    if state == States.CHARACTER_SELECT then
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
        
    elseif state == States.DIFFICULTY_SELECT then
        local difficulties = {"ADEPT", "VETERAN", "ASCENDANT"}
        local cardWidth = 200
        local cardHeight = 120
        local spacing = 40
        local totalWidth = #difficulties * cardWidth + (#difficulties - 1) * spacing
        local startX = w/2 - totalWidth/2
        
        for i, diffKey in ipairs(difficulties) do
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
