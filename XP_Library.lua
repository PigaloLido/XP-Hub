local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TS = game:GetService("TweenService")


-- 1. ชื่อต้องตรงกับที่ตั้งใน ScreenGui.Name
local UI_NAME = "XPHub_UI" 
local UI_TITLE = "XP Hub 〢 Premium"
local UI_CREDIT = "By : Pigalo"
local UI_VERSION = "|  v1.0.0"

-- 2. เช็คทั้งใน CoreGui (รันผ่านรันเนอร์) และ PlayerGui (กรณีทั่วไป)
local OldUI = game:GetService("CoreGui"):FindFirstChild(UI_NAME) or 
              game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild(UI_NAME)

if OldUI then
    -- ถ้าเจอของเก่า ให้พิมพ์บอกใน Console แล้วหยุดรันสคริปต์ใหม่ทันที
    warn("สคริปต์รันอยู่แล้ว! | The script is already running!")
    return
end



local XPHub = { 
    Elements = {},   
    ConfigData = {}, 
    Objects = {}, -- สำหรับระบบ Save/Load
    MainFrame = nil,
    ConfigFolder = "XPHub_Configs"
}

local activeDropdownList = nil

if not isfolder(XPHub.ConfigFolder) then 
    makefolder(XPHub.ConfigFolder) 
end


function XPHub:GetConfigList()
    local files = listfiles(self.ConfigFolder)
    local names = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local cleanPath = file:gsub("\\", "/")
            local name = cleanPath:gsub(self.ConfigFolder .. "/", ""):gsub(".json", "")
            table.insert(names, name)
        end
    end
    return names
end

function XPHub:SaveCurrentConfig(name)
    if not name or name == "" then return end
    local json = game:GetService("HttpService"):JSONEncode(self.ConfigData)
    writefile(self.ConfigFolder.."/"..name..".json", json)
    print("Successfully saved config: " .. name)
end

function XPHub:LoadConfigData(name)
    local fileName = self.ConfigFolder .. "/" .. name .. ".json"
    if isfile(fileName) then
        local json = readfile(fileName)
        local data = game:GetService("HttpService"):JSONDecode(json)
        for id, value in pairs(data) do self.ConfigData[id] = value end
        
        -- เรียก ApplySettings (ฟังก์ชันภายใน)
        if ApplySettings then 
            ApplySettings(data) 
        end
        print("Successfully loaded config: " .. name)
        return data
    end
    return nil
end

local AutoloadPath = XPHub.ConfigFolder .. "/autoload.txt"
function XPHub:SetAutoload(name) writefile(AutoloadPath, name) end
function XPHub:GetAutoload() return isfile(AutoloadPath) and readfile(AutoloadPath) or nil end
function XPHub:ResetAutoload() if isfile(AutoloadPath) then delfile(AutoloadPath) end end


local function ApplySettings(data)
    for id, value in pairs(data) do
        local obj = XPHub.Objects[id]
        if obj then
            if obj.Update then obj.Update(value) end
            if obj.Callback then
                task.spawn(function()
                    pcall(function() obj.Callback(value) end)
                end)
            end
        end
    end
end

local function UpdateState(id, value)
    if id then 
        XPHub.ConfigData[id] = value 
    end
end

local function ResetAllSettings()
    -- วนลูปตาม IDs ทั้งหมดที่บันทึกไว้ใน Objects
    for id, obj in pairs(XPHub.Objects) do
        
        -- 1. จัดการส่วน Keybind (ต้องสั่งหยุดการดักฟังปุ่มทันที)
        if obj.Type == "Keybind" then
            pcall(function()
                -- ถ้ามีฟังก์ชัน Stop ให้รันเพื่อตัด Connection
                if obj.Stop then
                    obj.Stop()
                -- กรณีไม่ได้ใช้โครงสร้าง Stop ให้ลองตัด Connection ตรงๆ (แผนสำรอง)
                elseif obj.Connection then
                    obj.Connection:Disconnect()
                end
            end)
            -- เมื่อหยุด Keybind แล้ว ให้ข้ามไปทำไอเทมตัวถัดไปในลูปทันที
            continue 
        end

        -- 2. จัดการส่วน Component อื่นๆ (Toggle, Slider, Dropdown, Input)
        if obj.Callback then
            local defaultValue = nil
            
            -- กำหนดค่าเริ่มต้นตามประเภทของ Component เพื่อ Reset ระบบเกม
            if obj.Type == "Slider" then
                -- Reset กลับไปค่าต่ำสุดที่ตั้งไว้
                defaultValue = (obj.Config and obj.Config.Min) or 0
            elseif obj.Type == "Toggle" then
                -- ปิดฟังก์ชันการทำงานทั้งหมด
                defaultValue = false
            elseif obj.Type == "Dropdown" then
                -- ป้องกัน Error 'concat' โดยคืนค่าเป็นข้อความว่าง หรือค่า Default
                defaultValue = obj.Default or ""
            elseif obj.Type == "Input" then
                defaultValue = ""
            end
            
            -- สั่งรัน Callback เพื่อคืนค่าในเกม (เช่น คืนค่า WalkSpeed เป็น 16)
            if defaultValue ~= nil then
                -- ใช้ task.spawn เพื่อให้การ Reset แต่ละตัวไม่ขัดจังหวะกัน
                task.spawn(function()
                    -- pcall ป้องกันกรณี Error หากฟังก์ชัน Callback อ้างอิงถึงสิ่งที่ถูกลบไปแล้ว
                    pcall(function()
                        obj.Callback(defaultValue)
                    end)
                end)
            end
            
            -- อัปเดตหน้าตา UI ให้กลับไปจุดเริ่มต้น (ถ้า UI ยังไม่โดน Destroy)
            if obj.Update then
                pcall(function()
                    obj.Update(defaultValue)
                end)
            end
        end
    end
    
    print("Kill Switch: ทุกระบบถูก Reset และตัดการเชื่อมต่อ Keybind เรียบร้อยแล้ว")
end


-- ธีมสีหลัก Windows XP
local Colors = {
    TitleBarDark = Color3.fromRGB(0, 80, 230),
    TitleBarLight = Color3.fromRGB(45, 140, 255),
    Background = Color3.fromRGB(236, 233, 216),
    Sidebar = Color3.fromRGB(214, 211, 191),
    Text = Color3.fromRGB(0, 0, 0),
    SubText = Color3.fromRGB(80, 80, 80),
    
    -- ปุ่มควบคุม
    CloseRed = Color3.fromRGB(232, 17, 35),
    CloseRedLight = Color3.fromRGB(255, 100, 100),
    ControlBlue = Color3.fromRGB(45, 120, 255),
    ControlBlueLight = Color3.fromRGB(100, 180, 255),
    
    -- ส่วนประกอบ
    StartGreen = Color3.fromRGB(58, 175, 58),
    White = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(128, 128, 128),
    ScrollBarThumb = Color3.fromRGB(37, 71, 46),
    ButtonClassic = Color3.fromRGB(212, 208, 200),
    DropdownSelectBlue = Color3.fromRGB(10, 36, 106), 
    SwitchOn = Color3.fromRGB(0, 100, 255),
    SwitchOff = Color3.fromRGB(180, 180, 180),
    InputBackground = Color3.fromRGB(255, 255, 255),
    XPInputBorder = Color3.fromRGB(127, 157, 185) -- ขอบน้ำเงินสไตล์ XP สำหรับ Input

}

local SizeItem = {
    -- ขนาด
    BoxItem = UDim2.new(0.980, 0, 0, 65),
    TitleItem = UDim2.new(0.980, 0, 0, 45)
}

-- ฟังก์ชันปิด Dropdown ทั้งหมด
local function CloseAllDropdowns()
    if activeDropdownList then
        activeDropdownList.Visible = false
        activeDropdownList = nil
    end
end

-- ระบบลากหน้าต่าง
local function MakeDraggable(obj, dragPart)
    local dragging, dragInput, dragStart, startPos
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
            -- คำนวณขนาดใหม่ (ตั้งขั้นต่ำไว้ที่ 500x350 เพื่อไม่ให้ UI พัง)
            local newWidth = math.max(500, startSize.X.Offset + delta.X)
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

local wasDragging = false -- ตัวแปรกลางสำหรับเช็คสถานะการลาก (ไว้ใช้ร่วมกับ MouseButton1Click)
local lastScreenRatioX = 0.5 -- ค่าเริ่มต้นกึ่งกลางจอ
local lastScreenRatioY = 0.05 -- ค่าเริ่มต้นขอบบน

