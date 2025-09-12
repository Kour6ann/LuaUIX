-- LuaUIX v19.1 - Enhanced UI Library with Proper API Structure
-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Library Table
local LuaUIX = {}
LuaUIX.__index = LuaUIX
LuaUIX.Version = "19.1"
LuaUIX.Themes = {}
LuaUIX.Elements = {}

-- Persistent Save/Load
local SAVE_FILE = "luaux_v19.json"
local settingsData = {}

-- Configuration
local config = {
    autoSave = true,
    saveInterval = 30,
    defaultSettings = {
        toggle = false,
        volume = 50,
        keybind = "RightShift",
        uiColor = {r = 70/255, g = 120/255, b = 255/255},
        theme = "Dark"
    }
}

-- Theme Definitions
LuaUIX.Themes.Dark = {
    Main = Color3.fromRGB(30, 30, 30),
    TopBar = Color3.fromRGB(20, 20, 20),
    TabBar = Color3.fromRGB(25, 25, 25),
    Content = Color3.fromRGB(35, 35, 35),
    Element = Color3.fromRGB(40, 40, 40),
    ElementHover = Color3.fromRGB(50, 50, 50),
    ElementActive = Color3.fromRGB(70, 120, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    TextMuted = Color3.fromRGB(150, 150, 150),
    Accent = Color3.fromRGB(70, 120, 255),
    Success = Color3.fromRGB(80, 200, 80),
    Warning = Color3.fromRGB(255, 180, 80),
    Error = Color3.fromRGB(220, 80, 80)
}

LuaUIX.Themes.Light = {
    Main = Color3.fromRGB(240, 240, 240),
    TopBar = Color3.fromRGB(220, 220, 220),
    TabBar = Color3.fromRGB(210, 210, 210),
    Content = Color3.fromRGB(230, 230, 230),
    Element = Color3.fromRGB(250, 250, 250),
    ElementHover = Color3.fromRGB(240, 240, 240),
    ElementActive = Color3.fromRGB(70, 120, 255),
    Text = Color3.fromRGB(30, 30, 30),
    TextSecondary = Color3.fromRGB(80, 80, 80),
    TextMuted = Color3.fromRGB(120, 120, 120),
    Accent = Color3.fromRGB(70, 120, 255),
    Success = Color3.fromRGB(60, 180, 60),
    Warning = Color3.fromRGB(220, 150, 60),
    Error = Color3.fromRGB(200, 60, 60)
}

LuaUIX.Themes.Midnight = {
    Main = Color3.fromRGB(15, 15, 25),
    TopBar = Color3.fromRGB(10, 10, 20),
    TabBar = Color3.fromRGB(20, 20, 30),
    Content = Color3.fromRGB(25, 25, 35),
    Element = Color3.fromRGB(35, 35, 45),
    ElementHover = Color3.fromRGB(45, 45, 55),
    ElementActive = Color3.fromRGB(80, 140, 255),
    Text = Color3.fromRGB(240, 240, 255),
    TextSecondary = Color3.fromRGB(180, 180, 200),
    TextMuted = Color3.fromRGB(120, 120, 150),
    Accent = Color3.fromRGB(80, 140, 255),
    Success = Color3.fromRGB(70, 200, 100),
    Warning = Color3.fromRGB(255, 200, 80),
    Error = Color3.fromRGB(240, 80, 100)
}

-- Load settings
pcall(function()
    if type(isfile) == "function" and isfile(SAVE_FILE) then
        local ok, data = pcall(function() return readfile(SAVE_FILE) end)
        if ok and data then
            local succ, decoded = pcall(function() return HttpService:JSONDecode(data) end)
            if succ and decoded then
                settingsData = decoded
            end
        end
    end
end)

-- Enhanced save function
local function saveSettings()
    if not config.autoSave then return end
    
    for key, defaultValue in pairs(config.defaultSettings) do
        if settingsData[key] == nil then
            settingsData[key] = defaultValue
        end
    end
    
    if type(writefile) == "function" then
        pcall(function()
            writefile(SAVE_FILE, HttpService:JSONEncode(settingsData))
        end)
    end
end

-- Auto-save timer
task.spawn(function()
    while task.wait(config.saveInterval) do
        saveSettings()
    end
end)

-- Destroy previous session if re-run
if CoreGui:FindFirstChild("LuaUIX_Main") then
    CoreGui.LuaUIX_Main:Destroy()
end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuaUIX_Main"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

-- Ripple Effect
local function makeRipple(parent, globalX, globalY)
    if not parent or not parent:IsA("GuiObject") then return end
    local topInset = 0
    pcall(function() topInset = GuiService:GetGuiInset().Y end)

    local relX = globalX - parent.AbsolutePosition.X
    local relY = (globalY - topInset) - parent.AbsolutePosition.Y

    if type(relX) ~= "number" or type(relY) ~= "number" or tostring(relX) == "nan" or tostring(relY) == "nan" then
        relX, relY = parent.AbsoluteSize.X/2, parent.AbsoluteSize.Y/2
    end

    local p = Instance.new("Frame")
    p.Size = UDim2.new(0, 8, 0, 8)
    p.AnchorPoint = Vector2.new(0.5, 0.5)
    p.Position = UDim2.new(0, relX, 0, relY)
    p.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
    p.BackgroundTransparency = 0.6
    p.ZIndex = (parent.ZIndex or 1) + 10
    p.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = p

    local ok, tween = pcall(function()
        return TweenService:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 120, 0, 120),
            BackgroundTransparency = 1
        })
    end)

    if ok and tween then
        tween:Play()
        tween.Completed:Connect(function()
            if p and p.Parent then p:Destroy() end
        end)
    else
        if p and p.Parent then p:Destroy() end
    end
