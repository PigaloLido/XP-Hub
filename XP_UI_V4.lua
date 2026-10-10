local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UI_NAME = "XPHub_UI"
local UI_TITLE = "XP Hub | Premium"
local UI_CREDIT = "By : Pigalo"
local UI_VERSION = "v1.0.0"

local CoreGuiSuccess, CoreGui = pcall(function() return game:GetService("CoreGui") end)
local OldUI = (CoreGuiSuccess and CoreGui and CoreGui:FindFirstChild(UI_NAME)) or PlayerGui:FindFirstChild(UI_NAME)

if OldUI then
    warn("The script is already running!")
    return nil
end

local ConfigFolder = "XPHub_Configs"
if isfolder and makefolder and not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

local XPHub = {
    Elements = {},
    ConfigData = {},
    Objects = {},
    ConfigFolder = ConfigFolder
}

local activeDropdownList = nil
local activeDropdownArrow = nil
local MainFrame = nil
local StartBtn = nil
local IsBinding = false

function XPHub:CheckPlaceId(allowedMaps)
    if type(allowedMaps) ~= "table" then return true end
    local currentId = game.PlaceId
    for _, id in ipairs(allowedMaps) do
        if currentId == id then
            return true
        end
    end
    LocalPlayer:Kick("Unsupported Game | PlaceId: " .. tostring(currentId))
    return false
end

function XPHub:GetConfigList()
    if not listfiles or not isfolder or not isfolder(ConfigFolder) then return {} end
    local files = listfiles(ConfigFolder)
    local names = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local cleanPath = file:gsub("\\", "/")
            local nameWithExtension = cleanPath:gsub(ConfigFolder .. "/", "")
            local finalName = nameWithExtension:gsub(".json", "")
            table.insert(names, finalName)
        end
    end
    return names
end

function XPHub:SaveCurrentConfig(name)
    if not name or name == "" or not writefile then return end
    local json = HttpService:JSONEncode(XPHub.ConfigData)
    writefile(ConfigFolder .. "/" .. name .. ".json", json)
end

local function ApplySettings(data)
    for id, value in pairs(data) do
        local obj = XPHub.Objects[id]
        if obj then
            if obj.Update then obj.Update(value) end
            if obj.Callback then
                task.spawn(function()
                    obj.Callback(value)
                end)
            end
        end
    end
end

function XPHub:LoadConfigData(name)
    if not isfile or not readfile then return nil end
    local fileName = ConfigFolder .. "/" .. name .. ".json"
    if isfile(fileName) then
        local json = readfile(fileName)
        local data = HttpService:JSONDecode(json)
        for id, value in pairs(data) do
            XPHub.ConfigData[id] = value
        end
        ApplySettings(data)
        return data
    end
    return nil
end

local function UpdateState(id, value)
    if id then
        XPHub.ConfigData[id] = value
    end
end

function XPHub:ResetAllSettings()
    for _, obj in pairs(XPHub.Objects) do
        if obj.Type == "Keybind" then
            pcall(function()
                if obj.Stop then
                    obj.Stop()
                elseif obj.Connection then
                    obj.Connection:Disconnect()
                end
            end)
            continue
        end

        if obj.Callback then
            local defaultValue = nil
            if obj.Type == "Slider" then
                defaultValue = (obj.Config and obj.Config.Min) or 0
            elseif obj.Type == "Toggle" then
                defaultValue = false
            elseif obj.Type == "Dropdown" then
                defaultValue = obj.Default or ""
            elseif obj.Type == "MultiSelect" then
                defaultValue = {}
            elseif obj.Type == "Input" then
                defaultValue = ""
            end

            if defaultValue ~= nil then
                task.spawn(function()
                    pcall(function()
                        obj.Callback(defaultValue)
                    end)
                end)
            end

            if obj.Update then
                pcall(function()
                    obj.Update(defaultValue)
                end)
            end
        end
    end
end

local AutoloadFile = ConfigFolder .. "/autoload.txt"
function XPHub:SetAutoload(name)
    if writefile then writefile(AutoloadFile, name) end
end

function XPHub:GetAutoload()
    return (isfile and readfile and isfile(AutoloadFile)) and readfile(AutoloadFile) or nil
end

function XPHub:ResetAutoload()
    if isfile and delfile and isfile(AutoloadFile) then delfile(AutoloadFile) end
end

local Colors = {
    WindowBg        = Color3.fromRGB(20, 20, 22),
    TopBarBg        = Color3.fromRGB(26, 26, 29),
    SidebarBg       = Color3.fromRGB(24, 24, 27),
    SectionHeaderBg = Color3.fromRGB(30, 30, 34),
    CardBg          = Color3.fromRGB(32, 32, 36),
    CardHover       = Color3.fromRGB(38, 38, 43),
    InputBg         = Color3.fromRGB(22, 22, 25),
    DropdownBg      = Color3.fromRGB(26, 26, 30),

    Accent          = Color3.fromRGB(45, 125, 245),
    AccentHover     = Color3.fromRGB(65, 140, 255),

    Text            = Color3.fromRGB(240, 240, 240),
    SubText         = Color3.fromRGB(155, 155, 165),
    MutedText       = Color3.fromRGB(105, 105, 115),

    Border          = Color3.fromRGB(50, 50, 56),
    BorderFocus     = Color3.fromRGB(80, 80, 90),

    CloseRed        = Color3.fromRGB(210, 45, 50),
    ControlBtn      = Color3.fromRGB(42, 42, 48),

    SwitchOn        = Color3.fromRGB(45, 125, 245),
    SwitchOff       = Color3.fromRGB(58, 58, 66),

    ButtonBg        = Color3.fromRGB(48, 48, 55),
    ButtonHover     = Color3.fromRGB(62, 62, 70),
    ButtonPress     = Color3.fromRGB(38, 38, 44),
    White           = Color3.fromRGB(255, 255, 255)
}

local SizeItem = {
    BoxItem   = UDim2.new(1, -4, 0, 56),
    TitleItem = UDim2.new(1, -4, 0, 42)
}