-- ฟังก์ชันหลักสำหรับการลาก
local function MakeDraggableStartBtn(obj, dragPart)
    local dragging = false
    local dragInput, dragStart, startPos
    
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            wasDragging = false -- รีเซ็ตสถานะทุกครั้งที่เริ่มจิ้ม
            dragStart = input.Position
            startPos = obj.Position
            
            -- ดักจับตอนปล่อยปุ่มเพื่อหยุดการลาก
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
            
            -- ถ้าเมาส์ขยับเกิน 5 pixels ให้ถือว่าเป็นการลาก (จะไปล็อคไม่ให้เมนูเปิด)
            if delta.Magnitude > 5 then
                wasDragging = true
            end
            
            -- คำนวณตำแหน่งพิกัดใหม่
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            
            -- ระบบกันออกนอกจอ (Clamp)
            local parentScreen = obj:FindFirstAncestorOfClass("ScreenGui")
            if parentScreen then
                local screenSize = parentScreen.AbsoluteSize
                local btnSize = obj.AbsoluteSize
                
                -- แปลงพิกัดทั้งหมดเป็น Offset เพื่อหาจุดที่แน่นอนบนหน้าจอ
                local currentX = newPos.X.Offset + (screenSize.X * newPos.X.Scale)
                local currentY = newPos.Y.Offset + (screenSize.Y * newPos.Y.Scale)
                
                -- ล็อคไม่ให้ค่าเกินขอบจอ (0 ถึง ขนาดจอ-ขนาดปุ่ม)
                local finalX = math.clamp(currentX, 0, screenSize.X - btnSize.X)
                local finalY = math.clamp(currentY, 0, screenSize.Y - btnSize.Y)
                
                -- อัปเดตตำแหน่งปุ่ม
                obj.Position = UDim2.new(0, finalX, 0, finalY)
            else
                -- กรณีฉุกเฉินถ้าหา ScreenGui ไม่เจอ ให้ลากแบบปกติ
                obj.Position = newPos
            end
            
        end
    end)
end

-- ฟังก์ชันปรับตำแหน่งปุ่มอัตโนมัติเมื่อขนาดหน้าจอเปลี่ยน
local function AdjustStartBtnByRatio(obj)
    local parentScreen = obj:FindFirstAncestorOfClass("ScreenGui")
    if parentScreen and obj.Visible then
        local screenSize = parentScreen.AbsoluteSize
        local btnSize = obj.AbsoluteSize
        
        -- คำนวณพิกัดใหม่จาก Ratio ที่บันทึกไว้ล่าสุด
        local targetX = lastScreenRatioX * (screenSize.X - btnSize.X)
        local targetY = lastScreenRatioY * (screenSize.Y - btnSize.Y)
        
        -- เลื่อนปุ่มไปยังตำแหน่งที่เหมาะสมด้วย Tween เพื่อความนุ่มนวล
        TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, math.clamp(targetX, 0, screenSize.X - btnSize.X), 0, math.clamp(targetY, 0, screenSize.Y - btnSize.Y))
        }):Play()
    end
end

-- ต้องมีฟังก์ชันนี้ประกาศไว้ด้านบนๆ ของสคริปต์
local function SaveCurrentConfig(name)
    if name == "" then return end
    local json = HttpService:JSONEncode(XPHub.ConfigData)
    writefile(ConfigFolder.."/"..name..".json", json)
    print("Saved: " .. name)
end

function XPHub:Window(GuiConfig)
    GuiConfig = GuiConfig or {}
    local window = {Tabs = {}, CountTab = 0}
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = UI_NAME
    ScreenGui.IgnoreGuiInset = true
    -- ตรวจสอบว่ารันใน Studio หรือ Execute จริง
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game.CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = game.CoreGui
    end

    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.DisplayOrder = 9999
    ScreenGui.Parent = PlayerGui

    MainFrame = Instance.new("Frame")
    XPHub.MainFrame = MainFrame -- เก็บไว้ในตารางหลักเพื่อให้ฟังก์ชันอื่นๆ เข้าถึงได้ง่ายขึ้น
    MainFrame.Size = UDim2.new(0, 640, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -320, 0.5, -260)
    MainFrame.BackgroundColor3 = Colors.TitleBarDark
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true 
    MainFrame.ZIndex = 1
    MainFrame.Parent = ScreenGui


    -- สร้างปุ่มสำหรับยืดหด (Resize Handle)
    local ResizeHandle = Instance.new("Frame")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 25, 0, 25) -- ขนาดที่นิ้วมือบนมือถือกดง่าย
    ResizeHandle.Position = UDim2.new(1, -25, 1, -22)
    ResizeHandle.BackgroundTransparency = 1 -- ซ่อนพื้นหลัง
    ResizeHandle.ZIndex = 5000
    ResizeHandle.Parent = MainFrame

    -- วาดสัญลักษณ์มุมสามเหลี่ยม (สไตล์ Windows XP / Classic)
    local ResizeIcon = Instance.new("TextLabel")
    ResizeIcon.Text = "◢" -- สัญลักษณ์มุมขวา
    ResizeIcon.Size = UDim2.new(1, 0, 1, 0)
    ResizeIcon.BackgroundTransparency = 1
    ResizeIcon.TextColor3 = Colors.Border
    ResizeIcon.TextSize = 20
    ResizeIcon.TextXAlignment = Enum.TextXAlignment.Right
    ResizeIcon.TextYAlignment = Enum.TextYAlignment.Bottom
    ResizeIcon.ZIndex = 4999
    ResizeIcon.Parent = ResizeHandle

    -- เรียกใช้งานระบบ Resize
    MakeResizable(MainFrame, ResizeHandle)


local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    -- 1. แถบ TopBar หลัก
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 36)
    TopBar.BackgroundColor3 = Colors.White
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 1115
    TopBar.Parent = MainFrame
    
    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 10)
    TopCorner.Parent = TopBar

    local TopGradient = Instance.new("UIGradient")
    TopGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Colors.TitleBarLight),
        ColorSequenceKeypoint.new(0.5, Colors.TitleBarDark),
        ColorSequenceKeypoint.new(1, Colors.TitleBarDark)
    })
    TopGradient.Rotation = 90
    TopGradient.Parent = TopBar

    -- 2. ส่วนของ Logo (ซ้ายสุด)
    local TopLogo = Instance.new("ImageLabel")
    TopLogo.Name = "TopLogo"
    TopLogo.Size = UDim2.new(0, 22, 0, 22)
    TopLogo.Position = UDim2.new(0, 10, 0.5, 0)
    TopLogo.AnchorPoint = Vector2.new(0, 0.5)
    TopLogo.Image = "rbxassetid://106080187166557"
    TopLogo.BackgroundTransparency = 1
    TopLogo.ZIndex = 1116
    TopLogo.Parent = TopBar

