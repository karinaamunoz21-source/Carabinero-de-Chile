--[[
    RobberyUI - Interfaz de robos
    Joyería, Banco, Camión Blindado
    Muestra progreso del robo y loot obtenido
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-----------------------------------------------------
-- CREAR GUI
-----------------------------------------------------
local robberyGui = Instance.new("ScreenGui")
robberyGui.Name = "RobberyUI"
robberyGui.ResetOnSpawn = false
robberyGui.Parent = playerGui

-- Frame de robo activo
local robberyFrame = Instance.new("Frame")
robberyFrame.Name = "RobberyFrame"
robberyFrame.Size = UDim2.new(0, 350, 0, 120)
robberyFrame.Position = UDim2.new(0.5, -175, 0.8, -60)
robberyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
robberyFrame.BackgroundTransparency = 0.2
robberyFrame.BorderSizePixel = 0
robberyFrame.Visible = false
robberyFrame.Parent = robberyGui

local robberyCorner = Instance.new("UICorner")
robberyCorner.CornerRadius = UDim.new(0, 10)
robberyCorner.Parent = robberyFrame

-- Título del robo
local robberyTitle = Instance.new("TextLabel")
robberyTitle.Size = UDim2.new(1, 0, 0, 30)
robberyTitle.BackgroundTransparency = 1
robberyTitle.Text = "ROBANDO..."
robberyTitle.TextColor3 = Color3.fromRGB(255, 50, 50)
robberyTitle.Font = Enum.Font.GothamBold
robberyTitle.TextSize = 18
robberyTitle.Parent = robberyFrame

-- Barra de progreso
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0.9, 0, 0, 20)
progressBg.Position = UDim2.new(0.05, 0, 0, 40)
progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressBg.BorderSizePixel = 0
progressBg.Parent = robberyFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 10)
progressCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, 10)
progressBarCorner.Parent = progressBar

-- Info del robo
local robberyInfo = Instance.new("TextLabel")
robberyInfo.Size = UDim2.new(1, 0, 0, 30)
robberyInfo.Position = UDim2.new(0, 0, 0, 65)
robberyInfo.BackgroundTransparency = 1
robberyInfo.Text = ""
robberyInfo.TextColor3 = Color3.new(1, 1, 1)
robberyInfo.Font = Enum.Font.Gotham
robberyInfo.TextSize = 12
robberyInfo.Parent = robberyFrame

-- Botón cancelar
local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0, 100, 0, 25)
cancelBtn.Position = UDim2.new(0.5, -50, 0, 90)
cancelBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
cancelBtn.Text = "Cancelar"
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 12
cancelBtn.BorderSizePixel = 0
cancelBtn.Parent = robberyFrame

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 6)
cancelCorner.Parent = cancelBtn

local isRobbing = false

cancelBtn.MouseButton1Click:Connect(function()
    isRobbing = false
    robberyFrame.Visible = false
end)

-----------------------------------------------------
-- BOTONES DE ROBO (aparecen cerca de tiendas robables)
-----------------------------------------------------
local robButtonFrame = Instance.new("Frame")
robButtonFrame.Name = "RobButtons"
robButtonFrame.Size = UDim2.new(0, 200, 0, 40)
robButtonFrame.Position = UDim2.new(0.5, -100, 0.7, 0)
robButtonFrame.BackgroundTransparency = 1
robButtonFrame.Visible = false
robButtonFrame.Parent = robberyGui

local robJewelryBtn = Instance.new("TextButton")
robJewelryBtn.Size = UDim2.new(1, 0, 0, 35)
robJewelryBtn.BackgroundColor3 = Color3.fromRGB(200, 170, 0)
robJewelryBtn.Text = "ROBAR JOYERÍA"
robJewelryBtn.TextColor3 = Color3.new(0, 0, 0)
robJewelryBtn.Font = Enum.Font.GothamBold
robJewelryBtn.TextSize = 14
robJewelryBtn.BorderSizePixel = 0
robJewelryBtn.Visible = false
robJewelryBtn.Parent = robberyGui

