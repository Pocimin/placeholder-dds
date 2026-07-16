-- Small Arcane-shaped facade backed by the bundled CompKiller runtime.
local env = (getgenv and getgenv()) or _G
local Compkiller = env.NZNT_COMPKILLER
assert(Compkiller, "nznt CompKiller runtime is missing")

local LOGO = "rbxassetid://75353810328300"
local WARNING_TEXT = "Warning! Normal config changes can cause kicks or bans. Use carefully."

local function sectionFor(tab, config)
    config = config or {}
    return tab:DrawSection({
        Name = config.Name or "Section",
        Position = config.Position or "left"
    })
end

local function wrapSection(section)
    local proxy = {}

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

    function proxy:Button(config)
        config = config or {}
        return section:AddButton({Name = config.Name, Callback = config.Callback})
    end

    function proxy:Slider(config)
        config = config or {}
        local control = section:AddSlider({
            Name = config.Name,
            Flag = config.Flag,
            Default = config.Default ~= nil and config.Default or config.CurrentValue,
            Min = config.Min or (config.Range and config.Range[1]) or 0,
            Max = config.Max or (config.Range and config.Range[2]) or 100,
            Round = config.Round or 2,
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
            Default = config.Default ~= nil and config.Default or config.CurrentOption,
            Values = config.Values or config.Options or {},
            Multi = config.Multi == true,
            Callback = config.Callback
        })
        control.Set = control.SetValue
        control.Refresh = control.SetValues
        return control
    end

    function proxy:Label(text)
        local paragraph = section:AddParagraph({Title = tostring(text or ""), Content = ""})
        return {
            SetText = function(_, value) paragraph:SetTitle(tostring(value or "")) end,
            Set = function(_, value) paragraph:SetTitle(tostring(value or "")) end
        }
    end

    function proxy:Paragraph(config)
        config = config or {}
        return section:AddParagraph({
            Title = config.Name or config.Title or "",
            Content = config.Content or config.Text or ""
        })
    end

    return proxy
end

local function makePage(window, config)
    config = config or {}
    local tab = window:DrawTab({
        Name = config.Name or "Page",
        Icon = config.Icon or "layout-dashboard",
        Type = "Single"
    })
    local page = {Tab = tab, Active = false}

    function page:Turn(value)
        self.Active = value ~= false
        return self
    end

    function page:Section(sectionConfig)
        return wrapSection(sectionFor(tab, sectionConfig))
    end

    function page:SubPage(subConfig)
        return self
    end

    return page
end

local function makeWindow(options)
    options = options or {}
    local window = Compkiller.new({
        Name = options.Name or "nznt's hub",
        Logo = options.Logo or LOGO,
        Keybind = options.Keybind or "RightControl",
        Scale = options.Scale
    })

    local root = window.Root
    if root then
        root.Name = "NZNT_CompKiller"
        root.DisplayOrder = 2147483645
        root.IgnoreGuiInset = true
        root.ZIndexBehavior = Enum.ZIndexBehavior.Global
    end

    local mainFrame = root and root:FindFirstChildWhichIsA("Frame")
    local overlay = Instance.new("Frame")
    overlay.Name = "NZNT_BlackScreenOverlay"
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromScale(0, 0)
    overlay.ZIndex = 1
    overlay.Visible = false
    overlay.Parent = root

    local items = {
        MainFrame = {Instance = mainFrame},
        OpenButton = {Instance = Instance.new("Frame")},
        Minimize = {Instance = Instance.new("Frame")},
        Close = {Instance = Instance.new("Frame")}
    }
    for _, item in pairs({items.OpenButton, items.Minimize, items.Close}) do
        item.Instance.Visible = false
    end

    local proxy = {Items = items, IsOpen = true}

    function proxy:Category(_)
        return self
    end

    function proxy:Page(config)
        return makePage(window, config)
    end

    function proxy:SetOpen(value)
        self.IsOpen = value ~= false
        window:SetVisible(self.IsOpen)
    end

    local holder = {Instance = root}
    local ui = {
        Library = {Holder = holder},
        Window = proxy,
        BlackOverlay = overlay,
        StatsPage = nil,
        ConfigPage = nil,
        WebhookPage = nil,
        MonitoringPage = nil
    }

    function ui:Notify(text, duration, icon)
        return window.Notify.new({
            Title = options.Name or "nznt's hub",
            Content = tostring(text or ""),
            Icon = icon or LOGO,
            Duration = duration or 5
        })
    end

    function ui:SetBlackScreen(value)
        overlay.Visible = value == true
        overlay.ZIndex = value and 999 or 1
        if mainFrame then mainFrame.ZIndex = value and 1000 or 4 end
    end

    return ui, proxy, window, root
end

local Helper = {}

function Helper:Window(options)
    local ui, windowProxy, _, root = makeWindow(options or {})
    self.Holder = {Instance = root}
    self.LastWindow = windowProxy
    return windowProxy
end

function Helper.CreateFarmWindow(options)
    local ui, windowProxy, window, root = makeWindow(options)
    local farmPage = makePage(window, {
        Name = (options and (options.PageName or options.Page)) or "Auto Drive",
        Icon = options and (options.PageIcon or options.Icon) or "layout-dashboard"
    })

    ui.StatsNav = farmPage
    ui.ConfigNav = farmPage
    ui.WebhookNav = farmPage
    ui.StatsPage = makePage(window, {Name = "Stats", Icon = "bar-chart-3"})
    ui.ConfigPage = makePage(window, {Name = "AutoFarm Config", Icon = "settings-2"})
    ui.WebhookPage = options and options.Webhook == false and nil or makePage(window, {Name = "Webhook", Icon = "webhook"})
    ui.MonitoringPage = options and options.Monitoring and makePage(window, {Name = "Monitoring", Icon = "activity"}) or nil
    ui.Window = windowProxy
    ui.Library.Holder.Instance = root
    return ui
end

function Helper.MakeStat(section, name, defaultValue)
    local label = section:Label(name .. ": " .. tostring(defaultValue or ""))
    local stat = {Value = tostring(defaultValue or ""), Label = label, Name = name}

    function stat:Set(value)
        self.Value = tostring(value or "")
        if self.Label and self.Label.SetText then
            self.Label:SetText(self.Name .. ": " .. self.Value)
        end
    end

    return setmetatable(stat, {
        __newindex = function(self, key, value)
            if key == "Text" then self:Set(value) else rawset(self, key, value) end
        end,
        __index = function(self, key)
            if key == "Text" then return rawget(self, "Value") end
            return rawget(stat, key)
        end
    })
end

function Helper.MakeLockedConfig(ui, options)
    options = options or {}
    local state = {Unlocked = false, WarningText = options.WarningText or WARNING_TEXT}
    if options.Section then
        options.Section:Button({
            Name = options.ButtonName or "Unlock Normal Config",
            Callback = function()
                state.Unlocked = true
                if state.OnUnlock then state.OnUnlock() end
                if ui and ui.Notify then ui:Notify(state.WarningText, 7) end
            end
        })
    end
    function state:Guard(onLocked)
        if self.Unlocked then return true end
        if ui and ui.Notify then ui:Notify(self.WarningText, 7) end
        if onLocked then onLocked() end
        return false
    end
    return state
end

function Helper.MakeBlackScreenToggle(ui, section, flag)
    if not ui or not section then return end
    section:Toggle({
        Name = "Black Screen",
        Flag = flag or "NZNTBlackScreen",
        Default = false,
        Callback = function(value) ui:SetBlackScreen(value) end
    })
end

env.NZNT_COMPKILLER_ARCANE_COMPAT = Helper
return Helper
