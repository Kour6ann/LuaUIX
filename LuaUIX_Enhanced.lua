        local btn = new("TextButton", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 10 + (#self.Tabs * 50)),
            BackgroundColor3 = theme.Section,
            Text = name,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Text,
            Parent = self.Sidebar
        })
        roundify(btn, 8)
        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(self.Pages) do p.Visible = false end
            page.Visible = true
        end)
        if #self.Tabs == 0 then page.Visible = true end

        local Tab = { Page = page, Sections = {}, Parent = self }

        -- Section
        function Tab:NewSection(title)
            local section = new("Frame", {
                Size = UDim2.new(1, -20, 0, 150),
                BackgroundColor3 = theme.Section,
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = page
            })
            roundify(section, 10)

            local pad = Instance.new("UIPadding", section)
            pad.PaddingTop = UDim.new(0, 10)
            pad.PaddingLeft = UDim.new(0, 10)
            pad.PaddingRight = UDim.new(0, 10)
            pad.PaddingBottom = UDim.new(0, 10)

            local lay = Instance.new("UIListLayout", section)
            lay.Padding = UDim.new(0, 6)
            lay.SortOrder = Enum.SortOrder.LayoutOrder

            -- Auto resize section
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                section.Size = UDim2.new(1, -20, 0, lay.AbsoluteContentSize.Y + 40)
            end)

            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = title or "Section",
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = section
            })

            local Sec = { Parent = self }

            -- TOGGLE
            function Sec:NewToggle(text, default, callback)
                local id = SessionID .. "_Toggle_" .. text
                local btn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = default and theme.Accent or theme.Section,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = theme.Text,
                    AutoButtonColor = false,
                    Parent = section
                })
                roundify(btn, 6)
                local state = default or false

                self.Parent.Config[id] = {
                    Value = state,
                    Set = function(v)
                        state = v
                        btn.BackgroundColor3 = state and theme.Accent or theme.Section
                        if callback then callback(state) end
                    end
                }

                btn.MouseButton1Click:Connect(function()
                    state = not state
                    btn.BackgroundColor3 = state and theme.Accent or theme.Section
                    self.Parent.Config[id].Value = state
                    if callback then callback(state) end
                end)
            end

            -- BUTTON
            function Sec:NewButton(text, callback)
                local btn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = theme.Button,
                    Text = text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 14,
                    TextColor3 = theme.Text,
                    Parent = section
                })
                roundify(btn, 6)
                btn.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
            end

            -- SLIDER
            function Sec:NewSlider(text, min, max, default, callback)
                local id = SessionID .. "_Slider_" .. text
                local frame = new("Frame", {Size = UDim2.new(1,0,0,50),BackgroundTransparency=1,Parent=section})
                local label = new("TextLabel", {
                    Size = UDim2.new(1,0,0,20),BackgroundTransparency=1,
                    Text = text .. ": " .. (default or min),
                    Font = Enum.Font.Gotham,TextSize=14,TextColor3=theme.SubText,
                    TextXAlignment=Enum.TextXAlignment.Left,Parent=frame
                })
                local back = new("Frame", {
                    Size=UDim2.new(1,-20,0,8),Position=UDim2.new(0,10,0,30),
                    BackgroundColor3=Color3.fromRGB(60,60,80),Parent=frame
                })
                roundify(back,4)
                local fill = new("Frame",{Size=UDim2.new((default or min)/max,0,1,0),BackgroundColor3=theme.Accent,Parent=back})
                roundify(fill,4)
                local val = default or min

                self.Parent.Config[id] = {
                    Value = val,
                    Set = function(v)
                        val = v
                        fill.Size = UDim2.new(val/max,0,1,0)
                        label.Text = text .. ": " .. val
                        if callback then callback(val) end
                    end
                }

                local dragging = false
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X-back.AbsolutePosition.X)/back.AbsoluteSize.X,0,1)
                        val = math.floor(min+(max-min)*rel)
                        self.Parent.Config[id].Value = val
                        fill.Size = UDim2.new(rel,0,1,0)
                        label.Text = text .. ": " .. val
                        if callback then callback(val) end
                    end
                end)
                back.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
                back.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            end

            -- DROPDOWN
            function Sec:NewDropdown(text, options, callback)
                local id = SessionID .. "_Dropdown_" .. text
                local frame = new("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Section,Parent=section})
                roundify(frame,6)
                local btn = new("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=text.." ▼",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=frame})
                local list = new("Frame",{Size=UDim2.new(1,0,0,#options*28),BackgroundColor3=theme.Content,Visible=false,Parent=section})
                roundify(list,6)
                Instance.new("UIListLayout",list)

                local current = nil
                self.Parent.Config[id] = {
                    Value = nil,
                    Set = function(v)
                        current = v
                        btn.Text = text..": "..tostring(v)
                        if callback then callback(v) end
                    end
                }

                for _,opt in ipairs(options) do
                    local optBtn = new("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text=opt,
                        Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.SubText,Parent=list})
                    optBtn.MouseButton1Click:Connect(function()
                        current = opt
                        self.Parent.Config[id].Value = opt
                        btn.Text = text..": "..opt
                        list.Visible = false
                        if callback then callback(opt) end
                    end)
                end
                btn.MouseButton1Click:Connect(function() list.Visible=not list.Visible end)
            end

            -- TEXTBOX
            function Sec:NewTextbox(text, default, callback)
                local id = SessionID .. "_Textbox_" .. text
                local box = new("TextBox",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Section,
                    Text=default or "",PlaceholderText=text or "Enter text...",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=section})
                roundify(box,6)

                self.Parent.Config[id] = {
                    Value = default or "",
                    Set = function(v)
                        box.Text = v
                        if callback then callback(v) end
                    end
                }

                box.FocusLost:Connect(function()
                    self.Parent.Config[id].Value = box.Text
                    if callback then callback(box.Text) end
                end)
            end

            -- PARAGRAPH
            function Sec:NewParagraph(title, contentText)
                local frame = new("Frame",{Size=UDim2.new(1,0,0,80),BackgroundColor3=theme.Section,Parent=section})
                roundify(frame,6)
                new("TextLabel",{Size=UDim2.new(1,-10,0,20),Position=UDim2.new(0,5,0,5),BackgroundTransparency=1,
                    Text=title,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=theme.Text,TextXAlignment=Enum.TextXAlignment.Left,Parent=frame})
                new("TextLabel",{Size=UDim2.new(1,-10,1,-25),Position=UDim2.new(0,5,0,25),BackgroundTransparency=1,
                    Text=contentText,Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.SubText,TextWrapped=true,
                    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Parent=frame})
            end

            -- KEYBIND
            function Sec:NewKeybind(text, key, callback)
                local id = SessionID .. "_Keybind_" .. text
                local btn = new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=theme.Section,
                    Text=text.." ["..key.Name.."]",Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=section})
                roundify(btn,6)

                self.Parent.Config[id] = {
                    Value = key.Name,
                    Set = function(v)
                        local newKey = Enum.KeyCode[v] or key
                        key = newKey
                        btn.Text = text.." ["..newKey.Name.."]"
                    end
                }

                UserInputService.InputBegan:Connect(function(i)
                    if i.KeyCode==key then if callback then callback() end end
                end)
            end

            -- COLOR PICKER
            function Sec:NewColorPicker(text, default, callback)
                local id = SessionID .. "_Color_" .. text
                local color = default or theme.Accent
                local btn = new("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=color,Text=text or "Pick Color",
                    Font=Enum.Font.Gotham,TextSize=14,TextColor3=theme.Text,Parent=section})
                roundify(btn,6)

                self.Parent.Config[id] = {
                    Value = {color.R, color.G, color.B},
                    Set = function(v)
                        local c=Color3.new(v[1],v[2],v[3])
                        btn.BackgroundColor3=c
                        if callback then callback(c) end
                    end
                }

                btn.MouseButton1Click:Connect(function()
                    self.Parent.Config[id].Value = {btn.BackgroundColor3.R, btn.BackgroundColor3.G, btn.BackgroundColor3.B}
                    if callback then callback(btn.BackgroundColor3) end
                end)
            end

            table.insert(Tab.Sections, Sec)
            return Sec
        end

        table.insert(self.Tabs, Tab)
        return Tab
    end

    -- CONFIG SAVE/LOAD
    function self:SaveConfig(name)
        if not writefile then return end
        local data = {}
        for id, entry in pairs(self.Config) do
            data[id] = entry.Value
        end
        writefile(name..".json", HttpService:JSONEncode(data))
    end

    function self:LoadConfig(name)
        if not readfile then return end
        local raw = readfile(name..".json")
        local data = HttpService:JSONDecode(raw)
        for id, val in pairs(data) do
            if self.Config[id] and self.Config[id].Set then
                self.Config[id].Set(val)
                self.Config[id].Value = val
            end
        end
    end

    return self
end

return Library
