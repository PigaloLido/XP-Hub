local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. ชื่อต้องตรงกับที่ตั้งใน ScreenGui.Name
local UI_NAME = "XPHub_UI"
local UI_TITLE = "XP Hub 〢 Premium"
local UI_CREDIT = "By : Pigalo"
local UI_VERSION = "v1.0.0"

-- 2. เช็คทั้งใน CoreGui และ PlayerGui ป้องกันการรันซ้ำ
local CoreGuiSuccess, CoreGui = pcall(function() return game:GetService("CoreGui") end)
local OldUI = (CoreGuiSuccess and CoreGui and CoreGui:FindFirstChild(UI_NAME)) or PlayerGui:FindFirstChild(UI_NAME)

if OldUI then
    warn("สคริปต์รันอยู่แล้ว! | The script is already running!")
    return
end

local XPHub = {
    Elements = {},
    ConfigData = {},
    Objects = {} -- เก็บ UI Objects และ Callback สำหรับระบบ Load / Reset
}

local activeDropdownList = nil
local activeDropdownArrow = nil
local MainFrame
local StartBtn
local IsBinding = false

-- โฟลเดอร์สำหรับบันทึกการตั้งค่า (Config)
local ConfigFolder = "XPHub_Configs"
if isfolder and makefolder and not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

-- ฟังก์ชันจัดการ Config (Save/Load/Get List)
local function GetConfigList()
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

local function SaveCurrentConfig(name)
    if not name or name == "" or not writefile then return end
    local json = HttpService:JSONEncode(XPHub.ConfigData)
    writefile(ConfigFolder .. "/" .. name .. ".json", json)
    print("Successfully saved config: " .. name)
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

local function LoadConfigData(name)
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

local function ResetAllSettings()
    for id, obj in pairs(XPHub.Objects) do
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
    print("Kill Switch: ทุกระบบถูก Reset และตัดการเชื่อมต่อ Keybind เรียบร้อยแล้ว")
end

local AutoloadFile = ConfigFolder .. "/autoload.txt"
local function SetAutoload(name) if writefile then writefile(AutoloadFile, name) end end
local function GetAutoload() return (isfile and readfile and isfile(AutoloadFile)) and readfile(AutoloadFile) or nil end
local function ResetAutoload() if isfile and delfile and isfile(AutoloadFile) then delfile(AutoloadFile) end end

-- ==========================================
-- 🎨 ธีมสีใหม่: Modern Dark & Cobalt Blue
-- ==========================================
local Colors = {
    -- พื้นหลังหลัก
    WindowBg        = Color3.fromRGB(15, 17, 24),
    TopBarBg        = Color3.fromRGB(20, 23, 33),
    SidebarBg       = Color3.fromRGB(19, 22, 31),
    SectionHeaderBg = Color3.fromRGB(24, 29, 42),
    CardBg          = Color3.fromRGB(23, 27, 38),
    CardHover       = Color3.fromRGB(29, 34, 48),
    InputBg         = Color3.fromRGB(16, 19, 27),
    DropdownBg      = Color3.fromRGB(20, 24, 34),

    -- สี Accent (ฟ้า-น้ำเงินพรีเมียม)
    Accent          = Color3.fromRGB(59, 130, 246),
    AccentLight     = Color3.fromRGB(96, 165, 250),
    AccentDark      = Color3.fromRGB(37, 99, 235),

    -- ข้อความ
    Text            = Color3.fromRGB(243, 244, 246),
    SubText         = Color3.fromRGB(148, 163, 184),
    MutedText       = Color3.fromRGB(100, 116, 139),

    -- เส้นขอบ
    Border          = Color3.fromRGB(38, 45, 64),
    BorderHighlight = Color3.fromRGB(65, 80, 115),

    -- ปุ่มควบคุมหน้าต่าง
    CloseRed        = Color3.fromRGB(239, 68, 68),
    ControlBtnBg    = Color3.fromRGB(30, 35, 48),

    -- สถานะ Switch / ปุ่ม
    SwitchOn        = Color3.fromRGB(59, 130, 246),
    SwitchOff       = Color3.fromRGB(45, 53, 72),
    ButtonBg        = Color3.fromRGB(34, 41, 58),
    ButtonHover     = Color3.fromRGB(47, 56, 78),
    White           = Color3.fromRGB(255, 255, 255),
}

local SizeItem = {
    BoxItem   = UDim2.new(1, -4, 0, 58),
    TitleItem = UDim2.new(1, -4, 0, 46)
}

-- ฟังก์ชันปิด Dropdown ทั้งหมด
local function CloseAllDropdowns()
    if activeDropdownList then
        activeDropdownList.Visible = false
        activeDropdownList = nil
    end
    if activeDropdownArrow then
        TweenService:Create(activeDropdownArrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 0}):Play()
        activeDropdownArrow = nil
    end
end

-- ระบบลากหน้าต่าง
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

-- ระบบย่อ/ขยายขนาดหน้าต่าง
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
            local newWidth = math.max(540, startSize.X.Offset + delta.X)
            local newHeight = math.max(360, startSize.Y.Offset + delta.Y)
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
local lastScreenRatioY = 0.06

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
                local finalX = math.clamp(currentX, 8, math.max(8, screenSize.X - btnSize.X - 8))
                local finalY = math.clamp(currentY, 8, math.max(8, screenSize.Y - btnSize.Y - 8))

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

        TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, math.clamp(targetX, 8, math.max(8, screenSize.X - btnSize.X - 8)), 0, math.clamp(targetY, 8, math.max(8, screenSize.Y - btnSize.Y - 8)))
        }):Play()
    end
end

-- Helper สร้าง UIStroke อย่างรวดเร็ว
local function AddStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Helper สร้าง Hover Effect ให้การ์ดแต่ละแถว
local function AttachCardHover(row)
    local stroke = AddStroke(row, Colors.Border, 1, 0.2)
    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = Colors.CardHover}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Color = Colors.BorderHighlight, Transparency = 0}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = Colors.CardBg}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Color = Colors.Border, Transparency = 0.2}):Play()
    end)
    return stroke
end

