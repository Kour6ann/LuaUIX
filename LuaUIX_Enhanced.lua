-- LuaUIX - Single-file library
-- Combines LuaUIX visuals (your uploaded implementation) with a Kavo-style API:
-- Window: CreateLib / NewTab / NewSection
-- Section: NewButton, NewToggle, NewSlider, NewDropdown, NewTextbox, NewKeybind, NewColorPicker
-- Uses Lucide icons (supply image asset id strings) for tab icons instead of emojis.
--
-- Usage:
-- local LuaUIX = require(path_to_this_file) -- or loadstring/httpget
-- local Window = LuaUIX:CreateLib("My Hub")
-- local Tab = Window:NewTab("Main", "123456789") -- lucide asset id
-- local Section = Tab:NewSection("Combat")
-- Section:NewButton("Kill All", function() print("clicked") end)

-- ---------------------------------------------------------------------------
-- BEGIN: Core LuaUIX visuals implementation (based on your uploaded LuaUIX.txt)
-- ---------------------------------------------------------------------------

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = workspace

-- Utility functions
local function Create(className, properties)
    local instance = Instance.new(className)
    if properties then
        for property, value in pairs(properties) do
            instance[property] = value
        end
    end
    return instance
end

-- Color palette (from your LuaUIX.txt)
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

-- Constructor (original: LuaUIX.new)
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
    
    -- Create content area
    self.content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundColor3 = colors.content,
        Parent = self.window
    })
    
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.content})
    
    -- Initialize internal state
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
    self.tweenInfo = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- we'll create tweens ad-hoc
    
    -- Add draggable functionality
    self:draggable(self.titlebar)
    
    -- Add keybind to toggle UI
    self:setupToggleKeybind()
    
    -- Make UI responsive
    self:MakeResponsive()
    
    -- Notification container placeholder
    self.notificationContainer = nil
    
    return self
end

-- Tween helper (uses TweenService directly with short tween info)
function LuaUIX:Tween(object, properties, time)
    time = time or 0.18
    local tween = TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
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
    
    local conn
    conn = UserInputService.InputChanged:Connect(function(input)
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
    table.insert(self.connections, conn)
end

-- Setup UI toggle keybind (RightShift)
function LuaUIX:setupToggleKeybind()
    local toggleKey = Enum.KeyCode.RightShift
    local connection = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == toggleKey then
            self:ToggleVisibility()
        end
    end)
    table.insert(self.connections, connection)
end

-- Minimize / restore
function LuaUIX:Minimize()
    if self.isMinimized then
        -- Restore window
        self:Tween(self.window, {Size = self.originalSize, Position = self.originalPosition})
        self.content.Visible = true
        self.sidebar.Visible = true
        self.minimizeButton.Text = "_"
        self.isMinimized = false
    else
        -- Minimize
        self.originalSize = self.window.Size
        self.originalPosition = self.window.Position
        self:Tween(self.window, {Size = UDim2.new(0, 200, 0, 40), Position = UDim2.new(0.5, -100, 0, 10)})
        self.content.Visible = false
        self.sidebar.Visible = false
        self.minimizeButton.Text = "+"
        self.isMinimized = true
    end
end

-- Create a page (tab) with optional icon asset id (lucide)
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
    
    -- Create tab button in sidebar
    local tabCount = 0
    for _ in pairs(self.pages) do tabCount = tabCount + 1 end
    
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
    
    -- Add default padding; we'll adjust if icon provided
    local pad = Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = tabButton
    })
    
    -- If an icon asset id is provided, create an ImageLabel and shift text
    if icon and type(icon) == "string" then
        local img = Create("ImageLabel", {
            Name = name .. "_Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 12, 0.5, -10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. icon,
            Parent = tabButton
        })
        -- shift text a bit by modifying the button's Text (simple approach)
        tabButton.Text = "   " .. tabButton.Text
    end
    
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

-- Show a page and highlight corresponding tab
function LuaUIX:ShowPage(name)
    if self.currentPage then
        self.currentPage.Visible = false
        for pageName, button in pairs(self.tabButtons) do
            button.BackgroundColor3 = colors.toggleOff
        end
    end
    
    if self.pages[name] then
        self.pages[name].Visible = true
        self.currentPage = self.pages[name]
        self:Tween(self.tabButtons[name], {BackgroundColor3 = colors.accent}, 0.12)
    end
end

-- Create a section inside a page
function LuaUIX:CreateSection(parent, titleText)
    parent = parent or self.content
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
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = header
    })
    
    return section
end