end

-- Set default theme
LuaUIX.CurrentTheme = LuaUIX.Themes[settingsData.theme or "Dark"]

-- API: CreateWindow
function LuaUIX:CreateWindow(options)
    options = options or {}
    local window = {
        Name = options.Name or "LuaUIX Window",
        Size = options.Size or {500, 350},
        Theme = options.Theme or "Dark",
        Tabs = {},
        Elements = {}
    }
    
    -- Set theme
    LuaUIX.CurrentTheme = LuaUIX.Themes[window.Theme]
    
    -- Main Frame
    local TARGET_WIDTH, TARGET_HEIGHT = window.Size[1], window.Size[2]
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -TARGET_WIDTH/2, 0.5, -TARGET_HEIGHT/2)
    MainFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Main
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui
    window.MainFrame = MainFrame
    
    local UICorner = Instance.new("UICorner", MainFrame)
    UICorner.CornerRadius = UDim.new(0, 12)

    -- Drop shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.ZIndex = -1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10,10,118,118)
    Shadow.Parent = MainFrame

    -- Topbar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = LuaUIX.CurrentTheme.TopBar
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    window.TopBar = TopBar
    
    local TopBarCorner = Instance.new("UICorner", TopBar)
    TopBarCorner.CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = window.Name
    Title.TextColor3 = LuaUIX.CurrentTheme.Text
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- Minimize Button
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0,25,0,25)
    MinimizeBtn.Position = UDim2.new(1, -60, 0.5, -12)
    MinimizeBtn.Text = "_"
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.BackgroundColor3 = LuaUIX.CurrentTheme.Element
    MinimizeBtn.TextColor3 = LuaUIX.CurrentTheme.Text
    MinimizeBtn.Font = Enum.Font.SourceSansBold
    MinimizeBtn.TextSize = 16
    MinimizeBtn.Parent = TopBar
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0,6)

    MinimizeBtn.MouseEnter:Connect(function()
        TweenService:Create(MinimizeBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.ElementHover}):Play()
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        TweenService:Create(MinimizeBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
    end)

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0,25,0,25)
    CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
    CloseBtn.Text = "X"
    CloseBtn.AutoButtonColor = false
    CloseBtn.BackgroundColor3 = LuaUIX.CurrentTheme.Error
    CloseBtn.TextColor3 = LuaUIX.CurrentTheme.Text
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.TextSize = 16
    CloseBtn.Parent = TopBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)

    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(220,70,70)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Error}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- Dragging system
    local draggingUI, dragStart, startPos, dragInput
    local dragConnectionCleanup = {}

    local function updateDrag(input)
        if not (dragStart and startPos) then return end
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingUI = true
            dragStart = input.Position
            startPos = MainFrame.Position

            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingUI = false
                    if changedConn then
                        changedConn:Disconnect()
                        changedConn = nil
                    end
                end
            end)
            table.insert(dragConnectionCleanup, changedConn)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and draggingUI then
            updateDrag(input)
        end
    end)

    -- Tab Bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0,120,1,-30)
    TabBar.Position = UDim2.new(0,0,0,30)
    TabBar.BackgroundColor3 = LuaUIX.CurrentTheme.TabBar
    TabBar.BorderSizePixel = 0
    TabBar.Parent = MainFrame
    window.TabBar = TabBar
    
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0,8)

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Vertical
    TabLayout.Padding = UDim.new(0,5)
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TabLayout.Parent = TabBar

    -- TabHolder
    local TabHolder = Instance.new("Frame")
    TabHolder.Size = UDim2.new(1, -130, 1, -40)
    TabHolder.Position = UDim2.new(0, 130, 0, 35)
    TabHolder.BackgroundColor3 = LuaUIX.CurrentTheme.Content
    TabHolder.Parent = MainFrame
    window.TabHolder = TabHolder
    
    Instance.new("UICorner", TabHolder).CornerRadius = UDim.new(0,8)

    -- Window methods
    function window:SetTheme(themeName)
        if LuaUIX.Themes[themeName] then
            LuaUIX.CurrentTheme = LuaUIX.Themes[themeName]
            settingsData.theme = themeName
            saveSettings()
            self.Theme = themeName  -- Update window theme property
            
            -- Update theme labels across all tabs
            for _, tab in pairs(self.Tabs) do
                for _, section in pairs(tab.Elements) do
                    for _, element in pairs(section.Elements) do
                        if element.Type == "Label" and string.find(element.Text or "", "Current theme:") then
                            element:SetText("Current theme: " .. themeName)
                        end
                        if element.ApplyTheme then
                            element:ApplyTheme()
                        end
                    end
                end
            end
            self:ApplyTheme()
        end
    end

    function window:ApplyTheme()
        self.MainFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Main
        self.TopBar.BackgroundColor3 = LuaUIX.CurrentTheme.TopBar
        self.TabBar.BackgroundColor3 = LuaUIX.CurrentTheme.TabBar
        self.TabHolder.BackgroundColor3 = LuaUIX.CurrentTheme.Content

        -- Ensure header bar text/buttons stay readable
        if self.TopBar:FindFirstChild("TextLabel") then
            self.TopBar.TextLabel.TextColor3 = LuaUIX.CurrentTheme.Text
        end
        if self.TopBar:FindFirstChild("TextButton") then
            for _,btn in pairs(self.TopBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.TextColor3 = LuaUIX.CurrentTheme.Text
                end
            end
        end

        -- Update all elements
        for _, element in pairs(self.Elements) do
            if element.ApplyTheme then
                element:ApplyTheme()
            end
        end
    end

    function window:CreateTab(name)
        local tab = {
            Name = name,
            Elements = {},
            Window = self
        }
        
        -- Create tab button
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.BackgroundColor3 = LuaUIX.CurrentTheme.Element
        btn.TextColor3 = LuaUIX.CurrentTheme.Text
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.Text = name
        btn.AutoButtonColor = false
        btn.Parent = TabBar
        tab.Button = btn
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

        -- Create tab page
        local page = Instance.new("Frame")
        page.Size = UDim2.new(1,0,1,0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.Parent = TabHolder
        tab.Page = page

        -- Tab content container
        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -20, 1, -20)
        content.Position = UDim2.new(0, 10, 0, 10)
        content.BackgroundTransparency = 1
        content.Parent = page
        tab.Content = content
        
        local layout = Instance.new("UIListLayout", content)
        layout.Padding = UDim.new(0,12)

        -- Tab methods
        function tab:CreateSection(title, height)
            local section = {
                Title = title,
                Height = height or 100,
                Elements = {},
                Tab = self
            }
            
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(1, 0, 0, section.Height)
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.Parent = content
            section.Frame = sectionFrame
            
            if title then
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -10, 0, 20)
                label.Position = UDim2.new(0, 10, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = title
                label.TextColor3 = LuaUIX.CurrentTheme.TextMuted
                label.Font = Enum.Font.GothamSemibold
                label.TextSize = 14
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = sectionFrame
            end
            
            local sectionContent = Instance.new("Frame")
            sectionContent.Size = UDim2.new(1, 0, 0, section.Height - (title and 25 or 0))
            sectionContent.Position = UDim2.new(0, 0, 0, title and 25 or 0)
            sectionContent.BackgroundTransparency = 1
            sectionContent.Parent = sectionFrame
            section.Content = sectionContent
            
            local sectionLayout = Instance.new("UIListLayout", sectionContent)
            sectionLayout.Padding = UDim.new(0, 8)
            
            -- Section methods
            function section:CreateButton(name, callback)
                local button = {
                    Type = "Button",
                    Name = name,
                    Callback = callback,
                    Section = self
                }
                
                local btnFrame = Instance.new("TextButton")
                btnFrame.Size = UDim2.new(1, 0, 0, 32)
                btnFrame.Text = name
                btnFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                btnFrame.TextColor3 = LuaUIX.CurrentTheme.Text
                btnFrame.Font = Enum.Font.Gotham
                btnFrame.TextSize = 14
                btnFrame.AutoButtonColor = false
                btnFrame.Parent = self.Content
                button.Frame = btnFrame
                
                Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0,6)

                btnFrame.MouseButton1Click:Connect(function()
                    local pos = UserInputService:GetMouseLocation()
                    makeRipple(btnFrame, pos.X, pos.Y)
                    if callback then
                        callback()
                    end
                end)

                btnFrame.MouseEnter:Connect(function()
                    TweenService:Create(btnFrame, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.ElementHover}):Play()
                end)
                btnFrame.MouseLeave:Connect(function()
                    TweenService:Create(btnFrame, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
                end)

                -- Button methods
                function button:SetText(text)
                    btnFrame.Text = text
                end

                function button:SetCallback(cb)
                    button.Callback = cb
                end

                function button:ApplyTheme()
                    btnFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    btnFrame.TextColor3 = LuaUIX.CurrentTheme.Text
                end

                table.insert(self.Elements, button)
                table.insert(self.Tab.Window.Elements, button)
                return button
            end

            function section:CreateToggle(name, defaultValue, callback)
                local toggle = {
                    Type = "Toggle",
                    Name = name,
                    Value = defaultValue or false,
                    Callback = callback,
                    Section = self
                }
                
                local toggleFrame = Instance.new("TextButton")
                toggleFrame.Size = UDim2.new(1, 0, 0, 32)
                toggleFrame.Text = name .. ": " .. (toggle.Value and "ON" or "OFF")
                toggleFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                toggleFrame.TextColor3 = LuaUIX.CurrentTheme.Text
                toggleFrame.Font = Enum.Font.Gotham
                toggleFrame.TextSize = 14
                toggleFrame.AutoButtonColor = false
                toggleFrame.Parent = self.Content
                toggle.Frame = toggleFrame
                
                Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0,6)

                toggleFrame.MouseButton1Click:Connect(function()
                    local pos = UserInputService:GetMouseLocation()
                    makeRipple(toggleFrame, pos.X, pos.Y)
                    toggle.Value = not toggle.Value
                    toggleFrame.Text = name .. ": " .. (toggle.Value and "ON" or "OFF")
                    if callback then
                        callback(toggle.Value)
                    end
                end)

                toggleFrame.MouseEnter:Connect(function()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.ElementHover}):Play()
                end)
                toggleFrame.MouseLeave:Connect(function()
                    TweenService:Create(toggleFrame, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
                end)

                -- Toggle methods
                function toggle:Set(value)
                    toggle.Value = value
                    toggleFrame.Text = name .. ": " .. (value and "ON" or "OFF")
                    if callback then
                        callback(value)
                    end
                end

                function toggle:Get()
                    return toggle.Value
                end

                function toggle:ApplyTheme()
                    toggleFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    toggleFrame.TextColor3 = LuaUIX.CurrentTheme.Text
                end

                table.insert(self.Elements, toggle)
                table.insert(self.Tab.Window.Elements, toggle)
                return toggle
            end

            function section:CreateSlider(name, min, max, defaultValue, callback)
                local slider = {
                    Type = "Slider",
                    Name = name,
                    Min = min or 0,
                    Max = max or 100,
                    Value = defaultValue or 50,
                    Callback = callback,
                    Section = self
                }
                
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(1, 0, 0, 50)
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Parent = self.Content
                slider.Frame = sliderFrame

                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Size = UDim2.new(1, 0, 0, 20)
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Text = name .. ": " .. slider.Value
                sliderLabel.TextColor3 = LuaUIX.CurrentTheme.Text
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.TextSize = 14
                sliderLabel.Parent = sliderFrame

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 25)
                track.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                track.Parent = sliderFrame
                Instance.new("UICorner", track).CornerRadius = UDim.new(0,3)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
                fill.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
                fill.Parent = track
                Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 12, 0, 12)
                knob.Position = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), -6, 0.5, -6)
                knob.BackgroundColor3 = LuaUIX.CurrentTheme.Text
                knob.Parent = track
                Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

                local dragging = false

                local function setValue(value)
                    local clamped = math.clamp(value, slider.Min, slider.Max)
                    slider.Value = clamped
                    sliderLabel.Text = name .. ": " .. clamped
                    fill.Size = UDim2.new((clamped - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
                    knob.Position = UDim2.new((clamped - slider.Min) / (slider.Max - slider.Min), -6, 0.5, -6)
                    if callback then
                        callback(clamped)
                    end
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local posX = UserInputService:GetMouseLocation().X
                        local rel = (posX - track.AbsolutePosition.X) / track.AbsoluteSize.X
                        setValue(math.floor(slider.Min + rel * (slider.Max - slider.Min)))
                    end
                end)

                track.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local posX = UserInputService:GetMouseLocation().X
                        local rel = (posX - track.AbsolutePosition.X) / track.AbsoluteSize.X
                        setValue(math.floor(slider.Min + rel * (slider.Max - slider.Min)))
                    end
                end)

                -- Slider methods
                function slider:Set(value)
                    setValue(value)
                end

                function slider:Get()
                    return slider.Value
                end

                function slider:ApplyTheme()
                    sliderLabel.TextColor3 = LuaUIX.CurrentTheme.Text
                    track.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    fill.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
                    knob.BackgroundColor3 = LuaUIX.CurrentTheme.Text
                end

                table.insert(self.Elements, slider)
                table.insert(self.Tab.Window.Elements, slider)
                return slider
            end

            function section:CreateDropdown(name, options, defaultIndex, callback, multiSelect)
                local dropdown = {
                    Type = "Dropdown",
                    Name = name,
                    Options = options or {},
                    Value = defaultIndex or 1,
                    Callback = callback,
                    MultiSelect = multiSelect or false,
                    Section = self
                }
                
                if multiSelect and defaultIndex then
                    dropdown.SelectedIndices = type(defaultIndex) == "table" and defaultIndex or {defaultIndex}
                end

                local dropdownFrame = Instance.new("TextButton")
                dropdownFrame.Size = UDim2.new(1, 0, 0, 32)
                dropdownFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                dropdownFrame.AutoButtonColor = false
                dropdownFrame.Parent = self.Content
                dropdownFrame.ZIndex = 10
                dropdown.Frame = dropdownFrame
                
                Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0,6)

                local dropdownLabel = Instance.new("TextLabel")
                dropdownLabel.Size = UDim2.new(1, -30, 1, 0)
                dropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                dropdownLabel.BackgroundTransparency = 1
                dropdownLabel.TextColor3 = LuaUIX.CurrentTheme.Text
                dropdownLabel.Font = Enum.Font.Gotham
                dropdownLabel.TextSize = 14
                dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                dropdownLabel.Parent = dropdownFrame
                dropdown.Label = dropdownLabel

                local dropdownArrow = Instance.new("TextLabel")
                dropdownArrow.Size = UDim2.new(0, 20, 1, 0)
                dropdownArrow.Position = UDim2.new(1, -25, 0, 0)
                dropdownArrow.BackgroundTransparency = 1
                dropdownArrow.Text = "▼"
                dropdownArrow.TextColor3 = LuaUIX.CurrentTheme.Text
                dropdownArrow.Font = Enum.Font.Gotham
                dropdownArrow.TextSize = 14
                dropdownArrow.Parent = dropdownFrame

                local dropdownList = Instance.new("Frame")
                dropdownList.Size = UDim2.new(0, dropdownFrame.AbsoluteSize.X, 0, 0)
                dropdownList.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                dropdownList.BorderSizePixel = 0
                dropdownList.Visible = false
                dropdownList.ZIndex = 1000
                dropdownList.Parent = ScreenGui
                dropdown.List = dropdownList
                
                Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0,6)

                local listLayout = Instance.new("UIListLayout", dropdownList)
                listLayout.Padding = UDim.new(0,4)

                local dropdownOpen = false
                local outsideClickConn

                local function closeDropdown()
                    if dropdownOpen then
                        dropdownOpen = false
                        dropdownList.Visible = false
                        dropdownArrow.Text = "▼"
                        if outsideClickConn then
                            pcall(function() outsideClickConn:Disconnect() end)
                            outsideClickConn = nil
                        end
                    end
                end

                local function updateSelection()
                    if dropdown.MultiSelect then
                        local names = {}
                        for _, idx in ipairs(dropdown.SelectedIndices or {}) do
                            if dropdown.Options[idx] then 
                                table.insert(names, dropdown.Options[idx]) 
                            end
                        end
                        dropdownLabel.Text = name .. ": " .. (#names > 0 and table.concat(names, ", ") or "Select...")
                    else
                        dropdownLabel.Text = name .. ": " .. (dropdown.Options[dropdown.Value] or "Select...")
                    end
                end

                local function createOption(option, idx)
                    local optionBtn = Instance.new("TextButton")
                    optionBtn.Size = UDim2.new(1, -10, 0, 28)
                    optionBtn.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    optionBtn.TextColor3 = LuaUIX.CurrentTheme.Text
                    optionBtn.Text = option
                    optionBtn.Font = Enum.Font.Gotham
                    optionBtn.TextSize = 14
                    optionBtn.AutoButtonColor = false
                    optionBtn.Parent = dropdownList
                    optionBtn.ZIndex = 1001
                    Instance.new("UICorner", optionBtn).CornerRadius = UDim.new(0,4)

                    -- Set initial selection
                    if dropdown.MultiSelect then
                        if table.find(dropdown.SelectedIndices or {}, idx) then
                            optionBtn.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
                        end
                    else
                        if idx == dropdown.Value then
                            optionBtn.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
                        end
                    end

                    optionBtn.MouseEnter:Connect(function()
                        TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.ElementHover}):Play()
                    end)
                    optionBtn.MouseLeave:Connect(function()
                        if dropdown.MultiSelect then
                            if table.find(dropdown.SelectedIndices or {}, idx) then
                                TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Accent}):Play()
                            else
                                TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
                            end
                        else
                            if idx == dropdown.Value then
                                TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Accent}):Play()
                            else
                                TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
                            end
                        end
                    end)

                    optionBtn.MouseButton1Click:Connect(function()
                        local pos = UserInputService:GetMouseLocation()
                        makeRipple(optionBtn, pos.X, pos.Y)

                        if dropdown.MultiSelect then
                            local found = table.find(dropdown.SelectedIndices or {}, idx)
                            if found then 
                                table.remove(dropdown.SelectedIndices, found)
                                TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
                            else 
                                table.insert(dropdown.SelectedIndices, idx)
                                TweenService:Create(optionBtn, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Accent}):Play()
                            end
                            if callback then
                                callback(dropdown.SelectedIndices)
                            end
                            updateSelection()
                        else
                            dropdown.Value = idx
                            for i, child in ipairs(dropdownList:GetChildren()) do
                                if child:IsA("TextButton") then
                                    if i == idx then
                                        TweenService:Create(child, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Accent}):Play()
                                    else
                                        TweenService:Create(child, TweenInfo.new(0.12), {BackgroundColor3 = LuaUIX.CurrentTheme.Element}):Play()
                                    end
                                end
                            end
                            if callback then callback(idx) end
                            updateSelection()
                            closeDropdown()
                        end
                    end)
                end

                -- Populate options
                for i, option in ipairs(dropdown.Options) do createOption(option, i) end

                dropdownFrame.MouseButton1Click:Connect(function()
                    if dropdownOpen then
                        closeDropdown()
                    else
                        dropdownOpen = true
                        local absPos, absSize = dropdownFrame.AbsolutePosition, dropdownFrame.AbsoluteSize
                        dropdownList.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 2)
                        dropdownList.Size = UDim2.fromOffset(absSize.X, math.min(#dropdown.Options * 32 + 10, 150))
                        dropdownList.Visible = true
                        dropdownArrow.Text = "▲"

                        outsideClickConn = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                            local mouse = UserInputService:GetMouseLocation()
                            local inList = mouse.X >= dropdownList.AbsolutePosition.X and mouse.X <= (dropdownList.AbsolutePosition.X + dropdownList.AbsoluteSize.X)
                                and mouse.Y >= dropdownList.AbsolutePosition.Y and mouse.Y <= (dropdownList.AbsolutePosition.Y + dropdownList.AbsoluteSize.Y)
                            local inBtn = mouse.X >= dropdownFrame.AbsolutePosition.X and mouse.X <= (dropdownFrame.AbsolutePosition.X + dropdownFrame.AbsoluteSize.X)
                                and mouse.Y >= dropdownFrame.AbsolutePosition.Y and mouse.Y <= (dropdownFrame.AbsolutePosition.Y + dropdownFrame.AbsoluteSize.Y)
                            if not inList and not inBtn then
                                closeDropdown()
                            end
                        end)
                    end
                end)

                updateSelection()

                -- Dropdown methods
                function dropdown:SetValue(value)
                    if dropdown.MultiSelect then
                        dropdown.SelectedIndices = type(value) == "table" and value or {value}
                    else
                        dropdown.Value = value
                    end
                    updateSelection()
                    if callback then
                        if dropdown.MultiSelect then
                            callback(dropdown.SelectedIndices)
                        else
                            callback(dropdown.Value)
                        end
                    end
                end

                function dropdown:GetValue()
                    if dropdown.MultiSelect then
                        return dropdown.SelectedIndices
                    else
                        return dropdown.Value
                    end
                end

                function dropdown:SetOptions(newOptions)
                    dropdown.Options = newOptions or {}
                    -- Clear existing options
                    for i = #dropdownList:GetChildren(), 1, -1 do
                        local child = dropdownList:GetChildren()[i]
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    -- Create new options
                    for i, option in ipairs(dropdown.Options) do createOption(option, i) end
                    updateSelection()
                end

                function dropdown:ApplyTheme()
                    dropdownFrame.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    dropdownLabel.TextColor3 = LuaUIX.CurrentTheme.Text
                    dropdownArrow.TextColor3 = LuaUIX.CurrentTheme.Text
                    dropdownList.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    
                    for _, child in ipairs(dropdownList:GetChildren()) do
                        if child:IsA("TextButton") then
                            if dropdown.MultiSelect then
                                if table.find(dropdown.SelectedIndices or {}, _) then
                                    child.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
                                else
                                    child.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                                end
                            else
                                if _ == dropdown.Value then
                                    child.BackgroundColor3 = LuaUIX.CurrentTheme.Accent
                                else
                                    child.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                                end
                            end
                            child.TextColor3 = LuaUIX.CurrentTheme.Text
                        end
                    end
                end

                table.insert(self.Elements, dropdown)
                table.insert(self.Tab.Window.Elements, dropdown)
                return dropdown
            end

            function section:CreateLabel(text)
                local label = {
                    Type = "Label",
                    Text = text,
                    Section = self
                }
                
                local labelFrame = Instance.new("TextLabel")
                labelFrame.Size = UDim2.new(1, 0, 0, 20)
                labelFrame.BackgroundTransparency = 1
                labelFrame.Text = text
                labelFrame.TextColor3 = LuaUIX.CurrentTheme.TextSecondary
                labelFrame.Font = Enum.Font.Gotham
                labelFrame.TextSize = 14
                labelFrame.TextXAlignment = Enum.TextXAlignment.Left
                labelFrame.Parent = self.Content
                label.Frame = labelFrame

                -- Label methods
                function label:SetText(newText)
                    labelFrame.Text = newText
                    label.Text = newText
                end

                function label:ApplyTheme()
                    labelFrame.TextColor3 = LuaUIX.CurrentTheme.TextSecondary
                end

                table.insert(self.Elements, label)
                table.insert(self.Tab.Window.Elements, label)
                return label
            end

            function section:CreateInput(name, placeholder, callback)
                local input = {
                    Type = "Input",
                    Name = name,
                    Placeholder = placeholder,
                    Callback = callback,
                    Section = self
                }
                
                local inputFrame = Instance.new("Frame")
                inputFrame.Size = UDim2.new(1, 0, 0, 32)
                inputFrame.BackgroundTransparency = 1
                inputFrame.Parent = self.Content
                input.Frame = inputFrame

                local inputLabel = Instance.new("TextLabel")
                inputLabel.Size = UDim2.new(0.4, -5, 1, 0)
                inputLabel.BackgroundTransparency = 1
                inputLabel.Text = name
                inputLabel.TextColor3 = LuaUIX.CurrentTheme.Text
                inputLabel.Font = Enum.Font.Gotham
                inputLabel.TextSize = 14
                inputLabel.TextXAlignment = Enum.TextXAlignment.Left
                inputLabel.Parent = inputFrame

                local inputBox = Instance.new("TextBox")
                inputBox.Size = UDim2.new(0.6, -5, 1, 0)
                inputBox.Position = UDim2.new(0.4, 5, 0, 0)
                inputBox.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                inputBox.TextColor3 = LuaUIX.CurrentTheme.Text
                inputBox.Font = Enum.Font.Gotham
                inputBox.TextSize = 14
                inputBox.PlaceholderText = placeholder or ""
                inputBox.Text = ""
                inputBox.Parent = inputFrame
                Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

                inputBox.FocusLost:Connect(function()
                    if callback then
                        callback(inputBox.Text)
                    end
                end)

                -- Input methods
                function input:SetText(text)
                    inputBox.Text = text
                end

                function input:GetText()
                    return inputBox.Text
                end

                function input:SetCallback(cb)
                    input.Callback = cb
                end

                function input:ApplyTheme()
                    inputLabel.TextColor3 = LuaUIX.CurrentTheme.Text
                    inputBox.BackgroundColor3 = LuaUIX.CurrentTheme.Element
                    inputBox.TextColor3 = LuaUIX.CurrentTheme.Text
                end

                table.insert(self.Elements, input)
                table.insert(self.Tab.Window.Elements, input)
                return input
            end

            function section:ApplyTheme()
                for _, element in pairs(self.Elements) do
                    if element.ApplyTheme then
                        element:ApplyTheme()
                    end
                end
            end

            table.insert(self.Elements, section)
            return section
        end

        function tab:Switch()
            for _, otherTab in pairs(self.Window.Tabs) do
                otherTab.Page.Visible = false
                otherTab.Button.BackgroundColor3 = LuaUIX.CurrentTheme.Element
            end
            self.Page.Visible = true
            self.Button.BackgroundColor3 = LuaUIX.CurrentTheme.ElementActive
        end

        function tab:ApplyTheme()
            self.Button.BackgroundColor3 = self.Page.Visible and LuaUIX.CurrentTheme.ElementActive or LuaUIX.CurrentTheme.Element
            self.Button.TextColor3 = LuaUIX.CurrentTheme.Text
            
            for _, section in pairs(self.Elements) do
                if section.ApplyTheme then
                    section:ApplyTheme()
                end
            end
        end

        btn.MouseButton1Click:Connect(function()
            local pos = UserInputService:GetMouseLocation()
            makeRipple(btn, pos.X, pos.Y)
            tab:Switch()
        end)

        table.insert(self.Tabs, tab)
        return tab
    end

    -- Switch to first tab by default
    function window:SwitchToFirstTab()
        if #self.Tabs > 0 then
            self.Tabs[1]:Switch()
        end
    end

    -- Animate window in
    function window:Show()
        MainFrame.Visible = true
        local ok, tween = pcall(function()
            return TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, TARGET_WIDTH, 0, TARGET_HEIGHT)
            })
        end)
        if ok and tween then tween:Play() else MainFrame.Size = UDim2.new(0, TARGET_WIDTH, 0, TARGET_HEIGHT) end
    end

    function window:Hide()
        MainFrame.Visible = false
    end

    function window:Toggle()
        MainFrame.Visible = not MainFrame.Visible
    end

    -- Minimize functionality
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        
        if minimized then
            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, TARGET_WIDTH, 0, 30)
            })
            tween:Play()
            tween.Completed:Connect(function()
                TabBar.Visible = false
                TabHolder.Visible = false
            end)
        else
            TabBar.Visible = true
            TabHolder.Visible = true
            local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, TARGET_WIDTH, 0, TARGET_HEIGHT)
            })
            tween:Play()
        end
    end)

    -- Keybind toggle handler
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local pressed = tostring(input.KeyCode.Name or input.KeyCode)
            local configured = settingsData.keybind or "RightShift"
            if pressed == configured then
                window:Toggle()
            end
        end
    end)

    -- Show window initially
    window:Show()
    window:SwitchToFirstTab()

    return window
