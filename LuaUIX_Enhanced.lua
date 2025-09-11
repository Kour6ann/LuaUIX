-- LuaUIX_Fixed.lua
-- Rewritten, double-checked UI lib: tabs, scrolling, real widgets, inline+float dropdown fallback.
-- Usage: local LuaUIX = loadstring(game:HttpGet("URL"))(); local W = LuaUIX:CreateWindow{Title="Demo"}; local t = W:CreateTab("Main")

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Filesystem guards
local canFile = type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function"
local SAVE_FILE = "LuaUIX_Settings.json"

-- ScreenGuis
local function makeScreenGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        sg.Parent = LocalPlayer.PlayerGui
    else
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
    end
    return sg
end

local RootGui = makeScreenGui("LuaUIX_Root")
local FloatGui = makeScreenGui("LuaUIX_Float")
local NotifGui = makeScreenGui("LuaUIX_Notifs")

-- Utilities
local function safeTween(inst, info, props) pcall(function() TweenService:Create(inst, info, props):Play() end) end
local function applyUICorner(obj, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0,6); c.Parent = obj; return c end
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end

-- Persistence
local settingsStore = {}
local function loadSettings()
    if not canFile then return end
    pcall(function()
        if isfile(SAVE_FILE) then
            settingsStore = HttpService:JSONDecode(readfile(SAVE_FILE)) or {}
        end
    end)
end
local function saveSettings()
    if not canFile then return end
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode(settingsStore))
    end)
end
loadSettings()

-- Notifications
do
    local queue = {}
    local running = false
    local function process()
        if running then return end
        running = true
        while #queue > 0 do
            local n = table.remove(queue, 1)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 320, 0, 72)
            frame.Position = UDim2.new(1, 340, 0, 18)
            frame.AnchorPoint = Vector2.new(1,0)
            frame.BackgroundColor3 = Color3.fromRGB(34,34,34)
            frame.Parent = NotifGui
            applyUICorner(frame, UDim.new(0,8))
            frame.ZIndex = 200

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.new(0,12,0,8)
            title.Size = UDim2.new(1,-24,0,18)
            title.Text = n.title or "Notice"
            title.Font = Enum.Font.GothamBold
            title.TextSize = 14
            title.TextColor3 = Color3.fromRGB(230,230,230)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = frame

            local msg = Instance.new("TextLabel")
            msg.BackgroundTransparency = 1
            msg.Position = UDim2.new(0,12,0,26)
            msg.Size = UDim2.new(1,-24,0,40)
            msg.Text = n.msg or ""
            msg.Font = Enum.Font.Gotham
            msg.TextSize = 12
            msg.TextColor3 = Color3.fromRGB(190,190,190)
            msg.TextXAlignment = Enum.TextXAlignment.Left
            msg.TextYAlignment = Enum.TextYAlignment.Top
            msg.TextWrapped = true
            msg.Parent = frame

            if n.type == "success" then title.TextColor3 = Color3.fromRGB(120,200,120)
            elseif n.type == "warning" then title.TextColor3 = Color3.fromRGB(235,200,80)
            elseif n.type == "error" then title.TextColor3 = Color3.fromRGB(220,100,100) end

            safeTween(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -20, 0, 18)})
            task.wait(n.duration or 3.6)
            safeTween(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 340, 0, 18)})
            task.wait(0.26)
            frame:Destroy()
        end
        running = false
    end

    function LuaUIX.Notify(title, msg, duration, typ)
        table.insert(queue, {title = title, msg = msg, duration = duration, type = typ})
        spawn(process)
    end
end

-- Tooltip helper (FloatGui)
function LuaUIX.AddTooltip(guiObj, text)
    if not guiObj or not guiObj:IsA("GuiObject") then return end
    guiObj.MouseEnter:Connect(function()
        local tip = Instance.new("TextLabel")
        tip.Size = UDim2.new(0, 180, 0, 36)
        local abs = guiObj.AbsolutePosition
        tip.Position = UDim2.new(0, abs.X, 0, abs.Y + guiObj.AbsoluteSize.Y + 6)
        tip.BackgroundColor3 = Color3.fromRGB(45,45,45)
        tip.TextColor3 = Color3.fromRGB(230,230,230)
        tip.Text = text
        tip.TextWrapped = true
        tip.Font = Enum.Font.Gotham
        tip.TextSize = 12
        tip.Parent = FloatGui
        applyUICorner(tip, UDim.new(0,6))
        tip.ZIndex = 300
        local conn; conn = guiObj.MouseLeave:Connect(function() tip:Destroy(); conn:Disconnect() end)
    end)
