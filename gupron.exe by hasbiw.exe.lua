-- ============================================================
--  ██████╗ ██╗   ██╗██████╗ ██████╗  ██████╗ ███╗   ██╗.exe
--  ██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔═══██╗████╗  ██║
--  ██║  ███╗██║   ██║██████╔╝██████╔╝██║   ██║██╔██╗ ██║
--  ██║   ██║██║   ██║██╔═══╝ ██╔══██╗██║   ██║██║╚██╗██║
--  ╚██████╔╝╚██████╔╝██║     ██║  ██║╚██████╔╝██║ ╚████║
--   ╚═════╝  ╚═════╝ ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
--  
--  SOUTH BRONX: THE TRENCHES - PREMIUM EDITION
--  Created by: GUPRON.EXE
--  Access Code: HASBIW.EXE ONTOP
--  Version: 4.0 | Full Functional Release
-- ============================================================

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Theme
local Theme = {
    Background = Color3.fromRGB(12, 12, 18),
    BackgroundLight = Color3.fromRGB(18, 18, 28),
    BackgroundDark = Color3.fromRGB(8, 8, 12),
    Primary = Color3.fromRGB(147, 51, 255),
    PrimaryLight = Color3.fromRGB(180, 100, 255),
    PrimaryDark = Color3.fromRGB(100, 30, 200),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(0, 255, 150),
    Error = Color3.fromRGB(255, 50, 50),
    Warning = Color3.fromRGB(255, 193, 7)
}

-- Settings
local Settings = {
    Aimbot = {
        Enabled = false,
        TeamCheck = true,
        WallCheck = true,
        ShowFOV = true,
        FOV = 150,
        Smoothness = 8,
        Prediction = 0.165,
        TargetPart = "Head"
    },
    Triggerbot = {
        Enabled = false,
        TeamCheck = true,
        WallCheck = true,
        Delay = 50,
        Humanization = 0
    },
    ESP = {
        Enabled = false,
        TeamCheck = true,
        Boxes = true,
        BoxFilled = false,
        Names = true,
        Distance = true,
        Health = true,
        HealthBar = true,
        Tracers = false,
        Skeleton = false,
        TeamColor = false
    },
    AutoFarm = {
        Enabled = false,
        Type = "Money",
        Speed = 50,
        AutoShoot = false
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 50
    },
    Gun = {
        NoRecoil = false,
        NoSpread = false,
        InstantReload = false,
        RapidFire = false,
        InfiniteAmmo = false,
        DamageMultiplier = 1
    },
    Misc = {
        AutoLoot = false,
        AutoSell = false,
        AntiAim = false,
        Spinbot = false
    }
}

-- Variables
local ESPObjects = {}
local Connections = {}
local DrawingObjects = {}
local ActiveLoops = {}
local GUIVisible = true
local CurrentTab = nil
local FlyBodyGyro = nil
local FlyBodyVelocity = nil
local NoclipConnection = nil
local AimbotTarget = nil
local TriggerbotTarget = nil
local LastShot = 0

-- Utility Functions
local function CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    table.insert(DrawingObjects, drawing)
    return drawing
end

local function Tween(obj, properties, duration, easing, direction)
    local tween = TweenService:Create(obj, TweenInfo.new(
        duration or 0.3,
        easing or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    ), properties)
    tween:Play()
    return tween
end

local function Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

local function CreateLoop(name, callback)
    if ActiveLoops[name] then
        ActiveLoops[name]:Disconnect()
    end
    ActiveLoops[name] = RunService.RenderStepped:Connect(callback)
    table.insert(Connections, ActiveLoops[name])
    return ActiveLoops[name]
end

local function StopLoop(name)
    if ActiveLoops[name] then
        ActiveLoops[name]:Disconnect()
        ActiveLoops[name] = nil
    end
end

local function GetCharacter(player)
    return player and player.Character
end

local function GetRoot(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("Humanoid")
end

local function GetHead(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("Head")
end

local function IsAlive(player)
    local humanoid = GetHumanoid(player)
    return humanoid and humanoid.Health > 0
end

local function IsTeammate(player)
    if not Settings.Aimbot.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

local function RaycastVisible(origin, target, ignoreList)
    if not Settings.Aimbot.WallCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignoreList or {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin, (target - origin).Unit * (target - origin).Magnitude, raycastParams)
    return result == nil
end

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "GUPRON.EXE",
            Text = text or "",
            Duration = duration or 3
        })
    end)
end

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GUPRON_EXE_FULL"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Access GUI
local AccessFrame = Instance.new("Frame")
AccessFrame.Name = "AccessGUI"
AccessFrame.Size = UDim2.new(0, 450, 0, 280)
AccessFrame.Position = UDim2.new(0.5, -225, 0.5, -140)
AccessFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
AccessFrame.BorderSizePixel = 0
AccessFrame.ClipsDescendants = true
AccessFrame.Parent = ScreenGui

local AccessCorner = Instance.new("UICorner")
AccessCorner.CornerRadius = UDim.new(0, 15)
AccessCorner.Parent = AccessFrame

local AccessStroke = Instance.new("UIStroke")
AccessStroke.Color = Theme.Primary
AccessStroke.Thickness = 2
AccessStroke.Parent = AccessFrame

local AccessGradient = Instance.new("UIGradient")
AccessGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 10, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 5, 12))
})
AccessGradient.Rotation = 135
AccessGradient.Parent = AccessFrame

-- Access Glow
local AccessGlow = Instance.new("ImageLabel")
AccessGlow.Size = UDim2.new(1, 60, 1, 60)
AccessGlow.Position = UDim2.new(0, -30, 0, -30)
AccessGlow.BackgroundTransparency = 1
AccessGlow.Image = "rbxassetid://4996891970"
AccessGlow.ImageColor3 = Theme.Primary
AccessGlow.ImageTransparency = 0.9
AccessGlow.Parent = AccessFrame

