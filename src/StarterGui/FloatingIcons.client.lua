--[[
    FloatingIcons - Iconos flotantes sobre cada tienda
    Cada tienda tiene su propio icono visible desde lejos
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-----------------------------------------------------
-- ICONOS DE TIENDA
-----------------------------------------------------
local shopIcons = {
    ROPA = { Emoji = "👕", Color = Color3.fromRGB(150, 50, 200) },
    ZAPATOS = { Emoji = "👟", Color = Color3.fromRGB(200, 130, 50) },
    PANTALON = { Emoji = "👖", Color = Color3.fromRGB(50, 130, 200) },
    ACCESORIOS = { Emoji = "🎩", Color = Color3.fromRGB(200, 50, 150) },
    JOYERIA = { Emoji = "💎", Color = Color3.fromRGB(255, 215, 0) },
    BANCO = { Emoji = "🏦", Color = Color3.fromRGB(50, 150, 50) },
    MERCADO_NEGRO = { Emoji = "🔫", Color = Color3.fromRGB(30, 30, 30) },
    TATUAJES = { Emoji = "🎨", Color = Color3.fromRGB(150, 30, 30) },
}

-----------------------------------------------------
-- CREAR ICONO FLOTANTE PARA UNA TIENDA
-----------------------------------------------------
local function createFloatingIcon(shopPart, shopKey)
    local shopConfig = GameConfig.Shops[shopKey]
    local iconConfig = shopIcons[shopKey]
    if not shopConfig or not iconConfig then return end
    
    -- BillboardGui flotante
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ShopIcon_" .. shopKey
    billboard.Size = UDim2.new(0, 180, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 200
    billboard.Parent = shopPart
    
    -- Frame del icono
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(1, 0, 1, 0)
    iconFrame.BackgroundColor3 = iconConfig.Color
    iconFrame.BackgroundTransparency = 0.2
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = billboard
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 10)
    iconCorner.Parent = iconFrame
    
    -- Icono / Emoji
    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Size = UDim2.new(0, 40, 0, 40)
    emojiLabel.Position = UDim2.new(0, 5, 0.5, -20)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = iconConfig.Emoji
    emojiLabel.TextSize = 28
    emojiLabel.Parent = iconFrame
    
    -- Nombre de la tienda
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -50, 0, 25)
    nameLabel.Position = UDim2.new(0, 45, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = shopConfig.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = iconFrame
    
    -- Indicador de "Entrar"
    local enterLabel = Instance.new("TextLabel")
    enterLabel.Size = UDim2.new(1, -50, 0, 20)
    enterLabel.Position = UDim2.new(0, 45, 0, 30)
    enterLabel.BackgroundTransparency = 1
    enterLabel.Text = shopConfig.Robbable and "Clic para entrar/robar" or "Clic para entrar"
    enterLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    enterLabel.Font = Enum.Font.Gotham
    enterLabel.TextSize = 10
    enterLabel.TextXAlignment = Enum.TextXAlignment.Left
    enterLabel.Parent = iconFrame
    
    -- Efecto de flotación (sube y baja)
    local startOffset = billboard.StudsOffset
    local elapsed = math.random() * math.pi * 2 -- Fase aleatoria
    
    RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        local yOffset = math.sin(elapsed * 2) * 0.5
        billboard.StudsOffset = startOffset + Vector3.new(0, yOffset, 0)
    end)
end

-----------------------------------------------------
-- BUSCAR TIENDAS EN EL WORKSPACE Y AGREGAR ICONOS
-----------------------------------------------------
local function setupShopIcons()
    -- Buscar partes con atributo "ShopType" o nombre específico
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local shopType = obj:GetAttribute("ShopType")
            if shopType and shopIcons[shopType] then
                local part = obj:IsA("Model") and obj.PrimaryPart or obj
                if part then
                    createFloatingIcon(part, shopType)
                end
            end
        end
    end
    
    -- Escuchar nuevas tiendas
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") then
            local shopType = obj:GetAttribute("ShopType")
            if shopType and shopIcons[shopType] then
                createFloatingIcon(obj, shopType)
            end
        end
    end)
end

-----------------------------------------------------
-- PROXIMIDAD A TIENDAS (abrir UI al acercarse)
-----------------------------------------------------
local function setupProximityDetection()
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    local SHOP_RANGE = 15 -- Studs
    local lastShopOpened = nil
    
    RunService.Heartbeat:Connect(function()
        if not rootPart or not rootPart.Parent then
            character = player.Character
            if character then
                rootPart = character:FindFirstChild("HumanoidRootPart")
            end
            return
        end
        
        local nearestShop = nil
        local nearestDistance = SHOP_RANGE
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj:GetAttribute("ShopType") then
                local distance = (rootPart.Position - obj.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestShop = obj:GetAttribute("ShopType")
                end
            end
        end
        
        if nearestShop and nearestShop ~= lastShopOpened then
            lastShopOpened = nearestShop
            local openShopEvent = RemoteEvents.GetEvent("OpenShop")
            if openShopEvent then
                openShopEvent:FireClient(nearestShop)
            end
        elseif not nearestShop then
            lastShopOpened = nil
        end
    end)
end

-----------------------------------------------------
-- INICIALIZAR
-----------------------------------------------------
task.wait(3) -- Esperar a que el workspace cargue
setupShopIcons()

-- Esperar al personaje para detección de proximidad
player.CharacterAdded:Connect(function()
    task.wait(1)
    setupProximityDetection()
end)

if player.Character then
    setupProximityDetection()
end

print("[FloatingIcons] Iconos flotantes de tiendas inicializados")
