-- LuaUIX Library v1.6
-- Enhanced UI library for Roblox exploits

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Utility functions
local function createInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

-- Color palette
local colors = {
    background = Color3.fromRGB(33, 34, 44),
    titlebar = Color3.fromRGB(46, 46, 66),
    sidebar = Color3.fromRGB(27, 28, 37),
    content = Color3.fromRGB(40, 42, 54),
    section = Color3.fromRGB(23, 25, 34),
    accent = Color3.fromRGB(56, 172, 212),
    button = Color3.fromRGB(90, 120, 255),
    toggleOff = Color3.fromRGB(42, 46, 59),
    text = Color3.fromRGB(255, 255, 255),
    textSecondary = Color3.fromRGB(200, 200, 200),
    success = Color3.fromRGB(76, 175, 80),
    warning = Color3.fromRGB(255, 193, 7),
    error = Color3.fromRGB(244, 67, 54)
}

-- Library initialization
function LuaUIX.new(menuName)
    local self = setmetatable({}, LuaUIX)
    
    -- Cleanup existing UI
    if CoreGui:FindFirstChild("LuaUIX_" .. menuName) then
        CoreGui["LuaUIX_" .. menuName]:Destroy()
    end
    
    -- Create main GUI
    self.gui = createInstance("ScreenGui", {
        Name = "LuaUIX_" .. menuName,
        ResetOnSpawn = false,
        Parent = CoreGui
    })
    
    -- Create main window
    self.window = createInstance("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 650, 0, 500),
        Position = UDim2.new(0.5, -325, 0.5, -250),
        BackgroundColor3 = colors.background,
        Parent = self.gui
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.window
    })
    
    -- Create titlebar
    self.titlebar = createInstance("Frame", {
        Name = "Titlebar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.titlebar,
        Parent = self.window
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.titlebar
    })
    
    self.title = createInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = menuName or "LuaUIX Window",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.titlebar
    })
    
    -- Create sidebar
    self.sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = colors.sidebar,
        Parent = self.window
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.sidebar
    })
    
    -- Create content area
    self.content = createInstance("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundColor3 = colors.content,
        Parent = self.window
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.content
    })
    
    -- Initialize pages table
    self.pages = {}
    self.currentPage = nil
    self.tabButtons = {}
    
    -- Add draggable functionality
    self:draggable(self.titlebar)
    
    -- Add keybind to toggle UI
    self:setupToggleKeybind()
    
    -- Create watermark
    self:CreateWatermark("LuaUIX v1.6")
    
    return self
end

-- Make window draggable
function LuaUIX:draggable(frame)
    local dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = self.window.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragStart then
            local delta = input.Position - dragStart
            self.window.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Setup UI toggle keybind
function LuaUIX:setupToggleKeybind()
    local toggleKey = Enum.KeyCode.RightShift
    
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then
            self:ToggleVisibility()
        end
    end)
end

-- Create a new page
function LuaUIX:CreatePage(name, icon)
    local page = createInstance("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = colors.accent,
        Parent = self.content
    })
    
    local layout = createInstance("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })
    
    local padding = createInstance("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = page
    })
    
    self.pages[name] = page
    
    -- Create tab button
    local tabCount = 0
    for _ in pairs(self.pages) do
        tabCount = tabCount + 1
    end
    
    local tabButton = createInstance("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10 + (tabCount - 1) * 50),
        BackgroundColor3 = colors.toggleOff,
        Text = icon and (icon .. "  " .. name) or name,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = self.sidebar
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = tabButton
    })
    
    tabButton.MouseButton1Click:Connect(function()
        self:ShowPage(name)
    end)
    
    self.tabButtons[name] = tabButton
    
    -- Show first page by default
    if tabCount == 1 then
        self:ShowPage(name)
    end
    
    return page
end

-- Show a specific page
function LuaUIX:ShowPage(name)
    if self.currentPage then
        self.currentPage.Visible = false
        -- Reset tab button color
        for pageName, button in pairs(self.tabButtons) do
            button.BackgroundColor3 = colors.toggleOff
        end
    end
    
    if self.pages[name] then
        self.pages[name].Visible = true
        self.currentPage = self.pages[name]
        -- Highlight active tab
        self.tabButtons[name].BackgroundColor3 = colors.accent
    end
end

-- Create a section
function LuaUIX:CreateSection(parent, titleText)
    local section = createInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = colors.section,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = section
    })
    
    local padding = createInstance("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = section
    })
    
    local layout = createInstance("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = section
    })
    
    local header = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = titleText or "Section",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    return section