-- Crown Icon
local CrownIcon = Instance.new("TextLabel")
CrownIcon.Size = UDim2.new(0, 50, 0, 50)
CrownIcon.Position = UDim2.new(0.5, -25, 0, 20)
CrownIcon.BackgroundTransparency = 1
CrownIcon.Text = "👑"
CrownIcon.TextSize = 40
CrownIcon.Parent = AccessFrame

-- Access Title
local AccessTitle = Instance.new("TextLabel")
AccessTitle.Size = UDim2.new(1, 0, 0, 40)
AccessTitle.Position = UDim2.new(0, 0, 0, 70)
AccessTitle.BackgroundTransparency = 1
AccessTitle.Text = "GUPRON.EXE"
AccessTitle.TextColor3 = Theme.Primary
AccessTitle.TextSize = 36
AccessTitle.Font = Enum.Font.GothamBlack
AccessTitle.Parent = AccessFrame

-- Access Subtitle
local AccessSub = Instance.new("TextLabel")
AccessSub.Size = UDim2.new(1, 0, 0, 25)
AccessSub.Position = UDim2.new(0, 0, 0, 110)
AccessSub.BackgroundTransparency = 1
AccessSub.Text = "SOUTH BRONX PREMIUM"
AccessSub.TextColor3 = Theme.TextDim
AccessSub.TextSize = 14
AccessSub.Font = Enum.Font.GothamBold
AccessSub.Parent = AccessFrame

-- Code Input
local CodeInput = Instance.new("TextBox")
CodeInput.Size = UDim2.new(0, 350, 0, 45)
CodeInput.Position = UDim2.new(0.5, -175, 0, 150)
CodeInput.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
CodeInput.BorderSizePixel = 0
CodeInput.Text = ""
CodeInput.PlaceholderText = "ENTER ACCESS CODE..."
CodeInput.TextColor3 = Theme.Text
CodeInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
CodeInput.TextSize = 14
CodeInput.Font = Enum.Font.GothamBold
CodeInput.ClearTextOnFocus = false
CodeInput.Parent = AccessFrame

local CodeCorner = Instance.new("UICorner")
CodeCorner.CornerRadius = UDim.new(0, 10)
CodeCorner.Parent = CodeInput

local CodeStroke = Instance.new("UIStroke")
CodeStroke.Color = Theme.PrimaryDark
CodeStroke.Thickness = 1.5
CodeStroke.Parent = CodeInput

-- Verify Button
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(0, 350, 0, 45)
VerifyBtn.Position = UDim2.new(0.5, -175, 0, 210)
VerifyBtn.BackgroundColor3 = Theme.Primary
VerifyBtn.BorderSizePixel = 0
VerifyBtn.Text = "VERIFY ACCESS"
VerifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
VerifyBtn.TextSize = 16
VerifyBtn.Font = Enum.Font.GothamBlack
VerifyBtn.Parent = AccessFrame

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 10)
VerifyCorner.Parent = VerifyBtn

-- Error Label
local ErrorLabel = Instance.new("TextLabel")
ErrorLabel.Size = UDim2.new(1, 0, 0, 20)
ErrorLabel.Position = UDim2.new(0, 0, 0, 260)
ErrorLabel.BackgroundTransparency = 1
ErrorLabel.Text = ""
ErrorLabel.TextColor3 = Theme.Error
ErrorLabel.TextSize = 12
ErrorLabel.Font = Enum.Font.GothamBold
ErrorLabel.Parent = AccessFrame

-- Main GUI (Hidden initially)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainGUI"
MainFrame.Size = UDim2.new(0, 650, 0, 450)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 12, 28)),
    ColorSequenceKeypoint.new(0.5, Theme.Background),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 12))
})
MainGradient.Rotation = 135
MainGradient.Parent = MainFrame

-- Main Glow
local MainGlow = Instance.new("ImageLabel")
MainGlow.Size = UDim2.new(1, 80, 1, 80)
MainGlow.Position = UDim2.new(0, -40, 0, -40)
MainGlow.BackgroundTransparency = 1
MainGlow.Image = "rbxassetid://4996891970"
MainGlow.ImageColor3 = Theme.Primary
MainGlow.ImageTransparency = 0.95
MainGlow.ZIndex = -1
MainGlow.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 20)
TopBarCorner.Parent = TopBar

local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 25)
TopBarFix.Position = UDim2.new(0, 0, 0.5, 0)
TopBarFix.BackgroundColor3 = TopBar.BackgroundColor3
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

-- Crown Icon Main
local MainCrown = Instance.new("TextLabel")
MainCrown.Size = UDim2.new(0, 30, 0, 50)
MainCrown.Position = UDim2.new(0, 15, 0, 0)
MainCrown.BackgroundTransparency = 1
MainCrown.Text = "👑"
MainCrown.TextSize = 24
MainCrown.Parent = TopBar

-- Title
local MainTitle = Instance.new("TextLabel")
MainTitle.Size = UDim2.new(0, 200, 0, 50)
MainTitle.Position = UDim2.new(0, 45, 0, 0)
MainTitle.BackgroundTransparency = 1
MainTitle.Text = "GUPRON.EXE"
MainTitle.TextColor3 = Theme.Primary
MainTitle.TextSize = 22
MainTitle.Font = Enum.Font.GothamBlack
MainTitle.TextXAlignment = Enum.TextXAlignment.Left
MainTitle.Parent = TopBar

