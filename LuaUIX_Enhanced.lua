-- LuaUIX Library v1.0
-- A comprehensive UI library for Roblox exploits

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Utility functions
local function createInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

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
        BackgroundColor3 = Color3.fromRGB(33, 34, 44),
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
        BackgroundColor3 = Color3.fromRGB(46, 46, 66),
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
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.titlebar
    })
    
    -- Create sidebar
    self.sidebar = createInstance("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(27, 28, 37),
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
        BackgroundColor3 = Color3.fromRGB(40, 42, 54),
        Parent = self.window
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.content
    })
    
    -- Initialize pages table
    self.pages = {}
    self.currentPage = nil
    
    -- Add draggable functionality
    self:draggable(self.titlebar)
    
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

-- Create a new page
function LuaUIX:CreatePage(name)
    local page = createInstance("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = Color3.fromRGB(56, 172, 212),
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
        BackgroundColor3 = Color3.fromRGB(42, 46, 59),
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = self.sidebar
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = tabButton
    })
    
    tabButton.MouseButton1Click:Connect(function()
        self:ShowPage(name)
    end)
    
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
    end
    
    if self.pages[name] then
        self.pages[name].Visible = true
        self.currentPage = self.pages[name]
    end
end

-- Create a section
function LuaUIX:CreateSection(parent, titleText)
    local section = createInstance("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = Color3.fromRGB(23, 25, 34),
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
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    return section
end

-- Create a toggle
function LuaUIX:CreateToggle(parent, text, callback, defaultValue)
    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = defaultValue and Color3.fromRGB(56, 172, 212) or Color3.fromRGB(42, 46, 59),
        Text = text or "Toggle",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
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
        btn.BackgroundColor3 = state and Color3.fromRGB(56, 172, 212) or Color3.fromRGB(42, 46, 59)
        if callback then 
            callback(state) 
        end
    end)
    
    return {
        SetState = function(newState)
            state = newState
            btn.BackgroundColor3 = state and Color3.fromRGB(56, 172, 212) or Color3.fromRGB(42, 46, 59)
        end,
        GetState = function()
            return state
        end
    }
end

-- Create a button
function LuaUIX:CreateButton(parent, text, callback)
    local btn = createInstance("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(90, 120, 255),
        Text = text or "Button",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = parent
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = btn
    })
    
    btn.MouseButton1Click:Connect(function()
        if callback then 
            callback() 
        end
    end)
    
    return btn
end

-- Create a slider
function LuaUIX:CreateSlider(parent, text, min, max, callback, defaultValue)
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
        TextColor3 = Color3.fromRGB(220, 220, 220),
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
        BackgroundColor3 = Color3.fromRGB(56, 172, 212),
        BorderSizePixel = 0,
        Parent = sliderBack
    })
    
    createInstance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = sliderFill
    })
    
    local dragging = false
    local currentValue = defaultValue or min
    
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
            currentValue = math.floor(min + (max - min) * rel)
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
        BackgroundColor3 = Color3.fromRGB(42, 46, 59),
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
        TextColor3 = Color3.fromRGB(255, 255, 255),
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
            TextColor3 = Color3.fromRGB(220, 220, 220),
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
function LuaUIX:CreateLabel(parent, text, textSize)
    local label = createInstance("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = textSize or 14,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    
    return label
end

-- Create a textbox
function LuaUIX:CreateTextBox(parent, text, callback, placeholder)
    local frame = createInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(42, 46, 59),
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
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = frame
    })
    
    textBox.FocusLost:Connect(function()
        if callback then 
            callback(textBox.Text) 
        end
    end)
    
    return textBox
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