local function CloseAllDropdowns()
    if activeDropdownList then
        activeDropdownList.Visible = false
        activeDropdownList = nil
    end
    if activeDropdownArrow then
        TweenService:Create(activeDropdownArrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
        activeDropdownArrow = nil
    end
end
XPHub.CloseAllDropdowns = CloseAllDropdowns

local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function MakeDraggable(obj, dragPart)
    local dragging, dragStart, startPos
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function MakeResizable(obj, dragPart)
    local dragging = false
    local dragStart = nil
    local startSize = nil

    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startSize = obj.Size
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newWidth = math.max(520, startSize.X.Offset + delta.X)
            local newHeight = math.max(350, startSize.Y.Offset + delta.Y)
            obj.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local wasDragging = false
local lastScreenRatioX = 0.5
local lastScreenRatioY = 0.05

local function MakeDraggableStartBtn(obj, dragPart)
    local dragging = false
    local dragStart, startPos

    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDragging = false
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                wasDragging = true
            end

            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            local parentScreen = obj:FindFirstAncestorOfClass("ScreenGui")
            if parentScreen then
                local screenSize = parentScreen.AbsoluteSize
                local btnSize = obj.AbsoluteSize
                local currentX = newPos.X.Offset + (screenSize.X * newPos.X.Scale)
                local currentY = newPos.Y.Offset + (screenSize.Y * newPos.Y.Scale)
                local finalX = math.clamp(currentX, 6, math.max(6, screenSize.X - btnSize.X - 6))
                local finalY = math.clamp(currentY, 6, math.max(6, screenSize.Y - btnSize.Y - 6))

                obj.Position = UDim2.new(0, finalX, 0, finalY)
                if screenSize.X - btnSize.X > 0 then lastScreenRatioX = finalX / (screenSize.X - btnSize.X) end
                if screenSize.Y - btnSize.Y > 0 then lastScreenRatioY = finalY / (screenSize.Y - btnSize.Y) end
            else
                obj.Position = newPos
            end
        end
    end)
end

local function AdjustStartBtnByRatio(obj)
    local parentScreen = obj:FindFirstAncestorOfClass("ScreenGui")
    if parentScreen and obj.Visible then
        local screenSize = parentScreen.AbsoluteSize
        local btnSize = obj.AbsoluteSize
        local targetX = lastScreenRatioX * (screenSize.X - btnSize.X)
        local targetY = lastScreenRatioY * (screenSize.Y - btnSize.Y)

        TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, math.clamp(targetX, 6, math.max(6, screenSize.X - btnSize.X - 6)), 0, math.clamp(targetY, 6, math.max(6, screenSize.Y - btnSize.Y - 6)))
        }):Play()
    end
end

