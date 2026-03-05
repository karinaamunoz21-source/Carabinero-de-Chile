--[[
    SWATSystem - Sistema SWAT completo
    Requiere GamePass SWAT para acceder al rango
    Incluye camión blindado SWAT y comando "spawn swat"
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local SWATSystem = {}

-- Camiones SWAT activos por jugador
local activeSWATTrucks = {}

-- Posición de spawn del camión SWAT
local SWAT_TRUCK_SPAWN = Vector3.new(50, 5, 50)

-----------------------------------------------------
-- VERIFICAR PASE SWAT
-----------------------------------------------------
local function hasSWATPass(player)
    local data = DataManager.GetPlayerData(player)
    if data and data.OwnedGamePasses and data.OwnedGamePasses["SWAT"] then
        return true
    end
    
    local passId = GameConfig.GamePasses.SWAT
    if passId > 0 then
        local success, hasPass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
        end)
        if success and hasPass then
            if data then
                data.OwnedGamePasses["SWAT"] = true
            end
            return true
        end
    end
    
    return false
end

-----------------------------------------------------
-- UNIRSE A SWAT
-----------------------------------------------------
local function joinSWAT(player)
    if not hasSWATPass(player) then
        return false, "Necesitas el Pase SWAT para unirte al equipo SWAT"
    end
    
    local swatTeam = Teams:FindFirstChild("SWAT")
    if not swatTeam then
        return false, "Equipo SWAT no encontrado"
    end
    
    player.Team = swatTeam
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        leaderstats.Equipo.Value = "SWAT"
    end
    
    local data = DataManager.GetPlayerData(player)
    if data then
        data.Team = "SWAT"
    end
    
    return true, "¡Te has unido al equipo SWAT!"
end

-----------------------------------------------------
-- SPAWN CAMIÓN BLINDADO SWAT
-----------------------------------------------------
local function spawnSWATTruck(player)
    if not hasSWATPass(player) then
        return false, "Necesitas el Pase SWAT para generar el camión blindado"
    end
    
    -- Verificar que es SWAT
    if not player.Team or player.Team.Name ~= "SWAT" then
        return false, "Debes estar en el equipo SWAT"
    end
    
    -- Destruir camión anterior si existe
    if activeSWATTrucks[player.UserId] then
        local oldTruck = activeSWATTrucks[player.UserId]
        if oldTruck and oldTruck.Parent then
            oldTruck:Destroy()
        end
    end
    
    -- Crear camión SWAT
    local truck = Instance.new("Model")
    truck.Name = "SWAT_Truck_" .. player.Name
    
    -- Cuerpo principal
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(10, 7, 18)
    body.BrickColor = BrickColor.new("Navy blue")
    body.Material = Enum.Material.Metal
    body.Anchored = false
    body.Parent = truck
    
    -- Cab (cabina)
    local cab = Instance.new("Part")
    cab.Name = "Cab"
    cab.Size = Vector3.new(8, 4, 6)
    cab.Position = body.Position + Vector3.new(0, 2, -10)
    cab.BrickColor = BrickColor.new("Navy blue")
    cab.Material = Enum.Material.Metal
    cab.Parent = truck
    
    -- Ventanas
    local windshield = Instance.new("Part")
    windshield.Name = "Windshield"
    windshield.Size = Vector3.new(7, 3, 0.2)
    windshield.Position = cab.Position + Vector3.new(0, 0.5, -3)
    windshield.BrickColor = BrickColor.new("Institutional white")
    windshield.Material = Enum.Material.Glass
    windshield.Transparency = 0.5
    windshield.Parent = truck
    
    -- Texto "SWAT"
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = body
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 80)
    label.Text = "SWAT - " .. player.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard
    
    -- Ruedas
    local wheelPositions = {
        Vector3.new(-4, -3.5, -5),
        Vector3.new(4, -3.5, -5),
        Vector3.new(-4, -3.5, 5),
        Vector3.new(4, -3.5, 5),
    }
    
    for i, pos in ipairs(wheelPositions) do
        local wheel = Instance.new("Part")
        wheel.Name = "Wheel_" .. i
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Size = Vector3.new(1.5, 3, 3)
        wheel.Position = body.Position + pos
        wheel.BrickColor = BrickColor.new("Black")
        wheel.Material = Enum.Material.SmoothPlastic
        wheel.Parent = truck
        
        -- Soldar rueda al cuerpo
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body
        weld.Part1 = wheel
        weld.Parent = wheel
    end
    
    -- Soldar cabina al cuerpo
    local cabWeld = Instance.new("WeldConstraint")
    cabWeld.Part0 = body
    cabWeld.Part1 = cab
    cabWeld.Parent = cab
    
    local wsWeld = Instance.new("WeldConstraint")
    wsWeld.Part0 = cab
    wsWeld.Part1 = windshield
    wsWeld.Parent = windshield
    
    -- Seat para conducir
    local seat = Instance.new("VehicleSeat")
    seat.Name = "DriverSeat"
    seat.Size = Vector3.new(2, 1, 2)
    seat.Position = cab.Position + Vector3.new(0, -1, 0)
    seat.MaxSpeed = 80
    seat.Torque = 20
    seat.TurnSpeed = 5
    seat.Parent = truck
    
    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = cab
    seatWeld.Part1 = seat
    seatWeld.Parent = seat
    
    -- Posicionar el camión
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local spawnPos = character.HumanoidRootPart.Position + character.HumanoidRootPart.CFrame.LookVector * 15
        body.Position = spawnPos + Vector3.new(0, 5, 0)
    else
        body.Position = SWAT_TRUCK_SPAWN
    end
    
    truck.PrimaryPart = body
    truck.Parent = workspace
    
    activeSWATTrucks[player.UserId] = truck
    
    -- Auto-destruir después de 30 minutos
    task.delay(1800, function()
        if truck and truck.Parent then
            truck:Destroy()
            activeSWATTrucks[player.UserId] = nil
        end
    end)
    
    return true, "¡Camión blindado SWAT generado!"
end

-----------------------------------------------------
-- MANEJAR CHAT PARA "spawn swat"
-----------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        local lowerMsg = string.lower(message)
        
        if lowerMsg == "spawn swat" then
            local success, msg = spawnSWATTruck(player)
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = success and "SWAT" or "Error",
                Text = msg,
                Duration = 5,
                Type = success and "Success" or "Error",
            })
        elseif lowerMsg == "join swat" then
            local success, msg = joinSWAT(player)
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = success and "SWAT" or "Error",
                Text = msg,
                Duration = 5,
                Type = success and "Success" or "Error",
            })
        end
    end)
end)

-----------------------------------------------------
-- EVENTO: SPAWN SWAT TRUCK
-----------------------------------------------------
local spawnEvent = RemoteEvents.GetEvent("SpawnSWATTruck")
if spawnEvent then
    spawnEvent.OnServerEvent:Connect(function(player)
        local success, msg = spawnSWATTruck(player)
        RemoteEvents.GetEvent("SWATTruckSpawned"):FireClient(player, {
            Success = success,
            Message = msg,
        })
    end)
end

-----------------------------------------------------
-- LIMPIAR AL SALIR
-----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    if activeSWATTrucks[player.UserId] then
        local truck = activeSWATTrucks[player.UserId]
        if truck and truck.Parent then
            truck:Destroy()
        end
        activeSWATTrucks[player.UserId] = nil
    end
end)

print("[SWATSystem] Sistema SWAT inicializado")
print("[SWATSystem] Escribe 'spawn swat' en el chat para generar el camión blindado")
