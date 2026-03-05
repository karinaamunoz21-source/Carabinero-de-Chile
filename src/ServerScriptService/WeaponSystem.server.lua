--[[
    WeaponSystem - Sistema de armas completo
    PD: Taser, Esposas
    SWAT: Colt M4, HK MP5, Rifle Francotirador, Ariete
    Criminal: C4
    Spawn Commands: /sg golden, /sg tambor, /sg arp christmas
]]

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("RemoteEvents"))
local DataManager = require(ReplicatedStorage:WaitForChild("DataManager"))

local WeaponSystem = {}

-----------------------------------------------------
-- CREAR TOOL DE ARMA
-----------------------------------------------------
local function createWeaponTool(weaponConfig)
    local tool = Instance.new("Tool")
    tool.Name = weaponConfig.Name
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    
    -- Handle (parte visual del arma)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.5, 0.5, 2)
    handle.BrickColor = BrickColor.new("Black")
    handle.Material = Enum.Material.Metal
    handle.Parent = tool
    
    -- Valores del arma
    local damageVal = Instance.new("NumberValue")
    damageVal.Name = "Damage"
    damageVal.Value = weaponConfig.Damage or 0
    damageVal.Parent = tool
    
    local typeVal = Instance.new("StringValue")
    typeVal.Name = "WeaponType"
    typeVal.Value = weaponConfig.Type or "Unknown"
    typeVal.Parent = tool
    
    if weaponConfig.FireRate then
        local fireRateVal = Instance.new("NumberValue")
        fireRateVal.Name = "FireRate"
        fireRateVal.Value = weaponConfig.FireRate
        fireRateVal.Parent = tool
    end
    
    if weaponConfig.MagSize then
        local magVal = Instance.new("IntValue")
        magVal.Name = "MagSize"
        magVal.Value = weaponConfig.MagSize
        magVal.Parent = tool
        
        local currentAmmo = Instance.new("IntValue")
        currentAmmo.Name = "CurrentAmmo"
        currentAmmo.Value = weaponConfig.MagSize
        currentAmmo.Parent = tool
    end
    
    if weaponConfig.Stun then
        local stunVal = Instance.new("NumberValue")
        stunVal.Name = "StunDuration"
        stunVal.Value = weaponConfig.Stun
        stunVal.Parent = tool
    end
    
    if weaponConfig.Radius then
        local radiusVal = Instance.new("NumberValue")
        radiusVal.Name = "ExplosionRadius"
        radiusVal.Value = weaponConfig.Radius
        radiusVal.Parent = tool
    end
    
    -- Script de activación del arma (dentro del tool)
    local weaponScript = Instance.new("Script")
    weaponScript.Name = "WeaponHandler"
    weaponScript.Source = [[
        local tool = script.Parent
        local weaponType = tool:FindFirstChild("WeaponType") and tool.WeaponType.Value or "Unknown"
        local damage = tool:FindFirstChild("Damage") and tool.Damage.Value or 0
        local fireRate = tool:FindFirstChild("FireRate") and tool.FireRate.Value or 0.5
        local magSize = tool:FindFirstChild("MagSize") and tool.MagSize.Value or 1
        local currentAmmo = tool:FindFirstChild("CurrentAmmo")
        local stunDuration = tool:FindFirstChild("StunDuration") and tool.StunDuration.Value or 0
        
        local player = nil
        local canFire = true
        local equipped = false
        
        tool.Equipped:Connect(function()
            equipped = true
            player = game.Players:GetPlayerFromCharacter(tool.Parent)
        end)
        
        tool.Unequipped:Connect(function()
            equipped = false
        end)
        
        tool.Activated:Connect(function()
            if not equipped or not canFire then return end
            if not player then return end
            
            canFire = false
            
            if weaponType == "Taser" then
                -- Disparo de taser - aturdir objetivo
                local character = tool.Parent
                local head = character and character:FindFirstChild("Head")
                if head then
                    local ray = Ray.new(head.Position, head.CFrame.LookVector * 50)
                    local hit, pos = workspace:FindPartOnRay(ray, character)
                    if hit then
                        local targetChar = hit.Parent
                        local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                        if targetHumanoid then
                            targetHumanoid.WalkSpeed = 0
                            targetHumanoid.JumpPower = 0
                            task.delay(stunDuration, function()
                                if targetHumanoid and targetHumanoid.Parent then
                                    targetHumanoid.WalkSpeed = 16
                                    targetHumanoid.JumpPower = 50
                                end
                            end)
                        end
                    end
                end
                
            elseif weaponType == "Cuffs" then
                -- Esposas - arrestar jugador
                local character = tool.Parent
                local head = character and character:FindFirstChild("Head")
                if head then
                    local ray = Ray.new(head.Position, head.CFrame.LookVector * 8)
                    local hit, pos = workspace:FindPartOnRay(ray, character)
                    if hit then
                        local targetChar = hit.Parent
                        local targetPlayer = game.Players:GetPlayerFromCharacter(targetChar)
                        if targetPlayer then
                            local ReplicatedStorage = game:GetService("ReplicatedStorage")
                            local events = ReplicatedStorage:FindFirstChild("RemoteEvents")
                            if events then
                                local sendToPrison = events:FindFirstChild("SendToPrison")
                                if sendToPrison then
                                    sendToPrison:FireServer(targetPlayer.UserId)
                                end
                            end
                        end
                    end
                end
                
            elseif weaponType == "Explosive" then
                -- C4 - explosión
                local character = tool.Parent
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local explosion = Instance.new("Explosion")
                    explosion.Position = rootPart.Position + rootPart.CFrame.LookVector * 10
                    explosion.BlastRadius = tool:FindFirstChild("ExplosionRadius") and tool.ExplosionRadius.Value or 20
                    explosion.BlastPressure = 500000
                    explosion.Parent = workspace
                end
                
                -- Destruir C4 después de usar
                tool:Destroy()
                
            elseif weaponType == "Battering Ram" then
                -- Ariete - destruir puertas
                local character = tool.Parent
                local head = character and character:FindFirstChild("Head")
                if head then
                    local ray = Ray.new(head.Position, head.CFrame.LookVector * 8)
                    local hit, pos = workspace:FindPartOnRay(ray, character)
                    if hit and (hit.Name == "Door" or hit.Name == "BreakableDoor" or hit:GetAttribute("Breakable")) then
                        hit:Destroy()
                    end
                end
                
            else
                -- Armas de fuego estándar
                if currentAmmo and currentAmmo.Value <= 0 then
                    -- Recargar
                    task.wait(2)
                    if currentAmmo then
                        currentAmmo.Value = magSize
                    end
                else
                    if currentAmmo then
                        currentAmmo.Value = currentAmmo.Value - 1
                    end
                    
                    local character = tool.Parent
                    local head = character and character:FindFirstChild("Head")
                    if head then
                        local ray = Ray.new(head.Position, head.CFrame.LookVector * 300)
                        local hit, pos = workspace:FindPartOnRay(ray, character)
                        if hit then
                            local targetChar = hit.Parent
                            local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")
                            if targetHumanoid then
                                targetHumanoid:TakeDamage(damage)
                            end
                        end
                    end
                end
            end
            
            task.wait(fireRate)
            canFire = true
        end)
    ]]
    weaponScript.Parent = tool
    
    return tool