function XPHub:Window(GuiConfig)
    GuiConfig = GuiConfig or {}
    local window = {Tabs = {}, CountTab = 0}

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = UI_NAME
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.DisplayOrder = 9999

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    elseif CoreGuiSuccess and CoreGui then
        local ok = pcall(function() ScreenGui.Parent = CoreGui end)
        if not ok then ScreenGui.Parent = PlayerGui end
    else
        ScreenGui.Parent = PlayerGui
    end

    MainFrame = Instance.new("Frame")
    XPHub.MainFrame = MainFrame
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 650, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -325, 0.5, -230)
    MainFrame.BackgroundColor3 = Colors.WindowBg
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 1
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    AddStroke(MainFrame, Colors.Border, 1)

    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
    ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.ZIndex = 5000
    ResizeHandle.Parent = MainFrame

    local ResizeLine1 = Instance.new("Frame")
    ResizeLine1.Size = UDim2.new(0, 10, 0, 2)
    ResizeLine1.Position = UDim2.new(1, -12, 1, -6)
    ResizeLine1.Rotation = -45
    ResizeLine1.BackgroundColor3 = Colors.MutedText
    ResizeLine1.BorderSizePixel = 0
    ResizeLine1.ZIndex = 4999
    ResizeLine1.Parent = ResizeHandle

    local ResizeLine2 = Instance.new("Frame")
    ResizeLine2.Size = UDim2.new(0, 6, 0, 2)
    ResizeLine2.Position = UDim2.new(1, -8, 1, -6)
    ResizeLine2.Rotation = -45
    ResizeLine2.BackgroundColor3 = Colors.MutedText
    ResizeLine2.BorderSizePixel = 0
    ResizeLine2.ZIndex = 4999
    ResizeLine2.Parent = ResizeHandle

    MakeResizable(MainFrame, ResizeHandle)

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Colors.TopBarBg
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 1115
    TopBar.Parent = MainFrame
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

    local TopBarFix = Instance.new("Frame")
    TopBarFix.Size = UDim2.new(1, 0, 0, 8)
    TopBarFix.Position = UDim2.new(0, 0, 1, -8)
    TopBarFix.BackgroundColor3 = Colors.TopBarBg
    TopBarFix.BorderSizePixel = 0
    TopBarFix.ZIndex = 1115
    TopBarFix.Parent = TopBar

    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 1, -1)
    TopLine.BackgroundColor3 = Colors.Border
    TopLine.BorderSizePixel = 0
    TopLine.ZIndex = 1116
    TopLine.Parent = TopBar

    local TopLogo = Instance.new("ImageLabel")
    TopLogo.Name = "TopLogo"
    TopLogo.Size = UDim2.new(0, 22, 0, 22)
    TopLogo.Position = UDim2.new(0, 12, 0.5, 0)
    TopLogo.AnchorPoint = Vector2.new(0, 0.5)
    TopLogo.Image = "rbxassetid://106080187166557"
    TopLogo.BackgroundTransparency = 1
    TopLogo.ZIndex = 1116
    TopLogo.Parent = TopBar

    local TitleContainer = Instance.new("Frame")
    TitleContainer.Name = "TitleContainer"
    TitleContainer.Size = UDim2.new(1, -160, 1, 0)
    TitleContainer.Position = UDim2.new(0, 42, 0, 0)
    TitleContainer.BackgroundTransparency = 1
    TitleContainer.ZIndex = 1116
    TitleContainer.Parent = TopBar

    local TitleLayout = Instance.new("UIListLayout")
    TitleLayout.FillDirection = Enum.FillDirection.Horizontal
    TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TitleLayout.Padding = UDim.new(0, 8)
    TitleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TitleLayout.Parent = TitleContainer

    local HubTitle = Instance.new("TextLabel")
    HubTitle.Text = GuiConfig.Title or UI_TITLE
    HubTitle.Font = Enum.Font.GothamBold
    HubTitle.TextSize = 15
    HubTitle.TextColor3 = Colors.Text
    HubTitle.Size = UDim2.new(0, 0, 1, 0)
    HubTitle.AutomaticSize = Enum.AutomaticSize.X
    HubTitle.BackgroundTransparency = 1
    HubTitle.ZIndex = 1116
    HubTitle.LayoutOrder = 1
    HubTitle.Parent = TitleContainer

    local CreditTitle = Instance.new("TextLabel")
    CreditTitle.Text = UI_CREDIT
    CreditTitle.Font = Enum.Font.Gotham
    CreditTitle.TextSize = 12
    CreditTitle.TextColor3 = Colors.SubText
    CreditTitle.Size = UDim2.new(0, 0, 1, 0)
    CreditTitle.AutomaticSize = Enum.AutomaticSize.X
    CreditTitle.BackgroundTransparency = 1
    CreditTitle.ZIndex = 1116
    CreditTitle.LayoutOrder = 2
    CreditTitle.Parent = TitleContainer

    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Name = "VersionLabel"
    VersionLabel.Text = "| " .. UI_VERSION
    VersionLabel.Font = Enum.Font.Code
    VersionLabel.TextSize = 12
    VersionLabel.TextColor3 = Colors.MutedText
    VersionLabel.Size = UDim2.new(0, 0, 1, 0)
    VersionLabel.AutomaticSize = Enum.AutomaticSize.X
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.ZIndex = 1116
    VersionLabel.LayoutOrder = 3
    VersionLabel.Parent = TitleContainer

    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(0, 100, 1, 0)
    Controls.Position = UDim2.new(1, -8, 0, 0)
    Controls.AnchorPoint = Vector2.new(1, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 1117
    Controls.Parent = TopBar

    local ControlLayout = Instance.new("UIListLayout")
    ControlLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ControlLayout.Padding = UDim.new(0, 5)
    ControlLayout.Parent = Controls

    local function ToggleUI()
        if not MainFrame or not StartBtn then return end
        CloseAllDropdowns()
        if MainFrame.Visible then
            MainFrame.Visible = false
            StartBtn.Visible = true
        else
            MainFrame.Visible = true
            StartBtn.Visible = false
        end
    end
    XPHub.ToggleUI = ToggleUI

    local function CreateTopBtn(name, iconText, baseColor, hoverColor, order, callback)
        local btnFrame = Instance.new("TextButton")
        btnFrame.Name = name
        btnFrame.LayoutOrder = order
        btnFrame.Size = UDim2.new(0, 26, 0, 24)
        btnFrame.BackgroundColor3 = baseColor
        btnFrame.AutoButtonColor = false
        btnFrame.Text = ""
        btnFrame.ZIndex = 9998
        btnFrame.Parent = Controls
        Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 5)
        AddStroke(btnFrame, Colors.Border, 1)

        local icon = Instance.new("TextLabel")
        icon.Text = iconText
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.BackgroundTransparency = 1
        icon.TextColor3 = Colors.Text
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 13
        icon.ZIndex = 9999
        icon.Parent = btnFrame

        btnFrame.MouseEnter:Connect(function()
            TweenService:Create(btnFrame, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
        end)
        btnFrame.MouseLeave:Connect(function()
            TweenService:Create(btnFrame, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
        end)

        btnFrame.MouseButton1Click:Connect(callback)
    end

    CreateTopBtn("Min", "-", Colors.ControlBtn, Colors.ButtonHover, 1, function()
        ToggleUI()
    end)
    CreateTopBtn("Res", "▢", Colors.ControlBtn, Colors.ButtonHover, 2, function()
        MainFrame.Position = UDim2.new(0.5, -MainFrame.AbsoluteSize.X / 2, 0.5, -MainFrame.AbsoluteSize.Y / 2)
    end)
    CreateTopBtn("Close", "X", Colors.CloseRed, Color3.fromRGB(235, 65, 70), 3, function()
        XPHub:ResetAllSettings()
        task.wait(0.1)
        ScreenGui:Destroy()
    end)

    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, 0, 1, -40)
    Body.Position = UDim2.new(0, 0, 0, 40)
    Body.BackgroundTransparency = 1
    Body.BorderSizePixel = 0
    Body.ClipsDescendants = true
    Body.ZIndex = 2
    Body.Parent = MainFrame

    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, 160, 1, -16)
    Sidebar.Position = UDim2.new(0, 8, 0, 8)
    Sidebar.BackgroundColor3 = Colors.SidebarBg
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 3
    Sidebar.ScrollBarImageColor3 = Colors.Accent
    Sidebar.ScrollingEnabled = false
    Sidebar.ZIndex = 3
    Sidebar.Parent = Body
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)
    AddStroke(Sidebar, Colors.Border, 1)

    local SidebarPad = Instance.new("UIPadding", Sidebar)
    SidebarPad.PaddingTop = UDim.new(0, 6)
    SidebarPad.PaddingBottom = UDim.new(0, 6)
    SidebarPad.PaddingLeft = UDim.new(0, 6)
    SidebarPad.PaddingRight = UDim.new(0, 6)

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Padding = UDim.new(0, 4)
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = Sidebar

    SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local totalY = SidebarLayout.AbsoluteContentSize.Y + 12
        Sidebar.CanvasSize = UDim2.new(0, 0, 0, totalY)
        if totalY > Sidebar.AbsoluteSize.Y then
            Sidebar.ScrollBarThickness = 3
            Sidebar.ScrollingEnabled = true
        else
            Sidebar.ScrollBarThickness = 0
            Sidebar.ScrollingEnabled = false
        end
    end)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -184, 1, -16)
    Container.Position = UDim2.new(0, 176, 0, 8)
    Container.BackgroundTransparency = 1
    Container.ZIndex = 3
    Container.Parent = Body

    StartBtn = Instance.new("ImageButton")
    XPHub.StartBtn = StartBtn
    StartBtn.Name = "StartBtn"
    StartBtn.Size = UDim2.new(0, 50, 0, 50)
    StartBtn.AnchorPoint = Vector2.new(0, 0)
    StartBtn.Position = UDim2.new(0.5, -25, 0.05, 0)
    StartBtn.BackgroundColor3 = Colors.TopBarBg
    StartBtn.Image = "rbxassetid://106080187166557"
    StartBtn.Visible = false
    StartBtn.ZIndex = 2000
    StartBtn.Parent = ScreenGui
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 10)
    AddStroke(StartBtn, Colors.BorderFocus, 1.5)

    if getgenv then
        getgenv().StartBtn = StartBtn
        getgenv().CloseAllDropdowns = CloseAllDropdowns
        getgenv().UI_TITLE = UI_TITLE
    end
    _G.StartBtn = StartBtn
    _G.CloseAllDropdowns = CloseAllDropdowns
    _G.UI_TITLE = UI_TITLE

    StartBtn.MouseButton1Click:Connect(function()
        if not wasDragging then
            ToggleUI()
        end
    end)

    MakeDraggableStartBtn(StartBtn, StartBtn)
    MakeDraggable(MainFrame, TopBar)

    function window:AddTab(TabConfig)
        local tab = {CountSection = 0}

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Colors.CardHover
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.BorderSizePixel = 0
        TabBtn.ZIndex = 4
        TabBtn.Parent = Sidebar
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        local Indicator = Instance.new("Frame")
        Indicator.Name = "Indicator"
        Indicator.Size = UDim2.new(0, 3, 0, 18)
        Indicator.Position = UDim2.new(0, 0, 0.5, -9)
        Indicator.BackgroundColor3 = Colors.Accent
        Indicator.BackgroundTransparency = 1
        Indicator.BorderSizePixel = 0
        Indicator.ZIndex = 5
        Indicator.Parent = TabBtn
        Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

        local TabContent = Instance.new("Frame")
        TabContent.Name = "Frame"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Parent = TabBtn

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 18, 0, 18)
        TabIcon.Position = UDim2.new(0, 10, 0.5, -9)
        TabIcon.Image = TabConfig.Icon or ""
        TabIcon.ImageColor3 = Colors.SubText
        TabIcon.BackgroundTransparency = 1
        TabIcon.ZIndex = 5
        TabIcon.Parent = TabContent

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "Label"
        TabLabel.Text = TabConfig.Name
        TabLabel.Size = UDim2.new(1, -38, 1, 0)
        TabLabel.Position = UDim2.new(0, 34, 0, 0)
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextSize = 13
        TabLabel.TextColor3 = Colors.SubText
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.BackgroundTransparency = 1
        TabLabel.ZIndex = 5
        TabLabel.Parent = TabContent

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = Colors.BorderFocus
        Page.BorderSizePixel = 0
        Page.ScrollingEnabled = true
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.ZIndex = 4
        Page.ClipsDescendants = true
        Page.Parent = Container

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local PagePadding = Instance.new("UIPadding", Page)
        PagePadding.PaddingTop = UDim.new(0, 2)
        PagePadding.PaddingLeft = UDim.new(0, 2)
        PagePadding.PaddingRight = UDim.new(0, 8)
        PagePadding.PaddingBottom = UDim.new(0, 10)

        local PageTitle = Instance.new("TextLabel")
        PageTitle.Name = "PageTitle"
        PageTitle.Size = UDim2.new(1, -4, 0, 28)
        PageTitle.Text = TabConfig.Name
        PageTitle.Font = Enum.Font.GothamBold
        PageTitle.TextSize = 18
        PageTitle.TextColor3 = Colors.Text
        PageTitle.TextXAlignment = Enum.TextXAlignment.Left
        PageTitle.BackgroundTransparency = 1
        PageTitle.ZIndex = 5
        PageTitle.LayoutOrder = -100
        PageTitle.Parent = Page

        local function UpdateTabVisuals()
            for _, b in pairs(Sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundTransparency = 1
                    if b:FindFirstChild("Indicator") then
                        b.Indicator.BackgroundTransparency = 1
                    end
                    if b:FindFirstChild("Frame") then
                        b.Frame.Label.TextColor3 = Colors.SubText
                        b.Frame.Label.Font = Enum.Font.GothamMedium
                        b.Frame.Icon.ImageColor3 = Colors.SubText
                    end
                end
            end
            TabBtn.BackgroundTransparency = 0
            Indicator.BackgroundTransparency = 0
            TabLabel.TextColor3 = Colors.Text
            TabLabel.Font = Enum.Font.GothamBold
            TabIcon.ImageColor3 = Colors.Accent
        end

        TabBtn.MouseButton1Click:Connect(function()
            CloseAllDropdowns()
            for _, p in pairs(Container:GetChildren()) do
                if p:IsA("ScrollingFrame") then p.Visible = false end
            end
            UpdateTabVisuals()
            Page.Visible = true
        end)

        if window.CountTab == 0 then
            Page.Visible = true
            UpdateTabVisuals()
        end
        window.CountTab = window.CountTab + 1

        function tab:AddSection(Title, Description, IconID)
            local sectionItems = {}
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Size = UDim2.new(1, 0, 0, 50)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.ZIndex = 5
            SectionFrame.ClipsDescendants = false
            tab.CountSection = tab.CountSection + 1
            SectionFrame.LayoutOrder = tab.CountSection
            SectionFrame.Parent = Page

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.Padding = UDim.new(0, 6)
            SectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Parent = SectionFrame

            local HeaderContainer = Instance.new("Frame")
            HeaderContainer.Size = SizeItem.TitleItem
            HeaderContainer.BackgroundColor3 = Colors.SectionHeaderBg
            HeaderContainer.BorderSizePixel = 0
            HeaderContainer.ZIndex = 6
            HeaderContainer.Parent = SectionFrame
            Instance.new("UICorner", HeaderContainer).CornerRadius = UDim.new(0, 6)
            AddStroke(HeaderContainer, Colors.Border, 1)

            if IconID then
                local SecIcon = Instance.new("ImageLabel")
                SecIcon.Size = UDim2.new(0, 18, 0, 18)
                SecIcon.Position = UDim2.new(0, 12, 0.5, -9)
                SecIcon.Image = IconID
                SecIcon.BackgroundTransparency = 1
                SecIcon.ImageColor3 = Colors.Accent
                SecIcon.ZIndex = 7
                SecIcon.Parent = HeaderContainer
            end

            local hasDesc = Description and Description ~= ""
            local xPos = IconID and 36 or 12

            local HeaderTitle = Instance.new("TextLabel")
            HeaderTitle.Size = UDim2.new(1, -45, 0, 18)
            HeaderTitle.Position = hasDesc and UDim2.new(0, xPos, 0, 5) or UDim2.new(0, xPos, 0.5, -9)
            HeaderTitle.Text = Title
            HeaderTitle.Font = Enum.Font.GothamBold
            HeaderTitle.TextSize = 13
            HeaderTitle.TextColor3 = Colors.Text
            HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.ZIndex = 7
            HeaderTitle.Parent = HeaderContainer

            if hasDesc then
                local Desc = Instance.new("TextLabel")
                Desc.Size = UDim2.new(1, -45, 0, 14)
                Desc.Position = UDim2.new(0, xPos, 0, 22)
                Desc.Text = Description
                Desc.Font = Enum.Font.Gotham
                Desc.TextSize = 11
                Desc.TextColor3 = Colors.SubText
                Desc.TextXAlignment = Enum.TextXAlignment.Left
                Desc.BackgroundTransparency = 1
                Desc.ZIndex = 7
                Desc.Parent = HeaderContainer
            end

            SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                SectionFrame.Size = UDim2.new(1, 0, 0, SectionLayout.AbsoluteContentSize.Y + 4)
            end)

            local function SetupRowText(row, title, desc, rightSpace)
                local hasRowDesc = desc and desc ~= ""
                local TTitle = Instance.new("TextLabel")
                TTitle.Text = title or ""
                TTitle.Size = UDim2.new(1, -rightSpace, 0, 20)
                TTitle.Position = hasRowDesc and UDim2.new(0, 14, 0, 9) or UDim2.new(0, 14, 0.5, -10)
                TTitle.Font = Enum.Font.GothamBold
                TTitle.TextSize = 13
                TTitle.TextColor3 = Colors.Text
                TTitle.TextXAlignment = Enum.TextXAlignment.Left
                TTitle.BackgroundTransparency = 1
                TTitle.ZIndex = 8
                TTitle.Parent = row

                if hasRowDesc then
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = desc
                    TDesc.Size = UDim2.new(1, -rightSpace, 0, 16)
                    TDesc.Position = UDim2.new(0, 14, 0, 29)
                    TDesc.Font = Enum.Font.Gotham
                    TDesc.TextSize = 11
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = row
                end
            end

            function sectionItems:AddToggleSwitch(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 80)

                local SwitchBg = Instance.new("TextButton")
                SwitchBg.Size = UDim2.new(0, 44, 0, 22)
                SwitchBg.Position = UDim2.new(1, -58, 0.5, -11)
                SwitchBg.BackgroundColor3 = Config.Default and Colors.SwitchOn or Colors.SwitchOff
                SwitchBg.AutoButtonColor = false
                SwitchBg.Text = ""
                SwitchBg.ZIndex = 9
                SwitchBg.Parent = Row
                Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
                AddStroke(SwitchBg, Colors.Border, 1)

                local Knob = Instance.new("Frame")
                Knob.Size = UDim2.new(0, 16, 0, 16)
                Knob.Position = Config.Default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                Knob.BackgroundColor3 = Colors.White
                Knob.ZIndex = 10
                Knob.Parent = SwitchBg
                Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

                local state = Config.Default or false
                UpdateState(Config.ID, state)

                local function VisualUpdate(val)
                    local targetPos = val and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                    local targetColor = val and Colors.SwitchOn or Colors.SwitchOff
                    TweenService:Create(Knob, TweenInfo.new(0.18), {Position = targetPos}):Play()
                    TweenService:Create(SwitchBg, TweenInfo.new(0.18), {BackgroundColor3 = targetColor}):Play()
                end

                if Config.ID and XPHub.Objects then
                    XPHub.Objects[Config.ID] = {
                        Type = "Toggle",
                        Instance = SwitchBg,
                        Knob = Knob,
                        Callback = Config.Callback,
                        Update = function(val)
                            state = val
                            VisualUpdate(val)
                        end
                    }
                end

                SwitchBg.MouseButton1Click:Connect(function()
                    state = not state
                    VisualUpdate(state)
                    UpdateState(Config.ID, state)
                    if Config.Callback then Config.Callback(state) end
                end)
            end

            function sectionItems:AddSlider(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 175)

                local SliderContainer = Instance.new("Frame")
                SliderContainer.Size = UDim2.new(0, 150, 0, 38)
                SliderContainer.Position = UDim2.new(1, -164, 0.5, -19)
                SliderContainer.BackgroundTransparency = 1
                SliderContainer.ZIndex = 9
                SliderContainer.Parent = Row

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(1, 0, 0, 16)
                ValueLabel.Position = UDim2.new(0, 0, 0, 0)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(Config.Default or Config.Min) .. " / " .. tostring(Config.Max)
                ValueLabel.TextColor3 = Colors.Text
                ValueLabel.Font = Enum.Font.Code
                ValueLabel.TextSize = 12
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.ZIndex = 10
                ValueLabel.Parent = SliderContainer

                local SliderBack = Instance.new("Frame")
                SliderBack.Size = UDim2.new(1, 0, 0, 6)
                SliderBack.Position = UDim2.new(0, 0, 0, 24)
                SliderBack.BackgroundColor3 = Colors.InputBg
                SliderBack.BorderSizePixel = 0
                SliderBack.ZIndex = 10
                SliderBack.Parent = SliderContainer
                Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)
                AddStroke(SliderBack, Colors.Border, 1)

                local initRatio = math.clamp(((Config.Default or Config.Min) - Config.Min) / (Config.Max - Config.Min), 0, 1)

                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(initRatio, 0, 1, 0)
                SliderFill.BackgroundColor3 = Colors.Accent
                SliderFill.BorderSizePixel = 0
                SliderFill.ZIndex = 11
                SliderFill.Parent = SliderBack
                Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

                local Handle = Instance.new("Frame")
                Handle.Size = UDim2.new(0, 12, 0, 12)
                Handle.AnchorPoint = Vector2.new(0.5, 0.5)
                Handle.Position = UDim2.new(initRatio, 0, 0.5, 0)
                Handle.BackgroundColor3 = Colors.White
                Handle.ZIndex = 12
                Handle.Active = true
                Handle.Parent = SliderBack
                Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)

                local dragging = false
                UpdateState(Config.ID, Config.Default or Config.Min)

                local function VisualUpdate(val)
                    local relativeX = math.clamp((val - Config.Min) / (Config.Max - Config.Min), 0, 1)
                    SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                    Handle.Position = UDim2.new(relativeX, 0, 0.5, 0)
                    ValueLabel.Text = tostring(val) .. " / " .. tostring(Config.Max)
                end

                if Config.ID and XPHub.Objects then
                    XPHub.Objects[Config.ID] = {
                        Type = "Slider",
                        Instance = SliderFill,
                        Handle = Handle,
                        Label = ValueLabel,
                        Config = Config,
                        Callback = Config.Callback,
                        Update = VisualUpdate
                    }
                end

                local function UpdateSlider(input)
                    local relativeX = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    local value = math.floor(Config.Min + (Config.Max - Config.Min) * relativeX)
                    VisualUpdate(value)
                    UpdateState(Config.ID, value)
                    if Config.Callback then Config.Callback(value) end
                end

                SliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        UpdateSlider(input)
                    end
                end)

                Handle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input)
                    end
                end)
            end

            function sectionItems:AddDropdown(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 200)

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(0, 175, 0, 32)
                Frame.Position = UDim2.new(1, -188, 0.5, -16)
                Frame.BackgroundColor3 = Colors.InputBg
                Frame.ZIndex = 10
                Frame.Parent = Row
                Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 5)
                AddStroke(Frame, Colors.BorderFocus, 1)

                local Label = Instance.new("TextLabel")
                Label.Text = Config.Default or "Select..."
                Label.Size = UDim2.new(1, -36, 1, 0)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = Colors.Text
                Label.Font = Enum.Font.Gotham
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.ClipsDescendants = true
                Label.ZIndex = 11
                Label.Parent = Frame

                local ArrowBtn = Instance.new("Frame")
                ArrowBtn.Size = UDim2.new(0, 24, 0, 24)
                ArrowBtn.Position = UDim2.new(1, -28, 0.5, -12)
                ArrowBtn.BackgroundColor3 = Colors.ButtonBg
                ArrowBtn.ZIndex = 11
                ArrowBtn.Parent = Frame
                Instance.new("UICorner", ArrowBtn).CornerRadius = UDim.new(0, 4)

                local ArrowIcon = Instance.new("ImageLabel")
                ArrowIcon.Image = "rbxassetid://74976956154520"
                ArrowIcon.Size = UDim2.new(0, 12, 0, 12)
                ArrowIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.ImageColor3 = Colors.Text
                ArrowIcon.ZIndex = 12
                ArrowIcon.Parent = ArrowBtn

                local DropdownClickBtn = Instance.new("TextButton")
                DropdownClickBtn.Size = UDim2.new(1, 0, 1, 0)
                DropdownClickBtn.BackgroundTransparency = 1
                DropdownClickBtn.Text = ""
                DropdownClickBtn.ZIndex = 15
                DropdownClickBtn.Parent = Frame

                local List = Instance.new("Frame")
                List.Name = "DropdownList"
                List.BackgroundColor3 = Colors.DropdownBg
                List.ZIndex = 1000
                List.Visible = false
                List.ClipsDescendants = true
                List.Parent = MainFrame
                Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
                AddStroke(List, Colors.BorderFocus, 1)

                local SearchBox = Instance.new("TextBox")
                SearchBox.Size = UDim2.new(1, -10, 0, 26)
                SearchBox.Position = UDim2.new(0, 5, 0, 5)
                SearchBox.BackgroundColor3 = Colors.InputBg
                SearchBox.PlaceholderText = "Search..."
                SearchBox.PlaceholderColor3 = Colors.MutedText
                SearchBox.TextColor3 = Colors.Text
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.Text = ""
                SearchBox.TextSize = 12
                SearchBox.ZIndex = 1001
                SearchBox.Parent = List
                Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)
                AddStroke(SearchBox, Colors.Border, 1)

                local ItemScroll = Instance.new("ScrollingFrame")
                ItemScroll.Size = UDim2.new(1, -8, 1, -38)
                ItemScroll.Position = UDim2.new(0, 4, 0, 35)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.BorderSizePixel = 0
                ItemScroll.ScrollBarThickness = 3
                ItemScroll.ScrollBarImageColor3 = Colors.Accent
                ItemScroll.ZIndex = 1001
                ItemScroll.Parent = List

                local ItemListLayout = Instance.new("UIListLayout", ItemScroll)
                ItemListLayout.Padding = UDim.new(0, 2)

                local syncConnection
                local currentlySelected = Config.Default or nil
                UpdateState(Config.ID, currentlySelected)

                local function UpdateListPosition()
                    if List.Visible then
                        local absPos = Frame.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        local contentHeight = ItemListLayout.AbsoluteContentSize.Y
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 4)
                        local dynamicHeight = math.clamp(contentHeight + 42, 70, 200)
                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y + 3)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            local isSelected = (item == currentlySelected)
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 26)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = "  " .. tostring(item)
                            itemBtn.Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham
                            itemBtn.TextSize = 12
                            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                            itemBtn.ZIndex = 1002
                            itemBtn.BackgroundColor3 = isSelected and Colors.Accent or Colors.CardBg
                            itemBtn.TextColor3 = isSelected and Colors.White or Colors.Text
                            itemBtn.Parent = ItemScroll
                            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)

                            itemBtn.MouseButton1Click:Connect(function()
                                Label.Text = tostring(item)
                                currentlySelected = item
                                CloseAllDropdowns()
                                if syncConnection then syncConnection:Disconnect() end
                                UpdateState(Config.ID, item)
                                if Config.Callback then Config.Callback(item) end
                            end)
                        end
                    end
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    Populate(SearchBox.Text)
                    UpdateListPosition()
                end)

                local dropdownFunc = {}
                function dropdownFunc:Refresh(newList)
                    Config.Options = newList
                    Populate("")
                end
                function dropdownFunc:Update(val)
                    Label.Text = tostring(val)
                    currentlySelected = val
                end
                function dropdownFunc:Set(val)
                    Label.Text = tostring(val)
                    currentlySelected = val
                    UpdateState(Config.ID, val)
                    if Config.Callback then Config.Callback(val) end
                end

                if Config.ID then
                    XPHub.Objects[Config.ID] = {
                        Type = "Dropdown",
                        Default = Config.Default,
                        Update = function(val)
                            Label.Text = tostring(val)
                            currentlySelected = val
                        end,
                        Callback = Config.Callback or function() end
                    }
                end

                DropdownClickBtn.MouseButton1Click:Connect(function()
                    if List.Visible then
                        CloseAllDropdowns()
                        if syncConnection then syncConnection:Disconnect() end
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180}):Play()
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        if syncConnection then syncConnection:Disconnect() end
                        syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
                    end
                end)

                return dropdownFunc
            end

            function sectionItems:AddMultiSelect(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 200)

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(0, 175, 0, 32)
                Frame.Position = UDim2.new(1, -188, 0.5, -16)
                Frame.BackgroundColor3 = Colors.InputBg
                Frame.ZIndex = 10
                Frame.Parent = Row
                Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 5)
                AddStroke(Frame, Colors.BorderFocus, 1)

                local Label = Instance.new("TextLabel")
                Label.Text = "None"
                Label.Size = UDim2.new(1, -36, 1, 0)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = Colors.Text
                Label.Font = Enum.Font.Gotham
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.ClipsDescendants = true
                Label.ZIndex = 11
                Label.Parent = Frame

                local ArrowBtn = Instance.new("Frame")
                ArrowBtn.Size = UDim2.new(0, 24, 0, 24)
                ArrowBtn.Position = UDim2.new(1, -28, 0.5, -12)
                ArrowBtn.BackgroundColor3 = Colors.ButtonBg
                ArrowBtn.ZIndex = 11
                ArrowBtn.Parent = Frame
                Instance.new("UICorner", ArrowBtn).CornerRadius = UDim.new(0, 4)

                local ArrowIcon = Instance.new("ImageLabel")
                ArrowIcon.Image = "rbxassetid://74976956154520"
                ArrowIcon.Size = UDim2.new(0, 12, 0, 12)
                ArrowIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.ImageColor3 = Colors.Text
                ArrowIcon.ZIndex = 12
                ArrowIcon.Parent = ArrowBtn

                local MultiClickBtn = Instance.new("TextButton")
                MultiClickBtn.Size = UDim2.new(1, 0, 1, 0)
                MultiClickBtn.BackgroundTransparency = 1
                MultiClickBtn.Text = ""
                MultiClickBtn.ZIndex = 15
                MultiClickBtn.Parent = Frame

                local List = Instance.new("Frame")
                List.Name = "MultiSelectList"
                List.BackgroundColor3 = Colors.DropdownBg
                List.ZIndex = 1000
                List.Visible = false
                List.ClipsDescendants = true
                List.Parent = MainFrame
                Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
                AddStroke(List, Colors.BorderFocus, 1)

                local SearchBox = Instance.new("TextBox")
                SearchBox.Size = UDim2.new(1, -10, 0, 26)
                SearchBox.Position = UDim2.new(0, 5, 0, 5)
                SearchBox.BackgroundColor3 = Colors.InputBg
                SearchBox.PlaceholderText = "Search..."
                SearchBox.PlaceholderColor3 = Colors.MutedText
                SearchBox.TextColor3 = Colors.Text
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.Text = ""
                SearchBox.TextSize = 12
                SearchBox.ZIndex = 1001
                SearchBox.Parent = List
                Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)
                AddStroke(SearchBox, Colors.Border, 1)

                local ItemScroll = Instance.new("ScrollingFrame")
                ItemScroll.Size = UDim2.new(1, -8, 1, -38)
                ItemScroll.Position = UDim2.new(0, 4, 0, 35)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.BorderSizePixel = 0
                ItemScroll.ScrollBarThickness = 3
                ItemScroll.ScrollBarImageColor3 = Colors.Accent
                ItemScroll.ZIndex = 1001
                ItemScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
                ItemScroll.Parent = List

                local ListLayout = Instance.new("UIListLayout", ItemScroll)
                ListLayout.Padding = UDim.new(0, 2)

                local syncConnection
                local selectedItems = Config.Default or {}
                UpdateState(Config.ID, selectedItems)

                local function UpdateLabel()
                    if type(selectedItems) == "table" then
                        Label.Text = #selectedItems == 0 and "None" or table.concat(selectedItems, ", ")
                    else
                        Label.Text = tostring(selectedItems)
                    end
                end
                UpdateLabel()

                local function UpdateListPosition()
                    if List.Visible then
                        local absPos = Frame.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        local contentHeight = ListLayout.AbsoluteContentSize.Y
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 4)
                        local dynamicHeight = math.clamp(contentHeight + 42, 70, 200)
                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y + 3)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 26)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = "  " .. tostring(item)
                            itemBtn.Font = Enum.Font.Gotham
                            itemBtn.TextSize = 12
                            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                            itemBtn.ZIndex = 1002
                            itemBtn.Parent = ItemScroll
                            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 4)

                            local function RefreshColor()
                                if type(selectedItems) == "table" and table.find(selectedItems, item) then
                                    itemBtn.BackgroundColor3 = Colors.Accent
                                    itemBtn.TextColor3 = Colors.White
                                    itemBtn.Font = Enum.Font.GothamBold
                                else
                                    itemBtn.BackgroundColor3 = Colors.CardBg
                                    itemBtn.TextColor3 = Colors.Text
                                    itemBtn.Font = Enum.Font.Gotham
                                end
                            end
                            RefreshColor()

                            itemBtn.MouseButton1Click:Connect(function()
                                if type(selectedItems) ~= "table" then selectedItems = {} end
                                local foundIndex = table.find(selectedItems, item)
                                if foundIndex then
                                    table.remove(selectedItems, foundIndex)
                                else
                                    table.insert(selectedItems, item)
                                end
                                RefreshColor()
                                UpdateLabel()
                                UpdateState(Config.ID, selectedItems)
                                if Config.Callback then Config.Callback(selectedItems) end
                            end)
                        end
                    end
                end

                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    Populate(SearchBox.Text)
                    UpdateListPosition()
                end)

                if Config.ID and XPHub.Objects then
                    XPHub.Objects[Config.ID] = {
                        Type = "MultiSelect",
                        Update = function(val)
                            if type(val) == "table" then
                                selectedItems = val
                            else
                                selectedItems = {val}
                            end
                            UpdateLabel()
                        end,
                        Callback = Config.Callback or function() end
                    }
                end

                MultiClickBtn.MouseButton1Click:Connect(function()
                    if List.Visible then
                        CloseAllDropdowns()
                        if syncConnection then syncConnection:Disconnect() end
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.15), {Rotation = 180}):Play()
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        if syncConnection then syncConnection:Disconnect() end
                        syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
                    end
                end)
            end

            function sectionItems:AddInput(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 175)

                local InputFrame = Instance.new("Frame")
                InputFrame.Size = UDim2.new(0, 150, 0, 32)
                InputFrame.Position = UDim2.new(1, -164, 0.5, -16)
                InputFrame.BackgroundColor3 = Colors.InputBg
                InputFrame.ClipsDescendants = true
                InputFrame.ZIndex = 9
                InputFrame.Parent = Row
                Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 5)
                local stroke = AddStroke(InputFrame, Colors.BorderFocus, 1)

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -16, 1, 0)
                TextBox.Position = UDim2.new(0, 8, 0, 0)
                TextBox.BackgroundTransparency = 1
                TextBox.Text = Config.Default or ""
                TextBox.PlaceholderText = Config.Placeholder or "Input..."
                TextBox.PlaceholderColor3 = Colors.MutedText
                TextBox.TextColor3 = Colors.Text
                TextBox.TextSize = 12
                TextBox.Font = Enum.Font.Gotham
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = false
                TextBox.ZIndex = 10
                TextBox.Parent = InputFrame

                if Config.ID and XPHub.Objects then
                    UpdateState(Config.ID, Config.Default or "")
                    XPHub.Objects[Config.ID] = {
                        Type = "Input",
                        Instance = TextBox,
                        Callback = Config.Callback,
                        Update = function(val)
                            TextBox.Text = tostring(val)
                        end
                    }
                end

                TextBox.Focused:Connect(function()
                    stroke.Color = Colors.Accent
                end)

                TextBox.FocusLost:Connect(function(enterPressed)
                    stroke.Color = Colors.BorderFocus
                    local currentText = TextBox.Text
                    if Config.ID then
                        UpdateState(Config.ID, currentText)
                    end
                    if Config.Callback then
                        Config.Callback(currentText, enterPressed)
                    end
                end)

                return Row
            end

            function sectionItems:AddButton(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 150)

                local Button = Instance.new("TextButton")
                Button.Name = "XPButton"
                Button.Size = UDim2.new(0, 120, 0, 32)
                Button.Position = UDim2.new(1, -134, 0.5, -16)
                Button.BackgroundColor3 = Colors.ButtonBg
                Button.AutoButtonColor = false
                Button.Text = Config.ButtonText or "Click"
                Button.Font = Enum.Font.GothamBold
                Button.TextSize = 12
                Button.TextColor3 = Colors.Text
                Button.ZIndex = 9
                Button.Parent = Row
                Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 5)
                AddStroke(Button, Colors.BorderFocus, 1)

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonHover}):Play()
                end)

                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.12), {BackgroundColor3 = Colors.ButtonBg}):Play()
                end)

                Button.MouseButton1Down:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.Accent}):Play()
                end)

                Button.MouseButton1Up:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.ButtonHover}):Play()
                end)

                Button.MouseButton1Click:Connect(function()
                    if Config.Callback then Config.Callback() end
                end)

                return Button
            end

            function sectionItems:AddLabel(Title)
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, -4, 0, 36)
                Row.BackgroundColor3 = Colors.SectionHeaderBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                local Accent = Instance.new("Frame")
                Accent.Size = UDim2.new(0, 3, 1, -10)
                Accent.Position = UDim2.new(0, 5, 0.5, 0)
                Accent.AnchorPoint = Vector2.new(0, 0.5)
                Accent.BackgroundColor3 = Colors.Accent
                Accent.BorderSizePixel = 0
                Accent.ZIndex = 8
                Accent.Parent = Row
                Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)

                local TTitle = Instance.new("TextLabel")
                TTitle.Text = tostring(Title)
                TTitle.Size = UDim2.new(1, -24, 1, 0)
                TTitle.Position = UDim2.new(0, 16, 0, 0)
                TTitle.Font = Enum.Font.GothamBold
                TTitle.TextSize = 12
                TTitle.TextColor3 = Colors.Text
                TTitle.TextXAlignment = Enum.TextXAlignment.Left
                TTitle.TextWrapped = true
                TTitle.BackgroundTransparency = 1
                TTitle.ZIndex = 8
                TTitle.Parent = Row

                TTitle:GetPropertyChangedSignal("Text"):Connect(function()
                    local textHeight = TTitle.TextBounds.Y
                    Row.Size = UDim2.new(1, -4, 0, math.max(36, textHeight + 14))
                end)

                local labelFunc = {}
                function labelFunc:Set(newText)
                    TTitle.Text = tostring(newText)
                end
                function labelFunc:SetColor(color)
                    Accent.BackgroundColor3 = color
                    TTitle.TextColor3 = color
                end

                return labelFunc
            end

            function sectionItems:AddKeybind(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                AddStroke(Row, Colors.Border, 1)

                SetupRowText(Row, Config.Title, Config.Description, 120)

                local currentKey = Config.Default
                local keyConnection

                local BindButton = Instance.new("TextButton")
                BindButton.Size = UDim2.new(0, 90, 0, 30)
                BindButton.Position = UDim2.new(1, -104, 0.5, -15)
                BindButton.BackgroundColor3 = Colors.ButtonBg
                BindButton.AutoButtonColor = false
                BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
                BindButton.Font = Enum.Font.Code
                BindButton.TextSize = 13
                BindButton.TextColor3 = Colors.Text
                BindButton.ZIndex = 9
                BindButton.Parent = Row
                Instance.new("UICorner", BindButton).CornerRadius = UDim.new(0, 5)
                AddStroke(BindButton, Colors.BorderFocus, 1)

                if currentKey then
                    UpdateState(Config.ID, currentKey.Name)
                end

                local function StartListening()
                    if keyConnection then keyConnection:Disconnect() end
                    if not currentKey then return end

                    keyConnection = UserInputService.InputBegan:Connect(function(input, gp)
                        if gp or IsBinding then return end
                        if input.KeyCode == currentKey then
                            if Config.Callback then Config.Callback(currentKey) end
                        end
                    end)

                    if Config.ID and XPHub.Objects[Config.ID] then
                        XPHub.Objects[Config.ID].Connection = keyConnection
                    end
                end

                if Config.ID and XPHub.Objects then
                    XPHub.Objects[Config.ID] = {
                        Type = "Keybind",
                        Stop = function()
                            if keyConnection then
                                keyConnection:Disconnect()
                                keyConnection = nil
                            end
                        end,
                        Update = function(valName)
                            if not valName or valName == "" then return end
                            if typeof(valName) == "string" and Enum.KeyCode[valName] then
                                currentKey = Enum.KeyCode[valName]
                                BindButton.Text = "[" .. valName .. "]"
                                StartListening()
                            end
                        end
                    }
                end

                if currentKey then StartListening() end

                BindButton.MouseButton1Click:Connect(function()
                    if IsBinding then return end
                    IsBinding = true
                    BindButton.Text = "[ ... ]"
                    BindButton.TextColor3 = Colors.Accent

                    local tempConnection
                    tempConnection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode
                            if newKey ~= Enum.KeyCode.Escape then
                                currentKey = newKey
                                BindButton.Text = "[" .. newKey.Name .. "]"
                                UpdateState(Config.ID, newKey.Name)
                                StartListening()
                            else
                                BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
                            end
                            BindButton.TextColor3 = Colors.Text
                            tempConnection:Disconnect()
                            task.wait(0.05)
                            IsBinding = false
                        end
                    end)
                end)
            end

            return sectionItems
        end
        return tab
    end

    ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if StartBtn then
            AdjustStartBtnByRatio(StartBtn)
        end
    end)

    return window
end

return XPHub