-- Subtitle
local MainSub = Instance.new("TextLabel")
MainSub.Size = UDim2.new(0, 150, 0, 50)
MainSub.Position = UDim2.new(0, 175, 0, 0)
MainSub.BackgroundTransparency = 1
MainSub.Text = "| SOUTH BRONX"
MainSub.TextColor3 = Theme.TextDim
MainSub.TextSize = 12
MainSub.Font = Enum.Font.GothamBold
MainSub.TextXAlignment = Enum.TextXAlignment.Left
MainSub.Parent = TopBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "Minimize"
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -75, 0, 10)
MinBtn.BackgroundColor3 = Theme.Warning
MinBtn.BorderSizePixel = 0
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextSize = 20
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 10)
CloseBtn.BackgroundColor3 = Theme.Error
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 140, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 0)
SidebarCorner.Parent = Sidebar

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 20, 1, 0)
SidebarFix.Position = UDim2.new(1, -20, 0, 0)
SidebarFix.BackgroundColor3 = Sidebar.BackgroundColor3
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -10, 1, -20)
TabContainer.Position = UDim2.new(0, 10, 0, 10)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabContainer

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "Content"
ContentArea.Size = UDim2.new(1, -150, 1, -60)
ContentArea.Position = UDim2.new(0, 145, 0, 55)
ContentArea.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 15)
ContentCorner.Parent = ContentArea

-- Credits
local Credits = Instance.new("TextLabel")
Credits.Size = UDim2.new(1, 0, 0, 20)
Credits.Position = UDim2.new(0, 0, 1, -25)
Credits.BackgroundTransparency = 1
Credits.Text = "⚡ MADE BY GUPRON.EXE | PREMIUM EDITION ⚡"
Credits.TextColor3 = Theme.Primary
Credits.TextSize = 10
Credits.Font = Enum.Font.GothamBold
Credits.Parent = MainFrame

-- FOV Circle
local FOVCircle = CreateDrawing("Circle", {
    Visible = false,
    Thickness = 1.5,
    Color = Theme.Primary,
    NumSides = 64,
    Radius = Settings.Aimbot.FOV,
    Filled = false,
    Transparency = 0.7
})

local FOVCircleOutline = CreateDrawing("Circle", {
    Visible = false,
    Thickness = 1,
    Color = Color3.new(0, 0, 0),
    NumSides = 64,
    Radius = Settings.Aimbot.FOV + 1,
    Filled = false,
    Transparency = 0.5
})

-- ESP System
local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        Box = CreateDrawing("Square", {
            Visible = false,
            Color = Theme.Primary,
            Thickness = 1.5,
            Filled = false,
            Transparency = 1,
            ZIndex = 2
        }),
        BoxOutline = CreateDrawing("Square", {
            Visible = false,
            Color = Color3.new(0, 0, 0),
            Thickness = 3,
            Filled = false,
            Transparency = 1,
            ZIndex = 1
        }),
        BoxFill = CreateDrawing("Square", {
            Visible = false,
            Color = Theme.Primary,
            Thickness = 1,
            Filled = true,
            Transparency = 0.2,
            ZIndex = 0
        }),
        Name = CreateDrawing("Text", {
            Visible = false,
            Color = Theme.Text,
            Size = 13,
            Center = true,
            Outline = true,
            Font = Drawing.Fonts.UI,
            Transparency = 1,
            ZIndex = 3
        }),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Color = Theme.TextDim,
            Size = 11,
            Center = true,
            Outline = true,
            Font = Drawing.Fonts.UI,
            Transparency = 1,
            ZIndex = 3
        }),
        HealthBar = CreateDrawing("Square", {
            Visible = false,
            Color = Theme.Success,
            Thickness = 1,
            Filled = true,
            Transparency = 1,
            ZIndex = 2
        }),
        HealthBarBg = CreateDrawing("Square", {
            Visible = false,
            Color = Color3.fromRGB(40, 40, 40),
            Thickness = 1,
            Filled = true,
            Transparency = 1,
            ZIndex = 1
        }),
        Tracer = CreateDrawing("Line", {
            Visible = false,
            Color = Theme.Primary,
            Thickness = 1.5,
            Transparency = 0.7,
            ZIndex = 1
        }),
        SkeletonLines = {}
    }
    
    for i = 1, #SkeletonConnections do
        esp.SkeletonLines[i] = CreateDrawing("Line", {
            Visible = false,
            Color = Theme.Primary,
            Thickness = 1,
            Transparency = 0.8,
            ZIndex = 2
        })
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    for player, esp in pairs(ESPObjects) do
        if not Settings.ESP.Enabled or not player.Parent then
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        local character = GetCharacter(player)
        if not character then
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = GetHumanoid(player)
        
        if not root or not head or not humanoid then
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        if humanoid.Health <= 0 then
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        if Settings.ESP.TeamCheck and IsTeammate(player) then
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            for key, drawing in pairs(esp) do
                if key == "SkeletonLines" then
                    for _, line in pairs(drawing) do
                        line.Visible = false
                    end
                else
                    drawing.Visible = false
                end
            end
            continue
        end
        
        local distance = GetDistance(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(), root.Position)
        local scale = math.clamp(1000 / distance, 8, 40)
        local boxWidth = scale * 2.5
        local boxHeight = scale * 3.5
        
        local topLeft = Vector2.new(pos.X - boxWidth/2, pos.Y - boxHeight/2)
        local bottomRight = Vector2.new(pos.X + boxWidth/2, pos.Y + boxHeight/2)
        
        local espColor = Settings.ESP.TeamColor and (IsTeammate(player) and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)) or Theme.Primary
        
        -- Box ESP
        if Settings.ESP.Boxes then
            esp.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            esp.BoxOutline.Position = topLeft
            esp.BoxOutline.Visible = true
            
            esp.Box.Size = Vector2.new(boxWidth, boxHeight)
            esp.Box.Position = topLeft
            esp.Box.Color = espColor
            esp.Box.Visible = true
            
            if Settings.ESP.BoxFilled then
                esp.BoxFill.Size = Vector2.new(boxWidth, boxHeight)
                esp.BoxFill.Position = topLeft
                esp.BoxFill.Color = espColor
                esp.BoxFill.Visible = true
            else
                esp.BoxFill.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
            esp.BoxFill.Visible = false
        end
        
        -- Name ESP
        if Settings.ESP.Names then
            esp.Name.Position = Vector2.new(pos.X, topLeft.Y - 20)
            esp.Name.Text = player.Name
            esp.Name.Color = espColor
            esp.Name.Visible = true
        else
            esp.Name.Visible = false
        end
        
        -- Distance ESP
        if Settings.ESP.Distance then
            esp.Distance.Position = Vector2.new(pos.X, bottomRight.Y + 5)
            esp.Distance.Text = string.format("%.0fm", distance)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end
        
        -- Health Bar
        if Settings.ESP.Health then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barHeight = boxHeight * healthPercent
            
            esp.HealthBarBg.Size = Vector2.new(4, boxHeight)
            esp.HealthBarBg.Position = Vector2.new(topLeft.X - 12, topLeft.Y)
            esp.HealthBarBg.Visible = true
            
            esp.HealthBar.Size = Vector2.new(2, barHeight)
            esp.HealthBar.Position = Vector2.new(topLeft.X - 11, topLeft.Y + boxHeight - barHeight)
            esp.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
            esp.HealthBar.Visible = true
        else
            esp.HealthBar.Visible = false
            esp.HealthBarBg.Visible = false
        end
        
        -- Tracers
        if Settings.ESP.Tracers then
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To = Vector2.new(pos.X, bottomRight.Y)
            esp.Tracer.Color = espColor
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
        
        -- Skeleton
        if Settings.ESP.Skeleton then
            for i, connection in ipairs(SkeletonConnections) do
                local part1 = character:FindFirstChild(connection[1])
                local part2 = character:FindFirstChild(connection[2])
                
                if part1 and part2 then
                    local p1 = Camera:WorldToViewportPoint(part1.Position)
                    local p2 = Camera:WorldToViewportPoint(part2.Position)
                    
                    if p1.Z > 0 and p2.Z > 0 then
                        esp.SkeletonLines[i].From = Vector2.new(p1.X, p1.Y)
                        esp.SkeletonLines[i].To = Vector2.new(p2.X, p2.Y)
                        esp.SkeletonLines[i].Color = espColor
                        esp.SkeletonLines[i].Visible = true
                    else
                        esp.SkeletonLines[i].Visible = false
                    end
                else
                    esp.SkeletonLines[i].Visible = false
                end
            end
        else
            for _, line in pairs(esp.SkeletonLines) do
                line.Visible = false
            end
        end
    end
