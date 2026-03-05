--[[
    LootingSystem - Sistema de luteo de jugadores
    Requiere GamePass "Luteo" para poder lutear
    Sistema de bolso con límite expandible
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local LootingSystem = {}

-- Cooldown de luteo (evitar spam)
local lootCooldowns = {}
local LOOT_COOLDOWN = 30 -- 30 segundos entre luteos

-----------------------------------------------------
-- VERIFICAR PASE DE LUTEO
-----------------------------------------------------
local function hasLootPass(player)
    local data = DataManager.GetPlayerData(player)
    if data and data.OwnedGamePasses and data.OwnedGamePasses["LUTEO"] then
        return true
    end
    
    -- Verificar en tiempo real
    local passId = GameConfig.GamePasses.LUTEO
    if passId > 0 then
        local success, hasPass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
        end)
        if success and hasPass then
            if data then
                data.OwnedGamePasses["LUTEO"] = true
            end
            return true
        end
    end
    
    return false
end

-----------------------------------------------------
-- LUTEAR JUGADOR
-----------------------------------------------------
local function lootPlayer(looter, targetPlayer)
    -- Verificar que tiene el pase
    if not hasLootPass(looter) then
        return false, "Necesitas el Pase de Luteo para poder lutear jugadores"
    end
    
    -- Verificar cooldown
    if lootCooldowns[looter.UserId] and (os.time() - lootCooldowns[looter.UserId]) < LOOT_COOLDOWN then
        local remaining = LOOT_COOLDOWN - (os.time() - lootCooldowns[looter.UserId])
        return false, "Debes esperar " .. remaining .. " segundos para lutear de nuevo"
    end
    
    -- Verificar que el objetivo está muerto o noqueado
    local targetCharacter = targetPlayer.Character
    if not targetCharacter then
        return false, "El jugador no tiene personaje"
    end
    
    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
    if targetHumanoid and targetHumanoid.Health > 0 then
        return false, "El jugador debe estar eliminado para poder lutearlo"
    end
    
    -- Verificar distancia
    local looterCharacter = looter.Character
    if not looterCharacter or not looterCharacter:FindFirstChild("HumanoidRootPart") then
        return false, "Error de personaje"
    end
    
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        return false, "Error: objetivo no tiene posición"
    end
    
    local distance = (looterCharacter.HumanoidRootPart.Position - targetRoot.Position).Magnitude
    if distance > 10 then
        return false, "Estás demasiado lejos del jugador (máx 10 studs)"
    end
    
    -- Obtener datos del objetivo
    local targetData = DataManager.GetPlayerData(targetPlayer)
    local looterData = DataManager.GetPlayerData(looter)
    
    if not targetData or not looterData then
        return false, "Error de datos"
    end
    
    -- Lutear dinero (50% del dinero del objetivo)
    local lootAmount = math.floor(targetData.Cash * 0.5)
    if lootAmount > 0 then
        DataManager.RemoveCash(targetPlayer, lootAmount)
        DataManager.AddCash(looter, lootAmount)
        
        -- Actualizar leaderstats
        local looterStats = looter:FindFirstChild("leaderstats")
        local targetStats = targetPlayer:FindFirstChild("leaderstats")
        
        if looterStats then
            looterStats.Dinero.Value = looterData.Cash
        end
        if targetStats then
            targetStats.Dinero.Value = targetData.Cash
        end
    end
    
    -- Lutear items del bolso (transferir al bolso del saqueador)
    local lootedItems = {}
    local bagContents = targetData.BagContents or {}
    
    for i = #bagContents, 1, -1 do
        local item = bagContents[i]
        local success, msg = DataManager.AddToBag(looter, item)
        if success then
            table.insert(lootedItems, item.Name or "Item desconocido")
            table.remove(targetData.BagContents, i)
        else
            break -- Bolso del saqueador lleno
        end
    end
    
    -- Establecer cooldown
    lootCooldowns[looter.UserId] = os.time()
    
    -- Notificar al saqueador
    local lootSummary = "Luteaste a " .. targetPlayer.Name .. ":\n"
    lootSummary = lootSummary .. "- Dinero: $" .. lootAmount .. "\n"
    if #lootedItems > 0 then
        lootSummary = lootSummary .. "- Items: " .. table.concat(lootedItems, ", ")
    end
    
    -- Notificar a la víctima
    RemoteEvents.GetEvent("ShowNotification"):FireClient(targetPlayer, {
        Title = "¡Te han luteado!",
        Text = looter.Name .. " te ha luteado",
        Duration = 5,
        Type = "Error",
    })
    
    return true, lootSummary
end

-----------------------------------------------------
-- EVENTO DE LUTEO
-----------------------------------------------------
local lootEvent = RemoteEvents.GetEvent("LootPlayer")
if lootEvent then
    lootEvent.OnServerEvent:Connect(function(looter, targetUserId)
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if not targetPlayer then
            RemoteEvents.GetEvent("LootResult"):FireClient(looter, {
                Success = false,
                Message = "Jugador no encontrado",
            })
            return
        end
        
        local success, message = lootPlayer(looter, targetPlayer)
        
        RemoteEvents.GetEvent("LootResult"):FireClient(looter, {
            Success = success,
            Message = message,
        })
    end)
end

-----------------------------------------------------
-- SISTEMA DE BOLSO - ACTUALIZAR
-----------------------------------------------------
local updateBagEvent = RemoteEvents.GetEvent("UpdateBag")
if updateBagEvent then
    updateBagEvent.OnServerEvent:Connect(function(player, action, itemData)
        local data = DataManager.GetPlayerData(player)
        if not data then return end
        
        if action == "Sell" then
            -- Vender todo el contenido del bolso
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
                
                RemoteEvents.GetEvent("BagContentsChanged"):FireClient(player, {
                    Contents = {},
                    TotalValue = 0,
                    Message = "¡Vendiste todo por $" .. totalValue .. "!",
                })
            end
        elseif action == "Drop" then
            -- Tirar un item del bolso
            if itemData and itemData.Index then
                local index = itemData.Index
                if index >= 1 and index <= #data.BagContents then
                    table.remove(data.BagContents, index)
                    RemoteEvents.GetEvent("BagContentsChanged"):FireClient(player, {
                        Contents = data.BagContents,
                        Message = "Item tirado",
                    })
                end
            end
        end
    end)
end

-----------------------------------------------------
-- GET BAG CONTENTS (RemoteFunction)
-----------------------------------------------------
local getBagFunc = RemoteEvents.GetFunction("GetBagContents")
if getBagFunc then
    getBagFunc.OnServerInvoke = function(player)
        local data = DataManager.GetPlayerData(player)
        if data then
            return {
                Contents = data.BagContents,
                Capacity = data.BagCapacity,
                Expanded = data.ExpandedBag,
            }
        end
        return { Contents = {}, Capacity = 5, Expanded = false }
    end
end

-----------------------------------------------------
-- LIMPIAR COOLDOWNS
-----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    lootCooldowns[player.UserId] = nil
end)

print("[LootingSystem] Sistema de luteo inicializado")
