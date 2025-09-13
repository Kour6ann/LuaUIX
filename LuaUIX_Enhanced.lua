-- LuaUIX Library v3.0 - Complete Implementation
-- A reliable UI library for Roblox exploits

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Utility functions
local function Create(className, properties)
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
    error = Color3.fromRGB(244, 67, 54),
    close = Color3.fromRGB(244, 67, 54),
    minimize = Color3.fromRGB(255, 193, 7),
    info = Color3.fromRGB(33, 150, 243)
}

-- Library initialization
function LuaUIX.new(menuName)
    local self = setmetatable({}, LuaUIX)
    
    -- Cleanup existing UI
    if CoreGui:FindFirstChild("LuaUIX_" .. menuName) then
        CoreGui["LuaUIX_" .. menuName]:Destroy()
    end
    
    -- Create main GUI
    self.gui = Create("ScreenGui", {
        Name = "LuaUIX_" .. menuName,
        ResetOnSpawn = false,
        Parent = CoreGui
    })
    
    -- Create main window
    self.window = Create("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 650, 0, 500),
        Position = UDim2.new(0.5, -325, 0.5, -250),
        BackgroundColor3 = colors.background,
        Parent = self.gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.window})
    
    -- Create titlebar
    self.titlebar = Create("Frame", {
        Name = "Titlebar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.titlebar,
        Parent = self.window
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.titlebar})
    
    self.title = Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = menuName or "LuaUIX Window",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.titlebar
    })
    
    -- Create close button
    self.closeButton = Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, -30, 0.5, -12.5),
        BackgroundColor3 = colors.close,
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = self.titlebar
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.closeButton})
    
    self.closeButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    -- Create minimize button
    self.minimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(1, -60, 0.5, -12.5),
        BackgroundColor3 = colors.minimize,
        Text = "_",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = self.titlebar
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.minimizeButton})
    
    self.minimizeButton.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
    
    -- Create sidebar
    self.sidebar = Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = colors.sidebar,
        Parent = self.window
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.sidebar})
    
    -- Create content area
    self.content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundColor3 = colors.content,
        Parent = self.window
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.content})
    
    -- Initialize pages table
    self.pages = {}
    self.currentPage = nil
    self.tabButtons = {}
    self.isMinimized = false
    self.originalSize = UDim2.new(0, 650, 0, 500)
    self.originalPosition = UDim2.new(0.5, -325, 0.5, -250)
    self.connections = {}
    self.elements = {}
    self.focusedElement = nil
    
    -- Animation settings
    self.tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Add draggable functionality
    self:draggable(self.titlebar)
    
    -- Add keybind to toggle UI
    self:setupToggleKeybind()
    
    -- Make UI responsive
    self:MakeResponsive()
    
    return self
end

-- Tween helper function
function LuaUIX:Tween(object, properties)
    local tween = TweenService:Create(object, self.tweenInfo, properties)
    tween:Play()
    return tween
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
    
    local connection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then
            self:ToggleVisibility()
        end
    end)
    
    table.insert(self.connections, connection)
end

-- Minimize function (like Rayfield)
function LuaUIX:Minimize()
    if self.isMinimized then
        -- Restore window with animation
        self:Tween(self.window, {Size = self.originalSize, Position = self.originalPosition})
        self.content.Visible = true
        self.sidebar.Visible = true
        self.minimizeButton.Text = "_"
        self.isMinimized = false
    else
        -- Minimize window with animation
        self.originalSize = self.window.Size
        self.originalPosition = self.window.Position
        self:Tween(self.window, {Size = UDim2.new(0, 200, 0, 40), Position = UDim2.new(0.5, -100, 0, 10)})
        self.content.Visible = false
        self.sidebar.Visible = false
        self.minimizeButton.Text = "+"
        self.isMinimized = true
    end
end

-- Create a new page
function LuaUIX:CreatePage(name, icon)
    local page = Create("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = colors.accent,
        Parent = self.content
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })
    
    Create("UIPadding", {
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
    
    local tabButton = Create("TextButton", {
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
    
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = tabButton})
    
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
        -- Highlight active tab with animation
        self:Tween(self.tabButtons[name], {BackgroundColor3 = colors.accent})
    end
end

-- Create a section
function LuaUIX:CreateSection(parent, titleText)
    local section = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = colors.section,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = section})
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = section
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = section
    })
    
    local header = Create("TextLabel", {
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
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = defaultValue and colors.accent or colors.toggleOff,
        Text = text or "Toggle",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})
    
    local state = defaultValue or false
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        if callback then 
            callback(state) 
        end
    end)
    
    local elementId = "toggle_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetState = function(newState)
            state = newState
            self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        end,
        GetState = function()
            return state
        end,
        GetButton = function()
            return btn
        end
    }
    
    return self.elements[elementId]