end

-- Helper: decide float fallback
local function useFloatFallback(containerFrame, neededHeight)
    if containerFrame.ClipsDescendants then return true end
    local absPos = containerFrame.AbsolutePosition
    local absSize = containerFrame.AbsoluteSize
    local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
    local below = viewportSize.Y - (absPos.Y + absSize.Y)
    if below < neededHeight then return true end
    return false
end

-- CreateWindow: returns window object with CreateTab
function LuaUIX:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "LuaUIX"
    local size = opts.Size or UDim2.new(0, 600, 0, 420)

    local window = {}
    window.__index = window

    -- root frame
    local main = Instance.new("Frame")
    main.Name = "LuaUIX_Window"
    main.Size = size
    main.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.BackgroundColor3 = Color3.fromRGB(30,30,30)
    main.Parent = RootGui
    applyUICorner(main, UDim.new(0,10))
    main.ZIndex = 100
    main.ClipsDescendants = false

    -- top bar
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,36)
    top.Position = UDim2.new(0,0,0,0)
    top.BackgroundTransparency = 1
    top.Parent = main

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 16, 0, 6)
    titleLabel.Size = UDim2.new(0.6, 0, 0, 24)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(235,235,235)
    titleLabel.Text = title
    titleLabel.Parent = top

    -- close btn
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,28,0,24)
    close.Position = UDim2.new(1, -36, 0, 6)
    close.Text = "X"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.Parent = top
    close.BackgroundColor3 = Color3.fromRGB(50,50,50)
    close.TextColor3 = Color3.fromRGB(220,120,120)
    applyUICorner(close, UDim.new(1,0))
    close.MouseEnter:Connect(function() safeTween(close, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70,70,70)}) end)
    close.MouseLeave:Connect(function() safeTween(close, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50,50,50)}) end)
    close.MouseButton1Click:Connect(function() pcall(function() main:Destroy() end) end)

    -- left tab column
    local tabCol = Instance.new("Frame")
    tabCol.Size = UDim2.new(0,140,1,-56)
    tabCol.Position = UDim2.new(0,12,0,44)
    tabCol.BackgroundTransparency = 1
    tabCol.Parent = main

    local tabList = Instance.new("UIListLayout")
    tabList.Parent = tabCol
    tabList.Padding = UDim.new(0,8)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder

    -- content area (right)
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -172, 1, -56)
    contentArea.Position = UDim2.new(0,164,0,44)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = main
    contentArea.ClipsDescendants = false

    -- drag logic
    do
        local dragging, dragStart, startPos, dragInput
        local function update(input)
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = main.Position
                local conn; conn = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging=false; conn:Disconnect() end end)
            end
        end)
        top.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput = input end end)
        UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)
    end

    -- internal storage
    local tabs = {}
    local activeTab = nil

    -- CreateTab
    function window:CreateTab(name)
        local tabObj = {}
        tabObj.__index = tabObj

        -- layout order management per tab (ensures inline options get placed after header)
        local nextOrder = 1

        -- tab button
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,28)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = name
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.Parent = tabCol
        btn.LayoutOrder = #tabs + 1
        applyUICorner(btn, UDim.new(0,6))

        -- scroll content for this tab
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.Position = UDim2.new(0, 0, 0, 0)
        scroll.BackgroundTransparency = 1
        scroll.Parent = contentArea
        scroll.Visible = false
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 6
        scroll.ClipsDescendants = false

        local layout = Instance.new("UIListLayout")
        layout.Parent = scroll
        layout.Padding = UDim.new(0,8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0,8)
        padding.PaddingLeft = UDim.new(0,8)
        padding.PaddingRight = UDim.new(0,8)
        padding.Parent = scroll

        -- tab switching
        btn.MouseButton1Click:Connect(function()
            if activeTab and activeTab._scroll then
                activeTab._scroll.Visible = false
                activeTab._btn.TextColor3 = Color3.fromRGB(200,200,200)
            end
            scroll.Visible = true
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            activeTab = tabObj
        end)

        -- auto-open first tab
        if not activeTab then
            btn:MouseButton1Click()
        end

        -- helper to reserve layout order numbers
        local function reserveOrders(n)
            local start = nextOrder
            nextOrder = nextOrder + n
            return start
        end

        -- WIDGETS: All widgets parent to scroll and use LayoutOrder values to keep order
        function tabObj:CreateLabel(text)
            local o = Instance.new("TextLabel")
            o.Size = UDim2.new(1,0,0,20)
            o.BackgroundTransparency = 1
            o.Text = text or ""
            o.Font = Enum.Font.Gotham
            o.TextSize = 14
            o.TextColor3 = Color3.fromRGB(220,220,220)
            o.TextXAlignment = Enum.TextXAlignment.Left
            o.Parent = scroll
            o.LayoutOrder = reserveOrders(1)
            return o
        end

        function tabObj:CreateButton(text, callback)
            local o = Instance.new("TextButton")
            o.Size = UDim2.new(1,0,0,36)
            o.BackgroundColor3 = Color3.fromRGB(55,55,55)
            o.Font = Enum.Font.GothamBold
            o.TextSize = 14
            o.Text = text or "Button"
            o.TextColor3 = Color3.fromRGB(245,245,245)
            applyUICorner(o, UDim.new(0,6))
            o.Parent = scroll
            o.LayoutOrder = reserveOrders(1)
            o.MouseEnter:Connect(function() safeTween(o, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(75,75,75)}) end)
            o.MouseLeave:Connect(function() safeTween(o, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(55,55,55)}) end)
            o.MouseButton1Click:Connect(function() pcall(callback) end)
            return o
        end

        function tabObj:CreateToggle(text, default, callback)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,36)
            container.BackgroundColor3 = Color3.fromRGB(40,40,40)
            applyUICorner(container, UDim.new(0,6))
            container.Parent = scroll
            container.LayoutOrder = reserveOrders(1)

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(0.7,0,1,0)
            lbl.Position = UDim2.new(0,10,0,0)
            lbl.Text = text or "Toggle"
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(230,230,230)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = container

            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0.25, -14, 0, 22)
            sw.Position = UDim2.new(0.7, 10, 0.5, -11)
            sw.BackgroundColor3 = default and Color3.fromRGB(90,160,90) or Color3.fromRGB(80,80,80)
            sw.Font = Enum.Font.GothamBold
            sw.TextSize = 13
            sw.Text = default and "ON" or "OFF"
            sw.TextColor3 = Color3.fromRGB(240,240,240)
            applyUICorner(sw, UDim.new(0,6))
            sw.Parent = container

            local state = default or false
            sw.MouseButton1Click:Connect(function()
                state = not state
                sw.Text = state and "ON" or "OFF"
                sw.BackgroundColor3 = state and Color3.fromRGB(90,160,90) or Color3.fromRGB(80,80,80)
                pcall(callback, state)
            end)

            return {
                Set = function(s) state = s; sw.Text = s and "ON" or "OFF"; sw.BackgroundColor3 = s and Color3.fromRGB(90,160,90) or Color3.fromRGB(80,80,80) end,
                Get = function() return state end,
                Instance = container
            }
        end

        function tabObj:CreateTextbox(placeholder, callback, validation)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,54)
            container.BackgroundTransparency = 1
            container.Parent = scroll
            container.LayoutOrder = reserveOrders(1)

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1,0,0,18)
            label.Position = UDim2.new(0,0,0,0)
            label.Text = placeholder or ""
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1,0,0,30)
            box.Position = UDim2.new(0,0,0,22)
            box.BackgroundColor3 = Color3.fromRGB(42,42,42)
            box.TextColor3 = Color3.fromRGB(230,230,230)
            box.PlaceholderText = ""
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.Parent = container
            applyUICorner(box, UDim.new(0,6))

            box.FocusLost:Connect(function()
                local ok = true
                if validation then
                    local s, res = pcall(function() return validation(box.Text) end)
                    ok = s and res
                end
                if not ok then
                    safeTween(box, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(90,40,40)})
                    task.wait(0.45)
                    safeTween(box, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(42,42,42)})
                else
                    pcall(callback, box.Text)
                end
            end)

            return {
                SetText = function(t) box.Text = t end,
                GetText = function() return box.Text end,
                Instance = container
            }
        end

        function tabObj:CreateKeybind(text, defaultKey, callback)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,36)
            container.BackgroundColor3 = Color3.fromRGB(40,40,40)
            applyUICorner(container, UDim.new(0,6))
            container.Parent = scroll
            container.LayoutOrder = reserveOrders(1)

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(0.6,0,1,0)
            lbl.Position = UDim2.new(0,10,0,0)
            lbl.Text = text or "Keybind"
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(230,230,230)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = container

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.35, -10, 0, 24)
            btn.Position = UDim2.new(0.6, 10, 0.5, -12)
            btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(240,240,240)
            applyUICorner(btn, UDim.new(0,6))
            btn.Parent = container

            local current = defaultKey or Enum.KeyCode.F
            btn.Text = tostring(current):gsub("Enum.KeyCode.", "")

            local conn
            btn.MouseButton1Click:Connect(function()
                btn.Text = "..."
                btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
                conn = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        current = inp.KeyCode
                        btn.Text = tostring(current):gsub("Enum.KeyCode.", "")
                        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
                        pcall(callback, current)
                        conn:Disconnect()
                    end
                end)
            end)

            return {
                Set = function(k) current = k; btn.Text = tostring(k):gsub("Enum.KeyCode.", "") end,
                Get = function() return current end,
                Instance = container
            }
        end

        function tabObj:CreateSlider(text, min, max, default, callback)
            min = min or 0; max = max or 100; default = default or min
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,48)
            container.BackgroundTransparency = 1
            container.Parent = scroll
            container.LayoutOrder = reserveOrders(1)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6,0,0,18)
            label.BackgroundTransparency = 1
            label.Text = text or "Slider"
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container

            local valLbl = Instance.new("TextLabel")
            valLbl.Size = UDim2.new(0.4,-10,0,18)
            valLbl.Position = UDim2.new(0.6,10,0,0)
            valLbl.BackgroundTransparency = 1
            valLbl.Text = tostring(default)
            valLbl.Font = Enum.Font.Gotham
            valLbl.TextSize = 13
            valLbl.TextColor3 = Color3.fromRGB(200,200,200)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.Parent = container

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1,0,0,12)
            barBg.Position = UDim2.new(0,0,0,26)
            barBg.BackgroundColor3 = Color3.fromRGB(55,55,55)
            applyUICorner(barBg, UDim.new(0,6))
            barBg.Parent = container

            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new((default-min)/(max-min),0,1,0)
            barFill.BackgroundColor3 = Color3.fromRGB(100,100,230)
            barFill.Parent = barBg
            applyUICorner(barFill, UDim.new(0,6))

            local dragging = false
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
            end)
            barBg.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local rel = clamp((input.Position.X - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X, 0,1)
                    local v = math.floor(min + rel*(max-min) + 0.5)
                    barFill.Size = UDim2.new(rel,0,1,0)
                    valLbl.Text = tostring(v)
                    pcall(callback, v)
                end
            end)

            return {
                Set = function(v) v = clamp(v,min,max); barFill.Size = UDim2.new((v-min)/(max-min),0,1,0); valLbl.Text = tostring(v) end,
                Get = function() return tonumber(valLbl.Text) end,
                Instance = container
            }
        end

        function tabObj:CreateDropdown(text, items, defaultIndex, callback)
            items = items or {}
            defaultIndex = defaultIndex or 1
            local headerOrder = reserveOrders(2) -- reserve two orders: header and inline options
            local header = Instance.new("Frame")
            header.Size = UDim2.new(1,0,0,36)
            header.BackgroundColor3 = Color3.fromRGB(40,40,40)
            applyUICorner(header, UDim.new(0,6))
            header.Parent = scroll
            header.LayoutOrder = headerOrder

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,-30,1,0)
            label.Position = UDim2.new(0,10,0,0)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. tostring(items[defaultIndex] or "")
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = header

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0,18,0,18)
            arrow.Position = UDim2.new(1,-26,0.5,-9)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.Font = Enum.Font.Gotham
            arrow.TextSize = 12
            arrow.TextColor3 = Color3.fromRGB(200,200,200)
            arrow.Parent = header

            -- click catcher (transparent button)
            local clicker = Instance.new("TextButton")
            clicker.Size = UDim2.new(1,0,1,0)
            clicker.BackgroundTransparency = 1
            clicker.Text = ""
            clicker.Parent = header

            -- inline options (sibling in scroll so layout works)
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(1,0,0,0)
            optionsFrame.BackgroundColor3 = Color3.fromRGB(42,42,42)
            optionsFrame.ClipsDescendants = true
            optionsFrame.Parent = scroll
            applyUICorner(optionsFrame, UDim.new(0,6))
            optionsFrame.LayoutOrder = headerOrder + 1

            local optionsLayout = Instance.new("UIListLayout")
            optionsLayout.Parent = optionsFrame
            optionsLayout.Padding = UDim.new(0,4)
            optionsFrame.Visible = false

            local current = defaultIndex
            local open = false

            local function updateLabel()
                label.Text = text .. ": " .. tostring(items[current] or "")
                pcall(callback, items[current], current)
            end

            local function closeInline()
                if open then
                    open = false
                    safeTween(arrow, TweenInfo.new(0.12), {Rotation = 0})
                    safeTween(optionsFrame, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,0)})
                    task.delay(0.16, function() optionsFrame.Visible = false end)
                end
            end

            local function openInline()
                optionsFrame.Visible = true
                local needed = #items * 30 + 8
                optionsFrame.Size = UDim2.new(1,0,0,needed)
                safeTween(arrow, TweenInfo.new(0.12), {Rotation = 180})
                open = true
            end

            local function openFloat()
                local f = Instance.new("Frame")
                f.BackgroundColor3 = Color3.fromRGB(42,42,42)
                f.Size = UDim2.new(0, 220, 0, #items*30 + 10)
                local abs = header.AbsolutePosition
                f.Position = UDim2.new(0, abs.X, 0, abs.Y + header.AbsoluteSize.Y + 6)
                f.Parent = FloatGui
                applyUICorner(f, UDim.new(0,6))
                f.ZIndex = 400

                for i,it in ipairs(items) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, -14, 0, 26)
                    b.Position = UDim2.new(0, 7, 0, (i-1)*30 + 6)
                    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
                    b.Text = it
                    b.Font = Enum.Font.Gotham
                    b.TextSize = 14
                    b.TextColor3 = Color3.fromRGB(230,230,230)
                    applyUICorner(b, UDim.new(0,4))
                    b.Parent = f
                    b.ZIndex = 410
                    b.MouseButton1Click:Connect(function()
                        current = i
                        updateLabel()
                        f:Destroy()
                    end)
                end

                local conn
                conn = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mx,my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
                        local pos = f.AbsolutePosition; local size = f.AbsoluteSize
                        if not (mx >= pos.X and mx <= pos.X+size.X and my >= pos.Y and my <= pos.Y+size.Y) then
                            f:Destroy()
                            conn:Disconnect()
                        end
                    end
                end)
            end

            clicker.MouseButton1Click:Connect(function()
                local needed = #items * 30 + 8
                if useFloatFallback(header, needed) then
                    openFloat()
                else
                    if open then closeInline() else openInline() end
                end
            end)

            -- populate inline options
            for i,it in ipairs(items) do
                local opt = Instance.new("TextButton")
                opt.Size = UDim2.new(1, -14, 0, 26)
                opt.Position = UDim2.new(0, 7, 0, (i-1)*30 + 6)
                opt.BackgroundColor3 = Color3.fromRGB(50,50,50)
                opt.Text = it
                opt.Font = Enum.Font.Gotham
                opt.TextSize = 14
                opt.TextColor3 = Color3.fromRGB(230,230,230)
                applyUICorner(opt, UDim.new(0,4))
                opt.Parent = optionsFrame
                opt.ZIndex = 120
                opt.MouseButton1Click:Connect(function()
                    current = i
                    updateLabel()
                    closeInline()
                end)
            end

            updateLabel()
            return {
                Set = function(idx) if idx>=1 and idx<=#items then current=idx; updateLabel() end end,
                Get = function() return current, items[current] end,
                Instance = header
            }
        end

        -- done building tab
        tabObj._btn = btn
        tabObj._scroll = scroll
        tabObj._name = name

        tabs[#tabs + 1] = tabObj
        return setmetatable(tabObj, tabObj)
    end

    function window:Toggle() main.Visible = not main.Visible end
    function window:Destroy() pcall(function() main:Destroy() end) end

    return setmetatable(window, window)
end

-- Expose Save/Load/Notify
function LuaUIX.Save() saveSettings() end
function LuaUIX.Load() loadSettings() end

return LuaUIX
