--[[
    MainHUD - Interfaz principal del jugador
    Incluye: Notificaciones, Chat Policial, Barra de Bolso, Info de Equipo
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-----------------------------------------------------
-- CREAR SCREEN GUI PRINCIPAL
-----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-----------------------------------------------------
-- PANEL DE NOTIFICACIONES
-----------------------------------------------------
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 350, 0, 0) -- Se expande dinámicamente
notificationFrame.Position = UDim2.new(1, -370, 0, 20)
notificationFrame.BackgroundTransparency = 1
notificationFrame.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 5)
notifLayout.Parent = notificationFrame

local function showNotification(data)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = data.Type == "Error" and Color3.fromRGB(180, 30, 30) 
        or data.Type == "Warning" and Color3.fromRGB(180, 150, 0) 
        or data.Type == "Success" and Color3.fromRGB(30, 150, 30) 
        or Color3.fromRGB(30, 100, 180)
    notif.BackgroundTransparency = 0.2
    notif.BorderSizePixel = 0
    notif.Parent = notificationFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 20)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = data.Title or "Notificación"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notif
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 0, 30)
    text.Position = UDim2.new(0, 5, 0, 25)
    text.BackgroundTransparency = 1
    text.Text = data.Text or ""
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.Gotham
    text.TextSize = 12
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.Parent = notif
    
    -- Auto-destruir
    task.delay(data.Duration or 5, function()
        if notif and notif.Parent then
            notif:Destroy()
        end
    end)
end

-----------------------------------------------------
-- CHAT PRIVADO DE POLICÍA
-----------------------------------------------------
local policeChatFrame = Instance.new("Frame")
policeChatFrame.Name = "PoliceChat"
policeChatFrame.Size = UDim2.new(0, 300, 0, 200)
policeChatFrame.Position = UDim2.new(0, 20, 1, -220)
policeChatFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 50)
policeChatFrame.BackgroundTransparency = 0.3
policeChatFrame.BorderSizePixel = 0
policeChatFrame.Visible = false -- Solo visible para policías
policeChatFrame.Parent = screenGui

local policeChatCorner = Instance.new("UICorner")
policeChatCorner.CornerRadius = UDim.new(0, 10)
policeChatCorner.Parent = policeChatFrame

local policeChatTitle = Instance.new("TextLabel")
policeChatTitle.Size = UDim2.new(1, 0, 0, 30)
policeChatTitle.BackgroundColor3 = Color3.fromRGB(0, 0, 100)
policeChatTitle.BackgroundTransparency = 0.3
policeChatTitle.Text = "CHAT POLICIAL PRIVADO"
policeChatTitle.TextColor3 = Color3.new(1, 1, 1)
policeChatTitle.Font = Enum.Font.GothamBold
policeChatTitle.TextSize = 14
policeChatTitle.Parent = policeChatFrame

local policeChatTitleCorner = Instance.new("UICorner")
policeChatTitleCorner.CornerRadius = UDim.new(0, 10)
policeChatTitleCorner.Parent = policeChatTitle

local policeChatScroll = Instance.new("ScrollingFrame")
policeChatScroll.Size = UDim2.new(1, -10, 1, -40)
policeChatScroll.Position = UDim2.new(0, 5, 0, 35)
policeChatScroll.BackgroundTransparency = 1
policeChatScroll.ScrollBarThickness = 4
policeChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
policeChatScroll.Parent = policeChatFrame

local policeChatLayout = Instance.new("UIListLayout")
policeChatLayout.SortOrder = Enum.SortOrder.LayoutOrder
policeChatLayout.Padding = UDim.new(0, 2)
policeChatLayout.Parent = policeChatScroll

local function addPoliceMessage(message)
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 20)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = os.date("%H:%M") .. " " .. message
    msgLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 11
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = policeChatScroll
    
    -- Actualizar canvas size
    policeChatScroll.CanvasSize = UDim2.new(0, 0, 0, policeChatLayout.AbsoluteContentSize.Y)
    policeChatScroll.CanvasPosition = Vector2.new(0, policeChatLayout.AbsoluteContentSize.Y)
end

-----------------------------------------------------
-- BARRA DE INFORMACIÓN DEL EQUIPO
-----------------------------------------------------
local teamBar = Instance.new("Frame")
teamBar.Name = "TeamBar"
teamBar.Size = UDim2.new(0, 200, 0, 30)
teamBar.Position = UDim2.new(0.5, -100, 0, 5)
teamBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
teamBar.BackgroundTransparency = 0.3
teamBar.BorderSizePixel = 0
teamBar.Parent = screenGui

local teamBarCorner = Instance.new("UICorner")
teamBarCorner.CornerRadius = UDim.new(0, 15)
teamBarCorner.Parent = teamBar

local teamLabel = Instance.new("TextLabel")
teamLabel.Size = UDim2.new(1, 0, 1, 0)
teamLabel.BackgroundTransparency = 1
teamLabel.Text = "Civil"
teamLabel.TextColor3 = Color3.new(1, 1, 1)
teamLabel.Font = Enum.Font.GothamBold
teamLabel.TextSize = 16
teamLabel.Parent = teamBar

-----------------------------------------------------
-- BARRA DE BOLSO
-----------------------------------------------------
local bagBar = Instance.new("Frame")
bagBar.Name = "BagBar"
bagBar.Size = UDim2.new(0, 180, 0, 25)
bagBar.Position = UDim2.new(0.5, -90, 0, 40)
bagBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
bagBar.BackgroundTransparency = 0.3
bagBar.BorderSizePixel = 0
bagBar.Visible = false -- Solo visible cuando tiene bolso
bagBar.Parent = screenGui

local bagBarCorner = Instance.new("UICorner")
bagBarCorner.CornerRadius = UDim.new(0, 12)
bagBarCorner.Parent = bagBar

