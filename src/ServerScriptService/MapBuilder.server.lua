--[[
    MapBuilder - Genera el mapa completo del juego
    Incluye: Bases con interior, PD, Prisión, Tiendas, Calles
    
    Este script crea la estructura básica del mapa.
    Los modelos detallados se pueden reemplazar con modelos
    personalizados en Roblox Studio.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MapBuilder = {}

-- Colores del mapa
local COLORS = {
    Street = BrickColor.new("Dark stone grey"),
    Sidewalk = BrickColor.new("Medium stone grey"),
    Grass = BrickColor.new("Bright green"),
    Building = BrickColor.new("Institutional white"),
    PDBuilding = BrickColor.new("Bright blue"),
    Prison = BrickColor.new("Dark orange"),
    CriminalBase = BrickColor.new("Really red"),
    Floor = BrickColor.new("Cork"),
    Wall = BrickColor.new("Medium stone grey"),
    Door = BrickColor.new("Brown"),
    Metal = BrickColor.new("Dark stone grey"),
}

-----------------------------------------------------
-- UTILIDADES DE CONSTRUCCIÓN
-----------------------------------------------------
local function createPart(name, size, position, color, material, parent, anchored)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.BrickColor = color or BrickColor.new("Medium stone grey")
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = anchored ~= false
    part.Parent = parent or Workspace
    return part
end

local function createModel(name, parent)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent or Workspace
    return model
end

-----------------------------------------------------
-- CREAR TERRENO BASE
-----------------------------------------------------
local function buildTerrain()
    local terrain = createModel("Terrain_Base", Workspace)
    
    -- Suelo principal
    local ground = createPart("Ground", Vector3.new(600, 1, 600), Vector3.new(0, -0.5, 0), 
        BrickColor.new("Bright green"), Enum.Material.Grass, terrain)
    
    -- Calles principales (cruz)
    createPart("MainStreet_NS", Vector3.new(20, 0.2, 600), Vector3.new(0, 0.1, 0), 
        COLORS.Street, Enum.Material.Concrete, terrain)
    createPart("MainStreet_EW", Vector3.new(600, 0.2, 20), Vector3.new(0, 0.1, 0), 
        COLORS.Street, Enum.Material.Concrete, terrain)
    
    -- Aceras
    createPart("Sidewalk_N1", Vector3.new(24, 0.15, 600), Vector3.new(12, 0.08, 0), 
        COLORS.Sidewalk, Enum.Material.Concrete, terrain)
    createPart("Sidewalk_N2", Vector3.new(24, 0.15, 600), Vector3.new(-12, 0.08, 0), 
        COLORS.Sidewalk, Enum.Material.Concrete, terrain)
    
    return terrain
end

-----------------------------------------------------
-- CREAR EDIFICIO GENÉRICO
-----------------------------------------------------
local function buildBuilding(name, position, size, color, shopType, parent)
    local building = createModel(name, parent or Workspace)
    
    local width = size.X or 20
    local height = size.Y or 15
    local depth = size.Z or 20
    
    -- Piso
    local floor = createPart("Floor", Vector3.new(width, 0.5, depth), 
        position + Vector3.new(0, 0.25, 0), COLORS.Floor, Enum.Material.Wood, building)
    
    -- Paredes
    createPart("Wall_Front", Vector3.new(width, height, 1), 
        position + Vector3.new(0, height/2, -depth/2), color or COLORS.Building, Enum.Material.Concrete, building)
    createPart("Wall_Back", Vector3.new(width, height, 1), 
        position + Vector3.new(0, height/2, depth/2), color or COLORS.Building, Enum.Material.Concrete, building)
    createPart("Wall_Left", Vector3.new(1, height, depth), 
        position + Vector3.new(-width/2, height/2, 0), color or COLORS.Building, Enum.Material.Concrete, building)
    createPart("Wall_Right", Vector3.new(1, height, depth), 
        position + Vector3.new(width/2, height/2, 0), color or COLORS.Building, Enum.Material.Concrete, building)
    
    -- Techo
    createPart("Roof", Vector3.new(width + 2, 0.5, depth + 2), 
        position + Vector3.new(0, height, 0), COLORS.Metal, Enum.Material.Metal, building)
    
    -- Puerta
    local door = createPart("Door", Vector3.new(4, 7, 1), 
        position + Vector3.new(0, 3.5, -depth/2), COLORS.Door, Enum.Material.Wood, building)
    door.CanCollide = true
    
    -- Agregar atributo de tipo de tienda
    if shopType then
        floor:SetAttribute("ShopType", shopType)
        door:SetAttribute("ShopType", shopType)
        
        -- ClickDetector para entrar a la tienda
        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 10
        clickDetector.Parent = door
    end
    
    building.PrimaryPart = floor
    return building
end

-----------------------------------------------------
-- CREAR BASE DE PANDILLA (con interior)
-----------------------------------------------------
local function buildGangBase(name, position, parent)
    local base = createModel(name, parent or Workspace)
    
    local width = 30
    local height = 12
    local depth = 25
    
    -- Estructura exterior
    local floor = createPart("Floor", Vector3.new(width, 0.5, depth), 
        position + Vector3.new(0, 0.25, 0), COLORS.Floor, Enum.Material.Concrete, base)
    
    -- Paredes exteriores (estilo urbano/graffiti)
    createPart("Wall_Front", Vector3.new(width, height, 1.5), 
        position + Vector3.new(0, height/2, -depth/2), COLORS.CriminalBase, Enum.Material.Concrete, base)
    createPart("Wall_Back", Vector3.new(width, height, 1.5), 
        position + Vector3.new(0, height/2, depth/2), BrickColor.new("Dark stone grey"), Enum.Material.Concrete, base)
    createPart("Wall_Left", Vector3.new(1.5, height, depth), 
        position + Vector3.new(-width/2, height/2, 0), BrickColor.new("Dark stone grey"), Enum.Material.Concrete, base)
    createPart("Wall_Right", Vector3.new(1.5, height, depth), 
        position + Vector3.new(width/2, height/2, 0), BrickColor.new("Dark stone grey"), Enum.Material.Concrete, base)
    
    -- Techo
    createPart("Roof", Vector3.new(width + 2, 0.5, depth + 2), 
        position + Vector3.new(0, height, 0), COLORS.Metal, Enum.Material.Metal, base)
    
    -- PUERTA DE GRUPO (vinculada al grupo de Roblox)
    local groupDoor = createPart("GroupDoor", Vector3.new(5, 8, 1.5), 
        position + Vector3.new(0, 4, -depth/2), BrickColor.new("Bright red"), Enum.Material.Metal, base)
    groupDoor:SetAttribute("GroupDoor", true)
    groupDoor.CanCollide = true
    
    -- Texto en la puerta
    local doorBillboard = Instance.new("BillboardGui")
    doorBillboard.Size = UDim2.new(0, 150, 0, 40)
    doorBillboard.StudsOffset = Vector3.new(0, 3, 0)
    doorBillboard.Parent = groupDoor
    
    local doorLabel = Instance.new("TextLabel")
    doorLabel.Size = UDim2.new(1, 0, 1, 0)
    doorLabel.BackgroundTransparency = 0.3
    doorLabel.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    doorLabel.Text = "BASE - SOLO MIEMBROS"
    doorLabel.TextColor3 = Color3.new(1, 1, 1)
    doorLabel.Font = Enum.Font.GothamBold
    doorLabel.TextScaled = true
    doorLabel.Parent = doorBillboard
    
    -- INTERIOR: CASILLERO
    local locker = createPart("Locker", Vector3.new(3, 6, 1.5), 
        position + Vector3.new(-10, 3, 8), BrickColor.new("Medium stone grey"), Enum.Material.Metal, base)
    
    local lockerLabel = Instance.new("BillboardGui")
    lockerLabel.Size = UDim2.new(0, 100, 0, 30)
    lockerLabel.StudsOffset = Vector3.new(0, 2, 0)
    lockerLabel.Parent = locker
    
    local lockerText = Instance.new("TextLabel")
    lockerText.Size = UDim2.new(1, 0, 1, 0)
    lockerText.BackgroundTransparency = 0.3
    lockerText.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    lockerText.Text = "CASILLERO"
    lockerText.TextColor3 = Color3.new(1, 1, 1)
    lockerText.Font = Enum.Font.GothamBold
    lockerText.TextScaled = true
    lockerText.Parent = lockerLabel
    
    local lockerClick = Instance.new("ClickDetector")
    lockerClick.MaxActivationDistance = 8
    lockerClick.Parent = locker
    
    -- INTERIOR: BOLSO DE ROPA
    local clothingBag = createPart("ClothingBag", Vector3.new(2, 3, 2), 
        position + Vector3.new(-6, 1.5, 8), BrickColor.new("Reddish brown"), Enum.Material.Fabric, base)
    
    local bagLabel = Instance.new("BillboardGui")
    bagLabel.Size = UDim2.new(0, 120, 0, 30)
    bagLabel.StudsOffset = Vector3.new(0, 1.5, 0)
    bagLabel.Parent = clothingBag
    
    local bagText = Instance.new("TextLabel")
    bagText.Size = UDim2.new(1, 0, 1, 0)
    bagText.BackgroundTransparency = 0.3
    bagText.BackgroundColor3 = Color3.fromRGB(100, 50, 30)
    bagText.Text = "BOLSO DE ROPA"
    bagText.TextColor3 = Color3.new(1, 1, 1)
    bagText.Font = Enum.Font.GothamBold
    bagText.TextScaled = true
    bagText.Parent = bagLabel
    
    local bagClick = Instance.new("ClickDetector")
    bagClick.MaxActivationDistance = 8
    bagClick.Parent = clothingBag
    
    -- Mesa interior
    createPart("Table", Vector3.new(6, 1, 3), 
        position + Vector3.new(5, 2, 5), BrickColor.new("Brown"), Enum.Material.Wood, base)
    
    -- Sillas
    createPart("Chair1", Vector3.new(2, 2, 2), 
        position + Vector3.new(3, 1, 8), BrickColor.new("Dark stone grey"), Enum.Material.Plastic, base)
    createPart("Chair2", Vector3.new(2, 2, 2), 
        position + Vector3.new(7, 1, 8), BrickColor.new("Dark stone grey"), Enum.Material.Plastic, base)
    
    -- Iluminación interior
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range = 30
    light.Color = Color3.fromRGB(255, 200, 150)
    light.Parent = floor
    
    base.PrimaryPart = floor
    return base
end

-----------------------------------------------------
-- CREAR DEPARTAMENTO DE POLICÍA (PD)
-----------------------------------------------------
local function buildPoliceStation(position, parent)
    local pd = createModel("DepartamentoPD", parent or Workspace)
    
    local width = 40
    local height = 18
    local depth = 35
    
    -- Estructura
    local floor = createPart("Floor", Vector3.new(width, 0.5, depth), 
        position + Vector3.new(0, 0.25, 0), COLORS.Floor, Enum.Material.Marble, pd)
    
    createPart("Wall_Front", Vector3.new(width, height, 1.5), 
        position + Vector3.new(0, height/2, -depth/2), COLORS.PDBuilding, Enum.Material.Concrete, pd)
    createPart("Wall_Back", Vector3.new(width, height, 1.5), 
        position + Vector3.new(0, height/2, depth/2), COLORS.PDBuilding, Enum.Material.Concrete, pd)
    createPart("Wall_Left", Vector3.new(1.5, height, depth), 
        position + Vector3.new(-width/2, height/2, 0), COLORS.PDBuilding, Enum.Material.Concrete, pd)
    createPart("Wall_Right", Vector3.new(1.5, height, depth), 
        position + Vector3.new(width/2, height/2, 0), COLORS.PDBuilding, Enum.Material.Concrete, pd)
    
    createPart("Roof", Vector3.new(width + 2, 0.5, depth + 2), 
        position + Vector3.new(0, height, 0), COLORS.Metal, Enum.Material.Metal, pd)
    
    -- Puerta principal PD
    local pdDoor = createPart("PD_Door", Vector3.new(6, 9, 1.5), 
        position + Vector3.new(0, 4.5, -depth/2), BrickColor.new("Bright blue"), Enum.Material.Metal, pd)
    
    local pdBillboard = Instance.new("BillboardGui")
    pdBillboard.Size = UDim2.new(0, 250, 0, 60)
    pdBillboard.StudsOffset = Vector3.new(0, 6, 0)
    pdBillboard.AlwaysOnTop = true
    pdBillboard.Parent = pdDoor
    
    local pdLabel = Instance.new("TextLabel")
    pdLabel.Size = UDim2.new(1, 0, 1, 0)
    pdLabel.BackgroundTransparency = 0.2
    pdLabel.BackgroundColor3 = Color3.fromRGB(0, 50, 150)
    pdLabel.Text = "DEPARTAMENTO DE POLICÍA"
    pdLabel.TextColor3 = Color3.new(1, 1, 1)
    pdLabel.Font = Enum.Font.GothamBold
    pdLabel.TextScaled = true
    pdLabel.Parent = pdBillboard
    
    -- Interior: Armería
    local armorySign = createPart("ArmorySign", Vector3.new(6, 1, 0.5), 
        position + Vector3.new(-12, 10, 12), COLORS.PDBuilding, Enum.Material.Neon, pd)
    
    local armoryBillboard = Instance.new("BillboardGui")
    armoryBillboard.Size = UDim2.new(0, 120, 0, 30)
    armoryBillboard.StudsOffset = Vector3.new(0, 1, 0)
    armoryBillboard.Parent = armorySign
    
    local armoryLabel = Instance.new("TextLabel")
    armoryLabel.Size = UDim2.new(1, 0, 1, 0)
    armoryLabel.BackgroundTransparency = 1
    armoryLabel.Text = "ARMERÍA"
    armoryLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    armoryLabel.Font = Enum.Font.GothamBold
    armoryLabel.TextScaled = true
    armoryLabel.Parent = armoryBillboard
    
    -- Escritorios
    createPart("Desk1", Vector3.new(4, 1.5, 2), 
        position + Vector3.new(-10, 1, 0), BrickColor.new("Brown"), Enum.Material.Wood, pd)
    createPart("Desk2", Vector3.new(4, 1.5, 2), 
        position + Vector3.new(-4, 1, 0), BrickColor.new("Brown"), Enum.Material.Wood, pd)
    createPart("Desk3", Vector3.new(4, 1.5, 2), 
        position + Vector3.new(4, 1, 0), BrickColor.new("Brown"), Enum.Material.Wood, pd)
    
    -- Spawn point para policías
    local pdSpawn = Instance.new("SpawnLocation")
    pdSpawn.Name = "PD_Spawn"
    pdSpawn.Size = Vector3.new(6, 1, 6)
    pdSpawn.Position = position + Vector3.new(10, 0.5, 5)
    pdSpawn.BrickColor = COLORS.PDBuilding
    pdSpawn.Material = Enum.Material.Neon
    pdSpawn.Neutral = false
    pdSpawn.TeamColor = BrickColor.new("Bright blue")
    pdSpawn.Parent = pd
    
    -- Iluminación
    local light = Instance.new("PointLight")
    light.Brightness = 3
    light.Range = 40
    light.Color = Color3.fromRGB(200, 220, 255)
    light.Parent = floor
    
    pd.PrimaryPart = floor
    return pd
end

-----------------------------------------------------
-- CREAR PRISIÓN
-----------------------------------------------------
local function buildPrison(position, parent)
    local prison = createModel("Prisión", parent or Workspace)
    
    local width = 50
    local height = 15
    local depth = 40
    
    -- Estructura
    local floor = createPart("Floor", Vector3.new(width, 0.5, depth), 
        position + Vector3.new(0, 0.25, 0), COLORS.Floor, Enum.Material.Concrete, prison)
    
    createPart("Wall_Front", Vector3.new(width, height, 2), 
        position + Vector3.new(0, height/2, -depth/2), COLORS.Prison, Enum.Material.Concrete, prison)
    createPart("Wall_Back", Vector3.new(width, height, 2), 
        position + Vector3.new(0, height/2, depth/2), COLORS.Prison, Enum.Material.Concrete, prison)
    createPart("Wall_Left", Vector3.new(2, height, depth), 
        position + Vector3.new(-width/2, height/2, 0), COLORS.Prison, Enum.Material.Concrete, prison)
    createPart("Wall_Right", Vector3.new(2, height, depth), 
        position + Vector3.new(width/2, height/2, 0), COLORS.Prison, Enum.Material.Concrete, prison)
    
    -- Techo con rejas
    createPart("Roof", Vector3.new(width + 2, 0.5, depth + 2), 
        position + Vector3.new(0, height, 0), COLORS.Metal, Enum.Material.DiamondPlate, prison)
    
    -- Celdas (3 celdas)
    for i = 0, 2 do
        local cellX = -15 + (i * 15)
        
        -- Paredes de celda
        createPart("Cell_Wall_" .. i, Vector3.new(0.5, 10, 12), 
            position + Vector3.new(cellX - 5, 5, 5), COLORS.Wall, Enum.Material.Concrete, prison)
        createPart("Cell_Wall2_" .. i, Vector3.new(0.5, 10, 12), 
            position + Vector3.new(cellX + 5, 5, 5), COLORS.Wall, Enum.Material.Concrete, prison)
        
        -- Rejas de celda
        local bars = createPart("Cell_Bars_" .. i, Vector3.new(10, 10, 0.5), 
            position + Vector3.new(cellX, 5, -1), BrickColor.new("Black"), Enum.Material.Metal, prison)
        bars.Transparency = 0.3
        
        -- Cama
        createPart("Cell_Bed_" .. i, Vector3.new(3, 1, 6), 
            position + Vector3.new(cellX + 2, 1, 8), BrickColor.new("Medium stone grey"), Enum.Material.Fabric, prison)
        
        -- Spawn en celda
        local cellSpawn = Instance.new("SpawnLocation")
        cellSpawn.Name = "Prison_Spawn_" .. i
        cellSpawn.Size = Vector3.new(4, 1, 4)
        cellSpawn.Position = position + Vector3.new(cellX, 0.5, 5)
        cellSpawn.BrickColor = COLORS.Prison
        cellSpawn.Neutral = false
        cellSpawn.Enabled = false -- No auto-spawn aquí
        cellSpawn.Parent = prison
    end
    
    -- Letrero
    local prisonBillboard = Instance.new("BillboardGui")
    prisonBillboard.Size = UDim2.new(0, 200, 0, 50)
    prisonBillboard.StudsOffset = Vector3.new(0, 12, 0)
    prisonBillboard.AlwaysOnTop = true
    prisonBillboard.Parent = floor
    
    local prisonLabel = Instance.new("TextLabel")
    prisonLabel.Size = UDim2.new(1, 0, 1, 0)
    prisonLabel.BackgroundTransparency = 0.2
    prisonLabel.BackgroundColor3 = Color3.fromRGB(150, 80, 0)
    prisonLabel.Text = "PRISIÓN"
    prisonLabel.TextColor3 = Color3.new(1, 1, 1)
    prisonLabel.Font = Enum.Font.GothamBold
    prisonLabel.TextScaled = true
    prisonLabel.Parent = prisonBillboard
    
    prison.PrimaryPart = floor
    return prison
end

-----------------------------------------------------
-- CONSTRUIR MAPA COMPLETO
-----------------------------------------------------
local function buildMap()
    local map = createModel("Map_Pandilla", Workspace)
    
    -- 1. Terreno base
    buildTerrain()
    
    -- 2. Departamento de Policía
    buildPoliceStation(Vector3.new(-80, 0, -80), map)
    
    -- 3. Prisión
    buildPrison(Vector3.new(200, 0, 200), map)
    
    -- 4. Base de Pandilla 1
    buildGangBase("Base_Pandilla_1", Vector3.new(80, 0, -80), map)
    
    -- 5. Base de Pandilla 2
    buildGangBase("Base_Pandilla_2", Vector3.new(80, 0, 80), map)
    
    -- 6. TIENDAS
    -- Tienda de Ropa
    buildBuilding("Tienda_Ropa", Vector3.new(-40, 0, 30), 
        Vector3.new(18, 12, 15), BrickColor.new("Lavender"), "ROPA", map)
    
    -- Tienda de Zapatos
    buildBuilding("Tienda_Zapatos", Vector3.new(-40, 0, 55), 
        Vector3.new(16, 12, 14), BrickColor.new("Nougat"), "ZAPATOS", map)
    
    -- Tienda de Pantalón
    buildBuilding("Tienda_Pantalon", Vector3.new(-40, 0, 80), 
        Vector3.new(16, 12, 14), BrickColor.new("Pastel Blue"), "PANTALON", map)
    
    -- Tienda de Accesorios
    buildBuilding("Tienda_Accesorios", Vector3.new(-40, 0, 105), 
        Vector3.new(16, 12, 14), BrickColor.new("Hot pink"), "ACCESORIOS", map)
    
    -- Joyería
    buildBuilding("Joyería", Vector3.new(40, 0, 30), 
        Vector3.new(22, 14, 18), BrickColor.new("Gold"), "JOYERIA", map)
    
    -- Banco
    buildBuilding("Banco", Vector3.new(40, 0, 60), 
        Vector3.new(25, 16, 20), BrickColor.new("Sand green"), "BANCO", map)
    
    -- Mercado Negro
    buildBuilding("Mercado_Negro", Vector3.new(40, 0, 95), 
        Vector3.new(18, 10, 16), BrickColor.new("Black"), "MERCADO_NEGRO", map)
    
    -- Tienda de Tatuajes
    buildBuilding("Tienda_Tatuajes", Vector3.new(40, 0, 120), 
        Vector3.new(16, 12, 14), BrickColor.new("Maroon"), "TATUAJES", map)
    
    -- 7. Spawn points
    -- Spawn Civil (centro)
    local civilSpawn = Instance.new("SpawnLocation")
    civilSpawn.Name = "Civil_Spawn"
    civilSpawn.Size = Vector3.new(8, 1, 8)
    civilSpawn.Position = Vector3.new(0, 0.5, 0)
    civilSpawn.BrickColor = BrickColor.new("Bright green")
    civilSpawn.Material = Enum.Material.Neon
    civilSpawn.Neutral = true
    civilSpawn.Parent = map
    
    -- Spawn Criminal
    local criminalSpawn = Instance.new("SpawnLocation")
    criminalSpawn.Name = "Criminal_Spawn"
    criminalSpawn.Size = Vector3.new(6, 1, 6)
    criminalSpawn.Position = Vector3.new(80, 0.5, 0)
    criminalSpawn.BrickColor = BrickColor.new("Bright red")
    criminalSpawn.Material = Enum.Material.Neon
    criminalSpawn.Neutral = false
    criminalSpawn.TeamColor = BrickColor.new("Bright red")
    criminalSpawn.Parent = map
    
    -- SWAT Spawn
    local swatSpawn = Instance.new("SpawnLocation")
    swatSpawn.Name = "SWAT_Spawn"
    swatSpawn.Size = Vector3.new(6, 1, 6)
    swatSpawn.Position = Vector3.new(-80, 0.5, -60)
    swatSpawn.BrickColor = BrickColor.new("Navy blue")
    swatSpawn.Material = Enum.Material.Neon
    swatSpawn.Neutral = false
    swatSpawn.TeamColor = BrickColor.new("Navy blue")
    swatSpawn.Parent = map
    
    -- 8. Ruta del camión blindado (waypoints)
    local truckRoute = createModel("TruckRoute", map)
    local waypoints = {
        Vector3.new(-100, 2, -50),
        Vector3.new(-50, 2, -50),
        Vector3.new(0, 2, -50),
        Vector3.new(50, 2, -50),
        Vector3.new(100, 2, -50),
        Vector3.new(100, 2, 0),
        Vector3.new(100, 2, 50),
        Vector3.new(50, 2, 50),
        Vector3.new(0, 2, 50),
        Vector3.new(-50, 2, 50),
        Vector3.new(-100, 2, 50),
        Vector3.new(-100, 2, 0),
    }
    
    for i, pos in ipairs(waypoints) do
        local wp = createPart("Waypoint_" .. i, Vector3.new(1, 1, 1), pos, 
            BrickColor.new("Bright yellow"), Enum.Material.Neon, truckRoute)
        wp.Transparency = 1 -- Invisible
        wp:SetAttribute("WaypointIndex", i)
    end
    
    print("[MapBuilder] Mapa construido exitosamente")
    print("[MapBuilder] Edificios: PD, Prisión, 2 Bases, 8 Tiendas")
    
    return map
end

-----------------------------------------------------
-- INICIALIZAR
-----------------------------------------------------
task.wait(1)
buildMap()

print("[MapBuilder] ===== MAPA COMPLETO GENERADO =====")