-- ==========================================
-- 🪟 สร้างหน้าต่างหลัก (Window)
-- ==========================================
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
    MainFrame.Size = UDim2.new(0, 680, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -340, 0.5, -240)
    MainFrame.BackgroundColor3 = Colors.WindowBg
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 1
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
    AddStroke(MainFrame, Colors.BorderHighlight, 1.2, 0.15)

    -- ปุ่ม Resize มุมขวาล่าง
    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 22, 0, 22)
    ResizeHandle.Position = UDim2.new(1, -22, 1, -22)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.ZIndex = 5000
    ResizeHandle.Parent = MainFrame

    local ResizeIcon = Instance.new("TextLabel")
    ResizeIcon.Text = "◢"
    ResizeIcon.Size = UDim2.new(1, -4, 1, -4)
    ResizeIcon.BackgroundTransparency = 1
    ResizeIcon.TextColor3 = Colors.MutedText
    ResizeIcon.TextSize = 14
    ResizeIcon.TextXAlignment = Enum.TextXAlignment.Right
    ResizeIcon.TextYAlignment = Enum.TextYAlignment.Bottom
    ResizeIcon.ZIndex = 4999
    ResizeIcon.Parent = ResizeHandle

    MakeResizable(MainFrame, ResizeHandle)

    -- ==========================================
    -- 🔝 TopBar
    -- ==========================================
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 44)
    TopBar.BackgroundColor3 = Colors.TopBarBg
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 1115
    TopBar.Parent = MainFrame

    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

    -- ปิดมุมโค้งด้านล่างของ TopBar ให้เรียบสนิทกับตัวหน้าต่าง
    local TopBarBottomFix = Instance.new("Frame")
    TopBarBottomFix.Size = UDim2.new(1, 0, 0, 12)
    TopBarBottomFix.Position = UDim2.new(0, 0, 1, -12)
    TopBarBottomFix.BackgroundColor3 = Colors.TopBarBg
    TopBarBottomFix.BorderSizePixel = 0
    TopBarBottomFix.ZIndex = 1115
    TopBarBottomFix.Parent = TopBar

    -- เส้นคั่นใต้ TopBar
    local TopDivider = Instance.new("Frame")
    TopDivider.Size = UDim2.new(1, 0, 0, 1)
    TopDivider.Position = UDim2.new(0, 0, 1, -1)
    TopDivider.BackgroundColor3 = Colors.Border
    TopDivider.BorderSizePixel = 0
    TopDivider.ZIndex = 1116
    TopDivider.Parent = TopBar

    -- โลโก้ด้านซ้าย
    local LogoBadge = Instance.new("Frame")
    LogoBadge.Size = UDim2.new(0, 28, 0, 28)
    LogoBadge.Position = UDim2.new(0, 12, 0.5, 0)
    LogoBadge.AnchorPoint = Vector2.new(0, 0.5)
    LogoBadge.BackgroundColor3 = Colors.AccentDark
    LogoBadge.BackgroundTransparency = 0.75
    LogoBadge.ZIndex = 1116
    LogoBadge.Parent = TopBar
    Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 7)
    AddStroke(LogoBadge, Colors.Accent, 1, 0.5)

    local TopLogo = Instance.new("ImageLabel")
    TopLogo.Name = "TopLogo"
    TopLogo.Size = UDim2.new(0, 20, 0, 20)
    TopLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
    TopLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    TopLogo.Image = "rbxassetid://106080187166557"
    TopLogo.BackgroundTransparency = 1
    TopLogo.ZIndex = 1117
    TopLogo.Parent = LogoBadge

    -- ส่วนชื่อ Title, Credit และ Version Badge
    local TitleContainer = Instance.new("Frame")
    TitleContainer.Name = "TitleContainer"
    TitleContainer.Size = UDim2.new(1, -170, 1, 0)
    TitleContainer.Position = UDim2.new(0, 48, 0, 0)
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
    CreditTitle.Font = Enum.Font.GothamMedium
    CreditTitle.TextSize = 12
    CreditTitle.TextColor3 = Colors.SubText
    CreditTitle.Size = UDim2.new(0, 0, 1, 0)
    CreditTitle.AutomaticSize = Enum.AutomaticSize.X
    CreditTitle.BackgroundTransparency = 1
    CreditTitle.ZIndex = 1116
    CreditTitle.LayoutOrder = 2
    CreditTitle.Parent = TitleContainer

    -- ป้าย Version ทรงแคปซูล
    local VersionBadge = Instance.new("Frame")
    VersionBadge.Size = UDim2.new(0, 0, 0, 20)
    VersionBadge.AutomaticSize = Enum.AutomaticSize.X
    VersionBadge.BackgroundColor3 = Colors.AccentDark
    VersionBadge.BackgroundTransparency = 0.75
    VersionBadge.ZIndex = 1116
    VersionBadge.LayoutOrder = 3
    VersionBadge.Parent = TitleContainer
    Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(1, 0)
    AddStroke(VersionBadge, Colors.Accent, 1, 0.5)

    local VersionPadding = Instance.new("UIPadding", VersionBadge)
    VersionPadding.PaddingLeft = UDim.new(0, 8)
    VersionPadding.PaddingRight = UDim.new(0, 8)

    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Name = "VersionLabel"
    VersionLabel.Text = UI_VERSION
    VersionLabel.Font = Enum.Font.RobotoMono
    VersionLabel.TextSize = 11
    VersionLabel.TextColor3 = Colors.AccentLight
    VersionLabel.Size = UDim2.new(0, 0, 1, 0)
    VersionLabel.AutomaticSize = Enum.AutomaticSize.X
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.ZIndex = 1117
    VersionLabel.Parent = VersionBadge

    -- ปุ่มควบคุมหน้าต่าง (Minimize, Center, Close)
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(0, 110, 1, 0)
    Controls.Position = UDim2.new(1, -10, 0, 0)
    Controls.AnchorPoint = Vector2.new(1, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 1117
    Controls.Parent = TopBar

    local ControlLayout = Instance.new("UIListLayout")
    ControlLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ControlLayout.Padding = UDim.new(0, 6)
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

    local function CreateWindowBtn(name, iconText, hoverColor, order, callback)
        local btnFrame = Instance.new("TextButton")
        btnFrame.Name = name
        btnFrame.LayoutOrder = order
        btnFrame.Size = UDim2.new(0, 28, 0, 28)
        btnFrame.BackgroundColor3 = Colors.ControlBtnBg
        btnFrame.AutoButtonColor = false
        btnFrame.Text = ""
        btnFrame.ZIndex = 9998
        btnFrame.Parent = Controls
        Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 7)
        local stroke = AddStroke(btnFrame, Colors.Border, 1, 0.3)

        local icon = Instance.new("TextLabel")
        icon.Text = iconText
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.BackgroundTransparency = 1
        icon.TextColor3 = Colors.SubText
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 13
        icon.ZIndex = 9999
        icon.Parent = btnFrame

        btnFrame.MouseEnter:Connect(function()
            TweenService:Create(btnFrame, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
            TweenService:Create(icon, TweenInfo.new(0.15), {TextColor3 = Colors.White}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 1}):Play()
        end)
        btnFrame.MouseLeave:Connect(function()
            TweenService:Create(btnFrame, TweenInfo.new(0.15), {BackgroundColor3 = Colors.ControlBtnBg}):Play()
            TweenService:Create(icon, TweenInfo.new(0.15), {TextColor3 = Colors.SubText}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
        end)

        btnFrame.MouseButton1Click:Connect(callback)
    end

    CreateWindowBtn("Min", "—", Colors.Accent, 1, function()
        ToggleUI()
    end)
    CreateWindowBtn("Res", "▢", Colors.Accent, 2, function()
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.5, -MainFrame.AbsoluteSize.X / 2, 0.5, -MainFrame.AbsoluteSize.Y / 2)
        }):Play()
    end)
    CreateWindowBtn("Close", "✕", Colors.CloseRed, 3, function()
        ResetAllSettings()
        task.wait(0.1)
        ScreenGui:Destroy()
    end)

    -- ==========================================
    -- 📐 โครงสร้าง Body, Sidebar และ Container
    -- ==========================================
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, 0, 1, -44)
    Body.Position = UDim2.new(0, 0, 0, 44)
    Body.BackgroundTransparency = 1
    Body.BorderSizePixel = 0
    Body.ClipsDescendants = true
    Body.ZIndex = 2
    Body.Parent = MainFrame

    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 175, 1, -20)
    Sidebar.Position = UDim2.new(0, 10, 0, 10)
    Sidebar.BackgroundColor3 = Colors.SidebarBg
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 3
    Sidebar.ScrollBarImageColor3 = Colors.Accent
    Sidebar.ScrollingEnabled = false
    Sidebar.ZIndex = 3
    Sidebar.Parent = Body

    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
    AddStroke(Sidebar, Colors.Border, 1, 0.2)

    local SidebarPadding = Instance.new("UIPadding", Sidebar)
    SidebarPadding.PaddingTop = UDim.new(0, 8)
    SidebarPadding.PaddingBottom = UDim.new(0, 8)
    SidebarPadding.PaddingLeft = UDim.new(0, 8)
    SidebarPadding.PaddingRight = UDim.new(0, 8)

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Padding = UDim.new(0, 5)
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = Sidebar

    SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentY = SidebarLayout.AbsoluteContentSize.Y + 16
        Sidebar.CanvasSize = UDim2.new(0, 0, 0, contentY)
        if contentY > Sidebar.AbsoluteSize.Y then
            Sidebar.ScrollBarThickness = 3
            Sidebar.ScrollingEnabled = true
        else
            Sidebar.ScrollBarThickness = 0
            Sidebar.ScrollingEnabled = false
        end
    end)

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -205, 1, -20)
    Container.Position = UDim2.new(0, 195, 0, 10)
    Container.BackgroundTransparency = 1
    Container.ZIndex = 3
    Container.Parent = Body

    -- ==========================================
    -- 🔘 ปุ่มลอยเปิดเมนู (Floating Start Button)
    -- ==========================================
    StartBtn = Instance.new("ImageButton")
    StartBtn.Name = "StartBtn"
    StartBtn.Size = UDim2.new(0, 52, 0, 52)
    StartBtn.AnchorPoint = Vector2.new(0, 0)
    StartBtn.Position = UDim2.new(0.5, -26, 0.06, 0)
    StartBtn.BackgroundColor3 = Colors.TopBarBg
    StartBtn.BackgroundTransparency = 0.1
    StartBtn.Image = "rbxassetid://106080187166557"
    StartBtn.Visible = false
    StartBtn.ZIndex = 2000
    StartBtn.Parent = ScreenGui

    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 14)
    local StartStroke = AddStroke(StartBtn, Colors.Accent, 1.8, 0.2)

    StartBtn.MouseButton1Click:Connect(function()
        if not wasDragging then
            ToggleUI()
        end
    end)

    StartBtn.MouseEnter:Connect(function()
        TweenService:Create(StartBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 56, 0, 56),
            BackgroundColor3 = Colors.CardHover
        }):Play()
        TweenService:Create(StartStroke, TweenInfo.new(0.2), {Color = Colors.AccentLight, Transparency = 0}):Play()
    end)

    StartBtn.MouseLeave:Connect(function()
        TweenService:Create(StartBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 52, 0, 52),
            BackgroundColor3 = Colors.TopBarBg
        }):Play()
        TweenService:Create(StartStroke, TweenInfo.new(0.2), {Color = Colors.Accent, Transparency = 0.2}):Play()
    end)

    MakeDraggableStartBtn(StartBtn, StartBtn)
    MakeDraggable(MainFrame, TopBar)

    -- ==========================================
    -- 📁 ฟังก์ชันสร้าง Tab
    -- ==========================================
    function window:AddTab(TabConfig)
        local tab = {CountSection = 0}

        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = TabConfig.Name .. "_Tab"
        TabBtn.Size = UDim2.new(1, 0, 0, 38)
        TabBtn.BackgroundColor3 = Colors.CardBg
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.BorderSizePixel = 0
        TabBtn.ZIndex = 4
        TabBtn.Parent = Sidebar
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)

        -- แถบสีฟ้าบอกสถานะ Active
        local ActiveBar = Instance.new("Frame")
        ActiveBar.Name = "ActiveBar"
        ActiveBar.Size = UDim2.new(0, 3, 0, 18)
        ActiveBar.Position = UDim2.new(0, 0, 0.5, 0)
        ActiveBar.AnchorPoint = Vector2.new(0, 0.5)
        ActiveBar.BackgroundColor3 = Colors.Accent
        ActiveBar.BackgroundTransparency = 1
        ActiveBar.BorderSizePixel = 0
        ActiveBar.ZIndex = 6
        ActiveBar.Parent = TabBtn
        Instance.new("UICorner", ActiveBar).CornerRadius = UDim.new(1, 0)

        local TabContent = Instance.new("Frame")
        TabContent.Name = "Frame"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Parent = TabBtn

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 18, 0, 18)
        TabIcon.Position = UDim2.new(0, 12, 0.5, -9)
        TabIcon.Image = TabConfig.Icon or ""
        TabIcon.ImageColor3 = Colors.SubText
        TabIcon.BackgroundTransparency = 1
        TabIcon.ZIndex = 5
        TabIcon.Parent = TabContent

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "Label"
        TabLabel.Text = TabConfig.Name
        TabLabel.Size = UDim2.new(1, -42, 1, 0)
        TabLabel.Position = UDim2.new(0, 38, 0, 0)
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.TextSize = 13
        TabLabel.TextColor3 = Colors.SubText
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.BackgroundTransparency = 1
        TabLabel.ZIndex = 5
        TabLabel.Parent = TabContent

        -- หน้า Page ของแต่ละ Tab
        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabConfig.Name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = Colors.Accent
        Page.BorderSizePixel = 0
        Page.ScrollingEnabled = true
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.ZIndex = 4
        Page.ClipsDescendants = true
        Page.Parent = Container

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 12)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        local PagePadding = Instance.new("UIPadding", Page)
        PagePadding.PaddingTop = UDim.new(0, 2)
        PagePadding.PaddingLeft = UDim.new(0, 2)
        PagePadding.PaddingRight = UDim.new(0, 8)
        PagePadding.PaddingBottom = UDim.new(0, 14)

        -- หัวข้อใหญ่ประจำหน้า
        local PageHeaderFrame = Instance.new("Frame")
        PageHeaderFrame.Name = "PageHeader"
        PageHeaderFrame.Size = UDim2.new(1, -4, 0, 34)
        PageHeaderFrame.BackgroundTransparency = 1
        PageHeaderFrame.LayoutOrder = -100
        PageHeaderFrame.ZIndex = 5
        PageHeaderFrame.Parent = Page

        local PageTitle = Instance.new("TextLabel")
        PageTitle.Name = "PageTitle"
        PageTitle.Size = UDim2.new(1, 0, 0, 26)
        PageTitle.Text = TabConfig.Name
        PageTitle.Font = Enum.Font.GothamBold
        PageTitle.TextSize = 20
        PageTitle.TextColor3 = Colors.Text
        PageTitle.TextXAlignment = Enum.TextXAlignment.Left
        PageTitle.BackgroundTransparency = 1
        PageTitle.ZIndex = 5
        PageTitle.Parent = PageHeaderFrame

        local PageUnderline = Instance.new("Frame")
        PageUnderline.Size = UDim2.new(0, 36, 0, 3)
        PageUnderline.Position = UDim2.new(0, 0, 1, -3)
        PageUnderline.BackgroundColor3 = Colors.Accent
        PageUnderline.BorderSizePixel = 0
        PageUnderline.ZIndex = 5
        PageUnderline.Parent = PageHeaderFrame
        Instance.new("UICorner", PageUnderline).CornerRadius = UDim.new(1, 0)

        local function UpdateTabVisuals()
            for _, b in pairs(Sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    TweenService:Create(b, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    if b:FindFirstChild("ActiveBar") then
                        TweenService:Create(b.ActiveBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                    end
                    if b:FindFirstChild("Frame") then
                        b.Frame.Label.Font = Enum.Font.GothamMedium
                        TweenService:Create(b.Frame.Label, TweenInfo.new(0.2), {TextColor3 = Colors.SubText}):Play()
                        TweenService:Create(b.Frame.Icon, TweenInfo.new(0.2), {ImageColor3 = Colors.SubText}):Play()
                    end
                end
            end

            TweenService:Create(TabBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.CardHover,
                BackgroundTransparency = 0
            }):Play()
            TweenService:Create(ActiveBar, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TabLabel.Font = Enum.Font.GothamBold
            TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = Colors.Text}):Play()
            TweenService:Create(TabIcon, TweenInfo.new(0.2), {ImageColor3 = Colors.AccentLight}):Play()
        end

        TabBtn.MouseEnter:Connect(function()
            if not Page.Visible then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.15), {TextColor3 = Colors.Text}):Play()
            end
        end)

        TabBtn.MouseLeave:Connect(function()
            if not Page.Visible then
                TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
                TweenService:Create(TabLabel, TweenInfo.new(0.15), {TextColor3 = Colors.SubText}):Play()
            end
        end)

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

        -- ==========================================
        -- 📦 ฟังก์ชันสร้าง Section
        -- ==========================================
        function tab:AddSection(Title, Description, IconID)
            local sectionItems = {}
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = "SectionFrame"
            SectionFrame.Size = UDim2.new(1, 0, 0, 50)
            SectionFrame.BackgroundTransparency = 1
            SectionFrame.ZIndex = 5
            SectionFrame.ClipsDescendants = false
            tab.CountSection = tab.CountSection + 1
            SectionFrame.LayoutOrder = tab.CountSection
            SectionFrame.Parent = Page

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.Padding = UDim.new(0, 7)
            SectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Parent = SectionFrame

            -- ส่วนหัว Section สไตล์ Modern Card Header
            local HeaderContainer = Instance.new("Frame")
            HeaderContainer.Size = SizeItem.TitleItem
            HeaderContainer.BackgroundColor3 = Colors.SectionHeaderBg
            HeaderContainer.BorderSizePixel = 0
            HeaderContainer.ZIndex = 6
            HeaderContainer.Parent = SectionFrame

            Instance.new("UICorner", HeaderContainer).CornerRadius = UDim.new(0, 8)
            AddStroke(HeaderContainer, Colors.BorderHighlight, 1, 0.35)

            local HeaderGrad = Instance.new("UIGradient", HeaderContainer)
            HeaderGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 42, 66)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 26, 38))
            })

            local LeftAccent = Instance.new("Frame")
            LeftAccent.Size = UDim2.new(0, 3, 0, 22)
            LeftAccent.Position = UDim2.new(0, 0, 0.5, 0)
            LeftAccent.AnchorPoint = Vector2.new(0, 0.5)
            LeftAccent.BackgroundColor3 = Colors.Accent
            LeftAccent.BorderSizePixel = 0
            LeftAccent.ZIndex = 7
            LeftAccent.Parent = HeaderContainer
            Instance.new("UICorner", LeftAccent).CornerRadius = UDim.new(1, 0)

            if IconID then
                local SecIcon = Instance.new("ImageLabel")
                SecIcon.Size = UDim2.new(0, 20, 0, 20)
                SecIcon.Position = UDim2.new(0, 14, 0.5, -10)
                SecIcon.Image = IconID
                SecIcon.BackgroundTransparency = 1
                SecIcon.ImageColor3 = Colors.AccentLight
                SecIcon.ZIndex = 7
                SecIcon.Parent = HeaderContainer
            end

            local hasDesc = Description and Description ~= ""
            local textOffsetX = IconID and 42 or 14

            local HeaderTitle = Instance.new("TextLabel")
            HeaderTitle.Size = UDim2.new(1, -50, 0, 20)
            HeaderTitle.Position = hasDesc and UDim2.new(0, textOffsetX, 0, 6) or UDim2.new(0, textOffsetX, 0.5, -10)
            HeaderTitle.Text = Title
            HeaderTitle.Font = Enum.Font.GothamBold
            HeaderTitle.TextSize = 14
            HeaderTitle.TextColor3 = Colors.AccentLight
            HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.ZIndex = 7
            HeaderTitle.Parent = HeaderContainer

            if hasDesc then
                local Desc = Instance.new("TextLabel")
                Desc.Size = UDim2.new(1, -50, 0, 15)
                Desc.Position = UDim2.new(0, textOffsetX, 0, 25)
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

            -- Helper สร้าง Title + Description ภายในแถว
            local function CreateRowLabels(row, titleText, descText, rightReservedWidth)
                local hasRowDesc = descText and descText ~= ""
                local TTitle = Instance.new("TextLabel")
                TTitle.Text = titleText or ""
                TTitle.Size = UDim2.new(1, -rightReservedWidth, 0, 20)
                TTitle.Position = hasRowDesc and UDim2.new(0, 14, 0, 10) or UDim2.new(0, 14, 0.5, -10)
                TTitle.Font = Enum.Font.GothamBold
                TTitle.TextSize = 13
                TTitle.TextColor3 = Colors.Text
                TTitle.TextXAlignment = Enum.TextXAlignment.Left
                TTitle.BackgroundTransparency = 1
                TTitle.ZIndex = 8
                TTitle.Parent = row

                if hasRowDesc then
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = descText
                    TDesc.Size = UDim2.new(1, -rightReservedWidth, 0, 16)
                    TDesc.Position = UDim2.new(0, 14, 0, 31)
                    TDesc.Font = Enum.Font.Gotham
                    TDesc.TextSize = 11
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = row
                end
            end

            -- ==========================================
            -- 1. Toggle Switch
            -- ==========================================
            function sectionItems:AddToggleSwitch(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 85)

                local SwitchBg = Instance.new("TextButton")
                SwitchBg.Size = UDim2.new(0, 46, 0, 24)
                SwitchBg.Position = UDim2.new(1, -60, 0.5, -12)
                SwitchBg.BackgroundColor3 = Config.Default and Colors.SwitchOn or Colors.SwitchOff
                SwitchBg.AutoButtonColor = false
                SwitchBg.Text = ""
                SwitchBg.ZIndex = 9
                SwitchBg.Parent = Row
                Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
                local switchStroke = AddStroke(SwitchBg, Config.Default and Colors.AccentLight or Colors.Border, 1, 0.3)

                local Knob = Instance.new("Frame")
                Knob.Size = UDim2.new(0, 18, 0, 18)
                Knob.Position = Config.Default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                Knob.BackgroundColor3 = Colors.White
                Knob.ZIndex = 10
                Knob.Parent = SwitchBg
                Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

                local state = Config.Default or false
                UpdateState(Config.ID, state)

                local function VisualUpdate(val)
                    local targetPos = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    local targetColor = val and Colors.SwitchOn or Colors.SwitchOff
                    local strokeColor = val and Colors.AccentLight or Colors.Border
                    TweenService:Create(Knob, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {Position = targetPos}):Play()
                    TweenService:Create(SwitchBg, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundColor3 = targetColor}):Play()
                    TweenService:Create(switchStroke, TweenInfo.new(0.22), {Color = strokeColor}):Play()
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

            -- ==========================================
            -- 2. Slider
            -- ==========================================
            function sectionItems:AddSlider(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 180)

                local SliderContainer = Instance.new("Frame")
                SliderContainer.Size = UDim2.new(0, 155, 0, 42)
                SliderContainer.Position = UDim2.new(1, -168, 0.5, -21)
                SliderContainer.BackgroundTransparency = 1
                SliderContainer.ZIndex = 9
                SliderContainer.Parent = Row

                local ValueBadge = Instance.new("Frame")
                ValueBadge.Size = UDim2.new(0, 0, 0, 18)
                ValueBadge.AutomaticSize = Enum.AutomaticSize.X
                ValueBadge.Position = UDim2.new(1, 0, 0, 2)
                ValueBadge.AnchorPoint = Vector2.new(1, 0)
                ValueBadge.BackgroundColor3 = Colors.InputBg
                ValueBadge.ZIndex = 10
                ValueBadge.Parent = SliderContainer
                Instance.new("UICorner", ValueBadge).CornerRadius = UDim.new(0, 5)
                AddStroke(ValueBadge, Colors.Border, 1, 0.3)

                local BadgePad = Instance.new("UIPadding", ValueBadge)
                BadgePad.PaddingLeft = UDim.new(0, 6)
                BadgePad.PaddingRight = UDim.new(0, 6)

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(0, 0, 1, 0)
                ValueLabel.AutomaticSize = Enum.AutomaticSize.X
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(Config.Default or Config.Min) .. " / " .. tostring(Config.Max)
                ValueLabel.TextColor3 = Colors.AccentLight
                ValueLabel.Font = Enum.Font.RobotoMono
                ValueLabel.TextSize = 11
                ValueLabel.ZIndex = 11
                ValueLabel.Parent = ValueBadge

                local SliderBack = Instance.new("Frame")
                SliderBack.Size = UDim2.new(1, 0, 0, 6)
                SliderBack.Position = UDim2.new(0, 0, 0, 29)
                SliderBack.BackgroundColor3 = Colors.InputBg
                SliderBack.BorderSizePixel = 0
                SliderBack.ZIndex = 10
                SliderBack.Parent = SliderContainer
                Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)
                AddStroke(SliderBack, Colors.Border, 1, 0.4)

                local initialScale = math.clamp(((Config.Default or Config.Min) - Config.Min) / (Config.Max - Config.Min), 0, 1)

                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(initialScale, 0, 1, 0)
                SliderFill.BackgroundColor3 = Colors.Accent
                SliderFill.BorderSizePixel = 0
                SliderFill.ZIndex = 11
                SliderFill.Parent = SliderBack
                Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

                local Handle = Instance.new("Frame")
                Handle.Size = UDim2.new(0, 14, 0, 14)
                Handle.AnchorPoint = Vector2.new(0.5, 0.5)
                Handle.Position = UDim2.new(initialScale, 0, 0.5, 0)
                Handle.BackgroundColor3 = Colors.White
                Handle.ZIndex = 12
                Handle.Active = true
                Handle.Parent = SliderBack
                Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
                AddStroke(Handle, Colors.Accent, 2, 0)

                local dragging = false
                UpdateState(Config.ID, Config.Default or Config.Min)

                local function VisualUpdate(val)
                    local relativeX = math.clamp((val - Config.Min) / (Config.Max - Config.Min), 0, 1)
                    TweenService:Create(SliderFill, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = UDim2.new(relativeX, 0, 1, 0)}):Play()
                    TweenService:Create(Handle, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Position = UDim2.new(relativeX, 0, 0.5, 0)}):Play()
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
                    local mouseLocation = input.Position
                    local relativeX = math.clamp((mouseLocation.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    local value = math.floor(Config.Min + (Config.Max - Config.Min) * relativeX)

                    VisualUpdate(value)
                    UpdateState(Config.ID, value)
                    if Config.Callback then Config.Callback(value) end
                end

                SliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        TweenService:Create(Handle, TweenInfo.new(0.15), {Size = UDim2.new(0, 17, 0, 17)}):Play()
                        UpdateSlider(input)
                    end
                end)

                Handle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        TweenService:Create(Handle, TweenInfo.new(0.15), {Size = UDim2.new(0, 17, 0, 17)}):Play()
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        TweenService:Create(Handle, TweenInfo.new(0.15), {Size = UDim2.new(0, 14, 0, 14)}):Play()
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input)
                    end
                end)
            end

            -- ==========================================
            -- 3. Dropdown
            -- ==========================================
            function sectionItems:AddDropdown(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 205)

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(0, 180, 0, 34)
                Frame.Position = UDim2.new(1, -192, 0.5, -17)
                Frame.BackgroundColor3 = Colors.InputBg
                Frame.BorderSizePixel = 0
                Frame.ZIndex = 10
                Frame.Parent = Row
                Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 7)
                local boxStroke = AddStroke(Frame, Colors.Border, 1, 0)

                local Label = Instance.new("TextLabel")
                Label.Text = Config.Default or "เลือก..."
                Label.Size = UDim2.new(1, -36, 1, 0)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = Colors.Text
                Label.Font = Enum.Font.GothamMedium
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.ClipsDescendants = true
                Label.ZIndex = 11
                Label.Parent = Frame

                local ArrowIcon = Instance.new("ImageLabel")
                ArrowIcon.Image = "rbxassetid://74976956154520"
                ArrowIcon.Size = UDim2.new(0, 12, 0, 12)
                ArrowIcon.Position = UDim2.new(1, -22, 0.5, -6)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.ImageColor3 = Colors.SubText
                ArrowIcon.ZIndex = 12
                ArrowIcon.Parent = Frame

                local DropdownClickBtn = Instance.new("TextButton")
                DropdownClickBtn.Size = UDim2.new(1, 0, 1, 0)
                DropdownClickBtn.BackgroundTransparency = 1
                DropdownClickBtn.Text = ""
                DropdownClickBtn.ZIndex = 15
                DropdownClickBtn.Parent = Frame

                local List = Instance.new("Frame")
                List.Name = "DropdownList"
                List.BackgroundColor3 = Colors.DropdownBg
                List.BorderSizePixel = 0
                List.ZIndex = 1000
                List.Visible = false
                List.ClipsDescendants = true
                List.Parent = MainFrame
                Instance.new("UICorner", List).CornerRadius = UDim.new(0, 8)
                AddStroke(List, Colors.BorderHighlight, 1.2, 0)

                local SearchContainer = Instance.new("Frame")
                SearchContainer.Size = UDim2.new(1, -12, 0, 28)
                SearchContainer.Position = UDim2.new(0, 6, 0, 6)
                SearchContainer.BackgroundColor3 = Colors.InputBg
                SearchContainer.ZIndex = 1001
                SearchContainer.Parent = List
                Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 6)
                AddStroke(SearchContainer, Colors.Border, 1, 0.3)

                local SearchBox = Instance.new("TextBox")
                SearchBox.Size = UDim2.new(1, -16, 1, 0)
                SearchBox.Position = UDim2.new(0, 8, 0, 0)
                SearchBox.BackgroundTransparency = 1
                SearchBox.PlaceholderText = "🔍 ค้นหา..."
                SearchBox.PlaceholderColor3 = Colors.MutedText
                SearchBox.TextColor3 = Colors.Text
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.Text = ""
                SearchBox.TextSize = 12
                SearchBox.TextXAlignment = Enum.TextXAlignment.Left
                SearchBox.ZIndex = 1002
                SearchBox.Parent = SearchContainer

                local ItemScroll = Instance.new("ScrollingFrame")
                ItemScroll.Size = UDim2.new(1, -8, 1, -42)
                ItemScroll.Position = UDim2.new(0, 4, 0, 38)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.BorderSizePixel = 0
                ItemScroll.ScrollBarThickness = 3
                ItemScroll.ScrollBarImageColor3 = Colors.Accent
                ItemScroll.ZIndex = 1001
                ItemScroll.Parent = List

                local ItemListLayout = Instance.new("UIListLayout", ItemScroll)
                ItemListLayout.Padding = UDim.new(0, 3)

                local syncConnection
                local currentlySelected = Config.Default or nil
                UpdateState(Config.ID, currentlySelected)

                local function UpdateListPosition()
                    if List.Visible then
                        local absPos = Frame.AbsolutePosition
                        local mainAbsPos = MainFrame.AbsolutePosition
                        local contentHeight = ItemListLayout.AbsoluteContentSize.Y
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 6)
                        local dynamicHeight = math.clamp(contentHeight + 46, 75, 210)
                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y + 4)
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
                            itemBtn.Size = UDim2.new(1, -4, 0, 28)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Text = "   " .. tostring(item)
                            itemBtn.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium
                            itemBtn.TextSize = 12
                            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                            itemBtn.ZIndex = 1002
                            itemBtn.BackgroundColor3 = isSelected and Colors.Accent or Colors.CardBg
                            itemBtn.BackgroundTransparency = isSelected and 0.15 or 0.4
                            itemBtn.TextColor3 = isSelected and Colors.White or Colors.SubText
                            itemBtn.Parent = ItemScroll
                            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)

                            itemBtn.MouseEnter:Connect(function()
                                if item ~= currentlySelected then
                                    TweenService:Create(itemBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.CardHover, BackgroundTransparency = 0, TextColor3 = Colors.Text}):Play()
                                end
                            end)
                            itemBtn.MouseLeave:Connect(function()
                                if item ~= currentlySelected then
                                    TweenService:Create(itemBtn, TweenInfo.new(0.12), {BackgroundColor3 = Colors.CardBg, BackgroundTransparency = 0.4, TextColor3 = Colors.SubText}):Play()
                                end
                            end)

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

                DropdownClickBtn.MouseEnter:Connect(function()
                    TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Accent}):Play()
                end)
                DropdownClickBtn.MouseLeave:Connect(function()
                    if not List.Visible then
                        TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Border}):Play()
                    end
                end)

                DropdownClickBtn.MouseButton1Click:Connect(function()
                    if List.Visible then
                        CloseAllDropdowns()
                        TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Border}):Play()
                        if syncConnection then syncConnection:Disconnect() end
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 180}):Play()
                        TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Accent}):Play()
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

            -- ==========================================
            -- 4. MultiSelect
            -- ==========================================
            function sectionItems:AddMultiSelect(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 205)

                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(0, 180, 0, 34)
                Frame.Position = UDim2.new(1, -192, 0.5, -17)
                Frame.BackgroundColor3 = Colors.InputBg
                Frame.BorderSizePixel = 0
                Frame.ZIndex = 10
                Frame.Parent = Row
                Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 7)
                local boxStroke = AddStroke(Frame, Colors.Border, 1, 0)

                local Label = Instance.new("TextLabel")
                Label.Text = "None"
                Label.Size = UDim2.new(1, -36, 1, 0)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextColor3 = Colors.Text
                Label.Font = Enum.Font.GothamMedium
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.ClipsDescendants = true
                Label.ZIndex = 11
                Label.Parent = Frame

                local ArrowIcon = Instance.new("ImageLabel")
                ArrowIcon.Image = "rbxassetid://74976956154520"
                ArrowIcon.Size = UDim2.new(0, 12, 0, 12)
                ArrowIcon.Position = UDim2.new(1, -22, 0.5, -6)
                ArrowIcon.BackgroundTransparency = 1
                ArrowIcon.ImageColor3 = Colors.SubText
                ArrowIcon.ZIndex = 12
                ArrowIcon.Parent = Frame

                local MultiClickBtn = Instance.new("TextButton")
                MultiClickBtn.Size = UDim2.new(1, 0, 1, 0)
                MultiClickBtn.BackgroundTransparency = 1
                MultiClickBtn.Text = ""
                MultiClickBtn.ZIndex = 15
                MultiClickBtn.Parent = Frame

                local List = Instance.new("Frame")
                List.Name = "MultiSelectList"
                List.BackgroundColor3 = Colors.DropdownBg
                List.BorderSizePixel = 0
                List.ZIndex = 1000
                List.Visible = false
                List.ClipsDescendants = true
                List.Parent = MainFrame
                Instance.new("UICorner", List).CornerRadius = UDim.new(0, 8)
                AddStroke(List, Colors.BorderHighlight, 1.2, 0)

                local SearchContainer = Instance.new("Frame")
                SearchContainer.Size = UDim2.new(1, -12, 0, 28)
                SearchContainer.Position = UDim2.new(0, 6, 0, 6)
                SearchContainer.BackgroundColor3 = Colors.InputBg
                SearchContainer.ZIndex = 1001
                SearchContainer.Parent = List
                Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 6)
                AddStroke(SearchContainer, Colors.Border, 1, 0.3)

                local SearchBox = Instance.new("TextBox")
                SearchBox.Size = UDim2.new(1, -16, 1, 0)
                SearchBox.Position = UDim2.new(0, 8, 0, 0)
                SearchBox.BackgroundTransparency = 1
                SearchBox.PlaceholderText = "🔍 ค้นหา..."
                SearchBox.PlaceholderColor3 = Colors.MutedText
                SearchBox.TextColor3 = Colors.Text
                SearchBox.Font = Enum.Font.Gotham
                SearchBox.Text = ""
                SearchBox.TextSize = 12
                SearchBox.TextXAlignment = Enum.TextXAlignment.Left
                SearchBox.ZIndex = 1002
                SearchBox.Parent = SearchContainer

                local ItemScroll = Instance.new("ScrollingFrame")
                ItemScroll.Size = UDim2.new(1, -8, 1, -42)
                ItemScroll.Position = UDim2.new(0, 4, 0, 38)
                ItemScroll.BackgroundTransparency = 1
                ItemScroll.BorderSizePixel = 0
                ItemScroll.ScrollBarThickness = 3
                ItemScroll.ScrollBarImageColor3 = Colors.Accent
                ItemScroll.ZIndex = 1001
                ItemScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
                ItemScroll.Parent = List

                local ListLayout = Instance.new("UIListLayout", ItemScroll)
                ListLayout.Padding = UDim.new(0, 3)

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
                        ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 6)
                        local dynamicHeight = math.clamp(contentHeight + 46, 75, 210)
                        List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                        List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y + 4)
                    end
                end

                local function Populate(filter)
                    for _, child in pairs(ItemScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, item in pairs(Config.Options or {}) do
                        if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                            local itemBtn = Instance.new("TextButton")
                            itemBtn.Size = UDim2.new(1, -4, 0, 28)
                            itemBtn.BorderSizePixel = 0
                            itemBtn.AutoButtonColor = false
                            itemBtn.Font = Enum.Font.GothamMedium
                            itemBtn.TextSize = 12
                            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                            itemBtn.ZIndex = 1002
                            itemBtn.Parent = ItemScroll
                            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)

                            local function RefreshColor()
                                local isChecked = type(selectedItems) == "table" and table.find(selectedItems, item)
                                if isChecked then
                                    itemBtn.Text = "  ✓  " .. tostring(item)
                                    itemBtn.Font = Enum.Font.GothamBold
                                    itemBtn.BackgroundColor3 = Colors.Accent
                                    itemBtn.BackgroundTransparency = 0.15
                                    itemBtn.TextColor3 = Colors.White
                                else
                                    itemBtn.Text = "      " .. tostring(item)
                                    itemBtn.Font = Enum.Font.GothamMedium
                                    itemBtn.BackgroundColor3 = Colors.CardBg
                                    itemBtn.BackgroundTransparency = 0.4
                                    itemBtn.TextColor3 = Colors.SubText
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

                MultiClickBtn.MouseEnter:Connect(function()
                    TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Accent}):Play()
                end)
                MultiClickBtn.MouseLeave:Connect(function()
                    if not List.Visible then
                        TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Border}):Play()
                    end
                end)

                MultiClickBtn.MouseButton1Click:Connect(function()
                    if List.Visible then
                        CloseAllDropdowns()
                        TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Border}):Play()
                        if syncConnection then syncConnection:Disconnect() end
                    else
                        CloseAllDropdowns()
                        List.Visible = true
                        activeDropdownList = List
                        activeDropdownArrow = ArrowIcon
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 180}):Play()
                        TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = Colors.Accent}):Play()
                        ItemScroll.CanvasPosition = Vector2.new(0, 0)
                        SearchBox.Text = ""
                        Populate("")
                        UpdateListPosition()
                        if syncConnection then syncConnection:Disconnect() end
                        syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
                    end
                end)
            end

            -- ==========================================
            -- 5. Input Box
            -- ==========================================
            function sectionItems:AddInput(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 180)

                local InputFrame = Instance.new("Frame")
                InputFrame.Size = UDim2.new(0, 155, 0, 34)
                InputFrame.Position = UDim2.new(1, -168, 0.5, -17)
                InputFrame.BackgroundColor3 = Colors.InputBg
                InputFrame.BorderSizePixel = 0
                InputFrame.ClipsDescendants = true
                InputFrame.ZIndex = 9
                InputFrame.Parent = Row
                Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 7)
                local inputStroke = AddStroke(InputFrame, Colors.Border, 1, 0)

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -18, 1, 0)
                TextBox.Position = UDim2.new(0, 9, 0, 0)
                TextBox.BackgroundTransparency = 1
                TextBox.Text = Config.Default or ""
                TextBox.PlaceholderText = Config.Placeholder or "พิมพ์ที่นี่..."
                TextBox.PlaceholderColor3 = Colors.MutedText
                TextBox.TextColor3 = Colors.Text
                TextBox.TextSize = 12
                TextBox.Font = Enum.Font.GothamMedium
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
                    TweenService:Create(inputStroke, TweenInfo.new(0.15), {Color = Colors.Accent, Thickness = 1.4}):Play()
                end)

                TextBox.FocusLost:Connect(function(enterPressed)
                    TweenService:Create(inputStroke, TweenInfo.new(0.15), {Color = Colors.Border, Thickness = 1}):Play()
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

            -- ==========================================
            -- 6. Button
            -- ==========================================
            function sectionItems:AddButton(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 155)

                local Button = Instance.new("TextButton")
                Button.Name = "ActionBtn"
                Button.Size = UDim2.new(0, 125, 0, 32)
                Button.Position = UDim2.new(1, -138, 0.5, -16)
                Button.BackgroundColor3 = Colors.ButtonBg
                Button.AutoButtonColor = false
                Button.Text = Config.ButtonText or "Click"
                Button.Font = Enum.Font.GothamBold
                Button.TextSize = 12
                Button.TextColor3 = Colors.Text
                Button.ZIndex = 9
                Button.Parent = Row
                Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 7)
                local btnStroke = AddStroke(Button, Colors.BorderHighlight, 1, 0.2)

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Accent}):Play()
                    TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = Colors.AccentLight, Transparency = 0}):Play()
                end)

                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Colors.ButtonBg}):Play()
                    TweenService:Create(btnStroke, TweenInfo.new(0.15), {Color = Colors.BorderHighlight, Transparency = 0.2}):Play()
                end)

                Button.MouseButton1Down:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.AccentDark}):Play()
                end)

                Button.MouseButton1Up:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.08), {BackgroundColor3 = Colors.Accent}):Play()
                end)

                Button.MouseButton1Click:Connect(function()
                    if Config.Callback then Config.Callback() end
                end)

                return Button
            end

            -- ==========================================
            -- 7. Label / Status Banner
            -- ==========================================
            function sectionItems:AddLabel(Title)
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, -4, 0, 38)
                Row.BackgroundColor3 = Colors.SectionHeaderBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AddStroke(Row, Colors.Border, 1, 0.3)

                local Accent = Instance.new("Frame")
                Accent.Size = UDim2.new(0, 3, 1, -12)
                Accent.Position = UDim2.new(0, 6, 0.5, 0)
                Accent.AnchorPoint = Vector2.new(0, 0.5)
                Accent.BackgroundColor3 = Colors.Accent
                Accent.BorderSizePixel = 0
                Accent.ZIndex = 8
                Accent.Parent = Row
                Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)

                local TTitle = Instance.new("TextLabel")
                TTitle.Text = "ℹ️  " .. tostring(Title)
                TTitle.Size = UDim2.new(1, -28, 1, 0)
                TTitle.Position = UDim2.new(0, 18, 0, 0)
                TTitle.Font = Enum.Font.GothamMedium
                TTitle.TextSize = 12
                TTitle.TextColor3 = Colors.AccentLight
                TTitle.TextXAlignment = Enum.TextXAlignment.Left
                TTitle.TextWrapped = true
                TTitle.BackgroundTransparency = 1
                TTitle.ZIndex = 8
                TTitle.Parent = Row

                TTitle:GetPropertyChangedSignal("Text"):Connect(function()
                    local textHeight = TTitle.TextBounds.Y
                    Row.Size = UDim2.new(1, -4, 0, math.max(38, textHeight + 16))
                end)

                local labelFunc = {}
                function labelFunc:Set(newText)
                    TTitle.Text = "ℹ️  " .. tostring(newText)
                end
                function labelFunc:SetColor(color)
                    Accent.BackgroundColor3 = color
                    TTitle.TextColor3 = color
                end

                return labelFunc
            end

            -- ==========================================
            -- 8. Keybind
            -- ==========================================
            function sectionItems:AddKeybind(Config)
                local Row = Instance.new("Frame")
                Row.Size = SizeItem.BoxItem
                Row.BackgroundColor3 = Colors.CardBg
                Row.BorderSizePixel = 0
                Row.ZIndex = 7
                Row.Parent = SectionFrame
                Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
                AttachCardHover(Row)

                CreateRowLabels(Row, Config.Title, Config.Description, 125)

                local currentKey = Config.Default
                local keyConnection

                local BindButton = Instance.new("TextButton")
                BindButton.Size = UDim2.new(0, 96, 0, 30)
                BindButton.Position = UDim2.new(1, -110, 0.5, -15)
                BindButton.BackgroundColor3 = Colors.InputBg
                BindButton.AutoButtonColor = false
                BindButton.Text = currentKey and "[ " .. currentKey.Name .. " ]" or "[ None ]"
                BindButton.Font = Enum.Font.RobotoMono
                BindButton.TextSize = 12
                BindButton.TextColor3 = Colors.AccentLight
                BindButton.ZIndex = 9
                BindButton.Parent = Row
                Instance.new("UICorner", BindButton).CornerRadius = UDim.new(0, 6)
                local bStroke = AddStroke(BindButton, Colors.BorderHighlight, 1, 0.2)

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
                                BindButton.Text = "[ " .. valName .. " ]"
                                StartListening()
                            end
                        end
                    }
                end

                if currentKey then StartListening() end

                BindButton.MouseButton1Click:Connect(function()
                    if IsBinding then return end
                    IsBinding = true
                    BindButton.Text = "[ Press... ]"
                    BindButton.TextColor3 = Colors.White
                    TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = Colors.Accent, Transparency = 0}):Play()

                    local tempConnection
                    tempConnection = UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode
                            if newKey ~= Enum.KeyCode.Escape then
                                currentKey = newKey
                                BindButton.Text = "[ " .. newKey.Name .. " ]"
                                UpdateState(Config.ID, newKey.Name)
                                StartListening()
                            else
                                BindButton.Text = currentKey and "[ " .. currentKey.Name .. " ]" or "[ None ]"
                            end

                            BindButton.TextColor3 = Colors.AccentLight
                            TweenService:Create(bStroke, TweenInfo.new(0.15), {Color = Colors.BorderHighlight, Transparency = 0.2}):Play()
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


