-- Compatibility surface for the existing nznt game modules.
-- The runtime underneath is CompKiller; this keeps the migration mechanical.
local Compkiller = getgenv().NZNT_COMPKILLER
assert(Compkiller, "nznt CompKiller runtime is missing")

local function imageId(value)
    if value == nil then return Compkiller.Logo end
    local text = tostring(value)
    return text:find("rbxassetid://", 1, true) and text or "rbxassetid://" .. text
end

local function sectionFor(tab, title)
    return tab:DrawSection({Name = title or ""})
end

local function wrapSection(section)
    local proxy = {}

    function proxy:CreateSection(title)
        return wrapSection(sectionFor(section.__tab, title))
    end

    function proxy:CreateToggle(config, flag)
        config = config or {}
        local control = section:AddToggle({
            Name = config.Name,
            Default = config.CurrentValue == true,
            Flag = flag,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        return control
    end

    function proxy:CreateButton(config)
        config = config or {}
        return section:AddButton({Name = config.Name, Callback = config.Callback})
    end

    function proxy:CreateSlider(config)
        config = config or {}
        local range = config.Range or {0, 100}
        local control = section:AddSlider({
            Name = config.Name,
            Default = config.CurrentValue or range[1],
            Min = range[1],
            Max = range[2],
            Round = config.Increment and 2 or 0,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        return control
    end

    function proxy:CreateInput(config)
        config = config or {}
        local control = section:AddTextBox({
            Name = config.Name,
            Default = "",
            Placeholder = config.PlaceholderText or "",
            Callback = config.Callback
        })
        control.Set = control.SetValue
        return control
    end

    function proxy:CreateDropdown(config)
        config = config or {}
        local control = section:AddDropdown({
            Name = config.Name,
            Default = config.CurrentOption or config.CurrentValue,
            Values = config.Options or config.Values or {},
            Multi = config.Multi == true,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        return control
    end

    function proxy:CreateParagraph(config)
        config = config or {}
        return section:AddParagraph({
            Title = config.Title or "",
            Content = config.Text or config.Content or ""
        })
    end

    return proxy
end

local function wrapTab(tab)
    local proxy = {__tab = tab}

    function proxy:CreateSection(title)
        local section = sectionFor(tab, title)
        section.__tab = tab
        return wrapSection(section)
    end

    function proxy:Select()
        return self
    end

    return proxy
end

local function createWindow(config)
    config = config or {}
    local window = Compkiller.new({
        Name = config.Name or "nznt's hub",
        Logo = imageId(config.Logo or config.LogoID or config.Icon),
        Keybind = config.Keybind or "RightControl",
        Scale = config.Scale
    })

    local proxy = {__window = window, __tabs = {}}

    function proxy:CreateTab(configOrName, maybeIcon)
        local config = type(configOrName) == "table" and configOrName or {
            Name = configOrName,
            Icon = maybeIcon or "layout-dashboard"
        }
        local tab = wrapTab(window:DrawTab({
            Name = config.Name or "Tab",
            Icon = config.Icon or "layout-dashboard",
            Type = "Single"
        }))
        table.insert(self.__tabs, tab)
        return tab
    end

    function proxy:CreateHomeTab()
        return self:CreateTab("Home", "home")
    end

    function proxy:Notification(config)
        config = config or {}
        return window.Notify.new({
            Title = config.Title or "nznt's hub",
            Content = config.Content or "",
            Icon = config.Icon or "info",
            Duration = config.Lifetime or 3
        })
    end

    function proxy:SetOpen(value)
        window:Toggle(value ~= false)
    end

    function proxy:BuildThemeSection()
        return self
    end

    function proxy:BuildConfigSection()
        return self
    end

    return proxy
end

getgenv().NZNT_COMPKILLER_COMPAT = {
    CreateWindow = createWindow
}

return getgenv().NZNT_COMPKILLER_COMPAT