end

-- Notification system
function LuaUIX:Notify(title, message, duration)
    duration = duration or 5
    
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 300, 0, 80)
    Notification.Position = UDim2.new(1, -320, 0, 10)
    Notification.BackgroundColor3 = LuaUIX.CurrentTheme.Main
    Notification.ZIndex = 1000
    Notification.Parent = ScreenGui
    Instance.new("UICorner", Notification).CornerRadius = UDim.new(0, 8)
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Position = UDim2.new(0, 10, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = LuaUIX.CurrentTheme.Text
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Notification
    
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -20, 1, -40)
    MessageLabel.Position = UDim2.new(0, 10, 0, 35)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = message
    MessageLabel.TextColor3 = LuaUIX.CurrentTheme.TextSecondary
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.TextSize = 14
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.TextWrapped = true
    MessageLabel.Parent = Notification
    
    -- Animate in
    Notification.Position = UDim2.new(1, 300, 0, 10)
    local tweenIn = TweenService:Create(Notification, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -320, 0, 10)
    })
    tweenIn:Play()
    
    -- Auto dismiss after duration
    task.delay(duration, function()
        if Notification and Notification.Parent then
            local tweenOut = TweenService:Create(Notification, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 300, 0, 10)
            })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                Notification:Destroy()
            end)
        end
    end)
end

-- FPS watermark
local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(0,120,0,30)
FPSLabel.Position = UDim2.new(0,10,1,-40)
FPSLabel.BackgroundColor3 = LuaUIX.CurrentTheme.Main
FPSLabel.TextColor3 = LuaUIX.CurrentTheme.Text
FPSLabel.Text = "FPS: 60"
FPSLabel.Font = Enum.Font.Gotham
FPSLabel.TextSize = 14
FPSLabel.Parent = ScreenGui
Instance.new("UICorner", FPSLabel).CornerRadius = UDim.new(0,6)

-- FPS update loop
local lastTime = os.clock()
local frameCount = 0
RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    local currentTime = os.clock()
    if currentTime - lastTime >= 1 then
        local fps = math.floor(frameCount / (currentTime - lastTime))
        FPSLabel.Text = "FPS: " .. fps
        frameCount = 0
        lastTime = currentTime
    end
end)

-- Send welcome notification
task.delay(1, function()
    LuaUIX:Notify("LuaUIX v19.1", "UI Library loaded successfully!", 3)
end)

-- Return the library for external use
return LuaUIX