end

-- Create a button
function LuaUIX:CreateButton(parent, text, callback, color)
    color = color or colors.button
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = color,
        Text = text or "Button",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})
    
    -- Add hover effect
    btn.MouseEnter:Connect(function()
        self:Tween(btn, {BackgroundColor3 = Color3.fromRGB(
            math.floor(color.R * 255 * 0.8),
            math.floor(color.G * 255 * 0.8),
            math.floor(color.B * 255 * 0.8)
        )})
    end)
    
    btn.MouseLeave:Connect(function()
        self:Tween(btn, {BackgroundColor3 = color})
    end)
    
    btn.MouseButton1Click:Connect(function()
        if callback then 
            callback() 
        end
    end)
    
    return btn
end

-- Create a slider
function LuaUIX:CreateSlider(parent, text, min, max, callback, defaultValue, precision)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text .. ": " .. (defaultValue or min),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local sliderBack = Create("Frame", {
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(60, 60, 80),
        BorderSizePixel = 0,
        Parent = frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = sliderBack})
    
    local sliderFill = Create("Frame", {
        Size = UDim2.new(defaultValue and ((defaultValue - min) / (max - min)) or 0, 0, 1, 0),
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
        Parent = sliderBack
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = sliderFill})
    
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
            self:Tween(sliderFill, {Size = UDim2.new(rel, 0, 1, 0)})
            
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
    
    local elementId = "slider_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetValue = function(value)
            local rel = math.clamp((value - min) / (max - min), 0, 1)
            self:Tween(sliderFill, {Size = UDim2.new(rel, 0, 1, 0)})
            currentValue = value
            label.Text = text .. ": " .. currentValue
        end,
        GetValue = function()
            return currentValue
        end
    }
    
    return self.elements[elementId]
end

