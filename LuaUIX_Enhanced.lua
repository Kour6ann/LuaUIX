-- LuaUIX Library v1.2 - Complete Fix
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
        if property ~= "Parent" then
            pcall(function()
                instance[property] = value
            end)
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
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
    
    -- Create tab container with UIListLayout
    self.tabContainer = Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.sidebar
    })
    
    Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.tabContainer
    })
    
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = self.tabContainer
    })
    
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
    self.tweens = {}
    self.configCallbacks = {}
    
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
    table.insert(self.tweens, tween)
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
    
    local connection = UserInputService.InputChanged:Connect(function(input)
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
    
    table.insert(self.connections, connection)
end

-- Setup UI toggle keybind
function LuaUIX:setupToggleKeybind()
    local toggleKey = Enum.KeyCode.RightShift
    
    local connection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey and not UserInputService:GetFocusedTextBox() then
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
    local tabButton = Create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = colors.toggleOff,
        Text = icon and (icon .. "  " .. name) or name,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        LayoutOrder = #self.tabButtons + 1,
        Parent = self.tabContainer
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
    if not self.currentPage then
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
    local connections = {}
    
    local clickConnection = btn.MouseButton1Click:Connect(function()
        state = not state
        self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        
        pcall(function()
            if callback then
                callback(state)
            end
        end)
    end)
    
    table.insert(connections, clickConnection)
    
    -- Add to config system
    local elementId = "toggle_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        Get = function()
            return state
        end,
        Set = function(value)
            state = value
            self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            btn:Destroy()
        end
    }
    
    return self.elements[elementId]
end

