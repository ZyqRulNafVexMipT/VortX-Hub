-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
-- VORTEX HUB V2.9 | ULTIMATE EDITION
-- ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/1nig1htmare1234/SCRIPTS/main/Orion.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Window
local Window = OrionLib:MakeWindow({
    Name = "VortX Hub V2.9 | Hypershot Ultimate",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "Vortex_Configs",
    Theme = "Nightmare"
})

-- Tabs
local CombatTab = Window:MakeTab({Name = "Combat"})
local ESPTab = Window:MakeTab({Name = "ESP"})
local UtilityTab = Window:MakeTab({Name = "Utilities"})
local OpenTab = Window:MakeTab({Name = "Open"})
local GunModsTab = Window:MakeTab({Name = "Gun Mods"})

-- Global Flags
getgenv().SilentAimEnabled = false
getgenv().WallbangEnabled = false
getgenv().InfiniteAmmo = false
getgenv().AntiDetection = false
getgenv().BringPlayersEnabled = false
getgenv().teleportDistance = 5
getgenv().FOV = 180
getgenv().AutoJump = false
getgenv().NoClip = false
getgenv().AntiRecoil = false
getgenv().AutoSpawn = false
getgenv().AutoFarm = false
getgenv().AutoOpenChest = false
getgenv().AutoSpinWheel = false
getgenv().AutoCollectAwards = false
getgenv().RapidFire = false
getgenv().HitboxExpander = false
getgenv().KillAura = false
getgenv().NoCooldown = false
getgenv().BigHead = false
getgenv().Spectating = false
getgenv().SkeletonESP = false

-- Constants
local Gravity = workspace.Gravity
local BulletSpeed = 4500

-- ESP Configuration
local ESP_Config = {
    Enabled = false,
    Thickness = 1.5,
    Color = Color3.fromRGB(255, 0, 0),
    Transparency = 0.75,
    TeamCheck = false
}

local Drawings = {}

-- Helpers
local function root(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function head(char) return char and char:FindFirstChild("Head") end

-- ESP Box
local function CreateESPBox(player)
    if not player.Character or not root(player.Character) then return end
    local espBox = Drawing.new("Square")
    espBox.Visible = false
    espBox.Thickness = ESP_Config.Thickness
    espBox.Color = ESP_Config.Color
    espBox.Transparency = ESP_Config.Transparency
    espBox.Filled = false

    local espName = Drawing.new("Text")
    espName.Visible = false
    espName.Color = ESP_Config.Color
    espName.Outline = true
    espName.OutlineColor = Color3.new(0, 0, 0)
    espName.Font = 2
    espName.TextSize = 14

    table.insert(Drawings, {espBox, espName, player})

    RunService.Heartbeat:Connect(function()
        if not ESP_Config.Enabled or not root(player.Character) then
            espBox.Visible = false
            espName.Visible = false
            return
        end
        if ESP_Config.TeamCheck and player.Team == LocalPlayer.Team then
            espBox.Visible = false
            espName.Visible = false
            return
        end
        local Vector, onScreen = Camera:WorldToViewportPoint(root(player.Character).Position)
        if onScreen then
            local Size = Vector2.new(150, 300)
            espBox.Size = Size
            espBox.Position = Vector2.new(Vector.X - Size.X / 2, Vector.Y - Size.Y / 2)
            espBox.Visible = true
            espName.Position = Vector2.new(Vector.X, Vector.Y - 30)
            espName.Text = player.Name
            espName.Visible = true
        else
            espBox.Visible = false
            espName.Visible = false
        end
    end)
end

-- ESP Skeleton
local function CreateSkeletonESP()
    RunService.Heartbeat:Connect(function()
        if not getgenv().SkeletonESP then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                -- Placeholder for full skeleton
                -- You can expand this later
            end
        end
    end)
end

-- ESP Toggle
local function ToggleESP(v)
    ESP_Config.Enabled = v
    for _, drawing in ipairs(Drawings) do
        drawing[1].Visible = v and drawing[3].Character and root(drawing[3].Character) and (not ESP_Config.TeamCheck or drawing[3].Team ~= LocalPlayer.Team)
        drawing[2].Visible = v and drawing[3].Character and root(drawing[3].Character) and (not ESP_Config.TeamCheck or drawing[3].Team ~= LocalPlayer.Team)
    end
end

-- Bring Players
RunService.RenderStepped:Connect(function()
    if not getgenv().BringPlayersEnabled then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local targetPos = root.Position + root.CFrame.LookVector * getgenv().teleportDistance
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Root = Player.Character:FindFirstChild("HumanoidRootPart")
            if Root then
                Root.CFrame = CFrame.new(targetPos + Vector3.new(math.random(-2,2), 0, math.random(-2,2)))
            end
        end
    end
end)

-- Anti-Cheat Bypass
local function AntiCheatBypass()
    local oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if key == "Velocity" and self.Name == "HumanoidRootPart" then
            return Vector3.new(0, 0.1, 0)
        end
        return oldIndex(self, key)
    end))
end