-- [[ ส่วนชื่อ Title, Credit และ Version ]]
    local TitleContainer = Instance.new("Frame")
    TitleContainer.Name = "TitleContainer"
    TitleContainer.Size = UDim2.new(1, -150, 1, 0)
    TitleContainer.Position = UDim2.new(0, 40, 0, 0)
    TitleContainer.BackgroundTransparency = 1
    TitleContainer.ZIndex = 1116
    TitleContainer.Parent = TopBar

    local TitleLayout = Instance.new("UIListLayout")
    TitleLayout.FillDirection = Enum.FillDirection.Horizontal
    TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TitleLayout.Padding = UDim.new(0, 8) 
    TitleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TitleLayout.Parent = TitleContainer

    -- 1. ชื่อ Hub
    local HubTitle = Instance.new("TextLabel")
    HubTitle.Text = GuiConfig.Title or UI_TITLE or "XP Hub"
    HubTitle.Font = Enum.Font.ArialBold
    HubTitle.TextSize = 17
    HubTitle.TextColor3 = Colors.White
    HubTitle.Size = UDim2.new(0, 0, 1, 0)
    HubTitle.AutomaticSize = Enum.AutomaticSize.X
    HubTitle.BackgroundTransparency = 1
    HubTitle.ZIndex = 1116
    HubTitle.LayoutOrder = 1
    HubTitle.Parent = TitleContainer

    -- 2. เครดิต (By : Pigalo)
    local CreditTitle = Instance.new("TextLabel")
    CreditTitle.Text = UI_CREDIT
    CreditTitle.Font = Enum.Font.SourceSans
    CreditTitle.TextSize = 13
    CreditTitle.TextColor3 = Color3.fromRGB(210, 210, 210) -- สีขาวเทา
    CreditTitle.Size = UDim2.new(0, 0, 1, 0)
    CreditTitle.AutomaticSize = Enum.AutomaticSize.X
    CreditTitle.BackgroundTransparency = 1
    CreditTitle.ZIndex = 1116
    CreditTitle.LayoutOrder = 2
    CreditTitle.Parent = TitleContainer

    -- 3. เลข Version (เพิ่มใหม่)
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Name = "VersionLabel"
    VersionLabel.Text = UI_VERSION
    VersionLabel.Font = Enum.Font.Code -- ใช้ฟอนต์แนว Code จะดูเหมือนโปรแกรมจริง
    VersionLabel.TextSize = 12
    VersionLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- สีเหลืองอ่อนให้เด่นออกมานิดนึง
    VersionLabel.Size = UDim2.new(0, 0, 1, 0)
    VersionLabel.AutomaticSize = Enum.AutomaticSize.X
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.ZIndex = 1116
    VersionLabel.LayoutOrder = 3
    VersionLabel.Parent = TitleContainer

    -- 4. ส่วนของปุ่ม Control (_ , ▢ , X)
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(0, 110, 1, 0)
    Controls.Position = UDim2.new(1, -5, 0, 0)
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
        -- 1. เช็คก่อนว่าสร้างเสร็จหรือยัง
        if not MainFrame or not StartBtn then return end

        -- 2. สลับสถานะ (ถ้าเปิดให้ปิด ถ้าปิดให้เปิด)
        if MainFrame.Visible then
            MainFrame.Visible = false
            StartBtn.Visible = true
        else
            MainFrame.Visible = true
            StartBtn.Visible = false
        end
    end

    local function CreatePremiumBtn(name, iconText, baseColor, lightColor, order, callback)
        local btnFrame = Instance.new("TextButton")
        btnFrame.Name = name
        btnFrame.LayoutOrder = order
        btnFrame.Size = UDim2.new(0, 24, 0, 24)
        btnFrame.BackgroundColor3 = baseColor
        btnFrame.Text = ""
        btnFrame.ZIndex = 9998
        btnFrame.Parent = Controls
        Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 4)
        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Colors.White
        bStroke.Thickness = 1.5
        bStroke.Parent = btnFrame
        local icon = Instance.new("TextLabel")
        icon.Text = iconText
        icon.Size = UDim2.new(1, 0, 1, 0)
        icon.BackgroundTransparency = 1
        icon.TextColor3 = Colors.White
        icon.Font = Enum.Font.ArialBold
        icon.TextSize = name == "Close" and 16 or 18
        icon.ZIndex = 9999
        icon.Parent = btnFrame
        btnFrame.MouseButton1Click:Connect(callback)
    end

    CreatePremiumBtn("Min", "_", Colors.ControlBlue, Colors.ControlBlueLight, 1, function() 
        ToggleUI()
    end)
    CreatePremiumBtn("Res", "▢", Colors.ControlBlue, Colors.ControlBlueLight, 2, function() MainFrame.Position = UDim2.new(0.5, -310, 0.5, -250) end)
    CreatePremiumBtn("Close", "X", Colors.CloseRed, Colors.CloseRedLight, 3, function() 
        ResetAllSettings() -- สั่งล้างทุกอย่างและตัด Keybind
        task.wait(0.1)     -- รอให้ Callback ทำงานเสร็จนิดนึง
        ScreenGui:Destroy() -- ลบหน้าจอทิ้ง
    end)

    local Body = Instance.new("Frame")
    Body.Size = UDim2.new(1, -6, 1, -40)
    Body.Position = UDim2.new(0, 3, 0, 37)
    Body.BackgroundColor3 = Colors.Background
    Body.BorderSizePixel = 0
    Body.ClipsDescendants = true 
    Body.ZIndex = 2
    Body.Parent = MainFrame
    Instance.new("UICorner", Body).CornerRadius = UDim.new(0, 5)

    -- Sidebar (Smart Scroll)
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, 150, 1, -10)
    Sidebar.Position = UDim2.new(0, 5, 0, 5)
    Sidebar.BackgroundColor3 = Colors.Sidebar
    Sidebar.BorderSizePixel = 1
    Sidebar.BorderColor3 = Colors.Border
    Sidebar.ScrollBarThickness = 8
    Sidebar.ScrollBarImageColor3 = Colors.ScrollBarThumb -- สีของตัวเลื่อน
    Sidebar.ScrollingEnabled = false 
    Sidebar.ZIndex = 3
    Sidebar.Parent = Body
    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Padding = UDim.new(0, 2)
    SidebarLayout.Parent = Sidebar


    SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if SidebarLayout.AbsoluteContentSize.Y > Sidebar.AbsoluteSize.Y then
            Sidebar.ScrollBarThickness = 5
            Sidebar.ScrollingEnabled = true
        else
            Sidebar.ScrollBarThickness = 0
            Sidebar.ScrollingEnabled = false
        end
    end)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -165, 1, -10)
    Container.Position = UDim2.new(0, 160, 0, 5)
    Container.BackgroundTransparency = 1
    Container.ZIndex = 3
    Container.Parent = Body

    StartBtn = Instance.new("ImageButton") 
    StartBtn.Name = "StartBtn"
    
    -- [จุดสำคัญ] เปลี่ยน Size เป็นแบบ Scale (เช่น 0.08 หรือ 8% ของความกว้างจอ)
    -- และใส่ Offset เป็น 0 ทั้งหมด
    StartBtn.Size = UDim2.new(0.08, 0, 0.08, 0) 
    
    -- ใช้ UIAspectRatioConstraint เพื่อให้ปุ่มเป็นสี่เหลี่ยมจัตุรัส 1:1 เสมอ
    local AspectRatio = Instance.new("UIAspectRatioConstraint")
    AspectRatio.AspectRatio = 1
    AspectRatio.DominantAxis = Enum.DominantAxis.Width
    AspectRatio.Parent = StartBtn

    StartBtn.AnchorPoint = Vector2.new(0, 0)
    StartBtn.Position = UDim2.new(0.5, 0, 0.05, 0) -- วางกึ่งกลางจอ 5% จากขอบบน
    StartBtn.BackgroundTransparency = 1
    StartBtn.Image = "rbxassetid://106080187166557"
    StartBtn.Visible = false
    StartBtn.ZIndex = 2000
    StartBtn.Parent = ScreenGui

    StartBtn.MouseButton1Click:Connect(function()
        if not wasDragging then
            ToggleUI()
        end
    end)

    

    StartBtn.MouseEnter:Connect(function()
        TweenService:Create(StartBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 15, -- หมุนไปทางขวา 15 องศา
            -- Size เท่าเดิม ไม่ต้องใส่เพื่อให้ปุ่มไม่ขยาย
        }):Play()
    end)

    -- เมื่อเมาส์ออก (หรือปล่อยนิ้ว)
    StartBtn.MouseLeave:Connect(function()
        TweenService:Create(StartBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Rotation = 0, -- กลับมาที่องศาเดิม (0)
        }):Play()
    end)

    -- รันระบบลาก (ใช้ฟังก์ชันตัวลื่นที่คุณชอบ)
    MakeDraggableStartBtn(StartBtn, StartBtn)
    MakeDraggable(MainFrame, TopBar)


        function window:AddTab(TabConfig)
            local tab = {CountSection = 0}
            
            -- สร้างปุ่ม Tab ใน Sidebar
            local TabBtn = Instance.new("TextButton")
            TabBtn.Size = UDim2.new(1, 0, 0, 40)
            TabBtn.BackgroundColor3 = Colors.Sidebar
            TabBtn.Text = "" -- เราจะไม่ใช้ Text ของปุ่มโดยตรง เพื่อควบคุม Icon ได้อิสระ
            TabBtn.BorderSizePixel = 0
            TabBtn.ZIndex = 4
            TabBtn.Parent = Sidebar

            -- ตัวครอบ Icon และ Text เพื่อจัดกึ่งกลาง/ชิดซ้าย
            local TabContent = Instance.new("Frame")
            TabContent.Size = UDim2.new(1, 0, 1, 0)
            TabContent.BackgroundTransparency = 1
            TabContent.Parent = TabBtn

            local TabIcon = Instance.new("ImageLabel")
            TabIcon.Name = "Icon"
            TabIcon.Size = UDim2.new(0, 20, 0, 20)
            TabIcon.Position = UDim2.new(0, 10, 0.5, -10)
            TabIcon.Image = TabConfig.Icon or "" -- รับค่า Icon จาก Config
            TabIcon.ImageColor3 = Color3.fromRGB(80, 80, 80) -- สีตอนปกติ
            TabIcon.BackgroundTransparency = 1
            TabIcon.ZIndex = 5
            TabIcon.Parent = TabContent

            local TabLabel = Instance.new("TextLabel")
            TabLabel.Name = "Label"
            TabLabel.Text = TabConfig.Name
            TabLabel.Size = UDim2.new(1, -40, 1, 0)
            TabLabel.Position = UDim2.new(0, 38, 0, 0)
            TabLabel.Font = Enum.Font.ArialBold
            TabLabel.TextSize = 14
            TabLabel.TextColor3 = Colors.Text -- สีตอนปกติ
            TabLabel.TextXAlignment = Enum.TextXAlignment.Left
            TabLabel.BackgroundTransparency = 1
            TabLabel.ZIndex = 5
            TabLabel.Parent = TabContent

            -- หน้า Page ของแต่ละ Tab
            local Page = Instance.new("ScrollingFrame")
            Page.Size = UDim2.new(1, 0, 1, 0)
            Page.BackgroundTransparency = 1
            Page.Visible = false
            Page.ScrollBarThickness = 8 -- ให้เห็นแถบเลื่อนสไตล์ XP
            Page.ScrollBarImageColor3 = Colors.ScrollBarThumb
            Page.BorderSizePixel = 0
            Page.ScrollingEnabled = true -- เปิดไว้ตลอดเพื่อความชัวร์
            Page.CanvasSize = UDim2.new(0, 0, 0, 0) -- เดี๋ยว AutomaticSize จัดการเอง
            Page.AutomaticCanvasSize = Enum.AutomaticSize.Y -- บังคับให้ขยายตามเนื้อหา
            Page.ZIndex = 4
            Page.ClipsDescendants = true 
            Page.Parent = Container
                      
            local PageLayout = Instance.new("UIListLayout")
            PageLayout.Padding = UDim.new(0, 15)
            PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            PageLayout.SortOrder = Enum.SortOrder.LayoutOrder 
            PageLayout.Parent = Page
            
            -- [จัดการ Padding ของหน้า Page ให้ชิดเส้นซ้ายและบน]
            local PagePadding = Page:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", Page)
            PagePadding.PaddingTop = UDim.new(0, 0)    -- ระยะห่างจากขอบบน (กำลังดีไม่ชิดจนน่าเกลียด)
            PagePadding.PaddingLeft = UDim.new(0, 0)   -- [จุดสำคัญ] ขยับให้เกือบติดเส้นซ้ายตามที่ต้องการ
            PagePadding.PaddingBottom = UDim.new(0, 0) -- เผื่อพื้นที่ด้านล่างเวลาเลื่อนสุด


            -- 3. หัวข้อใหญ่
            local PageTitle = Instance.new("TextLabel")
            PageTitle.Name = "PageTitle"
            PageTitle.Size = UDim2.new(0.99, 0, 0, 45) -- ปรับกว้างเกือบเต็มพื้นที่
            PageTitle.Text = TabConfig.Name
            PageTitle.Font = Enum.Font.ArialBold
            PageTitle.TextSize = 32 
            PageTitle.TextColor3 = Colors.Text
            PageTitle.TextXAlignment = Enum.TextXAlignment.Left
            PageTitle.BackgroundTransparency = 1
            PageTitle.ZIndex = 5
            PageTitle.LayoutOrder = -100
            PageTitle.Parent = Page

            -- ฟังก์ชันจัดการตอนคลิกเปลี่ยน Tab (Active / Inactive)
            local function UpdateTabVisuals()
                -- วนลูป Reset ทุกปุ่มใน Sidebar
                for _, b in pairs(Sidebar:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = Colors.Sidebar
                        if b:FindFirstChild("Frame") then
                            b.Frame.Label.TextColor3 = Colors.Text
                            b.Frame.Icon.ImageColor3 = Color3.fromRGB(80, 80, 80)
                        end
                    end
                end
                -- ตั้งค่าปุ่มปัจจุบันเป็น Active
                TabBtn.BackgroundColor3 = Colors.White
                TabLabel.TextColor3 = Colors.TitleBarDark -- เปลี่ยนข้อความเป็นสีน้ำเงินตอน Active
                TabIcon.ImageColor3 = Colors.TitleBarDark -- เปลี่ยนสี Icon ตอน Active
            end

            TabBtn.MouseButton1Click:Connect(function()
                CloseAllDropdowns()
                for _, p in pairs(Container:GetChildren()) do 
                    if p:IsA("ScrollingFrame") then p.Visible = false end 
                end
                UpdateTabVisuals()
                Page.Visible = true
            end)

            -- เปิดหน้าแรกอัตโนมัติ
            if window.CountTab == 0 then
                Page.Visible = true
                UpdateTabVisuals()
            end
            window.CountTab = window.CountTab + 1

            function tab:AddSection(Title, Description, IconID)
                local sectionItems = {}
                local SectionFrame = Instance.new("Frame")
                SectionFrame.Size = UDim2.new(0.98, 0, 0, 60) -- ขนาดเริ่มต้นเล็กๆ เดี๋ยว AutomaticSize จะปรับเอง
                SectionFrame.BackgroundTransparency = 1
                SectionFrame.ZIndex = 5
                SectionFrame.ClipsDescendants = false -- เปลี่ยนเป็น false เพื่อให้ Effect บางอย่างล้นได้ถ้าจำเป็น
                tab.CountSection = tab.CountSection + 1
                SectionFrame.LayoutOrder = tab.CountSection
                SectionFrame.Parent = Page
                
                local SectionLayout = Instance.new("UIListLayout")
                SectionLayout.Padding = UDim.new(0, 5) -- เพิ่ม Padding ระหว่าง Sections ให้ดูไม่แน่นเกินไป
                SectionLayout.Parent = SectionFrame

                -- ### ส่วนหัว Section ที่ปรับปรุงใหม่ให้โดดเด่น ###
                local HeaderContainer = Instance.new("Frame")
                HeaderContainer.Size = SizeItem.TitleItem
                HeaderContainer.BackgroundColor3 = Color3.fromRGB(220, 225, 235) -- สีฟ้าอ่อนๆ สไตล์ XP Task Pane
                HeaderContainer.BorderSizePixel = 0
                HeaderContainer.ZIndex = 6
                HeaderContainer.Parent = SectionFrame
                
                local HeaderCorner = Instance.new("UICorner", HeaderContainer)
                HeaderCorner.CornerRadius = UDim.new(0, 6)
                
                -- เส้นขอบให้ดูนูน (XP Style)
                local HeaderStroke = Instance.new("UIStroke", HeaderContainer)
                HeaderStroke.Color = Colors.TitleBarLight
                HeaderStroke.Thickness = 1.2
                HeaderStroke.Transparency = 0.5

                -- Icon ของ Section
                if IconID then
                    local SecIcon = Instance.new("ImageLabel")
                    SecIcon.Size = UDim2.new(0, 24, 0, 24)
                    SecIcon.Position = UDim2.new(0, 10, 0.5, -12)
                    SecIcon.Image = IconID
                    SecIcon.BackgroundTransparency = 1
                    SecIcon.ImageColor3 = Colors.TitleBarDark
                    SecIcon.ZIndex = 7
                    SecIcon.Parent = HeaderContainer
                end

                local HeaderTitle = Instance.new("TextLabel")
                HeaderTitle.Size = UDim2.new(1, -50, 0, 24)
                HeaderTitle.Position = IconID and UDim2.new(0, 40, 0, 5) or UDim2.new(0, 12, 0, 5)
                HeaderTitle.Text = Title
                HeaderTitle.Font = Enum.Font.ArialBold
                HeaderTitle.TextSize = 18
                HeaderTitle.TextColor3 = Colors.TitleBarDark -- ใช้สีน้ำเงินเข้มให้ดูเป็นหัวข้อหลัก
                HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
                HeaderTitle.BackgroundTransparency = 1
                HeaderTitle.ZIndex = 7
                HeaderTitle.Parent = HeaderContainer

                if Description then
                    local Desc = Instance.new("TextLabel")
                    Desc.Size = UDim2.new(1, -50, 0, 15)
                    Desc.Position = IconID and UDim2.new(0, 40, 0, 25) or UDim2.new(0, 12, 0, 25)
                    Desc.Text = Description
                    Desc.Font = Enum.Font.Arial
                    Desc.TextSize = 12
                    Desc.TextColor3 = Colors.SubText
                    Desc.TextXAlignment = Enum.TextXAlignment.Left
                    Desc.BackgroundTransparency = 1
                    Desc.ZIndex = 7
                    Desc.Parent = HeaderContainer
                end

                -- ปรับขนาด SectionFrame อัตโนมัติ
                SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionFrame.Size = UDim2.new(0.98, 0, 0, SectionLayout.AbsoluteContentSize.Y + 5)
                end)


                -- Component: AddToggleSwitch (เวอร์ชันรองรับ Visual Sync และ Save/Load)
                function sectionItems:AddToggleSwitch(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4 
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -80, 0, 24)
                    TTitle.Position = UDim2.new(0, 15, 0, 10)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row
                    
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = Config.Description or ""
                    TDesc.Size = UDim2.new(1, -80, 0, 20)
                    TDesc.Position = UDim2.new(0, 15, 0, 32)
                    TDesc.Font = Enum.Font.Arial
                    TDesc.TextSize = 13
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = Row

                    local SwitchBg = Instance.new("TextButton")
                    SwitchBg.Size = UDim2.new(0, 50, 0, 26)
                    SwitchBg.Position = UDim2.new(1, -65, 0.5, -13)
                    SwitchBg.BackgroundColor3 = Config.Default and Colors.SwitchOn or Colors.SwitchOff
                    SwitchBg.Text = ""
                    SwitchBg.ZIndex = 9
                    SwitchBg.Parent = Row
                    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(0, 13)
                    
                    local Knob = Instance.new("Frame")
                    Knob.Size = UDim2.new(0, 22, 0, 22)
                    Knob.Position = Config.Default and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
                    Knob.BackgroundColor3 = Colors.White
                    Knob.ZIndex = 10
                    Knob.Parent = SwitchBg
                    Instance.new("UICorner", Knob).CornerRadius = UDim.new(0, 10)

                    local state = Config.Default
                    UpdateState(Config.ID, state) -- บันทึกค่าเริ่มต้นลงตาราง Config

                    -- ฟังก์ชันสำหรับอัปเดตหน้าตา UI (ใช้ตอนคลิก และ ตอนโหลด Config)
                    local function VisualUpdate(val)
                        local targetPos = val and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
                        local targetColor = val and Colors.SwitchOn or Colors.SwitchOff
                        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
                        TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                    end

                    -- บันทึกลงในระบบ Objects เพื่อให้ ApplySettings วิ่งมาหาเจอ
                    if Config.ID and XPHub.Objects then
                        XPHub.Objects[Config.ID] = {
                            Type = "Toggle",
                            Instance = SwitchBg,
                            Knob = Knob,
                            Update = function(val)
                                state = val -- อัปเดตตัวแปรภายใน
                                VisualUpdate(val)
                            end
                        }
                    end

                    SwitchBg.MouseButton1Click:Connect(function()
                        state = not state
                        VisualUpdate(state)
                        UpdateState(Config.ID, state) -- บันทึกค่าใหม่ลงตาราง
                        Config.Callback(state)
                    end)
                end

                -- Component: AddSlider (เวอร์ชันรองรับ Visual Sync และ Save/Load)
                function sectionItems:AddSlider(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -160, 0, 24)
                    TTitle.Position = UDim2.new(0, 15, 0, 12)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextColor3 = Colors.Text
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row
                    
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = Config.Description or ""
                    TDesc.Size = UDim2.new(1, -160, 0, 20)
                    TDesc.Position = UDim2.new(0, 15, 0, 34)
                    TDesc.Font = Enum.Font.Arial
                    TDesc.TextSize = 13
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = Row

                    local SliderContainer = Instance.new("Frame")
                    SliderContainer.Size = UDim2.new(0, 140, 0, 40)
                    SliderContainer.Position = UDim2.new(1, -150, 0.5, -15)
                    SliderContainer.BackgroundTransparency = 1
                    SliderContainer.ZIndex = 9
                    SliderContainer.Parent = Row

                    local ValueLabel = Instance.new("TextLabel")
                    ValueLabel.Size = UDim2.new(1, 0, 0, 20)
                    ValueLabel.Position = UDim2.new(0, 0, 0, -5)
                    ValueLabel.BackgroundTransparency = 1
                    ValueLabel.Text = tostring(Config.Default or Config.Min) .. " | " .. tostring(Config.Max)
                    ValueLabel.TextColor3 = Colors.Text
                    ValueLabel.Font = Enum.Font.ArialBold
                    ValueLabel.TextSize = 14
                    ValueLabel.ZIndex = 10
                    ValueLabel.Parent = SliderContainer

                    local SliderBack = Instance.new("Frame")
                    SliderBack.Size = UDim2.new(1, 0, 0, 6)
                    SliderBack.Position = UDim2.new(0, 0, 0.7, 0)
                    SliderBack.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    SliderBack.BorderSizePixel = 0
                    SliderBack.ZIndex = 10
                    SliderBack.Parent = SliderContainer
                    Instance.new("UICorner", SliderBack)

                    local SliderFill = Instance.new("Frame")
                    SliderFill.Size = UDim2.new(math.clamp(((Config.Default or Config.Min) - Config.Min) / (Config.Max - Config.Min), 0, 1), 0, 1, 0)
                    SliderFill.BackgroundColor3 = Colors.SwitchOn
                    SliderFill.BorderSizePixel = 0
                    SliderFill.ZIndex = 11
                    SliderFill.Parent = SliderBack
                    Instance.new("UICorner", SliderFill)

                    local Handle = Instance.new("Frame")
                    Handle.Size = UDim2.new(0, 16, 0, 16)
                    Handle.AnchorPoint = Vector2.new(0.5, 0.5)
                    Handle.Position = UDim2.new(SliderFill.Size.X.Scale, 0, 0.5, 0)
                    Handle.BackgroundColor3 = Colors.White
                    Handle.ZIndex = 12
                    Handle.Active = true
                    Handle.Parent = SliderBack
                    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1, 0)
                    local HandleStroke = Instance.new("UIStroke", Handle)
                    HandleStroke.Color = Colors.Border
                    HandleStroke.Thickness = 1

                    local dragging = false
                    UpdateState(Config.ID, Config.Default or Config.Min)

                    -- ฟังก์ชันสำหรับอัปเดตหน้าตา Slider (Visual Update)
                    local function VisualUpdate(val)
                        local relativeX = math.clamp((val - Config.Min) / (Config.Max - Config.Min), 0, 1)
                        SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                        Handle.Position = UDim2.new(relativeX, 0, 0.5, 0)
                        ValueLabel.Text = tostring(val) .. " | " .. tostring(Config.Max)
                    end

                    if Config.ID and XPHub.Objects then
                            XPHub.Objects[Config.ID] = {
                                Type = "Slider",
                                Instance = SliderFill,
                                Handle = Handle,
                                Label = ValueLabel,
                                Config = Config,
                                Callback = Config.Callback, -- ### เพิ่มบรรทัดนี้: เก็บฟังก์ชันสั่งวิ่งไว้ ###
                                Update = function(val)
                                    local relativeX = math.clamp((val - Config.Min) / (Config.Max - Config.Min), 0, 1)
                                    SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
                                    Handle.Position = UDim2.new(relativeX, 0, 0.5, 0)
                                    ValueLabel.Text = tostring(val) .. " | " .. tostring(Config.Max)
                                end
                            }
                        end

                    local function UpdateSlider(input)
                        local mouseLocation = input.Position
                        local relativeX = math.clamp((mouseLocation.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                        local value = math.floor(Config.Min + (Config.Max - Config.Min) * relativeX)
                        
                        VisualUpdate(value)
                        UpdateState(Config.ID, value)
                        Config.Callback(value)
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

                -- Component: AddDropdown (เวอร์ชันรองรับ Visual Sync และ Auto-Update)
                function sectionItems:AddDropdown(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -210, 0, 24)
                    TTitle.Position = UDim2.new(0, 15, 0, 12)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextColor3 = Colors.Text
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row
                    
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = Config.Description or ""
                    TDesc.Size = UDim2.new(1, -210, 0, 20)
                    TDesc.Position = UDim2.new(0, 15, 0, 34)
                    TDesc.Font = Enum.Font.Arial
                    TDesc.TextSize = 13
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = Row

                    local Frame = Instance.new("Frame")
                    Frame.Size = UDim2.new(0, 180, 0, 32)
                    Frame.Position = UDim2.new(1, -190, 0.5, -16)
                    Frame.BackgroundColor3 = Colors.White
                    Frame.BorderSizePixel = 1
                    Frame.BorderColor3 = Colors.XPInputBorder
                    Frame.ZIndex = 10
                    Frame.Parent = Row

                    local Label = Instance.new("TextLabel")
                    Label.Text = Config.Default or "เลือก..."
                    Label.Size = UDim2.new(1, -37, 1, 0)
                    Label.Position = UDim2.new(0, 8, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.TextColor3 = Colors.Text
                    Label.Font = Enum.Font.Arial
                    Label.TextSize = 14
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.ClipsDescendants = true
                    Label.ZIndex = 11
                    Label.Parent = Frame

                    local ArrowBtn = Instance.new("Frame")
                    ArrowBtn.Size = UDim2.new(0, 23, 0, 23)
                    ArrowBtn.Position = UDim2.new(1, -28, 0, 5)
                    ArrowBtn.BackgroundColor3 = Colors.ButtonClassic
                    ArrowBtn.BorderSizePixel = 1
                    ArrowBtn.BorderColor3 = Color3.fromRGB(150, 150, 150)
                    ArrowBtn.ZIndex = 11
                    ArrowBtn.Parent = Frame
                    Instance.new("UICorner", ArrowBtn).CornerRadius = UDim.new(0, 5)
                    
                    local ArrowIcon = Instance.new("ImageLabel")
                    ArrowIcon.Image = "rbxassetid://74976956154520"
                    ArrowIcon.Size = UDim2.new(0, 14, 0, 14)
                    ArrowIcon.Position = UDim2.new(0.23, 0, 0.24, 0)
                    ArrowIcon.BackgroundTransparency = 1
                    ArrowIcon.ImageColor3 = Color3.fromRGB(80, 80, 80)
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
                    List.BackgroundColor3 = Colors.White
                    List.BorderSizePixel = 1
                    List.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    List.ZIndex = 1000
                    List.Visible = false
                    List.Parent = MainFrame 

                    local SearchBox = Instance.new("TextBox")
                    SearchBox.Size = UDim2.new(1, -4, 0, 28)
                    SearchBox.Position = UDim2.new(0, 2, 0, 2)
                    SearchBox.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
                    SearchBox.PlaceholderText = "ค้นหา..."
                    SearchBox.Text = ""
                    SearchBox.TextSize = 14
                    SearchBox.ZIndex = 1001
                    SearchBox.Parent = List

                    local ItemScroll = Instance.new("ScrollingFrame")
                    ItemScroll.Size = UDim2.new(1, 0, 1, -32)
                    ItemScroll.Position = UDim2.new(0, 0, 0, 32)
                    ItemScroll.BackgroundTransparency = 1
                    ItemScroll.BorderSizePixel = 0
                    ItemScroll.ScrollBarThickness = 6
                    ItemScroll.ScrollBarImageColor3 = Colors.ScrollBarThumb
                    ItemScroll.ZIndex = 1001
                    ItemScroll.Parent = List
                    local ItemListLayout = Instance.new("UIListLayout", ItemScroll)

                    local syncConnection
                    local currentlySelected = Config.Default or nil 

                    local function UpdateListPosition()
                        if List.Visible then
                            local absPos = Frame.AbsolutePosition
                            local mainAbsPos = MainFrame.AbsolutePosition
                            local contentHeight = ItemListLayout.AbsoluteContentSize.Y
                            ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 5)
                            local dynamicHeight = math.clamp(contentHeight + 34, 60, 200)
                            List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                            List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y)
                        end
                    end

                    local function Populate(filter)
                        for _, child in pairs(ItemScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                        for _, item in pairs(Config.Options or {}) do
                            if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                                local itemBtn = Instance.new("TextButton")
                                itemBtn.Size = UDim2.new(1, 0, 0, 28)
                                itemBtn.BorderSizePixel = 0
                                itemBtn.Text = "  " .. tostring(item)
                                itemBtn.TextSize = 14
                                itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                                itemBtn.ZIndex = 1002
                                itemBtn.Parent = ItemScroll
                                
                                itemBtn.BackgroundColor3 = (item == currentlySelected) and Colors.DropdownSelectBlue or Colors.White
                                itemBtn.TextColor3 = (item == currentlySelected) and Colors.White or Colors.Text
                                
                                itemBtn.MouseButton1Click:Connect(function()
                                    Label.Text = item
                                    currentlySelected = item 
                                    List.Visible = false
                                    activeDropdownList = nil
                                    if syncConnection then syncConnection:Disconnect() end
                                    UpdateState(Config.ID, item)
                                    Config.Callback(item)
                                end)
                            end
                        end
                    end

                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function() Populate(SearchBox.Text) end)

                    local dropdownFunc = {}

                    -- ฟังก์ชัน Refresh รายการ (ใช้ใน Tab 2)
                    function dropdownFunc:Refresh(newList)
                        Config.Options = newList
                        Populate("") 
                    end

                    -- ฟังก์ชันสำหรับ Update หน้าตา UI (ใช้ตอน Load Config)
                    function dropdownFunc:Update(val)
                        Label.Text = tostring(val)
                        currentlySelected = val
                    end

                    -- ฟังก์ชัน Set ค่าพร้อมรัน Callback
                    function dropdownFunc:Set(val)
                        Label.Text = tostring(val)
                        currentlySelected = val
                        UpdateState(Config.ID, val)
                        Config.Callback(val)
                    end

                    if Config.ID then
                        XPHub.Objects[Config.ID] = {
                            Update = function(val) 
                                Label.Text = tostring(val) 
                                currentlySelected = val -- อัปเดตตัวแปรภายในด้วย
                            end,
                            -- ดักจับ Error ถ้าลืมใส่ Callback ตอนสร้าง
                            Callback = Config.Callback or function() end 
                        }
                    end

                    DropdownClickBtn.MouseButton1Click:Connect(function()
                        if List.Visible then
                            List.Visible = false
                            activeDropdownList = nil
                            if syncConnection then syncConnection:Disconnect() end
                        else
                            CloseAllDropdowns() 
                            List.Visible = true
                            activeDropdownList = List
                            ItemScroll.CanvasPosition = Vector2.new(0, 0)
                            SearchBox.Text = "" 
                            UpdateListPosition()
                            Populate("") 
                            if syncConnection then syncConnection:Disconnect() end
                            syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
                        end
                    end)
                    
                    return dropdownFunc
                end

                -- Component: AddMultiSelect (เวอร์ชันรองรับ Visual Sync และ Fix Load Error)
                function sectionItems:AddMultiSelect(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -210, 0, 24)
                    TTitle.Position = UDim2.new(0, 15, 0, 12)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextColor3 = Colors.Text
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row
                    
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = Config.Description or ""
                    TDesc.Size = UDim2.new(1, -210, 0, 20)
                    TDesc.Position = UDim2.new(0, 15, 0, 34)
                    TDesc.Font = Enum.Font.Arial
                    TDesc.TextSize = 13
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = Row

                    local Frame = Instance.new("Frame")
                    Frame.Size = UDim2.new(0, 180, 0, 32)
                    Frame.Position = UDim2.new(1, -190, 0.5, -16)
                    Frame.BackgroundColor3 = Colors.White
                    Frame.BorderSizePixel = 1
                    Frame.BorderColor3 = Colors.XPInputBorder
                    Frame.ZIndex = 10
                    Frame.Parent = Row

                    local Label = Instance.new("TextLabel")
                    Label.Text = "None"
                    Label.Size = UDim2.new(1, -37, 1, 0)
                    Label.Position = UDim2.new(0, 8, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.TextColor3 = Colors.Text
                    Label.Font = Enum.Font.Arial
                    Label.TextSize = 13
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.ClipsDescendants = true 
                    Label.ZIndex = 11
                    Label.Parent = Frame

                    local ArrowBtn = Instance.new("Frame")
                    ArrowBtn.Size = UDim2.new(0, 23, 0, 23)
                    ArrowBtn.Position = UDim2.new(1, -28, 0, 5)
                    ArrowBtn.BackgroundColor3 = Colors.ButtonClassic
                    ArrowBtn.BorderSizePixel = 1
                    ArrowBtn.BorderColor3 = Color3.fromRGB(150, 150, 150)
                    ArrowBtn.ZIndex = 11
                    ArrowBtn.Parent = Frame
                    Instance.new("UICorner", ArrowBtn).CornerRadius = UDim.new(0, 5)

                    local ArrowIcon = Instance.new("ImageLabel")
                    ArrowIcon.Image = "rbxassetid://74976956154520"
                    ArrowIcon.Size = UDim2.new(0, 14, 0, 14)
                    ArrowIcon.Position = UDim2.new(0.23, 0, 0.24, 0)
                    ArrowIcon.BackgroundTransparency = 1
                    ArrowIcon.ImageColor3 = Color3.fromRGB(80, 80, 80)
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
                    List.BackgroundColor3 = Colors.White
                    List.BorderSizePixel = 1
                    List.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    List.ZIndex = 1000 
                    List.Visible = false
                    List.Parent = MainFrame 

                    local SearchBox = Instance.new("TextBox")
                    SearchBox.Size = UDim2.new(1, -4, 0, 28)
                    SearchBox.Position = UDim2.new(0, 2, 0, 2)
                    SearchBox.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
                    SearchBox.PlaceholderText = "ค้นหา..."
                    SearchBox.Text = ""
                    SearchBox.TextSize = 14
                    SearchBox.ZIndex = 1001
                    SearchBox.Parent = List

                    local ItemScroll = Instance.new("ScrollingFrame")
                    ItemScroll.Size = UDim2.new(1, 0, 1, -32)
                    ItemScroll.Position = UDim2.new(0, 0, 0, 32)
                    ItemScroll.BackgroundTransparency = 1
                    ItemScroll.BorderSizePixel = 0
                    ItemScroll.ScrollBarThickness = 6
                    ItemScroll.ScrollBarImageColor3 = Colors.ScrollBarThumb
                    ItemScroll.ZIndex = 1001
                    ItemScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
                    ItemScroll.Parent = List
                    local ListLayout = Instance.new("UIListLayout", ItemScroll)

                    local syncConnection
                    local selectedItems = Config.Default or {} 

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
                            ItemScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 5)
                            local dynamicHeight = math.clamp(contentHeight + 34, 60, 200)
                            List.Size = UDim2.new(0, Frame.AbsoluteSize.X, 0, dynamicHeight)
                            List.Position = UDim2.new(0, absPos.X - mainAbsPos.X, 0, absPos.Y - mainAbsPos.Y + Frame.AbsoluteSize.Y)
                        end
                    end

                    local function Populate(filter)
                        for _, child in pairs(ItemScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                        for _, item in pairs(Config.Options or {}) do
                            if filter == "" or string.find(string.lower(tostring(item)), string.lower(tostring(filter))) then
                                local itemBtn = Instance.new("TextButton")
                                itemBtn.Size = UDim2.new(1, 0, 0, 28)
                                itemBtn.BorderSizePixel = 0
                                itemBtn.Text = "  " .. tostring(item)
                                itemBtn.TextSize = 14
                                itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                                itemBtn.ZIndex = 1002
                                itemBtn.Parent = ItemScroll
                                
                                local function RefreshColor()
                                    if type(selectedItems) == "table" and table.find(selectedItems, item) then
                                        itemBtn.BackgroundColor3 = Colors.DropdownSelectBlue
                                        itemBtn.TextColor3 = Colors.White
                                    else
                                        itemBtn.BackgroundColor3 = Colors.White
                                        itemBtn.TextColor3 = Colors.Text
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
                                    Config.Callback(selectedItems)
                                end)
                            end
                        end
                    end

                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function() Populate(SearchBox.Text) end)

                    -- ### ระบบ Visual Sync & Objects Storage ###
                    if Config.ID and XPHub.Objects then
                        XPHub.Objects[Config.ID] = {
                            Type = "MultiSelect",
                            Update = function(val)
                                -- ถ้าค่าที่โหลดมาไม่ใช่ Table (เช่นโหลด String มาตัวเดียว) ให้แปลงเป็น Table
                                if type(val) == "table" then
                                    selectedItems = val
                                else
                                    selectedItems = {val}
                                end
                                UpdateLabel()
                            end,
                            -- ป้องกัน Error ถ้าไม่ได้ใส่ Callback
                            Callback = Config.Callback or function() end 
                        }
                    end

                    MultiClickBtn.MouseButton1Click:Connect(function()
                        if List.Visible then
                            List.Visible = false
                            activeDropdownList = nil
                            if syncConnection then syncConnection:Disconnect() end
                        else
                            CloseAllDropdowns() 
                            List.Visible = true
                            activeDropdownList = List
                            ItemScroll.CanvasPosition = Vector2.new(0, 0)
                            SearchBox.Text = "" 
                            UpdateListPosition()
                            Populate("") 
                            if syncConnection then syncConnection:Disconnect() end
                            syncConnection = RunService.RenderStepped:Connect(UpdateListPosition)
                        end
                    end)
                end

                -- Component: AddInput (เวอร์ชันรองรับ Visual Sync และ Save/Load สมบูรณ์)
                function sectionItems:AddInput(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -160, 0, 24)
                    TTitle.Position = UDim2.new(0, 15, 0, 12)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextColor3 = Colors.Text
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row
                    
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = Config.Description or ""
                    TDesc.Size = UDim2.new(1, -160, 0, 20)
                    TDesc.Position = UDim2.new(0, 15, 0, 34)
                    TDesc.Font = Enum.Font.Arial
                    TDesc.TextSize = 13
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = Row

                    local InputFrame = Instance.new("Frame")
                    InputFrame.Size = UDim2.new(0, 140, 0, 32)
                    InputFrame.Position = UDim2.new(1, -150, 0.5, -16)
                    InputFrame.BackgroundColor3 = Colors.InputBackground
                    InputFrame.BorderSizePixel = 1
                    InputFrame.BorderColor3 = Colors.XPInputBorder
                    InputFrame.ClipsDescendants = true
                    InputFrame.ZIndex = 9
                    InputFrame.Parent = Row
                    Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 4)

                    local TextBox = Instance.new("TextBox")
                    TextBox.Size = UDim2.new(1, -12, 1, 0)
                    TextBox.Position = UDim2.new(0, 6, 0, 0)
                    TextBox.BackgroundTransparency = 1
                    TextBox.Text = Config.Default or ""
                    TextBox.PlaceholderText = Config.Placeholder or "พิมพ์ที่นี่..."
                    TextBox.TextColor3 = Colors.Text
                    TextBox.TextSize = 14
                    TextBox.Font = Enum.Font.Arial
                    TextBox.TextXAlignment = Enum.TextXAlignment.Left
                    TextBox.ClearTextOnFocus = false
                    TextBox.ZIndex = 10
                    TextBox.Parent = InputFrame

                    -- ### ระบบบันทึกค่าและ Sync UI ###
                    if Config.ID and XPHub.Objects then
                        UpdateState(Config.ID, Config.Default or "")
                        
                        -- เก็บ Object พร้อมฟังก์ชัน Update สำหรับ Load Config
                        XPHub.Objects[Config.ID] = {
                            Type = "Input",
                            Instance = TextBox,
                            Update = function(val)
                                TextBox.Text = tostring(val)
                            end
                        }
                    end

                    TextBox.FocusLost:Connect(function(enterPressed)
                        local currentText = TextBox.Text
                        if Config.ID then
                            UpdateState(Config.ID, currentText)
                        end
                        Config.Callback(currentText, enterPressed)
                    end)
                    
                    return Row
                end

                -- Component: AddButton (ปุ่มกดสไตล์ Windows XP Classic)
                function sectionItems:AddButton(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -160, 0, 24)
                    TTitle.Position = UDim2.new(0, 15, 0, 12)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextColor3 = Colors.Text
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row
                    
                    local TDesc = Instance.new("TextLabel")
                    TDesc.Text = Config.Description or ""
                    TDesc.Size = UDim2.new(1, -160, 0, 20)
                    TDesc.Position = UDim2.new(0, 15, 0, 34)
                    TDesc.Font = Enum.Font.Arial
                    TDesc.TextSize = 13
                    TDesc.TextColor3 = Colors.SubText
                    TDesc.TextXAlignment = Enum.TextXAlignment.Left
                    TDesc.BackgroundTransparency = 1
                    TDesc.ZIndex = 8
                    TDesc.Parent = Row

                    -- ตัวปุ่มจริง
                    local Button = Instance.new("TextButton")
                    Button.Name = "XPButton"
                    Button.Size = UDim2.new(0, 120, 0, 32)
                    Button.Position = UDim2.new(1, -135, 0.5, -16)
                    Button.BackgroundColor3 = Colors.ButtonClassic
                    Button.Text = Config.ButtonText or "Click"
                    Button.Font = Enum.Font.ArialBold
                    Button.TextSize = 14
                    Button.TextColor3 = Colors.Text
                    Button.ZIndex = 9
                    Button.Parent = Row
                    
                    local BtnCorner = Instance.new("UICorner", Button)
                    BtnCorner.CornerRadius = UDim.new(0, 4)

                    -- เส้นขอบปุ่มสไตล์ XP
                    local BtnStroke = Instance.new("UIStroke", Button)
                    BtnStroke.Color = Color3.fromRGB(100, 100, 100)
                    BtnStroke.Thickness = 1
                    BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                    -- Gradient เพิ่มความนูนให้ปุ่ม
                    local BtnGradient = Instance.new("UIGradient", Button)
                    BtnGradient.Rotation = 90
                    BtnGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
                    })

                    -- Click Animation & Logic
                    Button.MouseButton1Down:Connect(function()
                        TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(180, 180, 180)}):Play()
                    end)

                    Button.MouseButton1Up:Connect(function()
                        TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Colors.ButtonClassic}):Play()
                    end)

                    Button.MouseButton1Click:Connect(function()
                        Config.Callback()
                    end)
                    
                    return Button
                end

                -- Component: AddLabel (เวอร์ชัน Premium Status Box)
                function sectionItems:AddLabel(Title)
                    local Row = Instance.new("Frame")
                    Row.Size = UDim2.new(0.99, 0, 0, 35) -- เริ่มต้นที่ 35
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.BorderSizePixel = 0
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    
                    local RowCorner = Instance.new("UICorner", Row)
                    RowCorner.CornerRadius = UDim.new(0, 4)

                    -- แถบสีด้านซ้าย (Accent Bar)
                    local Accent = Instance.new("Frame")
                    Accent.Size = UDim2.new(0, 4, 1, 0)
                    Accent.BackgroundColor3 = Colors.TitleBarDark
                    Accent.BorderSizePixel = 0
                    Accent.ZIndex = 8
                    Accent.Parent = Row
                    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 4)

                    -- พื้นหลังไล่เฉดสีเบาๆ (XP Gradient)
                    local Grad = Instance.new("UIGradient")
                    Grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 245, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    })
                    Grad.Rotation = 0
                    Grad.Parent = Row

                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = "ℹ️ " .. Title -- ใส่ Icon เล็กๆ ให้ดูเป็น Status
                    TTitle.Size = UDim2.new(1, -25, 1, 0)
                    TTitle.Position = UDim2.new(0, 15, 0, 0)
                    TTitle.Font = Enum.Font.ArialBold -- ใช้ตัวหนาให้ดูเป็นทางการ
                    TTitle.TextSize = 13
                    TTitle.TextColor3 = Color3.fromRGB(50, 50, 80) -- สีน้ำเงินเทาเข้ม
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.TextWrapped = true -- ถ้ายาวเกินให้ตัดบรรทัด
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row

                    -- ระบบปรับขนาดอัตโนมัติ (Dynamic Height)
                    TTitle:GetPropertyChangedSignal("Text"):Connect(function()
                        local textHeight = TTitle.TextBounds.Y
                        Row.Size = UDim2.new(0.99, 0, 0, math.max(35, textHeight + 15))
                    end)

                    -- ฟังก์ชันควบคุมภายนอก
                    local labelFunc = {}
                    
                    -- อัปเดตข้อความ
                    function labelFunc:Set(newText)
                        TTitle.Text = "ℹ️ " .. newText
                    end

                    -- เปลี่ยนสี Accent และ Text (เช่น เปลี่ยนเป็นสีเขียว/แดง)
                    function labelFunc:SetColor(color)
                        Accent.BackgroundColor3 = color
                        TTitle.TextColor3 = color
                    end

                    return labelFunc
                end

                -- Component: AddKeybind (Perfect Version: Enum Support & JSON Safe)
                function sectionItems:AddKeybind(Config)
                    local Row = Instance.new("Frame")
                    Row.Size = SizeItem.BoxItem
                    Row.BackgroundColor3 = Colors.White
                    Row.BackgroundTransparency = 0.4
                    Row.ZIndex = 7
                    Row.Parent = SectionFrame
                    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 6)
                    
                    local TTitle = Instance.new("TextLabel")
                    TTitle.Text = Config.Title
                    TTitle.Size = UDim2.new(1, -120, 1, 0)
                    TTitle.Position = UDim2.new(0, 15, 0, 0)
                    TTitle.Font = Enum.Font.ArialBold
                    TTitle.TextSize = 16
                    TTitle.TextColor3 = Colors.Text
                    TTitle.TextXAlignment = Enum.TextXAlignment.Left
                    TTitle.BackgroundTransparency = 1
                    TTitle.ZIndex = 8
                    TTitle.Parent = Row

                    local BindButton = Instance.new("TextButton")
                    BindButton.Size = UDim2.new(0, 80, 0, 32)
                    BindButton.Position = UDim2.new(1, -95, 0.5, -16)
                    BindButton.BackgroundColor3 = Colors.ButtonClassic
                    
                    -- ตัวแปรเก็บค่า Key (เป็น Enum จริง)
                    local currentKey = Config.Default
                    
                    -- แสดงผลแค่ชื่อปุ่ม เช่น [ G ] หรือ [ ... ] ถ้าไม่มีค่า
                    BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
                    BindButton.Font = Enum.Font.ArialBold
                    BindButton.TextSize = 14
                    BindButton.TextColor3 = Colors.Text
                    BindButton.ZIndex = 9
                    BindButton.Parent = Row
                    Instance.new("UICorner", BindButton).CornerRadius = UDim.new(0, 4)
                    
                    local bStroke = Instance.new("UIStroke", BindButton)
                    bStroke.Color = Color3.fromRGB(120, 120, 120)
                    bStroke.Thickness = 1

                    -- ใน function sectionItems:AddKeybind(Config)
                    local currentKey = Config.Default
                    local keyConnection

                    local function StartListening()
                        if keyConnection then keyConnection:Disconnect() end
                        if not currentKey then return end
                        
                        keyConnection = UserInputService.InputBegan:Connect(function(input, gp)
                            if gp then return end
                            if input.KeyCode == currentKey then
                                Config.Callback(currentKey) -- ส่ง Enum จริงกลับไป
                            end
                        end)
                        
                        -- เก็บ Connection ไว้เผื่อสั่ง Stop
                        if XPHub.Objects[Config.ID] then
                            XPHub.Objects[Config.ID].Connection = keyConnection
                        end
                    end

                    -- เพิ่มส่วน Reset ใน Objects
                    if Config.ID and XPHub.Objects then
                        XPHub.Objects[Config.ID] = {
                            Type = "Keybind",
                            -- ฟังก์ชันสั่งหยุดทำงาน
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

                    -- เริ่มทำงานทันทีถ้ามีค่า Default มาให้
                    if currentKey then StartListening() end

                    -- ระบบดักจับการตั้งค่าปุ่มใหม่
                    BindButton.MouseButton1Click:Connect(function()
                        if IsBinding then return end -- IsBinding ต้องประกาศเป็น Local/Global ไว้บนสุดของสคริปต์
                        IsBinding = true
                        BindButton.Text = "[ ... ]"
                        BindButton.TextColor3 = Colors.TitleBarDark
                        
                        local tempConnection
                        tempConnection = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                local newKey = input.KeyCode
                                
                                if newKey ~= Enum.KeyCode.Escape then
                                    currentKey = newKey -- เก็บค่า Enum จริงไว้ใช้งาน
                                    BindButton.Text = "[" .. newKey.Name .. "]"
                                    BindButton.TextColor3 = Colors.Text
                                    
                                    -- ### จุดสำคัญ: ส่งแค่ .Name (String) ไปเซฟเพื่อไม่ให้ JSON พัง ###
                                    UpdateState(Config.ID, newKey.Name)
                                    
                                    StartListening() -- อัปเดตการตรวจจับปุ่มใหม่
                                else
                                    -- ถ้ากด ESC ให้ยกเลิกและกลับไปใช้ค่าเดิม
                                    BindButton.Text = currentKey and "[" .. currentKey.Name .. "]" or "[ ... ]"
                                    BindButton.TextColor3 = Colors.Text
                                end
                                
                                IsBinding = false
                                tempConnection:Disconnect()
                            end
                        end)
                    end)

                    -- สำหรับระบบ Load Config (Visual Sync)
                    if Config.ID and XPHub.Objects then
                        XPHub.Objects[Config.ID] = {
                            Update = function(valName)
                                if not valName or valName == "" then return end -- ป้องกันค่า nil/ว่าง
                                if typeof(valName) == "string" and Enum.KeyCode[valName] then
                                    currentKey = Enum.KeyCode[valName]
                                    BindButton.Text = "[" .. valName .. "]"
                                    StartListening()
                                end
                            end
                        }
                    end
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