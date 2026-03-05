--[[
    RobberySystem - Sistema de robos completo
    Incluye: Joyería, Banco, Camión Blindado
    Con notificaciones a chat privado de policías
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local RobberySystem = {}

-- Cooldowns de robos
local robberyCooldowns = {
    JOYERIA = {},
    BANCO = {},
    CAMION = {},
}

local COOLDOWN_TIME = 600 -- 10 minutos entre robos

-- Estado del camión blindado
local armoredTruckActive = false
local currentTruck = nil

-----------------------------------------------------
-- UTILIDADES
-----------------------------------------------------
local function isOnCooldown(player, robberyType)
    local lastRob = robberyCooldowns[robberyType][player.UserId]
    if lastRob and (os.time() - lastRob) < COOLDOWN_TIME then
        return true, COOLDOWN_TIME - (os.time() - lastRob)
    end
    return false, 0
end

local function setCooldown(player, robberyType)
    robberyCooldowns[robberyType][player.UserId] = os.time()
end

-----------------------------------------------------
-- NOTIFICAR A POLICÍAS
-----------------------------------------------------
local function notifyPolice(message)
    local policeTeam = Teams:FindFirstChild("Policía") or Teams:FindFirstChild("SWAT")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team and (player.Team.Name == "Policía" or player.Team.Name == "SWAT") then
            local policeChatEvent = RemoteEvents.GetEvent("PoliceChatMessage")
            if policeChatEvent then
                policeChatEvent:FireClient(player, "[ALERTA POLICIAL] " .. message)
            end
            
            local notifEvent = RemoteEvents.GetEvent("ShowNotification")
            if notifEvent then
                notifEvent:FireClient(player, {
                    Title = "ALERTA POLICIAL",
                    Text = message,
                    Duration = 10,
                    Type = "Warning",
                })
            end
        end
    end
end

-----------------------------------------------------
-- LOOT ALEATORIO DE JOYERÍA
-----------------------------------------------------
local function getRandomJewelryLoot()
    local lootTable = GameConfig.Shops.JOYERIA.LootTable
    local totalWeight = 0
    
    for _, item in ipairs(lootTable) do
        totalWeight = totalWeight + item.Weight
    end
    
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    
    for _, item in ipairs(lootTable) do
        cumulative = cumulative + item.Weight
        if roll <= cumulative then
            return item
        end
    end
    
    return lootTable[1]
end

-----------------------------------------------------
-- ROBAR JOYERÍA
-----------------------------------------------------
local function robJewelry(player)
    -- Verificar que es criminal
    if not player.Team or player.Team.Name ~= "Criminal" then
        return false, "Debes ser Criminal para robar"
    end
    
    -- Verificar cooldown
    local onCooldown, remaining = isOnCooldown(player, "JOYERIA")
    if onCooldown then
        return false, "Debes esperar " .. remaining .. " segundos para robar de nuevo"
    end
    
    -- Verificar que tiene bolso
    local data = DataManager.GetPlayerData(player)
    if not data then return false, "Error de datos" end
    
    local hasBag = false
    for _, item in ipairs(data.Inventory) do
        if item == "Bolso de Robo" then
            hasBag = true
            break
        end
    end
    
    if not hasBag then
        return false, "Necesitas un Bolso de Robo (cómpralo en el Mercado Negro)"
    end
    
    -- Verificar espacio en bolso
    if #data.BagContents >= data.BagCapacity then
        return false, "Tu bolso está lleno (Límite: " .. data.BagCapacity .. ")"
    end
    
    -- Obtener loot aleatorio
    local loot = getRandomJewelryLoot()
    
    -- Agregar al bolso
    local success, msg = DataManager.AddToBag(player, {
        Name = loot.Name,
        Value = loot.Value,
        Type = "Joyería",
    })
    
    if success then
        setCooldown(player, "JOYERIA")
        data.RobberiesCompleted = data.RobberiesCompleted + 1
        data.CriminalRecord = data.CriminalRecord + 1
        
        -- Actualizar leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            leaderstats.Antecedentes.Value = data.CriminalRecord
        end
        
        -- Notificar a policías
        notifyPolice("¡Están robando la JOYERÍA! Ubicación: Joyería del centro")
        
        -- Notificar al ladrón
        RemoteEvents.GetEvent("RobberyComplete"):FireClient(player, {
            Type = "Joyería",
            Loot = loot.Name,
            Value = loot.Value,
        })
        
        return true, "¡Robaste: " .. loot.Name .. " (Valor: $" .. loot.Value .. ")!"
    end
    
    return false, msg
end

-----------------------------------------------------
-- ROBAR BANCO
-----------------------------------------------------
local function robBank(player)
    -- Verificar que es criminal
    if not player.Team or player.Team.Name ~= "Criminal" then
        return false, "Debes ser Criminal para robar"
    end
    
    -- Verificar cooldown
    local onCooldown, remaining = isOnCooldown(player, "BANCO")
    if onCooldown then
        return false, "Debes esperar " .. remaining .. " segundos para robar de nuevo"
    end
    
    -- Verificar que tiene C4
    local data = DataManager.GetPlayerData(player)
    if not data then return false, "Error de datos" end
    
    local hasC4 = false
    local c4Index = nil
    for i, item in ipairs(data.Inventory) do
        if item == "C4 Explosivo" then
            hasC4 = true
            c4Index = i
            break
        end
    end
    
    if not hasC4 then
        return false, "Necesitas C4 Explosivo (cómpralo en el Mercado Negro)"
    end
    
    -- Usar C4 (remover del inventario)
    table.remove(data.Inventory, c4Index)
    
    -- Dar recompensa
    local reward = GameConfig.Shops.BANCO.Reward
    DataManager.AddCash(player, reward)
    
    -- Actualizar leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        leaderstats.Dinero.Value = data.Cash
    end
    
    setCooldown(player, "BANCO")
    data.RobberiesCompleted = data.RobberiesCompleted + 1
    data.CriminalRecord = data.CriminalRecord + 3
    
    if leaderstats then
        leaderstats.Antecedentes.Value = data.CriminalRecord
    end
    
    -- Notificar a policías
    notifyPolice("¡Están robando el BANCO! ¡Explosión detectada! Ubicación: Banco Central")
    
    -- Notificar al ladrón
    RemoteEvents.GetEvent("RobberyComplete"):FireClient(player, {
        Type = "Banco",
        Reward = reward,
    })
    
    return true, "¡Robaste el banco! Ganaste $" .. reward
end

-----------------------------------------------------
-- CAMIÓN BLINDADO - SPAWN
-----------------------------------------------------
local function spawnArmoredTruck()
    if armoredTruckActive then return end
    
    armoredTruckActive = true
    
    -- Crear el camión blindado (modelo básico)
    local truck = Instance.new("Model")
    truck.Name = "CamionBlindado"
    
    -- Cuerpo principal del camión
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(8, 6, 16)
    body.Position = Vector3.new(0, 5, 0) -- Posición de spawn configurable
    body.Anchored = false
    body.BrickColor = BrickColor.new("Dark stone grey")
    body.Material = Enum.Material.Metal
    body.Parent = truck
    
    -- Hitbox para interacción
    local hitbox = Instance.new("ClickDetector")
    hitbox.MaxActivationDistance = 15
    hitbox.Parent = body
    
    -- BillboardGui para indicador
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = body
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.5
    label.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    label.Text = "CAMIÓN BLINDADO - $1,000,000"
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard
    
    -- Salud del camión
    local healthValue = Instance.new("IntValue")
    healthValue.Name = "Health"
    healthValue.Value = GameConfig.ArmoredTruck.HEALTH
    healthValue.Parent = truck
    
    truck.PrimaryPart = body
    truck.Parent = game.Workspace
    currentTruck = truck
    
    -- Notificar a todos
    for _, player in ipairs(Players:GetPlayers()) do
        RemoteEvents.GetEvent("ArmoredTruckSpawn"):FireClient(player, {
            Message = "¡Un Camión Blindado ha aparecido en el mapa!",
            Position = body.Position,
        })
    end
    
    -- Manejar clic para robar
    hitbox.MouseClick:Connect(function(player)
        if not player.Team or player.Team.Name ~= "Criminal" then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Error",
                Text = "Debes ser Criminal para robar el camión",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        local onCooldown, remaining = isOnCooldown(player, "CAMION")
        if onCooldown then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Cooldown",
                Text = "Espera " .. remaining .. " segundos",
                Duration = 5,
                Type = "Warning",
            })
            return
        end
        
        -- Reducir salud del camión
        local health = healthValue.Value
        health = health - 100
        healthValue.Value = health
        
        if health <= 0 then
            -- Camión robado exitosamente
            local reward = GameConfig.ArmoredTruck.REWARD
            DataManager.AddCash(player, reward)
            
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                leaderstats.Dinero.Value = DataManager.GetPlayerData(player).Cash
            end
            
            local data = DataManager.GetPlayerData(player)
            if data then
                data.RobberiesCompleted = data.RobberiesCompleted + 1
                data.CriminalRecord = data.CriminalRecord + 5
                if leaderstats then
                    leaderstats.Antecedentes.Value = data.CriminalRecord
                end
            end
            
            setCooldown(player, "CAMION")
            
            -- Notificar a policías
            notifyPolice("¡Están robando el CAMIÓN BLINDADO! ¡Envíen refuerzos!")
            
            -- Notificar al ladrón
            RemoteEvents.GetEvent("ArmoredTruckRobbed"):FireClient(player, {
                Reward = reward,
                Message = "¡Robaste el Camión Blindado! Ganaste $" .. reward,
            })
            
            -- Destruir camión
            truck:Destroy()
            currentTruck = nil
            armoredTruckActive = false
        else
            -- Actualizar indicador
            label.Text = "CAMIÓN BLINDADO - Salud: " .. health .. "/" .. GameConfig.ArmoredTruck.HEALTH
            
            -- Notificar a policías
            notifyPolice("¡Están atacando el CAMIÓN BLINDADO! Salud: " .. health)
        end
    end)
    
    -- Auto-destruir si no roban en 30 minutos
    task.delay(1800, function()
        if truck and truck.Parent then
            truck:Destroy()
            currentTruck = nil
            armoredTruckActive = false
            
            for _, player in ipairs(Players:GetPlayers()) do
                RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                    Title = "Camión Blindado",
                    Text = "El camión blindado se ha ido sin ser robado",
                    Duration = 5,
                    Type = "Info",
                })
            end
        end
    end)
