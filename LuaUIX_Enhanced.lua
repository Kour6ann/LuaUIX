-- LuaUIX v1.0
-- Clean API + 6 Themes + Advanced Widgets + Config System + Titlebar Controls

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

if CoreGui:FindFirstChild("LuaUIX_Library") then
    CoreGui.LuaUIX_Library:Destroy()
end

local function new(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do inst[k] = v end
    return inst
end
local function roundify(frame, radius)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, radius or 8)
end

-- Themes
local Themes = {
    Dark = {Window=Color3.fromRGB(33,34,44),Titlebar=Color3.fromRGB(46,46,66),
        Sidebar=Color3.fromRGB(27,28,37),Content=Color3.fromRGB(40,42,54),
        Section=Color3.fromRGB(23,25,34),Accent=Color3.fromRGB(56,172,212),
        Button=Color3.fromRGB(90,120,255),Text=Color3.fromRGB(255,255,255),SubText=Color3.fromRGB(200,200,200)},
    Light = {Window=Color3.fromRGB(245,245,245),Titlebar=Color3.fromRGB(220,220,230),
        Sidebar=Color3.fromRGB(230,230,240),Content=Color3.fromRGB(255,255,255),
        Section=Color3.fromRGB(240,240,245),Accent=Color3.fromRGB(66,135,245),
        Button=Color3.fromRGB(50,100,255),Text=Color3.fromRGB(30,30,30),SubText=Color3.fromRGB(80,80,80)},
    Midnight = {Window=Color3.fromRGB(20,20,30),Titlebar=Color3.fromRGB(25,25,40),
        Sidebar=Color3.fromRGB(15,15,25),Content=Color3.fromRGB(30,30,45),
        Section=Color3.fromRGB(20,20,30),Accent=Color3.fromRGB(180,60,255),
        Button=Color3.fromRGB(120,60,200),Text=Color3.fromRGB(255,255,255),SubText=Color3.fromRGB(180,180,200)},
    Discord = {Window=Color3.fromRGB(54,57,63),Titlebar=Color3.fromRGB(47,49,54),
        Sidebar=Color3.fromRGB(41,43,47),Content=Color3.fromRGB(54,57,63),
        Section=Color3.fromRGB(47,49,54),Accent=Color3.fromRGB(114,137,218),
        Button=Color3.fromRGB(88,101,242),Text=Color3.fromRGB(255,255,255),SubText=Color3.fromRGB(200,200,200)},
    Solarized = {Window=Color3.fromRGB(0,43,54),Titlebar=Color3.fromRGB(7,54,66),
        Sidebar=Color3.fromRGB(0,43,54),Content=Color3.fromRGB(0,43,54),
        Section=Color3.fromRGB(7,54,66),Accent=Color3.fromRGB(181,137,0),
        Button=Color3.fromRGB(203,75,22),Text=Color3.fromRGB(238,232,213),SubText=Color3.fromRGB(147,161,161)},
    Emerald = {Window=Color3.fromRGB(10,30,20),Titlebar=Color3.fromRGB(20,60,40),
        Sidebar=Color3.fromRGB(15,45,30),Content=Color3.fromRGB(20,60,40),
        Section=Color3.fromRGB(15,40,25),Accent=Color3.fromRGB(80,200,120),
        Button=Color3.fromRGB(60,180,100),Text=Color3.fromRGB(220,255,220),SubText=Color3.fromRGB(150,200,160)}
}

local Library = {}
Library.__index = Library