-- Create a slider
function LuaUIX:CreateSlider(parent, text, minValue, maxValue, callback, defaultValue, precision)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text .. ": " .. (defaultValue or minValue),
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
        Size = UDim2.new(defaultValue and ((defaultValue - minValue) / (maxValue - minValue)) or 0, 0, 1, 0),
        BackgroundColor3 = colors.accent,
        BorderSizePixel = 0,
        Parent = sliderBack
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = sliderFill})
    
    local dragging = false
    local currentValue = defaultValue or minValue
    local precision = precision or 0
    local connections = {}
    
    local function updateSlider(value)
        local rel = math.clamp((value - minValue) / (maxValue - minValue), 0, 1)
        self:Tween(sliderFill, {Size = UDim2.new(rel, 0, 1, 0)})
        
        if precision > 0 then
            currentValue = math.floor((minValue + (maxValue - minValue) * rel) * 10^precision) / 10^precision
        else
            currentValue = math.floor(minValue + (maxValue - minValue) * rel)
        end
        
        label.Text = text .. ": " .. currentValue
        
        pcall(function()
            if callback then
                callback(currentValue)
            end
        end)
    end
    
    local beginConnection = sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local mousePos = UserInputService:GetMouseLocation()
            local rel = math.clamp((mousePos.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
            updateSlider(minValue + (maxValue - minValue) * rel)
        end
    end)
    table.insert(connections, beginConnection)
    
    local endConnection = sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(connections, endConnection)
    
    local changedConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
            updateSlider(minValue + (maxValue - minValue) * rel)
        end
    end)
    table.insert(connections, changedConnection)
    
    -- Add to config system
    local elementId = "slider_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetValue = function(value)
            updateSlider(value)
        end,
        GetValue = function()
            return currentValue
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            frame:Destroy()
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
    
    -- Add consistent padding to dropdown buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = btn
    })
    
    local listFrame = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(30, 32, 44),
        Visible = false,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = colors.accent,
        Parent = parent
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = listFrame})
    
    local listLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listFrame
    })
    
    local currentOption = defaultValue
    local connections = {}
    
    -- Create options
    for _, opt in ipairs(options) do
        local optBtn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = opt,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            LayoutOrder = _,
            Parent = listFrame
        })
        
        -- Add consistent padding to dropdown options
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = optBtn
        })
        
        local optionConnection = optBtn.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. opt
            currentOption = opt
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            
            pcall(function()
                if callback then
                    callback(opt)
                end
            end)
        end)
        table.insert(connections, optionConnection)
    end
    
    -- Update list frame size based on content
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
    
    local buttonConnection = btn.MouseButton1Click:Connect(function()
        if listFrame.Visible then
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
        else
            listFrame.Visible = true
            -- Show max 5 options at a time with scrolling
            local maxHeight = math.min(#options * 28, 140)
            listFrame.Size = UDim2.new(1, 0, 0, maxHeight)
        end
    end)
    table.insert(connections, buttonConnection)
    
    -- Close dropdown when clicking outside
    local function closeDropdown(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and listFrame.Visible then
            local mousePos = input.Position
            local framePos = frame.AbsolutePosition
            local frameSize = frame.AbsoluteSize
            local listPos = listFrame.AbsolutePosition
            local listSize = listFrame.AbsoluteSize
            
            -- Check if mouse is outside both frame and listFrame
            if not (
                (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                 mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) or
                (mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and
                 mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y)
            ) then
                listFrame.Visible = false
                listFrame.Size = UDim2.new(1, 0, 0, 0)
            end
        end
    end
    
    local inputConnection = UserInputService.InputBegan:Connect(closeDropdown)
    table.insert(connections, inputConnection)
    
    -- Add to config system
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
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            frame:Destroy()
            listFrame:Destroy()
        end
    }
    
    return self.elements[elementId]
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
    
    local connections = {}
    
    local focusConnection = textBox.Focused:Connect(function()
        self:SetFocusedElement(textBox)
        self:Tween(frame, {BackgroundColor3 = Color3.fromRGB(
            math.floor(colors.toggleOff.R * 255 * 1.2),
            math.floor(colors.toggleOff.G * 255 * 1.2),
            math.floor(colors.toggleOff.B * 255 * 1.2)
        )})
    end)
    table.insert(connections, focusConnection)
    
    local unfocusConnection = textBox.FocusLost:Connect(function(enterPressed)
        self:SetFocusedElement(nil)
        self:Tween(frame, {BackgroundColor3 = colors.toggleOff})
        
        pcall(function()
            if enterPressed and callback then
                callback(textBox.Text)
            end
        end)
    end)
    table.insert(connections, unfocusConnection)
    
    -- Add to config system
    local elementId = "textbox_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetText = function(newText)
            textBox.Text = newText
        end,
        GetText = function()
            return textBox.Text
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            frame:Destroy()
        end
    }
    
    return self.elements[elementId]
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
    local connections = {}
    
    keyLabel.MouseButton1Click:Connect(function()
        listening = true
        keyLabel.Text = "..."
        keyLabel.BackgroundColor3 = colors.warning
    end)
    
    local inputConnection = UserInputService.InputBegan:Connect(function(input)
        if listening and not UserInputService:GetFocusedTextBox() then
            listening = false
            currentKey = input.KeyCode
            keyLabel.Text = currentKey.Name
            keyLabel.BackgroundColor3 = colors.accent
        end
    end)
    table.insert(connections, inputConnection)
    
    if defaultKey and callback then
        local keyConnection = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == currentKey and not UserInputService:GetFocusedTextBox() then
                pcall(function()
                    callback()
                end)
            end
        end)
        table.insert(connections, keyConnection)
    end
    
    -- Add to config system
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
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            frame:Destroy()
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
    local connections = {}
    
    colorBox.MouseButton1Click:Connect(function()
        -- Create color picker dialog
        self:CreateColorPickerDialog(currentColor, function(newColor)
            currentColor = newColor
            colorBox.BackgroundColor3 = currentColor
            
            pcall(function()
                if callback then
                    callback(currentColor)
                end
            end)
        end)
    end)
    
    -- Add to config system
    local elementId = "colorpicker_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetColor = function(color)
            currentColor = color
            colorBox.BackgroundColor3 = color
        end,
        GetColor = function()
            return currentColor
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            frame:Destroy()
        end
    }
    
    return self.elements[elementId]
end