end

-- Aimbot System
local function GetClosestPlayerToMouse()
    local closest = nil
    local shortestDistance = Settings.Aimbot.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not IsAlive(player) then continue end
        if Settings.Aimbot.TeamCheck and IsTeammate(player) then continue end
        
        local character = GetCharacter(player)
        if not character then continue end
        
        local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)
        if not targetPart then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end
        
        if Settings.Aimbot.WallCheck then
            local origin = Camera.CFrame.Position
            if not RaycastVisible(origin, targetPart.Position, {LocalPlayer.Character, character}) then
                continue
            end
        end
        
        local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
        if distance < shortestDistance then
            shortestDistance = distance
            closest = player
        end
    end
    
    return closest
end

local function RunAimbot()
    if not Settings.Aimbot.Enabled then
        AimbotTarget = nil
        return
    end
    
    if Settings.Aimbot.ShowFOV then
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
        FOVCircle.Radius = Settings.Aimbot.FOV
        FOVCircle.Visible = true
        
        FOVCircleOutline.Position = Vector2.new(Mouse.X, Mouse.Y)
        FOVCircleOutline.Radius = Settings.Aimbot.FOV + 1
        FOVCircleOutline.Visible = true
    else
        FOVCircle.Visible = false
        FOVCircleOutline.Visible = false
    end
    
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayerToMouse()
        if target then
            AimbotTarget = target
            local character = GetCharacter(target)
            if character then
                local targetPart = character:FindFirstChild(Settings.Aimbot.TargetPart)
                if targetPart then
                    local predictedPos = targetPart.Position + (targetPart.Velocity * Settings.Aimbot.Prediction)
                    local pos = Camera:WorldToViewportPoint(predictedPos)
                    local targetPos = Vector2.new(pos.X, pos.Y)
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local smoothness = Settings.Aimbot.Smoothness / 100
                    local moveVec = (targetPos - mousePos) * smoothness
                    
                    mousemoverel(moveVec.X, moveVec.Y)
                end
            end
        else
            AimbotTarget = nil
        end
    else
        AimbotTarget = nil
    end
end

-- Triggerbot System
local function GetPlayerUnderCrosshair()
    local ray = Camera:ViewportPointToRay(Mouse.X, Mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)
            if player and player ~= LocalPlayer then
                return player
            end
        end
    end
    return nil
end

local function RunTriggerbot()
    if not Settings.Triggerbot.Enabled then return end
    
    local target = GetPlayerUnderCrosshair()
    if target then
        if not IsAlive(target) then return end
        if Settings.Triggerbot.TeamCheck and IsTeammate(target) then return end
        
        if Settings.Triggerbot.WallCheck then
            local origin = Camera.CFrame.Position
            local targetPart = GetHead(target)
            if targetPart and not RaycastVisible(origin, targetPart.Position, {LocalPlayer.Character, GetCharacter(target)}) then
                return
            end
        end
        
        local delay = Settings.Triggerbot.Delay + math.random(0, Settings.Triggerbot.Humanization)
        if tick() - LastShot >= (delay / 1000) then
            mouse1press()
            task.wait(0.05)
            mouse1release()
            LastShot = tick()
        end
    end
end

-- AutoFarm System
local function GetFarmTargets()
    local targets = {}
    local farmTypes = {
        Money = {"money", "cash", "job", "work"},
        Crates = {"crate", "box", "loot", "supply"},
        Chips = {"chip", "casino", "gamble"}
    }
    
    local searchTerms = farmTypes[Settings.AutoFarm.Type] or farmTypes.Money
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            for _, term in pairs(searchTerms) do
                if name:find(term) then
                    table.insert(targets, obj)
                    break
                end
            end
        end
    end
    
    return targets