-- =====================================================================
-- 🚀 เริ่มใช้งาน XP Hub Premium API (ตัวอย่างการใช้งานของคุณ)
-- =====================================================================

local Win = XPHub:Window({
    Title = UI_TITLE,
})

local Tab1 = Win:AddTab({
    Name = "Dashboard",
    Icon = "rbxassetid://7733960981"
})

local Sec1 = Tab1:AddSection("🔥 General", "ปรับปรุงระบบโครงสร้างใหม่")

Sec1:AddDropdown({
    ID = "TargetNPC",
    Title = "เลือกศัตรูเป้าหมาย",
    Description = "เลือก NPC ที่ต้องการให้ระบบฟาร์มโจมตี",
    Options = {"Monkey", "Gorilla", "Goden Sun", "Snowman", "Yeti", "Dragon", "Snowman2", "Yeti2", "Dragon2"},
    Default = "Monkey",
    Callback = function(v) print("Selected NPC:", v) end
})

Sec1:AddMultiSelect({
    ID = "SelectedItems",
    Title = "Select Items",
    Description = "เลือกได้หลายรายการ",
    Options = {"Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6", "Item 7", "Item 8"},
    Default = {"Item 1"},
    Callback = function(v) print("Current Selected:", table.concat(v, ", ")) end
})