function Library:CreateLib(title, themeName)
    local theme = Themes[themeName] or Themes.Dark
    local self = setmetatable({}, Library)
    self.Tabs = {}
    self.Pages = {}

    local gui = new("ScreenGui",{Name="LuaUIX_Library", ResetOnSpawn=false, Parent=CoreGui})
    local window = new("Frame",{Size=UDim2.new(0,650,0,500),Position=UDim2.new(0.5,-325,0.5,-250),BackgroundColor3=theme.Window,Parent=gui})
    roundify(window,12)

    local titlebar = new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=theme.Titlebar,Parent=window})
    roundify(titlebar,12)
    new("TextLabel",{Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=title or "LuaUIX",
        Font=Enum.Font.GothamBold,TextSize=16,TextColor3=theme.Text,TextXAlignment=Enum.TextXAlignment.Left,Parent=titlebar})

    local closeBtn=new("TextButton",{Size=UDim2.new(0,40,1,0),Position=UDim2.new(1,-40,0,0),BackgroundTransparency=1,Text="✕",
        Font=Enum.Font.GothamBold,TextSize=16,TextColor3=theme.Text,Parent=titlebar})
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    local miniBtn=new("TextButton",{Size=UDim2.new(0,40,1,0),Position=UDim2.new(1,-80,0,0),BackgroundTransparency=1,Text="—",
        Font=Enum.Font.GothamBold,TextSize=16,TextColor3=theme.Text,Parent=titlebar})
    local minimized=false
    miniBtn.MouseButton1Click:Connect(function() minimized=not minimized; window.Visible=not minimized end)

    local sidebar=new("Frame",{Size=UDim2.new(0,150,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=theme.Sidebar,Parent=window})
    roundify(sidebar,12)
    local content=new("Frame",{Size=UDim2.new(1,-150,1,-40),Position=UDim2.new(0,150,0,40),BackgroundColor3=theme.Content,Parent=window})
    roundify(content,12)

    -- Draggable
    local dragging,dragStart,startPos
    titlebar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;dragStart=i.Position;startPos=window.Position end end)
    titlebar.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+(i.Position.X-dragStart.X),startPos.Y.Scale,startPos.Y.Offset+(i.Position.Y-dragStart.Y)) end end)
    titlebar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    -- RightShift toggle
    UserInputService.InputBegan:Connect(function(i) if i.KeyCode==Enum.KeyCode.RightShift then gui.Enabled=not gui.Enabled end end)

    self.Gui=gui; self.Window=window; self.Sidebar=sidebar; self.Content=content; self.Theme=theme

    -- API: NewTab
    function self:NewTab(name)
        local page=new("ScrollingFrame",{Name=name,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ScrollBarThickness=6,Parent=self.Content})
        local layout=Instance.new("UIListLayout",page);layout.Padding=UDim.new(0,10);layout.SortOrder=Enum.SortOrder.LayoutOrder
        self.Pages[name]=page

        local btn=new("TextButton",{Size=UDim2.new(1,-20,0,40),Position=UDim2.new(0,10,0,10+(#self.Tabs*50)),BackgroundColor3=theme.Section,
            Text=name,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=theme.Text,Parent=self.Sidebar})
        roundify(btn,8)
        btn.MouseButton1Click:Connect(function() for _,p in pairs(self.Pages) do p.Visible=false end page.Visible=true end)
        if #self.Tabs==0 then page.Visible=true end

        local Tab={Page=page,Sections={}}
        function Tab:NewSection(title)
            local section=new("Frame",{Size=UDim2.new(1,-20,0,150),BackgroundColor3=theme.Section,AutomaticSize=Enum.AutomaticSize.Y,Parent=page})
            roundify(section,10)
            local pad=Instance.new("UIPadding",section);pad.PaddingTop=UDim.new(0,10);pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10);pad.PaddingBottom=UDim.new(0,10)
            local lay=Instance.new("UIListLayout",section);lay.Padding=UDim.new(0,6);lay.SortOrder=Enum.SortOrder.LayoutOrder
            new("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=title or "Section",Font=Enum.Font.GothamBold,
                TextSize=14,TextColor3=theme.SubText,TextXAlignment=Enum.TextXAlignment.Left,Parent=section})

            local Sec={}
            function Sec:NewToggle(text,default,callback)
                local btn=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=default and theme.Accent or theme.Section,Text=text or "Toggle",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,AutoButtonColor=false,Parent=section})
                roundify(btn,6)
                local state=default or false
                btn.MouseButton1Click:Connect(function() state=not state;btn.BackgroundColor3=state and theme.Accent or theme.Section;if callback then callback(state) end end)
            end
            function Sec:NewButton(text,callback)
                local btn=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Button,Text=text or "Button",
                    Font=Enum.Font.GothamBold,TextSize=14,TextColor3=theme.Text,Parent=section})
                roundify(btn,6)
                btn.MouseButton1Click:Connect(function() if callback then callback() end end)
            end
            function Sec:NewSlider(text,min,max,default,callback)
                local frame=new("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Parent=section})
                local label=new("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=text..": "..(default or min),
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.SubText,TextXAlignment=Enum.TextXAlignment.Left,Parent=frame})
                local back=new("Frame",{Size=UDim2.new(1,-20,0,8),Position=UDim2.new(0,10,0,30),BackgroundColor3=Color3.fromRGB(60,60,80),Parent=frame})
                roundify(back,4)
                local fill=new("Frame",{Size=UDim2.new((default or min)/max,0,1,0),BackgroundColor3=theme.Accent,Parent=back});roundify(fill,4)
                local dragging=false
                UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                    local rel=math.clamp((i.Position.X-back.AbsolutePosition.X)/back.AbsoluteSize.X,0,1)
                    fill.Size=UDim2.new(rel,0,1,0)
                    local val=math.floor(min+(max-min)*rel)
                    label.Text=text..": "..val
                    if callback then callback(val) end
                end end)
                back.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
                back.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            end
            function Sec:NewDropdown(text,options,callback)
                local frame=new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Section,Parent=section})
                roundify(frame,6)
                local btn=new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=text.." ▼",Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=frame})
                local list=new("Frame",{Size=UDim2.new(1,0,0,#options*28),BackgroundColor3=theme.Content,Visible=false,Parent=section});roundify(list,6)
                local layout=Instance.new("UIListLayout",list)
                for _,opt in ipairs(options) do
                    local optBtn=new("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text=opt,Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.SubText,Parent=list})
                    optBtn.MouseButton1Click:Connect(function() btn.Text=text..": "..opt;list.Visible=false;if callback then callback(opt) end end)
                end
                btn.MouseButton1Click:Connect(function() list.Visible=not list.Visible end)
            end
            function Sec:NewTextbox(text,default,callback)
                local box=new("TextBox",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Section,Text=default or "",PlaceholderText=text or "Enter text...",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=section})
                roundify(box,6)
                box.FocusLost:Connect(function() if callback then callback(box.Text) end end)
            end
            function Sec:NewParagraph(title,contentText)
                local frame=new("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=theme.Section,Parent=section});roundify(frame,6)
                new("TextLabel",{Size=UDim2.new(1,-10,0,20),Position=UDim2.new(0,5,0,5),BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=theme.Text,TextXAlignment=Enum.TextXAlignment.Left,Parent=frame})
                new("TextLabel",{Size=UDim2.new(1,-10,1,-25),Position=UDim2.new(0,5,0,25),BackgroundTransparency=1,Text=contentText,Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.SubText,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Parent=frame})
            end
            function Sec:NewKeybind(text,key,callback)
                local btn=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Section,Text=text.." ["..key.Name.."]",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=section});roundify(btn,6)
                UserInputService.InputBegan:Connect(function(i) if i.KeyCode==key then if callback then callback() end end end)
            end
            function Sec:NewColorPicker(text,default,callback)
                local btn=new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=default or theme.Accent,Text=text or "Pick Color",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=section});roundify(btn,6)
                btn.MouseButton1Click:Connect(function() if callback then callback(btn.BackgroundColor3) end end)
            end

            table.insert(Tab.Sections,Sec)
            return Sec
        end

        table.insert(self.Tabs,Tab)
        return Tab
    end

    -- Config Save/Load
    function self:SaveConfig(name)
        if not writefile then return end
        local data={} -- TODO: collect widget states
        writefile(name..".json",HttpService:JSONEncode(data))
    end
    function self:LoadConfig(name)
        if not readfile then return end
        local raw=readfile(name..".json")
        local data=HttpService:JSONDecode(raw)
        -- TODO: apply to widgets
    end

    return self
end

return Library
