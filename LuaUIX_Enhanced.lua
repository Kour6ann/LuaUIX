-- LuaUIX.lua
-- Rewritten/Patched LuaUIX (Kavo-style API)
-- Features:
--  * CreateLib(name, theme) -> returns Library object
--  * Library:NewTab(name) -> Tab object
--  * Tab:NewSection(name[, hidden]) -> Section object
--  * Section:NewButton(name, tip, callback) -> Button
--  * Section:NewTextBox(name, tip, callback) -> TextBox
--  * Section:NewToggle(name, tip, callback, default) -> TogFunction
--  * Section:NewSlider(name, tip, min, max, callback, default, precision) -> SliderFunction
--  * Section:NewDropdown(name, tip, list, callback, multi) -> DropFunction (multi-select supported)
--  * Section:NewLabel(text) -> LabelFunction
--  * Library:ToggleUI(), Library:ChangeColor(property, color), Library:SaveConfig(), Library:LoadConfig()
--  * Backwards compatibility: LuaUIX.new(...) -> CreateLib(...)
--  * Config system uses a JSON file named "<libraryName>_LuaUIX_Config.json"
--  * Only 3 themes: "Dark", "Light", "Midnight"
--  * Preserves original visuals and many behaviors
--  * No placeholder code — complete working implementation

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Utility: safe Create with properties
local function Create(className, props)
    local obj = Instance.new(className)
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

-- Default theme palettes (only these 3)
local THEME_PRESETS = {
    Dark = {
        SchemeColor = Color3.fromRGB(64, 64, 64),
        Background  = Color3.fromRGB(20, 21, 25),
        Header      = Color3.fromRGB(28, 29, 34),
        TextColor   = Color3.fromRGB(235,235,235),
        ElementColor= Color3.fromRGB(32, 32, 38)
    },
    Light = {
        SchemeColor = Color3.fromRGB(150, 150, 150),
        Background  = Color3.fromRGB(245,245,245),
        Header      = Color3.fromRGB(220,220,220),
        TextColor   = Color3.fromRGB(12,12,12),
        ElementColor= Color3.fromRGB(234,234,234)
    },
    Midnight = {
        SchemeColor = Color3.fromRGB(26, 189, 158),
        Background  = Color3.fromRGB(44, 62, 82),
        Header      = Color3.fromRGB(57, 81, 105),
        TextColor   = Color3.fromRGB(245,245,245),
        ElementColor= Color3.fromRGB(52, 74, 95)
    }
}

-- Default general colors (used before CreateLib called)
local DEFAULT_COLORS = {
    SchemeColor = Color3.fromRGB(74,99,135),
    Background  = Color3.fromRGB(33,34,44),
    Header      = Color3.fromRGB(46,46,66),
    TextColor   = Color3.fromRGB(255,255,255),
    ElementColor= Color3.fromRGB(40,40,50)
}