-- Create Toggle
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
    
    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = btn
    })
    
    local state = defaultValue or false
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        if callback then pcall(callback, state) end
    end)
    
    local elementId = "toggle_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetState = function(newState)
            state = newState
            self:Tween(btn, {BackgroundColor3 = state and colors.accent or colors.toggleOff})
        end,
        GetState = function() return state end,
        GetButton = function() return btn end
    }
    
    return self.elements[elementId]
end

-- Create Button
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = btn})
    
    btn.MouseEnter:Connect(function()
        local r,g,b = math.floor(color.R*255*0.8), math.floor(color.G*255*0.8), math.floor(color.B*255*0.8)
        self:Tween(btn, {BackgroundColor3 = Color3.fromRGB(r,g,b)})
    end)
    btn.MouseLeave:Connect(function()
        self:Tween(btn, {BackgroundColor3 = color})
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return btn
end

-- Create Slider
function LuaUIX:CreateSlider(parent, text, min, max, callback, defaultValue, precision)
    local frame = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = (text or "Slider") .. ": " .. (defaultValue or min),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.textSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    Create("UIPadding", {PaddingLeft = UDim.new(0, 6), Parent = label})
    
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
    precision = precision or 0
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    sliderBack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    
    local moveConn
    local releaseConn
    moveConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
            self:Tween(sliderFill, {Size = UDim2.new(rel, 0, 1, 0)}, 0.03)
            if precision > 0 then
                currentValue = math.floor((min + (max - min) * rel) * 10^precision) / 10^precision
            else
                currentValue = math.floor(min + (max - min) * rel)
            end
            label.Text = (text or "Slider") .. ": " .. currentValue
            if callback then pcall(callback, currentValue) end
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
        GetValue = function() return currentValue end
    }
    return self.elements[elementId]
end

-- Create Dropdown
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
        Text = text .. (defaultValue and (": " .. tostring(defaultValue)) or " ▼"),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = frame
    })
    Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = btn})
    
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
    local listLayout = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = listFrame})
    
    local currentOption = defaultValue
    
    for i, opt in ipairs(options or {}) do
        local optBtn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = tostring(opt),
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(220, 220, 220),
            LayoutOrder = i,
            Parent = listFrame
        })
        Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = optBtn})
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = text .. ": " .. tostring(opt)
            currentOption = opt
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            if callback then pcall(callback, opt) end
        end)
    end
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
    
    btn.MouseButton1Click:Connect(function()
        if listFrame.Visible then
            listFrame.Visible = false
            listFrame.Size = UDim2.new(1, 0, 0, 0)
        else
            listFrame.Visible = true
            local maxHeight = math.min(#(options or {}) * 28, 140)
            listFrame.Size = UDim2.new(1, 0, 0, maxHeight)
        end
    end)
    
    local function closeDropdown(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and listFrame.Visible then
            if not frame:IsAncestorOf(input.Target) and not listFrame:IsAncestorOf(input.Target) then
                listFrame.Visible = false
                listFrame.Size = UDim2.new(1, 0, 0, 0)
            end
        end
    end
    local conn = UserInputService.InputBegan:Connect(closeDropdown)
    table.insert(self.connections, conn)
    
    local elementId = "dropdown_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetOption = function(option)
            if table.find(options or {}, option) then
                btn.Text = text .. ": " .. tostring(option)
                currentOption = option
            end
        end,
        GetOption = function() return currentOption end
    }
    
    return self.elements[elementId]
end

-- Create Label
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = label})
    return label
end

-- Create TextBox
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = textBox})
    
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
        if enterPressed and callback then pcall(callback, textBox.Text) end
    end)
    
    local elementId = "textbox_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetText = function(newText) textBox.Text = newText end,
        GetText = function() return textBox.Text end
    }
    return self.elements[elementId]
end

-- Create Keybind
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = label})
    
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = keyLabel})
    
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
        if currentKey and input.KeyCode == currentKey and callback then
            pcall(callback)
        end
    end)
    table.insert(self.connections, connection)
    
    local elementId = "keybind_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetKey = function(key) currentKey = key; keyLabel.Text = key.Name end,
        GetKey = function() return currentKey end,
        Destroy = function() if connection and connection.Connected then connection:Disconnect() end end
    }
    return self.elements[elementId]
end

