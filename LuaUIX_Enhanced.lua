-- LuaUIX_Enhanced.lua
-- Single-file enhancement pack for LuaUIX (polish + widgets + persistence + notifications + tooltips + mobile)
-- Usage: local LuaUIX = require(path_to_this_file); LuaUIX:Init() or use Create* functions.

local LuaUIX = {}
LuaUIX.__index = LuaUIX

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Save file (exploit-safe guards)
local SAVE_FILE = "LuaUIX_Settings.json"
local canFile = (type(isfile) == "function") and (type(writefile) == "function") and (type(readfile) == "function")

-- Internal state
local settingsData = {}
local widgetRegistry = {
    toggles = {},
    sliders = {},
    dropdowns = {},
    textboxes = {},
    keybinds = {}
}

-- Root UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuaUIX_Enhanced"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Demo main frame (created on Init)
local MainFrame, TopBar, CloseBtn

-- Utility helpers
local function safeTween(inst, info, props)
    pcall(function()
        TweenService:Create(inst, info, props):Play()
    end)
end

local function applyAccentColor(color3)
    settingsData.accentColor = {color3.R, color3.G, color3.B}
    -- In a large library you'd update relevant elements here
end

-- =========================
-- Close Button + Dragging
-- =========================
local function makeTopBarAndClose(mainFrame)
    TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 28)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = mainFrame

    -- Close Button
    CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -30, 0, 0)
    CloseBtn.Text = "X"
    CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    CloseBtn.TextColor3 = Color3.fromRGB(220, 80, 80)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TopBar
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function()
        safeTween(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)})
    end)
    CloseBtn.MouseLeave:Connect(function()
        safeTween(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)})
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end)

    -- Dragging
    local draggingUI, dragStart, startPos, dragInput
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingUI = true
            dragStart = input.Position
            startPos = mainFrame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    draggingUI = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and draggingUI then
            update(input)
        end
    end)
end

-- =========================
-- Dropdown Widget
-- =========================
function LuaUIX.CreateDropdown(parent, name, options, defaultIndex, callback)
    options = options or {}
    local dropdownOpen = false
    local currentSelection = defaultIndex or 1

    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Size = UDim2.new(1, 0, 0, 32)
    DropdownFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    DropdownFrame.Parent = parent
    Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0,6)

    local DropdownLabel = Instance.new("TextLabel")
    DropdownLabel.Size = UDim2.new(1, -30, 1, 0)
    DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
    DropdownLabel.BackgroundTransparency = 1
    DropdownLabel.Text = name .. ": " .. (options[currentSelection] or "")
    DropdownLabel.TextColor3 = Color3.fromRGB(200,200,200)
    DropdownLabel.Font = Enum.Font.Gotham
    DropdownLabel.TextSize = 14
    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    DropdownLabel.Parent = DropdownFrame

    local DropdownButton = Instance.new("TextButton")
    DropdownButton.Size = UDim2.new(1, 0, 1, 0)
    DropdownButton.BackgroundTransparency = 1
    DropdownButton.Text = ""
    DropdownButton.Parent = DropdownFrame

    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 20, 0, 20)
    Arrow.Position = UDim2.new(1, -25, 0.5, -10)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = Color3.fromRGB(200,200,200)
    Arrow.Font = Enum.Font.Gotham
    Arrow.TextSize = 12
    Arrow.Parent = DropdownFrame

    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
    OptionsFrame.Position = UDim2.new(0, 0, 1, 5)
    OptionsFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    OptionsFrame.ClipsDescendants = true
    OptionsFrame.Parent = DropdownFrame
    Instance.new("UICorner", OptionsFrame).CornerRadius = UDim.new(0,6)

    local OptionsLayout = Instance.new("UIListLayout")
    OptionsLayout.Parent = OptionsFrame
    OptionsLayout.Padding = UDim.new(0,4)

    local function updateDropdown()
        DropdownLabel.Text = name .. ": " .. (options[currentSelection] or "")
        if callback then
            pcall(callback, options[currentSelection], currentSelection)
        end
        -- persist
        widgetRegistry.dropdowns[name] = currentSelection
    end

    local function toggleDropdown()
        dropdownOpen = not dropdownOpen
        if dropdownOpen then
            local height = #options * 30
            safeTween(OptionsFrame, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, height)})
            safeTween(Arrow, TweenInfo.new(0.18), {Rotation = 180})
        else
            safeTween(OptionsFrame, TweenInfo.new(0.18), {Size = UDim2.new(1, 0, 0, 0)})
            safeTween(Arrow, TweenInfo.new(0.18), {Rotation = 0})
        end
    end

    for i, option in ipairs(options) do
        local OptionButton = Instance.new("TextButton")
        OptionButton.Size = UDim2.new(1, -10, 0, 28)
        OptionButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
        OptionButton.Text = option
        OptionButton.TextColor3 = Color3.fromRGB(200,200,200)
        OptionButton.Font = Enum.Font.Gotham
        OptionButton.TextSize = 14
        OptionButton.Parent = OptionsFrame
        Instance.new("UICorner", OptionButton).CornerRadius = UDim.new(0,4)

        OptionButton.MouseButton1Click:Connect(function()
            currentSelection = i
            updateDropdown()
            toggleDropdown()
        end)
    end

    DropdownButton.MouseButton1Click:Connect(toggleDropdown)

    updateDropdown()

    return {
        Set = function(index)
            if index >= 1 and index <= #options then
                currentSelection = index
                updateDropdown()
            end
        end,
        Get = function()
            return currentSelection, options[currentSelection]
        end
    }