end

-- Create a toggle
function LuaUIX:CreateToggle(parent, text, callback, defaultValue)
    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = defaultValue and colors.accent or colors.toggleOff,
        Text = text or "Toggle",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = btn
    })
    
    local state = defaultValue or false
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and colors.accent or colors.toggleOff
        if callback then 
            callback(state) 
        end
    end)
    
    return {
        SetState = function(newState)
            state = newState
            btn.BackgroundColor3 = state and colors.accent or colors.toggleOff
        end,
        GetState = function()
            return state
        end
    }
end

-- Create a button with hover effects
function LuaUIX:CreateButton(parent, text, callback, color)
    color = color or colors.button
    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = color,
        Text = text or "Button",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = btn
    })
    
    -- Hover effects
    local originalSize = btn.Size
    btn.MouseEnter:Connect(function()
        self:AnimateElement(btn, "Size", UDim2.new(1, 5, 0, 32), 0.1)
        self:AnimateElement(btn, "BackgroundColor3", Color3.fromRGB(
            math.min(color.R * 255 + 20, 255),
            math.min(color.G * 255 + 20, 255),
            math.min(color.B * 255 + 20, 255)
        ), 0.1)
    end)
    
    btn.MouseLeave:Connect(function()
        self:AnimateElement(btn, "Size", originalSize, 0.1)
        self:AnimateElement(btn, "BackgroundColor3", color, 0.1)
    end)
    
    btn.MouseButton1Click:Connect(function()
        self:AnimateElement(btn, "BackgroundColor3", Color3.fromRGB(
            math.max(color.R * 255 - 20, 0),
            math.max(color.G * 255 - 20, 0),
            math.max(color.B * 255 - 20, 0)
        ), 0.1)
        
        wait(0.1)
        self:AnimateElement(btn, "BackgroundColor3", color, 0.1)
        
        if callback then 
            callback() 
        end
    end)
    
    return btn
end

-- Create a slider
function LuaUIX:CreateSlider(parent, text, min, max, callback, defaultValue, precision)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text .. ": " .. (defaultValue or min),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local sliderBack = createInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(60, 60, 80),
        BorderSizePixel = 0,
        Parent = frame
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = sliderBack
    })
    
    local sliderFill = createInstance("Frame", {
        Size = UDim2.new(defaultValue and ((defaultValue - min) / (max - min)) or 0, 0, 1, 0),
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
        Parent = sliderBack
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = sliderFill
    })
    
    local dragging = false
    local currentValue = defaultValue or min
    local precision = precision or 0
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
            sliderFill.Size = UDim2.new(rel, 0, 1, 0)
            
            if precision > 0 then
                currentValue = math.floor((min + (max - min) * rel) * 10^precision) / 10^precision
            else
                currentValue = math.floor(min + (max - min) * rel)
            end
            
            label.Text = text .. ": " .. currentValue
            if callback then 
                callback(currentValue) 
            end
        end
    end)
    
    return {
        SetValue = function(value)
            local rel = math.clamp((value - min) / (max - min), 0, 1)
            sliderFill.Size = UDim2.new(rel, 0, 1, 0)
            currentValue = value
            label.Text = text .. ": " .. currentValue
        end,
        GetValue = function()
            return currentValue
        end
    }
end

-- Create a dropdown
function LuaUIX:CreateDropdown(parent, text, options, callback, defaultValue)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = frame
    })
    
    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text .. (defaultValue and (": " .. defaultValue) or " ▼"),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = frame
    })
    
    local listFrame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, #options * 28),
        BackgroundColor3 = Color3.fromRGB(30, 32, 44),
        Visible = false,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = listFrame
    })
    
    local layout = createInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listFrame
    })
    
    local currentOption = defaultValue
    
    for _, opt in ipairs(options) do
        local optBtn = createInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = opt,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = colors.textSecondary,
            Parent = listFrame
        })
        
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. opt
            listFrame.Visible = false
            currentOption = opt
            if callback then 
                callback(opt) 
            end
        end)
    end
    
    btn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)
    
    return {
        SetOption = function(option)
            if table.find(options, option) then
                btn.Text = text .. ": " .. option
                currentOption = option
            end
        end,
        GetOption = function()
            return currentOption
        end
    }
end

-- Create a label
function LuaUIX:CreateLabel(parent, text, textSize, color)
    local label = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = textSize or 14,
        TextColor3 = color or colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    
    return label
end

