-- Game State Management
local GameState = {}
GameState.__index = GameState

-- Game States Enum
GameState.States = {
    MENU = "menu",
    CHARACTER_SELECT = "character_select",
    BIOME_SELECT = "biome_select",
    DIFFICULTY_SELECT = "difficulty_select",
    SETTINGS = "settings",
    PLAYING = "playing",
    BOSS_FIGHT = "boss_fight",
    PAUSED = "paused",
    GAME_OVER = "game_over",
    VICTORY = "victory",
    TUTORIAL = "tutorial"
}

-- Hero Classes
GameState.HeroClasses = {
    ARCHER = {
        id = "archer",
        name = "Archer",
        role = "Ranged Executioner",
        description = "Swift ranger who strikes from afar with deadly precision.",
        lore = "Trained in the ancient forests, masters the bow.",
        baseHP = 100,
        baseATK = 15,
        baseSpeed = 246,
        attackRange = 350,
        attackSpeed = 0.4,
        color = {0.2, 0.7, 0.3}, -- Green
        secondaryColor = {0.72, 0.95, 0.56},
        abilities = {"Multi Shot", "Arrow Volley", "Dash", "Frenzy"},
        skills = {
            {
                id = "multi_shot",
                name = "Multi Shot",
                key = "Q",
                mode = "Manual",
                icon = "multi_shot",
                summary = "Cone burst",
                description = "Loose a tight fan of arrows for burst damage and on-demand lane clear when elites step into range.",
            },
            {
                id = "dash",
                name = "Dash",
                key = "SPACE",
                mode = "Manual",
                icon = "dash",
                summary = "Reposition",
                description = "Explode into a short evasive dash with invulnerability frames so the class can keep spacing without giving up pressure.",
            },
            {
                id = "arrow_volley",
                name = "Arrow Volley",
                key = "E",
                mode = "Auto",
                icon = "arrow_volley",
                summary = "Pack punish",
                description = "Call down a rain of arrows on the densest cluster, turning swarm control into something readable and satisfying.",
            },
            {
                id = "frenzy",
                name = "Frenzy",
                key = "R",
                mode = "Ultimate",
                icon = "frenzy",
                summary = "Power spike",
                description = "Cash in a full charge for a short crit-and-speed window that rewards confident movement and boss execution.",
            },
        },
    },
    WIZARD = {
        id = "wizard",
        name = "Wizard",
        role = "Arcane Artillery",
        description = "Master of arcane arts, wielding devastating magic.",
        lore = "Scholar of forbidden tomes, channels pure destruction.",
        baseHP = 60,
        baseATK = 25,
        baseSpeed = 202,
        attackRange = 300,
        attackSpeed = 0.6,
        color = {0.5, 0.2, 0.8}, -- Purple
        secondaryColor = {0.78, 0.60, 1.0},
        abilities = {"Fireball", "Teleport", "Ice Nova", "Starfall"},
        skills = {
            {
                id = "fireball",
                name = "Fireball",
                key = "Q",
                mode = "Manual",
                icon = "fireball",
                summary = "Explosive cast",
                description = "Launch a dense arcane fireball that detonates on impact, rewarding clean aim with reliable burst damage.",
            },
            {
                id = "teleport",
                name = "Teleport",
                key = "SPACE",
                mode = "Manual",
                icon = "teleport",
                summary = "Blink escape",
                description = "Slip through danger in a blink, repositioning before the next spell cycle catches up to the battlefield.",
            },
            {
                id = "ice_nova",
                name = "Ice Nova",
                key = "E",
                mode = "Manual",
                icon = "ice_nova",
                summary = "Point-blank zone",
                description = "Flash-freeze the area around the caster with a sharp frost pulse that stabilizes close-range pressure.",
            },
            {
                id = "starfall",
                name = "Starfall",
                key = "R",
                mode = "Ultimate",
                icon = "starfall",
                summary = "Arcane finisher",
                description = "Open the sky and hammer a target zone with astral force for a flashy, high-commitment finisher.",
            },
        },
    },
    KNIGHT = {
        id = "knight",
        name = "Knight",
        role = "Frontline Vanguard",
        description = "Armored warrior who crushes foes in close combat.",
        lore = "Sworn protector of the realm, unbreakable in battle.",
        baseHP = 120,
        baseATK = 12,
        baseSpeed = 179,
        attackRange = 60,
        attackSpeed = 0.8,
        color = {0.7, 0.7, 0.8}, -- Silver
        secondaryColor = {0.92, 0.94, 1.0},
        abilities = {"Shield Bash", "Bulwark Rush", "Whirlwind", "Fortress"},
        skills = {
            {
                id = "shield_bash",
                name = "Shield Bash",
                key = "Q",
                mode = "Manual",
                icon = "shield_bash",
                summary = "Breach opener",
                description = "Crash into the front line with a shield-first strike that makes room for the rest of the melee combo.",
            },
            {
                id = "bulwark_rush",
                name = "Bulwark Rush",
                key = "SPACE",
                mode = "Manual",
                icon = "bulwark_rush",
                summary = "Shielded engage",
                description = "Drive forward behind the shield to cross danger zones and keep pressure on priority targets.",
            },
            {
                id = "whirlwind",
                name = "Whirlwind",
                key = "E",
                mode = "Manual",
                icon = "whirlwind",
                summary = "Spin cleave",
                description = "Commit to a sweeping spin that chews through surrounding enemies when the arena collapses inward.",
            },
            {
                id = "fortress",
                name = "Fortress",
                key = "R",
                mode = "Ultimate",
                icon = "fortress",
                summary = "Hold the line",
                description = "Plant yourself as an immovable wall and turn the next few seconds into a bruising frontline power window.",
            },
        },
    },
    SPELLBLADE = {
        id = "spellblade",
        name = "Spellblade",
        role = "Arcane Duelist",
        description = "Fast arcane skirmisher who bends mirrors, prisms, and floating blades into burst windows.",
        lore = "A shard-bound duelist who turns motion into magic and magic into steel.",
        baseHP = 92,
        baseATK = 20,
        baseSpeed = 258,
        attackRange = 320,
        attackSpeed = 1.0,
        color = {0.28, 0.84, 1.0},
        secondaryColor = {0.86, 0.64, 1.0},
        abilities = {"Arcane Swords", "Mirror Blink", "Prism Rift", "Astral Ascension"},
        skills = {
            {
                id = "arcane_swords",
                name = "Arcane Swords",
                key = "Q",
                mode = "Manual",
                icon = "arcane_swords",
                summary = "Orbiting blades",
                description = "Summon floating swords that orbit the caster and cut down anything pushing into close range.",
            },
            {
                id = "mirror_blink",
                name = "Mirror Blink",
                key = "SPACE",
                mode = "Manual",
                icon = "mirror_blink",
                summary = "Mirror reposition",
                description = "Blink in your move or facing direction, leaving behind a mirror image that answers with an Energy Wave.",
            },
            {
                id = "prism_rift",
                name = "Prism Rift",
                key = "E",
                mode = "Manual",
                icon = "prism_rift",
                summary = "Setup pull",
                description = "Open a prism rift that drags enemies inward before collapsing into a sharp arcane payoff.",
            },
            {
                id = "astral_ascension",
                name = "Astral Ascension",
                key = "R",
                mode = "Ultimate",
                icon = "astral_ascension",
                summary = "Burst form",
                description = "Transform into an astral duelist and temporarily amplify your primary attack, blink, swords, and rift.",
            },
        },
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

-- Single difficulty (no selection; maps use this by default)
GameState.Difficulties = {
    NORMAL = {
        id = "normal",
        name = "Normal",
        enemyDamageMult = 1.0,
        enemyHealthMult = 1.0,
        playerDamageMult = 1.0,
        xpMult = 1.0
    }
}
-- Default used when starting a run (no difficulty screen)
GameState.DefaultDifficultyKey = "NORMAL"

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

function GameState:transitionTo(newState, instant)
    if instant then
        self.currentState = newState
        self.isTransitioning = false
        self.transitionAlpha = 0
        self.transitionTarget = nil
        return
    end
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
    self.selectedDifficulty = GameState.Difficulties[difficultyKey or GameState.DefaultDifficultyKey]
end

-- Set default difficulty (used when starting a run without a difficulty screen)
function GameState:setDefaultDifficulty()
    self:selectDifficulty(GameState.DefaultDifficultyKey)
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

function GameState:enterBossFight(instant)
    self:transitionTo(GameState.States.BOSS_FIGHT, instant)
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






