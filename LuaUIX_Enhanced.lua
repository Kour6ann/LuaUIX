-- LuaUIX.lua
-- Version: 1.0.0
-- License: MIT
-- Copyright (c) 2025 <your-username>
--
-- Minimal, robust UI library focused on exploit executor compatibility:
-- - Safe file read/write wrappers (works with common executor functions)
-- - CoreGui / PlayerGui fallback for parenting
-- - CreateWindow API with ConfigurationSaving, ConfigFolder, FileName
-- - RegisterFlag / CollectConfig / SaveConfiguration / LoadConfiguration
-- - Simple Toggle widget implementation (implements GetValue / SetValue)
-- - Defensive layout using UIListLayout / LayoutOrder (avoids manual Positioning)
--
-- TODO: Add more widgets (Dropdown, Slider, ColorPicker) following the GetValue/SetValue contract.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- ===== Metadata / defaults =====
local VERSION = "1.0.0"

local settings = settings or {}
settings.Config = settings.Config or {
    Enabled = false,
    FolderName = "LuaUIXConfigs",
    FileName = "default"
}
local DefaultToggle = DefaultToggle or Enum.KeyCode.RightShift

-- Minimal theme set (ensure common color keys exist)
LuaUIX.Themes = {
    Dark = {
        Primary = Color3.fromRGB(25,25,25),
        Secondary = Color3.fromRGB(35,35,35),
        Accent = Color3.fromRGB(76,201,240),
        Text = Color3.fromRGB(230,230,230),
        Success = Color3.fromRGB(46,204,113)
    },
    Light = {
        Primary = Color3.fromRGB(240,240,240),
        Secondary = Color3.fromRGB(255,255,255),
        Accent = Color3.fromRGB(0,120,215),
        Text = Color3.fromRGB(20,20,20),
        Success = Color3.fromRGB(46,204,113)
    }
}

-- ===== Utilities =====
local function try(call)
    local ok, res = pcall(call)
    return ok, res
end

local function safeWrite(path, data)
    -- tries multiple common executor write functions
    local ok, err = pcall(function() writefile(path, data) end)
    if ok then return true end
    -- alternative names some executors provide
    pcall(function() if write_file then write_file(path, data) end end)
    pcall(function() if writeFile then writeFile(path, data) end end)
    if not ok then
        warn(("LuaUIX: writefile failed: %s"):format(tostring(err)))
    end
    return ok
end

local function safeRead(path)
    local ok, content = pcall(function() return readfile(path) end)
    if ok then return content end
    local altOk, altContent = pcall(function() if read_file then return read_file(path) end end)
    if altOk and altContent then return altContent end
    pcall(function() if readFile then return readFile(path) end end)
    return nil
end

local function makePath(folder, filename)
    folder = folder or (settings and settings.Config and settings.Config.FolderName) or "LuaUIXConfigs"
    filename = filename or (settings and settings.Config and settings.Config.FileName) or "default"
    return folder .. "/" .. filename .. ".json"
end

local function ShowNotification(text)
    text = tostring(text or "")
    pcall(function()
        if StarterGui and StarterGui.SetCore then
            StarterGui:SetCore("SendNotification", {
                Title = "LuaUIX",
                Text = text,
                Duration = 3
            })
        end
    end)
    warn("[LuaUIX] " .. text)
end

local function getGuiParent()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then
        -- some executors block CoreGui, but we try; fall back to PlayerGui otherwise
        return core
    end
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        return localPlayer:WaitForChild("PlayerGui")
    end
    return nil
end

-- element pooling (small safety)
local elementPool = {}
function LuaUIX:GetFromPool(kind, createFn)
    kind = kind or "Default"
    elementPool[kind] = elementPool[kind] or {}
    if #elementPool[kind] > 0 then
        return table.remove(elementPool[kind])
    else
        return createFn()
    end
end
function LuaUIX:ReturnToPool(kind, element)
    if not element then return end
    element.Parent = nil
    element.Visible = false
    elementPool[kind] = elementPool[kind] or {}
    table.insert(elementPool[kind], element)
end

