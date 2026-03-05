--[[
    PrisonSystem - Sistema de prisión completo
    Arrestar criminales, sentencia con temporizador, escape
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local PrisonSystem = {}

-- Jugadores actualmente en prisión
local prisonPlayers = {}

-- Posición de la prisión (cambiar según tu mapa)
local PRISON_POSITION = Vector3.new(200, 5, 200)
local RELEASE_POSITION = Vector3.new(0, 5, 0)

-----------------------------------------------------
-- ENVIAR A PRISIÓN
-----------------------------------------------------
local function sendToPrison(officer, criminalPlayer)
    if not criminalPlayer then return false, "Jugador no encontrado" end
    
    -- Verificar que el oficial es policía o SWAT
    if not officer.Team or (officer.Team.Name ~= "Policía" and officer.Team.Name ~= "SWAT") then
        return false, "Solo policías pueden arrestar"
    end
    
    -- Verificar que el objetivo es criminal
    if criminalPlayer.Team and criminalPlayer.Team.Name ~= "Criminal" then
        return false, "Solo puedes arrestar criminales"
    end
    
    -- Verificar distancia
    local officerChar = officer.Character
    local criminalChar = criminalPlayer.Character
    if not officerChar or not criminalChar then
        return false, "Error de personaje"
    end
    
    local officerRoot = officerChar:FindFirstChild("HumanoidRootPart")
    local criminalRoot = criminalChar:FindFirstChild("HumanoidRootPart")
    if not officerRoot or not criminalRoot then
        return false, "Error de posición"
    end
    
    local distance = (officerRoot.Position - criminalRoot.Position).Magnitude
    if distance > 15 then
        return false, "Estás demasiado lejos para arrestar"
    end
    
    -- Verificar que el criminal está aturdido o con baja salud
    local criminalHumanoid = criminalChar:FindFirstChild("Humanoid")
    if criminalHumanoid and criminalHumanoid.Health > criminalHumanoid.MaxHealth * 0.5 then
        -- Permitir arresto si está aturdido (walkspeed = 0) o con poca vida
        if criminalHumanoid.WalkSpeed > 0 then
            return false, "El criminal debe estar aturdido o herido para ser arrestado"
        end
    end
    
    -- Calcular tiempo de sentencia
    local criminalData = DataManager.GetPlayerData(criminalPlayer)
    local baseSentence = GameConfig.Prison.SENTENCE_TIME
    local extraTime = (criminalData and criminalData.CriminalRecord or 0) * 10
    local totalSentence = baseSentence + extraTime
    
    -- Teletransportar a prisión
    criminalRoot.CFrame = CFrame.new(PRISON_POSITION)
    
    -- Registrar en prisión
    prisonPlayers[criminalPlayer.UserId] = {
        SentenceEnd = os.time() + totalSentence,
        TotalSentence = totalSentence,
        ArrestedBy = officer.Name,
    }
    
    -- Desactivar movimiento
    if criminalHumanoid then
        criminalHumanoid.WalkSpeed = 8 -- Velocidad reducida en prisión
        criminalHumanoid.JumpPower = 0 -- No puede saltar en prisión
    end
    
    -- Actualizar estadísticas del oficial
    local officerData = DataManager.GetPlayerData(officer)
    if officerData then
        officerData.ArrestsCount = officerData.ArrestsCount + 1
        local officerStats = officer:FindFirstChild("leaderstats")
        if officerStats then
            officerStats.Arrestos.Value = officerData.ArrestsCount
        end
    end
    
    -- Recompensa al oficial
    DataManager.AddCash(officer, 5000)
    local officerStats = officer:FindFirstChild("leaderstats")
    if officerStats and officerData then
        officerStats.Dinero.Value = officerData.Cash
    end
    
    -- Notificaciones
    RemoteEvents.GetEvent("ShowNotification"):FireClient(officer, {
        Title = "Arresto Exitoso",
        Text = "Arrestaste a " .. criminalPlayer.Name .. " (+$5,000)\nSentencia: " .. totalSentence .. "s",
        Duration = 5,
        Type = "Success",
    })
    
    RemoteEvents.GetEvent("ShowNotification"):FireClient(criminalPlayer, {
        Title = "¡Arrestado!",
        Text = "Fuiste arrestado por " .. officer.Name .. "\nSentencia: " .. totalSentence .. " segundos",
        Duration = 10,
        Type = "Error",
    })
    
    -- Iniciar temporizador de liberación
    spawn(function()
        local remainingTime = totalSentence
        while remainingTime > 0 and prisonPlayers[criminalPlayer.UserId] do
            task.wait(1)
            remainingTime = remainingTime - 1
            
            -- Enviar actualización de tiempo
            if criminalPlayer.Parent then -- Verificar que sigue conectado
                RemoteEvents.GetEvent("ShowNotification"):FireClient(criminalPlayer, {
                    Title = "Tiempo en Prisión",
                    Text = "Tiempo restante: " .. remainingTime .. " segundos",
                    Duration = 1.5,
                    Type = "Warning",
                })
            else
                break
            end
        end
        
        -- Liberar al criminal
        releaseFromPrison(criminalPlayer)
    end)
    
    return true, "Arrestado exitosamente"
end

-----------------------------------------------------
-- LIBERAR DE PRISIÓN
-----------------------------------------------------
function releaseFromPrison(player)
    if not prisonPlayers[player.UserId] then return end
    
    prisonPlayers[player.UserId] = nil
    
    if player.Parent then -- Verificar que sigue conectado
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
            
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = CFrame.new(RELEASE_POSITION)
            end
        end
        
        -- Cambiar a Civil
        local civilTeam = Teams:FindFirstChild("Civil")
        if civilTeam then
            player.Team = civilTeam
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                leaderstats.Equipo.Value = "Civil"
            end
        end
        
        RemoteEvents.GetEvent("PrisonRelease"):FireClient(player, {
            Message = "Has sido liberado de prisión",
        })
        
        RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
            Title = "Liberado",
            Text = "Has cumplido tu sentencia. Ahora eres Civil.",
            Duration = 5,
            Type = "Success",
        })
    end