end

local function RunAutoFarm()
    if not Settings.AutoFarm.Enabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local targets = GetFarmTargets()
    if #targets == 0 then return end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, target in pairs(targets) do
        if target and target.Parent then
            local dist = GetDistance(root.Position, target.Position)
            if dist < nearestDist then
                nearestDist = dist
                nearest = target
            end
        end
    end
    
    if nearest then
        local speed = Settings.AutoFarm.Speed / 50
        local direction = (nearest.Position - root.Position).Unit
        root.CFrame = root.CFrame + (direction * speed)
        root.CFrame = CFrame.new(root.Position.X, nearest.Position.Y + 3, root.Position.Z)
        
        -- Auto Shoot
        if Settings.AutoFarm.AutoShoot then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and IsAlive(player) then
                    local pRoot = GetRoot(player)
                    if pRoot then
                        local dist = GetDistance(root.Position, pRoot.Position)
                        if dist < 50 then
                            local tool = character:FindFirstChildOfClass("Tool")
                            if tool then
                                tool:Activate()
                            end
                        end
                    end
                end
            end
        end
        
        -- Interact
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                pcall(function()
                    if remote.Name:lower():find("interact") or remote.Name:lower():find("collect") then
                        remote:FireServer(nearest)
                    end
                end)
            end
        end
    end
end

-- Player Mods
local function UpdatePlayerMods()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    humanoid.WalkSpeed = Settings.Player.WalkSpeed
    humanoid.JumpPower = Settings.Player.JumpPower
    
    -- Noclip
    if Settings.Player.Noclip then
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Fly System
local FlyConnection = nil

local function ToggleFly(enabled)
    local character = LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if enabled then
        FlyBodyGyro = Instance.new("BodyGyro")
        FlyBodyGyro.P = 9e4
        FlyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        FlyBodyGyro.CFrame = root.CFrame
        FlyBodyGyro.Parent = root
        
        FlyBodyVelocity = Instance.new("BodyVelocity")
        FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        FlyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        FlyBodyVelocity.Parent = root
        
        FlyConnection = Connect(RunService.RenderStepped, function()
            if not FlyBodyGyro or not FlyBodyVelocity then return end
            
            local moveDir = Vector3.new(0, 0, 0)
            local speed = Settings.Player.FlySpeed
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            
            FlyBodyGyro.CFrame = Camera.CFrame
            FlyBodyVelocity.Velocity = moveDir * speed
        end)
    else
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if FlyBodyGyro then
            FlyBodyGyro:Destroy()
            FlyBodyGyro = nil
        end
        if FlyBodyVelocity then
            FlyBodyVelocity:Destroy()
            FlyBodyVelocity = nil
        end
    end
end

-- Gun Mods
local function ApplyGunMods()
    if not Settings.Gun.NoRecoil and not Settings.Gun.NoSpread and not Settings.Gun.InfiniteAmmo then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            -- No Recoil
            if Settings.Gun.NoRecoil then
                local recoil = tool:FindFirstChild("Recoil") or tool:FindFirstChild("RecoilValue")
                if recoil then
                    recoil.Value = 0
                end
            end
            
            -- No Spread
            if Settings.Gun.NoSpread then
                local spread = tool:FindFirstChild("Spread") or tool:FindFirstChild("SpreadValue")
                if spread then
                    spread.Value = 0
                end
            end
            
            -- Instant Reload
            if Settings.Gun.InstantReload then
                local reload = tool:FindFirstChild("ReloadTime")
                if reload then
                    reload.Value = 0.01
                end
            end
            
            -- Rapid Fire
            if Settings.Gun.RapidFire then
                local fireRate = tool:FindFirstChild("FireRate") or tool:FindFirstChild("FireRateValue")
                if fireRate then
                    fireRate.Value = 0.01
                end
            end
            
            -- Infinite Ammo
            if Settings.Gun.InfiniteAmmo then
                local ammo = tool:FindFirstChild("Ammo")
                local maxAmmo = tool:FindFirstChild("MaxAmmo")
                if ammo and maxAmmo then
                    ammo.Value = maxAmmo.Value
                end
            end
        end
    end
end

-- Misc Features
local function RunMisc()
    -- Auto Loot
    if Settings.Misc.AutoLoot then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("loot") or obj.Name:lower():find("item") then
                local dist = GetDistance(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(), obj.Position)
                if dist < 20 then
                    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                        if remote:IsA("RemoteEvent") and remote.Name:lower():find("loot") then
                            pcall(function()
                                remote:FireServer(obj)
                            end)
                        end
                    end
                end
            end
        end
    end
    
    -- Anti Aim / Spinbot
    if Settings.Misc.AntiAim or Settings.Misc.Spinbot then
        local character = LocalPlayer.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                if Settings.Misc.Spinbot then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(30), 0)
                elseif Settings.Misc.AntiAim then
                    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
                end
            end
        end
    end
end

-- UI Components
local function CreateToggle(parent, text, settingTable, settingKey, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -10, 0, 45)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = ToggleFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 50, 0, 26)
    ToggleBtn.Position = UDim2.new(1, -65, 0.5, -13)
    ToggleBtn.BackgroundColor3 = settingTable[settingKey] and Theme.Primary or Color3.fromRGB(60, 60, 70)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 20, 0, 20)
    Circle.Position = settingTable[settingKey] and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = ToggleBtn
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
    ToggleBtn.MouseButton1Click:Connect(function()
        settingTable[settingKey] = not settingTable[settingKey]
        Tween(ToggleBtn, {BackgroundColor3 = settingTable[settingKey] and Theme.Primary or Color3.fromRGB(60, 60, 70)}, 0.2)
        Tween(Circle, {Position = settingTable[settingKey] and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)}, 0.2)
        
        if callback then
            callback(settingTable[settingKey])
        end
    end)
    
    return ToggleFrame
end

