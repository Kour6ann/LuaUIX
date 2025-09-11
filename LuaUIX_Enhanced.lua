-- LuaUIX_Refined.lua
-- Polished, Orion/Rayfield-like single-file UI library (client-side)
-- Usage: local LuaUIX = loadstring(game:HttpGet("URL"))(); local w = LuaUIX:CreateWindow{...}

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Filesystem guards
local canFile = type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function"
local SAVE_FILE = "LuaUIX_Settings.json"

-- Top-level ScreenGuis
local function makeScreenGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        sg.Parent = LocalPlayer.PlayerGui
    else
        -- fallback
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
    end
    return sg
end

local RootGui = makeScreenGui("LuaUIX_Root")
local NotifGui = makeScreenGui("LuaUIX_Notifs")
local FloatGui = makeScreenGui("LuaUIX_Float") -- used for dropdowns/tooltips so they aren't clipped

-- Utility
local function safeTween(inst, info, props)
    pcall(function() TweenService:Create(inst, info, props):Play() end)
end

local function setChildrenZIndex(frame, z)
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("GuiObject") then
            child.ZIndex = z
        end
    end
end

local function applyUICorner(guiObj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0,6)
    c.Parent = guiObj
    return c
end

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
            frame.Size = UDim2.new(0, 300, 0, 70)
            frame.Position = UDim2.new(1, 320, 0, 20) -- start off-screen right
            frame.AnchorPoint = Vector2.new(1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(36,36,36)
            frame.Parent = NotifGui
            applyUICorner(frame, UDim.new(0,8))
            frame.BorderSizePixel = 0
            frame.ZIndex = 50

            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -20, 0, 20)
            title.Position = UDim2.new(0, 10, 0, 6)
            title.BackgroundTransparency = 1
            title.Text = n.title or "Notice"
            title.Font = Enum.Font.GothamBold
            title.TextSize = 14
            title.TextColor3 = Color3.fromRGB(220,220,220)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = frame
            local msg = Instance.new("TextLabel")
            msg.Size = UDim2.new(1, -20, 0, 40)
            msg.Position = UDim2.new(0, 10, 0, 24)
            msg.BackgroundTransparency = 1
            msg.Text = n.msg or ""
            msg.Font = Enum.Font.Gotham
            msg.TextSize = 12
            msg.TextColor3 = Color3.fromRGB(180,180,180)
            msg.TextXAlignment = Enum.TextXAlignment.Left
            msg.TextYAlignment = Enum.TextYAlignment.Top
            msg.TextWrapped = true
            msg.Parent = frame

            if n.type == "success" then title.TextColor3 = Color3.fromRGB(100,200,100)
            elseif n.type == "warning" then title.TextColor3 = Color3.fromRGB(235,200,80)
            elseif n.type == "error" then title.TextColor3 = Color3.fromRGB(220,100,100) end

            safeTween(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -20, 0, 20)})
            task.wait(n.duration or 3.5)
            safeTween(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 320, 0, 20)})
            task.wait(0.24)
            frame:Destroy()
        end
        running = false
    end

    function LuaUIX.Notify(title, msg, duration, typ)
        table.insert(queue, {title = title, msg = msg, duration = duration, type = typ})
        spawn(process)
    end
end

-- Persistence
local settingsStore = {}
local function saveSettings()
    if not canFile then return end
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode(settingsStore))
    end)
end
local function loadSettings()
    if not canFile then return end
    pcall(function()
        if isfile(SAVE_FILE) then
            settingsStore = HttpService:JSONDecode(readfile(SAVE_FILE)) or {}
        end
    end)
end
loadSettings()