end

-----------------------------------------------------
-- INTENTO DE ESCAPE
-----------------------------------------------------
local function attemptEscape(player)
    local prisonData = prisonPlayers[player.UserId]
    if not prisonData then
        return false, "No estás en prisión"
    end
    
    -- Probabilidad de escape basada en dificultad
    local escapeDifficulty = GameConfig.Prison.ESCAPE_DIFFICULTY
    local chance = math.random(1, 10)
    
    if chance > escapeDifficulty * 2 then
        -- Escape exitoso
        prisonPlayers[player.UserId] = nil
        
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
            
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = CFrame.new(RELEASE_POSITION + Vector3.new(50, 0, 50))
            end
        end
        
        -- Actualizar estadísticas
        local data = DataManager.GetPlayerData(player)
        if data then
            data.Stats.Escapes = data.Stats.Escapes + 1
            data.CriminalRecord = data.CriminalRecord + 2 -- Más antecedentes por escapar
        end
        
        -- Notificar a policías
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Team and (p.Team.Name == "Policía" or p.Team.Name == "SWAT") then
                RemoteEvents.GetEvent("PoliceChatMessage"):FireClient(p, 
                    "[ALERTA] ¡" .. player.Name .. " ha escapado de prisión!")
            end
        end
        
        return true, "¡Escapaste de prisión!"
    else
        -- Escape fallido - agregar tiempo
        prisonData.SentenceEnd = prisonData.SentenceEnd + 60
        prisonData.TotalSentence = prisonData.TotalSentence + 60
        
        return false, "¡Escape fallido! +60 segundos de sentencia"
    end
end

-----------------------------------------------------
-- EVENTOS
-----------------------------------------------------
local sendToPrisonEvent = RemoteEvents.GetEvent("SendToPrison")
if sendToPrisonEvent then
    sendToPrisonEvent.OnServerEvent:Connect(function(officer, targetUserId)
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if targetPlayer then
            local success, message = sendToPrison(officer, targetPlayer)
            RemoteEvents.GetEvent("ShowNotification"):FireClient(officer, {
                Title = success and "Éxito" or "Error",
                Text = message,
                Duration = 5,
                Type = success and "Success" or "Error",
            })
        end
    end)
end

local prisonEscapeEvent = RemoteEvents.GetEvent("PrisonEscape")
if prisonEscapeEvent then
    prisonEscapeEvent.OnServerEvent:Connect(function(player)
        local success, message = attemptEscape(player)
        RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
            Title = success and "¡Escape!" or "Fallido",
            Text = message,
            Duration = 5,
            Type = success and "Success" or "Error",
        })
    end)
end

-----------------------------------------------------
-- LIMPIAR AL SALIR
-----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    prisonPlayers[player.UserId] = nil
end)

print("[PrisonSystem] Sistema de prisión inicializado")
