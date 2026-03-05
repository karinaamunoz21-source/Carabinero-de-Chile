--[[
    AdminCommands - Sistema completo de comandos de moderador y admin
    
    COMANDOS MODERADOR:
    fly, unfly, nuke, /h (anunciar), timer, ban, unban, kick
    
    COMANDOS ADMIN ABUSE (solo owner/co-owner):
    god, ungod, kill, tp, bring, speed, jump, respawn, freeze, unfreeze
    
    Todos los comandos se ejecutan por ID del jugador
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local AdminCommands = {}

-- Cache de permisos
local permissionsCache = {}

-----------------------------------------------------
-- VERIFICAR PERMISOS
-----------------------------------------------------
local function getPlayerRank(player)
    if permissionsCache[player.UserId] then
        return permissionsCache[player.UserId]
    end
    
    local success, rank = pcall(function()
        return player:GetRankInGroup(GameConfig.GROUP_ID)
    end)
    
    if success then
        permissionsCache[player.UserId] = rank
        return rank
    end
    
    return 0
end

local function isModerator(player)
    local rank = getPlayerRank(player)
    return rank >= GameConfig.Ranks.MODERATOR
end

local function isOwnerOrCoOwner(player)
    local rank = getPlayerRank(player)
    return rank >= GameConfig.Ranks.CO_OWNER
end

local function getPlayerById(userId)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.UserId == userId then
            return p
        end
    end
    return nil
end

-----------------------------------------------------
-- COMANDO: FLY
-----------------------------------------------------
local function cmdFly(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado (ID: " .. targetId .. ")" end
    
    local character = target.Character
    if not character then return false, "El jugador no tiene personaje" end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart then
        -- Crear BodyVelocity para volar
        local existingBV = rootPart:FindFirstChild("FlyVelocity")
        if existingBV then
            return false, target.Name .. " ya está volando"
        end
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = rootPart
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.Parent = rootPart
        
        return true, target.Name .. " ahora puede volar"
    end
    
    return false, "Error al activar vuelo"
end

-----------------------------------------------------
-- COMANDO: UNFLY
-----------------------------------------------------
local function cmdUnfly(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if not character then return false, "El jugador no tiene personaje" end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local bv = rootPart:FindFirstChild("FlyVelocity")
        local bg = rootPart:FindFirstChild("FlyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        return true, target.Name .. " ya no puede volar"
    end
    
    return false, "Error al desactivar vuelo"
end

-----------------------------------------------------
-- COMANDO: NUKE
-----------------------------------------------------
local function cmdNuke(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if not character then return false, "El jugador no tiene personaje" end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        -- Crear explosión nuclear
        local explosion = Instance.new("Explosion")
        explosion.Position = rootPart.Position
        explosion.BlastRadius = 100
        explosion.BlastPressure = 1000000
        explosion.DestroyJointRadiusPercent = 1
        explosion.Parent = workspace
        
        -- Efectos visuales
        local fireball = Instance.new("Part")
        fireball.Shape = Enum.PartType.Ball
        fireball.Size = Vector3.new(50, 50, 50)
        fireball.Position = rootPart.Position
        fireball.Anchored = true
        fireball.BrickColor = BrickColor.new("Bright orange")
        fireball.Material = Enum.Material.Neon
        fireball.Transparency = 0.3
        fireball.Parent = workspace
        
        -- Limpiar efecto después de 5 segundos
        task.delay(5, function()
            if fireball and fireball.Parent then
                fireball:Destroy()
            end
        end)
        
        return true, "¡NUKE en " .. target.Name .. "!"
    end
    
    return false, "Error al ejecutar nuke"
end

-----------------------------------------------------
-- COMANDO: /H (ANUNCIAR)
-----------------------------------------------------
local function cmdAnnounce(admin, message)
    -- Enviar anuncio a todos los jugadores
    for _, player in ipairs(Players:GetPlayers()) do
        RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
            Title = "ANUNCIO",
            Text = "[" .. admin.Name .. "] " .. message,
            Duration = 15,
            Type = "Info",
        })
    end
    
    return true, "Anuncio enviado: " .. message
end

-----------------------------------------------------
-- COMANDO: TIMER
-----------------------------------------------------
local function cmdTimer(admin, seconds)
    local duration = tonumber(seconds)
    if not duration or duration <= 0 then
        return false, "Duración inválida"
    end
    
    -- Iniciar temporizador global
    spawn(function()
        local remaining = duration
        while remaining > 0 do
            for _, player in ipairs(Players:GetPlayers()) do
                RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                    Title = "TEMPORIZADOR",
                    Text = "Tiempo restante: " .. remaining .. " segundos",
                    Duration = 1.5,
                    Type = "Warning",
                })
            end
            task.wait(1)
            remaining = remaining - 1
        end
        
        -- Temporizador terminado
        for _, player in ipairs(Players:GetPlayers()) do
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "TEMPORIZADOR",
                Text = "¡Tiempo terminado!",
                Duration = 5,
                Type = "Success",
            })
        end
    end)
    
    return true, "Temporizador de " .. duration .. " segundos iniciado"
