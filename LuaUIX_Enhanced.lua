-- LuaUIX Library v1.1 - Fixed Implementation
-- A reliable UI library for Roblox exploits

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Safe instance creation function with proper Parent handling
local function Create(className, properties)
    local success, instance = pcall(function()
        local inst = Instance.new(className)
        
        -- Handle Parent property separately (it must be set last)
        local parentValue = properties.Parent
        properties.Parent = nil -- Remove from properties to handle separately
        
        -- Set all other properties
        for property, value in pairs(properties) do
            if inst[property] ~= nil then
                inst[property] = value
            else
                warn("[LuaUIX] Property '" .. property .. "' does not exist for " .. className)
            end
        end
        
        -- Set Parent last
        if parentValue then
            inst.Parent = parentValue
        end
        
        return inst
    end)
    
    if not success then
        warn("[LuaUIX] Failed to create " .. className .. ": " .. tostring(instance))
        return nil
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
    
    if not self.gui then
        error("[LuaUIX] Failed to create ScreenGui")
        return nil
    end
    
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
    
    -- Add padding to title
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        Parent = self.title
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
    self.elementConnections = {} -- New: Track connections per element for cleanup
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
    
    local function update(input)
        if input and dragStart and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.window.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end
    
    local beganConnection = frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = self.window.Position
            
            local changedConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                    changedConnection:Disconnect()
                end
            end)
        end
    end)
    
    local changedConnection = frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragStart then
            update(input)
        end
    end)
    
    table.insert(self.connections, beganConnection)
    table.insert(self.connections, changedConnection)
    table.insert(self.connections, inputChangedConnection)
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
    
    -- Add consistent padding to tab buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
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
    
    -- Add consistent padding to section headers
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = header
    })
    
    return section
end

-- Create a toggle
function LuaUIX:CreateToggle(parent, text, callback, defaultValue)
    local elementId = "toggle_" .. HttpService:GenerateGUID(false)
    local elementConnections = {}
    
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
    
    -- Add consistent padding to toggle buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = btn
    })
    
    local state = defaultValue or false
    
    table.insert(elementConnections, btn.MouseButton1Click:Connect(function()
        state = not state
        self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        if callback then 
            callback(state) 
        end
    end))
    
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
        end,
        Destroy = function()
            for _, conn in ipairs(elementConnections) do
                conn:Disconnect()
            end
            btn:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    self.elementConnections[elementId] = elementConnections
    
    return self.elements[elementId]
end