-- Create color picker dialog
function LuaUIX:CreateColorPickerDialog(defaultColor, callback)
    local dialog = Create("Frame", {
        Name = "ColorPickerDialog",
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100),
        BackgroundColor3 = colors.section,
        Parent = self.gui
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialog})
    
    -- Add padding to dialog
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = dialog
    })
    
    -- Simple color selection buttons
    local presetColors = {
        Color3.fromRGB(255, 0, 0),    -- Red
        Color3.fromRGB(0, 255, 0),    -- Green
        Color3.fromRGB(0, 0, 255),    -- Blue
        Color3.fromRGB(255, 255, 0),  -- Yellow
        Color3.fromRGB(255, 0, 255),  -- Magenta
        Color3.fromRGB(0, 255, 255),  -- Cyan
        Color3.fromRGB(255, 165, 0),  -- Orange
        Color3.fromRGB(128, 0, 128)   -- Purple
    }
    
    for i, color in ipairs(presetColors) do
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
            
            pcall(function()
                if callback then
                    callback(color)
                end
            end)
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
    
    -- Add consistent padding to dialog buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = closeButton
    })
    
    closeButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    return dialog
end

-- Make UI responsive to screen size
function LuaUIX:MakeResponsive()
    local function updateSize()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local scale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080) * 0.9
        
        self.window.Size = UDim2.new(0, 650 * scale, 0, 500 * scale)
        self.window.Position = UDim2.new(0.5, -325 * scale, 0.5, -250 * scale)
    end
    
    local connection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
    table.insert(self.connections, connection)
    
    updateSize()
end

-- Focus management
function LuaUIX:SetFocusedElement(element)
    self.focusedElement = element
end

function LuaUIX:GetFocusedElement()
    return self.focusedElement
end

-- Toggle UI visibility
function LuaUIX:ToggleVisibility()
    self.gui.Enabled = not self.gui.Enabled
end

-- Config system implementation
function LuaUIX:SaveConfig(name)
    if not name or type(name) ~= "string" then
        error("Config name must be a string")
    end
    
    local configData = {}
    
    for id, element in pairs(self.elements) do
        local value = element.Get and element:Get()
        
        -- Handle Color3 values
        if typeof(value) == "Color3" then
            value = {value.R, value.G, value.B}
        -- Handle EnumItem values
        elseif typeof(value) == "EnumItem" then
            value = {Enum = tostring(value.EnumType), Value = value.Value}
        end
        
        configData[id] = value
    end
    
    local jsonData = HttpService:JSONEncode(configData)
    
    if writefile then
        writefile("LuaUIX_" .. name .. ".json", jsonData)
        return true
    end
    
    return false
end

function LuaUIX:LoadConfig(name)
    if not name or type(name) ~= "string" then
        error("Config name must be a string")
    end
    
    if readfile then
        local success, data = pcall(function()
            return readfile("LuaUIX_" .. name .. ".json")
        end)
        
        if success and data then
            local success2, configData = pcall(function()
                return HttpService:JSONDecode(data)
            end)
            
            if success2 and configData then
                for id, value in pairs(configData) do
                    if self.elements[id] and self.elements[id].Set then
                        -- Handle Color3 values
                        if type(value) == "table" and #value == 3 then
                            value = Color3.new(value[1], value[2], value[3])
                        -- Handle EnumItem values
                        elseif type(value) == "table" and value.Enum and value.Value then
                            local enumType = Enum[value.Enum]
                            if enumType then
                                value = enumType[value.Value]
                            end
                        end
                        
                        self.elements[id]:Set(value)
                    end
                end
                
                return true
            end
        end
    end
    
    return false
end

function LuaUIX:DeleteConfig(name)
    if not name or type(name) ~= "string" then
        error("Config name must be a string")
    end
    
    if delfile then
        local success = pcall(function()
            delfile("LuaUIX_" .. name .. ".json")
        end)
        
        return success
    end
    
    return false
end

-- Destroy UI
function LuaUIX:Destroy()
    -- Disconnect all connections
    for _, connection in ipairs(self.connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    -- Cancel all tweens
    for _, tween in ipairs(self.tweens) do
        tween:Cancel()
    end
    
    -- Destroy all elements
    for _, element in pairs(self.elements) do
        if element.Destroy then
            element:Destroy()
        end
    end
    
    -- Destroy GUI
    self.gui:Destroy()
end

return LuaUIX