-- Spectate
local function SpectatePlayer(target)
    if target and target.Character then
        workspace.CurrentCamera.CameraSubject = target.Character:FindFirstChild("Humanoid")
        workspace.CurrentCamera.CameraType = Enum.CameraType.Follow
        getgenv().Spectating = target
    else
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        getgenv().Spectating = false
    end
end

-- Auto Pickup (Coins, Heals, Ammo, Weapons)
local function startAutoPickUpCoins()
    getgenv().AutoPickupCoins = true
    task.spawn(function()
        while getgenv().AutoPickupCoins do
            local coinsFolder = Workspace:FindFirstChild("IgnoreThese") and Workspace.IgnoreThese:FindFirstChild("Pickups") and Workspace.IgnoreThese.Pickups:FindFirstChild("Loot")
            if coinsFolder then
                for _, coin in ipairs(coinsFolder:GetChildren()) do
                    if coin:IsA("BasePart") then
                        coin.CFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame or coin.CFrame
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function startAutoPickUpHeal()
    getgenv().AutoPickupHeal = true
    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("PickUpHeal", 9e9)
        local healsFolder = Workspace:WaitForChild("IgnoreThese", 9e9):WaitForChild("Pickups", 9e9):WaitForChild("Heals", 9e9)
        while getgenv().AutoPickupHeal do
            for _, heal in ipairs(healsFolder:GetChildren()) do
                network:FireServer(heal)
            end
            task.wait(0.3)
        end
    end)
end

local function startAutoPickUpAmmo()
    getgenv().AutoPickupAmmo = true
    task.spawn(function()
        local network = ReplicatedStorage:WaitForChild("Network", 9e9):WaitForChild("Remotes", 9e9):WaitForChild("PickUpAmmo", 9e9)
        local ammoFolder = Workspace:WaitForChild("IgnoreThese", 9e9):WaitForChild("Pickups", 9e9):WaitForChild("Ammo", 9e9)
        while getgenv().AutoPickupAmmo do
            for _, ammo in ipairs(ammoFolder:GetChildren()) do
                network:FireServer(ammo)
            end
            task.wait(0.3)
        end
    end)
end

