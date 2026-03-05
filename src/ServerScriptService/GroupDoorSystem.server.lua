--[[
    GroupDoorSystem - Sistema de puertas vinculadas al grupo de Roblox
    Solo miembros del grupo pueden abrir las puertas de las bases
]]

local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

local GroupDoorSystem = {}

-- Cache de verificación de grupo
local groupCache = {}

-----------------------------------------------------
-- VERIFICAR MEMBRESÍA DE GRUPO
-----------------------------------------------------
local function isInGroup(player)
    if groupCache[player.UserId] ~= nil then
        return groupCache[player.UserId]
    end
    
    local success, inGroup = pcall(function()
        return player:IsInGroup(GameConfig.GROUP_ID)
    end)
    
    if success then
        groupCache[player.UserId] = inGroup
        return inGroup
    end
    
    return false
end

local function getGroupRank(player)
    local success, rank = pcall(function()
        return player:GetRankInGroup(GameConfig.GROUP_ID)
    end)
    
    if success then
        return rank
    end
    return 0
end

-----------------------------------------------------
-- CONFIGURAR PUERTAS DE GRUPO
-----------------------------------------------------
local function setupGroupDoors()
    -- Buscar todas las puertas con tag "GroupDoor" en el Workspace
    local workspace = game:GetService("Workspace")
    
    local function setupDoor(door)
        if not door:IsA("BasePart") then return end
        
        local clickDetector = door:FindFirstChild("ClickDetector")
        if not clickDetector then
            clickDetector = Instance.new("ClickDetector")
            clickDetector.MaxActivationDistance = 10
            clickDetector.Parent = door
        end
        
        local isOpen = false
        local originalPosition = door.Position
        local originalTransparency = door.Transparency
        
        clickDetector.MouseClick:Connect(function(player)
            if isInGroup(player) then
                if not isOpen then
                    -- Abrir puerta
                    door.Transparency = 0.8
                    door.CanCollide = false
                    isOpen = true
                    
                    RemoteEvents.GetEvent("DoorAccessResult"):FireClient(player, true, "Puerta abierta")
                    
                    -- Cerrar después de 5 segundos
                    task.delay(5, function()
                        door.Transparency = originalTransparency
                        door.CanCollide = true
                        isOpen = false
                    end)
                end
            else
                RemoteEvents.GetEvent("DoorAccessResult"):FireClient(
                    player, false, 
                    "Debes ser miembro del grupo para entrar. ID del Grupo: " .. GameConfig.GROUP_ID
                )
            end
        end)
    end
    
    -- Buscar puertas en el workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "GroupDoor" or obj:GetAttribute("GroupDoor")) then
            setupDoor(obj)
        end
    end
    
    -- Escuchar nuevas puertas agregadas
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and (obj.Name == "GroupDoor" or obj:GetAttribute("GroupDoor")) then
            setupDoor(obj)
        end
    end)
end

-----------------------------------------------------
-- EVENTO DE INTERACCIÓN CON PUERTA
-----------------------------------------------------
local doorInteractEvent = RemoteEvents.GetEvent("GroupDoorInteract")
if doorInteractEvent then
    doorInteractEvent.OnServerEvent:Connect(function(player, doorName)
        local inGroup = isInGroup(player)
        local rank = getGroupRank(player)
        
        RemoteEvents.GetEvent("DoorAccessResult"):FireClient(player, inGroup, 
            inGroup and "Acceso concedido (Rango: " .. rank .. ")" or "Acceso denegado - No eres miembro del grupo"
        )
    end)
end

-----------------------------------------------------
-- LIMPIAR CACHE AL SALIR
-----------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    groupCache[player.UserId] = nil
end)

-----------------------------------------------------
-- INICIALIZAR
-----------------------------------------------------
setupGroupDoors()
print("[GroupDoorSystem] Sistema de puertas de grupo inicializado")
