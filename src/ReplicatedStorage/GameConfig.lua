--[[
    GameConfig - Configuración central del juego
    Carabineros de Chile - Mapa Estilo Pandilla
]]

local GameConfig = {}

-----------------------------------------------------
-- ID DEL GRUPO DE ROBLOX (cambiar por el tuyo)
-----------------------------------------------------
GameConfig.GROUP_ID = 0 -- Cambia este número por el ID de tu grupo de Roblox

-----------------------------------------------------
-- RANGOS DEL GRUPO
-----------------------------------------------------
GameConfig.Ranks = {
    OWNER = 255,
    CO_OWNER = 254,
    MODERATOR = 200,
    SWAT = 150,
    POLICE = 100,
    CIVIL = 1,
}

-----------------------------------------------------
-- GAMEPASSES (IDs - cambiar por los tuyos)
-----------------------------------------------------
GameConfig.GamePasses = {
    LUTEO = 0,              -- Pase para lutear jugadores
    EXPANDIR_BOLSO = 0,     -- Pase para expandir bolso de robo
    SWAT = 0,               -- Pase para rango SWAT
    BARRA = 0,              -- Pase de barra (comandos especiales)
    GENERAR_ARMAS = 0,      -- Pase para generar armas (/sg)
    SERVIDOR_PRIVADO = 0,   -- Pase de servidor privado mensual (100 robux)
}

-----------------------------------------------------
-- EQUIPOS / TEAMS
-----------------------------------------------------
GameConfig.Teams = {
    PD = {
        Name = "Policía",
        Color = BrickColor.new("Bright blue"),
    },
    CIVIL = {
        Name = "Civil",
        Color = BrickColor.new("Bright green"),
    },
    CRIMINAL = {
        Name = "Criminal",
        Color = BrickColor.new("Bright red"),
    },
    SWAT = {
        Name = "SWAT",
        Color = BrickColor.new("Navy blue"),
    },
}

-----------------------------------------------------
-- ARMAS
-----------------------------------------------------
GameConfig.Weapons = {
    PD = {
        { Name = "Pistola Taser", Damage = 0, Type = "Taser", Stun = 5 },
        { Name = "Esposas", Damage = 0, Type = "Cuffs" },
    },
    SWAT = {
        { Name = "Colt M4", Damage = 35, Type = "Rifle", FireRate = 0.12, MagSize = 30 },
        { Name = "HK MP5", Damage = 25, Type = "SMG", FireRate = 0.08, MagSize = 30 },
        { Name = "Rifle Francotirador", Damage = 90, Type = "Sniper", FireRate = 1.5, MagSize = 5 },
        { Name = "Ariete", Damage = 0, Type = "Battering Ram" },
    },
    CRIMINAL = {
        { Name = "C4", Damage = 200, Type = "Explosive", Radius = 20 },
    },
    SPAWN_COMMANDS = {
        ["golden"] = { Name = "Golden Gun", Damage = 100, Type = "Pistol", FireRate = 0.5, MagSize = 7 },
        ["tambor"] = { Name = "Revólver Tambor", Damage = 55, Type = "Revolver", FireRate = 0.6, MagSize = 6 },
        ["arp christmas"] = { Name = "ARP Christmas", Damage = 28, Type = "SMG", FireRate = 0.07, MagSize = 35 },
    },
}

