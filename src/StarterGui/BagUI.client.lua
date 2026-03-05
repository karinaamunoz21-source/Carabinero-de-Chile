--[[
    BagUI - Interfaz del bolso de robo
    Muestra contenido del bolso, capacidad, y opciones de vender/tirar
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))

-----------------------------------------------------
-- CREAR GUI
-----------------------------------------------------
local bagGui = Instance.new("ScreenGui")
bagGui.Name = "BagUI"
bagGui.ResetOnSpawn = false
bagGui.Parent = playerGui

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "BagFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 350)
mainFrame.Position = UDim2.new(1, -320, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = bagGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Título
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(60, 50, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BOLSO DE ROBO (0/5)"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Lista de items
local itemsScroll = Instance.new("ScrollingFrame")
itemsScroll.Size = UDim2.new(1, -20, 1, -100)
itemsScroll.Position = UDim2.new(0, 10, 0, 45)
itemsScroll.BackgroundTransparency = 1
itemsScroll.ScrollBarThickness = 4
itemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
itemsScroll.Parent = mainFrame

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsLayout.Padding = UDim.new(0, 5)
itemsLayout.Parent = itemsScroll

-- Valor total
local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(1, -20, 0, 20)
totalLabel.Position = UDim2.new(0, 10, 1, -50)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = "Valor Total: $0"
totalLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextSize = 14
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = mainFrame

-- Botón vender todo
local sellBtn = Instance.new("TextButton")
sellBtn.Size = UDim2.new(0.9, 0, 0, 30)
sellBtn.Position = UDim2.new(0.05, 0, 1, -35)
sellBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 30)
sellBtn.Text = "VENDER TODO"
sellBtn.TextColor3 = Color3.new(1, 1, 1)
sellBtn.Font = Enum.Font.GothamBold
sellBtn.TextSize = 14
sellBtn.BorderSizePixel = 0
sellBtn.Parent = mainFrame

local sellCorner = Instance.new("UICorner")
sellCorner.CornerRadius = UDim.new(0, 8)
sellCorner.Parent = sellBtn

sellBtn.MouseButton1Click:Connect(function()
    local updateBagEvent = RemoteEvents.GetEvent("UpdateBag")
    if updateBagEvent then
        updateBagEvent:FireServer("Sell")
    end
end)

-----------------------------------------------------
-- ACTUALIZAR CONTENIDO DEL BOLSO
-----------------------------------------------------
local function updateBagDisplay(contents, capacity)
    -- Limpiar items
    for _, child in ipairs(itemsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local totalValue = 0
    
    for i, item in ipairs(contents or {}) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, 0, 0, 35)
        itemFrame.BackgroundColor3 = Color3.fromRGB(50, 45, 40)
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = itemsScroll
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = itemFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.Name or "Item"
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "$" .. (item.Value or 0)
        valueLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 12
        valueLabel.Parent = itemFrame
        
        -- Botón tirar
        local dropBtn = Instance.new("TextButton")
        dropBtn.Size = UDim2.new(0, 50, 0, 25)
        dropBtn.Position = UDim2.new(1, -55, 0.5, -12)
        dropBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        dropBtn.Text = "Tirar"
        dropBtn.TextColor3 = Color3.new(1, 1, 1)
        dropBtn.Font = Enum.Font.Gotham
        dropBtn.TextSize = 10
        dropBtn.BorderSizePixel = 0
        dropBtn.Parent = itemFrame
        
        local dropCorner = Instance.new("UICorner")
        dropCorner.CornerRadius = UDim.new(0, 4)
        dropCorner.Parent = dropBtn
        
        dropBtn.MouseButton1Click:Connect(function()
            local updateBagEvent = RemoteEvents.GetEvent("UpdateBag")
            if updateBagEvent then
                updateBagEvent:FireServer("Drop", { Index = i })
            end
        end)
        
        totalValue = totalValue + (item.Value or 0)
    end
    
    local count = contents and #contents or 0
    local cap = capacity or 5
    titleLabel.Text = "BOLSO DE ROBO (" .. count .. "/" .. cap .. ")"
    totalLabel.Text = "Valor Total: $" .. totalValue
    
    itemsScroll.CanvasSize = UDim2.new(0, 0, 0, itemsLayout.AbsoluteContentSize.Y + 10)
end

-----------------------------------------------------
-- TOGGLE CON TECLA B
-----------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.B then
        mainFrame.Visible = not mainFrame.Visible
        
        if mainFrame.Visible then
            -- Solicitar contenido actualizado
            local getBagFunc = RemoteEvents.GetFunction("GetBagContents")
            if getBagFunc then
                local bagData = getBagFunc:InvokeServer()
                if bagData then
                    updateBagDisplay(bagData.Contents, bagData.Capacity)
                end
            end
        end
    end
end)

-----------------------------------------------------
-- ESCUCHAR ACTUALIZACIONES
-----------------------------------------------------
task.wait(2)

local bagChangedEvent = RemoteEvents.GetEvent("BagContentsChanged")
if bagChangedEvent then
    bagChangedEvent.OnClientEvent:Connect(function(data)
        updateBagDisplay(data.Contents, data.Capacity)
    end)
end

print("[BagUI] Interfaz de bolso inicializada (Tecla B para abrir)")
