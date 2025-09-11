-- LuaUIX_PlusPlus.lua
-- Combined-inspired UI lib (Rayfield + Orion + Kavo + Luna + Ash)
-- Supports inline dropdown expansion (preferred) and FloatGui fallback when needed.
-- Usage:
-- local LuaUIX = loadstring(game:HttpGet("URL"))()
-- local Window = LuaUIX:CreateWindow({Title="Demo"})
-- local Tab = Window:CreateTab("Main"); Tab:CreateButton("Hello", callback)

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Filesystem
local canFile = type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function"
local SAVE_FILE = "LuaUIX_PlusPlus_Settings.json"

-- GUIs
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
local function safeTween(inst, info, props)
    pcall(function() TweenService:Create(inst, info, props):Play() end)
end
local function applyUICorner(obj, radius) local c = Instance.new("UICorner"); c.CornerRadius = radius or UDim.new(0,6); c.Parent = obj; return c end
local function applyStroke(obj, thickness, color) local s=Instance.new("UIStroke"); s.Thickness=thickness or 1; s.Color=color or Color3.new(0,0,0); s.Parent=obj; return s end
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end

-- Persistence store
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
            local n = table.remove(queue,1)
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

            if n.type == "success" then title.TextColor3 = Color3.fromRGB(120, 200, 120)
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

-- Tooltip helper (uses FloatGui)
function LuaUIX.AddTooltip(guiObj, text)
    if not guiObj or not guiObj:IsA("GuiObject") then return end
    guiObj.MouseEnter:Connect(function()
        local tip = Instance.new("TextLabel")
        tip.Size = UDim2.new(0, 180, 0, 36)
        local absPos = guiObj.AbsolutePosition
        tip.Position = UDim2.new(0, absPos.X, 0, absPos.Y + guiObj.AbsoluteSize.Y + 6)
        tip.BackgroundColor3 = Color3.fromRGB(45,45,45)
        tip.TextColor3 = Color3.fromRGB(230,230,230)
        tip.Text = text
        tip.TextWrapped = true
        tip.Font = Enum.Font.Gotham
        tip.TextSize = 12
        tip.Parent = FloatGui
        applyUICorner(tip, UDim.new(0,6))
        tip.ZIndex = 300
        local leaveConn; leaveConn = guiObj.MouseLeave:Connect(function() tip:Destroy(); leaveConn:Disconnect() end)
    end)
end

