--[[
    RemoteEvents - Configuración de todos los RemoteEvents y RemoteFunctions
    Se crean al inicio del servidor
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- Lista de todos los eventos remotos necesarios
local eventNames = {
    -- Equipos / Teams
    "ChangeTeam",
    "TeamChanged",
    
    -- Tiendas
    "OpenShop",
    "PurchaseItem",
    "PurchaseResult",
    
    -- Robos
    "StartRobbery",
    "RobberyUpdate",
    "RobberyComplete",
    "PoliceAlert",
    
    -- Camión Blindado
    "ArmoredTruckSpawn",
    "ArmoredTruckRobbed",
    
    -- Bolso / Bag
    "UpdateBag",
    "BagContentsChanged",
    
    -- Luteo
    "LootPlayer",
    "LootResult",
    
    -- Armas
    "GiveWeapon",
    "SpawnWeapon",
    
    -- Prisión
    "SendToPrison",
    "PrisonEscape",
    "PrisonRelease",
    
    -- Tatuajes
    "ApplyTattoo",
    "TattooApplied",
    
    -- Puerta de Grupo
    "GroupDoorInteract",
    "DoorAccessResult",
    
    -- Base Interior
    "UseLocker",
    "UseClothingBag",
    
    -- Comandos
    "ExecuteCommand",
    "CommandResult",
    "AdminCommand",
    "AdminCommandResult",
    
    -- SWAT
    "SpawnSWATTruck",
    "SWATTruckSpawned",
    
    -- Chat Privado Policía
    "PoliceChatMessage",
    
    -- Notificaciones
    "ShowNotification",
    
    -- Servidor Privado
    "RenewServer",
    "ServerRenewed",
    
    -- Leaderboard
    "UpdateLeaderboard",
    
    -- Weapon Spawn Commands
    "WeaponSpawnCommand",
}

-- Lista de RemoteFunctions
local functionNames = {
    "GetPlayerData",
    "GetShopItems",
    "GetBagContents",
    "GetLeaderboard",
    "CheckGamePass",
    "GetPlayerTeam",
}

function RemoteEvents.Init()
    local eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "RemoteEvents"
    eventsFolder.Parent = ReplicatedStorage
    
    local functionsFolder = Instance.new("Folder")
    functionsFolder.Name = "RemoteFunctions"
    functionsFolder.Parent = ReplicatedStorage
    
    for _, name in ipairs(eventNames) do
        local event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = eventsFolder
    end
    
    for _, name in ipairs(functionNames) do
        local func = Instance.new("RemoteFunction")
        func.Name = name
        func.Parent = functionsFolder
    end
end

function RemoteEvents.GetEvent(name)
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if folder then
        return folder:FindFirstChild(name)
    end
    return nil
end

function RemoteEvents.GetFunction(name)
    local folder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
    if folder then
        return folder:FindFirstChild(name)
    end
    return nil
end

return RemoteEvents