-- Window / Tab system
function LuaUIX:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "LuaUIX"
    local size = opts.Size or UDim2.new(0, 520, 0, 320)

    local Window = {}
    Window.__index = Window

    -- window container
    local winFrame = Instance.new("Frame")
    winFrame.Name = "LuaUIX_Window"
    winFrame.Size = size
    winFrame.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    winFrame.AnchorPoint = Vector2.new(0.5,0.5)
    winFrame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    winFrame.Parent = RootGui
    applyUICorner(winFrame, UDim.new(0,8))
    winFrame.BorderSizePixel = 0
    winFrame.ClipsDescendants = false
    winFrame.ZIndex = 5

    -- top bar
    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1, 0, 0, 30)
    topbar.Position = UDim2.new(0, 0, 0, 0)
    topbar.BackgroundTransparency = 1
    topbar.Parent = winFrame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position = UDim2.new(0, 12, 0, 4)
    titleLbl.Size = UDim2.new(0, 300, 0, 22)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextSize = 16
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextColor3 = Color3.fromRGB(235,235,235)
    titleLbl.Parent = topbar

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 24)
    closeBtn.Position = UDim2.new(1, -34, 0, 3)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    closeBtn.TextColor3 = Color3.fromRGB(200,80,80)
    closeBtn.Parent = topbar
    applyUICorner(closeBtn, UDim.new(1,0))

    closeBtn.MouseEnter:Connect(function() safeTween(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(65,65,65)}) end)
    closeBtn.MouseLeave:Connect(function() safeTween(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(45,45,45)}) end)

    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() winFrame:Destroy() end)
    end)

    -- dragging
    do
        local dragging, dragStart, startPos, dragInput
        local function update(input)
            local delta = input.Position - dragStart
            winFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end

        topbar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = winFrame.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        conn:Disconnect()
                    end
                end)
            end
        end)
        topbar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)
    end

    -- content holder (vertical stack)
    local contentHolder = Instance.new("Frame")
    contentHolder.Size = UDim2.new(1, -24, 1, -42)
    contentHolder.Position = UDim2.new(0, 12, 0, 36)
    contentHolder.BackgroundTransparency = 1
    contentHolder.Parent = winFrame
    contentHolder.AutomaticSize = Enum.AutomaticSize.Y
    contentHolder.ClipsDescendants = false

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0,8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = contentHolder

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,6)
    padding.PaddingBottom = UDim.new(0,6)
    padding.PaddingLeft = UDim.new(0,6)
    padding.PaddingRight = UDim.new(0,6)
    padding.Parent = contentHolder

    -- API: CreateTab returns an object with widget creation functions that put children into contentHolder in vertical stack
    function Window:CreateTab(tabName)
        local Tab = {}
        Tab.__index = Tab

        -- section header
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, 0, 0, 22)
        header.BackgroundTransparency = 1
        header.Text = tabName
        header.Font = Enum.Font.GothamBold
        header.TextSize = 14
        header.TextColor3 = Color3.fromRGB(220,220,220)
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = contentHolder
        header.LayoutOrder = 0

        function Tab:CreateDropdown(name, options, defaultIndex, callback)
            defaultIndex = defaultIndex or 1
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 36)
            container.BackgroundColor3 = Color3.fromRGB(40,40,40)
            container.Parent = contentHolder
            applyUICorner(container, UDim.new(0,6))
            container.LayoutOrder = 1

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -34, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = name .. ": " .. tostring(options[defaultIndex] or "")
            label.Font = Enum.Font.Gotham
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 0, 20)
            arrow.Position = UDim2.new(1, -28, 0.5, -10)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.Font = Enum.Font.Gotham
            arrow.TextSize = 12
            arrow.TextColor3 = Color3.fromRGB(200,200,200)
            arrow.Parent = container

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.Parent = container

            -- floating options frame in FloatGui so not clipped
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(0, 180, 0, 0)
            optionsFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
            optionsFrame.Parent = FloatGui
            applyUICorner(optionsFrame, UDim.new(0,6))
            optionsFrame.Visible = false
            optionsFrame.ZIndex = 80

            local layout = Instance.new("UIListLayout")
            layout.Parent = optionsFrame
            layout.Padding = UDim.new(0,4)

            local current = defaultIndex

            local function updateLabel()
                label.Text = name .. ": " .. tostring(options[current] or "")
                if callback then pcall(callback, options[current], current) end
            end

            local function toggle()
                if optionsFrame.Visible then
                    optionsFrame.Visible = false
                    safeTween(arrow, TweenInfo.new(0.12), {Rotation = 0})
                    safeTween(optionsFrame, TweenInfo.new(0.15), {Size = UDim2.new(0, optionsFrame.Size.X.Offset, 0, 0)})
                else
                    -- position below container
                    local absPos = container.AbsolutePosition
                    optionsFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + container.AbsoluteSize.Y + 6)
                    optionsFrame.Size = UDim2.new(0, 180, 0, #options * 30)
                    optionsFrame.Visible = true
                    safeTween(arrow, TweenInfo.new(0.12), {Rotation = 180})
                end
            end

            btn.MouseButton1Click:Connect(toggle)

            for i, opt in ipairs(options) do
                local oBtn = Instance.new("TextButton")
                oBtn.Size = UDim2.new(1, -14, 0, 26)
                oBtn.Position = UDim2.new(0, 7, 0, (i-1)*30 + 6)
                oBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                oBtn.Text = opt
                oBtn.Font = Enum.Font.Gotham
                oBtn.TextSize = 14
                oBtn.TextColor3 = Color3.fromRGB(220,220,220)
                oBtn.Parent = optionsFrame
                applyUICorner(oBtn, UDim.new(0,4))
                oBtn.ZIndex = 85

                oBtn.MouseButton1Click:Connect(function()
                    current = i
                    updateLabel()
                    toggle()
                end)
            end

            updateLabel()

            return {
                Set = function(idx)
                    if idx >=1 and idx <= #options then current = idx; updateLabel() end
                end,
                Get = function() return current, options[current] end
            }
        end

        function Tab:CreateTextbox(name, placeholder, callback, validation)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 50)
            container.BackgroundTransparency = 1
            container.Parent = contentHolder
            container.LayoutOrder = 1

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 18)
            label.BackgroundTransparency = 1
            label.Text = name
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, 0, 0, 28)
            box.Position = UDim2.new(0, 0, 0, 20)
            box.BackgroundColor3 = Color3.fromRGB(40,40,40)
            box.TextColor3 = Color3.fromRGB(220,220,220)
            box.PlaceholderText = placeholder or ""
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.Parent = container
            applyUICorner(box, UDim.new(0,6))

            box.FocusLost:Connect(function(enter)
                local ok = true
                if validation then
                    local succ, res = pcall(function() return validation(box.Text) end)
                    ok = succ and res
                end
                if not ok then
                    safeTween(box, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70,35,35)})
                    task.wait(0.45)
                    safeTween(box, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40,40,40)})
                else
                    if callback then pcall(callback, box.Text) end
                end
            end)

            return {
                SetText = function(t) box.Text = t end,
                GetText = function() return box.Text end
            }
        end

        function Tab:CreateKeybind(name, defaultKey, callback)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 34)
            container.BackgroundColor3 = Color3.fromRGB(40,40,40)
            container.Parent = contentHolder
            applyUICorner(container, UDim.new(0,6))
            container.LayoutOrder = 1

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.6, 0, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(220,220,220)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = container

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.35, -10, 0, 24)
            btn.Position = UDim2.new(0.6, 10, 0.5, -12)
            btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(220,220,220)
            btn.Parent = container
            applyUICorner(btn, UDim.new(0,4))

            local current = defaultKey or Enum.KeyCode.F
            btn.Text = tostring(current):gsub("Enum.KeyCode.", "")

            local listening
            local conn
            btn.MouseButton1Click:Connect(function()
                listening = true
                btn.Text = "..."
                btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
                conn = UserInputService.InputBegan:Connect(function(inp)
                    if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        current = inp.KeyCode
                        btn.Text = tostring(current):gsub("Enum.KeyCode.", "")
                        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                        if callback then pcall(callback, current) end
                        conn:Disconnect()
                    end
                end)
            end)

            return {
                Set = function(k) current = k; btn.Text = tostring(k):gsub("Enum.KeyCode.", "") end,
                Get = function() return current end
            }
        end

        function Tab:CreateToggle(name, default, callback)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 34)
            container.BackgroundColor3 = Color3.fromRGB(40,40,40)
            container.Parent = contentHolder
            applyUICorner(container, UDim.new(0,6))
            container.LayoutOrder = 1

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.7, 0, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = name
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(220,220,220)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = container

            local switch = Instance.new("TextButton")
            switch.Size = UDim2.new(0.25, -10, 0, 22)
            switch.Position = UDim2.new(0.7, 10, 0.5, -11)
            switch.BackgroundColor3 = Color3.fromRGB(60,60,60)
            switch.Text = tostring(default and "ON" or "OFF")
            switch.Font = Enum.Font.GothamBold
            switch.TextSize = 13
            switch.TextColor3 = Color3.fromRGB(220,220,220)
            applyUICorner(switch, UDim.new(0,6))
            switch.Parent = container
            local state = default or false
            switch.MouseButton1Click:Connect(function()
                state = not state
                switch.Text = tostring(state and "ON" or "OFF")
                if callback then pcall(callback, state) end
            end)

            return {
                Set = function(s) state = s; switch.Text = tostring(state and "ON" or "OFF") end,
                Get = function() return state end
            }
        end

        function Tab:CreateSlider(name, min, max, default, callback)
            min = min or 0; max = max or 100; default = default or min
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 44)
            container.BackgroundTransparency = 1
            container.Parent = contentHolder
            container.LayoutOrder = 1

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.6, 0, 0, 18)
            label.BackgroundTransparency = 1
            label.Text = name
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextColor3 = Color3.fromRGB(220,220,220)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = container

            local valLabel = Instance.new("TextLabel")
            valLabel.Size = UDim2.new(0.4, -10, 0, 18)
            valLabel.Position = UDim2.new(0.6, 10, 0, 0)
            valLabel.BackgroundTransparency = 1
            valLabel.Text = tostring(default)
            valLabel.Font = Enum.Font.Gotham
            valLabel.TextSize = 13
            valLabel.TextColor3 = Color3.fromRGB(200,200,200)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.Parent = container

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, 0, 0, 12)
            barBg.Position = UDim2.new(0, 0, 0, 24)
            barBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
            barBg.Parent = container
            applyUICorner(barBg, UDim.new(0,6))

            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(100,100,240)
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
                    local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                    local v = math.floor(min + rel * (max - min) + 0.5)
                    barFill.Size = UDim2.new(rel, 0, 1, 0)
                    valLabel.Text = tostring(v)
                    if callback then pcall(callback, v) end
                end
            end)

            return {
                Set = function(v)
                    v = math.clamp(v, min, max)
                    local rel = (v - min) / (max - min)
                    barFill.Size = UDim2.new(rel, 0, 1, 0)
                    valLabel.Text = tostring(v)
                end,
                Get = function() return tonumber(valLabel.Text) end
            }
        end

        function Tab:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 34)
            btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            btn.Text = text
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(235,235,235)
            applyUICorner(btn, UDim.new(0,6))
            btn.Parent = contentHolder
            btn.LayoutOrder = 1

            btn.MouseEnter:Connect(function() safeTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(80,80,80)}) end)
            btn.MouseLeave:Connect(function() safeTween(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(60,60,60)}) end)
            btn.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)

            return btn
        end

        function Tab:CreateTooltip(guiObj, text)
            -- display tooltip using FloatGui
            if not guiObj or not guiObj:IsA("GuiObject") then return end
            guiObj.MouseEnter:Connect(function()
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(0, 160, 0, 36)
                local abs = guiObj.AbsolutePosition
                t.Position = UDim2.new(0, abs.X, 0, abs.Y + guiObj.AbsoluteSize.Y + 6)
                t.BackgroundColor3 = Color3.fromRGB(45,45,45)
                t.TextColor3 = Color3.fromRGB(220,220,220)
                t.Text = text
                t.TextWrapped = true
                t.Font = Enum.Font.Gotham
                t.TextSize = 12
                applyUICorner(t, UDim.new(0,6))
                t.Parent = FloatGui
                t.ZIndex = 95
                guiObj.MouseLeave:Wait()
                t:Destroy()
            end)
        end

        return setmetatable(Tab, Tab)
    end

    -- return window object
    return setmetatable(Window, Window)
end

-- Expose quick Save/Load
function LuaUIX.Save()
    saveSettings()
end
function LuaUIX.Load()
    loadSettings()
end

-- Backwards-compat helpers (very small)
LuaUIX.CreateWindow = LuaUIX.CreateWindow
LuaUIX.Notify = LuaUIX.Notify
LuaUIX.Save = LuaUIX.Save
LuaUIX.Load = LuaUIX.Load

return LuaUIX