local function CreateSlider(parent, text, min, max, settingTable, settingKey, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, -10, 0, 60)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = SliderFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 25)
    Label.Position = UDim2.new(0, 15, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = SliderFrame
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.3, -15, 0, 25)
    ValueLabel.Position = UDim2.new(0.7, 0, 0, 8)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(settingTable[settingKey])
    ValueLabel.TextColor3 = Theme.Primary
    ValueLabel.TextSize = 13
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderFrame
    
    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -30, 0, 6)
    SliderBg.Position = UDim2.new(0, 15, 0, 38)
    SliderBg.BackgroundColor3 = Color3.fromRGB(50, 48, 60)
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = SliderFrame
    
    local SliderBgCorner = Instance.new("UICorner")
    SliderBgCorner.CornerRadius = UDim.new(1, 0)
    SliderBgCorner.Parent = SliderBg
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((settingTable[settingKey] - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Theme.Primary
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBg
    
    local SliderFillCorner = Instance.new("UICorner")
    SliderFillCorner.CornerRadius = UDim.new(1, 0)
    SliderFillCorner.Parent = SliderFill
    
    local DragBtn = Instance.new("TextButton")
    DragBtn.Size = UDim2.new(0, 14, 0, 14)
    DragBtn.Position = UDim2.new((settingTable[settingKey] - min) / (max - min), -7, 0.5, -7)
    DragBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DragBtn.BorderSizePixel = 0
    DragBtn.Text = ""
    DragBtn.Parent = SliderBg
    
    local DragCorner = Instance.new("UICorner")
    DragCorner.CornerRadius = UDim.new(1, 0)
    DragCorner.Parent = DragBtn
    
    local dragging = false
    
    DragBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    DragBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            settingTable[settingKey] = value
            
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            DragBtn.Position = UDim2.new(pos, -7, 0.5, -7)
            ValueLabel.Text = tostring(value)
            
            if callback then
                callback(value)
            end
        end
    end)
    
    Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            settingTable[settingKey] = value
            
            SliderFill.Size = UDim2.new(pos, 0, 1, 0)
            DragBtn.Position = UDim2.new(pos, -7, 0.5, -7)
            ValueLabel.Text = tostring(value)
            
            if callback then
                callback(value)
            end
        end
    end)
    
    return SliderFrame
end

