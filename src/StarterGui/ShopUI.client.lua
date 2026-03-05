--[[
    ShopUI - Interfaz de todas las tiendas
    Incluye: Ropa, Zapatos, Pantalón, Accesorios, Joyería, 
    Mercado Negro, Tatuajes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-----------------------------------------------------
-- CREAR SCREEN GUI
-----------------------------------------------------
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopUI"
shopGui.ResetOnSpawn = false
shopGui.Parent = playerGui

-----------------------------------------------------
-- FRAME PRINCIPAL DE TIENDA
-----------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "ShopFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = shopGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Título
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "TIENDA"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Scrolling frame para items
local itemsScroll = Instance.new("ScrollingFrame")
itemsScroll.Size = UDim2.new(1, -20, 1, -55)
itemsScroll.Position = UDim2.new(0, 10, 0, 50)
itemsScroll.BackgroundTransparency = 1
itemsScroll.ScrollBarThickness = 6
itemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
itemsScroll.Parent = mainFrame

local itemsGrid = Instance.new("UIGridLayout")
itemsGrid.CellSize = UDim2.new(0, 220, 0, 80)
itemsGrid.CellPadding = UDim2.new(0, 10, 0, 10)
itemsGrid.SortOrder = Enum.SortOrder.LayoutOrder
itemsGrid.Parent = itemsScroll

-----------------------------------------------------
-- CREAR ITEM CARD
-----------------------------------------------------
local function createItemCard(item, shopKey)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    card.BorderSizePixel = 0
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Nombre del item
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = item.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Zona (para tatuajes)
    if item.Zone then
        local zoneLabel = Instance.new("TextLabel")
        zoneLabel.Size = UDim2.new(1, -10, 0, 15)
        zoneLabel.Position = UDim2.new(0, 5, 0, 28)
        zoneLabel.BackgroundTransparency = 1
        zoneLabel.Text = "Zona: " .. item.Zone
        zoneLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
        zoneLabel.Font = Enum.Font.Gotham
        zoneLabel.TextSize = 10
        zoneLabel.TextXAlignment = Enum.TextXAlignment.Left
        zoneLabel.Parent = card
    end
    
    -- Precio
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0.5, -5, 0, 25)
    priceLabel.Position = UDim2.new(0, 5, 1, -30)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "$" .. (item.Price or 0)
    priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextSize = 14
    priceLabel.TextXAlignment = Enum.TextXAlignment.Left
    priceLabel.Parent = card
    
    -- Botón comprar
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0.45, 0, 0, 25)
    buyBtn.Position = UDim2.new(0.5, 5, 1, -30)
    buyBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
    buyBtn.Text = "Comprar"
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 12
    buyBtn.BorderSizePixel = 0
    buyBtn.Parent = card
    
    local buyBtnCorner = Instance.new("UICorner")
    buyBtnCorner.CornerRadius = UDim.new(0, 6)
    buyBtnCorner.Parent = buyBtn
    
    buyBtn.MouseButton1Click:Connect(function()
        local purchaseEvent = RemoteEvents.GetEvent("PurchaseItem")
        if purchaseEvent then
            purchaseEvent:FireServer(shopKey, item.Name)
        end
    end)
    
    return card
end

-----------------------------------------------------
-- ABRIR TIENDA
-----------------------------------------------------
local function openShop(shopKey)
    local shopConfig = GameConfig.Shops[shopKey]
    if not shopConfig then return end
    
    -- Limpiar items anteriores
    for _, child in ipairs(itemsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Actualizar título
    titleLabel.Text = shopConfig.Name
    
    -- Configurar color según tipo de tienda
    local colors = {
        ROPA = Color3.fromRGB(100, 50, 150),
        ZAPATOS = Color3.fromRGB(150, 100, 50),
        PANTALON = Color3.fromRGB(50, 100, 150),
        ACCESORIOS = Color3.fromRGB(150, 50, 100),
        JOYERIA = Color3.fromRGB(200, 170, 50),
        MERCADO_NEGRO = Color3.fromRGB(30, 30, 30),
        TATUAJES = Color3.fromRGB(80, 30, 30),
    }
    
    titleBar.BackgroundColor3 = colors[shopKey] or Color3.fromRGB(40, 40, 60)
    
    -- Crear cards para cada item
    if shopConfig.Items then
        for _, item in ipairs(shopConfig.Items) do
            local card = createItemCard(item, shopKey)
            card.Parent = itemsScroll
        end
    end
    
    -- Actualizar canvas size
    task.wait(0.1)
    itemsScroll.CanvasSize = UDim2.new(0, 0, 0, itemsGrid.AbsoluteContentSize.Y + 20)
    
    mainFrame.Visible = true
end

-----------------------------------------------------
-- CONECTAR EVENTOS
-----------------------------------------------------
task.wait(2)

-- Evento de abrir tienda
local openShopEvent = RemoteEvents.GetEvent("OpenShop")
if openShopEvent then
    openShopEvent.OnClientEvent:Connect(function(shopKey)
        openShop(shopKey)
    end)
end

-- Resultado de compra
local purchaseResultEvent = RemoteEvents.GetEvent("PurchaseResult")
if purchaseResultEvent then
    purchaseResultEvent.OnClientEvent:Connect(function(data)
        -- Mostrar notificación usando MainHUD
        local showNotifEvent = RemoteEvents.GetEvent("ShowNotification")
        if showNotifEvent then
            -- El evento de notificación ya está manejado en MainHUD
        end
    end)
end

-- Resultado de tatuaje
local tattooEvent = RemoteEvents.GetEvent("TattooApplied")
if tattooEvent then
    tattooEvent.OnClientEvent:Connect(function(data)
        if data.Success then
            -- Feedback visual
        end
    end)
end

print("[ShopUI] Interfaz de tiendas inicializada")