-- Create a textbox
function LuaUIX:CreateTextBox(parent, text, callback, placeholder)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = frame
    })
    
    local textBox = createInstance("TextBox", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = text or "",
        PlaceholderText = placeholder or "",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = frame
    })
    
    textBox.FocusLost:Connect(function()
        if callback then 
            callback(textBox.Text) 
        end
    end)
    
    return textBox
end

-- Create a keybind
function LuaUIX:CreateKeybind(parent, text, defaultKey, callback)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = frame
    })
    
    local label = createInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local keyLabel = createInstance("TextButton", {
        Size = UDim2.new(0.4, -5, 1, -5),
        Position = UDim2.new(0.6, 0, 0, 2.5),
        BackgroundColor3 = colors.accent,
        Text = defaultKey and defaultKey.Name or "NONE",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = frame
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = keyLabel
    })
    
    local listening = false
    local currentKey = defaultKey
    
    keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
        keyLabel.BackgroundColor3 = colors.warning
    end)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if listening then
            listening = false
            currentKey = input.KeyCode
            keyLabel.Text = currentKey.Name
            keyLabel.BackgroundColor3 = colors.accent
        end
    end)
    
    if defaultKey and callback then
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == currentKey then
                callback()
            end
        end)
    end
    
    return {
        SetKey = function(key)
            currentKey = key
            keyLabel.Text = key.Name
        end,
        GetKey = function()
            return currentKey
        end
    }
end

-- Create a color picker
function LuaUIX:CreateColorPicker(parent, text, defaultColor, callback)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = frame
    })
    
    local label = createInstance("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local colorBox = createInstance("TextButton", {
        Size = UDim2.new(0.4, -5, 1, -5),
        Position = UDim2.new(0.6, 0, 0, 2.5),
        BackgroundColor3 = defaultColor or colors.accent,
        Text = "",
        AutoButtonColor = false,
        Parent = frame
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = colorBox
    })
    
    local currentColor = defaultColor or colors.accent
    
    colorBox.MouseButton1Click:Connect(function()
        -- This would open a color picker dialog
        -- For simplicity, we'll just cycle through some colors
        local colors = {colors.accent, colors.button, colors.success, colors.warning, colors.error}
        local nextColor = colors[(table.find(colors, currentColor) or 0) % #colors + 1]
        currentColor = nextColor
        colorBox.BackgroundColor3 = currentColor
        if callback then
            callback(currentColor)
        end
    end)
    
    return {
        SetColor = function(color)
            currentColor = color
            colorBox.BackgroundColor3 = color
        end,
        GetColor = function()
            return currentColor
        end
    }
end

-- Notification System
function LuaUIX:Notify(title, message, duration, notifType)
    duration = duration or 5
    notifType = notifType or "info"
    
    local notification = createInstance("Frame", {
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(1, -320, 1, -100),
        BackgroundColor3 = colors.section,
        Parent = self.gui
    })
    
    createInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = notification})
    
    local accentColor
    if notifType == "success" then
        accentColor = colors.success
    elseif notifType == "warning" then
        accentColor = colors.warning
    elseif notifType == "error" then
        accentColor = colors.error
    else
        accentColor = colors.accent
    end
    
    local accentBar = createInstance("Frame", {
        Size = UDim2.new(0, 5, 1, 0),
        BackgroundColor3 = accentColor,
        Parent = notification
    })
    
    local titleLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    local messageLabel = createInstance("TextLabel", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 15, 0, 35),
        BackgroundTransparency = 1,
        Text = message,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notification
    })
    
    -- Animate in
    notification.Position = UDim2.new(1, -320, 1, 100)
    local tween = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 1, -100)}
    )
    tween:Play()
    
    -- Auto-remove after duration
    delay(duration, function()
        local tweenOut = TweenService:Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(1, -320, 1, 100)}
        )
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            notification:Destroy()
        end)
    end)
    
    return notification
end

-- Config System
function LuaUIX:SaveConfig(name)
    local config = {
        windowPosition = {self.window.Position.X.Scale, self.window.Position.X.Offset, 
                         self.window.Position.Y.Scale, self.window.Position.Y.Offset},
        settings = {}
    }
    
    -- You would iterate through all UI elements and save their states
    -- This is a simplified example
    
    if writefile then
        writefile("LuaUIX_" .. name .. ".json", game:GetService("HttpService"):JSONEncode(config))
        self:Notify("Config Saved", "Configuration '" .. name .. "' has been saved.", 3, "success")
    else
        self:Notify("Error", "Config system requires writefile capability.", 3, "error")
    end
