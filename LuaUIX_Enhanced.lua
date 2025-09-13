-- LuaUIX Library v1.1 - Fixed Implementation with Config System
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
    local dragConnection
    
    local function endDrag()
        dragStart = nil
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = self.window.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    endDrag()
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    local mainDragConnection = UserInputService.InputChanged:Connect(function(input)
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
    
    table.insert(self.connections, mainDragConnection)
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
    local elementId = #self.elements + 1
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
    
    return {
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
end

-- Create a slider
function LuaUIX:CreateSlider(parent, text, minValue, maxValue, defaultValue, callback, valueSuffix)
    local sliderFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Slider",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderFrame
    })
    
    -- Add consistent padding to slider labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = label
    })
    
    local valueLabel = Create("TextLabel", {
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        Text = (defaultValue or minValue) .. (valueSuffix or ""),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = sliderFrame
    })
    
    local sliderBar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = colors.toggleOff,
        Parent = sliderFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBar})
    
    local sliderFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = colors.accent,
        Parent = sliderBar
    })
    
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderFill})
    
    local sliderButton = Create("TextButton", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = colors.text,
        Text = "",
        Parent = sliderBar
    })
    
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderButton})
    
    local value = defaultValue or minValue
    local dragging = false
    local connections = {}
    
    -- Calculate fill width based on value
    local function updateSlider()
        local fillWidth = ((value - minValue) / (maxValue - minValue)) * sliderBar.AbsoluteSize.X
        sliderFill.Size = UDim2.new(0, fillWidth, 1, 0)
        sliderButton.Position = UDim2.new(0, fillWidth - 8, 0.5, -8)
        valueLabel.Text = tostring(math.floor(value * 100) / 100) .. (valueSuffix or "")
    end
    
    updateSlider()
    
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local dragConnection
            
            dragConnection = RunService.RenderStepped:Connect(function()
                if not dragging then
                    dragConnection:Disconnect()
                    return
                end
                
                local mousePos = UserInputService:GetMouseLocation()
                local barPos = sliderBar.AbsolutePosition
                local barSize = sliderBar.AbsoluteSize.X
                
                local relativeX = math.clamp(mousePos.X - barPos.X, 0, barSize)
                local percentage = relativeX / barSize
                value = math.floor((minValue + (maxValue - minValue) * percentage) * 100) / 100
                
                updateSlider()
                
                pcall(function()
                    if callback then
                        callback(value)
                    end
                end)
            end)
            
            table.insert(connections, dragConnection)
        end
    end
    
    local function endDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end
    
    local buttonConnection = sliderButton.MouseButton1Down:Connect(startDrag)
    table.insert(connections, buttonConnection)
    
    local barConnection = sliderBar.MouseButton1Down:Connect(startDrag)
    table.insert(connections, barConnection)
    
    local endConnection = UserInputService.InputEnded:Connect(endDrag)
    table.insert(connections, endConnection)
    
    -- Add to config system
    local elementId = #self.elements + 1
    self.elements[elementId] = {
        Get = function()
            return value
        end,
        Set = function(newValue)
            value = math.clamp(newValue, minValue, maxValue)
            updateSlider()
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            sliderFrame:Destroy()
        end
    }
    
    return {
        Get = function()
            return value
        end,
        Set = function(newValue)
            value = math.clamp(newValue, minValue, maxValue)
            updateSlider()
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            sliderFrame:Destroy()
        end
    }
end