-- Create a button
function LuaUIX:CreateButton(parent, text, callback, color)
    local elementId = "button_" .. HttpService:GenerateGUID(false)
    local elementConnections = {}
    
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
    
    -- Add consistent padding to buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = btn
    })
    
    -- Add hover effect
    table.insert(elementConnections, btn.MouseEnter:Connect(function()
        self:Tween(btn, {BackgroundColor3 = Color3.fromRGB(
            math.floor(color.R * 255 * 0.8),
            math.floor(color.G * 255 * 0.8),
            math.floor(color.B * 255 * 0.8)
        )})
    end))
    
    table.insert(elementConnections, btn.MouseLeave:Connect(function()
        self:Tween(btn, {BackgroundColor3 = color})
    end))
    
    table.insert(elementConnections, btn.MouseButton1Click:Connect(function()
        if callback then 
            callback() 
        end
    end))
    
    self.elements[elementId] = {
        GetButton = function()
            return btn
        end,
        SetText = function(newText)
            btn.Text = newText
        end,
        SetColor = function(newColor)
            color = newColor
            btn.BackgroundColor3 = newColor
        end,
        Destroy = function()
            for _, conn in ipairs(elementConnections) do
                conn:Disconnect()
            end
            btn:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    self.elementConnections[elementId] = elementConnections
    
    return self.elements[elementId]
end

-- Create a slider
function LuaUIX:CreateSlider(parent, text, min, max, callback, defaultValue, precision)
    local elementId = "slider_" .. HttpService:GenerateGUID(false)
    local elementConnections = {}
    
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
    
    -- Add consistent padding to slider labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = label
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
    
    table.insert(elementConnections, sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end))
    
    table.insert(elementConnections, sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    
    local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
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
    
    table.insert(self.connections, inputChangedConnection)
    table.insert(elementConnections, inputChangedConnection)
    
    self.elements[elementId] = {
        SetValue = function(value)
            local rel = math.clamp((value - min) / (max - min), 0, 1)
            self:Tween(sliderFill, {Size = UDim2.new(rel, 0, 1, 0)})
            currentValue = value
            label.Text = text .. ": " .. currentValue
        end,
        GetValue = function()
            return currentValue
        end,
        Destroy = function()
            for _, conn in ipairs(elementConnections) do
                if conn.Connected then
                    conn:Disconnect()
                end
            end
            frame:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    self.elementConnections[elementId] = elementConnections
    
    return self.elements[elementId]
end

-- FIXED DROPDOWN WITH PROPER PROGRAMMATIC CONTROL
function LuaUIX:CreateDropdown(parent, text, options, callback, defaultValue)
    local elementId = "dropdown_" .. HttpService:GenerateGUID(false)
    
    local frame = Create("Frame", {
        Name = "DropdownFrame",
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
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = btn
    })
    
    -- Store state in self.elements
    self.elements[elementId] = {
        currentOption = defaultValue,
        btn = btn,  -- Store the actual TextButton, not the wrapper object
        text = text,
        options = options,
        callback = callback
    }
    
    local element = self.elements[elementId]
    
    -- Main dropdown toggle - Cycle through options on click
    btn.MouseButton1Click:Connect(function()
        local currentIndex = table.find(options, element.currentOption) or 1
        local nextIndex = (currentIndex % #options) + 1
        local newOption = options[nextIndex]
        
        element.currentOption = newOption
        element.btn.Text = element.text .. ": " .. newOption
        
        if element.callback then
            element.callback(newOption)
        end
    end)
    
    -- Return methods
    return {
        SetOption = function(option)
            if table.find(options, option) then
                print("SetOption called with:", option)
                element.currentOption = option
                element.btn.Text = element.text .. ": " .. option  -- Directly set Text property
                
                if element.callback then
                    element.callback(option)
                end
            end
        end,
        
        GetOption = function()
            return element.currentOption
        end,
        
        Destroy = function()
            frame:Destroy()
            self.elements[elementId] = nil
        end
    }
end
-- Create a label
function LuaUIX:CreateLabel(parent, text, textSize, color)
    local elementId = "label_" .. HttpService:GenerateGUID(false)
    
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
    
    -- Add consistent padding to labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = label
    })
    
    self.elements[elementId] = {
        SetText = function(newText)
            label.Text = newText
        end,
        GetText = function()
            return label.Text
        end,
        Destroy = function()
            label:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    return self.elements[elementId]
end

-- Create a textbox
function LuaUIX:CreateTextBox(parent, text, callback, placeholder)
    local elementId = "textbox_" .. HttpService:GenerateGUID(false)
    local elementConnections = {}
    
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    
    local textBox = Create("TextBox", {
        Size = UDim2.new(1, -20, 1, -10),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = text or "",
        PlaceholderText = placeholder or "",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = frame
    })
    
    -- Add consistent padding to textboxes
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = textBox
    })
    
    table.insert(elementConnections, textBox.Focused:Connect(function()
        self:SetFocusedElement(textBox)
        self:Tween(frame, {BackgroundColor3 = Color3.fromRGB(
            math.floor(colors.toggleOff.R * 255 * 1.2),
            math.floor(colors.toggleOff.G * 255 * 1.2),
            math.floor(colors.toggleOff.B * 255 * 1.2)
        )})
    end))
    
    table.insert(elementConnections, textBox.FocusLost:Connect(function(enterPressed)
        self:SetFocusedElement(nil)
        self:Tween(frame, {BackgroundColor3 = colors.toggleOff})
        if enterPressed and callback then 
            callback(textBox.Text) 
        end
    end))
    
    self.elements[elementId] = {
        SetText = function(newText)
            textBox.Text = newText
        end,
        GetText = function()
            return textBox.Text
        end,
        Destroy = function()
            for _, conn in ipairs(elementConnections) do
                conn:Disconnect()
            end
            frame:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    self.elementConnections[elementId] = elementConnections
    
    return self.elements[elementId]
end

-- Create a keybind
function LuaUIX:CreateKeybind(parent, text, defaultKey, callback)
    local elementId = "keybind_" .. HttpService:GenerateGUID(false)
    local elementConnections = {}
    
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
    
    -- Add consistent padding to keybind labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        Parent = label
    })
    
    local keyLabel = Create("TextButton", {
        Size = UDim2.new(0.4, -15, 1, -10),
        Position = UDim2.new(0.6, 5, 0, 5),
        BackgroundColor3 = colors.accent,
        Text = defaultKey and defaultKey.Name or "NONE",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keyLabel})
    
    -- Add consistent padding to keybind buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = keyLabel
    })
    
    local listening = false
    local currentKey = defaultKey
    
    table.insert(elementConnections, keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
        keyLabel.BackgroundColor3 = colors.warning
    end))
    
    local listenConnection = UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            currentKey = input.KeyCode
            keyLabel.Text = currentKey.Name
            keyLabel.BackgroundColor3 = colors.accent
        end
    end)
    
    table.insert(self.connections, listenConnection)
    table.insert(elementConnections, listenConnection)
    
    local keyConnection
    if defaultKey and callback then
        keyConnection = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == currentKey and input.UserInputType == Enum.UserInputType.Keyboard then
                callback()
            end
        end)
        
        table.insert(self.connections, keyConnection)
        table.insert(elementConnections, keyConnection)
    end
    
    self.elements[elementId] = {
        SetKey = function(key)
            currentKey = key
            keyLabel.Text = key.Name
        end,
        GetKey = function()
            return currentKey
        end,
        Destroy = function()
            for _, conn in ipairs(elementConnections) do
                if conn.Connected then
                    conn:Disconnect()
                end
            end
            frame:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    self.elementConnections[elementId] = elementConnections
    
    return self.elements[elementId]
end

-- Create a color picker
function LuaUIX:CreateColorPicker(parent, text, defaultColor, callback)
    local elementId = "colorpicker_" .. HttpService:GenerateGUID(false)
    local elementConnections = {}
    
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
    
    -- Add consistent padding to color picker labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        Parent = label
    })
    
    local colorBox = Create("TextButton", {
        Size = UDim2.new(0.4, -15, 1, -10),
        Position = UDim2.new(0.6, 5, 0, 5),
        BackgroundColor3 = defaultColor or colors.accent,
        Text = "",
        AutoButtonColor = false,
        Parent = frame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = colorBox})
    
    local currentColor = defaultColor or colors.accent
    
    table.insert(elementConnections, colorBox.MouseButton1Click:Connect(function()
        -- Create color picker dialog
        self:CreateColorPickerDialog(currentColor, function(newColor)
            currentColor = newColor
            colorBox.BackgroundColor3 = currentColor
            if callback then
                callback(currentColor)
            end
        end)
    end))
    
    self.elements[elementId] = {
        SetColor = function(color)
            currentColor = color
            colorBox.BackgroundColor3 = color
        end,
        GetColor = function()
            return currentColor
        end,
        Destroy = function()
            for _, conn in ipairs(elementConnections) do
                conn:Disconnect()
            end
            frame:Destroy()
            self.elements[elementId] = nil
        end
    }
    
    self.elementConnections[elementId] = elementConnections
    
    return self.elements[elementId]
