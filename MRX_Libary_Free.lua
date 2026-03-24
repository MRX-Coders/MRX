--[[
    MRX_TBUH_GUI: "Death God" Edition
    "MRX the best Grey hat in the word."
    
    A sophisticated GUI Library for Roblox, built from the ground up for
    robustness, customization, and smooth animations. Features a built-in
    MRX_ESP module and custom TweenService wrapper.
    
    Author: MRX
]]

local MRX_Library = {
    Version = "2.0.0",
    Theme = {
        Background = Color3.fromRGB(15, 10, 20),
        SectionBackground = Color3.fromRGB(20, 15, 25),
        HeaderBackground = Color3.fromRGB(30, 10, 30),
        Border = Color3.fromRGB(50, 0, 50),
        Text = Color3.fromRGB(255, 200, 220),
        TextMuted = Color3.fromRGB(180, 120, 150),
        Accent = Color3.fromRGB(200, 0, 50),     -- Death God Crimson
        AccentHover = Color3.fromRGB(255, 30, 80),
        Glow = Color3.fromRGB(150, 0, 30),
        Rounding = 6,
        Success = Color3.fromRGB(0, 255, 100),
        Warning = Color3.fromRGB(255, 150, 0),
        Error = Color3.fromRGB(255, 0, 50),
    },
    Settings = {
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ToggleKey = Enum.KeyCode.RightControl
    },
    Connections = {},
    Flags = {},
    -- Built-in modules
    ESP = {
        Enabled = false,
        Boxes = false,
        BoxColor = Color3.fromRGB(255, 0, 50),
        Names = false,
        NameColor = Color3.fromRGB(255, 255, 255),
        Health = false,
        HealthBarColor = Color3.fromRGB(0, 255, 0),
        Distance = false,
        DistanceColor = Color3.fromRGB(255, 255, 255),
        Tracers = false,
        TracerOrigin = "Bottom", -- "Bottom", "Top", "Mouse"
        TracerColor = Color3.fromRGB(200, 0, 50),
        Skeletons = false,
        SkeletonColor = Color3.fromRGB(255, 255, 255),
        Chams = false,
        ChamsFillColor = Color3.fromRGB(200, 0, 50),
        ChamsOutlineColor = Color3.fromRGB(100, 0, 25),
        ChamsFillTransparency = 0.5,
        ChamsOutlineTransparency = 0,
        Players = {},
        Drawings = {}
    }
}

-- [ Services ] ------------------------------------------------------------------------------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- [ Global Dependencies Check ] --------------------------------------------------------------------------------------------------------------------------
local gethui = gethui or function() return CoreGui end
local Drawing = Drawing or {
    new = function(type)
        return {
            Visible = false, ZIndex = 0, Transparency = 1, Color = Color3.new(),
            Remove = function() end, Text = "", Size = 16, Center = false,
            Outline = false, OutlineColor = Color3.new(), Position = Vector2.new(),
            From = Vector2.new(), To = Vector2.new(), Thickness = 1, Filled = false
        }
    end
}

-- [ Folder & Instance Protection ] -----------------------------------------------------------------------------------------------------------------------
local MRX_ScreenGui = Instance.new("ScreenGui")
MRX_ScreenGui.Name = HttpService:GenerateGUID(false)
MRX_ScreenGui.ResetOnSpawn = false
MRX_ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
MRX_ScreenGui.IgnoreGuiInset = true

if syn and syn.protect_gui then
    syn.protect_gui(MRX_ScreenGui)
    MRX_ScreenGui.Parent = CoreGui
elseif gethui then
    MRX_ScreenGui.Parent = gethui()
else
    MRX_ScreenGui.Parent = CoreGui
end

-- [ Utility Functions ] ----------------------------------------------------------------------------------------------------------------------------------
local Utility = {}

function Utility:Tween(instance, properties, duration, style, direction)
    duration = duration or 0.2
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utility:Create(class, properties)
    local instance = Instance.new(class)
    for name, value in pairs(properties) do
        if name ~= "Parent" then
            instance[name] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility:MakeDraggable(topbar, frame)
    local dragging = false
    local dragInput, mousePos, framePos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
            Utility:Tween(frame, {Position = newPos}, 0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        end
    end)
end

function Utility:GetTextBounds(text, font, size)
    local textSize = game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
    return textSize
end

function Utility:AddGlow(parent, color, radius)
    local glow = Utility:Create("ImageLabel", {
        Name = "Glow",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -radius, 0, -radius),
        Size = UDim2.new(1, radius * 2, 1, radius * 2),
        Image = "rbxassetid://5028857084",
        ImageColor3 = color,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = parent.ZIndex - 1,
        Parent = parent
    })
    return glow
end

function Utility:AddRipple(button)
    local container = Utility:Create("Frame", {
        Name = "RippleContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true,
        ZIndex = button.ZIndex + 1,
        Parent = button
    })

    button.MouseButton1Down:Connect(function()
        local mousePos = UserInputService:GetMouseLocation()
        local absolutePos = button.AbsolutePosition
        local relativeX = mousePos.X - absolutePos.X
        local relativeY = mousePos.Y - absolutePos.Y - 36 -- Account for topbar offset generally
        
        local ripple = Utility:Create("ImageLabel", {
            Name = "Ripple",
            BackgroundTransparency = 1,
            Image = "rbxassetid://4560909609",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            ImageTransparency = 0.6,
            Position = UDim2.new(0, relativeX, 0, relativeY),
            Size = UDim2.new(0, 0, 0, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = container.ZIndex + 1,
            Parent = container
        })

        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.5
        local tweenPlay = Utility:Tween(ripple, {Size = UDim2.new(0, size, 0, size), ImageTransparency = 1}, 0.5)
        
        tweenPlay.Completed:Connect(function()
            ripple:Destroy()
        end)
    end)
end

-- [ Notification System ] --------------------------------------------------------------------------------------------------------------------------------
MRX_Library.Notifs = {}

local NotificationContainer = Utility:Create("Frame", {
    Name = "MRX_Notifications",
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, -40),
    Position = UDim2.new(1, -320, 0, 20),
    Parent = MRX_ScreenGui
})