local robJewelryCorner = Instance.new("UICorner")
robJewelryCorner.CornerRadius = UDim.new(0, 8)
robJewelryCorner.Parent = robJewelryBtn

local robBankBtn = Instance.new("TextButton")
robBankBtn.Size = UDim2.new(0, 200, 0, 35)
robBankBtn.Position = UDim2.new(0.5, -100, 0.7, 40)
robBankBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
robBankBtn.Text = "ROBAR BANCO (C4)"
robBankBtn.TextColor3 = Color3.new(1, 1, 1)
robBankBtn.Font = Enum.Font.GothamBold
robBankBtn.TextSize = 14
robBankBtn.BorderSizePixel = 0
robBankBtn.Visible = false
robBankBtn.Parent = robberyGui

local robBankCorner = Instance.new("UICorner")
robBankCorner.CornerRadius = UDim.new(0, 8)
robBankCorner.Parent = robBankBtn

-----------------------------------------------------
-- FUNCIONES DE ROBO
-----------------------------------------------------
local function startRobbery(robberyType, duration)
    if isRobbing then return end
    isRobbing = true
    
    robberyTitle.Text = "ROBANDO " .. string.upper(robberyType) .. "..."
    robberyInfo.Text = "No te muevas... Policías alertados"
    robberyFrame.Visible = true
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    
    local elapsed = 0
    local totalTime = duration or 15
    
    while elapsed < totalTime and isRobbing do
        task.wait(0.1)
        elapsed = elapsed + 0.1
        local progress = elapsed / totalTime
        progressBar.Size = UDim2.new(math.min(progress, 1), 0, 1, 0)
        robberyInfo.Text = string.format("Progreso: %d%% | Tiempo: %.1fs", progress * 100, totalTime - elapsed)
    end
    
    if isRobbing then
        -- Completar robo
        local startRobberyEvent = RemoteEvents.GetEvent("StartRobbery")
        if startRobberyEvent then
            startRobberyEvent:FireServer(robberyType)
        end
    end
    
    isRobbing = false
    robberyFrame.Visible = false
end

-- Robar Joyería
robJewelryBtn.MouseButton1Click:Connect(function()
    robJewelryBtn.Visible = false
    startRobbery("Joyería", 20)
end)

-- Robar Banco
robBankBtn.MouseButton1Click:Connect(function()
    robBankBtn.Visible = false
    startRobbery("Banco", 30)
end)

-----------------------------------------------------
-- DETECTAR PROXIMIDAD A LUGARES ROBABLES
-----------------------------------------------------
local RunService = game:GetService("RunService")

local function checkProximity()
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local nearJewelry = false
    local nearBank = false
    
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local shopType = obj:GetAttribute("ShopType")
            local distance = (rootPart.Position - obj.Position).Magnitude
            
            if shopType == "JOYERIA" and distance < 15 then
                nearJewelry = true
            elseif shopType == "BANCO" and distance < 15 then
                nearBank = true
            end
        end
    end
    
    robJewelryBtn.Visible = nearJewelry and not isRobbing
    robBankBtn.Visible = nearBank and not isRobbing
    
    if nearJewelry then
        robJewelryBtn.Position = UDim2.new(0.5, -100, 0.7, 0)
    end
    if nearBank then
        robBankBtn.Position = UDim2.new(0.5, -100, 0.7, nearJewelry and 40 or 0)
    end
end

RunService.Heartbeat:Connect(function()
    checkProximity()
end)

-----------------------------------------------------
-- RESULTADO DE ROBO
-----------------------------------------------------
task.wait(2)

local robberyUpdateEvent = RemoteEvents.GetEvent("RobberyUpdate")
if robberyUpdateEvent then
    robberyUpdateEvent.OnClientEvent:Connect(function(data)
        if data.Success then
            robberyFrame.Visible = false
            isRobbing = false
        end
    end)
end

print("[RobberyUI] Interfaz de robos inicializada")