-- Create a dropdown
function LuaUIX:CreateDropdown(parent, text, options, callback, defaultValue)
    local dropdownFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Dropdown",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdownFrame
    })
    
    -- Add consistent padding to dropdown labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = label
    })
    
    local dropdownButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = colors.toggleOff,
        Text = defaultValue or "Select...",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = dropdownFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownButton})
    
    -- Add consistent padding to dropdown buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = dropdownButton
    })
    
    local dropdownList = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundColor3 = colors.section,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = colors.accent,
        Visible = false,
        Parent = dropdownFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = dropdownList})
    
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = dropdownList
    })
    
    local selected = defaultValue
    local open = false
    local connections = {}
    
    local function updateDropdown()
        dropdownButton.Text = selected or "Select..."
    end
    
    local function toggleDropdown()
        open = not open
        dropdownList.Visible = open
        
        if open then
            self:Tween(dropdownList, {Size = UDim2.new(1, 0, 0, math.min(#options * 30, 150))})
        else
            self:Tween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)})
        end
    end
    
    local function closeDropdown()
        if open then
            open = false
            self:Tween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)})
            dropdownList.Visible = false
        end
    end
    
    -- Populate dropdown options
    for i, option in ipairs(options) do
        local optionButton = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = colors.toggleOff,
            Text = option,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = colors.text,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = dropdownList
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = optionButton})
        
        -- Add consistent padding to dropdown options
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = optionButton
        })
        
        local optionConnection = optionButton.MouseButton1Click:Connect(function()
            selected = option
            updateDropdown()
            closeDropdown()
            
            pcall(function()
                if callback then
                    callback(option)
                end
            end)
        end)
        
        table.insert(connections, optionConnection)
    end
    
    local buttonConnection = dropdownButton.MouseButton1Click:Connect(function()
        toggleDropdown()
    end)
    
    table.insert(connections, buttonConnection)
    
    -- Close dropdown when clicking elsewhere
    local closeConnection
    closeConnection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local buttonPos = dropdownButton.AbsolutePosition
            local buttonSize = dropdownButton.AbsoluteSize
            
            -- Check if mouse is outside the dropdown
            if mousePos.X < buttonPos.X or mousePos.X > buttonPos.X + buttonSize.X or
               mousePos.Y < buttonPos.Y or mousePos.Y > buttonPos.Y + buttonSize.Y + (open and dropdownList.AbsoluteSize.Y or 0) then
                closeDropdown()
            end
        end
    end)
    
    table.insert(connections, closeConnection)
    
    updateDropdown()
    
    -- Add to config system
    local elementId = #self.elements + 1
    self.elements[elementId] = {
        Get = function()
            return selected
        end,
        Set = function(value)
            if table.find(options, value) then
                selected = value
                updateDropdown()
            end
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            dropdownFrame:Destroy()
        end
    }
    
    return {
        Get = function()
            return selected
        end,
        Set = function(value)
            if table.find(options, value) then
                selected = value
                updateDropdown()
            end
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            dropdownFrame:Destroy()
        end
    }
end

-- Create a textbox
function LuaUIX:CreateTextbox(parent, text, placeholder, callback, defaultValue)
    local textboxFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Textbox",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = textboxFrame
    })
    
    -- Add consistent padding to textbox labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = label
    })
    
    local textbox = Create("TextBox", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = colors.toggleOff,
        Text = defaultValue or "",
        PlaceholderText = placeholder or "Enter text...",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = textboxFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = textbox})
    
    -- Add consistent padding to textboxes
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = textbox
    })
    
    local connections = {}
    
    local focusConnection = textbox.Focused:Connect(function()
        self:Tween(textbox, {BackgroundColor3 = colors.accent})
    end)
    
    table.insert(connections, focusConnection)
    
    local unfocusConnection = textbox.FocusLost:Connect(function()
        self:Tween(textbox, {BackgroundColor3 = colors.toggleOff})
        
        pcall(function()
            if callback then
                callback(textbox.Text)
            end
        end)
    end)
    
    table.insert(connections, unfocusConnection)
    
    -- Add to config system
    local elementId = #self.elements + 1
    self.elements[elementId] = {
        Get = function()
            return textbox.Text
        end,
        Set = function(value)
            textbox.Text = tostring(value)
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            textboxFrame:Destroy()
        end
    }
    
    return {
        Get = function()
            return textbox.Text
        end,
        Set = function(value)
            textbox.Text = tostring(value)
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            textboxFrame:Destroy()
        end
    }
end