Sec1:AddToggleSwitch({
    ID = "AutoFarm",
    Title = "Enable Farm",
    Description = "ฟาร์มมอนสเตอร์ที่เลือกไว้",
    Default = false,
    Callback = function(v) end
})

Sec1:AddSlider({
    ID = "CharacterSpeed",
    Title = "WalkSpeed",
    Description = "ปรับความเร็วในการเคลื่อนที่",
    Min = 16,
    Max = 300,
    Default = 16,
    Callback = function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

Sec1:AddSlider({
    ID = "FieldOfView",
    Title = "Field of View",
    Description = "ปรับระยะการมองเห็น (FOV)",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end
})

Sec1:AddInput({
    ID = "WebhookURL",
    Title = "Webhook URL",
    Description = "ใส่ URL สำหรับส่งข้อมูลไปยัง Discord",
    Placeholder = "https://discord.com/api/...",
    Callback = function(text, enter)
        print("Webhook set to:", text)
    end
})

Sec1:AddButton({
    Title = "Reset Character",
    Description = "ฆ่าตัวตายเพื่อกลับจุดเกิด",
    ButtonText = "Reset Now",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            print("ตัวละครถูกรีเซ็ตแล้ว")
        end
    end
})

Sec1:AddButton({
    Title = "Copy Job ID",
    Description = "คัดลอกไอดีเซิร์ฟเวอร์ปัจจุบัน",
    ButtonText = "Copy",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            print("คัดลอก Job ID แล้ว!")
        end
    end
})

------------------------------------------------------- Tab 2 -------------------------------------------------------

local Tab2 = Win:AddTab({
    Name = "Settings",
    Icon = "rbxassetid://7734053495"
})

local SecKeybind = Tab2:AddSection("⌨️ Keybind Open/Minimize UI", "ตั้งค่าปุ่มเปิด/ปิดหน้าจอ (Keybind)")

SecKeybind:AddToggleSwitch({
    ID = "EnableBind_UI",
    Title = "Enable Keybind",
    Description = "เปิดใช้งานปุ่มเปิด/ปิดหน้าจอ",
    Default = false,
    Callback = function(v) end
})

SecKeybind:AddKeybind({
    ID = "MenuBind",
    Title = "Keybind Open/Close",
    Description = "กดปุ่มลัดเพื่อซ่อนหรือแสดงเมนูหลัก",
    Default = Enum.KeyCode.G,
    Callback = function(key)
        if XPHub.ConfigData["EnableBind_UI"] == true and XPHub.ToggleUI then
            XPHub.ToggleUI()
        end
    end
})

local SecConfig = Tab2:AddSection("⚙️ Configuration (Save/Load)", "ระบบบันทึก Config (Save/Load)")

local StatusLabel
local ConfigName = ""
local SelectedFile = ""
local ConfigDropdown

SecConfig:AddInput({
    Title = "Config Name",
    Description = "พิมพ์ชื่อที่ต้องการบันทึกใหม่",
    Placeholder = "เช่น ProFarm_V1",
    Callback = function(text)
        ConfigName = text
    end
})

SecConfig:AddButton({
    Title = "Create Config",
    Description = "บันทึกการตั้งค่าปัจจุบันลงไฟล์ใหม่",
    ButtonText = "Create New",
    Callback = function()
        if ConfigName ~= "" then
            SaveCurrentConfig(ConfigName)
            if ConfigDropdown and ConfigDropdown.Refresh then
                ConfigDropdown:Refresh(GetConfigList())
            end
            print("Saved New: " .. ConfigName)
        end
    end
})

ConfigDropdown = SecConfig:AddDropdown({
    Title = "Config List",
    Description = "เลือกไฟล์ที่ต้องการจัดการ",
    Options = GetConfigList(),
    Default = "---",
    Callback = function(selected)
        SelectedFile = selected
    end
})

SecConfig:AddButton({
    Title = "Overwrite Config",
    Description = "เซฟทับไฟล์ที่เลือกอยู่ใน List",
    ButtonText = "Overwrite",
    Callback = function()
        if SelectedFile ~= "" and SelectedFile ~= "---" then
            SaveCurrentConfig(SelectedFile)
            print("Overwrote: " .. SelectedFile)
        end
    end
})

SecConfig:AddButton({
    Title = "Load Config",
    Description = "ดึงค่าจากไฟล์มาใช้งาน",
    ButtonText = "Load",
    Callback = function()
        if SelectedFile ~= "" and SelectedFile ~= "---" then
            LoadConfigData(SelectedFile)
            print("Loaded: " .. SelectedFile)
        end
    end
})

SecConfig:AddButton({
    Title = "Set as Autoload",
    Description = "ตั้งให้โหลดไฟล์นี้ทุกครั้งที่รันสคริปต์",
    ButtonText = "Set Auto",
    Callback = function()
        if SelectedFile ~= "" and SelectedFile ~= "---" then
            SetAutoload(SelectedFile)
            StatusLabel:Set("Current Autoload: " .. SelectedFile)
            print("Autoload set to: " .. SelectedFile)
        end
    end
})

SecConfig:AddButton({
    Title = "Reset Autoload",
    Description = "ยกเลิกการโหลดอัตโนมัติ",
    ButtonText = "Reset",
    Callback = function()
        ResetAutoload()
        StatusLabel:Set("Current Autoload: None")
        print("Autoload Disabled")
    end
})

SecConfig:AddButton({
    Title = "Delete Config",
    Description = "ลบไฟล์การตั้งค่าที่เลือกอยู่ถาวร",
    ButtonText = "Delete",
    Callback = function()
        if SelectedFile ~= "" and SelectedFile ~= "---" then
            local filePath = ConfigFolder .. "/" .. SelectedFile .. ".json"
            if isfile and delfile and isfile(filePath) then
                delfile(filePath)
                if ConfigDropdown then
                    ConfigDropdown:Refresh(GetConfigList())
                    ConfigDropdown:Set("---")
                end
                SelectedFile = ""
                print("Deleted and Reset Dropdown!")
            end
        end
    end
})

StatusLabel = SecConfig:AddLabel("Current Autoload: " .. (GetAutoload() or "None"))

-- ### AUTOLOAD EXECUTION ###
task.spawn(function()
    task.wait(1.5)
    local auto = GetAutoload()
    if auto then LoadConfigData(auto) end
end)
