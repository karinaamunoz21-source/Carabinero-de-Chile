--[[
    ChatCommands - Sistema de comandos por chat
    Maneja: /sg (spawn gun), comandos de moderador, barra commands
    
    COMANDOS DISPONIBLES:
    /sg golden - Generar Golden Gun (requiere pase)
    /sg tambor - Generar Revólver Tambor (requiere pase)
    /sg arp christmas - Generar ARP Christmas (requiere pase)
    
    MODERADOR:
    /fly [id] - Activar vuelo
    /unfly [id] - Desactivar vuelo
    /nuke [id] - Nuke en jugador
    /h [mensaje] - Anunciar a todos
    /timer [segundos] - Temporizador global
    /ban [id] [razón] - Banear jugador
    /unban [id] - Desbanear jugador
    /kick [id] [razón] - Kickear jugador
    
    ADMIN ABUSE (owner/co-owner):
    /god [id], /ungod [id], /kill [id], /tp [id], /bring [id]
    /speed [id] [valor], /jump [id] [valor], /respawn [id]
    /freeze [id], /unfreeze [id]
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

-----------------------------------------------------
-- PARSEAR COMANDO DEL CHAT
-----------------------------------------------------
local function parseCommand(message)
    local parts = {}
    for part in message:gmatch("%S+") do
        table.insert(parts, part)
    end
    return parts
end

-----------------------------------------------------
-- VERIFICAR PERMISOS
-----------------------------------------------------
local function getGroupRank(player)
    local success, rank = pcall(function()
        return player:GetRankInGroup(GameConfig.GROUP_ID)
    end)
    return success and rank or 0
end

local function isModerator(player)
    return getGroupRank(player) >= GameConfig.Ranks.MODERATOR
end

local function isOwnerOrCoOwner(player)
    return getGroupRank(player) >= GameConfig.Ranks.CO_OWNER
end

local function hasGamePass(player, passName)
    local data = DataManager.GetPlayerData(player)
    if data and data.OwnedGamePasses and data.OwnedGamePasses[passName] then
        return true
    end
    
    local passId = GameConfig.GamePasses[passName]
    if passId and passId > 0 then
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
        end)
        if success and owns then
            if data then
                data.OwnedGamePasses[passName] = true
            end
            return true
        end
    end
    return false
end

-----------------------------------------------------
-- MANEJAR COMANDOS POR CHAT
-----------------------------------------------------
local function handleChatCommand(player, message)
    local parts = parseCommand(message)
    if #parts == 0 then return end
    
    local cmd = string.lower(parts[1])
    
    -----------------------------------------------
    -- COMANDO /sg (Spawn Gun) - Requiere pase
    -----------------------------------------------
    if cmd == "/sg" then
        if not hasGamePass(player, "GENERAR_ARMAS") then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Pase Requerido",
                Text = "Necesitas el Pase de Generar Armas para usar /sg",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        -- Obtener nombre del arma (puede ser de 2 palabras como "arp christmas")
        local weaponKey = ""
        for i = 2, #parts do
            if i > 2 then weaponKey = weaponKey .. " " end
            weaponKey = weaponKey .. string.lower(parts[i])
        end
        
        if weaponKey == "" then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Uso",
                Text = "Uso: /sg golden | /sg tambor | /sg arp christmas",
                Duration = 5,
                Type = "Info",
            })
            return
        end
        
        -- Disparar evento de spawn de arma
        local weaponSpawnEvent = RemoteEvents.GetEvent("WeaponSpawnCommand")
        if weaponSpawnEvent then
            weaponSpawnEvent:FireServer(weaponKey) -- Este lo maneja WeaponSystem
            -- Pero como estamos en servidor, lo manejamos directamente aquí
        end
        
        -- Buscar arma en configuración
        local weaponConfig = GameConfig.Weapons.SPAWN_COMMANDS[weaponKey]
        if weaponConfig then
            -- Crear y dar el arma directamente
            local tool = Instance.new("Tool")
            tool.Name = weaponConfig.Name
            tool.CanBeDropped = false
            tool.RequiresHandle = true
            
            local handle = Instance.new("Part")
            handle.Name = "Handle"
            handle.Size = Vector3.new(0.5, 0.5, 2)
            handle.BrickColor = BrickColor.new("Bright yellow")
            handle.Material = Enum.Material.Metal
            handle.Parent = tool
            
            local damageVal = Instance.new("NumberValue")
            damageVal.Name = "Damage"
            damageVal.Value = weaponConfig.Damage or 0
            damageVal.Parent = tool
            
            local typeVal = Instance.new("StringValue")
            typeVal.Name = "WeaponType"
            typeVal.Value = weaponConfig.Type or "Unknown"
            typeVal.Parent = tool
            
            if weaponConfig.FireRate then
                local fr = Instance.new("NumberValue")
                fr.Name = "FireRate"
                fr.Value = weaponConfig.FireRate
                fr.Parent = tool
            end
            
            if weaponConfig.MagSize then
                local ms = Instance.new("IntValue")
                ms.Name = "MagSize"
                ms.Value = weaponConfig.MagSize
                ms.Parent = tool
                
                local ca = Instance.new("IntValue")
                ca.Name = "CurrentAmmo"
                ca.Value = weaponConfig.MagSize
                ca.Parent = tool
            end
            
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                tool.Parent = backpack
            end
            
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Arma Generada",
                Text = "Se generó: " .. weaponConfig.Name,
                Duration = 5,
                Type = "Success",
            })
        else
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Error",
                Text = "Arma no encontrada. Opciones: golden, tambor, arp christmas",
                Duration = 5,
                Type = "Error",
            })
        end
        return
    end
    
    -----------------------------------------------
    -- COMANDOS MODERADOR
    -----------------------------------------------
    if cmd == "/fly" or cmd == "/unfly" or cmd == "/nuke" or 
       cmd == "/ban" or cmd == "/unban" or cmd == "/kick" then
        
        if not isModerator(player) then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Sin Permisos",
                Text = "Solo moderadores pueden usar este comando",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        local command = cmd:sub(2) -- Remover el /
        local targetId = tonumber(parts[2])
        local extraArg = parts[3] and table.concat(parts, " ", 3) or nil
        
        local executeEvent = RemoteEvents.GetEvent("ExecuteCommand")
        -- Manejar directamente en servidor
        if executeEvent then
            -- Disparar evento interno
            local commandEvent = RemoteEvents.GetEvent("ExecuteCommand")
            if commandEvent then
                -- Simulamos la llamada al servidor
                commandEvent:FireServer(command, targetId, extraArg)
            end
        end
        return
    end
    
    -----------------------------------------------
    -- COMANDO /h (Anunciar)
    -----------------------------------------------
    if cmd == "/h" then
        if not isModerator(player) then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Sin Permisos",
                Text = "Solo moderadores pueden hacer anuncios",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        local announcement = table.concat(parts, " ", 2)
        if announcement and announcement ~= "" then
            for _, p in ipairs(Players:GetPlayers()) do
                RemoteEvents.GetEvent("ShowNotification"):FireClient(p, {
                    Title = "ANUNCIO",
                    Text = "[" .. player.Name .. "] " .. announcement,
                    Duration = 15,
                    Type = "Info",
                })
            end
        end
        return
    end
    
    -----------------------------------------------
    -- COMANDO /timer
    -----------------------------------------------
    if cmd == "/timer" then
        if not isModerator(player) then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Sin Permisos",
                Text = "Solo moderadores pueden usar el temporizador",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        local seconds = tonumber(parts[2])
        if not seconds or seconds <= 0 then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Uso",
                Text = "Uso: /timer [segundos]",
                Duration = 5,
                Type = "Info",
            })
            return
        end
        
        -- Iniciar temporizador
        spawn(function()
            local remaining = seconds
            while remaining > 0 do
                for _, p in ipairs(Players:GetPlayers()) do
                    RemoteEvents.GetEvent("ShowNotification"):FireClient(p, {
                        Title = "TEMPORIZADOR",
                        Text = "Tiempo: " .. remaining .. "s",
                        Duration = 1.5,
                        Type = "Warning",
                    })
                end
                task.wait(1)
                remaining = remaining - 1
            end
            for _, p in ipairs(Players:GetPlayers()) do
                RemoteEvents.GetEvent("ShowNotification"):FireClient(p, {
                    Title = "TEMPORIZADOR",
                    Text = "¡Tiempo terminado!",
                    Duration = 5,
                    Type = "Success",
                })
            end
        end)
        return
    end
    
    -----------------------------------------------
    -- COMANDOS ADMIN ABUSE (owner/co-owner)
    -----------------------------------------------
    local adminCmds = {"/god", "/ungod", "/kill", "/tp", "/bring", "/speed", "/jump", "/respawn", "/freeze", "/unfreeze"}
    local isAdminCmd = false
    for _, ac in ipairs(adminCmds) do
        if cmd == ac then
            isAdminCmd = true
            break
        end
    end
    
    if isAdminCmd then
        if not isOwnerOrCoOwner(player) then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Sin Permisos",
                Text = "Solo Owner y Co-Owner pueden usar comandos admin abuse",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        local command = cmd:sub(2)
        local targetId = tonumber(parts[2])
        local extraArg = parts[3]
        
        local adminEvent = RemoteEvents.GetEvent("AdminCommand")
        if adminEvent then
            adminEvent:FireServer(command, targetId, extraArg)
        end
        return
    end
    
    -----------------------------------------------
    -- COMANDOS DE BARRA (requiere pase BARRA)
    -----------------------------------------------
    if cmd:sub(1, 1) == "/" and hasGamePass(player, "BARRA") then
        -- Comandos personalizados de barra
        RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
            Title = "Comando de Barra",
            Text = "Ejecutando: " .. message,
            Duration = 3,
            Type = "Info",
        })
    end
end

-----------------------------------------------------
-- CONECTAR AL CHAT DE CADA JUGADOR
-----------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:sub(1, 1) == "/" then
            handleChatCommand(player, message)
        end
    end)
end)

print("[ChatCommands] Sistema de comandos por chat inicializado")
print("[ChatCommands] Comandos disponibles: /sg, /fly, /unfly, /nuke, /h, /timer, /ban, /unban, /kick")
print("[ChatCommands] Admin abuse: /god, /ungod, /kill, /tp, /bring, /speed, /jump, /respawn, /freeze, /unfreeze")