-- Create a keybind
function LuaUIX:CreateKeybind(parent, text, callback, defaultValue)
    local keybindFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Keybind",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = keybindFrame
    })
    
    -- Add consistent padding to keybind labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = label
    })
    
    local keybindButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = colors.toggleOff,
        Text = defaultValue and defaultValue.Name or "Click to bind",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = keybindFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = keybindButton})
    
    -- Add consistent padding to keybind buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = keybindButton
    })
    
    local key = defaultValue
    local listening = false
    local connections = {}
    
    local function updateKeybind()
        keybindButton.Text = key and key.Name or "Click to bind"
    end
    
    local function startListening()
        listening = true
        keybindButton.Text = "Press any key..."
        self:Tween(keybindButton, {BackgroundColor3 = colors.accent})
    end
    
    local function stopListening()
        listening = false
        updateKeybind()
        self:Tween(keybindButton, {BackgroundColor3 = colors.toggleOff})
    end
    
    local buttonConnection = keybindButton.MouseButton1Click:Connect(function()
        if not listening then
            startListening()
        else
            stopListening()
        end
    end)
    
    table.insert(connections, buttonConnection)
    
    local inputConnection = UserInputService.InputBegan:Connect(function(input)
        if listening and not UserInputService:GetFocusedTextBox() then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode
                stopListening()
                
                pcall(function()
                    if callback then
                        callback(key)
                    end
                end)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                key = Enum.UserInputType.MouseButton1
                stopListening()
                
                pcall(function()
                    if callback then
                        callback(key)
                    end
                end)
            end
        end
    end)
    
    table.insert(connections, inputConnection)
    
    updateKeybind()
    
    -- Add to config system
    local elementId = #self.elements + 1
    self.elements[elementId] = {
        Get = function()
            return key
        end,
        Set = function(value)
            key = value
            updateKeybind()
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            keybindFrame:Destroy()
        end
    }
    
    return {
        Get = function()
            return key
        end,
        Set = function(value)
            key = value
            updateKeybind()
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            keybindFrame:Destroy()
        end
    }
end