-- Create Color Picker (simplified)
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 10), Parent = label})
    
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
    
    colorBox.MouseButton1Click:Connect(function()
        self:CreateColorPickerDialog(currentColor, function(newColor)
            currentColor = newColor
            colorBox.BackgroundColor3 = currentColor
            if callback then pcall(callback, currentColor) end
        end)
    end)
    
    local elementId = "colorpicker_" .. HttpService:GenerateGUID(false)
    self.elements[elementId] = {
        SetColor = function(color) currentColor = color; colorBox.BackgroundColor3 = color end,
        GetColor = function() return currentColor end
    }
    return self.elements[elementId]
end

-- Create Color Picker Dialog (simplified)
function LuaUIX:CreateColorPickerDialog(defaultColor, callback)
    local dialog = Create("Frame", {
        Name = "ColorPickerDialog",
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100),
        BackgroundColor3 = colors.section,
        Parent = self.gui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialog})
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        Parent = dialog
    })
    local colorList = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 165, 0),
        Color3.fromRGB(128, 0, 128)
    }
    for i, color in ipairs(colorList) do
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
            if callback then pcall(callback, color) end
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
    Create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = closeButton})
    closeButton.MouseButton1Click:Connect(function() dialog:Destroy() end)
    return dialog
end

-- Tooltips (simple)
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
    element.MouseEnter:Connect(function() tooltip.Visible = true end)
    element.MouseLeave:Connect(function() tooltip.Visible = false end)
    element.MouseMoved:Connect(function(x, y) tooltip.Position = UDim2.new(0, x + 20, 0, y + 20) end)
end