local bagLabel = Instance.new("TextLabel")
bagLabel.Size = UDim2.new(1, 0, 1, 0)
bagLabel.BackgroundTransparency = 1
bagLabel.Text = "Bolso: 0/5"
bagLabel.TextColor3 = Color3.new(1, 1, 1)
bagLabel.Font = Enum.Font.Gotham
bagLabel.TextSize = 12
bagLabel.Parent = bagBar

-----------------------------------------------------
-- CONECTAR EVENTOS
-----------------------------------------------------
local function connectEvents()
    -- Notificaciones
    local showNotifEvent = RemoteEvents.GetEvent("ShowNotification")
    if showNotifEvent then
        showNotifEvent.OnClientEvent:Connect(function(data)
            showNotification(data)
        end)
    end
    
    -- Chat Policial
    local policeMsgEvent = RemoteEvents.GetEvent("PoliceChatMessage")
    if policeMsgEvent then
        policeMsgEvent.OnClientEvent:Connect(function(message)
            policeChatFrame.Visible = true
            addPoliceMessage(message)
        end)
    end
    
    -- Actualización de equipo
    local teamChangedEvent = RemoteEvents.GetEvent("TeamChanged")
    if teamChangedEvent then
        teamChangedEvent.OnClientEvent:Connect(function(teamName)
            teamLabel.Text = teamName
            
            -- Mostrar/ocultar chat policial
            local isPolice = (teamName == "Policía" or teamName == "SWAT")
            policeChatFrame.Visible = isPolice
        end)
    end
    
    -- Actualización de bolso
    local bagEvent = RemoteEvents.GetEvent("BagContentsChanged")
    if bagEvent then
        bagEvent.OnClientEvent:Connect(function(data)
            if data.Contents then
                bagBar.Visible = true
                local capacity = data.Capacity or 5
                bagLabel.Text = "Bolso: " .. #data.Contents .. "/" .. capacity
            end
            if data.Message then
                showNotification({
                    Title = "Bolso",
                    Text = data.Message,
                    Duration = 3,
                    Type = "Info",
                })
            end
        end)
    end
    
    -- Robo completado
    local robberyEvent = RemoteEvents.GetEvent("RobberyComplete")
    if robberyEvent then
        robberyEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = "¡Robo Exitoso!",
                Text = data.Type .. ": " .. (data.Loot or ("$" .. (data.Reward or 0))),
                Duration = 8,
                Type = "Success",
            })
        end)
    end
    
    -- Camión blindado
    local truckSpawnEvent = RemoteEvents.GetEvent("ArmoredTruckSpawn")
    if truckSpawnEvent then
        truckSpawnEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = "CAMIÓN BLINDADO",
                Text = data.Message,
                Duration = 10,
                Type = "Warning",
            })
        end)
    end
    
    local truckRobbedEvent = RemoteEvents.GetEvent("ArmoredTruckRobbed")
    if truckRobbedEvent then
        truckRobbedEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = "¡CAMIÓN BLINDADO ROBADO!",
                Text = data.Message,
                Duration = 10,
                Type = "Success",
            })
        end)
    end
    
    -- Resultado de puerta de grupo
    local doorEvent = RemoteEvents.GetEvent("DoorAccessResult")
    if doorEvent then
        doorEvent.OnClientEvent:Connect(function(hasAccess, message)
            showNotification({
                Title = hasAccess and "Acceso Concedido" or "Acceso Denegado",
                Text = message,
                Duration = 3,
                Type = hasAccess and "Success" or "Error",
            })
        end)
    end
    
    -- Resultado de comandos
    local cmdResultEvent = RemoteEvents.GetEvent("CommandResult")
    if cmdResultEvent then
        cmdResultEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = data.Success and "Comando Ejecutado" or "Error",
                Text = data.Message,
                Duration = 5,
                Type = data.Success and "Success" or "Error",
            })
        end)
    end
    
    -- Resultado de admin
    local adminResultEvent = RemoteEvents.GetEvent("AdminCommandResult")
    if adminResultEvent then
        adminResultEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = data.Success and "Admin" or "Error",
                Text = data.Message,
                Duration = 5,
                Type = data.Success and "Success" or "Error",
            })
        end)
    end
    
    -- Prisión
    local prisonReleaseEvent = RemoteEvents.GetEvent("PrisonRelease")
    if prisonReleaseEvent then
        prisonReleaseEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = "Liberado",
                Text = data.Message,
                Duration = 5,
                Type = "Success",
            })
        end)
    end
    
    -- SWAT truck
    local swatTruckEvent = RemoteEvents.GetEvent("SWATTruckSpawned")
    if swatTruckEvent then
        swatTruckEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = data.Success and "SWAT" or "Error",
                Text = data.Message,
                Duration = 5,
                Type = data.Success and "Success" or "Error",
            })
        end)
    end
    
    -- Servidor privado renovado
    local serverRenewedEvent = RemoteEvents.GetEvent("ServerRenewed")
    if serverRenewedEvent then
        serverRenewedEvent.OnClientEvent:Connect(function(data)
            showNotification({
                Title = data.Success and "Servidor Renovado" or "Error",
                Text = data.Message,
                Duration = 10,
                Type = data.Success and "Success" or "Error",
            })
        end)
    end
end

-- Esperar a que los eventos estén listos
task.wait(2)
connectEvents()

-- Inicializar equipo
if player.Team then
    teamLabel.Text = player.Team.Name
end

player:GetPropertyChangedSignal("Team"):Connect(function()
    if player.Team then
        teamLabel.Text = player.Team.Name
        policeChatFrame.Visible = (player.Team.Name == "Policía" or player.Team.Name == "SWAT")
    end
end)

print("[MainHUD] HUD principal inicializado")