local function startAutoPickUpWeapons()
    getgenv().AutoPickupWeapons = true
    task.spawn(function()
        while getgenv().AutoPickupWeapons do
            local weaponsFolder = Workspace:FindFirstChild("IgnoreThese") and Workspace.IgnoreThese:FindFirstChild("Pickups") and Workspace.IgnoreThese.Pickups:FindFirstChild("Weapons")
            if weaponsFolder then
                for _, weapon in ipairs(weaponsFolder:GetChildren()) do
                    if weapon:IsA("Model") or weapon:IsA("Part") then
                        weapon.CFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame or weapon.CFrame
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

-- Auto Open Chest
local function startAutoOpenChest()
    getgenv().AutoOpenChest = true
    task.spawn(function()
        while getgenv().AutoOpenChest do
            local args = { [1] = "Wooden", [2] = "Random" }
            ReplicatedStorage:WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("OpenCase"):InvokeServer(unpack(args))
            task.wait(5)
        end
    end)
end

-- Auto Spin Wheel
local function startAutoSpin()
    getgenv().AutoSpinWheel = true
    task.spawn(function()
        while getgenv().AutoSpinWheel do
            ReplicatedStorage:WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("SpinWheel"):InvokeServer()
            task.wait(5)
        end
    end)
end

-- Auto Playtime
local function startAutoPlaytime()
    getgenv().AutoPlaytime = true
    task.spawn(function()
        while getgenv().AutoPlaytime do
            for i = 1, 12 do
                ReplicatedStorage:WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("ClaimPlaytimeReward"):FireServer(i)
                task.wait(1)
            end
            task.wait(15)
        end
    end)
end

-- No Clip
RunService.Heartbeat:Connect(function()
    if not getgenv().NoClip or not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- Infinite Ammo
RunService.Heartbeat:Connect(function()
    if not getgenv().InfiniteAmmo then return end
    local function scan(container)
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                for _, child in ipairs(tool:GetDescendants()) do
                    if child:IsA("NumberValue") and (child.Name:lower() == "ammo" or child.Name:lower() == "clip") then
                        child.Value = 9999
                    end
                end
            end
        end
    end
    scan(LocalPlayer.Backpack)
    scan(LocalPlayer.Character or {})
end)

-- Big Head
RunService.Heartbeat:Connect(function()
    if not getgenv().BigHead then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                head.Size = Vector3.new(4, 4, 4)
                head.Transparency = 0.7
            end
        end
    end
end)

-- Hitbox Expander
RunService.Heartbeat:Connect(function()
    if not getgenv().HitboxExpander then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                head.Size = Vector3.new(8, 8, 8)
            end
        end
    end
end)

-- Kill Aura
RunService.Heartbeat:Connect(function()
    if not getgenv().KillAura then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 20) then
                if ReplicatedStorage:FindFirstChild("Shoot") then
                    ReplicatedStorage.Shoot:FireServer()
                end
            end
        end
    end
end)

-- UI Toggles
CombatTab:AddToggle({ Name = "Silent Aimbot", Default = false, Callback = function(v) getgenv().SilentAimEnabled = v end })
CombatTab:AddToggle({ Name = "Wallbang", Default = false, Callback = function(v) getgenv().WallbangEnabled = v end })
CombatTab:AddToggle({ Name = "Bring All Players", Default = false, Callback = function(v) getgenv().BringPlayersEnabled = v end })
CombatTab:AddSlider({ Name = "Bring Distance", Min = 1, Max = 50, Default = 5, ValueName = "Studs", Callback = function(v) getgenv().teleportDistance = v end })
CombatTab:AddToggle({ Name = "Infinite Ammo", Default = false, Callback = function(v) getgenv().InfiniteAmmo = v end })
CombatTab:AddToggle({ Name = "Anti-Cheat Bypass", Default = false, Callback = function(v) if v then AntiCheatBypass() end end })
CombatTab:AddToggle({ Name = "Big Head", Default = false, Callback = function(v) getgenv().BigHead = v end })
CombatTab:AddToggle({ Name = "Hitbox Expander", Default = false, Callback = function(v) getgenv().HitboxExpander = v end })
CombatTab:AddToggle({ Name = "Kill Aura", Default = false, Callback = function(v) getgenv().KillAura = v end })
CombatTab:AddToggle({ Name = "No Cooldown", Default = false, Callback = function(v) getgenv().NoCooldown = v end })

ESPTab:AddToggle({ Name = "Enable ESP", Default = false, Callback = ToggleESP })
ESPTab:AddToggle({ Name = "ESP Skeleton", Default = false, Callback = function(v) getgenv().SkeletonESP = v end })
ESPTab:AddSlider({ Name = "ESP Thickness", Min = 0.5, Max = 5, Default = 1.5, ValueName = "px", Callback = function(v) ESP_Config.Thickness = v end })
ESPTab:AddColorpicker({ Name = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Callback = function(v) ESP_Config.Color = v end })
ESPTab:AddSlider({ Name = "ESP Transparency", Min = 0, Max = 1, Default = 0.75, ValueName = "Transparency", Callback = function(v) ESP_Config.Transparency = v end })
ESPTab:AddToggle({ Name = "Team Check", Default = false, Callback = function(v) ESP_Config.TeamCheck = v end })

UtilityTab:AddToggle({ Name = "Auto Pickup Coins", Default = false, Callback = function(v) v and startAutoPickUpCoins() or (getgenv().AutoPickupCoins = false) end })
UtilityTab:AddToggle({ Name = "Auto Pickup Heals", Default = false, Callback = function(v) v and startAutoPickUpHeal() or (getgenv().AutoPickupHeal = false) end })
UtilityTab:AddToggle({ Name = "Auto Pickup Ammo", Default = false, Callback = function(v) v and startAutoPickUpAmmo() or (getgenv().AutoPickupAmmo = false) end })
UtilityTab:AddToggle({ Name = "Auto Pickup Weapons", Default = false, Callback = function(v) v and startAutoPickUpWeapons() or (getgenv().AutoPickupWeapons = false) end })
UtilityTab:AddToggle({ Name = "No Clip", Default = false, Callback = function(v) getgenv().NoClip = v end })
UtilityTab:AddToggle({ Name = "Auto Jump", Default = false, Callback = function(v) getgenv().AutoJump = v end })

OpenTab:AddToggle({ Name = "Auto Open Chest", Default = false, Callback = function(v) v and startAutoOpenChest() or (getgenv().AutoOpenChest = false) end })
OpenTab:AddToggle({ Name = "Auto Spin Wheel", Default = false, Callback = function(v) v and startAutoSpin() or (getgenv().AutoSpinWheel = false) end })
OpenTab:AddToggle({ Name = "Auto Collect Playtime", Default = false, Callback = function(v) v and startAutoPlaytime() or (getgenv().AutoPlaytime = false) end })

-- Spectate Dropdown
local spectateOptions = {"None"}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(spectateOptions, p.Name)
    end
end

local spectateDropdown = CombatTab:AddDropdown({
    Name = "Spectate Player",
    Default = "None",
    Options = spectateOptions,
    Callback = function(name)
        if name == "None" then
            SpectatePlayer(nil)
        else
            SpectatePlayer(Players:FindFirstChild(name))
        end
    end
})

-- Auto Jump
Mouse.KeyDown:Connect(function(k)
    if k == " " and getgenv().AutoJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Jump = true
    end
end)

-- Create ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPBox(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    CreateESPBox(player)
    spectateDropdown:Refresh({"None", unpack(Players:GetPlayers())}, true)
end)

Players.PlayerRemoving:Connect(function(player)
    for i, drawing in ipairs(Drawings) do
        if drawing[3] == player then
            table.remove(Drawings, i)
            drawing[1]:Remove()
            drawing[2]:Remove()
            break
        end
    end
    spectateDropdown:Refresh({"None", unpack(Players:GetPlayers())}, true)
end)

OrionLib:MakeNotification({
    Name = "VortX Hub V2.9",
    Content = "All features loaded successfully!",
    Time = 5
})

OrionLib:Init()