local NotifLayout = Utility:Create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 10),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Parent = NotificationContainer
})

function MRX_Library:Notify(options)
    local title = options.Title or "Notification"
    local text = options.Text or "No text provided."
    local duration = options.Duration or 5
    local nType = options.Type or "Info" -- Info, Success, Warning, Error
    
    local accentColor = MRX_Library.Theme.Accent
    if nType == "Success" then accentColor = MRX_Library.Theme.Success
    elseif nType == "Warning" then accentColor = MRX_Library.Theme.Warning
    elseif nType == "Error" then accentColor = MRX_Library.Theme.Error end

    local NotifFrame = Utility:Create("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 280, 0, 0), -- Automatically sizes
        Position = UDim2.new(1, 300, 0, 0),
        BackgroundColor3 = MRX_Library.Theme.SectionBackground,
        BorderSizePixel = 0,
        Parent = NotificationContainer,
        ClipsDescendants = true
    })

    Utility:Create("UICorner", { CornerRadius = UDim.new(0, MRX_Library.Theme.Rounding), Parent = NotifFrame })
    Utility:AddGlow(NotifFrame, accentColor, 15)

    local NotifLine = Utility:Create("Frame", {
        Name = "Line",
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = NotifFrame
    })

    local TitleLabel = Utility:Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 8),
        Size = UDim2.new(1, -25, 0, 16),
        Font = MRX_Library.Theme.Font,
        Text = title,
        TextColor3 = MRX_Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = NotifFrame
    })

    local TextLabel = Utility:Create("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 28),
        Size = UDim2.new(1, -25, 0, 0),
        Font = Enum.Font.Code,
        Text = text,
        TextColor3 = MRX_Library.Theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = NotifFrame
    })

    -- Calculate needed size
    local bounds = Utility:GetTextBounds(text, TextLabel.Font, TextLabel.TextSize)
    local lines = math.ceil(bounds.X / (NotifFrame.AbsoluteSize.X - 25))
    local textHeight = lines * 14
    local totalHeight = 28 + textHeight + 12

    TextLabel.Size = UDim2.new(1, -25, 0, textHeight)
    
    -- Animate In
    NotifFrame.Size = UDim2.new(0, 280, 0, totalHeight)
    Utility:Tween(NotifFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(duration, function()
        -- Animate Out
        local animOut = Utility:Tween(NotifFrame, {Position = UDim2.new(1, 300, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        animOut.Completed:Connect(function()
            NotifFrame:Destroy()
        end)
    end)
end

-- [ MRX_ESP Module Core ] --------------------------------------------------------------------------------------------------------------------------------
local function CreateESPElement(type)
    local elem = Drawing.new(type)
    return elem
end

function MRX_Library.ESP:CreatePlayerDrawings(player)
    if not MRX_Library.ESP.Drawings[player.Name] then
        MRX_Library.ESP.Drawings[player.Name] = {
            Box = CreateESPElement("Square"),
            BoxOutline = CreateESPElement("Square"),
            Name = CreateESPElement("Text"),
            HealthBarbg = CreateESPElement("Square"),
            HealthBar = CreateESPElement("Square"),
            Distance = CreateESPElement("Text"),
            Tracer = CreateESPElement("Line"),
            Skeleton = {
                HeadNeck = CreateESPElement("Line"),
                NeckTorso = CreateESPElement("Line"),
                TorsoPelvis = CreateESPElement("Line"),
                LeftShoulderLeftArm = CreateESPElement("Line"),
                RightShoulderRightArm = CreateESPElement("Line"),
                LeftArmLeftHand = CreateESPElement("Line"),
                RightArmRightHand = CreateESPElement("Line"),
                PelvisLeftLeg = CreateESPElement("Line"),
                PelvisRightLeg = CreateESPElement("Line"),
                LeftLegLeftFoot = CreateESPElement("Line"),
                RightLegRightFoot = CreateESPElement("Line"),
            },
            Chams = Instance.new("Highlight")
        }
        
        local drawings = MRX_Library.ESP.Drawings[player.Name]
        
        drawings.Box.Thickness = 1
        drawings.Box.Filled = false
        drawings.Box.Color = MRX_Library.ESP.BoxColor
        
        drawings.BoxOutline.Thickness = 3
        drawings.BoxOutline.Filled = false
        drawings.BoxOutline.Color = Color3.new(0,0,0)
        drawings.BoxOutline.ZIndex = -1
        
        drawings.Name.Size = 14
        drawings.Name.Center = true
        drawings.Name.Outline = true
        drawings.Name.Color = MRX_Library.ESP.NameColor
        
        drawings.HealthBarbg.Thickness = 1
        drawings.HealthBarbg.Filled = true
        drawings.HealthBarbg.Color = Color3.new(0,0,0)
        
        drawings.HealthBar.Thickness = 1
        drawings.HealthBar.Filled = true
        drawings.HealthBar.Color = MRX_Library.ESP.HealthBarColor
        
        drawings.Distance.Size = 13
        drawings.Distance.Center = true
        drawings.Distance.Outline = true
        drawings.Distance.Color = MRX_Library.ESP.DistanceColor
        
        drawings.Tracer.Thickness = 1
        drawings.Tracer.Color = MRX_Library.ESP.TracerColor
        
        for _, line in pairs(drawings.Skeleton) do
            line.Thickness = 1
            line.Color = MRX_Library.ESP.SkeletonColor
        end
        
        drawings.Chams.Name = player.Name .. "_Chams"
        if syn and syn.protect_gui then
            syn.protect_gui(drawings.Chams)
        end
        drawings.Chams.Parent = CoreGui
        drawings.Chams.FillColor = MRX_Library.ESP.ChamsFillColor
        drawings.Chams.OutlineColor = MRX_Library.ESP.ChamsOutlineColor
        drawings.Chams.FillTransparency = MRX_Library.ESP.ChamsFillTransparency
        drawings.Chams.OutlineTransparency = MRX_Library.ESP.ChamsOutlineTransparency
    end
end

function MRX_Library.ESP:RemovePlayerDrawings(player)
    if MRX_Library.ESP.Drawings[player.Name] then
        local drawings = MRX_Library.ESP.Drawings[player.Name]
        drawings.Box:Remove()
        drawings.BoxOutline:Remove()
        drawings.Name:Remove()
        drawings.HealthBarbg:Remove()
        drawings.HealthBar:Remove()
        drawings.Distance:Remove()
        drawings.Tracer:Remove()
        for _, line in pairs(drawings.Skeleton) do
            line:Remove()
        end
        if drawings.Chams then
            drawings.Chams:Destroy()
        end
        MRX_Library.ESP.Drawings[player.Name] = nil
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        MRX_Library.ESP:CreatePlayerDrawings(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer then
        MRX_Library.ESP:RemovePlayerDrawings(player)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        MRX_Library.ESP:CreatePlayerDrawings(player)
    end
end
RunService.RenderStepped:Connect(function()
    if not MRX_Library.ESP.Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and MRX_Library.ESP.Drawings[player.Name] then
                local drawings = MRX_Library.ESP.Drawings[player.Name]
                drawings.Box.Visible = false
                drawings.BoxOutline.Visible = false
                drawings.Name.Visible = false
                drawings.HealthBar.Visible = false
                drawings.HealthBarbg.Visible = false
                drawings.Distance.Visible = false
                drawings.Tracer.Visible = false
                for _, line in pairs(drawings.Skeleton) do
                    line.Visible = false
                end
                if drawings.Chams then drawings.Chams.Adornee = nil end
            end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and MRX_Library.ESP.Drawings[player.Name] then
            local drawings = MRX_Library.ESP.Drawings[player.Name]
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local hrp = char.HumanoidRootPart
                local head = char:FindFirstChild("Head")
                
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local headVector = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legVector = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                local height = headVector.Y - legVector.Y
                local width = height / 2

                if onScreen then
                    -- Boxes
                    if MRX_Library.ESP.Boxes then
                        drawings.Box.Visible = true
                        drawings.Box.Size = Vector2.new(width, height)
                        drawings.Box.Position = Vector2.new(vector.X - width/2, vector.Y - height/2)
                        
                        drawings.BoxOutline.Visible = true
                        drawings.BoxOutline.Size = drawings.Box.Size
                        drawings.BoxOutline.Position = drawings.Box.Position
                    else
                        drawings.Box.Visible = false
                        drawings.BoxOutline.Visible = false
                    end

                    -- Names
                    if MRX_Library.ESP.Names then
                        drawings.Name.Visible = true
                        drawings.Name.Position = Vector2.new(vector.X, vector.Y - height/2 - 20)
                        drawings.Name.Text = player.Name
                    else
                        drawings.Name.Visible = false
                    end
                    
                    -- HealthBar
                    if MRX_Library.ESP.Health then
                        local maxHealth = char.Humanoid.MaxHealth
                        local health = char.Humanoid.Health
                        local healthPercent = health / maxHealth
                        
                        drawings.HealthBarbg.Visible = true
                        drawings.HealthBarbg.Size = Vector2.new(3, height)
                        drawings.HealthBarbg.Position = Vector2.new(vector.X - width/2 - 6, vector.Y - height/2)
                        
                        drawings.HealthBar.Visible = true
                        drawings.HealthBar.Size = Vector2.new(1, height * healthPercent)
                        drawings.HealthBar.Position = Vector2.new(vector.X - width/2 - 5, vector.Y - height/2 + (height - height * healthPercent))
                        drawings.HealthBar.Color = Color3.fromRGB(255 - (healthPercent * 255), healthPercent * 255, 0)
                    else
                        drawings.HealthBarbg.Visible = false
                        drawings.HealthBar.Visible = false
                    end

                    -- Distance
                    if MRX_Library.ESP.Distance then
                        local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                        drawings.Distance.Visible = true
                        drawings.Distance.Position = Vector2.new(vector.X, vector.Y + height/2 + 5)
                        drawings.Distance.Text = "[" .. tostring(dist) .. "s]"
                    else
                        drawings.Distance.Visible = false
                    end
                    
                    -- Tracers
                    if MRX_Library.ESP.Tracers then
                        drawings.Tracer.Visible = true
                        local origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        if MRX_Library.ESP.TracerOrigin == "Top" then origin = Vector2.new(Camera.ViewportSize.X/2, 0)
                        elseif MRX_Library.ESP.TracerOrigin == "Mouse" then origin = UserInputService:GetMouseLocation() end
                        
                        drawings.Tracer.From = origin
                        drawings.Tracer.To = Vector2.new(vector.X, vector.Y + height/2)
                    else
                        drawings.Tracer.Visible = false
                    end
                    
                    -- Chams
                    if MRX_Library.ESP.Chams and drawings.Chams then
                        drawings.Chams.Adornee = char
                    else
                        if drawings.Chams then drawings.Chams.Adornee = nil end
                    end
                else
                    drawings.Box.Visible = false
                    drawings.BoxOutline.Visible = false
                    drawings.Name.Visible = false
                    drawings.HealthBarbg.Visible = false
                    drawings.HealthBar.Visible = false
                    drawings.Distance.Visible = false
                    drawings.Tracer.Visible = false
                end
            else
                drawings.Box.Visible = false
                drawings.BoxOutline.Visible = false
                drawings.Name.Visible = false
                drawings.HealthBarbg.Visible = false
                drawings.HealthBar.Visible = false
                drawings.Distance.Visible = false
                drawings.Tracer.Visible = false
                for _, line in pairs(drawings.Skeleton) do line.Visible = false end
                if drawings.Chams then drawings.Chams.Adornee = nil end
            end
        end
    end
end)

-- [ Library Architecture ] -------------------------------------------------------------------------------------------------------------------------------

function MRX_Library:CreateWindow(options)
    local WindowName = options.Name or "MRX_TBUH_GUI ("..MRX_Library.Version..")"
    local WindowSize = options.Size or UDim2.new(0, 600, 0, 450)
    
    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 0, 0, 0), -- Setup for an opening animation
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = MRX_Library.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MRX_ScreenGui
    })

    Utility:Create("UICorner", { CornerRadius = UDim.new(0, MRX_Library.Theme.Rounding), Parent = MainFrame })
    Utility:AddGlow(MainFrame, MRX_Library.Theme.Glow, 25)

    -- Animate Window Open
    Utility:Tween(MainFrame, {Size = WindowSize}, 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local Topbar = Utility:Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = MRX_Library.Theme.HeaderBackground,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(0, MRX_Library.Theme.Rounding), Parent = Topbar })

    local AccentTop = Utility:Create("Frame", {
        Name = "AccentTop",
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = MRX_Library.Theme.Accent,
        BorderSizePixel = 0,
        Parent = Topbar
    })

    local Title = Utility:Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Text = WindowName,
        TextColor3 = MRX_Library.Theme.Text,
        Font = MRX_Library.Settings.Font,
        TextSize = MRX_Library.Settings.TextSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Parent = Topbar
    })

    -- Watermark Logo text inside main area
    local Watermark = Utility:Create("TextLabel", {
        Name = "Watermark",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "DEATH GOD\n<font size='12'>MRX the best Grey hat in the world.</font>",
        TextColor3 = MRX_Library.Theme.Background, -- Hidden deeply, faint
        TextTransparency = 0.95,
        Font = Enum.Font.GothamBlack,
        TextSize = 50,
        ZIndex = 0,
        RichText = true,
        Parent = MainFrame
    })

    Utility:MakeDraggable(Topbar, MainFrame)

    local TabContainer = Utility:Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 160, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = MRX_Library.Theme.SectionBackground,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    
    local TabList = Utility:Create("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, -10, 1, -20),
        Position = UDim2.new(0, 5, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = MRX_Library.Theme.Accent,
        Parent = TabContainer
    })
    Utility:Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = TabList })

    local PageContainer = Utility:Create("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1, -160, 1, -35),
        Position = UDim2.new(0, 160, 0, 35),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == MRX_Library.Settings.ToggleKey then
            MRX_ScreenGui.Enabled = not MRX_ScreenGui.Enabled
        end
    end)

    local WindowObj = {}
    local CurrentTab = nil

    function WindowObj:CreateTab(options)
        local TabName = options.Name or "Tab"
        local TabIcon = options.Icon or "rbxassetid://3926305904" -- Replace with proper icon handling later if needed

        local TabButton = Utility:Create("TextButton", {
            Name = TabName,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = MRX_Library.Theme.Background,
            BackgroundTransparency = 1,
            Text = "  " .. TabName,
            TextColor3 = MRX_Library.Theme.TextMuted,
            Font = MRX_Library.Settings.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = TabList
        })
        Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TabButton })
        
        local TabHighlight = Utility:Create("Frame", {
            Name = "Highlight",
            Size = UDim2.new(0, 2, 1, -10),
            Position = UDim2.new(0, 0, 0, 5),
            BackgroundColor3 = MRX_Library.Theme.Accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Parent = TabButton
        })
        Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TabHighlight })

        local PageView = Utility:Create("ScrollingFrame", {
            Name = TabName .. "_Page",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = MRX_Library.Theme.Accent,
            Visible = false,
            Parent = PageContainer
        })
        
        Utility:Create("UIListLayout", { 
            SortOrder = Enum.SortOrder.LayoutOrder, 
            Padding = UDim.new(0, 10), 
            Parent = PageView 
        })

        if not CurrentTab then
            CurrentTab = TabButton
            PageView.Visible = true
            TabButton.BackgroundTransparency = 0
            TabButton.TextColor3 = MRX_Library.Theme.Text
            TabHighlight.BackgroundTransparency = 0
        end

        TabButton.MouseButton1Click:Connect(function()
            if CurrentTab ~= TabButton then
                for _, child in pairs(TabList:GetChildren()) do
                    if child:IsA("TextButton") then
                        Utility:Tween(child, {BackgroundTransparency = 1, TextColor3 = MRX_Library.Theme.TextMuted}, 0.2)
                        Utility:Tween(child.Highlight, {BackgroundTransparency = 1}, 0.2)
                    end
                end
                for _, child in pairs(PageContainer:GetChildren()) do
                    child.Visible = false
                end
                
                CurrentTab = TabButton
                Utility:Tween(TabButton, {BackgroundTransparency = 0, TextColor3 = MRX_Library.Theme.Text}, 0.2)
                Utility:Tween(TabHighlight, {BackgroundTransparency = 0}, 0.2)
                
                PageView.Visible = true
                -- Transition effect for page
                PageView.Position = UDim2.new(0, 20, 0, 10)
                Utility:Tween(PageView, {Position = UDim2.new(0, 10, 0, 10)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end)
        local TabObj = {}
        
        function TabObj:CreateSection(options)
            local SectionName = options.Name or "Section"
            
            local SectionFrame = Utility:Create("Frame", {
                Name = SectionName,
                Size = UDim2.new(1, 0, 0, 30), -- Initial size
                BackgroundColor3 = MRX_Library.Theme.SectionBackground,
                BorderSizePixel = 0,
                Parent = PageView
            })
            Utility:Create("UICorner", { CornerRadius = UDim.new(0, MRX_Library.Theme.Rounding), Parent = SectionFrame })
            
            local SectionLabel = Utility:Create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -20, 0, 30),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = SectionName,
                TextColor3 = MRX_Library.Theme.Text,
                Font = MRX_Library.Settings.Font,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SectionFrame
            })
            
            local SectionContainer = Utility:Create("Frame", {
                Name = "Container",
                Size = UDim2.new(1, -20, 1, -35),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundTransparency = 1,
                Parent = SectionFrame
            })
            
            local ContainerLayout = Utility:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                Parent = SectionContainer
            })
            
            -- Auto Resize
            ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Utility:Tween(SectionFrame, {Size = UDim2.new(1, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 40)}, 0.2)
            end)
            
            local SectionObj = {}
            
            function SectionObj:CreateButton(options)
                local BtnName = options.Name or "Button"
                local Callback = options.Callback or function() end
                
                local ButtonFrame = Utility:Create("Frame", {
                    Name = BtnName,
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    Parent = SectionContainer
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, MRX_Library.Theme.Rounding - 2), Parent = ButtonFrame })
                
                local ButtonText = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = BtnName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    Parent = ButtonFrame
                })
                
                local ButtonClick = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ButtonFrame
                })
                
                Utility:AddRipple(ButtonClick)
                
                ButtonClick.MouseEnter:Connect(function()
                    Utility:Tween(ButtonFrame, {BackgroundColor3 = MRX_Library.Theme.AccentHover}, 0.2)
                    Utility:Tween(ButtonText, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                end)
                
                ButtonClick.MouseLeave:Connect(function()
                    Utility:Tween(ButtonFrame, {BackgroundColor3 = MRX_Library.Theme.Background}, 0.2)
                    Utility:Tween(ButtonText, {TextColor3 = MRX_Library.Theme.Text}, 0.2)
                end)
                
                ButtonClick.MouseButton1Click:Connect(function()
                    task.spawn(Callback)
                end)
            end
            
            function SectionObj:CreateToggle(options)
                local TglName = options.Name or "Toggle"
                local Flag = options.Flag or tostring(math.random(1, 100000))
                local Default = options.Default or false
                local Callback = options.Callback or function() end
                
                MRX_Library.Flags[Flag] = Default
                
                local ToggleFrame = Utility:Create("Frame", {
                    Name = TglName,
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = SectionContainer
                })
                
                local Title = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = TglName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleFrame
                })
                
                local Outer = Utility:Create("Frame", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -40, 0.5, -10),
                    BackgroundColor3 = Default and MRX_Library.Theme.Accent or MRX_Library.Theme.Background,
                    Parent = ToggleFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Outer })
                
                local Inner = Utility:Create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = Default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Outer
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Inner })
                
                local Glow = Utility:AddGlow(Outer, MRX_Library.Theme.Accent, 10)
                Glow.ImageTransparency = Default and 0.5 or 1
                
                local ToggleButton = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ToggleFrame
                })
                
                local function FireToggle()
                    MRX_Library.Flags[Flag] = not MRX_Library.Flags[Flag]
                    local state = MRX_Library.Flags[Flag]
                    
                    if state then
                        Utility:Tween(Outer, {BackgroundColor3 = MRX_Library.Theme.Accent}, 0.25)
                        Utility:Tween(Inner, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
                        Utility:Tween(Glow, {ImageTransparency = 0.5}, 0.25)
                        Utility:Tween(Title, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                    else
                        Utility:Tween(Outer, {BackgroundColor3 = MRX_Library.Theme.Background}, 0.25)
                        Utility:Tween(Inner, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.25, Enum.EasingStyle.Back)
                        Utility:Tween(Glow, {ImageTransparency = 1}, 0.25)
                        Utility:Tween(Title, {TextColor3 = MRX_Library.Theme.TextMuted}, 0.2)
                    end
                    task.spawn(Callback, state)
                end
                
                ToggleButton.MouseButton1Click:Connect(FireToggle)
                -- Initial Callback
                task.spawn(Callback, Default)
            end

            -- SLIDER
            function SectionObj:CreateSlider(options)
                local SldName = options.Name or "Slider"
                local Flag = options.Flag or tostring(math.random(1, 100000))
                local Min = options.Min or 0
                local Max = options.Max or 100
                local Default = options.Default or Min
                local Float = options.Float or 0.1
                local Callback = options.Callback or function() end
                
                MRX_Library.Flags[Flag] = Default
                
                local SliderFrame = Utility:Create("Frame", {
                    Name = SldName,
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundTransparency = 1,
                    Parent = SectionContainer
                })
                
                local Title = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 20),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = SldName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SliderFrame
                })
                
                local ValueLabel = Utility:Create("TextLabel", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -40, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(Default),
                    TextColor3 = MRX_Library.Theme.Accent,
                    Font = Enum.Font.Code,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = SliderFrame
                })
                
                local SliderBg = Utility:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 28),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    Parent = SliderFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBg })
                
                local Fill = Utility:Create("Frame", {
                    Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0),
                    BackgroundColor3 = MRX_Library.Theme.Accent,
                    Parent = SliderBg
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
                
                local Glow = Utility:AddGlow(Fill, MRX_Library.Theme.Accent, 10)
                Glow.ImageTransparency = 0.6
                
                local Dot = Utility:Create("Frame", {
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(1, -6, 0.5, -6),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Fill
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Dot })
                
                local SliderBtn = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = SliderBg
                })
                
                local dragging = false
                
                local function Update(input)
                    local sizeX = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                    local value = Min + ((Max - Min) * sizeX)
                    
                    if Float > 0 then
                        value = math.floor(value / Float) * Float
                    else
                        value = math.floor(value)
                    end
                    
                    value = math.clamp(value, Min, Max)
                    sizeX = (value - Min) / (Max - Min)
                    
                    Utility:Tween(Fill, {Size = UDim2.new(sizeX, 0, 1, 0)}, 0.1)
                    
                    if tostring(value):find("%.") then
                        ValueLabel.Text = string.format("%." .. tostring(Float):len() - 2 .. "f", value)
                    else
                        ValueLabel.Text = tostring(value)
                    end
                    
                    MRX_Library.Flags[Flag] = value
                    task.spawn(Callback, value)
                end
                
                SliderBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Utility:Tween(Dot, {Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0.5, -8)}, 0.2)
                        Utility:Tween(Glow, {ImageTransparency = 0.2}, 0.2)
                        Update(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                        dragging = false
                        Utility:Tween(Dot, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)}, 0.2)
                        Utility:Tween(Glow, {ImageTransparency = 0.6}, 0.2)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(input)
                    end
                end)
                
                task.spawn(Callback, Default)
            end
            
            -- Keep adding elements
            function SectionObj:CreateLabel(options)
                local TitleName = options.Name or "Label"
                
                local LabelFrame = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = TitleName,
                    TextColor3 = MRX_Library.Theme.TextMuted,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SectionContainer
                })
                
                return LabelFrame
            end


            function SectionObj:CreateDropdown(options)
                local DrpName = options.Name or "Dropdown"
                local Flag = options.Flag or tostring(math.random(1, 100000))
                local List = options.List or {}
                local Default = options.Default or ""
                local Callback = options.Callback or function() end
                
                MRX_Library.Flags[Flag] = Default
                
                local DropdownFrame = Utility:Create("Frame", {
                    Name = DrpName,
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    Parent = SectionContainer
                })
                
                local Title = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 20),
                    BackgroundTransparency = 1,
                    Text = DrpName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DropdownFrame
                })
                
                local SelectedLabel = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    Text = Default == "" and "Select..." or Default,
                    TextColor3 = MRX_Library.Theme.TextMuted,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    Parent = DropdownFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SelectedLabel })
                
                local DropdownBtn = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = SelectedLabel
                })
                
                local Icon = Utility:Create("TextLabel", {
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -20, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "+",
                    TextColor3 = MRX_Library.Theme.TextMuted,
                    Font = Enum.Font.Code,
                    TextSize = 16,
                    Parent = SelectedLabel
                })
                
                local DropdownContainer = Utility:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 45),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 5,
                    Parent = DropdownFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = DropdownContainer })
                
                local DropdownList = Utility:Create("ScrollingFrame", {
                    Size = UDim2.new(1, -5, 1, -5),
                    Position = UDim2.new(0, 2, 0, 2),
                    BackgroundTransparency = 1,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = MRX_Library.Theme.Accent,
                    ZIndex = 6,
                    Parent = DropdownContainer
                })
                local ListLayout = Utility:Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = DropdownList })
                
                local isOpen = false
                
                local function BuildList(newList)
                    for _, child in pairs(DropdownList:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    
                    for i, v in ipairs(newList) do
                        local OptBtn = Utility:Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 25),
                            BackgroundColor3 = MRX_Library.Theme.SectionBackground,
                            BackgroundTransparency = 1,
                            Text = tostring(v),
                            TextColor3 = MRX_Library.Theme.TextMuted,
                            Font = MRX_Library.Settings.Font,
                            TextSize = 13,
                            ZIndex = 7,
                            Parent = DropdownList
                        })
                        Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OptBtn })
                        
                        OptBtn.MouseEnter:Connect(function()
                            Utility:Tween(OptBtn, {BackgroundTransparency = 0, TextColor3 = MRX_Library.Theme.Text}, 0.2)
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            if MRX_Library.Flags[Flag] ~= v then
                                Utility:Tween(OptBtn, {BackgroundTransparency = 1, TextColor3 = MRX_Library.Theme.TextMuted}, 0.2)
                            end
                        end)
                        
                        OptBtn.MouseButton1Click:Connect(function()
                            isOpen = false
                            Utility:Tween(DropdownContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                            Utility:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
                            Utility:Tween(Icon, {Rotation = 0}, 0.2)
                            task.wait(0.2)
                            DropdownContainer.Visible = false
                            
                            SelectedLabel.Text = tostring(v)
                            SelectedLabel.TextColor3 = MRX_Library.Theme.Text
                            MRX_Library.Flags[Flag] = v
                            task.spawn(Callback, v)
                            
                            -- Reset visuals
                            for _, child in pairs(DropdownList:GetChildren()) do
                                if child:IsA("TextButton") then
                                    if child.Text ~= v then
                                        Utility:Tween(child, {BackgroundTransparency = 1, TextColor3 = MRX_Library.Theme.TextMuted}, 0.2)
                                    else
                                        Utility:Tween(child, {BackgroundTransparency = 0, TextColor3 = MRX_Library.Theme.Accent}, 0.2)
                                    end
                                end
                            end
                        end)
                        
                        if Default == v then
                            OptBtn.BackgroundTransparency = 0
                            OptBtn.TextColor3 = MRX_Library.Theme.Accent
                        end
                    end
                    DropdownList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
                end
                
                BuildList(List)
                
                DropdownBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        DropdownContainer.Visible = true
                        local listHeight = math.clamp(ListLayout.AbsoluteContentSize.Y + 5, 0, 100)
                        Utility:Tween(DropdownContainer, {Size = UDim2.new(1, 0, 0, listHeight)}, 0.2)
                        Utility:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40 + listHeight + 5)}, 0.2)
                        Utility:Tween(Icon, {Rotation = 45}, 0.2)
                    else
                        Utility:Tween(DropdownContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        Utility:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
                        Utility:Tween(Icon, {Rotation = 0}, 0.2)
                        task.wait(0.2)
                        DropdownContainer.Visible = false
                    end
                end)
                
                task.spawn(Callback, Default)
            end
            
            function SectionObj:CreateTextBox(options)
                local TxtName = options.Name or "TextBox"
                local Flag = options.Flag or tostring(math.random(1, 100000))
                local Default = options.Default or ""
                local PlaceholderText = options.Placeholder or "Enter text..."
                local ClearOnFocus = options.ClearOnFocus or false
                local Callback = options.Callback or function() end
                
                MRX_Library.Flags[Flag] = Default
                
                local TextBoxFrame = Utility:Create("Frame", {
                    Name = TxtName,
                    Size = UDim2.new(1, 0, 0, 45),
                    BackgroundTransparency = 1,
                    Parent = SectionContainer
                })
                
                local Title = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 20),
                    BackgroundTransparency = 1,
                    Text = TxtName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = TextBoxFrame
                })
                
                local TextBoxBg = Utility:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 25),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    Parent = TextBoxFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TextBoxBg })
                
                local Box = Utility:Create("TextBox", {
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    Text = Default,
                    PlaceholderText = PlaceholderText,
                    PlaceholderColor3 = MRX_Library.Theme.TextMuted,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    ClearTextOnFocus = ClearOnFocus,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = TextBoxBg
                })
                
                Box.Focused:Connect(function()
                    Utility:Tween(TextBoxBg, {BackgroundColor3 = MRX_Library.Theme.SectionBackground}, 0.2)
                    -- small outline glow effect
                end)
                
                Box.FocusLost:Connect(function()
                    Utility:Tween(TextBoxBg, {BackgroundColor3 = MRX_Library.Theme.Background}, 0.2)
                    MRX_Library.Flags[Flag] = Box.Text
                    task.spawn(Callback, Box.Text)
                end)
            end
            
            function SectionObj:CreateKeybind(options)
                local KbName = options.Name or "Keybind"
                local Flag = options.Flag or tostring(math.random(1, 100000))
                local Default = options.Default or Enum.KeyCode.Unknown
                local Callback = options.Callback or function() end
                
                MRX_Library.Flags[Flag] = Default
                local binding = false
                
                local KeybindFrame = Utility:Create("Frame", {
                    Name = KbName,
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = SectionContainer
                })
                
                local Title = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -80, 1, 0),
                    BackgroundTransparency = 1,
                    Text = KbName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeybindFrame
                })
                
                local KeyBg = Utility:Create("Frame", {
                    Size = UDim2.new(0, 70, 0, 20),
                    Position = UDim2.new(1, -70, 0.5, -10),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    Parent = KeybindFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = KeyBg })
                
                local KeyLabel = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Default == Enum.KeyCode.Unknown and "None" or Default.Name,
                    TextColor3 = MRX_Library.Theme.TextMuted,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 12,
                    Parent = KeyBg
                })
                
                local KeyBtn = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = KeyBg
                })
                
                KeyBtn.MouseButton1Click:Connect(function()
                    if not binding then
                        binding = true
                        KeyLabel.Text = "..."
                        KeyLabel.TextColor3 = MRX_Library.Theme.Accent
                    end
                end)
                
                UserInputService.InputBegan:Connect(function(input)
                    if binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            if input.KeyCode == Enum.KeyCode.Escape then
                                MRX_Library.Flags[Flag] = Enum.KeyCode.Unknown
                                KeyLabel.Text = "None"
                            else
                                MRX_Library.Flags[Flag] = input.KeyCode
                                KeyLabel.Text = input.KeyCode.Name
                            end
                            KeyLabel.TextColor3 = MRX_Library.Theme.TextMuted
                            Utility:Tween(KeyBg, {BackgroundColor3 = MRX_Library.Theme.Background}, 0.2)
                            binding = false
                            -- Передаём новый KeyCode в callback (замена клавиши)
                            task.spawn(Callback, MRX_Library.Flags[Flag])
                        end
                    elseif input.UserInputType == Enum.UserInputType.Keyboard
                        and input.KeyCode == MRX_Library.Flags[Flag]
                        and MRX_Library.Flags[Flag] ~= Enum.KeyCode.Unknown then
                        -- Передаём тот же KeyCode — теперь тип всегда EnumItem, без парадоксов
                        task.spawn(Callback, input.KeyCode)
                    end
                end)
            end
            function SectionObj:CreateColorPicker(options)
                local CpName = options.Name or "Color Picker"
                local Flag = options.Flag or tostring(math.random(1, 100000))
                local Default = options.Default or Color3.fromRGB(255, 255, 255)
                local Callback = options.Callback or function() end
                
                MRX_Library.Flags[Flag] = Default
                
                local ColorPickerFrame = Utility:Create("Frame", {
                    Name = CpName,
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = SectionContainer
                })
                
                local Title = Utility:Create("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = CpName,
                    TextColor3 = MRX_Library.Theme.Text,
                    Font = MRX_Library.Settings.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ColorPickerFrame
                })
                
                local ColorDisplay = Utility:Create("Frame", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -40, 0.5, -10),
                    BackgroundColor3 = Default,
                    Parent = ColorPickerFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ColorDisplay })
                
                local Glow = Utility:AddGlow(ColorDisplay, Default, 10)
                Glow.ImageTransparency = 0.5
                
                local ColorBtn = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ColorDisplay
                })
                
                local PickerContainer = Utility:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 35),
                    BackgroundColor3 = MRX_Library.Theme.Background,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    Visible = false,
                    ZIndex = 5,
                    Parent = ColorPickerFrame
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = PickerContainer })
                
                local HueSat = Utility:Create("ImageLabel", {
                    Size = UDim2.new(1, -30, 1, -10),
                    Position = UDim2.new(0, 5, 0, 5),
                    Image = "rbxassetid://4155801252",
                    ZIndex = 6,
                    Parent = PickerContainer
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HueSat })
                
                local ValueSlider = Utility:Create("Frame", {
                    Size = UDim2.new(0, 15, 1, -10),
                    Position = UDim2.new(1, -20, 0, 5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 6,
                    Parent = PickerContainer
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ValueSlider })
                local ValueGradient = Utility:Create("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
                    }),
                    Parent = ValueSlider
                })
                
                local PickerBtn = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 7,
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = HueSat
                })
                
                local ValueBtn = Utility:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 7,
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = ValueSlider
                })
                
                local Cursor = Utility:Create("Frame", {
                    Size = UDim2.new(0, 6, 0, 6),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    ZIndex = 8,
                    Parent = HueSat
                })
                Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Cursor })
                
                local ValCursor = Utility:Create("Frame", {
                    Size = UDim2.new(1, 4, 0, 4),
                    Position = UDim2.new(0, -2, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 1,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 8,
                    Parent = ValueSlider
                })
                
                local isOpen = false
                local h, s, v = Color3.toHSV(Default)
                
                local function UpdateColor()
                    local col = Color3.fromHSV(h, s, v)
                    ColorDisplay.BackgroundColor3 = col
                    Glow.ImageColor3 = col
                    ValueGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
                    })
                    MRX_Library.Flags[Flag] = col
                    task.spawn(Callback, col)
                end
                
                local picking = false
                local valPicking = false
                
                PickerBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        picking = true
                        local pos = math.clamp((input.Position.X - HueSat.AbsolutePosition.X) / HueSat.AbsoluteSize.X, 0, 1)
                        local posy = math.clamp((input.Position.Y - HueSat.AbsolutePosition.Y) / HueSat.AbsoluteSize.Y, 0, 1)
                        h = 1 - pos
                        s = 1 - posy
                        Cursor.Position = UDim2.new(pos, 0, posy, 0)
                        UpdateColor()
                    end
                end)
                
                ValueBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        valPicking = true
                        local posy = math.clamp((input.Position.Y - ValueSlider.AbsolutePosition.Y) / ValueSlider.AbsoluteSize.Y, 0, 1)
                        v = 1 - posy
                        ValCursor.Position = UDim2.new(0, -2, posy, 0)
                        UpdateColor()
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if picking then
                            local pos = math.clamp((input.Position.X - HueSat.AbsolutePosition.X) / HueSat.AbsoluteSize.X, 0, 1)
                            local posy = math.clamp((input.Position.Y - HueSat.AbsolutePosition.Y) / HueSat.AbsoluteSize.Y, 0, 1)
                            h = 1 - pos
                            s = 1 - posy
                            Cursor.Position = UDim2.new(pos, 0, posy, 0)
                            UpdateColor()
                        elseif valPicking then
                            local posy = math.clamp((input.Position.Y - ValueSlider.AbsolutePosition.Y) / ValueSlider.AbsoluteSize.Y, 0, 1)
                            v = 1 - posy
                            ValCursor.Position = UDim2.new(0, -2, posy, 0)
                            UpdateColor()
                        end
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        picking = false
                        valPicking = false
                    end
                end)
                
                ColorBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        PickerContainer.Visible = true
                        Utility:Tween(PickerContainer, {Size = UDim2.new(1, 0, 0, 100)}, 0.2)
                        Utility:Tween(ColorPickerFrame, {Size = UDim2.new(1, 0, 0, 140)}, 0.2)
                    else
                        Utility:Tween(PickerContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        Utility:Tween(ColorPickerFrame, {Size = UDim2.new(1, 0, 0, 32)}, 0.2)
                        task.wait(0.2)
                        PickerContainer.Visible = false
                    end
                end)
                
                h, s, v = Color3.toHSV(Default)
                Cursor.Position = UDim2.new(1 - h, 0, 1 - s, 0)
                ValCursor.Position = UDim2.new(0, -2, 1 - v, 0)
                UpdateColor()
            end
            
            return SectionObj
        end
        return TabObj
    end
    return WindowObj
