--[[
    ShopSystem - Sistema completo de tiendas
    Incluye: Ropa, Zapatos, Pantalón, Accesorios, Joyería, Banco, 
    Mercado Negro, Tatuajes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local ShopSystem = {}

-----------------------------------------------------
-- MAPEO DE CATEGORÍA A CLAVE DE INVENTARIO
-----------------------------------------------------
local categoryToInventoryKey = {
    Top = "OwnedClothes",
    Shoes = "OwnedShoes",
    Pants = "OwnedPants",
    Hat = "OwnedAccessories",
    Face = "OwnedAccessories",
    Neck = "OwnedAccessories",
    Back = "OwnedAccessories",
}

-----------------------------------------------------
-- COMPRAR ITEM DE TIENDA
-----------------------------------------------------
local function purchaseItem(player, shopKey, itemName)
    local shopConfig = GameConfig.Shops[shopKey]
    if not shopConfig then
        return false, "Tienda no encontrada"
    end
    
    local data = DataManager.GetPlayerData(player)
    if not data then
        return false, "Error de datos"
    end
    
    -- Buscar el item en la tienda
    local itemConfig = nil
    for _, item in ipairs(shopConfig.Items or {}) do
        if item.Name == itemName then
            itemConfig = item
            break
        end
    end
    
    if not itemConfig then
        return false, "Artículo no encontrado"
    end
    
    -- Verificar dinero
    local success, remainingCash = DataManager.RemoveCash(player, itemConfig.Price)
    if not success then
        return false, "No tienes suficiente dinero. Necesitas $" .. itemConfig.Price
    end
    
    -- Agregar al inventario según categoría
    if shopKey == "MERCADO_NEGRO" then
        -- Items del mercado negro van al inventario general
        table.insert(data.Inventory, itemName)
    elseif shopKey == "TATUAJES" then
        -- Tatuajes se aplican directamente
        local zone = itemConfig.Zone
        if zone then
            DataManager.AddTattoo(player, zone, itemName)
        end
    else
        -- Ropa, zapatos, accesorios, etc.
        local category = itemConfig.Category
        local inventoryKey = categoryToInventoryKey[category]
        if inventoryKey and data[inventoryKey] then
            table.insert(data[inventoryKey], itemName)
        else
            table.insert(data.Inventory, itemName)
        end
    end
    
    -- Actualizar leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        leaderstats.Dinero.Value = data.Cash
    end
    
    return true, "¡Compraste " .. itemName .. "! Dinero restante: $" .. data.Cash
end

-----------------------------------------------------
-- EVENTO DE COMPRA
-----------------------------------------------------
local purchaseEvent = RemoteEvents.GetEvent("PurchaseItem")
if purchaseEvent then
    purchaseEvent.OnServerEvent:Connect(function(player, shopKey, itemName)
        local success, message = purchaseItem(player, shopKey, itemName)
        
        local resultEvent = RemoteEvents.GetEvent("PurchaseResult")
        if resultEvent then
            resultEvent:FireClient(player, {
                Success = success,
                Message = message,
                ShopKey = shopKey,
                ItemName = itemName,
            })
        end
    end)
end

-----------------------------------------------------
-- GET SHOP ITEMS (RemoteFunction)
-----------------------------------------------------
local getShopItemsFunc = RemoteEvents.GetFunction("GetShopItems")
if getShopItemsFunc then
    getShopItemsFunc.OnServerInvoke = function(player, shopKey)
        local shopConfig = GameConfig.Shops[shopKey]
        if shopConfig then
            return {
                Name = shopConfig.Name,
                Items = shopConfig.Items or {},
                Robbable = shopConfig.Robbable or false,
            }
        end
        return nil
    end
end

-----------------------------------------------------
-- APLICAR TATUAJE
-----------------------------------------------------
local applyTattooEvent = RemoteEvents.GetEvent("ApplyTattoo")
if applyTattooEvent then
    applyTattooEvent.OnServerEvent:Connect(function(player, tattooName, zone)
        local data = DataManager.GetPlayerData(player)
        if not data then return end
        
        -- Verificar que tiene el tatuaje comprado
        local hasTattoo = false
        if data.Tattoos[zone] then
            for _, t in ipairs(data.Tattoos[zone]) do
                if t == tattooName then
                    hasTattoo = true
                    break
                end
            end
        end
        
        if hasTattoo then
            -- Aplicar tatuaje visual (decal en el personaje)
            local character = player.Character
            if character then
                local head = character:FindFirstChild("Head")
                local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
                local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
                
                if zone == "Face" and head then
                    local decal = Instance.new("Decal")
                    decal.Name = "Tattoo_" .. tattooName
                    decal.Face = Enum.NormalId.Front
                    -- decal.Texture = "rbxassetid://0" -- Cambiar por textura real
                    decal.Parent = head
                elseif zone == "Hand" then
                    for _, hand in ipairs({leftHand, rightHand}) do
                        if hand then
                            local decal = Instance.new("Decal")
                            decal.Name = "Tattoo_" .. tattooName
                            decal.Face = Enum.NormalId.Top
                            -- decal.Texture = "rbxassetid://0" -- Cambiar por textura real
                            decal.Parent = hand
                        end
                    end
                end
            end
            
            RemoteEvents.GetEvent("TattooApplied"):FireClient(player, {
                Success = true,
                TattooName = tattooName,
                Zone = zone,
            })
        else
            RemoteEvents.GetEvent("TattooApplied"):FireClient(player, {
                Success = false,
                Message = "No tienes este tatuaje comprado",
            })
        end
    end)
end

-----------------------------------------------------
-- USAR CASILLERO DE BASE
-----------------------------------------------------
local useLockerEvent = RemoteEvents.GetEvent("UseLocker")
if useLockerEvent then
    useLockerEvent.OnServerEvent:Connect(function(player, action, itemName)
        local data = DataManager.GetPlayerData(player)
        if not data then return end
        
        if action == "Store" then
            -- Guardar item en casillero
            if not data.Locker then
                data.Locker = {}
            end
            
            -- Buscar y remover del inventario
            for i, item in ipairs(data.Inventory) do
                if item == itemName then
                    table.remove(data.Inventory, i)
                    table.insert(data.Locker, itemName)
                    break
                end
            end
        elseif action == "Retrieve" then
            -- Sacar item del casillero
            if data.Locker then
                for i, item in ipairs(data.Locker) do
                    if item == itemName then
                        table.remove(data.Locker, i)
                        table.insert(data.Inventory, itemName)
                        break
                    end
                end
            end
        end
    end)
end

-----------------------------------------------------
-- USAR BOLSO DE ROPA DE BASE
-----------------------------------------------------
local useClothingBagEvent = RemoteEvents.GetEvent("UseClothingBag")
if useClothingBagEvent then
    useClothingBagEvent.OnServerEvent:Connect(function(player, action, clothingName)
        local data = DataManager.GetPlayerData(player)
        if not data then return end
        
        if action == "Equip" then
            -- Equipar ropa (se implementaría con el sistema de personajes)
            data.EquippedClothing = data.EquippedClothing or {}
            data.EquippedClothing[clothingName] = true
        elseif action == "Unequip" then
            if data.EquippedClothing then
                data.EquippedClothing[clothingName] = nil
            end
        end
    end)
end

print("[ShopSystem] Sistema de tiendas inicializado")