end

-- =========================
-- Textbox Widget
-- =========================
function LuaUIX.CreateTextbox(parent, name, placeholder, callback, validation)
    local TextboxFrame = Instance.new("Frame")
    TextboxFrame.Size = UDim2.new(1, 0, 0, 50)
    TextboxFrame.BackgroundTransparency = 1
    TextboxFrame.Parent = parent

    local TextboxLabel = Instance.new("TextLabel")
    TextboxLabel.Size = UDim2.new(1, 0, 0, 20)
    TextboxLabel.BackgroundTransparency = 1
    TextboxLabel.Text = name
    TextboxLabel.TextColor3 = Color3.fromRGB(200,200,200)
    TextboxLabel.Font = Enum.Font.Gotham
    TextboxLabel.TextSize = 14
    TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextboxLabel.Parent = TextboxFrame

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, 0, 0, 30)
    InputBox.Position = UDim2.new(0, 0, 0, 20)
    InputBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    InputBox.TextColor3 = Color3.fromRGB(200,200,200)
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 14
    InputBox.PlaceholderText = placeholder or ""
    InputBox.Text = ""
    InputBox.Parent = TextboxFrame
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0,6)

    InputBox.FocusLost:Connect(function(enterPressed)
        if validation and not pcall(function() return validation(InputBox.Text) end) then
            safeTween(InputBox, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60,40,40)})
            task.wait(0.45)
            safeTween(InputBox, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40,40,40)})
        else
            if callback then
                pcall(callback, InputBox.Text)
            end
            widgetRegistry.textboxes[name] = InputBox.Text
        end
    end)

    return {
        SetText = function(text)
            InputBox.Text = text
        end,
        GetText = function()
            return InputBox.Text
        end
    }
end

-- =========================
-- Keybind Picker
-- =========================
function LuaUIX.CreateKeybindPicker(parent, name, defaultKey, callback)
    local listening = false
    local currentKey = defaultKey or Enum.KeyCode.RightControl

    local KeybindFrame = Instance.new("Frame")
    KeybindFrame.Size = UDim2.new(1, 0, 0, 32)
    KeybindFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    KeybindFrame.Parent = parent
    Instance.new("UICorner", KeybindFrame).CornerRadius = UDim.new(0,6)

    local KeybindLabel = Instance.new("TextLabel")
    KeybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
    KeybindLabel.Position = UDim2.new(0, 10, 0, 0)
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.Text = name
    KeybindLabel.TextColor3 = Color3.fromRGB(200,200,200)
    KeybindLabel.Font = Enum.Font.Gotham
    KeybindLabel.TextSize = 14
    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeybindLabel.Parent = KeybindFrame

    local KeybindButton = Instance.new("TextButton")
    KeybindButton.Size = UDim2.new(0.35, 0, 0, 24)
    KeybindButton.Position = UDim2.new(0.6, 5, 0.5, -12)
    KeybindButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
    KeybindButton.Text = tostring(currentKey):gsub("Enum.KeyCode.", "")
    KeybindButton.TextColor3 = Color3.fromRGB(200,200,200)
    KeybindButton.Font = Enum.Font.Gotham
    KeybindButton.TextSize = 14
    KeybindButton.Parent = KeybindFrame
    Instance.new("UICorner", KeybindButton).CornerRadius = UDim.new(0,4)

    local function setKey(key)
        currentKey = key
        KeybindButton.Text = tostring(key):gsub("Enum.KeyCode.", "")
        widgetRegistry.keybinds[name] = tostring(key)
        if callback then
            pcall(callback, key)
        end
    end

    KeybindButton.MouseButton1Click:Connect(function()
        listening = true
        KeybindButton.Text = "..."
        KeybindButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                setKey(input.KeyCode)
                KeybindButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
                connection:Disconnect()
            end
        end)
    end)

    -- allow programmatic set/get
    return {
        SetKey = setKey,
        GetKey = function()
            return currentKey
        end
    }