end

-----------------------------------------------------
-- COMANDO: BAN
-----------------------------------------------------
local function cmdBan(admin, targetId, reason)
    local userId = tonumber(targetId)
    if not userId then return false, "ID inválido" end
    
    local success = DataManager.BanPlayer(userId, reason or "Baneado por " .. admin.Name)
    
    if success then
        -- Kickear si está conectado
        local target = getPlayerById(userId)
        if target then
            target:Kick("Has sido baneado: " .. (reason or "Sin razón especificada"))
        end
        return true, "Jugador (ID: " .. userId .. ") baneado"
    end
    
    return false, "Error al banear jugador"
end

-----------------------------------------------------
-- COMANDO: UNBAN
-----------------------------------------------------
local function cmdUnban(admin, targetId)
    local userId = tonumber(targetId)
    if not userId then return false, "ID inválido" end
    
    local success = DataManager.UnbanPlayer(userId)
    return success, success and "Jugador (ID: " .. userId .. ") desbaneado" or "Error al desbanear"
end

-----------------------------------------------------
-- COMANDO: KICK
-----------------------------------------------------
local function cmdKick(admin, targetId, reason)
    local target = getPlayerById(tonumber(targetId))
    if not target then return false, "Jugador no encontrado" end
    
    target:Kick(reason or "Kickeado por " .. admin.Name)
    return true, target.Name .. " ha sido kickeado"
end

-----------------------------------------------------
-- COMANDOS ADMIN ABUSE (solo owner/co-owner)
-----------------------------------------------------

