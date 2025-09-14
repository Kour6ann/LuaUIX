-- LuaUIX Library v2.0 - Simplified Working Version
-- A reliable UI library for Roblox exploits

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
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
function LuaUIX:CreateLib(menuName)
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

-- Minimize function
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
function LuaUIX:CreatePage(name)
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
    return page
end

-- Kavo-style API implementation
function LuaUIX:NewTab(name)
    local page = self:CreatePage(name)
    
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
        Text = name,
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
        self:ShowTab(name)
    end)
    
    self.tabButtons[name] = tabButton
    
    -- Show first page by default
    if tabCount == 1 then
        self:ShowTab(name)
    end
    
    -- Return a tab object with Kavo-like methods
    local tab = {}
    tab.Name = name
    tab.Page = page
    
    function tab:NewSection(sectionName)
        return self:CreateSection(page, sectionName)
    end
    
    setmetatable(tab, {
        __index = function(t, k)
            if k == "NewSection" then
                return function(_, sectionName)
                    return self:CreateSection(page, sectionName)
                end
            end
        end
    })
    
    return tab
end

-- Show a specific tab
function LuaUIX:ShowTab(name)
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

-- Create a section (Kavo-style)
function LuaUIX:CreateSection(parent, title)
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
        Text = title or "Section",
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
    
    -- Return a section object with Kavo-like methods
    local sectionObj = {}
    sectionObj.Frame = section
    
    function sectionObj:NewButton(text, callback)
        return self:CreateButton(section, text, callback)
    end
    
    function sectionObj:NewToggle(text, callback, defaultValue)
        return self:CreateToggle(section, text, callback, defaultValue)
    end
    
    function sectionObj:NewSlider(text, min, max, callback, defaultValue, precision)
        return self:CreateSlider(section, text, min, max, callback, defaultValue, precision)
    end
    
    function sectionObj:NewDropdown(text, options, callback, defaultValue)
        return self:CreateDropdown(section, text, options, callback, defaultValue)
    end
    
    function sectionObj:NewTextBox(text, callback, placeholder)
        return self:CreateTextBox(section, text, callback, placeholder)
    end
    
    function sectionObj:NewKeybind(text, defaultKey, callback)
        return self:CreateKeybind(section, text, defaultKey, callback)
    end
    
    function sectionObj:NewColorPicker(text, defaultColor, callback)
        return self:CreateColorPicker(section, text, defaultColor, callback)
    end
    
    function sectionObj:NewLabel(text, textSize, color)
        return self:CreateLabel(section, text, textSize, color)
    end
    
    setmetatable(sectionObj, {
        __index = function(t, k)
            local methods = {
                Button = function(_, text, callback)
                    return self:CreateButton(section, text, callback)
                end,
                Toggle = function(_, text, callback, defaultValue)
                    return self:CreateToggle(section, text, callback, defaultValue)
                end,
                Slider = function(_, text, min, max, callback, defaultValue, precision)
                    return self:CreateSlider(section, text, min, max, callback, defaultValue, precision)
                end,
                Dropdown = function(_, text, options, callback, defaultValue)
                    return self:CreateDropdown(section, text, options, callback, defaultValue)
                end,
                TextBox = function(_, text, callback, placeholder)
                    return self:CreateTextBox(section, text, callback, placeholder)
                end,
                Keybind = function(_, text, defaultKey, callback)
                    return self:CreateKeybind(section, text, defaultKey, callback)
                end,
                ColorPicker = function(_, text, defaultColor, callback)
                    return self:CreateColorPicker(section, text, defaultColor, callback)
                end,
                Label = function(_, text, textSize, color)
                    return self:CreateLabel(section, text, textSize, color)
                end
            }
            
            return methods[k]
        end
    })
    
    return sectionObj
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
    
    -- Add consistent padding to buttons
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = btn
    })
    
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
    
    local elementId = "button_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        UpdateText = function(newText)
            btn.Text = newText
        end,
        GetButton = function()
            return btn
        end
    }
    
    return self.elements[elementId]
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
        
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. opt
            currentOption = opt
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            if callback then 
                callback(opt) 
            end
        end)
    end
    
    -- Update list frame size based on content
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
    
    btn.MouseButton1Click:Connect(function()
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
    
    -- Close dropdown when clicking outside
    local function closeDropdown(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and listFrame.Visible then
            if not frame:IsAncestorOf(input.Parent) and not listFrame:IsAncestorOf(input.Parent) then
                listFrame.Visible = false
                listFrame.Size = UDim2.new(1, 0, 0, 0)
            end
        end
    end
    
    UserInputService.InputBegan:Connect(closeDropdown)
    
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
        Refresh = function(newOptions)
            -- Clear existing options
            for i, v in ipairs(listFrame:GetChildren()) do
                if v:IsA("TextButton") then
                    v:Destroy()
                end
            end
            
            -- Add new options
            for _, opt in ipairs(newOptions) do
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
                
                optBtn.MouseButton1Click:Connect(function()
                    btn.Text = text .. ": " .. opt
                    currentOption = opt
                    listFrame.Visible = false
                    listFrame.Size = UDim2.new(1, 0, 0, 0)
                    if callback then 
                        callback(opt) 
                    end
                end)
            end
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
    
    local elementId = "textbox_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetText = function(newText)
            textBox.Text = newText
        end,
        GetText = function()
            return textBox.Text
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
    
    -- Add consistent padding to labels
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = label
    })
    
    local elementId = "label_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        UpdateText = function(newText)
            label.Text = newText
        end
    }
    
    return self.elements[elementId]
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
