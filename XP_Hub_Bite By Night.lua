-- ดึง Library จาก GitHub (Link แบบ Raw)
local XPHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/PigaloLido/XP-Hub/main/XP_Library.lua"))()


local allowedMaps = {168556275, 77747658251236, 70845479499574} -- ใส่รหัสแมพที่คุณต้องการที่นี่
if not XPHub:CheckPlaceId(allowedMaps) then 
    return -- ถ้าแมพไม่ตรง สคริปต์จะหยุดทำงานทันที (และโดน Kick ตามเงื่อนไขใน Lib)
end



local Win = XPHub:Window({
        Title = UI_TITLE,
    })

    -- ตัวอย่างการเรียกใช้งาน
    local Tab1 = Win:AddTab({
        Name = "General",
        Icon = "rbxassetid://7733960981" -- ใส่ ID ของ Icon ที่คุณต้องการ
    })
    local Sec1 = Tab1:AddSection("🔥 General", "Automation")

    Sec1:AddDropdown({
        ID = "TargetNPC", -- เพิ่ม ID
        Title = "เลือกศัตรูเป้าหมาย",
        Description = "เลือก NPC ที่ต้องการให้ระบบฟาร์มโจมตี",
        Options = {"Monkey", "Gorilla", "Goden Sun", "Snowman", "Yeti", "Dragon", "Snowman2", "Yeti2", "Dragon2"},
        Default = "Monkey",
        Callback = function(v) print("Selected NPC:", v) end
    })

    Sec1:AddMultiSelect({
        ID = "SelectedItems", -- เพิ่ม ID
        Title = "Select Items",
        Description = "เลือกได้หลายรายการ",
        Options = {"Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6", "Item 7", "Item 8"},
        Default = {"Item 1"},
        Callback = function(v) print("Current Selected:", table.concat(v, ", ")) end
    })

    Sec1:AddToggleSwitch({
        ID = "AutoFarm", -- เพิ่ม ID
        Title = "Enable Farm",
        Description = "ฟาร์มมอนสเตอร์ที่เลือกไว้",
        Default = false,
        Callback = function(v) end
    })

    Sec1:AddSlider({
        ID = "CharacterSpeed", -- เพิ่ม ID
        Title = "WalkSpeed",
        Description = "ปรับความเร็วในการเคลื่อนที่",
        Min = 16,
        Max = 300,
        Default = 16,
        Callback = function(v)
            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
            end
        end
    })

    Sec1:AddSlider({
        ID = "FieldOfView", -- เพิ่ม ID
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
        ID = "WebhookURL", -- เพิ่ม ID
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
            game.Players.LocalPlayer.Character:BreakJoints()
            print("ตัวละครถูกรีเซ็ตแล้ว")
        end
    })

    Sec1:AddButton({
        Title = "Copy Job ID",
        Description = "คัดลอกไอดีเซิร์ฟเวอร์ปัจจุบัน",
        ButtonText = "Copy",
        Callback = function()
            setclipboard(game.JobId)
            print("คัดลอก Job ID แล้ว!")
        end
    })

    ------------------------------------------------------- Tab 2 -------------------------------------------------------
    local Tab2 = Win:AddTab({
        Name = "Player",
        Icon = "rbxassetid://7734053495"
    })

    local Sec2 = Tab2:AddSection("⌨️ Player Modifications", "ปรับแต่งตัวละคร")

    Sec2:AddToggleSwitch({
        ID = "Infinite_Stamina", 
        Title = "Infinite Stamina",
        Description = "ไม่เหนือยเมื่อวิ่ง",
        Default = false,
        Callback = function(v)
            _G.StaminaToggled = v 

            local function applyStamina(char)
                if not char or not _G.StaminaToggled then return end

                -- 1. เช็คทีมก่อนเริ่ม (ดึงจาก Attribute TEAM ที่คุณส่งรูปมาให้ดู)
                local currentTeam = game.Players.LocalPlayer:GetAttribute("TEAM")
                
                -- ถ้าเป็น Lobby ให้หยุดทำงานทันที (ไม่รัน Connection)
                if currentTeam == "Lobby" or not currentTeam then 
                    return 
                end

                -- 2. กำหนดค่าตามทีมที่คุณระบุ
                local maxVal = (currentTeam == "Killer") and 70 or 100

                -- 3. บังคับค่าเริ่มต้น
                char:SetAttribute("Stamina", maxVal)

                -- 4. เชื่อมต่อระบบดักจับ
                local connection
                connection = char.AttributeChanged:Connect(function(attr)
                    if not _G.StaminaToggled or game.Players.LocalPlayer:GetAttribute("TEAM") == "Lobby" then
                        connection:Disconnect()
                        return
                    end

                    if attr == "Stamina" then
                        if char:GetAttribute("Stamina") < maxVal then
                            char:SetAttribute("Stamina", maxVal)
                        end
                    end
                end)
            end

            -- [ ส่วนควบคุม ]
            if _G.StaminaToggled then
                -- ทำงานกับตัวละครปัจจุบัน
                applyStamina(game.Players.LocalPlayer.Character)

                -- ดักจับตอนเกิดใหม่/เปลี่ยนแมพ
                if not _G.StaminaObserver then
                    _G.StaminaObserver = game.Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
                        if _G.StaminaToggled then
                            task.wait(1) -- รอให้ Attribute TEAM โหลดเสร็จก่อนเช็ค
                            applyStamina(newChar)
                        end
                    end)
                end
            else
                -- ล้างระบบเมื่อปิด Toggle
                if _G.StaminaObserver then
                    _G.StaminaObserver:Disconnect()
                    _G.StaminaObserver = nil
                end
            end
        end
    })
    
    ------------------------------------------------------- Tab 9 -------------------------------------------------------
    ------------------------------------------------------- Tab 9 -------------------------------------------------------
    ------------------------------------------------------- Tab 9 -------------------------------------------------------
    ------------------------------------------------------- Tab 9 -------------------------------------------------------
    ------------------------------------------------------- Tab 9 -------------------------------------------------------
    ------------------------------------------------------- Tab 9 -------------------------------------------------------



    ------------------------------------------------------- Tab 9 -------------------------------------------------------

    local Tab9 = Win:AddTab({
        Name = "Settings",
        Icon = "rbxassetid://7734053495"
    })

    local Sec9 = Tab9:AddSection("⌨️ Keybind Open/Minimize UI", "ตั้งค่าปุ่มเปิด/ปิดหน้าจอ (Keybind)")

    -- 1. ตัว Toggle
    Sec9:AddToggleSwitch({
        ID = "EnableBind_UI",
        Title = "Enable Keybind",
        Description = "เปิดใช้งานปุ่มเปิด/ปิดหน้าจอ",
        Default = false,
        Callback = function(v) 
            -- ค่า v จะถูกเก็บเข้า XPHub.ConfigData["EnableBind_UI"] อัตโนมัติ
        end
    })

    Sec9:AddKeybind({
        ID = "MenuBind",
        Title = "Keybind Open/Close",
        Default = Enum.KeyCode.G, 
        Callback = function(key) 
            local Frame = XPHub.MainFrame
            local SBtn = StartBtn 

            if Frame and XPHub.ConfigData["EnableBind_UI"] == true then
                Frame.Visible = not Frame.Visible
                
                if SBtn then
                    SBtn.Visible = not Frame.Visible
                end
                
                -- ปิด Dropdown ที่อาจค้างอยู่เพื่อความสะอาด
                if CloseAllDropdowns then CloseAllDropdowns() end
            end
        end
    })

    local Sec9 = Tab9:AddSection("⚙️ Configuration (Save/Load)", "ระบบบันทึก Config (Save/Load)")

    -- [1] ย้ายตัวแปรสำคัญขึ้นมาประกาศไว้ด้านบนสุดของหน้า เพื่อให้ปุ่มทุกปุ่มมองเห็น
    local StatusLabel
    local ConfigName = ""
    local SelectedFile = ""
    local ConfigDropdown -- เตรียมไว้สำหรับรับค่าจาก AddDropdown

    -- [2] ส่วนกรอกชื่อไฟล์
    Sec9:AddInput({
        Title = "Config Name",
        Description = "พิมพ์ชื่อที่ต้องการบันทึกใหม่",
        Placeholder = "เช่น ProFarm_V1",
        Callback = function(text) 
            ConfigName = text 
        end
    })

    Sec9:AddButton({
        Title = "Create Config",
        Description = "บันทึกการตั้งค่าปัจจุบันลงไฟล์ใหม่",
        ButtonText = "Create New",
        Callback = function()
            if ConfigName ~= "" then
                XPHub:SaveCurrentConfig(ConfigName)
                if ConfigDropdown then
                    ConfigDropdown:Refresh(XPHub:GetConfigList())
                end
                print("Saved New: " .. ConfigName)
            end
        end
    })

    -- [4] Dropdown แสดงรายชื่อไฟล์ (กำหนดค่าเข้าตัวแปร ConfigDropdown ที่ประกาศไว้ด้านบน)
    ConfigDropdown = Sec9:AddDropdown({
        Title = "Config List",
        Description = "เลือกไฟล์ที่ต้องการจัดการ",
        Options = XPHub:GetConfigList(),
        Default = "---",
        Callback = function(selected) 
            SelectedFile = selected 
        end
    })
    
    -- [5] แผงปุ่มจัดการไฟล์ที่เลือก
    Sec9:AddButton({
        Title = "Overwrite Config",
        Description = "เซฟทับไฟล์ที่เลือกอยู่ใน List",
        ButtonText = "Overwrite",
        Callback = function()
            if SelectedFile ~= "" and SelectedFile ~= "---" then
                XPHub:SaveCurrentConfig(SelectedFile)
                print("Overwrote: " .. SelectedFile)
            end
        end
    })

    Sec9:AddButton({
        Title = "Load Config",
        Description = "ดึงค่าจากไฟล์มาใช้งาน",
        ButtonText = "Load",
        Callback = function()
            if SelectedFile ~= "" and SelectedFile ~= "---" then
                local data = XPHub:LoadConfigData(SelectedFile)
                -- บันทึก: คุณต้องเขียนฟังก์ชัน ApplySettings(data) เพื่ออัปเดต UI หน้าอื่นๆ ด้วย
                print("Loaded: " .. SelectedFile)
            end
        end
    })

    Sec9:AddButton({
        Title = "Set as Autoload",
        Description = "ตั้งให้โหลดไฟล์นี้ทุกครั้งที่รันสคริปต์",
        ButtonText = "Set Auto",
        Callback = function()
            if SelectedFile ~= "" and SelectedFile ~= "---" then
                XPHub:SetAutoload(SelectedFile)
                StatusLabel:Set("Current Autoload: " .. SelectedFile) -- เรียกใช้ได้เพราะประกาศไว้ด้านบนแล้ว
                print("Autoload set to: " .. SelectedFile)
            end
        end
    })

    Sec9:AddButton({
        Title = "Reset Autoload",
        Description = "ยกเลิกการโหลดอัตโนมัติ",
        ButtonText = "Reset",
        Callback = function()
            XPHub:ResetAutoload()
            StatusLabel:Set("Current Autoload: None")
            print("Autoload Disabled")
        end
    })

    Sec9:AddButton({
        Title = "Delete Config",
        ButtonText = "Delete",
        Callback = function()
            if SelectedFile ~= "" and SelectedFile ~= "---" then
                local filePath = XPHub.ConfigFolder .. "/" .. SelectedFile .. ".json"
                if isfile(filePath) then
                    delfile(filePath)
                    if ConfigDropdown then
                        ConfigDropdown:Refresh(XPHub:GetConfigList())
                        ConfigDropdown:Set("---")
                    end
                    SelectedFile = ""
                end
            end
        end
    })

    StatusLabel = Sec9:AddLabel("Current Autoload: " .. (XPHub:GetAutoload() or "None"))

-- ### ส่วนล่าง: ระบบ Autoload ตอนเริ่มสคริปต์ ###
task.spawn(function()
    task.wait(1)
    local auto = XPHub:GetAutoload()
    if auto then 
        XPHub:LoadConfigData(auto)
    end
end)