end

-- =========================
-- Persistence (save/load)
-- =========================
local function saveAllSettings()
    local data = {
        window = {
            position = {MainFrame.Position.X.Scale, MainFrame.Position.X.Offset,
                        MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset},
            size = {MainFrame.Size.X.Scale, MainFrame.Size.X.Offset,
                    MainFrame.Size.Y.Scale, MainFrame.Size.Y.Offset}
        },
        accentColor = settingsData.accentColor or {0.424, 0.471, 0.906},
        widgets = widgetRegistry
    }

    if canFile then
        pcall(function()
            writefile(SAVE_FILE, HttpService:JSONEncode(data))
        end)
    end
end

local function loadAllSettings()
    if canFile and isfile(SAVE_FILE) then
        pcall(function()
            local raw = readfile(SAVE_FILE)
            local data = HttpService:JSONDecode(raw)
            settingsData = data or settingsData
            if data and data.window and MainFrame then
                local p = data.window.position
                local s = data.window.size
                if p and s then
                    MainFrame.Position = UDim2.new(p[1], p[2], p[3], p[4])
                    MainFrame.Size = UDim2.new(s[1], s[2], s[3], s[4])
                end
            end
            if data and data.accentColor then
                applyAccentColor(Color3.new(data.accentColor[1], data.accentColor[2], data.accentColor[3]))
            end
            if data and data.widgets then
                widgetRegistry = data.widgets
            end
        end)
    end
end

-- Save on close or periodically
spawn(function()
    while ScreenGui.Parent do
        task.wait(10)
        pcall(saveAllSettings)
    end
end)

-- =========================
-- Notification System
-- =========================
local notificationQueue = {}
local showingNotification = false

local function processNextNotification()
    if #notificationQueue == 0 then
        showingNotification = false
        return
    end

    showingNotification = true
    local notif = table.remove(notificationQueue, 1)

    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 260, 0, 70)
    Notification.Position = UDim2.new(1, 300, 1, -80) -- start off-screen right
    Notification.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Notification.Parent = ScreenGui
    Instance.new("UICorner", Notification).CornerRadius = UDim.new(0,8)
    Notification.ZIndex = 100

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = notif.title
    Title.TextColor3 = Color3.fromRGB(200,200,200)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Notification

    local Message = Instance.new("TextLabel")
    Message.Size = UDim2.new(1, -10, 0, 40)
    Message.Position = UDim2.new(0, 10, 0, 28)
    Message.BackgroundTransparency = 1
    Message.Text = notif.message
    Message.TextColor3 = Color3.fromRGB(180,180,180)
    Message.Font = Enum.Font.Gotham
    Message.TextSize = 12
    Message.TextXAlignment = Enum.TextXAlignment.Left
    Message.TextYAlignment = Enum.TextYAlignment.Top
    Message.TextWrapped = true
    Message.Parent = Notification

    if notif.type == "success" then
        Title.TextColor3 = Color3.fromRGB(100,200,100)
    elseif notif.type == "warning" then
        Title.TextColor3 = Color3.fromRGB(200,200,100)
    elseif notif.type == "error" then
        Title.TextColor3 = Color3.fromRGB(200,100,100)
    end

    safeTween(Notification, TweenInfo.new(0.26), {Position = UDim2.new(1, -280, 1, -80)})
    task.wait(notif.duration or 4)
    safeTween(Notification, TweenInfo.new(0.26), {Position = UDim2.new(1, 300, 1, -80)})

    task.wait(0.28)
    Notification:Destroy()
    processNextNotification()