-----------------------------------------------------
-- TIENDAS
-----------------------------------------------------
GameConfig.Shops = {
    ROPA = {
        Name = "Tienda de Ropa",
        Icon = "rbxassetid://0", -- Cambiar por icono real
        Items = {
            { Name = "Camiseta Negra", Price = 500, Category = "Top" },
            { Name = "Camiseta Blanca", Price = 500, Category = "Top" },
            { Name = "Chaqueta Pandilla", Price = 2000, Category = "Top" },
            { Name = "Hoodie Street", Price = 1500, Category = "Top" },
            { Name = "Chaleco Antibalas", Price = 5000, Category = "Top" },
        },
    },
    ZAPATOS = {
        Name = "Tienda de Zapatos",
        Icon = "rbxassetid://0",
        Items = {
            { Name = "Zapatillas Deportivas", Price = 800, Category = "Shoes" },
            { Name = "Botas Militares", Price = 1500, Category = "Shoes" },
            { Name = "Zapatos Elegantes", Price = 1200, Category = "Shoes" },
            { Name = "Jordans Street", Price = 3000, Category = "Shoes" },
        },
    },
    PANTALON = {
        Name = "Tienda de Pantalón",
        Icon = "rbxassetid://0",
        Items = {
            { Name = "Jeans Negro", Price = 600, Category = "Pants" },
            { Name = "Jeans Azul", Price = 600, Category = "Pants" },
            { Name = "Pantalón Cargo", Price = 1000, Category = "Pants" },
            { Name = "Pantalón SWAT", Price = 3000, Category = "Pants" },
        },
    },
    ACCESORIOS = {
        Name = "Tienda de Accesorios",
        Icon = "rbxassetid://0",
        Items = {
            { Name = "Gorra Pandilla", Price = 400, Category = "Hat" },
            { Name = "Lentes de Sol", Price = 300, Category = "Face" },
            { Name = "Pasamontañas", Price = 1500, Category = "Face" },
            { Name = "Cadena Oro", Price = 2500, Category = "Neck" },
            { Name = "Mochila Táctica", Price = 2000, Category = "Back" },
        },
    },
    JOYERIA = {
        Name = "Joyería",
        Icon = "rbxassetid://0",
        Robbable = true,
        LootTable = {
            { Name = "Reloj de Oro", Value = 5000, Weight = 40 },
            { Name = "Reloj de Diamante", Value = 10000, Weight = 20 },
            { Name = "Cadena de Oro", Value = 7000, Weight = 30 },
            { Name = "Cadena de Platino", Value = 15000, Weight = 10 },
        },
    },
    BANCO = {
        Name = "Banco",
        Icon = "rbxassetid://0",
        Robbable = true,
        RequiresC4 = true,
        Reward = 500000,
    },
    MERCADO_NEGRO = {
        Name = "Mercado Negro",
        Icon = "rbxassetid://0",
        Items = {
            { Name = "Bolso de Robo", Price = 5000, Type = "Tool" },
            { Name = "C4 Explosivo", Price = 25000, Type = "Explosive" },
            { Name = "Lockpick", Price = 3000, Type = "Tool" },
            { Name = "Radio Policial", Price = 8000, Type = "Tool" },
        },
    },
    TATUAJES = {
        Name = "Tienda de Tatuajes",
        Icon = "rbxassetid://0",
        Items = {
            { Name = "Tatuaje Cara - Lágrima", Price = 2000, Zone = "Face" },
            { Name = "Tatuaje Cara - Cruz", Price = 2500, Zone = "Face" },
            { Name = "Tatuaje Cara - Estrella", Price = 3000, Zone = "Face" },
            { Name = "Tatuaje Cara - Tribal", Price = 3500, Zone = "Face" },
            { Name = "Tatuaje Mano - Telaraña", Price = 1500, Zone = "Hand" },
            { Name = "Tatuaje Mano - Calavera", Price = 2000, Zone = "Hand" },
            { Name = "Tatuaje Mano - Rosa", Price = 1800, Zone = "Hand" },
            { Name = "Tatuaje Mano - Letras", Price = 2500, Zone = "Hand" },
        },
    },
}

-----------------------------------------------------
-- BOLSO / BAG SYSTEM
-----------------------------------------------------
GameConfig.BagSystem = {
    DEFAULT_CAPACITY = 5,
    EXPANDED_CAPACITY = 20,
    BAG_SLOT_TYPES = { "Reloj", "Cadena", "Joya", "Dinero" },
}

-----------------------------------------------------
-- CAMIÓN BLINDADO
-----------------------------------------------------
GameConfig.ArmoredTruck = {
    SPAWN_INTERVAL = 3600,  -- Cada hora (en segundos)
    REWARD = 1000000,       -- 1 millón por robarlo
    HEALTH = 500,
    SPEED = 30,
}

-----------------------------------------------------
-- PRISIÓN
-----------------------------------------------------
GameConfig.Prison = {
    SENTENCE_TIME = 120,    -- Segundos en prisión
    ESCAPE_DIFFICULTY = 3,  -- Nivel de dificultad para escapar
}

-----------------------------------------------------
-- SERVIDOR PRIVADO
-----------------------------------------------------
GameConfig.PrivateServer = {
    MONTHLY_COST = 100,     -- 100 robux por mes
    MAX_PLAYERS = 20,
}

-----------------------------------------------------
-- COMANDOS MODERADOR
-----------------------------------------------------
GameConfig.ModCommands = {
    "fly", "unfly", "nuke", "/h", "ban", "unban", "kick", "timer",
}

-----------------------------------------------------
-- COMANDOS ADMIN ABUSE (solo owner/co-owner)
-----------------------------------------------------
GameConfig.AdminAbuseCommands = {
    "god", "ungod", "kill", "tp", "bring", "speed", "jump", "respawn", "freeze", "unfreeze",
}

return GameConfig