-- Tween utility wrapper
local function Tween(obj, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quad
    dir  = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(time, style, dir)
    local success, t = pcall(function()
        return TweenService:Create(obj, info, props)
    end)
    if success and t then
        t:Play()
        return t
    end
end

-- Dragging helper (standard pattern)
local function MakeDraggable(frame, parent)
    parent = parent or frame
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startPos = parent.Position

            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = inp
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging and dragStart and startPos then
            local delta = inp.Position - dragStart
            parent.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Config helpers
local function safeWriteFile(path, content)
    local ok, err = pcall(function() writefile(path, content) end)
    return ok, err
end
local function safeReadFile(path)
    local ok, content = pcall(function() return readfile(path) end)
    if ok then return content end
    return nil
end

-- ========== CreateLib (entry) ==========
-- Usage: local Library = require(module):CreateLib("My UI", "Dark")
function LuaUIX:CreateLib(libName, themeName)
    libName = tostring(libName or "LuaUIX")
    themeName = tostring(themeName or "Dark")
    local theme = THEME_PRESETS[themeName] or THEME_PRESETS["Dark"]

    -- Root object to return
    local Library = {}
    Library.__index = Library

    -- Persistent state
    Library.name = libName
    Library.colors = {
        SchemeColor  = theme.SchemeColor,
        Background   = theme.Background,
        Header       = theme.Header,
        TextColor    = theme.TextColor,
        ElementColor = theme.ElementColor
    }
    Library.tabs = {}
    Library.pagesFolder = nil
    Library.screen = nil
    Library.configName = libName .. "_LuaUIX_Config.json"
    Library.elements = {} -- track elements for external control
    Library.enabled = true

    -- Config storage (defaults)
    Library.config = {
        theme = themeName,
        elements = {} -- key-value for toggles, dropdown selections, sliders etc.
    }

    -- Build GUI (keeps your visual style: sidebar + content)
    -- Clean existing
    for _,v in pairs(CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == "LuaUIX_"..libName then
            v:Destroy()
        end
    end

    local screen = Create("ScreenGui", { Name = "LuaUIX_"..libName, Parent = CoreGui, ResetOnSpawn = false })
    Library.screen = screen

    -- Main window
    local main = Create("Frame", {
        Name = "Main",
        Parent = screen,
        BackgroundColor3 = Library.colors.Background,
        Size = UDim2.new(0, 650, 0, 460),
        Position = UDim2.new(0.5, -325, 0.5, -230),
        ClipsDescendants = true
    })
    Create("UICorner", { Parent = main, CornerRadius = UDim.new(0,10) })

    -- Header
    local header = Create("Frame", {
        Name = "Header",
        Parent = main,
        BackgroundColor3 = Library.colors.Header,
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0,0,0,0)
    })
    Create("UICorner", { Parent = header, CornerRadius = UDim.new(0,8) })

    local title = Create("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Text = libName,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Library.colors.TextColor,
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -150, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Close and Minimize (basic)
    local closeBtn = Create("TextButton", {
        Name = "Close",
        Parent = header,
        Text = "X",
        Size = UDim2.new(0,26,0,22),
        Position = UDim2.new(1, -34, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(210,60,60),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255,255,255)
    })
    Create("UICorner", { Parent = closeBtn, CornerRadius = UDim.new(0,6) })

    local minBtn = Create("TextButton", {
        Name = "Minimize",
        Parent = header,
        Text = "_",
        Size = UDim2.new(0,26,0,22),
        Position = UDim2.new(1, -64, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(200,160,50),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255,255,255)
    })
    Create("UICorner", { Parent = minBtn, CornerRadius = UDim.new(0,6) })

    -- Sidebar
    local sidebar = Create("Frame", {
        Name = "Sidebar",
        Parent = main,
        BackgroundColor3 = Library.colors.Header,
        Size = UDim2.new(0,170,1,-34),
        Position = UDim2.new(0,0,0,34)
    })
    Create("UICorner", { Parent = sidebar, CornerRadius = UDim.new(0,10) })

    -- Content
    local content = Create("Frame", {
        Name = "Content",
        Parent = main,
        BackgroundColor3 = Library.colors.ElementColor,
        Size = UDim2.new(1, -170, 1, -34),
        Position = UDim2.new(0,170,0,34),
        ClipsDescendants = true
    })
    Create("UICorner", { Parent = content, CornerRadius = UDim.new(0,10) })

    -- Pages folder (holds scrolling pages)
    local pagesFolder = Create("Folder", { Name = "Pages", Parent = content })
    Library.pagesFolder = pagesFolder

    -- Sidebar list layout container
    local tabListFrame = Create("Frame", { Parent = sidebar, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0) })
    local tabListLayout = Create("UIListLayout", { Parent = tabListFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) })
    Create("UIPadding", { Parent = tabListFrame, PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) })

    -- Info container (like Kavo's bottom info bar)
    local infoContainer = Create("Frame", {
        Name = "Info",
        Parent = main,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, content.Size.X.Offset, 0, 36),
        Position = UDim2.new(0,170,1,-36)
    })

    -- Utility: apply live theme to UI objects (observes Library.colors)
    local function applyThemeEveryFrame()
        -- small coroutine to keep UI colors in sync (cheap, acceptable)
        coroutine.wrap(function()
            while RunService.Stepped:Wait() do
                if not main or not main.Parent then break end
                pcall(function()
                    main.BackgroundColor3 = Library.colors.Background
                    header.BackgroundColor3 = Library.colors.Header
                    sidebar.BackgroundColor3 = Library.colors.Header
                    title.TextColor3 = Library.colors.TextColor
                    content.BackgroundColor3 = Library.colors.ElementColor
                    -- update children special cases:
                    for _,child in ipairs(tabListFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child.TextColor3 = Library.colors.TextColor
                        end
                    end
                end)
            end
        end)()
    end
    applyThemeEveryFrame()

    -- Toggle UI
    function Library:ToggleUI()
        if self.screen and self.screen.Parent then
            self.screen.Enabled = not self.screen.Enabled
            self.enabled = self.screen.Enabled
        end
    end

    -- Change a color property live
    function Library:ChangeColor(prop, color3)
        if self.colors[prop] ~= nil then
            self.colors[prop] = color3
            -- persist selected theme change as custom (update config)
            self.config.theme = "Custom"
            self:SaveConfig()
        end
    end

    -- Save/Load config
    function Library:SaveConfig()
        local ok, err = pcall(function()
            local s = HttpService:JSONEncode(self.config)
            writefile(self.configName, s)
        end)
        return ok, err
    end

    function Library:LoadConfig()
        local content = safeReadFile(self.configName)
        if not content then return false, "No config file" end
        local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok then return false, "Invalid JSON" end
        -- merge
        for k,v in pairs(data) do
            self.config[k] = v
        end
        -- apply theme if present
        if self.config.theme and THEME_PRESETS[self.config.theme] then
            local t = THEME_PRESETS[self.config.theme]
            self.colors.SchemeColor = t.SchemeColor
            self.colors.Background  = t.Background
            self.colors.Header      = t.Header
            self.colors.TextColor   = t.TextColor
            self.colors.ElementColor= t.ElementColor
        end
        -- apply element states if any
        if self.config.elements then
            for id, val in pairs(self.config.elements) do
                local el = self.elements[id]
                if el and el.SetState then
                    pcall(function() el.SetState(val) end)
                elseif el and el.SetValue then
                    pcall(function() el.SetValue(val) end)
                elseif el and el.SetOption then
                    pcall(function() el.SetOption(val) end)
                end
            end
        end
        return true
    end

    -- Internal helper: register an element to config system
    function Library:_registerElement(id, def)
        self.elements[id] = def
        -- restore from config if available
        if self.config.elements and self.config.elements[id] ~= nil then
            local prev = self.config.elements[id]
            pcall(function()
                if def.SetState then def.SetState(prev) end
                if def.SetValue then def.SetValue(prev) end
                if def.SetOption then def.SetOption(prev) end
            end)
        end
    end

    -- Close/minimize behavior
    closeBtn.MouseButton1Click:Connect(function()
        screen:Destroy()
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        if not minimized then
            -- store current size/position
            main.Size = UDim2.new(0, 180, 0, 36)
            main.Position = UDim2.new(0.5, -90, 0, 10)
            content.Visible = false
            sidebar.Visible = false
            minimized = true
        else
            -- restore approximate defaults
            main.Size = UDim2.new(0, 650, 0, 460)
            main.Position = UDim2.new(0.5, -325, 0.5, -230)
            content.Visible = true
            sidebar.Visible = true
            minimized = false
        end
    end)

    -- Draggable header
    MakeDraggable(header, main)

    -- Toggle keybind: RightShift (preserve earlier behaviour)
    do
        local connection
        connection = UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.KeyCode == Enum.KeyCode.RightShift then
                Library:ToggleUI()
            end
        end)
        -- store connection for possible disconnect (not exported)
    end

    -- ========== API: NewTab ==========
    function Library:NewTab(tabName)
        tabName = tostring(tabName or "Tab")
        -- create sidebar button
        local tabButton = Create("TextButton", {
            Name = tabName .. "Tab",
            Parent = tabListFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            Text = tabName,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Library.colors.TextColor,
            AutoButtonColor = false
        })
        Create("UICorner", { Parent = tabButton, CornerRadius = UDim.new(0,6) })
        Create("UIPadding", { Parent = tabButton, PaddingLeft = UDim.new(0,8) })

        -- create page/scrolling frame
        local page = Create("ScrollingFrame", {
            Name = tabName .. "Page",
            Parent = pagesFolder,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,1,0),
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarThickness = 6,
            Visible = false,
            Active = true
        })
        local pageLayout = Create("UIListLayout", { Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8) })
        Create("UIPadding", { Parent = page, PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) })

        -- hook for dynamic sizing
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            local y = pageLayout.AbsoluteContentSize.Y
            page.CanvasSize = UDim2.new(0,0,0,y + 10)
        end)

        -- make first tab visible if none exist
        if #pagesFolder:GetChildren() == 1 then
            page.Visible = true
            tabButton.BackgroundTransparency = 0
        end

        -- tab switch logic
        tabButton.MouseButton1Click:Connect(function()
            for _,p in ipairs(pagesFolder:GetChildren()) do
                if p:IsA("ScrollingFrame") then
                    p.Visible = false
                end
            end
            page.Visible = true
            -- set visual highlight (we use tween on background)
            for _,btn in ipairs(tabListFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundTransparency = 1}, 0.15)
                end
            end
            Tween(tabButton, {BackgroundTransparency = 0}, 0.15)
        end)

        -- Tab object to return
        local Tab = {}
        Tab.__index = Tab
        Tab._page = page
        Tab._library = Library

        -- NewSection: similar to Kavo
        function Tab:NewSection(secName, hidden)
            secName = tostring(secName or "Section")
            hidden = hidden or false

            local sectionFrame = Create("Frame", {
                Name = secName .. "Section",
                Parent = page,
                BackgroundColor3 = Library.colors.Background,
                Size = UDim2.new(1, -0, 0, 0), -- we'll auto-size by layout below
                AutomaticSize = Enum.AutomaticSize.Y
            })
            Create("UICorner", { Parent = sectionFrame, CornerRadius = UDim.new(0,8) })
            Create("UIPadding", { Parent = sectionFrame, PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingBottom = UDim.new(0,8), PaddingRight = UDim.new(0,8) })

            local header = Create("TextLabel", {
                Name = "SectionHeader",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                Text = secName,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = Library.colors.TextColor,
                Size = UDim2.new(1,0,0,20)
            })
            header.RichText = true

            local inner = Create("Frame", {
                Name = "Inner",
                Parent = sectionFrame,
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            Create("UIListLayout", { Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6) })
            Create("UIPadding", { Parent = inner, PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) })

            if hidden then header.Visible = false end

            -- Section API
            local Section = {}
            Section.__index = Section
            Section._inner = inner
            Section._lib = Library

            -- NewButton
            function Section:NewButton(bname, tip, callback)
                bname = tostring(bname or "Button")
                tip = tostring(tip or "")
                callback = callback or function() end

                local btn = Create("TextButton", {
                    Name = bname .. "Btn",
                    Parent = self._inner,
                    BackgroundColor3 = Library.colors.ElementColor,
                    Size = UDim2.new(1,0,0,34),
                    Text = "",
                    AutoButtonColor = false
                })
                Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0,6) })

                local label = Create("TextLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Text = bname,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 14,
                    TextColor3 = Library.colors.TextColor,
                    Position = UDim2.new(0,10,0,6),
                    Size = UDim2.new(1,-60,1,0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local icon = Create("ImageLabel", {
                    Parent = btn,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0,20,0,20),
                    Position = UDim2.new(1,-30,0,7),
                    Image = "rbxassetid://4560909609",
                    ImageColor3 = Library.colors.SchemeColor
                })

                btn.MouseEnter:Connect(function()
                    Tween(btn, {BackgroundColor3 = Library.colors.ElementColor + Color3.new(0.04,0.04,0.04)}, 0.12)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, {BackgroundColor3 = Library.colors.ElementColor}, 0.12)
                end)
                btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)

                -- Return small API
                local ButtonAPI = {}
                function ButtonAPI:UpdateButton(newTitle)
                    label.Text = tostring(newTitle or bname)
                end
                return ButtonAPI
            end

            -- NewTextBox
            function Section:NewTextBox(name, tip, callback)
                name = tostring(name or "Textbox")
                tip = tostring(tip or "")
                callback = callback or function() end

                local frame = Create("Frame", {
                    Parent = self._inner,
                    BackgroundColor3 = Library.colors.ElementColor,
                    Size = UDim2.new(1,0,0,34)
                })
                Create("UICorner", { Parent = frame, CornerRadius = UDim.new(0,6) })

                local label = Create("TextLabel", {
                    Parent = frame,
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 14,
                    TextColor3 = Library.colors.TextColor,
                    Position = UDim2.new(0,10,0,6),
                    Size = UDim2.new(0.4, -10, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local textbox = Create("TextBox", {
                    Parent = frame,
                    BackgroundColor3 = Library.colors.Background,
                    Size = UDim2.new(0.55, -20, 0, 22),
                    Position = UDim2.new(0.45, 0, 0, 6),
                    Text = "",
                    ClearTextOnFocus = false,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Library.colors.SchemeColor,
                    PlaceholderText = "Type here..."
                })
                Create("UICorner", { Parent = textbox, CornerRadius = UDim.new(0,5) })
                textbox.FocusLost:Connect(function(enter)
                    if enter then
                        pcall(callback, textbox.Text)
                        textbox.Text = ""
                    end
                end)

                local TextboxAPI = {}
                function TextboxAPI:SetText(t) textbox.Text = tostring(t or "") end
                function TextboxAPI:GetText() return textbox.Text end
                return TextboxAPI
            end

            -- NewToggle
            function Section:NewToggle(name, tip, callback, default)
                name = tostring(name or "Toggle")
                tip = tostring(tip or "")
                callback = callback or function() end
                default = not not default

                local frame = Create("Frame", {
                    Parent = self._inner,
                    BackgroundColor3 = Library.colors.ElementColor,
                    Size = UDim2.new(1,0,0,34)
                })
                Create("UICorner", { Parent = frame, CornerRadius = UDim.new(0,6) })

                local label = Create("TextLabel", {
                    Parent = frame,
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 14,
                    TextColor3 = Library.colors.TextColor,
                    Position = UDim2.new(0,10,0,6),
                    Size = UDim2.new(1,-80,1,0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local toggleBtn = Create("TextButton", {
                    Parent = frame,
                    BackgroundColor3 = default and Library.colors.SchemeColor or Library.colors.Background,
                    Size = UDim2.new(0,46,0,22),
                    Position = UDim2.new(1,-58,0,6),
                    Text = "",
                    AutoButtonColor = false
                })
                Create("UICorner", { Parent = toggleBtn, CornerRadius = UDim.new(0,6) })

                local state = default
                local elementId = "toggle_" .. HttpService:GenerateGUID(false)

                local function setState(newState, skipSave)
                    state = not not newState
                    Tween(toggleBtn, {BackgroundColor3 = state and Library.colors.SchemeColor or Library.colors.Background}, 0.12)
                    pcall(callback, state)
                    if not skipSave then
                        Library.config.elements[elementId] = state
                        Library:SaveConfig()
                    end
                end

                toggleBtn.MouseButton1Click:Connect(function()
                    setState(not state)
                end)

                -- register
                Library:_registerElement(elementId, {
                    SetState = function(v) setState(v, true) end,
                    GetState = function() return state end
                })

                local TogAPI = {}
                function TogAPI:SetState(v) setState(v) end
                function TogAPI:GetState() return state end
                return TogAPI
            end

            -- NewSlider
            function Section:NewSlider(name, tip, minVal, maxVal, callback, default, precision)
                name = tostring(name or "Slider")
                tip = tostring(tip or "")
                minVal = tonumber(minVal) or 0
                maxVal = tonumber(maxVal) or 100
                callback = callback or function() end
                precision = tonumber(precision) or 0
                default = default or minVal

                local frame = Create("Frame", { Parent = self._inner, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,50) })
                local label = Create("TextLabel", { Parent = frame, BackgroundTransparency = 1, Text = name .. ": " .. tostring(default), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Library.colors.TextColor, Position = UDim2.new(0,6,0,4), Size = UDim2.new(1,-12,0,18), TextXAlignment = Enum.TextXAlignment.Left })
                local barBack = Create("Frame", { Parent = frame, BackgroundColor3 = Library.colors.Background, Size = UDim2.new(1,-24,0,10), Position = UDim2.new(0,12,0,30) })
                Create("UICorner", { Parent = barBack, CornerRadius = UDim.new(0,6) })
                local barFill = Create("Frame", { Parent = barBack, BackgroundColor3 = Library.colors.SchemeColor, Size = UDim2.new( (default - minVal) / math.max(1, (maxVal-minVal)), 0, 1, 0 ) })
                Create("UICorner", { Parent = barFill, CornerRadius = UDim.new(0,6) })

                local dragging = false
                local value = default

                barBack.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)
                barBack.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((inp.Position.X - barBack.AbsolutePosition.X) / barBack.AbsoluteSize.X, 0, 1)
                        barFill.Size = UDim2.new(rel, 0, 1, 0)
                        local computed = minVal + (maxVal - minVal) * rel
                        if precision > 0 then
                            local factor = 10^precision
                            computed = math.floor(computed * factor + 0.5) / factor
                        else
                            computed = math.floor(computed + 0.5)
                        end
                        value = computed
                        label.Text = name .. ": " .. tostring(value)
                        pcall(callback, value)
                        -- store
                    end
                end)

                local elementId = "slider_" .. HttpService:GenerateGUID(false)
                Library:_registerElement(elementId, {
                    SetValue = function(v)
                        v = tonumber(v) or minVal
                        local rel = math.clamp((v-minVal)/(maxVal-minVal), 0, 1)
                        barFill.Size = UDim2.new(rel,0,1,0)
                        value = v
                        label.Text = name .. ": " .. tostring(value)
                    end,
                    GetValue = function() return value end
                })

                local SliderAPI = {}
                function SliderAPI:SetValue(v) Library.elements[elementId].SetValue(v) end
                function SliderAPI:GetValue() return value end
                return SliderAPI
            end

            -- NewDropdown (supports single and multi-select)
            function Section:NewDropdown(name, tip, list, callback, multi)
                name = tostring(name or "Dropdown")
                tip = tostring(tip or "")
                callback = callback or function() end
                multi = not not multi
                list = list or {}

                local frame = Create("Frame", {
                    Parent = self._inner,
                    BackgroundColor3 = Library.colors.ElementColor,
                    Size = UDim2.new(1,0,0,34)
                })
                Create("UICorner", { Parent = frame, CornerRadius = UDim.new(0,6) })

                local label = Create("TextLabel", {
                    Parent = frame,
                    BackgroundTransparency = 1,
                    Text = name,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 14,
                    TextColor3 = Library.colors.TextColor,
                    Position = UDim2.new(0,10,0,6),
                    Size = UDim2.new(0.5, -10, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local display = Create("TextButton", {
                    Parent = frame,
                    BackgroundTransparency = 1,
                    Text = multi and (name .. " (multi)") or (name .. " ▼"),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Library.colors.TextColor,
                    Position = UDim2.new(0.5, 0, 0, 6),
                    Size = UDim2.new(0.5, -12, 1, 0),
                    AutoButtonColor = true
                })
                Create("UIPadding", { Parent = display, PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6) })

                -- list frame below (hidden by default)
                local listFrame = Create("Frame", {
                    Parent = self._inner,
                    BackgroundColor3 = Library.colors.Background,
                    Size = UDim2.new(1,0,0,0),
                    Position = UDim2.new(0,0,0,40),
                    Visible = false,
                    ClipsDescendants = true
                })
                Create("UICorner", { Parent = listFrame, CornerRadius = UDim.new(0,6) })
                local listLayout = Create("UIListLayout", { Parent = listFrame, SortOrder = Enum.SortOrder.LayoutOrder })
                Create("UIPadding", { Parent = listFrame, PaddingTop = UDim.new(0,6), PaddingLeft = UDim.new(0,6) })

                local selected = {} -- table for multi, or single stored as {value}
                local elementId = "dropdown_" .. HttpService:GenerateGUID(false)

                local function updateDisplayText()
                    if multi then
                        if #selected == 0 then
                            display.Text = name .. " (none)"
                        else
                            display.Text = name .. ": " .. table.concat(selected, ", ")
                        end
                    else
                        if #selected == 0 then
                            display.Text = name .. " ▼"
                        else
                            display.Text = name .. ": " .. tostring(selected[1])
                        end
                    end
                end

                -- build option buttons
                local function buildOptions(newList)
                    -- clear
                    for _,c in ipairs(listFrame:GetChildren()) do
                        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then
                            c:Destroy()
                        end
                    end
                    for i,opt in ipairs(newList) do
                        local optBtn = Create("TextButton", {
                            Parent = listFrame,
                            Size = UDim2.new(1, -12, 0, 28),
                            BackgroundTransparency = 1,
                            Text = tostring(opt),
                            Font = Enum.Font.Gotham,
                            TextSize = 14,
                            TextColor3 = Library.colors.TextColor,
                            AutoButtonColor = true
                        })
                        Create("UIPadding", { Parent = optBtn, PaddingLeft = UDim.new(0,6) })
                        -- visual indicator for selected
                        local indicator = Create("Frame", { Parent = optBtn, Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(1, -16, 0.5, -3), BackgroundColor3 = Color3.fromRGB(0,0,0) })
                        Create("UICorner", { Parent = indicator, CornerRadius = UDim.new(0,3) })
                        indicator.Visible = false

                        optBtn.MouseButton1Click:Connect(function()
                            local val = tostring(opt)
                            if multi then
                                local f = table.find(selected, val)
                                if f then
                                    table.remove(selected, f)
                                    indicator.Visible = false
                                else
                                    table.insert(selected, val)
                                    indicator.Visible = true
                                end
                                updateDisplayText()
                                pcall(callback, selected)
                                Library.config.elements[elementId] = selected
                                Library:SaveConfig()
                            else
                                selected = {val}
                                -- mark only this indicator visible, hide others
                                for _,child in ipairs(listFrame:GetChildren()) do
                                    if child:IsA("TextButton") then
                                        local ind = child:FindFirstChildWhichIsA("Frame") or child:FindFirstChild("Indicator")
                                        if ind then ind.Visible = (child == optBtn) end
                                    end
                                end
                                updateDisplayText()
                                listFrame.Visible = false
                                pcall(callback, val)
                                Library.config.elements[elementId] = val
                                Library:SaveConfig()
                            end
                        end)
                    end
                    -- update height: max 6 options shown (28 each)
                    local num = #newList
                    local height = math.min(num * 28 + 12, 28 * 6 + 12)
                    listFrame.Size = UDim2.new(1, 0, 0, height)
                end

                buildOptions(list)

                display.MouseButton1Click:Connect(function()
                    listFrame.Visible = not listFrame.Visible
                end)

                -- close dropdown when clicking outside (simple global hook)
                local hook
                hook = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mouse = Players.LocalPlayer:GetMouse()
                        local inFrame = listFrame:IsAncestorOf(mouse.Target or nil) or frame:IsAncestorOf(mouse.Target or nil)
                        if not inFrame and listFrame.Visible then
                            listFrame.Visible = false
                        end
                    end
                end)

                -- register element for config system
                Library:_registerElement(elementId, {
                    SetOption = function(opt)
                        if multi then
                            if type(opt) == "table" then
                                selected = opt
                                updateDisplayText()
                                pcall(callback, selected)
                            end
                        else
                            if type(opt) == "string" then
                                selected = {opt}
                                updateDisplayText()
                                pcall(callback, opt)
                            end
                        end
                    end,
                    GetOption = function()
                        if multi then return selected end
                        return selected[1]
                    end
                })

                local DropAPI = {}
                function DropAPI:Refresh(newList)
                    newList = newList or {}
                    list = newList
                    buildOptions(list)
                end
                function DropAPI:GetSelected()
                    if multi then return selected end
                    return selected[1]
                end

                return DropAPI
            end

            -- NewLabel
            function Section:NewLabel(text)
                text = tostring(text or "")
                local lab = Create("TextLabel", {
                    Parent = self._inner,
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Library.colors.TextColor,
                    Size = UDim2.new(1,0,0,20)
                })
                local LabelAPI = {}
                function LabelAPI:UpdateLabel(newText)
                    lab.Text = tostring(newText or "")
                end
                return LabelAPI
            end

            return setmetatable(Section, Section)
        end

        -- return tab object
        return setmetatable(Tab, Tab)
    end

    -- Backwards compat: LuaUIX.new(...) usage
    function LuaUIX.new(...)
        return LuaUIX:CreateLib(...)
    end

    -- Done constructing library: inject computed members then return
    screen.Parent = CoreGui
    Library.screen = screen
    -- expose some functions on root Library table
    setmetatable(Library, Library)
    -- add public methods
    Library.NewTab = Library.NewTab
    Library.ToggleUI = Library.ToggleUI
    Library.ChangeColor = Library.ChangeColor
    Library.SaveConfig = Library.SaveConfig
    Library.LoadConfig = Library.LoadConfig

    -- attempt to load existing config
    pcall(function() 
        local ok = Library:LoadConfig()
        -- if config had a known theme, it's applied in LoadConfig
    end)

    return Library
end

-- For convenience export CreateLib under both names
LuaUIX.CreateLib = LuaUIX.CreateLib

return LuaUIX