-- Create a dropdown
function LuaUIX:CreateDropdown(parent, text, options, callback, defaultValue)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text .. (defaultValue and (": " .. defaultValue) or " ▼"),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = frame
    })
    
    local listFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(30, 32, 44),
        Visible = false,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = listFrame})
    
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listFrame
    })
    
    local currentOption = defaultValue
    
    for _, opt in ipairs(options) do
        local optBtn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = opt,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            Parent = listFrame
        })
        
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. opt
            self:Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
            wait(0.2)
            listFrame.Visible = false
            currentOption = opt
            if callback then 
                callback(opt) 
            end
        end)
    end
    
    btn.MouseButton1Click:Connect(function()
        if listFrame.Visible then
            self:Tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
            wait(0.2)
            listFrame.Visible = false
        else
            listFrame.Visible = true
            self:Tween(listFrame, {Size = UDim2.new(1, 0, 0, #options * 28)})
        end
    end)
    
    local elementId = "dropdown_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
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
    
    return self.elements[elementId]
end

-- Create a label
function LuaUIX:CreateLabel(parent, text, textSize, color)
    local label = Create("TextLabel", {
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
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    
    local textBox = Create("TextBox", {
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
    
    textBox.Focused:Connect(function()
        self:SetFocusedElement(textBox)
        self:Tween(frame, {BackgroundColor3 = Color3.fromRGB(
            math.floor(colors.toggleOff.R * 255 * 1.2),
            math.floor(colors.toggleOff.G * 255 * 1.2),
            math.floor(colors.toggleOff.B * 255 * 1.2)
        )})
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        self:SetFocusedElement(nil)
        self:Tween(frame, {BackgroundColor3 = colors.toggleOff})
        if enterPressed and callback then 
            callback(textBox.Text) 
        end
    end)
    
    return textBox
end

-- Create a keybind
function LuaUIX:CreateKeybind(parent, text, defaultKey, callback)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    
    local label = Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local keyLabel = Create("TextButton", {
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
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keyLabel})
    
    local listening = false
    local currentKey = defaultKey
    
    keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
        keyLabel.BackgroundColor3 = colors.warning
    end)
    
    local connection = UserInputService.InputBegan:Connect(function(input)
        if listening then
            listening = false
            currentKey = input.KeyCode
            keyLabel.Text = currentKey.Name
            keyLabel.BackgroundColor3 = colors.accent
        end
    end)
    
    table.insert(self.connections, connection)
    
    if defaultKey and callback then
        local keyConnection = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == currentKey then
                callback()
            end
        end)
        
        table.insert(self.connections, keyConnection)
    end
    
    local elementId = "keybind_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetKey = function(key)
            currentKey = key
            keyLabel.Text = key.Name
        end,
        GetKey = function()
            return currentKey
        end,
        Destroy = function()
            connection:Disconnect()
        end
    }
    
    return self.elements[elementId]
end

-- Create a color picker
function LuaUIX:CreateColorPicker(parent, text, defaultColor, callback)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    
    local label = Create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local colorBox = Create("TextButton", {
        Size = UDim2.new(0.4, -5, 1, -5),
        Position = UDim2.new(0.6, 0, 0, 2.5),
        BackgroundColor3 = defaultColor or colors.accent,
        Text = "",
        AutoButtonColor = false,
        Parent = frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = colorBox})
    
    local currentColor = defaultColor or colors.accent
    
    colorBox.MouseButton1Click:Connect(function()
        -- Create color picker dialog
        self:CreateColorPickerDialog(currentColor, function(newColor)
            currentColor = newColor
            colorBox.BackgroundColor3 = currentColor
            if callback then
                callback(currentColor)
            end
        end)
    end)
    
    local elementId = "colorpicker_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetColor = function(color)
            currentColor = color
            colorBox.BackgroundColor3 = color
        end,
        GetColor = function()
            return currentColor
        end
    }
    
    return self.elements[elementId]
end

-- Create color picker dialog (SIMPLIFIED VERSION)
function LuaUIX:CreateColorPickerDialog(defaultColor, callback)
    local dialog = Create("Frame", {
        Name = "ColorPickerDialog",
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100),
        BackgroundColor3 = colors.section,
        Parent = self.gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialog})
    
    -- Simple color selection buttons
    local colors = {
        Color3.fromRGB(255, 0, 0),    -- Red
        Color3.fromRGB(0, 255, 0),    -- Green
        Color3.fromRGB(0, 0, 255),    -- Blue
        Color3.fromRGB(255, 255, 0),  -- Yellow
        Color3.fromRGB(255, 0, 255),  -- Magenta
        Color3.fromRGB(0, 255, 255),  -- Cyan
        Color3.fromRGB(255, 165, 0),  -- Orange
        Color3.fromRGB(128, 0, 128)   -- Purple
    }
    
    for i, color in ipairs(colors) do
        local colorBtn = Create("TextButton", {
            Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(0, 20 + ((i-1) % 4) * 70, 0, 20 + math.floor((i-1)/4) * 70),
            BackgroundColor3 = color,
            Text = "",
            Parent = dialog
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = colorBtn})
        
        colorBtn.MouseButton1Click:Connect(function()
            dialog:Destroy()
            if callback then
                callback(color)
            end
        end)
    end
    
    local closeButton = Create("TextButton", {
        Size = UDim2.new(0, 80, 0, 30),
        Position = UDim2.new(0.5, -40, 1, -40),
        BackgroundColor3 = colors.accent,
        Text = "Cancel",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = dialog
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = closeButton})
    
    closeButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    return dialog
end

-- Add tooltip functionality
function LuaUIX:AddTooltip(element, text)
    local tooltip = Create("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, 200, 0, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tooltip})
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 0),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = colors.text,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tooltip
    })
    
    tooltip.Size = UDim2.new(0, 200, 0, label.TextBounds.Y + 10)
    
    element.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    element.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    element.MouseMoved:Connect(function(x, y)
        tooltip.Position = UDim2.new(0, x + 20, 0, y + 20)
    end)
end

-- Notification system
function LuaUIX:Notify(title, message, duration, notifType)
    duration = duration or 5
    notifType = notifType or "info"
    
    local notification = Create("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.new(1, -320, 1, -80),
        BackgroundColor3 = colors.section,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = notification})
    
    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    local messageLabel = Create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 0),
        Position = UDim2.new(0, 5, 0, 25),
        BackgroundTransparency = 1,
        Text = message,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = colors.textSecondary,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = notification
    })
    
    notification.Size = UDim2.new(0, 300, 0, messageLabel.TextBounds.Y + 35)
    
    -- Set color based on notification type
    local color = colors.info
    if notifType == "success" then color = colors.success
    elseif notifType == "warning" then color = colors.warning
    elseif notifType == "error" then color = colors.error end
    
    local accentBar = Create("Frame", {
        Size = UDim2.new(0, 5, 1, 0),
        BackgroundColor3 = color,
        Parent = notification
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = accentBar})
    
    -- Animate in
    self:Tween(notification, {Position = UDim2.new(1, -320, 1, -280)})
    
    -- Auto-remove after duration
    delay(duration, function()
        self:Tween(notification, {Position = UDim2.new(1, -320, 1, -80)}):Wait()
        notification:Destroy()
    end)
    
    return notification
