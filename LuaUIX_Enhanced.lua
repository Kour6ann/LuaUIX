-- LuaUIX_Enhanced.lua
-- Version 1.0.0
-- Single-file UI library that recreates the look from the provided screenshot:
-- - Left sidebar tabs with icons
-- - Rounded main window, titlebar with minimize & close
-- - Theme pill buttons at top
-- - Scrollable content area with "cards" and toggles
-- - API: CreateLib, NewTab, NewSection, NewToggle, NewButton
-- Designed for exploit executors (uses CoreGui/PlayerGui fallback)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Library = {}
Library.__index = Library

-- ====== Settings / Theme Colors (matching screenshot style) ======
local Themes = {
    Dark = {
        Background = Color3.fromRGB(27, 28, 37),
        Window = Color3.fromRGB(26, 28, 37),
        Sidebar = Color3.fromRGB(22, 24, 33),
        Card = Color3.fromRGB(34,36,48),
        Accent = Color3.fromRGB(56,172,212),
        Accent2 = Color3.fromRGB(147,51,158),
        Text = Color3.fromRGB(220,224,230),
        Muted = Color3.fromRGB(151,158,170),
        Soft = Color3.fromRGB(36,40,50),
        Highlight = Color3.fromRGB(66, 142, 165)
    }
}
local DefaultTheme = "Dark"

-- ====== Utility helpers ======
local function safeParent(gui)
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then
        pcall(function() gui.Parent = core end)
        if gui.Parent then return true end
    end
    local lp = Players.LocalPlayer
    if not lp then
        lp = Players.PlayerAdded:Wait()
    end
    local pg = lp:WaitForChild("PlayerGui")
    pcall(function() gui.Parent = pg end)
    return gui.Parent ~= nil
end

local function new(class, props)
    local inst = Instance.new(class)
    if props then
        for k,v in pairs(props) do
            if k == "Parent" then
                inst.Parent = v
            else
                pcall(function() inst[k] = v end)
            end
        end
    end
    return inst
end

local function applyTextStyle(lbl, size, bold)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = size or 14
    lbl.TextColor3 = Themes[DefaultTheme].Text
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    if bold then lbl.Font = Enum.Font.GothamBold end
end

