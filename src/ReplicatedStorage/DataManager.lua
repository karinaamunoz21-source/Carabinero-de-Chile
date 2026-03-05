--[[
    DataManager - Gestión de datos persistentes de jugadores
    Usa DataStoreService para guardar progreso
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local GameConfig = require(script.Parent.GameConfig)

local DataManager = {}

local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
local banDataStore = DataStoreService:GetDataStore("BanData_v1")

-- Cache local de datos de jugador
local playerDataCache = {}

-- Plantilla de datos por defecto
local DEFAULT_DATA = {
    Cash = 1000,
    Team = "Civil",
    Inventory = {},
    BagContents = {},
    BagCapacity = GameConfig.BagSystem.DEFAULT_CAPACITY,
    ExpandedBag = false,
    OwnedClothes = {},
    OwnedShoes = {},
    OwnedPants = {},
    OwnedAccessories = {},
    Tattoos = {
        Face = {},
        Hand = {},
    },
    CriminalRecord = 0,
    ArrestsCount = 0,
    RobberiesCompleted = 0,
    TotalEarnings = 0,
    PrisonTime = 0,
    OwnedGamePasses = {},
    Stats = {
        Kills = 0,
        Deaths = 0,
        Arrests = 0,
        Escapes = 0,
    },
}

function DataManager.LoadPlayerData(player)
    local success, data = pcall(function()
        return playerDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    if success and data then
        -- Merge con datos por defecto para campos nuevos
        for key, value in pairs(DEFAULT_DATA) do
            if data[key] == nil then
                data[key] = value
            end
        end
        playerDataCache[player.UserId] = data
    else
        playerDataCache[player.UserId] = table.clone(DEFAULT_DATA)
    end
    
    return playerDataCache[player.UserId]
end

function DataManager.SavePlayerData(player)
    local data = playerDataCache[player.UserId]
    if not data then return false end
    
    local success, err = pcall(function()
        playerDataStore:SetAsync("Player_" .. player.UserId, data)
    end)
    
    if not success then
        warn("Error al guardar datos de " .. player.Name .. ": " .. tostring(err))
    end
    
    return success
end

function DataManager.GetPlayerData(player)
    return playerDataCache[player.UserId]
end

function DataManager.UpdatePlayerData(player, key, value)
    local data = playerDataCache[player.UserId]
    if data then
        data[key] = value
    end
end

function DataManager.AddCash(player, amount)
    local data = playerDataCache[player.UserId]
    if data then
        data.Cash = data.Cash + amount
        data.TotalEarnings = data.TotalEarnings + math.max(0, amount)
        return data.Cash
    end
    return 0
end

function DataManager.RemoveCash(player, amount)
    local data = playerDataCache[player.UserId]
    if data then
        if data.Cash >= amount then
            data.Cash = data.Cash - amount
            return true, data.Cash
        end
        return false, data.Cash
    end
    return false, 0
end

function DataManager.AddToBag(player, item)
    local data = playerDataCache[player.UserId]
    if not data then return false, "No data" end
    
    if #data.BagContents >= data.BagCapacity then
        return false, "Bolso lleno"
    end
    
    table.insert(data.BagContents, item)
    return true, "Agregado al bolso"
end

function DataManager.ClearBag(player)
    local data = playerDataCache[player.UserId]
    if data then
        data.BagContents = {}
    end
end

function DataManager.GetBagContents(player)
    local data = playerDataCache[player.UserId]
    if data then
        return data.BagContents
    end
    return {}
end

function DataManager.ExpandBag(player)
    local data = playerDataCache[player.UserId]
    if data then
        data.BagCapacity = GameConfig.BagSystem.EXPANDED_CAPACITY
        data.ExpandedBag = true
    end
end

function DataManager.AddTattoo(player, zone, tattooName)
    local data = playerDataCache[player.UserId]
    if data and data.Tattoos[zone] then
        table.insert(data.Tattoos[zone], tattooName)
        return true
    end
    return false
end

-- Sistema de Ban
function DataManager.BanPlayer(userId, reason, duration)
    local banData = {
        Banned = true,
        Reason = reason or "Sin razón especificada",
        BannedAt = os.time(),
        Duration = duration or -1, -- -1 = permanente
    }
    
    local success = pcall(function()
        banDataStore:SetAsync("Ban_" .. userId, banData)
    end)
    
    return success
end

function DataManager.UnbanPlayer(userId)
    local success = pcall(function()
        banDataStore:RemoveAsync("Ban_" .. userId)
    end)
    return success
end

function DataManager.IsPlayerBanned(userId)
    local success, data = pcall(function()
        return banDataStore:GetAsync("Ban_" .. userId)
    end)
    
    if success and data and data.Banned then
        if data.Duration == -1 then
            return true, data.Reason
        end
        if os.time() - data.BannedAt < data.Duration then
            return true, data.Reason
        else
            -- Ban expirado, remover
            DataManager.UnbanPlayer(userId)
            return false, nil
        end
    end
    
    return false, nil
end

function DataManager.CleanupPlayer(player)
    DataManager.SavePlayerData(player)
    playerDataCache[player.UserId] = nil
end

return DataManager