local function CreateDropdown(parent, text, options, settingTable, settingKey, callback)
    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Size = UDim2.new(1, -10, 0, 45)
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
    DropdownFrame.BorderSizePixel = 0
    DropdownFrame.ClipsDescendants = true
    DropdownFrame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = DropdownFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 0, 45)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextSize = 13
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = DropdownFrame
    
    local SelectedBtn = Instance.new("TextButton")
    SelectedBtn.Size = UDim2.new(0, 150, 0, 30)
    SelectedBtn.Position = UDim2.new(1, -165, 0, 7)
    SelectedBtn.BackgroundColor3 = Color3.fromRGB(40, 38, 50)
    SelectedBtn.BorderSizePixel = 0
    SelectedBtn.Text = settingTable[settingKey]
    SelectedBtn.TextColor3 = Theme.Text
    SelectedBtn.TextSize = 12
    SelectedBtn.Font = Enum.Font.GothamBold
    SelectedBtn.Parent = DropdownFrame
    
    local SelectedCorner = Instance.new("UICorner")
    SelectedCorner.CornerRadius = UDim.new(0, 6)
    SelectedCorner.Parent = SelectedBtn
    
    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 0, 30)
    Arrow.Position = UDim2.new(1, -25, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = Theme.TextDim
    Arrow.TextSize = 12
    Arrow.Parent = SelectedBtn
    
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Size = UDim2.new(1, 0, 0, #options * 30)
    OptionsFrame.Position = UDim2.new(0, 0, 0, 45)
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(35, 33, 45)
    OptionsFrame.BorderSizePixel = 0
    OptionsFrame.Visible = false
    OptionsFrame.Parent = DropdownFrame
    
    local OptionsCorner = Instance.new("UICorner")
    OptionsCorner.CornerRadius = UDim.new(0, 8)
    OptionsCorner.Parent = OptionsFrame
    
    local expanded = false
    
    for i, option in pairs(options) do
        local OptionBtn = Instance.new("TextButton")
        OptionBtn.Size = UDim2.new(1, 0, 0, 30)
        OptionBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 30)
        OptionBtn.BackgroundColor3 = Color3.fromRGB(35, 33, 45)
        OptionBtn.BorderSizePixel = 0
        OptionBtn.Text = option
        OptionBtn.TextColor3 = Theme.Text
        OptionBtn.TextSize = 12
        OptionBtn.Font = Enum.Font.Gotham
        OptionBtn.Parent = OptionsFrame
        
        OptionBtn.MouseEnter:Connect(function()
            Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(50, 48, 65)}, 0.1)
        end)
        
        OptionBtn.MouseLeave:Connect(function()
            Tween(OptionBtn, {BackgroundColor3 = Color3.fromRGB(35, 33, 45)}, 0.1)
        end)
        
        OptionBtn.MouseButton1Click:Connect(function()
            settingTable[settingKey] = option
            SelectedBtn.Text = option
            expanded = false
            Tween(OptionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            task.delay(0.2, function()
                OptionsFrame.Visible = false
            end)
            Tween(Arrow, {Rotation = 0}, 0.2)
            
            if callback then
                callback(option)
            end
        end)
    end
    
    SelectedBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            OptionsFrame.Visible = true
            Tween(OptionsFrame, {Size = UDim2.new(1, 0, 0, #options * 30)}, 0.2)
            Tween(Arrow, {Rotation = 180}, 0.2)
        else
            Tween(OptionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            task.delay(0.2, function()
                OptionsFrame.Visible = false
            end)
            Tween(Arrow, {Rotation = 0}, 0.2)
        end
    end)
    
    return DropdownFrame
end

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = name .. "Tab"
    TabBtn.Size = UDim2.new(1, 0, 0, 38)
    TabBtn.BackgroundColor3 = Color3.fromRGB(25, 23, 35)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = name
    TabBtn.TextColor3 = Theme.TextDim
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.Parent = TabContainer
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabBtn
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = name .. "Content"
    TabContent.Size = UDim2.new(1, -20, 1, -20)
    TabContent.Position = UDim2.new(0, 10, 0, 10)
    TabContent.BackgroundTransparency = 1
    TabContent.BorderSizePixel = 0
    TabContent.ScrollBarThickness = 4
    TabContent.ScrollBarImageColor3 = Theme.Primary
    TabContent.Visible = false
    TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContent.Parent = ContentArea
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.Parent = TabContent
    
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    TabBtn.MouseButton1Click:Connect(function()
        if CurrentTab then
            CurrentTab.Content.Visible = false
            Tween(CurrentTab.Button, {BackgroundColor3 = Color3.fromRGB(25, 23, 35), TextColor3 = Theme.TextDim}, 0.2)
        end
        
        TabContent.Visible = true
        CurrentTab = {Button = TabBtn, Content = TabContent}
        Tween(TabBtn, {BackgroundColor3 = Theme.Primary, TextColor3 = Color3.fromRGB(0, 0, 0)}, 0.2)
    end)
    
    return TabContent
end

-- Create All Tabs
local AimbotTab = CreateTab("AIMBOT")
local TriggerbotTab = CreateTab("TRIGGERBOT")
local ESPTab = CreateTab("ESP")
local AutoFarmTab = CreateTab("AUTOFARM")
local PlayerTab = CreateTab("PLAYER")
local GunTab = CreateTab("GUN MODS")
local MiscTab = CreateTab("MISC")

-- AIMBOT TAB
CreateToggle(AimbotTab, "🔫 Enable Aimbot", Settings.Aimbot, "Enabled")
CreateToggle(AimbotTab, "👥 Team Check", Settings.Aimbot, "TeamCheck")
CreateToggle(AimbotTab, "🧱 Wall Check", Settings.Aimbot, "WallCheck")
CreateToggle(AimbotTab, "⭕ Show FOV", Settings.Aimbot, "ShowFOV")
CreateSlider(AimbotTab, "FOV Size", 50, 500, Settings.Aimbot, "FOV", function(val)
    FOVCircle.Radius = val
    FOVCircleOutline.Radius = val + 1
end)
CreateSlider(AimbotTab, "Smoothness", 1, 100, Settings.Aimbot, "Smoothness")
CreateSlider(AimbotTab, "Prediction", 0, 50, Settings.Aimbot, "Prediction", function(val)
    Settings.Aimbot.Prediction = val / 100
end)
CreateDropdown(AimbotTab, "Target Part", {"Head", "Torso", "HumanoidRootPart"}, Settings.Aimbot, "TargetPart")

-- TRIGGERBOT TAB
CreateToggle(TriggerbotTab, "🎯 Enable Triggerbot", Settings.Triggerbot, "Enabled")
CreateToggle(TriggerbotTab, "👥 Team Check", Settings.Triggerbot, "TeamCheck")
CreateToggle(TriggerbotTab, "🧱 Wall Check", Settings.Triggerbot, "WallCheck")
CreateSlider(TriggerbotTab, "Shoot Delay (ms)", 0, 500, Settings.Triggerbot, "Delay")
CreateSlider(TriggerbotTab, "Humanization", 0, 100, Settings.Triggerbot, "Humanization")

-- ESP TAB
CreateToggle(ESPTab, "👁️ Enable ESP", Settings.ESP, "Enabled")
CreateToggle(ESPTab, "👥 Team Check", Settings.ESP, "TeamCheck")
CreateToggle(ESPTab, "📦 Boxes", Settings.ESP, "Boxes")
CreateToggle(ESPTab, "🎨 Filled Boxes", Settings.ESP, "BoxFilled")
CreateToggle(ESPTab, "🏷️ Names", Settings.ESP, "Names")
CreateToggle(ESPTab, "📏 Distance", Settings.ESP, "Distance")
CreateToggle(ESPTab, "❤️ Health", Settings.ESP, "Health")
CreateToggle(ESPTab, "📊 Health Bar", Settings.ESP, "HealthBar")
CreateToggle(ESPTab, "➡️ Tracers", Settings.ESP, "Tracers")
CreateToggle(ESPTab, "🦴 Skeleton", Settings.ESP, "Skeleton")
CreateToggle(ESPTab, "🎨 Team Colors", Settings.ESP, "TeamColor")

-- AUTOFARM TAB
CreateToggle(AutoFarmTab, "🤖 Enable Auto Farm", Settings.AutoFarm, "Enabled")
CreateToggle(AutoFarmTab, "🔫 Auto Shoot", Settings.AutoFarm, "AutoShoot")
CreateDropdown(AutoFarmTab, "Farm Type", {"Money", "Crates", "Chips"}, Settings.AutoFarm, "Type")
CreateSlider(AutoFarmTab, "Farm Speed", 10, 200, Settings.AutoFarm, "Speed")

-- PLAYER TAB
CreateSlider(PlayerTab, "Walk Speed", 16, 200, Settings.Player, "WalkSpeed", function(val)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = val
    end
end)
CreateSlider(PlayerTab, "Jump Power", 50, 200, Settings.Player, "JumpPower", function(val)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = val
    end
end)
CreateSlider(PlayerTab, "Fly Speed", 10, 200, Settings.Player, "FlySpeed")
CreateToggle(PlayerTab, "🦅 Enable Fly", Settings.Player, "Fly", ToggleFly)
CreateToggle(PlayerTab, "🦘 Infinite Jump", Settings.Player, "InfiniteJump")
CreateToggle(PlayerTab, "👻 Noclip", Settings.Player, "Noclip")

-- GUN MODS TAB
CreateToggle(GunTab, "🔇 No Recoil", Settings.Gun, "NoRecoil")
CreateToggle(GunTab, "🎯 No Spread", Settings.Gun, "NoSpread")
CreateToggle(GunTab, "⚡ Instant Reload", Settings.Gun, "InstantReload")
CreateToggle(GunTab, "🔥 Rapid Fire", Settings.Gun, "RapidFire")
CreateToggle(GunTab, "♾️ Infinite Ammo", Settings.Gun, "InfiniteAmmo")

-- MISC TAB
CreateToggle(MiscTab, "💰 Auto Loot", Settings.Misc, "AutoLoot")
CreateToggle(MiscTab, "💵 Auto Sell", Settings.Misc, "AutoSell")
CreateToggle(MiscTab, "🔄 Anti Aim", Settings.Misc, "AntiAim")
CreateToggle(MiscTab, "🌪️ Spinbot", Settings.Misc, "Spinbot")

-- Draggable
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

Connect(TopBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

Connect(TopBar.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Hotkey (H)
Connect(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        GUIVisible = not GUIVisible
        MainFrame.Visible = GUIVisible
    end
end)

-- Close Button
Connect(CloseBtn.MouseButton1Click, function()
    -- Cleanup
    for _, conn in pairs(Connections) do
        if conn and conn.Disconnect then
            pcall(function() conn:Disconnect() end)
        end
    end
    
    for _, drawing in pairs(DrawingObjects) do
        if drawing and drawing.Remove then
            pcall(function() drawing:Remove() end)
        end
    end
    
    for player, esp in pairs(ESPObjects) do
        for key, drawing in pairs(esp) do
            if key == "SkeletonLines" then
                for _, line in pairs(drawing) do
                    pcall(function() line:Remove() end)
                end
            else
                pcall(function() drawing:Remove() end)
            end
        end
    end
    
    if NoclipConnection then
        NoclipConnection:Disconnect()
    end
    
    if FlyConnection then
        FlyConnection:Disconnect()
    end
    
    if FlyBodyGyro then
        FlyBodyGyro:Destroy()
    end
    
    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
    end
    
    ScreenGui:Destroy()
end)

-- Minimize Button
local minimized = false
Connect(MinBtn.MouseButton1Click, function()
    minimized = not minimized
    ContentArea.Visible = not minimized
    Sidebar.Visible = not minimized
    Credits.Visible = not minimized
    if minimized then
        Tween(MainFrame, {Size = UDim2.new(0, 650, 0, 50)}, 0.3)
    else
        Tween(MainFrame, {Size = UDim2.new(0, 650, 0, 450)}, 0.3)
    end
end)

-- Access Code Verification
Connect(VerifyBtn.MouseButton1Click, function()
    if CodeInput.Text == "HASBIW.EXE ONTOP" then
        Tween(AccessFrame, {Position = UDim2.new(0.5, -225, 1.5, 0)}, 0.5)
        task.wait(0.5)
        AccessFrame.Visible = false
        MainFrame.Visible = true
        MainFrame.Position = UDim2.new(0.5, -325, 1.5, 0)
        Tween(MainFrame, {Position = UDim2.new(0.5, -325, 0.5, -225)}, 0.5)
        
        -- Select first tab
        AimbotTab.Visible = true
        CurrentTab = {Button = TabContainer:FindFirstChild("AIMBOTTab"), Content = AimbotTab}
        if CurrentTab.Button then
            Tween(CurrentTab.Button, {BackgroundColor3 = Theme.Primary, TextColor3 = Color3.fromRGB(0, 0, 0)}, 0.2)
        end
        
        Notify("GUPRON.EXE", "Access Granted! Press H to toggle GUI", 5)
    else
        ErrorLabel.Text = "❌ INVALID ACCESS CODE"
        Tween(CodeInput, {BackgroundColor3 = Color3.fromRGB(60, 30, 30)}, 0.1)
        task.wait(0.2)
        Tween(CodeInput, {BackgroundColor3 = Color3.fromRGB(20, 20, 30)}, 0.1)
    end
end)

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
end

Connect(Players.PlayerAdded, CreateESP)
Connect(Players.PlayerRemoving, function(player)
    if ESPObjects[player] then
        for key, drawing in pairs(ESPObjects[player]) do
            if key == "SkeletonLines" then
                for _, line in pairs(drawing) do
                    pcall(function() line:Remove() end)
                end
            else
                pcall(function() drawing:Remove() end)
            end
        end
        ESPObjects[player] = nil
    end
end)

-- Main Loops
CreateLoop("ESP", UpdateESP)
CreateLoop("Aimbot", RunAimbot)
CreateLoop("Triggerbot", RunTriggerbot)
CreateLoop("AutoFarm", RunAutoFarm)
CreateLoop("PlayerMods", UpdatePlayerMods)
CreateLoop("GunMods", ApplyGunMods)
CreateLoop("Misc", RunMisc)

-- Infinite Jump
Connect(UserInputService.JumpRequest, function()
    if Settings.Player.InfiniteJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Initial Notification
Notify("GUPRON.EXE", "Script Loaded! Enter Access Code: HASBIW.EXE ONTOP", 5)

print([[
╔══════════════════════════════════════════════════════════╗
║                    GUPRON.EXE v4.0                       ║
║              SOUTH BRONX: THE TRENCHES                    ║
║                                                          ║
║  Access Code: HASBIW.EXE ONTOP                            ║
║  Hotkey: H (Toggle GUI)                                   ║
║                                                          ║
║  Features:                                               ║
║  - Aimbot with Prediction & Smoothness                    ║
║  - Triggerbot with Delay & Humanization                 ║
║  - Full ESP (Boxes, Names, Health, Skeleton)            ║
║  - AutoFarm with Multiple Types                           ║
║  - Player Mods (Fly, Noclip, Speed)                       ║
║  - Gun Mods (No Recoil, Infinite Ammo, etc)              ║
║  - Misc Features (Auto Loot, Anti Aim, Spinbot)          ║
╚══════════════════════════════════════════════════════════╝
]])