end

-- FIXED Color Picker Dialog - Manual Parenting
function LuaUIX:CreateColorPickerDialog(defaultColor, callback)
    -- Create dialog frame
    local dialog = Instance.new("Frame")
    dialog.Name = "ColorPickerDialog"
    dialog.Size = UDim2.new(0, 250, 0, 200)
    dialog.Position = UDim2.new(0.5, -125, 0.5, -100)
    dialog.BackgroundColor3 = colors.section
    dialog.ZIndex = 20
    dialog.Parent = self.gui
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = UDim.new(0, 8)
    dialogCorner.Parent = dialog
    
    -- Color options
    local colorList = {
        Color3.fromRGB(255, 0, 0),    -- Red
        Color3.fromRGB(0, 255, 0),    -- Green
        Color3.fromRGB(0, 0, 255),    -- Blue
        Color3.fromRGB(255, 255, 0),  -- Yellow
        Color3.fromRGB(255, 0, 255),  -- Magenta
        Color3.fromRGB(0, 255, 255),  -- Cyan
        Color3.fromRGB(255, 165, 0),  -- Orange
        Color3.fromRGB(128, 0, 128),  -- Purple
        Color3.fromRGB(255, 255, 255),-- White
        Color3.fromRGB(0, 0, 0),      -- Black
    }
    
    -- Create color buttons manually
    for i, color in ipairs(colorList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 30, 0, 30)
        btn.Position = UDim2.new(0, 15 + ((i-1) % 5) * 45, 0, 30 + math.floor((i-1)/5) * 40)
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.ZIndex = 21
        btn.Parent = dialog
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            dialog:Destroy()
            if callback then callback(color) end
        end)
    end
    
    -- Create close button manually
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 25)
    closeBtn.Position = UDim2.new(0.5, -40, 1, -35)
    closeBtn.BackgroundColor3 = colors.accent
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = colors.text
    closeBtn.ZIndex = 21
    closeBtn.Parent = dialog
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    -- Make dialog draggable
    self:draggable(dialog)
    
    return dialog