-- Create a color picker
function LuaUIX:CreateColorPicker(parent, text, callback, defaultValue)
    local colorPickerFrame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "Color Picker",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = colorPickerFrame
    })
    
    -- Add consistent padding to color picker labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = label
    })
    
    local colorButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = defaultValue or colors.accent,
        Text = "Pick Color",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        AutoButtonColor = false,
        Parent = colorPickerFrame
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = colorButton})
    
    -- Add consistent padding to color picker buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = colorButton
    })
    
    local color = defaultValue or colors.accent
    local connections = {}
    
    local function updateColor()
        colorButton.BackgroundColor3 = color
    end
    
    local function CreateColorPickerDialog()
        -- Create color picker dialog
        local dialog = Create("Frame", {
            Size = UDim2.new(0, 250, 0, 200),
            Position = UDim2.new(0.5, -125, 0.5, -100),
            BackgroundColor3 = colors.background,
            Parent = self.gui
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialog})
        
        local title = Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = colors.titlebar,
            Text = "Color Picker",
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = colors.text,
            Parent = dialog
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = title})
        
        local colorCanvas = Create("ImageButton", {
            Size = UDim2.new(0, 180, 0, 180),
            Position = UDim2.new(0, 10, 0, 40),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Image = "rbxassetid://2615689005",
            Parent = dialog
        })
        
        local hueSlider = Create("ImageButton", {
            Size = UDim2.new(0, 20, 0, 180),
            Position = UDim2.new(1, -30, 0, 40),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Image = "rbxassetid://2615692420",
            Parent = dialog
        })
        
        local closeButton = Create("TextButton", {
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(1, -30, 0, 5),
            BackgroundColor3 = colors.close,
            Text = "X",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = colors.text,
            Parent = dialog
        })
        
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = closeButton})
        
        local selectedColor = color
        local hue = 0
        local saturation = 0
        local value = 0
        
        local function updateFromHsv()
            selectedColor = Color3.fromHSV(hue, saturation, value)
            colorCanvas.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        end
        
        local function updateFromRgb()
            hue, saturation, value = selectedColor:ToHSV()
            colorCanvas.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        end
        
        local function closeDialog()
            dialog:Destroy()
        end
        
        local function applyColor()
            color = selectedColor
            updateColor()
            
            pcall(function()
                if callback then
                    callback(color)
                end
            end)
        end
        
        closeButton.MouseButton1Click:Connect(closeDialog)
        
        -- Color canvas interaction
        colorCanvas.MouseButton1Down:Connect(function()
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not dialog.Parent then
                    connection:Disconnect()
                    return
                end
                
                local mousePos = UserInputService:GetMouseLocation()
                local canvasPos = colorCanvas.AbsolutePosition
                local canvasSize = colorCanvas.AbsoluteSize
                
                local relativeX = math.clamp(mousePos.X - canvasPos.X, 0, canvasSize.X)
                local relativeY = math.clamp(mousePos.Y - canvasPos.Y, 0, canvasSize.Y)
                
                saturation = relativeX / canvasSize.X
                value = 1 - (relativeY / canvasSize.Y)
                
                updateFromHsv()
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                    applyColor()
                end
            end)
        end)
        
        -- Hue slider interaction
        hueSlider.MouseButton1Down:Connect(function()
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not dialog.Parent then
                    connection:Disconnect()
                    return
                end
                
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = hueSlider.AbsolutePosition
                local sliderSize = hueSlider.AbsoluteSize
                
                local relativeY = math.clamp(mousePos.Y - sliderPos.Y, 0, sliderSize.Y)
                
                hue = 1 - (relativeY / sliderSize.Y)
                
                updateFromHsv()
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                    applyColor()
                end
            end)
        end)
        
        updateFromRgb()
    end
    
    local buttonConnection = colorButton.MouseButton1Click:Connect(function()
        CreateColorPickerDialog()
    end)
    
    table.insert(connections, buttonConnection)
    
    updateColor()
    
    -- Add to config system
    local elementId = #self.elements + 1
    self.elements[elementId] = {
        Get = function()
            return color
        end,
        Set = function(value)
            color = value
            updateColor()
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            colorPickerFrame:Destroy()
        end
    }
    
    return {
        Get = function()
            return color
        end,
        Set = function(value)
            color = value
            updateColor()
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            colorPickerFrame:Destroy()
        end
    }
end

-- Make UI responsive to screen size changes
function LuaUIX:MakeResponsive()
    local function updateSize()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local scale = math.min(1, viewportSize.X / 1920, viewportSize.Y / 1080)
        
        self.window.Size = UDim2.new(0, 650 * scale, 0, 500 * scale)
        self.window.Position = UDim2.new(0.5, -325 * scale, 0.5, -250 * scale)
    end
    
    local viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
    table.insert(self.connections, viewportConnection)
    
    updateSize()
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
    
    for i, element in ipairs(self.elements) do
        local value = element.Get()
        
        -- Handle Color3 values
        if typeof(value) == "Color3" then
            value = {value.R, value.G, value.B}
        -- Handle EnumItem values
        elseif typeof(value) == "EnumItem" then
            value = {Enum = tostring(value.EnumType), Value = value.Value}
        end
        
        configData[i] = value
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
                for i, value in pairs(configData) do
                    if self.elements[i] then
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
                        
                        self.elements[i].Set(value)
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

-- Cleanup function
function LuaUIX:Destroy()
    -- Disconnect all connections
    for _, connection in ipairs(self.connections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    
    -- Cancel all tweens
    for _, tween in ipairs(self.tweens) do
        if tween then
            pcall(function()
                tween:Cancel()
            end)
        end
    end
    
    -- Destroy all elements
    for _, element in ipairs(self.elements) do
        if element and element.Destroy then
            pcall(function()
                element:Destroy()
            end)
        end
    end
    
    -- Destroy GUI
    if self.gui then
        self.gui:Destroy()
    end
    
    -- Clear tables
    self.connections = {}
    self.tweens = {}
    self.elements = {}
    self.pages = {}
    self.tabButtons = {}
end

return LuaUIX