-- ===== Window factory =====
function LuaUIX:CreateWindow(title, opts)
    opts = opts or {}
    local themeName = opts.Theme or "Dark"
    local theme = self.Themes[themeName] or self.Themes.Dark

    local window = {}
    window.Title = title or "LuaUIX Window"
    window.Elements = {}          -- flag -> widget
    window.ConfigurationSaving = (opts.ConfigurationSaving == nil) and false or opts.ConfigurationSaving
    window.ConfigFolder = opts.ConfigFolder or settings.Config.FolderName
    window.FileName = opts.FileName or settings.Config.FileName
    window.Theme = theme
    setmetatable(window, {__index = LuaUIX})

    -- create ScreenGui parent safely
    local guiParent = getGuiParent()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LuaUIX_ScreenGui_" .. tostring(math.random(1000,9999))
    ScreenGui.ResetOnSpawn = false
    if guiParent then
        pcall(function() ScreenGui.Parent = guiParent end)
    end

    -- window main frame
    local WindowFrame = Instance.new("Frame")
    WindowFrame.Name = "Window"
    WindowFrame.Size = UDim2.new(0, 520, 0, 640)
    WindowFrame.Position = UDim2.new(0.5, -260, 0.5, -320)
    WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    WindowFrame.BackgroundColor3 = theme.Primary
    WindowFrame.BorderSizePixel = 0
    WindowFrame.Parent = ScreenGui

    -- titlebar + controls
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 36)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = theme.Secondary
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = WindowFrame

    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.Size = UDim2.new(1, -80, 1, 0)
    TitleText.Position = UDim2.new(0, 12, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = window.Title
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 16
    TitleText.TextColor3 = theme.Text
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 56, 1, 0)
    CloseBtn.Position = UDim2.new(1, -56, 0, 0)
    CloseBtn.AnchorPoint = Vector2.new(1, 0)
    CloseBtn.BackgroundColor3 = theme.Secondary
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.TextSize = 14
    CloseBtn.Text = "Close"
    CloseBtn.TextColor3 = theme.Text
    CloseBtn.Parent = TitleBar

    CloseBtn.MouseButton1Click:Connect(function()
        -- destroy GUI
        pcall(function() ScreenGui:Destroy() end)
    end)

    -- left tabs (UIListLayout)
    local TabHolder = Instance.new("Frame")
    TabHolder.Name = "TabHolder"
    TabHolder.Size = UDim2.new(0, 160, 1, -36)
    TabHolder.Position = UDim2.new(0, 0, 0, 36)
    TabHolder.BackgroundTransparency = 1
    TabHolder.Parent = WindowFrame

    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 8)
    TabList.Parent = TabHolder

    -- right content area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -160, 1, -36)
    ContentArea.Position = UDim2.new(0, 160, 0, 36)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = WindowFrame

    -- internal storage
    window._tabs = {}
    window._ui = {
        ScreenGui = ScreenGui,
        WindowFrame = WindowFrame,
        TabHolder = TabHolder,
        ContentArea = ContentArea
    }

    -- RegisterFlag (so Save/Load map flags to widget objects)
    function window:RegisterFlag(flag, element)
        if not flag or flag == "" then return end
        self.Elements[flag] = element
        element._flag = flag
    end

    -- Collect config from registered elements (calls GetValue)
    function window:CollectConfig()
        local out = {}
        for flag, element in pairs(self.Elements) do
            if type(element.GetValue) == "function" then
                local ok, val = pcall(function() return element:GetValue() end)
                if ok then out[flag] = val end
            end
        end
        return out
    end

    function window:SaveConfiguration()
        if not self.ConfigurationSaving then return false, "disabled" end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(self:CollectConfig()) end)
        if not ok then return false, "encode_failed" end
        local path = makePath(self.ConfigFolder, self.FileName)
        local wrote = safeWrite(path, encoded)
        if wrote then ShowNotification("Configuration saved.") end
        return wrote
    end

    function window:LoadConfiguration()
        local path = makePath(self.ConfigFolder, self.FileName)
        local raw = safeRead(path)
        if not raw then
            warn("LuaUIX: no config file at " .. tostring(path))
            return false, "no_file"
        end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok then return false, "decode_failed" end
        for flag, val in pairs(decoded) do
            local element = self.Elements[flag]
            if element and type(element.SetValue) == "function" then
                pcall(function() element:SetValue(val) end)
            else
                warn(("LuaUIX: element for flag '%s' not found during LoadConfiguration"):format(tostring(flag)))
            end
        end
        ShowNotification("Configuration loaded.")
        return true
    end

    -- AddTab: creates a tab button (uses LayoutOrder) and a content frame
    function window:AddTab(name, icon)
        local tab = {}
        tab.Name = name or "Tab"
        tab.Icon = icon
        tab._widgets = {}
        tab._content = Instance.new("Frame")
        tab._content.Name = name .. "_Content"
        tab._content.Size = UDim2.new(1, 0, 1, 0)
        tab._content.BackgroundTransparency = 1
        tab._content.Visible = false
        tab._content.Parent = ContentArea

        local btn = Instance.new("TextButton")
        btn.Name = name .. "_Btn"
        btn.Size = UDim2.new(1, -12, 0, 42)
        btn.BackgroundColor3 = theme.Secondary
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = (icon and (icon .. "  ") or "") .. name
        btn.TextColor3 = theme.Text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        -- ensure LayoutOrder is appropriate; UIListLayout includes non-button children so we keep it safe
        btn.LayoutOrder = (#TabHolder:GetChildren() or 0) + 1
        btn.Parent = TabHolder

        btn.MouseButton1Click:Connect(function()
            for _, t in pairs(window._tabs) do
                if t._content then t._content.Visible = false end
                if t._btn then t._btn.BackgroundColor3 = theme.Secondary end
            end
            tab._content.Visible = true
            btn.BackgroundColor3 = theme.Accent
        end)

        -- open the first tab by default
        if #window._tabs == 0 then
            btn.BackgroundColor3 = theme.Accent
            tab._content.Visible = true
        end

        tab._btn = btn

        -- section factory inside tab
        function tab:CreateSection(title, side)
            side = side or "Left"
            local section = {}
            section.Title = title or "Section"
            section._frame = Instance.new("Frame")
            section._frame.Name = ("Section_%s"):format(title)
            section._frame.Size = UDim2.new(1, -24, 0, 160)
            -- position uses GetChildren() count: safe but simple (you may replace with proper layout)
            section._frame.Position = UDim2.new(0, 12, 0, (#tab._content:GetChildren() - 1) * 166)
            section._frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
            section._frame.BackgroundTransparency = 0.85
            section._frame.BorderSizePixel = 0
            section._frame.Parent = tab._content

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 0, 28)
            label.Position = UDim2.new(0, 6, 0, 6)
            label.BackgroundTransparency = 1
            label.Text = section.Title
            label.Font = Enum.Font.GothamSemibold
            label.TextSize = 14
            label.TextColor3 = theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = section._frame

            -- AddToggle: simple toggle widget (implements GetValue & SetValue)
            function section:AddToggle(flag, default, callback)
                local widget = {}
                widget._value = not not default

                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, -12, 0, 36)
                container.Position = UDim2.new(0, 6, 0, 36 + (#section._frame:GetChildren() - 1) * 40)
                container.BackgroundTransparency = 1
                container.Parent = section._frame

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = flag or "Toggle"
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 14
                lbl.TextColor3 = theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = container

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 80, 0, 28)
                btn.Position = UDim2.new(1, -84, 0, 4)
                btn.AnchorPoint = Vector2.new(1, 0)
                btn.BackgroundColor3 = widget._value and theme.Accent or theme.Secondary
                btn.BorderSizePixel = 0
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Text = widget._value and "On" or "Off"
                btn.TextColor3 = theme.Text
                btn.Parent = container

                function widget:GetValue() return widget._value end
                function widget:SetValue(v)
                    widget._value = not not v
                    btn.Text = widget._value and "On" or "Off"
                    btn.BackgroundColor3 = widget._value and theme.Accent or theme.Secondary
                end

                btn.MouseButton1Click:Connect(function()
                    widget:SetValue(not widget._value)
                    if type(callback) == "function" then
                        pcall(function() callback(widget._value) end)
                    end
                end)

                -- auto-register flag if provided
                if flag and flag ~= "" then
                    -- ensure parent window exists
                    window:RegisterFlag(flag, widget)
                end

                table.insert(tab._widgets, widget)
                return widget
            end

            section.ParentWindow = window
            section._frame.Parent = tab._content
            return section
        end

        table.insert(window._tabs, tab)
        return tab
    end

    return window
end

-- convenience global API
function LuaUIX.Create(title, opts)
    return LuaUIX:CreateWindow(title, opts)
end

return LuaUIX