end

-- [ Configuration System ] -------------------------------------------------------------------------------------------------------------------------------
MRX_Library.ConfigSystem = {}

function MRX_Library.ConfigSystem:Save(name)
    local config = {}
    for flag, value in pairs(MRX_Library.Flags) do
        if typeof(value) == "Color3" then
            config[flag] = {Color = {value.R, value.G, value.B}}
        elseif typeof(value) == "EnumItem" then
            config[flag] = {Enum = value.Name}
        else
            config[flag] = value
        end
    end
    
    local encoded = HttpService:JSONEncode(config)
    if not isfolder("MRX_DeathGod") then makefolder("MRX_DeathGod") end
    writefile("MRX_DeathGod/" .. name .. ".json", encoded)
    
    MRX_Library:Notify({
        Title = "Config System",
        Text = "Successfully saved configuration: " .. name,
        Duration = 3,
        Type = "Success"
    })
end

function MRX_Library.ConfigSystem:Load(name)
    local path = "MRX_DeathGod/" .. name .. ".json"
    if isfile(path) then
        local raw = readfile(path)
        local decoded = HttpService:JSONDecode(raw)
        
        for flag, value in pairs(decoded) do
            if typeof(value) == "table" and value.Color then
                MRX_Library.Flags[flag] = Color3.new(value.Color[1], value.Color[2], value.Color[3])
            elseif typeof(value) == "table" and value.Enum then
                MRX_Library.Flags[flag] = Enum.KeyCode[value.Enum]
            else
                MRX_Library.Flags[flag] = value
            end
        end
        
        MRX_Library:Notify({
            Title = "Config System",
            Text = "Successfully loaded configuration: " .. name,
            Duration = 3,
            Type = "Success"
        })
    else
        MRX_Library:Notify({
            Title = "Config System",
            Text = "Configuration file not found.",
            Duration = 3,
            Type = "Error"
        })
    end
end

-- [ Watermarks & Final Setup ] ---------------------------------------------------------------------------------------------------------------------------
local WatermarkFrame = Utility:Create("Frame", {
    Name = "Watermark",
    Size = UDim2.new(0, 250, 0, 25),
    Position = UDim2.new(0, 15, 0, 15),
    BackgroundColor3 = MRX_Library.Theme.SectionBackground,
    Parent = MRX_ScreenGui
})
Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = WatermarkFrame })
Utility:AddGlow(WatermarkFrame, MRX_Library.Theme.Accent, 10)

local WatermarkLine = Utility:Create("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = MRX_Library.Theme.Accent,
    BorderSizePixel = 0,
    Parent = WatermarkFrame
})

local WatermarkText = Utility:Create("TextLabel", {
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "MRX_TBUH_GUI | FPS: 0 | Ping: 0",
    TextColor3 = MRX_Library.Theme.Text,
    Font = Enum.Font.Code,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = WatermarkFrame
})

task.spawn(function()
    while true do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        WatermarkText.Text = "MRX_TBUH_GUI | FPS: " .. fps .. " | Ping: " .. ping .. "ms"
    end
end)

-- Initialize Library
getgenv().MRX_Library = MRX_Library
return MRX_Library
