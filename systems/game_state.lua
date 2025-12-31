-- Game State Management
local GameState = {}
GameState.__index = GameState

-- Game States Enum
GameState.States = {
    MENU = "menu",
    CHARACTER_SELECT = "character_select",
    BIOME_SELECT = "biome_select",
    DIFFICULTY_SELECT = "difficulty_select",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "game_over",
    VICTORY = "victory"
}

-- Hero Classes
GameState.HeroClasses = {
    ARCHER = {
        id = "archer",
        name = "Archer",
        description = "Swift ranger who strikes from afar with deadly precision.",
        lore = "Trained in the ancient forests, masters the bow.",
        baseHP = 80,
        baseATK = 15,
        baseSpeed = 220,
        attackRange = 350,
        attackSpeed = 0.4,
        color = {0.2, 0.7, 0.3}, -- Green
        abilities = {"Power Shot", "Arrow Rain", "Evasive Roll"}
    },
    WIZARD = {
        id = "wizard",
        name = "Wizard",
        description = "Master of arcane arts, wielding devastating magic.",
        lore = "Scholar of forbidden tomes, channels pure destruction.",
        baseHP = 60,
        baseATK = 25,
        baseSpeed = 180,
        attackRange = 300,
        attackSpeed = 0.6,
        color = {0.5, 0.2, 0.8}, -- Purple
        abilities = {"Fireball", "Ice Nova", "Teleport"}
    },
    KNIGHT = {
        id = "knight",
        name = "Knight",
        description = "Armored warrior who crushes foes in close combat.",
        lore = "Sworn protector of the realm, unbreakable in battle.",
        baseHP = 120,
        baseATK = 12,
        baseSpeed = 160,
        attackRange = 60,
        attackSpeed = 0.8,
        color = {0.7, 0.7, 0.8}, -- Silver
        abilities = {"Shield Bash", "Whirlwind", "Fortress"}
    }
}

-- Biomes
GameState.Biomes = {
    DEEPWOOD = {
        id = "deepwood",
        name = "Deepwood",
        subtitle = "The Eternal Forest",
        description = "Ancient trees hide lurking dangers.",
        bgColor = {0.05, 0.12, 0.08},
        accentColor = {0.2, 0.6, 0.3},
        enemies = {"wolf", "spriggan", "ent"},
        boss = "The Forest Heart"
    },
    GREY_HALLS = {
        id = "grey_halls",
        name = "Grey Halls",
        subtitle = "The Necropolis",
        description = "Undead horrors wander endless crypts.",
        bgColor = {0.08, 0.08, 0.12},
        accentColor = {0.4, 0.4, 0.6},
        enemies = {"skeleton", "wraith", "lich"},
        boss = "The Bone King"
    },
    ASH_CRAG = {
        id = "ash_crag",
        name = "Ash Crag",
        subtitle = "The Inferno",
        description = "Rivers of fire consume all who enter.",
        bgColor = {0.15, 0.05, 0.02},
        accentColor = {0.9, 0.4, 0.1},
        enemies = {"imp", "hellhound", "demon"},
        boss = "The Ember Lord"
    }
}

-- Difficulties
GameState.Difficulties = {
    ADEPT = {
        id = "adept",
        name = "Adept",
        subtitle = "For the Uninitiated",
        description = "Enemies deal less damage, more forgiving.",
        enemyDamageMult = 0.7,
        enemyHealthMult = 0.8,
        playerDamageMult = 1.2,
        xpMult = 0.8
    },
    VETERAN = {
        id = "veteran",
        name = "Veteran",
        subtitle = "The True Challenge",
        description = "Balanced combat for experienced warriors.",
        enemyDamageMult = 1.0,
        enemyHealthMult = 1.0,
        playerDamageMult = 1.0,
        xpMult = 1.0
    },
    ASCENDANT = {
        id = "ascendant",
        name = "Ascendant",
        subtitle = "Beyond Mortal Limits",
        description = "For those who seek true suffering.",
        enemyDamageMult = 1.5,
        enemyHealthMult = 1.5,
        playerDamageMult = 0.8,
        xpMult = 1.5
    }
}

function GameState:new()
    local state = {
        currentState = GameState.States.MENU,
        selectedHeroClass = nil,
        selectedBiome = nil,
        selectedDifficulty = nil,
        currentFloor = 1,
        maxFloors = 15,
        -- Transition effects
        transitionAlpha = 0,
        isTransitioning = false,
        transitionTarget = nil,
        transitionTime = 0,
        transitionDuration = 0.3
    }
    setmetatable(state, GameState)
    return state
end

function GameState:update(dt)
    -- Handle state transitions
    if self.isTransitioning then
        self.transitionTime = self.transitionTime + dt
        local progress = self.transitionTime / self.transitionDuration
        
        if progress < 0.5 then
            -- Fade out
            self.transitionAlpha = progress * 2
        else
            -- Switch state at midpoint
            if self.transitionTarget and self.currentState ~= self.transitionTarget then
                self.currentState = self.transitionTarget
            end
            -- Fade in
            self.transitionAlpha = 1 - ((progress - 0.5) * 2)
        end
        
        if progress >= 1 then
            self.isTransitioning = false
            self.transitionAlpha = 0
            self.transitionTarget = nil
        end
    end
end

function GameState:transitionTo(newState)
    if not self.isTransitioning then
        self.isTransitioning = true
        self.transitionTarget = newState
        self.transitionTime = 0
    end
end

function GameState:setState(newState)
    self.currentState = newState
end

function GameState:getState()
    return self.currentState
end

function GameState:selectHeroClass(classKey)
    self.selectedHeroClass = GameState.HeroClasses[classKey]
end

function GameState:selectBiome(biomeKey)
    self.selectedBiome = GameState.Biomes[biomeKey]
end

function GameState:selectDifficulty(difficultyKey)
    self.selectedDifficulty = GameState.Difficulties[difficultyKey]
end

function GameState:initFloor(floorNum)
    self.currentFloor = floorNum or 1
end

function GameState:nextFloor()
    self.currentFloor = self.currentFloor + 1
    if self.currentFloor > self.maxFloors then
        self:transitionTo(GameState.States.VICTORY)
        return false
    end
    return true
end

function GameState:reset()
    self.currentState = GameState.States.MENU
    self.selectedHeroClass = nil
    self.selectedBiome = nil
    self.selectedDifficulty = nil
    self.currentFloor = 1
    self.transitionAlpha = 0
    self.isTransitioning = false
end

return GameState






