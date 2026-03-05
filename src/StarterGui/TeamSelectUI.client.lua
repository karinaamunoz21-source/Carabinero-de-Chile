--[[
    TeamSelectUI - Interfaz de selección de equipo
    PD (Policía), Civil, Criminal
    SWAT requiere pase
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-----------------------------------------------------
-- CREAR GUI
-----------------------------------------------------
local teamGui = Instance.new("ScreenGui")
teamGui.Name = "TeamSelectUI"
teamGui.ResetOnSpawn = true
teamGui.Parent = playerGui

-- Fondo oscuro
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.4
backdrop.BorderSizePixel = 0
backdrop.Parent = teamGui

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 400)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = teamGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainFrame

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundTransparency = 1
title.Text = "SELECCIONA TU EQUIPO"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 28
title.Parent = mainFrame

-- Subtítulo
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 25)
subtitle.Position = UDim2.new(0, 0, 0, 50)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Carabineros de Chile - Roleplay"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 200)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.Parent = mainFrame

-- Container para botones de equipo
local teamsContainer = Instance.new("Frame")
teamsContainer.Size = UDim2.new(1, -40, 0, 250)
teamsContainer.Position = UDim2.new(0, 20, 0, 90)
teamsContainer.BackgroundTransparency = 1
teamsContainer.Parent = mainFrame

local teamsLayout = Instance.new("UIListLayout")
teamsLayout.FillDirection = Enum.FillDirection.Horizontal
teamsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
teamsLayout.Padding = UDim.new(0, 15)
teamsLayout.Parent = teamsContainer

-----------------------------------------------------
-- CREAR BOTÓN DE EQUIPO
-----------------------------------------------------
local function createTeamButton(teamKey, teamData, description, requiresPass, passName)
    local btn = Instance.new("Frame")
    btn.Size = UDim2.new(0, 125, 0, 240)
    btn.BackgroundColor3 = teamData.Color.Color
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Parent = teamsContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = btn
    
    -- Nombre del equipo
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 40)
    nameLabel.Position = UDim2.new(0, 0, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = teamData.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.Parent = btn
    
    -- Descripción
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 100)
    descLabel.Position = UDim2.new(0, 5, 0, 55)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.TextWrapped = true
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.Parent = btn
    
    -- Pase requerido
    if requiresPass then
        local passLabel = Instance.new("TextLabel")
        passLabel.Size = UDim2.new(1, 0, 0, 20)
        passLabel.Position = UDim2.new(0, 0, 0, 155)
        passLabel.BackgroundTransparency = 1
        passLabel.Text = "Requiere Pase"
        passLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        passLabel.Font = Enum.Font.GothamBold
        passLabel.TextSize = 10
        passLabel.Parent = btn
    end
    
    -- Botón seleccionar
    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(0.8, 0, 0, 35)
    selectBtn.Position = UDim2.new(0.1, 0, 1, -45)
    selectBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    selectBtn.Text = requiresPass and "Comprar Pase" or "Seleccionar"
    selectBtn.TextColor3 = Color3.new(1, 1, 1)
    selectBtn.Font = Enum.Font.GothamBold
    selectBtn.TextSize = 13
    selectBtn.BorderSizePixel = 0
    selectBtn.Parent = btn
    
    local selectCorner = Instance.new("UICorner")
    selectCorner.CornerRadius = UDim.new(0, 8)
    selectCorner.Parent = selectBtn
    
    selectBtn.MouseButton1Click:Connect(function()
        if requiresPass then
            -- Abrir compra de pase
            local passId = GameConfig.GamePasses[passName]
            if passId and passId > 0 then
                MarketplaceService:PromptGamePassPurchase(player, passId)
            end
        else
            -- Cambiar equipo
            local changeEvent = RemoteEvents.GetEvent("ChangeTeam")
            if changeEvent then
                changeEvent:FireServer(teamData.Name)
            end
            teamGui.Enabled = false
        end
    end)
    
    return btn
end

-----------------------------------------------------
-- CREAR BOTONES DE EQUIPOS
-----------------------------------------------------
task.wait(2) -- Esperar a que los eventos estén listos

createTeamButton("CIVIL", GameConfig.Teams.CIVIL, 
    "Vive como civil.\nTrabaja, compra,\nexplora la ciudad.\nSin armas.", false, nil)

createTeamButton("PD", GameConfig.Teams.PD, 
    "Protege la ciudad.\nTaser, Esposas.\nArresta criminales.\nPatrulla las calles.", false, nil)

createTeamButton("CRIMINAL", GameConfig.Teams.CRIMINAL, 
    "Roba tiendas.\nLutea jugadores.\nJoyería, Banco.\nCamión blindado.", false, nil)

createTeamButton("SWAT", GameConfig.Teams.SWAT, 
    "Unidad especial.\nM4, MP5, Sniper.\nAriete, Camión.\nRequiere GamePass.", true, "SWAT")

print("[TeamSelectUI] Selección de equipo inicializada")