-- Rounded shadow helper
local function addRounded(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = frame
    return corner
end

-- ====== Library API ======
-- Create base library/window
function Library.CreateLib(title, options)
    options = options or {}
    local themeName = options.Theme or DefaultTheme
    local theme = Themes[themeName] or Themes[DefaultTheme]

    local self = setmetatable({}, Library)
    self.Theme = theme
    self.Title = title or "LuaUIX Enhanced"
    self.Tabs = {}

    -- ScreenGui
    local screen = new("ScreenGui", {Name = "LuaUIX_Enhanced_ScreenGui", ResetOnSpawn = false})
    safeParent(screen)
    self.ScreenGui = screen

    -- root frame (centered)
    local root = new("Frame", {
        Name = "Root",
        Size = UDim2.new(0, 760, 0, 720),
        Position = UDim2.new(0.5, -380, 0.5, -360),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = theme.Window,
        BorderSizePixel = 0,
        Parent = screen
    })
    addRounded(root, 14)

    -- subtle outer shadow (using UIStroke and a darker border)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(10,10,15)
    stroke.Thickness = 1
    stroke.Parent = root
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Titlebar
    local titlebar = new("Frame", {
        Name = "Titlebar",
        Size = UDim2.new(1, 0, 0, 56),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(33, 34, 44),
        Parent = root
    })
    addRounded(titlebar, 12)

    local titleText = new("TextLabel", {
        Name = "TitleText",
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = " " .. self.Title .. " - v19.1",
        Parent = titlebar
    })
    applyTextStyle(titleText, 18, true)
    titleText.TextColor3 = theme.Text

    -- Minimize + Close buttons (styled)
    local btnClose = new("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 44, 0, 30),
        Position = UDim2.new(1, -58, 0, 12),
        AnchorPoint = Vector2.new(0,0),
        BackgroundColor3 = Color3.fromRGB(226, 86, 96),
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = titlebar
    })
    addRounded(btnClose, 8)

    local btnMin = new("TextButton", {
        Name = "MinBtn",
        Size = UDim2.new(0, 44, 0, 30),
        Position = UDim2.new(1, -110, 0, 12),
        AnchorPoint = Vector2.new(0,0),
        BackgroundColor3 = Color3.fromRGB(229, 105, 97),
        Text = "–",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255,255,255),
        Parent = titlebar
    })
    addRounded(btnMin, 8)

    -- left sidebar
    local sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 180, 1, -56),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = root
    })
    addRounded(sidebar, 12)

    -- left bar inner padding and list
    local sideList = new("Frame", {
        Name = "SideList",
        Size = UDim2.new(1, -18, 1, -30),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundTransparency = 1,
        Parent = sidebar
    })

    local sideLayout = new("UIListLayout", {Parent = sideList})
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Padding = UDim.new(0, 12)

    -- function to create a tab button in sidebar
    local function makeTabButton(text, icon)
        local container = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = Color3.fromRGB(42,46,59),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = sideList
        })
        addRounded(container, 10)

        local iconLbl = new("TextLabel", {
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Text = icon or "◼",
            Parent = container
        })
        iconLbl.Font = Enum.Font.Gotham
        iconLbl.TextSize = 18
        iconLbl.TextColor3 = theme.Accent

        local label = new("TextLabel", {
            Size = UDim2.new(1, -64, 1, 0),
            Position = UDim2.new(0, 56, 0, 0),
            BackgroundTransparency = 1,
            Text = text or "Tab",
            Parent = container
        })
        applyTextStyle(label, 15, true)
        label.TextColor3 = theme.Text

        return container
    end

    -- create a content area on the right
    local contentArea = new("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -200, 1, -56),
        Position = UDim2.new(0, 200, 0, 56),
        BackgroundTransparency = 1,
        Parent = root
    })

    -- top-right area (theme pills)
    local topRight = new("Frame", {
        Name = "TopRight",
        Size = UDim2.new(1, -200, 0, 96),
        Position = UDim2.new(0, 200, 0, 8),
        BackgroundTransparency = 1,
        Parent = root
    })

    -- holder for theme pills
    local pillHolder = new("Frame", {
        Name = "PillHolder",
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 24, 0, 10),
        BackgroundTransparency = 1,
        Parent = topRight
    })

    local pillLayout = Instance.new("UIListLayout", pillHolder)
    pillLayout.FillDirection = Enum.FillDirection.Horizontal
    pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pillLayout.Padding = UDim.new(0, 14)

    local function makePill(text, bg, textColor)
        local p = new("TextButton", {
            Size = UDim2.new(0, 120, 0, 40),
            BackgroundColor3 = bg,
            Text = text,
            AutoButtonColor = false,
            Parent = pillHolder
        })
        local c = addRounded(p, 10)
        p.Font = Enum.Font.GothamBold
        p.TextSize = 14
        p.TextColor3 = textColor or theme.Text
        return p
    end

    -- add sample pills (Dark, Light, Midnight, Custom)
    local pillDark = makePill("Dark", theme.Soft, theme.Text)
    local pillLight = makePill("Light", Color3.fromRGB(250,250,250), Color3.fromRGB(24,24,24))
    local pillMidnight = makePill("Midnight", Color3.fromRGB(10,10,20), Color3.fromRGB(180,200,220))
    local pillCustom = makePill("Custom", theme.Accent2, Color3.fromRGB(255,220,80))

    -- Scrollable container for the main content on the right
    local scrollFrame = new("ScrollingFrame", {
        Name = "MainScroll",
        Size = UDim2.new(1, -28, 1, -120),
        Position = UDim2.new(0, 12, 0, 120),
        BackgroundTransparency = 1,
        ScrollBarThickness = 8,
        Parent = contentArea
    })
    local canvas = Instance.new("UIListLayout", scrollFrame)
    canvas.SortOrder = Enum.SortOrder.LayoutOrder
    canvas.Padding = UDim.new(0, 18)

    -- style the scrollbar minimally
    local uiStroke = Instance.new("UIStroke", root)
    uiStroke.Thickness = 0.7
    uiStroke.Color = Color3.fromRGB(18,18,24)
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- helper to create a "card" (rounded panel with title and body)
    local function makeCard(title, bodyText)
        local card = new("Frame", {
            Size = UDim2.new(1, -24, 0, 160),
            BackgroundColor3 = theme.Card,
            BorderSizePixel = 0,
            Parent = scrollFrame
        })
        addRounded(card, 12)

        local header = new("TextLabel", {
            Size = UDim2.new(1, -24, 0, 36),
            Position = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Text = title,
            Parent = card
        })
        applyTextStyle(header, 16, true)
        header.TextColor3 = theme.Accent

        local body = new("TextLabel", {
            Size = UDim2.new(1, -36, 0, 84),
            Position = UDim2.new(0, 12, 0, 48),
            BackgroundTransparency = 1,
            Text = bodyText or "",
            TextWrapped = true,
            Parent = card
        })
        applyTextStyle(body, 14, false)
        body.TextColor3 = theme.Muted

        return card
    end

    -- toggle widget creator (stylish pill)
    local function createToggle(parent, default)
        local current = default and true or false
        local container = new("Frame", {
            Size = UDim2.new(0, 96, 0, 36),
            BackgroundTransparency = 1,
            Parent = parent
        })
        local pill = new("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = current and theme.Accent or theme.Soft,
            Text = (current and "On" or "Off"),
            AutoButtonColor = false,
            Parent = container
        })
        addRounded(pill, 18)
        pill.Font = Enum.Font.GothamBold
        pill.TextSize = 14
        pill.TextColor3 = Color3.fromRGB(250,250,250)

        function container:GetValue()
            return current
        end
        function container:SetValue(v)
            current = not not v
            pill.BackgroundColor3 = current and theme.Accent or theme.Soft
            pill.Text = current and "On" or "Off"
        end

        pill.MouseButton1Click:Connect(function()
            container:SetValue(not current)
        end)

        return container
    end

    -- Public API functions for building UI (Tab / Section / Widgets)
    function self:NewTab(name, icon)
        local tabBtn = makeTabButton(name, icon)
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = name .. "_Content"
        contentFrame.Size = UDim2.new(1, -28, 1, -0)
        contentFrame.Position = UDim2.new(0, 12, 0, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Visible = false
        contentFrame.Parent = contentArea

        -- keep content scrollable separate
        -- create inner scroll for tab content
        local innerScroll = Instance.new("ScrollingFrame", contentFrame)
        innerScroll.Name = "Scroll"
        innerScroll.Size = UDim2.new(1, -12, 1, -12)
        innerScroll.Position = UDim2.new(0, 6, 0, 6)
        innerScroll.BackgroundTransparency = 1
        innerScroll.ScrollBarThickness = 8

        local list = Instance.new("UIListLayout", innerScroll)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 18)

        -- Tab object to return
        local tabObj = {}
        tabObj.Name = name
        tabObj.Button = tabBtn
        tabObj.Content = innerScroll
        tabObj.Sections = {}

        -- clicking tab: hide others, show this
        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(self.Tabs) do
                t.Button.BackgroundColor3 = Color3.fromRGB(42,46,59)
                t.Content.Visible = false
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(30,36,55)
            innerScroll.Visible = true
        end)

        -- if first tab, open
        if #self.Tabs == 0 then
            tabBtn.BackgroundColor3 = Color3.fromRGB(30,36,55)
            innerScroll.Visible = true
        end

        function tabObj:NewSection(title)
            local sectionFrame = Instance.new("Frame", innerScroll)
            sectionFrame.Size = UDim2.new(1, -24, 0, 160)
            sectionFrame.BackgroundColor3 = Color3.fromRGB(23,25,34)
            sectionFrame.BorderSizePixel = 0
            addRounded(sectionFrame, 12)

            local header = new("TextLabel", {
                Text = title or "Section",
                BackgroundTransparency = 1,
                Parent = sectionFrame
            })
            header.Size = UDim2.new(1, -24, 0, 30)
            header.Position = UDim2.new(0, 12, 0, 8)
            applyTextStyle(header, 16, true)
            header.TextColor3 = theme.Highlight

            -- Inner container for controls
            local inner = Instance.new("Frame", sectionFrame)
            inner.Size = UDim2.new(1, -24, 1, -48)
            inner.Position = UDim2.new(0, 12, 0, 44)
            inner.BackgroundTransparency = 1

            local secObj = {Frame = sectionFrame, Inner = inner, Widgets = {}}

            function secObj:NewToggle(text, default, callback)
                local row = Instance.new("Frame", inner)
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundTransparency = 1

                local lbl = new("TextLabel", {
                    Text = text or "Toggle",
                    Size = UDim2.new(0.7, 0, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    Parent = row
                })
                applyTextStyle(lbl, 14, false)
                lbl.TextColor3 = theme.Text

                local toggle = createToggle(row, default)
                toggle:SetValue(default)
                toggleFrame = toggle
                toggle.Parent = row
                toggle.Position = UDim2.new(1, -110, 0, 2)
                toggle.AnchorPoint = Vector2.new(1,0)

                if callback then
                    -- connect to value changes by wrapping SetValue (non-intrusive)
                    local oldSet = toggle.SetValue
                    function toggle:SetValue(v)
                        oldSet(self, v)
                        pcall(function() callback(v) end)
                    end
                end

                table.insert(secObj.Widgets, toggle)
                return toggle
            end

            function secObj:NewButton(text, callback)
                local btn = new("TextButton", {
                    Text = text or "Button",
                    Size = UDim2.new(0.45, 0, 0, 36),
                    BackgroundColor3 = theme.Highlight,
                    BorderSizePixel = 0,
                    Parent = inner
                })
                addRounded(btn, 8)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 14
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                btn.MouseButton1Click:Connect(function()
                    pcall(function() callback() end)
                end)
                table.insert(secObj.Widgets, btn)
                return btn
            end

            table.insert(self.Tabs, tabObj)
            table.insert(tabObj.Sections, secObj)
            return secObj
        end

        table.insert(self.Tabs, tabObj)
        return tabObj
    end

    -- theme pill interactions (basic)
    pillDark.MouseButton1Click:Connect(function()
        -- no-op; it's the default look
    end)
    pillLight.MouseButton1Click:Connect(function()
        -- quick fake "light" override (not full re-theme)
        root.BackgroundColor3 = Color3.fromRGB(246,246,246)
        titlebar.BackgroundColor3 = Color3.fromRGB(246,246,246)
    end)

    -- close/minimize behavior
    btnClose.MouseButton1Click:Connect(function()
        pcall(function() screen:Destroy() end)
    end)
    local minimized = false
    btnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            -- collapse content area
            contentArea.Visible = false
            sidebar.Visible = false
            titlebar.Size = UDim2.new(1, 0, 0, 56)
            root.Size = UDim2.new(0, 360, 0, 84)
        else
            contentArea.Visible = true
            sidebar.Visible = true
            titlebar.Size = UDim2.new(1, 0, 0, 56)
            root.Size = UDim2.new(0, 760, 0, 720)
        end
    end)

    -- minimal drag for window (click+drag titlebar)
    do
        local dragging = false
        local dragStart = nil
        local startPos = nil
        titlebar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = root.Position
            end
        end)
        titlebar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- expose some internals for further customization
    self.ScreenGui = screen
    self.Root = root
    self.Sidebar = sidebar
    self.ContentArea = contentArea

    return self
end

return Library