end

-----------------------------------------------------
-- SPAWN PERIÓDICO DEL CAMIÓN BLINDADO
-----------------------------------------------------
spawn(function()
    while true do
        wait(GameConfig.ArmoredTruck.SPAWN_INTERVAL)
        spawnArmoredTruck()
    end
end)

-----------------------------------------------------
-- EVENTOS DE ROBO
-----------------------------------------------------
local startRobberyEvent = RemoteEvents.GetEvent("StartRobbery")
if startRobberyEvent then
    startRobberyEvent.OnServerEvent:Connect(function(player, robberyType)
        local success, message
        
        if robberyType == "Joyería" then
            success, message = robJewelry(player)
        elseif robberyType == "Banco" then
            success, message = robBank(player)
        else
            success = false
            message = "Tipo de robo no válido"
        end
        
        RemoteEvents.GetEvent("RobberyUpdate"):FireClient(player, {
            Success = success,
            Message = message,
            Type = robberyType,
        })
    end)
end

-----------------------------------------------------
-- VENDER CONTENIDO DEL BOLSO
-----------------------------------------------------
local function sellBagContents(player)
    local data = DataManager.GetPlayerData(player)
    if not data then return false, "Error de datos" end
    
    local totalValue = 0
    for _, item in ipairs(data.BagContents) do
        totalValue = totalValue + (item.Value or 0)
    end
    
    if totalValue > 0 then
        DataManager.AddCash(player, totalValue)
        DataManager.ClearBag(player)
        
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            leaderstats.Dinero.Value = data.Cash
        end
        
        return true, "Vendiste todo por $" .. totalValue
    end
    
    return false, "Tu bolso está vacío"
end

print("[RobberySystem] Sistema de robos inicializado")