-- Core: CreateWindow
function LuaUIX:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "LuaUIX"
    local size = opts.Size or UDim2.new(0, 560, 0, 420)
    local win = {}
    win.__index = win

    -- window
    local main = Instance.new("Frame")
    main.Name = "LuaUIX_Window"
    main.Size = size
    main.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(30,30,30)
    main.Parent = RootGui
    applyUICorner(main, UDim.new(0,10))
    main.ClipsDescendants = false
    main.ZIndex = 100

    -- topbar
    local top = Instance.new("Frame"); top.Size = UDim2.new(1,0,0,34); top.BackgroundTransparency = 1; top.Parent = main
    local titleLbl = Instance.new("TextLabel"); titleLbl.Size = UDim2.new(0.8,0,1,0); titleLbl.Position = UDim2.new(0,14,0,0); titleLbl.BackgroundTransparency=1
    titleLbl.Text = title; titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 16; titleLbl.TextColor3 = Color3.fromRGB(240,240,240); titleLbl.Parent = top

    -- close
    local close = Instance.new("TextButton"); close.Size = UDim2.new(0, 28, 0, 24); close.Position = UDim2.new(1, -36, 0, 5)
    close.Text = "X"; close.Font = Enum.Font.GothamBold; close.TextSize = 14; close.Parent = top
    close.BackgroundColor3 = Color3.fromRGB(50,50,50); close.TextColor3 = Color3.fromRGB(220,120,120); applyUICorner(close, UDim.new(1,0))
    close.MouseEnter:Connect(function() safeTween(close, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70,70,70)}) end)
    close.MouseLeave:Connect(function() safeTween(close, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50,50,50)}) end)
    close.MouseButton1Click:Connect(function() pcall(function() main:Destroy() end) end)

    -- left tabs column
    local tabCol = Instance.new("Frame"); tabCol.Size = UDim2.new(0, 130, 1, -44); tabCol.Position = UDim2.new(0, 10, 0, 40); tabCol.BackgroundTransparency = 1; tabCol.Parent = main
    local tabList = Instance.new("UIListLayout"); tabList.Parent = tabCol; tabList.Padding = UDim.new(0,8); tabList.SortOrder = Enum.SortOrder.LayoutOrder

    -- right content area
    local contentArea = Instance.new("Frame"); contentArea.Size = UDim2.new(1, -156, 1, -44); contentArea.Position = UDim2.new(0,146,0,40); contentArea.BackgroundTransparency = 1; contentArea.Parent = main
    contentArea.ClipsDescendants = false

    -- stores
    local tabs = {}
    local activeTab = nil

    -- drag
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
                local conn; conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging=false; conn:Disconnect() end
                end)
            end
        end)
        top.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input) if input==dragInput and dragging then update(input) end end)
    end

    -- CreateTab
    function win:CreateTab(name)
        -- tab button
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = tabCol
        applyUICorner(btn, UDim.new(0,6))
        btn.LayoutOrder = #tabs + 1

        -- content scrolling frame for this tab
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.Position = UDim2.new(0,0,0,0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 6
        scroll.Parent = contentArea
        scroll.Visible = false
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ClipsDescendants = false

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = scroll

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0,6); padding.PaddingBottom = UDim.new(0,8); padding.PaddingLeft = UDim.new(0,6); padding.PaddingRight = UDim.new(0,6)
        padding.Parent = scroll

        local tabObj = {}
        tabObj.__index = tabObj
        tabObj._btn = btn
        tabObj._scroll = scroll
        tabObj._name = name

        -- switch tab implementation
        btn.MouseButton1Click:Connect(function()
            if activeTab and activeTab._scroll then activeTab._scroll.Visible = false; activeTab._btn.TextColor3 = Color3.fromRGB(200,200,200) end
            scroll.Visible = true
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            activeTab = tabObj
        end)

        -- auto-open first tab
        if not activeTab then
            btn:MouseButton1Click()
        end

        -- utility to detect if we should float options (clips descendant or not enough space)
        local function useFloatFallback(targetFrame, neededHeight)
            -- if targetFrame clips descendants or there isn't enough below space to show neededHeight within window, float
            if targetFrame.ClipsDescendants then return true end
            local absPos = targetFrame.AbsolutePosition
            local absSize = targetFrame.AbsoluteSize
            local screenY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720
            local below = screenY - (absPos.Y + absSize.Y)
            if below < neededHeight then
                return true
            end
            return false
        end

        -- -------- Widgets --------
        function tabObj:CreateLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,0,20)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(220,220,220)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = scroll
            lbl.LayoutOrder = 1
            return lbl
        end

        function tabObj:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,0,0,36)
            btn.BackgroundColor3 = Color3.fromRGB(55,55,55)
            btn.Text = text or "Button"
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(245,245,245)
            btn.Parent = scroll
            applyUICorner(btn, UDim.new(0,6))
            btn.LayoutOrder = 1
            btn.MouseEnter:Connect(function() safeTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(75,75,75)}) end)
            btn.MouseLeave:Connect(function() safeTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(55,55,55)}) end)
            btn.MouseButton1Click:Connect(function() pcall(callback) end)
            return btn
        end

        function tabObj:CreateToggle(text, default, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,36)
            frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
            frame.Parent = scroll
            applyUICorner(frame, UDim.new(0,6))
            frame.LayoutOrder = 1

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.7,0,1,0)
            label.Position = UDim2.new(0,10,0,0)
            label.Text = text or "Toggle"
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(230,230,230)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0.25, -14, 0, 22)
            sw.Position = UDim2.new(0.7, 10, 0.5, -11)
            sw.BackgroundColor3 = default and Color3.fromRGB(90,160,90) or Color3.fromRGB(80,80,80)
            sw.Font = Enum.Font.GothamBold
            sw.TextSize = 13
            sw.Text = default and "ON" or "OFF"
            sw.TextColor3 = Color3.fromRGB(240,240,240)
            applyUICorner(sw, UDim.new(0,6))
            sw.Parent = frame

            local state = default or false
            sw.MouseButton1Click:Connect(function()
                state = not state
                sw.Text = state and "ON" or "OFF"
                sw.BackgroundColor3 = state and Color3.fromRGB(90,160,90) or Color3.fromRGB(80,80,80)
                pcall(callback, state)
            end)

            return {
                Set = function(s) state=s; sw.Text = s and "ON" or "OFF"; sw.BackgroundColor3 = s and Color3.fromRGB(90,160,90) or Color3.fromRGB(80,80,80) end,
                Get = function() return state end,
                Instance = frame
            }
        end

        function tabObj:CreateTextbox(placeholder, callback, validation)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,54)
            container.BackgroundTransparency = 1
            container.Parent = scroll
            container.LayoutOrder = 1

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

            box.FocusLost:Connect(function(enter)
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
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,36)
            frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
            frame.Parent = scroll
            frame.LayoutOrder = 1
            applyUICorner(frame, UDim.new(0,6))

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0.6,0,1,0)
            label.Position = UDim2.new(0,10,0,0)
            label.Text = text or "Keybind"
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(230,230,230)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.35, -10, 0, 24)
            btn.Position = UDim2.new(0.6, 10, 0.5, -12)
            btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(240,240,240)
            applyUICorner(btn, UDim.new(0,6))
            btn.Parent = frame

            local current = defaultKey or Enum.KeyCode.F
            btn.Text = tostring(current):gsub("Enum.KeyCode.", "")

            local listeningConn
            btn.MouseButton1Click:Connect(function()
                btn.Text = "..."
                btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
                listeningConn = UserInputService.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        current = i.KeyCode
                        btn.Text = tostring(current):gsub("Enum.KeyCode.", "")
                        btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
                        pcall(callback, current)
                        listeningConn:Disconnect()
                    end
                end)
            end)

            return {
                Set = function(k) current = k; btn.Text = tostring(k):gsub("Enum.KeyCode.", "") end,
                Get = function() return current end,
                Instance = frame
            }
        end

        function tabObj:CreateSlider(text, min, max, default, callback)
            min = min or 0; max = max or 100; default = default or min
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,48)
            container.BackgroundTransparency = 1
            container.Parent = scroll
            container.LayoutOrder = 1

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
            barBg.Parent = container
            applyUICorner(barBg, UDim.new(0,6))

            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new((default - min)/(max-min),0,1,0)
            barFill.BackgroundColor3 = Color3.fromRGB(100,100,230)
            barFill.Parent = barBg
            applyUICorner(barFill, UDim.new(0,6))

            local dragging = false
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            barBg.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
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
            defaultIndex = defaultIndex or 1
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,36)
            container.BackgroundColor3 = Color3.fromRGB(40,40,40)
            container.Parent = scroll
            applyUICorner(container, UDim.new(0,6))
            container.LayoutOrder = 1

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,-30,1,0)
            label.Position = UDim2.new(0,10,0,0)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. tostring(items[defaultIndex] or "")
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0,18,0,18)
            arrow.Position = UDim2.new(1,-26,0.5,-9)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.Font = Enum.Font.Gotham
            arrow.TextSize = 12
            arrow.TextColor3 = Color3.fromRGB(200,200,200)
            arrow.Parent = container

            -- inline options frame
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(1,0,0,0)
            optionsFrame.Position = UDim2.new(0, 0, 1, 6)
            optionsFrame.BackgroundColor3 = Color3.fromRGB(42,42,42)
            optionsFrame.ClipsDescendants = true
            optionsFrame.Parent = container
            applyUICorner(optionsFrame, UDim.new(0,6))
            optionsFrame.LayoutOrder = 2

            local optionsLayout = Instance.new("UIListLayout"); optionsLayout.Parent = optionsFrame; optionsLayout.Padding = UDim.new(0,4)

            local current = defaultIndex
            local open = false

            local function updateLabel()
                label.Text = text .. ": " .. tostring(items[current] or "")
                pcall(callback, items[current], current)
            end

            local function closeOptions()
                open = false
                safeTween(arrow, TweenInfo.new(0.12), {Rotation = 0})
                safeTween(optionsFrame, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,0)})
                task.delay(0.16, function() optionsFrame.Visible = false end)
            end

            local function openOptionsInline()
                optionsFrame.Visible = true
                local needed = #items * 30 + 8
                optionsFrame.Size = UDim2.new(1,0,0,needed)
                safeTween(arrow, TweenInfo.new(0.12), {Rotation = 180})
                open = true
            end

            local function openOptionsFloat()
                -- create floating frame in FloatGui
                local f = Instance.new("Frame")
                f.BackgroundColor3 = Color3.fromRGB(42,42,42)
                f.Size = UDim2.new(0, 200, 0, #items*30+10)
                local abs = container.AbsolutePosition
                f.Position = UDim2.new(0, abs.X, 0, abs.Y + container.AbsoluteSize.Y + 6)
                f.Parent = FloatGui
                f.ZIndex = 400
                applyUICorner(f, UDim.new(0,6))
                local flayout = Instance.new("UIListLayout"); flayout.Parent=f; flayout.Padding=UDim.new(0,4)
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
                -- close when clicking outside
                local conn; conn = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mousePos = UserInputService:GetMouseLocation()
                        local px,py = mousePos.X, mousePos.Y
                        local fPos = f.AbsolutePosition; local fSize = f.AbsoluteSize
                        if not (px >= fPos.X and px <= fPos.X+fSize.X and py >= fPos.Y and py <= fPos.Y+fSize.Y) then
                            f:Destroy(); conn:Disconnect()
                        end
                    end
                end)
            end

            container.MouseButton1Click:Connect(function()
                -- decide inline or float
                local needed = #items * 30 + 8
                if useFloatFallback(container, needed) then
                    openOptionsFloat()
                else
                    if open then closeOptions() else openOptionsInline() end
                end
            end)

            -- populate inline options (hidden)
            for i,it in ipairs(items) do
                local o = Instance.new("TextButton")
                o.Size = UDim2.new(1, -14, 0, 26)
                o.Position = UDim2.new(0, 7, 0, (i-1)*30 + 6)
                o.BackgroundColor3 = Color3.fromRGB(50,50,50)
                o.Text = it
                o.Font = Enum.Font.Gotham
                o.TextSize = 14
                o.TextColor3 = Color3.fromRGB(230,230,230)
                applyUICorner(o, UDim.new(0,4))
                o.Parent = optionsFrame
                o.ZIndex = 120
                o.MouseButton1Click:Connect(function()
                    current = i
                    updateLabel()
                    closeOptions()
                end)
            end

            updateLabel()
            return {
                Set = function(idx) if idx>=1 and idx<=#items then current = idx; updateLabel() end end,
                Get = function() return current, items[current] end,
                Instance = container
            }
        end

        -- Return tab object
        tabs[#tabs+1] = tabObj
        return setmetatable(tabObj, tabObj)
    end

    -- Expose window methods
    function win:Toggle() main.Visible = not main.Visible end
    function win:Destroy() pcall(function() main:Destroy() end) end

    return setmetatable(win, win)
end

-- Expose Save/Load/Notify
function LuaUIX.Save() saveSettings() end
function LuaUIX.Load() loadSettings() end

-- Return module
return LuaUIX