-- Notifications system
function LuaUIX:Notify(title, message, duration, notifType)
    duration = duration or 5
    notifType = notifType or "info"
    if not self.notificationContainer then
        self.notificationContainer = Create("Frame", {
            Name = "NotificationContainer",
            Size = UDim2.new(0, 340, 1, 0),
            Position = UDim2.new(1, -360, 0, 0),
            BackgroundTransparency = 1,
            Parent = self.gui
        })
        Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Parent = self.notificationContainer
        })
        Create("UIPadding", {PaddingBottom = UDim.new(0, 25), PaddingRight = UDim.new(0, 25), Parent = self.notificationContainer})
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
    Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 12),
        Parent = notification
    })
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
    notification.Size = UDim2.new(0, 320, 0, messageLabel.TextBounds.Y + 45)
    local color = colors.info
    if notifType == "success" then color = colors.success elseif notifType == "warning" then color = colors.warning elseif notifType == "error" then color = colors.error end
    local accentBar = Create("Frame", {
        Size = UDim2.new(0, 6, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = color,
        Parent = notification
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = accentBar})
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Size = UDim2.new(1, -10, 0, 22)
    messageLabel.Position = UDim2.new(0, 10, 0, 27)
    messageLabel.Size = UDim2.new(1, -10, 0, 0)
    notification.Position = UDim2.new(1, 0, 0, 0)
    self:Tween(notification, {Position = UDim2.new(0, 0, 0, 0)}, 0.18)
    delay(duration, function()
        if notification and notification.Parent then
            self:Tween(notification, {Position = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.18)
            wait(0.3)
            if notification and notification.Parent then notification:Destroy() end
        end
    end)
    return notification
end

-- Focus management
function LuaUIX:SetFocusedElement(element) self.focusedElement = element end
function LuaUIX:GetFocusedElement() return self.focusedElement end

-- Responsiveness
function LuaUIX:MakeResponsive()
    local function updateSize()
        local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
        local scale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080) * 0.9
        self.window.Size = UDim2.new(0, 650 * scale, 0, 500 * scale)
        self.window.Position = UDim2.new(0.5, -325 * scale, 0.5, -250 * scale)
    end
    updateSize()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
    end
end

-- Toggle visibility
function LuaUIX:ToggleVisibility() self.gui.Enabled = not self.gui.Enabled end

-- Destroy UI (cleanup connections)
function LuaUIX:Destroy()
    for _, connection in ipairs(self.connections) do
        if connection and connection.Connected then
            pcall(function() connection:Disconnect() end)
        end
    end
    if self.gui and self.gui.Parent then pcall(function() self.gui:Destroy() end) end
end

-- ---------------------------------------------------------------------------
-- END: Core visuals implementation
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- BEGIN: Kavo-style API wrappers (expose NewTab, NewSection, NewButton, etc.)
-- These wrappers let users migrate from Kavo quickly while using LuaUIX visuals.
-- ---------------------------------------------------------------------------

-- CreateLib alias (Kavo-style)
function LuaUIX.CreateLib(name)
    -- returns a window object wrapping an instance produced by LuaUIX.new
    local core = LuaUIX.new(name or "LuaUIX")
    -- We'll extend that `core` with Kavo-style methods: NewTab, NewSection, Notify, ToggleUI
    -- (most of these map directly to core:CreatePage / core:CreateSection / core:Notify)
    
    -- Kavo-styled method: ToggleUI (alias to ToggleVisibility)
    function core:ToggleUI()
        self:ToggleVisibility()
    end
    
    -- Kavo-styled NewTab: returns a tab object with :NewSection
    function core:NewTab(tabName, iconAssetId)
        local page = self:CreatePage(tabName, iconAssetId)
        -- Tab object
        local TabObj = {}
        TabObj.__index = TabObj
        TabObj._core = self
        TabObj._page = page
        TabObj.name = tabName
        TabObj.icon = iconAssetId
        
        -- NewSection creates a section inside this tab/page
        function TabObj:NewSection(sectionName)
            local section = self._core:CreateSection(self._page, sectionName)
            -- Section object with methods to add elements
            local Sect = {}
            Sect.__index = Sect
            Sect._core = self._core
            Sect._parent = section
            
            -- NewButton
            function Sect:NewButton(btnName, callback, color)
                return self._core:CreateButton(self._parent, btnName, callback, color)
            end
            -- NewToggle
            function Sect:NewToggle(tname, callback, default)
                return self._core:CreateToggle(self._parent, tname, callback, default)
            end
            -- NewSlider
            function Sect:NewSlider(sname, min, max, callback, default, precision)
                return self._core:CreateSlider(self._parent, sname, min, max, callback, default, precision)
            end
            -- NewDropdown
            function Sect:NewDropdown(dname, options, callback, default)
                return self._core:CreateDropdown(self._parent, dname, options, callback, default)
            end
            -- NewTextbox
            function Sect:NewTextbox(tname, callback, placeholder)
                return self._core:CreateTextBox(self._parent, tname, callback, placeholder)
            end
            -- NewKeybind
            function Sect:NewKeybind(kname, defaultKey, callback)
                return self._core:CreateKeybind(self._parent, kname, defaultKey, callback)
            end
            -- NewColorPicker
            function Sect:NewColorPicker(cname, defaultColor, callback)
                return self._core:CreateColorPicker(self._parent, cname, defaultColor, callback)
            end
            -- AddTooltip helper
            function Sect:AddTooltip(element, text)
                return self._core:AddTooltip(element, text)
            end
            
            setmetatable(Sect, Sect)
            return Sect
        end
        
        -- Expose a direct CreateSection to mimic some libs
        function TabObj:CreateSection(sectionName)
            return TabObj:NewSection(sectionName)
        end
        
        -- return tab object
        setmetatable(TabObj, TabObj)
        return TabObj
    end
    
    -- NewSection at top-level (create on current page or content)
    function core:NewSectionOnCurrent(sectionName)
        local parent = self.currentPage or self.content
        return self:CreateSection(parent, sectionName)
    end
    
    -- Kavo-style Notify alias
    function core:Notify(title, message, duration, ntype)
        return self:Notify(title, message, duration, ntype)
    end
    
    -- Expose element creation directly on window for convenience (optional)
    function core:NewButton(parentSectionOrPage, text, callback, color)
        return self:CreateButton(parentSectionOrPage, text, callback, color)
    end
    function core:NewToggle(parentSectionOrPage, text, callback, default)
        return self:CreateToggle(parentSectionOrPage, text, callback, default)
    end
    function core:NewSlider(parentSectionOrPage, text, min, max, callback, default, precision)
        return self:CreateSlider(parentSectionOrPage, text, min, max, callback, default, precision)
    end
    function core:NewDropdown(parentSectionOrPage, text, options, callback, default)
        return self:CreateDropdown(parentSectionOrPage, text, options, callback, default)
    end
    function core:NewTextbox(parentSectionOrPage, text, callback, placeholder)
        return self:CreateTextBox(parentSectionOrPage, text, callback, placeholder)
    end
    function core:NewKeybind(parentSectionOrPage, text, defaultKey, callback)
        return self:CreateKeybind(parentSectionOrPage, text, defaultKey, callback)
    end
    function core:NewColorPicker(parentSectionOrPage, text, defaultColor, callback)
        return self:CreateColorPicker(parentSectionOrPage, text, defaultColor, callback)
    end
    
    -- Return the configured core window
    return core
end

-- ---------------------------------------------------------------------------
-- END: Kavo-style API wrappers
-- ---------------------------------------------------------------------------

-- Final return (expose both LuaUIX.new and LuaUIX.CreateLib)
-- Example usage:
-- local Library = require("LuaUIX") -- then Library.CreateLib("MyHub")
return LuaUIX