local function cmdGod(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            return true, target.Name .. " ahora es inmortal"
        end
    end
    return false, "Error"
end

local function cmdUngod(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            return true, target.Name .. " ya no es inmortal"
        end
    end
    return false, "Error"
end

local function cmdKill(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
            return true, target.Name .. " ha sido eliminado"
        end
    end
    return false, "Error"
end

local function cmdTp(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local adminChar = admin.Character
    local targetChar = target.Character
    
    if adminChar and targetChar then
        local adminRoot = adminChar:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if adminRoot and targetRoot then
            adminRoot.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0)
            return true, "Teletransportado a " .. target.Name
        end
    end
    return false, "Error"
end

local function cmdBring(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local adminChar = admin.Character
    local targetChar = target.Character
    
    if adminChar and targetChar then
        local adminRoot = adminChar:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if adminRoot and targetRoot then
            targetRoot.CFrame = adminRoot.CFrame + Vector3.new(3, 0, 0)
            return true, target.Name .. " ha sido traído"
        end
    end
    return false, "Error"
end

local function cmdSpeed(admin, targetId, speedValue)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = tonumber(speedValue) or 16
            return true, target.Name .. " velocidad: " .. (speedValue or 16)
        end
    end
    return false, "Error"
end

local function cmdJump(admin, targetId, jumpValue)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = tonumber(jumpValue) or 50
            return true, target.Name .. " salto: " .. (jumpValue or 50)
        end
    end
    return false, "Error"
end

local function cmdRespawn(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    target:LoadCharacter()
    return true, target.Name .. " respawneado"
end

local function cmdFreeze(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Anchored = true
            return true, target.Name .. " congelado"
        end
    end
    return false, "Error"
end

local function cmdUnfreeze(admin, targetId)
    local target = getPlayerById(targetId)
    if not target then return false, "Jugador no encontrado" end
    
    local character = target.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Anchored = false
            return true, target.Name .. " descongelado"
        end
    end
    return false, "Error"
end

-----------------------------------------------------
-- MAPEO DE COMANDOS
-----------------------------------------------------
local modCommands = {
    fly = cmdFly,
    unfly = cmdUnfly,
    nuke = cmdNuke,
    ban = cmdBan,
    unban = cmdUnban,
    kick = cmdKick,
}

local adminAbuseCommands = {
    god = cmdGod,
    ungod = cmdUngod,
    kill = cmdKill,
    tp = cmdTp,
    bring = cmdBring,
    speed = cmdSpeed,
    jump = cmdJump,
    respawn = cmdRespawn,
    freeze = cmdFreeze,
    unfreeze = cmdUnfreeze,
}

-----------------------------------------------------
-- EVENTO: EJECUTAR COMANDO MODERADOR
-----------------------------------------------------
local executeCommandEvent = RemoteEvents.GetEvent("ExecuteCommand")
if executeCommandEvent then
    executeCommandEvent.OnServerEvent:Connect(function(player, command, ...)
        local args = {...}
        
        if not isModerator(player) then
            RemoteEvents.GetEvent("CommandResult"):FireClient(player, {
                Success = false,
                Message = "No tienes permisos de moderador",
            })
            return
        end
        
        local cmd = string.lower(command)
        
        -- Comandos especiales que no usan ID
        if cmd == "/h" or cmd == "announce" then
            local message = table.concat(args, " ")
            local success, result = cmdAnnounce(player, message)
            RemoteEvents.GetEvent("CommandResult"):FireClient(player, {
                Success = success,
                Message = result,
            })
            return
        end
        
        if cmd == "timer" then
            local success, result = cmdTimer(player, args[1])
            RemoteEvents.GetEvent("CommandResult"):FireClient(player, {
                Success = success,
                Message = result,
            })
            return
        end
        
        -- Comandos con ID de jugador
        local targetId = tonumber(args[1])
        if not targetId then
            RemoteEvents.GetEvent("CommandResult"):FireClient(player, {
                Success = false,
                Message = "Debes especificar el ID del jugador",
            })
            return
        end
        
        local handler = modCommands[cmd]
        if handler then
            local success, result = handler(player, targetId, args[2])
            RemoteEvents.GetEvent("CommandResult"):FireClient(player, {
                Success = success,
                Message = result,
            })
        else
            RemoteEvents.GetEvent("CommandResult"):FireClient(player, {
                Success = false,
                Message = "Comando no encontrado: " .. cmd,
            })
        end
    end)
end

-----------------------------------------------------
-- EVENTO: EJECUTAR COMANDO ADMIN ABUSE
-----------------------------------------------------
local adminCommandEvent = RemoteEvents.GetEvent("AdminCommand")
if adminCommandEvent then
    adminCommandEvent.OnServerEvent:Connect(function(player, command, ...)
        local args = {...}
        
        if not isOwnerOrCoOwner(player) then
            RemoteEvents.GetEvent("AdminCommandResult"):FireClient(player, {
                Success = false,
                Message = "Solo Owner y Co-Owner pueden usar comandos de admin abuse",
            })
            return
        end
        
        local cmd = string.lower(command)
        local targetId = tonumber(args[1])
        
        if not targetId then
            RemoteEvents.GetEvent("AdminCommandResult"):FireClient(player, {
                Success = false,
                Message = "Debes especificar el ID del jugador",
            })
            return
        end
        
        local handler = adminAbuseCommands[cmd]
        if handler then
            local success, result = handler(player, targetId, args[2])
            RemoteEvents.GetEvent("AdminCommandResult"):FireClient(player, {
                Success = success,
                Message = result,
            })
        else
            RemoteEvents.GetEvent("AdminCommandResult"):FireClient(player, {
                Success = false,
                Message = "Comando admin no encontrado: " .. cmd,
            })
        end
    end)
end

-----------------------------------------------------
-- LIMPIAR CACHE AL SALIR
-----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    permissionsCache[player.UserId] = nil
end)

print("[AdminCommands] Sistema de comandos inicializado")
print("[AdminCommands] Comandos Moderador: fly, unfly, nuke, /h, timer, ban, unban, kick")
print("[AdminCommands] Comandos Admin Abuse: god, ungod, kill, tp, bring, speed, jump, respawn, freeze, unfreeze")
