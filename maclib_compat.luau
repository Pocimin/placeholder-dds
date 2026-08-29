-- Minimal CompKiller facade for the bundled DDS free loader.
local env = (getgenv and getgenv()) or _G
local Compkiller = env.NZNT_COMPKILLER
assert(Compkiller, "nznt CompKiller runtime is missing")

local function notify(window, config)
    config = config or {}
    return window.Notify.new({
        Title = config.Title or "nznt's hub",
        Content = config.Description or config.Content or "",
        Icon = config.Icon or Compkiller.Logo,
        Duration = config.Lifetime or 3
    })
end

local function wrapSection(section)
    local proxy = {}
    proxy.Root = section.Root

    function proxy:SubText(text)
        return section:AddParagraph({Title = "", Content = tostring(text or "")})
    end

    function proxy:SubLabel(config)
        config = config or {}
        return section:AddParagraph({Title = "", Content = config.Text or config.Content or ""})
    end

    function proxy:Label(config)
        config = type(config) == "table" and config or {Text = config}
        return section:AddParagraph({Title = "", Content = config.Text or config.Content or ""})
    end

    function proxy:Divider()
        return nil
    end

    function proxy:Button(config)
        config = config or {}
        return section:AddButton({Name = config.Name, Callback = config.Callback})
    end

    function proxy:Toggle(config)
        config = config or {}
        local control = section:AddToggle({
            Name = config.Name,
            Flag = config.Flag,
            Default = config.Default == true,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        return control
    end

    function proxy:Slider(config)
        config = config or {}
        local control = section:AddSlider({
            Name = config.Name,
            Flag = config.Flag,
            Default = config.Default,
            Min = config.Minimum or config.Min or 0,
            Max = config.Maximum or config.Max or 100,
            Round = config.Precision or 0,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        return control
    end

    function proxy:Dropdown(config)
        config = config or {}
        local control = section:AddDropdown({
            Name = config.Name,
            Flag = config.Flag,
            Default = config.Default,
            Values = config.Options or config.Values or {},
            Multi = config.Multi == true,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        control.Refresh = control.SetValues
        return control
    end

    return proxy
end

local function createWindow(config)
    config = config or {}
    local window = Compkiller.new({
        Name = config.Title or "nznt's hub",
        Logo = config.Logo or "rbxassetid://75353810328300",
        Keybind = config.Keybind or "RightControl",
        Scale = config.Size
    })

    local proxy = {Root = window.Root, __window = window}

    function proxy:GlobalSetting(setting)
        local control = {Value = setting.Default == true}
        function control:GetValue() return self.Value end
        function control:SetValue(value) self.Value = value; if setting.Callback then setting.Callback(value) end end
        return control
    end

    function proxy:GetAcrylicBlurState() return false end
    function proxy:SetAcrylicBlurState(_) end
    function proxy:GetNotificationsState() return true end
    function proxy:SetNotificationsState(_) end

    function proxy:TabGroup()
        local group = {}
        function group:Tab(tabConfig)
            local tab = window:DrawTab({
                Name = tabConfig.Name or "Tab",
                Icon = tabConfig.Icon or "layout-dashboard",
                Type = "Double"
            })
            local tabProxy = {}
            function tabProxy:Section(sectionConfig)
                return wrapSection(tab:DrawSection({
                    Name = sectionConfig.Name or "Section",
                    Position = sectionConfig.Side or sectionConfig.Position or "Left"
                }))
            end
            function tabProxy:LockedSection(sectionConfig)
                local locked = self:Section({Name = sectionConfig.Name or "Locked", Side = sectionConfig.Side})
                local paragraph = locked.Root and locked.Root.AddParagraph and locked.Root:AddParagraph({
                    Title = "🔒  Buy premium to unlock!",
                    Content = sectionConfig.Description or sectionConfig.LockText or "Premium feature"
                })
                if not paragraph then
                    locked:SubText("🔒  Buy premium to unlock!")
                    locked:Label({Text = sectionConfig.Description or sectionConfig.LockText or "Premium feature"})
                end
                return locked
            end
            function tabProxy:Select() return self end
            return tabProxy
        end
        return group
    end

    function proxy:Notify(config)
        return notify(window, config)
    end

    function proxy:Dialog(config)
        config = config or {}
        local buttons = config.Buttons or {}
        if buttons[1] and buttons[1].Callback then
            return buttons[1].Callback()
        end
    end

    function proxy:SetFolder(_) end
    function proxy:Destroy() window:SetVisible(false) end
    function proxy:Unload() window:SetVisible(false) end

    return proxy
end

env.NZNT_FREE_UI_RUNTIME = {
    Window = function(_, config)
        return createWindow(config)
    end
}
return env.NZNT_FREE_UI_RUNTIME