end

function LuaUIX.Notify(title, message, duration, typ)
    table.insert(notificationQueue, {title = title or "Notice", message = message or "", duration = duration or 4, type = typ or "info"})
    if not showingNotification then
        processNextNotification()
    end
end

-- =========================
-- Tooltip System
-- =========================
local tooltip = Instance.new("Frame")
tooltip.Size = UDim2.new(0, 160, 0, 40)
tooltip.BackgroundColor3 = Color3.fromRGB(50,50,50)
tooltip.Visible = false
tooltip.ZIndex = 200
tooltip.Parent = ScreenGui
Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0,6)

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(1, -10, 1, -10)
tooltipText.Position = UDim2.new(0, 5, 0, 5)
tooltipText.BackgroundTransparency = 1
tooltipText.TextColor3 = Color3.fromRGB(200,200,200)
tooltipText.Font = Enum.Font.Gotham
tooltipText.TextSize = 12
tooltipText.TextWrapped = true
tooltipText.Parent = tooltip

local function addTooltip(button, text)
    if not button then return end
    button.MouseEnter:Connect(function()
        tooltipText.Text = text
        tooltip.Visible = true
    end)
    button.MouseMoved:Connect(function(x, y)
        tooltip.Position = UDim2.new(0, x + 20, 0, y + 20)
    end)
    button.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

LuaUIX.AddTooltip = addTooltip

-- =========================
-- Mobile support adjustments
-- =========================
local function applyMobileAdjustments()
    if UserInputService.TouchEnabled then
        MainFrame.Size = UDim2.new(0, 520, 0, 320)
        MainFrame.Position = UDim2.new(0.5, -260, 0.5, -160)
        -- other touch tweaks can go here
    end
end

-- =========================
-- Init / Demo UI + Exports
-- =========================
function LuaUIX:Init()
    -- attach screen gui
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- create main frame
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 460, 0, 260)
    MainFrame.Position = UDim2.new(0.5, -230, 0.5, -130)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,6)

    makeTopBarAndClose(MainFrame)
    applyMobileAdjustments()
    loadAllSettings()

    -- Demo content area
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -20, 1, -48)
    Content.Position = UDim2.new(0, 10, 0, 36)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,8)
    layout.Parent = Content

    -- Example: add widgets to demo content
    local dd = LuaUIX.CreateDropdown(Content, "Mode", {"Off","On","Auto"}, 2, function(val) LuaUIX.Notify("Dropdown", "Selected: "..tostring(val), 2, "info") end)
    local tb = LuaUIX.CreateTextbox(Content, "Name", "Enter name...", function(txt) LuaUIX.Notify("Textbox", "Saved: "..txt, 2, "success") end)
    local kb = LuaUIX.CreateKeybindPicker(Content, "Toggle Key", Enum.KeyCode.F, function(key) LuaUIX.Notify("Keybind", "Bound: "..tostring(key).gsub and tostring(key):gsub("Enum.KeyCode.", "") or tostring(key), 2, "info") end)

    -- Add simple tooltip to close button
    addTooltip(CloseBtn, "Close UI")

    -- Persist example widget values into registry so save/load can find them
    widgetRegistry.dropdowns["Mode"] = 2
    widgetRegistry.textboxes["Name"] = ""
    widgetRegistry.keybinds["Toggle Key"] = tostring(Enum.KeyCode.F)

    -- bind mainframe closing saving
    CloseBtn.MouseButton1Click:Connect(function()
        pcall(saveAllSettings)
    end)
end

-- direct utility exports
LuaUIX.CreateDropdown = LuaUIX.CreateDropdown
LuaUIX.CreateTextbox = LuaUIX.CreateTextbox
LuaUIX.CreateKeybindPicker = LuaUIX.CreateKeybindPicker
LuaUIX.Save = saveAllSettings
LuaUIX.Load = loadAllSettings
LuaUIX.Notify = LuaUIX.Notify
LuaUIX.AddTooltip = addTooltip

return LuaUIX