end

-- Fixed Tooltip functionality
function LuaUIX:AddTooltip(element, text)
    local tooltip = Create("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, 200, 0, 0),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 30,
        Parent = self.gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tooltip})
    
    -- Add padding to tooltips
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 6),
        Parent = tooltip
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = colors.text,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tooltip
    })
    
    tooltip.Size = UDim2.new(0, 200, 0, label.TextBounds.Y + 12)
    
    -- Store tooltip reference for cleanup
    if not self.tooltips then
        self.tooltips = {}
    end
    self.tooltips[element] = tooltip
    
    local mouseEnterConnection = element.MouseEnter:Connect(function()
        tooltip.Visible = true
    end)
    
    local mouseLeaveConnection = element.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
    
    local mouseMovedConnection = element.MouseMoved:Connect(function(x, y)
        tooltip.Position = UDim2.new(0, x + 20, 0, y + 20)
    end)
    
    -- Store connections for cleanup
    if not self.tooltipConnections then
        self.tooltipConnections = {}
    end
    self.tooltipConnections[element] = {
        mouseEnterConnection,
        mouseLeaveConnection,
        mouseMovedConnection
    }
    
    return tooltip
end

-- Fixed Notification System
function LuaUIX:Notify(title, message, duration, notifType)
    duration = duration or 5
    notifType = notifType or "info"
    
    -- Create notification container if it doesn't exist
    if not self.notificationContainer then
        self.notificationContainer = Create("Frame", {
            Name = "NotificationContainer",
            Size = UDim2.new(0, 340, 0, 0),
            Position = UDim2.new(1, -360, 0, 20), -- Fixed position
            BackgroundTransparency = 1,
            Parent = self.gui
        })
        
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top, -- Changed to Top
            Parent = self.notificationContainer
        })
        
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 25),
            PaddingRight = UDim.new(0, 25),
            Parent = self.notificationContainer
        })
    end
    
    local notification = Create("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 320, 0, 0),
        BackgroundColor3 = colors.section,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 999999,
        Parent = self.notificationContainer
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = notification})
    
    -- PROPER PADDING
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 12),
        Parent = notification
    })
    
    -- Title
    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Message
    local messageLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 27),
        BackgroundTransparency = 1,
        Text = message,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = colors.textSecondary,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = notification
    })
    
    -- Set size based on content
    notification.Size = UDim2.new(0, 320, 0, messageLabel.TextBounds.Y + 45)
    
    -- Set color based on notification type
    local color = colors.info
    if notifType == "success" then color = colors.success
    elseif notifType == "warning" then color = colors.warning
    elseif notifType == "error" then color = colors.error end
    
    -- Accent bar
    local accentBar = Create("Frame", {
        Size = UDim2.new(0, 6, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = color,
        Parent = notification
    })
    
    Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = accentBar
    })
    
    -- Adjust text position to account for accent bar
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Size = UDim2.new(1, -10, 0, 22)
    messageLabel.Position = UDim2.new(0, 10, 0, 27)
    messageLabel.Size = UDim2.new(1, -10, 0, 0)
    
    -- Make sure notification is visible
    notification.Visible = true
    
    -- Animate in from the right
    notification.Position = UDim2.new(1, 0, 0, 0)
    self:Tween(notification, {Position = UDim2.new(0, 0, 0, 0)})
    
    -- Auto-remove after duration
    delay(duration, function()
        if notification and notification.Parent then
            -- Fade out animation
            self:Tween(notification, {
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1
            })
            
            wait(0.3)
            if notification and notification.Parent then
                notification:Destroy()
            end
        end
    end)
    
    print("Notification created:", title, "-", message) -- Debug print
    
    return notification
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

-- Destroy UI (with safe connection cleanup)
function LuaUIX:Destroy()
    -- Disconnect all connections safely
    for _, connection in ipairs(self.connections) do
        if connection and typeof(connection) == "RBXScriptConnection" and connection.Connected then
            pcall(function() connection:Disconnect() end)
        end
    end
    
    -- Destroy all elements and their connections
    for elementId, element in pairs(self.elements) do
        if element and element.Destroy then
            pcall(function() element:Destroy() end)
        end
    end
    
    if self.gui then
        self.gui:Destroy()
    end
end

return LuaUIX
