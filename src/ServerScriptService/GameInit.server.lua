--[[
    GameInit - Script principal del servidor
    Inicializa todos los sistemas del juego
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Esperar a que los módulos estén disponibles
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

-----------------------------------------------------
-- INICIALIZAR REMOTE EVENTS
-----------------------------------------------------
RemoteEvents.Init()
print("[GameInit] RemoteEvents inicializados")

-----------------------------------------------------
-- CREAR EQUIPOS
-----------------------------------------------------
local function createTeams()
    for key, teamData in pairs(GameConfig.Teams) do
        local team = Instance.new("Team")
        team.Name = teamData.Name
        team.TeamColor = teamData.Color
        team.AutoAssignable = (key == "CIVIL")
        team.Parent = Teams
    end
    print("[GameInit] Equipos creados")
end

createTeams()

-----------------------------------------------------
-- CREAR LEADERSTATS
-----------------------------------------------------
local function setupLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    local cashStat = Instance.new("IntValue")
    cashStat.Name = "Dinero"
    cashStat.Parent = leaderstats
    
    local teamStat = Instance.new("StringValue")
    teamStat.Name = "Equipo"
    teamStat.Parent = leaderstats
    
    local roleStat = Instance.new("StringValue")
    roleStat.Name = "Rol"
    roleStat.Parent = leaderstats
    
    local criminalRecord = Instance.new("IntValue")
    criminalRecord.Name = "Antecedentes"
    criminalRecord.Parent = leaderstats
    
    local arrests = Instance.new("IntValue")
    arrests.Name = "Arrestos"
    arrests.Parent = leaderstats
    
    return leaderstats
end

-----------------------------------------------------
-- JUGADOR ENTRA
-----------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    -- Verificar ban
    local isBanned, reason = DataManager.IsPlayerBanned(player.UserId)
    if isBanned then
        player:Kick("Estás baneado: " .. (reason or "Sin razón"))
        return
    end
    
    -- Cargar datos
    local data = DataManager.LoadPlayerData(player)
    
    -- Crear leaderstats
    local leaderstats = setupLeaderstats(player)
    leaderstats.Dinero.Value = data.Cash
    leaderstats.Equipo.Value = data.Team
    leaderstats.Antecedentes.Value = data.CriminalRecord
    leaderstats.Arrestos.Value = data.ArrestsCount
    
    -- Asignar equipo
    local teamName = data.Team
    local team = Teams:FindFirstChild(teamName) or Teams:FindFirstChild("Civil")
    if team then
        player.Team = team
        leaderstats.Equipo.Value = team.Name
    end
    
    -- Verificar GamePasses
    for passName, passId in pairs(GameConfig.GamePasses) do
        if passId > 0 then
            local success, hasPass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            if success and hasPass then
                data.OwnedGamePasses[passName] = true
            end
        end
    end
    
    -- Expandir bolso si tiene el pase
    if data.OwnedGamePasses["EXPANDIR_BOLSO"] then
        DataManager.ExpandBag(player)
    end
    
    print("[GameInit] Jugador conectado: " .. player.Name)
end)

-----------------------------------------------------
-- JUGADOR SALE
-----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    -- Actualizar datos desde leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local data = DataManager.GetPlayerData(player)
        if data then
            data.Cash = leaderstats.Dinero.Value
            data.Team = leaderstats.Equipo.Value
        end
    end
    
    DataManager.CleanupPlayer(player)
    print("[GameInit] Jugador desconectado: " .. player.Name)
end)

-----------------------------------------------------
-- GUARDAR DATOS PERIÓDICAMENTE
-----------------------------------------------------
spawn(function()
    while true do
        wait(300) -- Cada 5 minutos
        for _, player in ipairs(Players:GetPlayers()) do
            DataManager.SavePlayerData(player)
        end
        print("[GameInit] Auto-guardado completado")
    end
end)

-----------------------------------------------------
-- CAMBIAR EQUIPO
-----------------------------------------------------
local changeTeamEvent = RemoteEvents.GetEvent("ChangeTeam")
if changeTeamEvent then
    changeTeamEvent.OnServerEvent:Connect(function(player, teamName)
        local team = Teams:FindFirstChild(teamName)
        if team then
            player.Team = team
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                leaderstats.Equipo.Value = teamName
            end
            
            local data = DataManager.GetPlayerData(player)
            if data then
                data.Team = teamName
            end
            
            RemoteEvents.GetEvent("TeamChanged"):FireClient(player, teamName)
        end
    end)
end

-----------------------------------------------------
-- GET PLAYER DATA (RemoteFunction)
-----------------------------------------------------
local getPlayerDataFunc = RemoteEvents.GetFunction("GetPlayerData")
if getPlayerDataFunc then
    getPlayerDataFunc.OnServerInvoke = function(player)
        return DataManager.GetPlayerData(player)
    end
end

-----------------------------------------------------
-- CHECK GAMEPASS (RemoteFunction)
-----------------------------------------------------
local checkGamePassFunc = RemoteEvents.GetFunction("CheckGamePass")
if checkGamePassFunc then
    checkGamePassFunc.OnServerInvoke = function(player, passName)
        local data = DataManager.GetPlayerData(player)
        if data then
            return data.OwnedGamePasses[passName] == true
        end
        return false
    end
end

print("[GameInit] ===== SERVIDOR INICIALIZADO =====")