end

function LuaUIX:LoadConfig(name)
    if readfile then
        local success, config = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile("LuaUIX_" .. name .. ".json"))
        end)
        
        if success and config then
            -- Apply config settings
            if config.windowPosition then
                self.window.Position = UDim2.new(
                    config.windowPosition[1], config.windowPosition[2],
                    config.windowPosition[3], config.windowPosition[4]
                )
            end
            
            self:Notify("Config Loaded", "Configuration '" .. name .. "' has been loaded.", 3, "success")
            return true
        else
            self:Notify("Error", "Failed to load config '" .. name .. "'.", 3, "error")
            return false
        end
    else
        self:Notify("Error", "Config system requires readfile capability.", 3, "error")
        return false
    end
end

-- Watermark
function LuaUIX:CreateWatermark(text)
    local watermark = createInstance("Frame", {
        Size = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = colors.section,
        Parent = self.gui
    })
    
    createInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = watermark})
    
    local label = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text or "LuaUIX v1.6",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = watermark
    })
    
    -- Make draggable
    self:draggable(watermark)
    
    -- Update FPS counter
    local fpsLabel = label
    local fps = 0
    local lastTime = tick()
    local frameCount = 0
    
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        if currentTime - lastTime >= 1 then
            fps = math.floor(frameCount / (currentTime - lastTime))
            frameCount = 0
            lastTime = currentTime
            fpsLabel.Text = text .. " | FPS: " .. fps
        end
    end)
    
    return watermark
end

-- Animation System
function LuaUIX:AnimateElement(element, property, targetValue, duration, easingStyle, easingDirection)
    duration = duration or 0.2
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    
    local tween = TweenService:Create(
        element,
        TweenInfo.new(duration, easingStyle, easingDirection),
        {[property] = targetValue}
    )
    tween:Play()
    return tween
end

-- Theme System
function LuaUIX:SetTheme(themeName)
    local themes = {
        dark = {
            background = Color3.fromRGB(33, 34, 44),
            titlebar = Color3.fromRGB(46, 46, 66),
            sidebar = Color3.fromRGB(27, 28, 37),
            content = Color3.fromRGB(40, 42, 54),
            section = Color3.fromRGB(23, 25, 34),
            accent = Color3.fromRGB(56, 172, 212),
            button = Color3.fromRGB(90, 120, 255),
            toggleOff = Color3.fromRGB(42, 46, 59),
            text = Color3.fromRGB(255, 255, 255),
            textSecondary = Color3.fromRGB(200, 200, 200)
        },
        light = {
            background = Color3.fromRGB(240, 240, 240),
            titlebar = Color3.fromRGB(220, 220, 220),
            sidebar = Color3.fromRGB(200, 200, 200),
            content = Color3.fromRGB(250, 250, 250),
            section = Color3.fromRGB(230, 230, 230),
            accent = Color3.fromRGB(0, 120, 215),
            button = Color3.fromRGB(0, 120, 215),
            toggleOff = Color3.fromRGB(180, 180, 180),
            text = Color3.fromRGB(0, 0, 0),
            textSecondary = Color3.fromRGB(80, 80, 80)
        },
        blue = {
            background = Color3.fromRGB(23, 33, 49),
            titlebar = Color3.fromRGB(33, 53, 79),
            sidebar = Color3.fromRGB(18, 28, 43),
            content = Color3.fromRGB(28, 43, 64),
            section = Color3.fromRGB(18, 33, 54),
            accent = Color3.fromRGB(0, 162, 255),
            button = Color3.fromRGB(0, 162, 255),
            toggleOff = Color3.fromRGB(38, 48, 69),
            text = Color3.fromRGB(255, 255, 255),
            textSecondary = Color3.fromRGB(200, 200, 220)
        }
    }
    
    local theme = themes[themeName] or themes.dark
    colors = theme
    
    -- Apply theme to all UI elements
    self.window.BackgroundColor3 = theme.background
    self.titlebar.BackgroundColor3 = theme.titlebar
    self.sidebar.BackgroundColor3 = theme.sidebar
    self.content.BackgroundColor3 = theme.content
    
    -- You would need to iterate through all elements and update their colors
    -- This is a simplified example
    
    return true
end

-- Toggle UI visibility
function LuaUIX:ToggleVisibility()
    self.gui.Enabled = not self.gui.Enabled
end

-- Destroy UI
function LuaUIX:Destroy()
    self.gui:Destroy()
end

return LuaUIX