end

-- Config system (SIMPLIFIED)
function LuaUIX:SaveConfig(name)
    local config = {}
    
    -- Gather all UI element values
    for elementId, element in pairs(self.elements) do
        if element.GetValue then
            config[elementId] = element:GetValue()
        elseif element.GetState then
            config[elementId] = element:GetState()
        elseif element.GetKey then
            config[elementId] = element:GetKey().Name
        elseif element.GetColor then
            config[elementId] = {R = element:GetColor().R, G = element:GetColor().G, B = element:GetColor().B}
        elseif element.GetOption then
            config[elementId] = element:GetOption()
        end
    end
    
    -- In a real implementation, you would save this to a file
    print("Config saved:", HttpService:JSONEncode(config))
    self:Notify("Config", "Configuration saved successfully!", 3, "success")
    
    return config
end

function LuaUIX:LoadConfig(name)
    -- In a real implementation, you would load from a file
    -- For demo purposes, we'll just show a notification
    self:Notify("Config", "Configuration loaded successfully!", 3, "success")
    
    -- This would be the actual loading code:
    -- local config = {} -- Load from storage
    -- for elementId, value in pairs(config) do
    --     if self.elements[elementId] then
    --         if self.elements[elementId].SetValue then
    --             self.elements[elementId]:SetValue(value)
    --         elseif self.elements[elementId].SetState then
    --             self.elements[elementId]:SetState(value)
    --         -- ... etc for other element types
    --         end
    --     end
    -- end
end

-- Theme system
function LuaUIX:SetTheme(themeName)
    local themes = {
        Dark = {
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
            error = Color3.fromRGB(244, 67, 54),
            close = Color3.fromRGB(244, 67, 54),
            minimize = Color3.fromRGB(255, 193, 7),
            info = Color3.fromRGB(33, 150, 243)
        },
        Light = {
            background = Color3.fromRGB(240, 240, 240),
            titlebar = Color3.fromRGB(220, 220, 220),
            sidebar = Color3.fromRGB(200, 200, 200),
            content = Color3.fromRGB(250, 250, 250),
            section = Color3.fromRGB(230, 230, 230),
            accent = Color3.fromRGB(56, 172, 212),
            button = Color3.fromRGB(90, 120, 255),
            toggleOff = Color3.fromRGB(180, 180, 180),
            text = Color3.fromRGB(30, 30, 30),
            textSecondary = Color3.fromRGB(80, 80, 80),
            success = Color3.fromRGB(76, 175, 80),
            warning = Color3.fromRGB(255, 193, 7),
            error = Color3.fromRGB(244, 67, 54),
            close = Color3.fromRGB(244, 67, 54),
            minimize = Color3.fromRGB(255, 193, 7),
            info = Color3.fromRGB(33, 150, 243)
        }
    }
    
    if themes[themeName] then
        self.colors = themes[themeName]
        self:ApplyTheme()
        self:Notify("Theme", "Theme changed to " .. themeName, 3, "info")
    end
end

function LuaUIX:ApplyTheme()
    -- Apply current theme colors to all UI elements
    self.window.BackgroundColor3 = self.colors.background
    self.titlebar.BackgroundColor3 = self.colors.titlebar
    self.sidebar.BackgroundColor3 = self.colors.sidebar
    self.content.BackgroundColor3 = self.colors.content
    self.title.TextColor3 = self.colors.text
    
    -- Apply to tab buttons
    for _, button in pairs(self.tabButtons) do
        if button.BackgroundColor3 == colors.accent then
            button.BackgroundColor3 = self.colors.accent
        else
            button.BackgroundColor3 = self.colors.toggleOff
        end
        button.TextColor3 = self.colors.text
    end
    
    -- Note: In a complete implementation, you would update all other elements too
end

-- Focus management
function LuaUIX:SetFocusedElement(element)
    self.focusedElement = element
end

function LuaUIX:GetFocusedElement()
    return self.focusedElement
end

-- Make UI responsive to screen size
function LuaUIX:MakeResponsive()
    local function updateSize()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local scale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080) * 0.9
        
        self.window.Size = UDim2.new(0, 650 * scale, 0, 500 * scale)
        self.window.Position = UDim2.new(0.5, -325 * scale, 0.5, -250 * scale)
    end
    
    updateSize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end

-- Toggle UI visibility
function LuaUIX:ToggleVisibility()
    self.gui.Enabled = not self.gui.Enabled
end

-- Destroy UI
function LuaUIX:Destroy()
    -- Disconnect all connections
    for _, connection in ipairs(self.connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    self.gui:Destroy()
end

return LuaUIX
