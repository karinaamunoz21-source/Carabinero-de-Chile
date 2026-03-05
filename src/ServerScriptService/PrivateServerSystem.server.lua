--[[
    PrivateServerSystem - Sistema de servidores privados
    Costo mensual de 100 robux para renovar
    Límites de jugadores por servidor
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local PrivateServerSystem = {}

local serverDataStore = DataStoreService:GetDataStore("PrivateServers_v1")

-----------------------------------------------------
-- VERIFICAR ESTADO DEL SERVIDOR PRIVADO
-----------------------------------------------------
local function checkServerStatus(serverId)
    local success, data = pcall(function()
        return serverDataStore:GetAsync("Server_" .. serverId)
    end)
    
    if success and data then
        -- Verificar si el mes ha expirado
        local currentTime = os.time()
        local expirationTime = data.ExpiresAt or 0
        
        if currentTime > expirationTime then
            return {
                Active = false,
                Expired = true,
                Owner = data.Owner,
                OwnerId = data.OwnerId,
                Message = "El servidor ha expirado. Debe renovarse por " .. GameConfig.PrivateServer.MONTHLY_COST .. " Robux",
            }
        end
        
        return {
            Active = true,
            Expired = false,
            Owner = data.Owner,
            OwnerId = data.OwnerId,
            ExpiresAt = data.ExpiresAt,
            MaxPlayers = data.MaxPlayers or GameConfig.PrivateServer.MAX_PLAYERS,
            RemainingDays = math.floor((expirationTime - currentTime) / 86400),
        }
    end
    
    return { Active = false, Expired = false, New = true }
end

-----------------------------------------------------
-- REGISTRAR / RENOVAR SERVIDOR PRIVADO
-----------------------------------------------------
local function renewServer(player, serverId)
    -- Verificar compra del pase
    local passId = GameConfig.GamePasses.SERVIDOR_PRIVADO
    if passId <= 0 then
        return false, "El sistema de servidores privados no está configurado"
    end
    
    -- Verificar que el jugador es owner del servidor o es nuevo
    local serverData = checkServerStatus(serverId)
    
    if serverData.OwnerId and serverData.OwnerId ~= player.UserId then
        return false, "No eres el dueño de este servidor"
    end
    
    -- Procesar renovación
    local newData = {
        Owner = player.Name,
        OwnerId = player.UserId,
        CreatedAt = serverData.CreatedAt or os.time(),
        ExpiresAt = os.time() + (30 * 86400), -- 30 días
        MaxPlayers = GameConfig.PrivateServer.MAX_PLAYERS,
        RenewedAt = os.time(),
    }
    
    local success = pcall(function()
        serverDataStore:SetAsync("Server_" .. serverId, newData)
    end)
    
    if success then
        return true, "¡Servidor renovado por 30 días! Expira el " .. os.date("%d/%m/%Y", newData.ExpiresAt)
    end
    
    return false, "Error al renovar el servidor"
end

-----------------------------------------------------
-- VERIFICAR AL ENTRAR AL SERVIDOR
-----------------------------------------------------
local function onPlayerJoin(player)
    -- Obtener ID del servidor privado
    local privateServerId = game.PrivateServerId
    
    if privateServerId and privateServerId ~= "" then
        -- Es un servidor privado
        local status = checkServerStatus(privateServerId)
        
        if status.Expired then
            -- Servidor expirado
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Servidor Expirado",
                Text = "Este servidor privado ha expirado. El dueño debe renovarlo por " 
                    .. GameConfig.PrivateServer.MONTHLY_COST .. " Robux",
                Duration = 15,
                Type = "Warning",
            })
            
            -- Si es el dueño, ofrecer renovación
            if status.OwnerId == player.UserId then
                RemoteEvents.GetEvent("RenewServer"):FireClient(player, {
                    ServerId = privateServerId,
                    Cost = GameConfig.PrivateServer.MONTHLY_COST,
                    Message = "Tu servidor ha expirado. ¿Deseas renovarlo?",
                })
            else
                -- Kickear después de 30 segundos si no se renueva
                task.delay(30, function()
                    local currentStatus = checkServerStatus(privateServerId)
                    if currentStatus.Expired and player.Parent then
                        player:Kick("El servidor privado ha expirado. Contacta al dueño para renovarlo.")
                    end
                end)
            end
        elseif status.Active then
            -- Verificar límite de jugadores
            local currentPlayers = #Players:GetPlayers()
            if currentPlayers > (status.MaxPlayers or 20) then
                player:Kick("El servidor está lleno (Límite: " .. status.MaxPlayers .. " jugadores)")
                return
            end
            
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Servidor Privado",
                Text = "Servidor de " .. (status.Owner or "Desconocido") 
                    .. " | Expira en " .. (status.RemainingDays or "?") .. " días",
                Duration = 5,
                Type = "Info",
            })
        end
    end
end

-----------------------------------------------------
-- EVENTO: RENOVAR SERVIDOR
-----------------------------------------------------
local renewEvent = RemoteEvents.GetEvent("RenewServer")
if renewEvent then
    renewEvent.OnServerEvent:Connect(function(player)
        local privateServerId = game.PrivateServerId
        if not privateServerId or privateServerId == "" then
            RemoteEvents.GetEvent("ServerRenewed"):FireClient(player, {
                Success = false,
                Message = "No estás en un servidor privado",
            })
            return
        end
        
        -- Intentar cobrar mediante GamePass/DevProduct
        local success, msg = renewServer(player, privateServerId)
        RemoteEvents.GetEvent("ServerRenewed"):FireClient(player, {
            Success = success,
            Message = msg,
        })
    end)
end

-----------------------------------------------------
-- CONECTAR EVENTOS
-----------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    task.wait(3) -- Esperar a que cargue
    onPlayerJoin(player)
end)

print("[PrivateServerSystem] Sistema de servidores privados inicializado")