end

-----------------------------------------------------
-- DAR ARMAS SEGÚN EQUIPO
-----------------------------------------------------
local function giveTeamWeapons(player)
    local character = player.Character
    if not character then return end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    
    local teamName = player.Team and player.Team.Name or "Civil"
    
    -- Limpiar armas anteriores
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("WeaponType") then
            tool:Destroy()
        end
    end
    
    if teamName == "Policía" then
        -- Dar armas de PD
        for _, weaponConfig in ipairs(GameConfig.Weapons.PD) do
            local weapon = createWeaponTool(weaponConfig)
            weapon.Parent = backpack
        end
    elseif teamName == "SWAT" then
        -- Dar armas de PD + SWAT
        for _, weaponConfig in ipairs(GameConfig.Weapons.PD) do
            local weapon = createWeaponTool(weaponConfig)
            weapon.Parent = backpack
        end
        for _, weaponConfig in ipairs(GameConfig.Weapons.SWAT) do
            local weapon = createWeaponTool(weaponConfig)
            weapon.Parent = backpack
        end
    end
end

-----------------------------------------------------
-- EVENTO: DAR ARMA
-----------------------------------------------------
local giveWeaponEvent = RemoteEvents.GetEvent("GiveWeapon")
if giveWeaponEvent then
    giveWeaponEvent.OnServerEvent:Connect(function(player, weaponName)
        -- Verificar permisos según equipo
        giveTeamWeapons(player)
    end)
end

-----------------------------------------------------
-- CUANDO JUGADOR CAMBIA DE EQUIPO
-----------------------------------------------------
local teamChangedEvent = RemoteEvents.GetEvent("TeamChanged")
if teamChangedEvent then
    -- Al spawnearse
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(1) -- Esperar a que el personaje cargue
            giveTeamWeapons(player)
        end)
    end)
end

-----------------------------------------------------
-- SPAWN WEAPON COMMANDS (/sg)
-----------------------------------------------------
local weaponSpawnEvent = RemoteEvents.GetEvent("WeaponSpawnCommand")
if weaponSpawnEvent then
    weaponSpawnEvent.OnServerEvent:Connect(function(player, weaponKey)
        -- Verificar que tiene el pase de generar armas
        local data = DataManager.GetPlayerData(player)
        if not data then return end
        
        local hasPass = data.OwnedGamePasses["GENERAR_ARMAS"]
        if not hasPass then
            -- Verificar en tiempo real
            local passId = GameConfig.GamePasses.GENERAR_ARMAS
            if passId > 0 then
                local success, owns = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
                end)
                if success and owns then
                    data.OwnedGamePasses["GENERAR_ARMAS"] = true
                    hasPass = true
                end
            end
        end
        
        if not hasPass then
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Pase Requerido",
                Text = "Necesitas el Pase de Generar Armas para usar /sg",
                Duration = 5,
                Type = "Error",
            })
            return
        end
        
        -- Buscar arma en la configuración
        local weaponConfig = GameConfig.Weapons.SPAWN_COMMANDS[string.lower(weaponKey)]
        if weaponConfig then
            local weapon = createWeaponTool(weaponConfig)
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                weapon.Parent = backpack
                
                RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                    Title = "Arma Generada",
                    Text = "Se generó: " .. weaponConfig.Name,
                    Duration = 5,
                    Type = "Success",
                })
            end
        else
            RemoteEvents.GetEvent("ShowNotification"):FireClient(player, {
                Title = "Error",
                Text = "Arma no encontrada: " .. tostring(weaponKey),
                Duration = 5,
                Type = "Error",
            })
        end
    end)
end

print("[WeaponSystem] Sistema de armas inicializado")
