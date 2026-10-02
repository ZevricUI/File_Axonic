--[[
    ZeHub UI Library
    A data-driven, modular Roblox Luau UI framework.

    Visual direction:
      - ZeHub branded dark navy / blue / purple dashboard
      - Rounded cards, gradients, glowing borders and soft animations
      - Main dashboard is generated from the script registry
      - No manual Main:AddCard() calls are required

    Public API:
      local ZeHub = require(path.To.ZeHub)

      local Window = ZeHub:CreateWindow({
          Name = "ZeHub",
          Version = "1.0.0",
      })

      local Doors = ZeHub:AddScript({
          Name = "Doors",
          Description = "Doors features and utilities",
          Icon = "door",
          Category = "Game",
          Version = "1.0.0",
      })

      local Main = Doors:AddSection("Main")

      Main:AddToggle({
          Name = "ESP",
          Description = "Enable ESP",
          Default = false,
          Callback = function(value)
              print("ESP:", value)
          end,
      })

    Notes:
      - Script cards/pages are created and removed automatically.
      - The permanent pages are Main, Profile, Settings and Themes.
      - Production builds do not include a demo/preview page.
      - Components support Toggle, Button, Slider, Dropdown, MultiDropdown,
        Keybind, Textbox, ColorPicker, Paragraph, Tooltip, Label and Divider.
      - Configs persist through executor file APIs when available.
      - Dynamic script pages are opened from Main cards; they are not forced
        into the permanent sidebar.
      - Configuration uses Roblox file APIs when available and safely falls
        back to in-memory storage when they are not.
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local ZeHub = {}
ZeHub.__index = ZeHub

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local ScriptMethods = {}
ScriptMethods.__index = ScriptMethods

local SectionMethods = {}
SectionMethods.__index = SectionMethods

local ComponentMethods = {}
ComponentMethods.__index = ComponentMethods

local CONFIG_FOLDER = "ZeHub"
local CONFIG_FILE = "ZeHubConfig.json"

local DEFAULTS = {
    Name = "ZeHub",
    Version = "1.0.0",
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Midnight",
    UIScale = 1,
    AutoScale = true,
    MinUIScale = 0.55,
    MaxUIScale = 1.05,
    Transparency = 0,
    AnimationSpeed = 1,
    ReduceAnimations = false,
    Notifications = true,
    SidebarVisible = true,
    SidebarCollapsed = false,
    CompactMode = false,
    Blur = true,
    Glow = true,
    Rounded = true,
    AutoSave = true,
    ConfigConfirmDelete = true,
    Profile = {
        HideUsername = false,
        HideUserId = false,
        HideProfile = false,
        CompactProfile = false,
    },
}

local THEMES = {
    Midnight = {
        Background = Color3.fromRGB(5, 8, 18),
        Surface = Color3.fromRGB(8, 13, 27),
        Surface2 = Color3.fromRGB(12, 18, 36),
        Card = Color3.fromRGB(10, 17, 32),
        Border = Color3.fromRGB(39, 65, 125),
        Accent = Color3.fromRGB(83, 96, 255),
        Accent2 = Color3.fromRGB(151, 79, 255),
        Text = Color3.fromRGB(242, 246, 255),
        Subtext = Color3.fromRGB(157, 172, 204),
        Muted = Color3.fromRGB(94, 110, 143),
        Positive = Color3.fromRGB(77, 220, 142),
        Warning = Color3.fromRGB(255, 190, 72),
        Negative = Color3.fromRGB(255, 86, 108),
    },

    Cyber = {
        Background = Color3.fromRGB(4, 10, 15),
        Surface = Color3.fromRGB(6, 17, 25),
        Surface2 = Color3.fromRGB(8, 23, 34),
        Card = Color3.fromRGB(7, 19, 29),
        Border = Color3.fromRGB(25, 103, 132),
        Accent = Color3.fromRGB(41, 204, 255),
        Accent2 = Color3.fromRGB(54, 255, 220),
        Text = Color3.fromRGB(235, 253, 255),
        Subtext = Color3.fromRGB(145, 190, 201),
        Muted = Color3.fromRGB(83, 125, 138),
        Positive = Color3.fromRGB(72, 242, 174),
        Warning = Color3.fromRGB(255, 199, 75),
        Negative = Color3.fromRGB(255, 84, 117),
    },

    Violet = {
        Background = Color3.fromRGB(11, 5, 18),
        Surface = Color3.fromRGB(18, 9, 30),
        Surface2 = Color3.fromRGB(26, 12, 43),
        Card = Color3.fromRGB(20, 11, 35),
        Border = Color3.fromRGB(105, 49, 157),
        Accent = Color3.fromRGB(151, 74, 255),
        Accent2 = Color3.fromRGB(242, 76, 208),
        Text = Color3.fromRGB(251, 241, 255),
        Subtext = Color3.fromRGB(190, 158, 211),
        Muted = Color3.fromRGB(126, 96, 145),
        Positive = Color3.fromRGB(81, 227, 160),
        Warning = Color3.fromRGB(255, 192, 73),
        Negative = Color3.fromRGB(255, 84, 126),
    },

    Crimson = {
        Background = Color3.fromRGB(17, 5, 10),
        Surface = Color3.fromRGB(27, 8, 15),
        Surface2 = Color3.fromRGB(40, 10, 20),
        Card = Color3.fromRGB(30, 9, 18),
        Border = Color3.fromRGB(133, 37, 57),
        Accent = Color3.fromRGB(255, 67, 94),
        Accent2 = Color3.fromRGB(185, 38, 76),
        Text = Color3.fromRGB(255, 241, 245),
        Subtext = Color3.fromRGB(204, 153, 165),
        Muted = Color3.fromRGB(144, 93, 106),
        Positive = Color3.fromRGB(77, 225, 148),
        Warning = Color3.fromRGB(255, 190, 70),
        Negative = Color3.fromRGB(255, 80, 91),
    },

    Emerald = {
        Background = Color3.fromRGB(4, 14, 12),
        Surface = Color3.fromRGB(6, 22, 19),
        Surface2 = Color3.fromRGB(8, 31, 26),
        Card = Color3.fromRGB(7, 26, 22),
        Border = Color3.fromRGB(25, 108, 88),
        Accent = Color3.fromRGB(52, 220, 157),
        Accent2 = Color3.fromRGB(27, 178, 157),
        Text = Color3.fromRGB(237, 255, 249),
        Subtext = Color3.fromRGB(143, 192, 177),
        Muted = Color3.fromRGB(82, 132, 119),
        Positive = Color3.fromRGB(77, 231, 152),
        Warning = Color3.fromRGB(255, 194, 73),
        Negative = Color3.fromRGB(255, 84, 112),
    },

    Sunset = {
        Background = Color3.fromRGB(18, 8, 10),
        Surface = Color3.fromRGB(29, 11, 15),
        Surface2 = Color3.fromRGB(43, 13, 21),
        Card = Color3.fromRGB(31, 12, 17),
        Border = Color3.fromRGB(145, 58, 65),
        Accent = Color3.fromRGB(255, 126, 63),
        Accent2 = Color3.fromRGB(229, 65, 166),
        Text = Color3.fromRGB(255, 246, 240),
        Subtext = Color3.fromRGB(207, 168, 153),
        Muted = Color3.fromRGB(147, 107, 99),
        Positive = Color3.fromRGB(78, 224, 145),
        Warning = Color3.fromRGB(255, 200, 73),
        Negative = Color3.fromRGB(255, 78, 104),
    },

    Arctic = {
        Background = Color3.fromRGB(5, 13, 20),
        Surface = Color3.fromRGB(8, 21, 31),
        Surface2 = Color3.fromRGB(10, 29, 42),
        Card = Color3.fromRGB(9, 24, 36),
        Border = Color3.fromRGB(42, 123, 157),
        Accent = Color3.fromRGB(91, 211, 255),
        Accent2 = Color3.fromRGB(82, 164, 255),
        Text = Color3.fromRGB(239, 252, 255),
        Subtext = Color3.fromRGB(151, 191, 208),
        Muted = Color3.fromRGB(87, 130, 149),
        Positive = Color3.fromRGB(77, 231, 160),
        Warning = Color3.fromRGB(255, 196, 73),
        Negative = Color3.fromRGB(255, 83, 112),
    },
}

local ICONS = {
    home = "⌂",
    house = "⌂",
    profile = "●",
    user = "●",
    settings = "⚙",
    gear = "⚙",
    themes = "◈",
    palette = "●",
    search = "⌕",
    arrow = "›",
    back = "‹",
    check = "✓",
    close = "×",
    minus = "−",
    plus = "+",
    door = "▣",
    gamepad = "▰",
    crosshair = "◎",
    combat = "◎",
    movement = "ϟ",
    lightning = "ϟ",
    visuals = "◉",
    eye = "◉",
    world = "◎",
    globe = "◎",
    player = "●",
    save = "▣",
    reset = "↻",
    info = "i",
    success = "✓",
    warning = "!",
    error = "×",
    star = "★",
    script = "◆",
    discord = "◈",
    copy = "▣",
    lock = "●",
    list = "☷",
    monitor = "▣",
    mobile = "▯",
    sliders = "≡",
    folder = "▰",
    refresh = "↻",
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for k, v in pairs(value) do
        result[k] = deepCopy(v)
    end
    return result
end

local function merge(defaults, values)
    local result = deepCopy(defaults)

    if type(values) ~= "table" then
        return result
    end

    for k, v in pairs(values) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = merge(result[k], v)
        else
            result[k] = v
        end
    end

    return result
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return
    end

    local args = table.pack(...)
    task.spawn(function()
        local ok, err = xpcall(function()
            callback(table.unpack(args, 1, args.n))
        end, debug.traceback)

        if not ok then
            warn("[ZeHub] Callback error:\n" .. tostring(err))
        end
    end)
end

local function resolveIcon(icon)
    if type(icon) == "number" then
        return "rbxassetid://" .. tostring(icon), true
    end

    if type(icon) == "string" and icon:match("^rbxassetid://") then
        return icon, true
    end

    return ICONS[string.lower(tostring(icon or "script"))] or tostring(icon or ICONS.script), false
end

local function new(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        local ok = pcall(function()
            object[property] = value
        end)

        if not ok then
            warn("[ZeHub] Invalid property:", className, property)
        end
    end

    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
    }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color or Color3.new(1, 1, 1),
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function gradient(parent, colorA, colorB, rotation)
    return new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB),
        }),
        Rotation = rotation or 0,
    }, parent)
end

local function padding(parent, left, top, right, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function tween(instance, info, properties)
    if not instance or instance.Parent == nil then
        return nil
    end

    local t = TweenService:Create(instance, info, properties)
    t:Play()
    return t
end

local function tweenTime(window, base)
    if window and window.Config.ReduceAnimations then
        return 0.05
    end

    return math.max(0.03, base / math.max(0.25, window and window.Config.AnimationSpeed or 1))
end

local function addText(parent, text, size, color, font, properties)
    local props = {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color or Color3.new(1, 1, 1),
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true,
    }

    for k, v in pairs(properties or {}) do
        props[k] = v
    end

    return new("TextLabel", props, parent)
end

local function addButton(parent, properties)
    return new("TextButton", merge({
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
    }, properties), parent)
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition
    local connectionMove
    local connectionEnd

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = target.Position

        connectionEnd = UserInputService.InputEnded:Connect(function(endInput)
            if endInput == input then
                dragging = false
                if connectionEnd then
                    connectionEnd:Disconnect()
                    connectionEnd = nil
                end
            end
        end)
    end)

    connectionMove = UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    return function()
        if connectionMove then
            connectionMove:Disconnect()
        end
        if connectionEnd then
            connectionEnd:Disconnect()
        end
    end
end

--==================================================
-- CONFIGURATION
--==================================================

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(window)
    return setmetatable({
        Window = window,
        Memory = {},
        Current = nil,
        LastSaved = nil,
    }, ConfigManager)
end

function ConfigManager:_fileAPI()
    return type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
        and type(delfile) == "function"
end

function ConfigManager:_ensureFolder()
    if not self:_fileAPI() then
        return false
    end

    if not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end

    return true
end

function ConfigManager:_path(name)
    local clean = tostring(name):gsub("[^%w%-%_]", "_")
    return CONFIG_FOLDER .. "/" .. clean .. ".json"
end

function ConfigManager:Serialize()
    local state = self.Window:_collectState()

    return {
        Theme = self.Window.Config.Theme,
        UI = {
            UIScale = self.Window.Config.UIScale,
            AutoScale = self.Window.Config.AutoScale,
            MinUIScale = self.Window.Config.MinUIScale,
            MaxUIScale = self.Window.Config.MaxUIScale,
            Transparency = self.Window.Config.Transparency,
            AnimationSpeed = self.Window.Config.AnimationSpeed,
            ReduceAnimations = self.Window.Config.ReduceAnimations,
            Notifications = self.Window.Config.Notifications,
            SidebarVisible = self.Window.Config.SidebarVisible,
            SidebarCollapsed = self.Window.Config.SidebarCollapsed,
            CompactMode = self.Window.Config.CompactMode,
            Blur = self.Window.Config.Blur,
            Glow = self.Window.Config.Glow,
            Rounded = self.Window.Config.Rounded,
            AutoSave = self.Window.Config.AutoSave,
            ConfigConfirmDelete = self.Window.Config.ConfigConfirmDelete,
            ToggleKey = self.Window.Config.ToggleKey.Name,
        },
        Profile = deepCopy(self.Window.Config.Profile),
        Components = state,
    }
end

function ConfigManager:SaveConfig(name)
    name = tostring(name or "default")
    local data = self:Serialize()
    local encoded = HttpService:JSONEncode(data)

    self.Memory[name] = encoded
    self.Current = name
    self.LastSaved = os.time()

    if self:_ensureFolder() then
        local ok, err = pcall(writefile, self:_path(name), encoded)
        if not ok then
            warn("[ZeHub] Failed to save config:", err)
        end
    end

    return true
end

function ConfigManager:LoadConfig(name)
    name = tostring(name or "default")

    local encoded = self.Memory[name]

    if self:_fileAPI() and isfile(self:_path(name)) then
        local ok, result = pcall(readfile, self:_path(name))
        if ok and type(result) == "string" then
            encoded = result
        end
    end

    if not encoded then
        return false, "Configuration not found"
    end

    local ok, data = pcall(HttpService.JSONDecode, HttpService, encoded)
    if not ok or type(data) ~= "table" then
        return false, "Invalid configuration"
    end

    self.Current = name
    self.Window._PendingConfig = data
    self.Window:_applyConfig(data)
    return true
end

function ConfigManager:DeleteConfig(name)
    name = tostring(name or "default")
    self.Memory[name] = nil

    if self:_fileAPI() and isfile(self:_path(name)) then
        pcall(delfile, self:_path(name))
    end

    return true
end

function ConfigManager:ListConfigs()
    local result = {}

    for name in pairs(self.Memory) do
        table.insert(result, name)
    end

    if type(listfiles) == "function" and self:_fileAPI() then
        local ok, files = pcall(listfiles, CONFIG_FOLDER)
        if ok and type(files) == "table" then
            for _, file in ipairs(files) do
                local filename = tostring(file):match("([^/\\]+)%.json$")
                if filename then
                    local exists = false
                    for _, current in ipairs(result) do
                        if current == filename then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(result, filename)
                    end
                end
            end
        end
    end

    table.sort(result)
    return result
end

--==================================================
-- COMPONENT BASE
--==================================================

function ComponentMethods:_registerState(id, getter, setter)
    self.Script.Window:_registerComponentState(id, getter, setter)
end

function ComponentMethods:Destroy()
    if self.Instance then
        self.Instance:Destroy()
        self.Instance = nil
    end
end

--==================================================
-- SECTION
--==================================================

function SectionMethods:_contentHeight()
    return self.Content.AbsoluteCanvasSize.Y
end

function SectionMethods:_refresh()
    if self.Window.Config.ReduceAnimations then
        self.PageCanvas.CanvasPosition = self.PageCanvas.CanvasPosition
    end
end

function SectionMethods:AddLabel(options)
    options = type(options) == "string" and {Name = options} or (options or {})
    local id = self.Script:_nextComponentId(options.Id or options.Name or "Label")

    local holder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, options.Height or 32),
    }, self.Content)

    local title = addText(holder, options.Name or options.Text or "", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(0, 1),
    })

    local description = addText(holder, options.Description or "", 12, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 17),
        Visible = options.Description ~= nil,
    })

    local component = setmetatable({
        Script = self.Script,
        Instance = holder,
        Id = id,
        Type = "Label",
    }, ComponentMethods)

    return component
end

function SectionMethods:AddDivider()
    local line = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Border,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
    }, self.Content)

    return setmetatable({
        Script = self.Script,
        Instance = line,
        Type = "Divider",
    }, ComponentMethods)
end

function SectionMethods:AddButton(options)
    options = options or {}

    local id = self.Script:_nextComponentId(options.Id or options.Name or "Button")

    local button = addButton(self.Content, {
        Size = UDim2.new(1, 0, 0, options.Height or 52),
    })
    corner(button, self.Window.Config.Rounded and 11 or 3)
    local buttonStroke = stroke(button, self.Window.Theme.Border, 0.35, 1)

    local iconText = options.Icon or ""
    if iconText ~= "" then
        local icon = addText(button, resolveIcon(iconText), 18, self.Window.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromOffset(34, 34),
            Position = UDim2.fromOffset(10, 9),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        corner(icon, 8)
    end

    local title = addText(button, options.Name or "Button", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -58, 0, 20),
        Position = UDim2.fromOffset(52, 7),
    })

    local desc = addText(button, options.Description or "", 11, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -70, 0, 18),
        Position = UDim2.fromOffset(52, 27),
        Visible = options.Description ~= nil,
    })

    local arrow = addText(button, ICONS.arrow, 22, self.Window.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -36, 0.5, -15),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    button.MouseEnter:Connect(function()
        tween(button, TweenInfo.new(tweenTime(self.Window, 0.14), Enum.EasingStyle.Quad), {
            BackgroundColor3 = self.Window.Theme.Surface2,
        })
        tween(buttonStroke, TweenInfo.new(tweenTime(self.Window, 0.14)), {
            Color = self.Window.Theme.Accent,
            Transparency = 0.05,
        })
        tween(arrow, TweenInfo.new(tweenTime(self.Window, 0.14), Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -31, 0.5, -15),
            TextColor3 = self.Window.Theme.Text,
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, TweenInfo.new(tweenTime(self.Window, 0.14), Enum.EasingStyle.Quad), {
            BackgroundColor3 = self.Window.Theme.Card,
        })
        tween(buttonStroke, TweenInfo.new(tweenTime(self.Window, 0.14)), {
            Color = self.Window.Theme.Border,
            Transparency = 0.35,
        })
        tween(arrow, TweenInfo.new(tweenTime(self.Window, 0.14), Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -36, 0.5, -15),
            TextColor3 = self.Window.Theme.Subtext,
        })
    end)

    button.MouseButton1Click:Connect(function()
        tween(button, TweenInfo.new(0.07), {BackgroundTransparency = 0.35})
        task.delay(0.07, function()
            if button.Parent then
                tween(button, TweenInfo.new(0.12), {BackgroundTransparency = 0})
            end
        end)

        safeCall(options.Callback)
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = button,
        Id = id,
        Type = "Button",
        GetValue = function()
            return nil
        end,
        SetValue = function() end,
    }, ComponentMethods)

    return component
end

function SectionMethods:AddToggle(options)
    options = options or {}

    local id = self.Script:_nextComponentId(options.Id or options.Name or "Toggle")
    local value = options.Default == true

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
    }, self.Content)

    local title = addText(row, options.Name or "Toggle", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -76, 0, 20),
        Position = UDim2.fromOffset(0, 4),
    })

    addText(row, options.Description or "", 11, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -76, 0, 18),
        Position = UDim2.fromOffset(0, 25),
        Visible = options.Description ~= nil,
    })

    local switch = addButton(row, {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -44, 0.5, -12),
    })
    corner(switch, 99)

    local knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = self.Window.Theme.Text,
        BorderSizePixel = 0,
    }, switch)
    corner(knob, 99)

    local function render(animated)
        local bg = value and self.Window.Theme.Accent or self.Window.Theme.Surface2
        local x = value and 23 or 3

        if animated then
            tween(switch, TweenInfo.new(tweenTime(self.Window, 0.16), Enum.EasingStyle.Quad), {
                BackgroundColor3 = bg,
            })
            tween(knob, TweenInfo.new(tweenTime(self.Window, 0.16), Enum.EasingStyle.Quad), {
                Position = UDim2.fromOffset(x, 3),
            })
        else
            switch.BackgroundColor3 = bg
            knob.Position = UDim2.fromOffset(x, 3)
        end
    end

    local function setValue(newValue, fire)
        value = newValue == true
        render(true)
        if fire ~= false then
            safeCall(options.Callback, value)
        end
    end

    switch.MouseButton1Click:Connect(function()
        setValue(not value, true)
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "Toggle",
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }, ComponentMethods)

    component:_registerState(id, function()
        return value
    end, function(newValue)
        setValue(newValue, false)
    end)

    render(false)
    return component
end

function SectionMethods:AddSlider(options)
    options = options or {}

    local id = self.Script:_nextComponentId(options.Id or options.Name or "Slider")
    local min = tonumber(options.Min or options.Minimum or 0) or 0
    local max = tonumber(options.Max or options.Maximum or 100) or 100
    local value = clamp(tonumber(options.Default or min) or min, min, max)
    local decimals = tonumber(options.Decimals or 0) or 0

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 68),
    }, self.Content)

    addText(row, options.Name or "Slider", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.fromOffset(0, 2),
    })

    local valueLabel = addText(row, "", 12, self.Window.Theme.Accent, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(65, 20),
        Position = UDim2.new(1, -65, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    addText(row, options.Description or "", 11, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 22),
        Visible = options.Description ~= nil,
    })

    local bar = addButton(row, {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -10),
    })
    corner(bar, 99)
    bar.BackgroundColor3 = self.Window.Theme.Surface2

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Window.Theme.Accent,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 99)

    local function formatValue(v)
        if decimals <= 0 then
            return tostring(math.floor(v + 0.5))
        end
        return string.format("%." .. tostring(decimals) .. "f", v)
    end

    local function setValue(newValue, fire)
        value = clamp(tonumber(newValue) or min, min, max)
        local alpha = (value - min) / math.max(0.0001, max - min)
        valueLabel.Text = formatValue(value)
        tween(fill, TweenInfo.new(tweenTime(self.Window, 0.1), Enum.EasingStyle.Quad), {
            Size = UDim2.new(alpha, 0, 1, 0),
        })
        if fire ~= false then
            safeCall(options.Callback, value)
        end
    end

    local dragging = false

    local function updateFromInput(input)
        local x = clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
        local alpha = bar.AbsoluteSize.X > 0 and x / bar.AbsoluteSize.X or 0
        local raw = min + (max - min) * alpha

        if decimals > 0 then
            local power = 10 ^ decimals
            raw = math.round(raw * power) / power
        else
            raw = math.round(raw)
        end

        setValue(raw, true)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "Slider",
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }, ComponentMethods)

    component:_registerState(id, function()
        return value
    end, function(newValue)
        setValue(newValue, false)
    end)

    setValue(value, false)
    return component
end

function SectionMethods:AddDropdown(options)
    options = options or {}

    local id = self.Script:_nextComponentId(options.Id or options.Name or "Dropdown")
    local values = options.Values or options.Options or {}
    local current = options.Default
    if current == nil and #values > 0 then
        current = values[1]
    end

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 74),
        ClipsDescendants = false,
        ZIndex = 4,
    }, self.Content)

    addText(row, options.Name or "Dropdown", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(0, 0),
    })

    local dropdown = addButton(row, {
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.fromOffset(0, 28),
        ZIndex = 5,
    })
    corner(dropdown, 9)
    stroke(dropdown, self.Window.Theme.Border, 0.35, 1)

    local selected = addText(dropdown, tostring(current or "Select..."), 12, self.Window.Theme.Text, Enum.Font.Gotham, {
        Size = UDim2.new(1, -38, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        ZIndex = 6,
    })

    addText(dropdown, "⌄", 16, self.Window.Theme.Subtext, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -32, 0.5, -14),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 6,
    })

    local list = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 68),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 30,
    }, row)
    corner(list, 9)
    stroke(list, self.Window.Theme.Border, 0.2, 1)

    local listLayout = new("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)
    padding(list, 5, 5, 5, 5)

    local open = false

    local function close()
        open = false
        list.Visible = false
        list.Size = UDim2.new(1, 0, 0, 0)
    end

    local function setValue(newValue, fire)
        current = newValue
        selected.Text = tostring(current or "Select...")
        if fire ~= false then
            safeCall(options.Callback, current)
        end
    end

    for index, option in ipairs(values) do
        local optionButton = addButton(list, {
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = index,
            ZIndex = 31,
        })

        addText(optionButton, tostring(option), 12, self.Window.Theme.Text, Enum.Font.Gotham, {
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            ZIndex = 32,
        })

        optionButton.MouseButton1Click:Connect(function()
            setValue(option, true)
            close()
        end)
    end

    dropdown.MouseButton1Click:Connect(function()
        open = not open

        if open then
            list.Visible = true
            local height = math.min(180, (#values * 32) + 10)
            tween(list, TweenInfo.new(tweenTime(self.Window, 0.16), Enum.EasingStyle.Quad), {
                Size = UDim2.new(1, 0, 0, height),
            })
        else
            close()
        end
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "Dropdown",
        GetValue = function()
            return current
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }, ComponentMethods)

    component:_registerState(id, function()
        return current
    end, function(newValue)
        setValue(newValue, false)
    end)

    return component
end


function SectionMethods:AddParagraph(options)
    options = options or {}
    local id = self.Script:_nextComponentId(options.Id or options.Name or "Paragraph")

    local holder = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Surface2,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Content)
    corner(holder, 10)
    stroke(holder, self.Window.Theme.Border, 0.3, 1)
    padding(holder, 12, 9, 12, 9)

    addText(holder, options.Name or "Information", 13, self.Window.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, 0, 0, 22),
    })
    addText(holder, options.Content or options.Description or "", 11, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(0, 24),
        TextWrapped = true,
    })

    local component = setmetatable({
        Script = self.Script,
        Instance = holder,
        Id = id,
        Type = "Paragraph",
    }, ComponentMethods)
    return component
end

function SectionMethods:AddTextbox(options)
    options = options or {}
    local id = self.Script:_nextComponentId(options.Id or options.Name or "Textbox")
    local value = tostring(options.Default or "")

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, options.Description and 78 or 58),
    }, self.Content)

    addText(row, options.Name or "Textbox", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, 0, 0, 20),
    })
    addText(row, options.Description or "", 10, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, 20),
        Visible = options.Description ~= nil,
    })

    local box = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.fromOffset(0, options.Description and 38 or 24),
        BackgroundColor3 = self.Window.Theme.Surface2,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = tostring(options.Placeholder or ""),
        PlaceholderColor3 = self.Window.Theme.Muted,
        Text = value,
        TextColor3 = self.Window.Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    corner(box, 9)
    stroke(box, self.Window.Theme.Border, 0.3, 1)
    padding(box, 11, 0, 11, 0)

    local function setValue(newValue, fire)
        value = tostring(newValue or "")
        box.Text = value
        if fire ~= false then
            safeCall(options.Callback, value)
        end
    end

    box.FocusLost:Connect(function()
        setValue(box.Text, true)
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "Textbox",
        GetValue = function() return value end,
        SetValue = function(_, newValue, fire) setValue(newValue, fire) end,
    }, ComponentMethods)

    component:_registerState(id, function() return value end, function(newValue)
        setValue(newValue, false)
    end)

    return component
end

function SectionMethods:AddMultiDropdown(options)
    options = options or {}
    local id = self.Script:_nextComponentId(options.Id or options.Name or "MultiDropdown")
    local values = options.Values or options.Options or {}
    local selected = {}
    for _, item in ipairs(options.Default or {}) do
        selected[tostring(item)] = true
    end

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 76),
        ClipsDescendants = false,
        ZIndex = 8,
    }, self.Content)

    addText(row, options.Name or "Multi Dropdown", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, 0, 0, 20),
    })

    local button = addButton(row, {
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.fromOffset(0, 28),
        BackgroundColor3 = self.Window.Theme.Surface2,
        ZIndex = 9,
    })
    corner(button, 9)
    stroke(button, self.Window.Theme.Border, 0.3, 1)

    local label = addText(button, "", 11, self.Window.Theme.Text, Enum.Font.Gotham, {
        Size = UDim2.new(1, -38, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 10,
    })
    addText(button, "⌄", 16, self.Window.Theme.Subtext, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -32, 0.5, -14),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 10,
    })

    local list = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 68),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 50,
    }, row)
    corner(list, 9)
    stroke(list, self.Window.Theme.Border, 0.2, 1)
    padding(list, 5, 5, 5, 5)

    local listLayout = new("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)

    local open = false
    local optionButtons = {}

    local function summary()
        local result = {}
        for _, item in ipairs(values) do
            if selected[tostring(item)] then
                table.insert(result, tostring(item))
            end
        end
        label.Text = #result > 0 and table.concat(result, ", ") or "Select..."
    end

    local function setValue(newValue, fire)
        selected = {}
        if type(newValue) == "table" then
            for _, item in ipairs(newValue) do
                selected[tostring(item)] = true
            end
        end
        summary()
        for item, info in pairs(optionButtons) do
            info.Text.Text = selected[tostring(item)] and "✓  " .. tostring(item) or "○  " .. tostring(item)
            info.Text.TextColor3 = selected[tostring(item)] and self.Window.Theme.Accent or self.Window.Theme.Text
        end
        if fire ~= false then
            local output = {}
            for _, item in ipairs(values) do
                if selected[tostring(item)] then table.insert(output, item) end
            end
            safeCall(options.Callback, output)
        end
    end

    for index, item in ipairs(values) do
        local optionButton = addButton(list, {
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = index,
            BackgroundTransparency = 1,
            ZIndex = 51,
        })
        local optionText = addText(optionButton, "", 11, self.Window.Theme.Text, Enum.Font.GothamMedium, {
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            ZIndex = 52,
        })
        optionButtons[tostring(item)] = {Button = optionButton, Text = optionText}
        optionButton.MouseButton1Click:Connect(function()
            local key = tostring(item)
            selected[key] = not selected[key]
            setValue((function()
                local output = {}
                for _, value in ipairs(values) do
                    if selected[tostring(value)] then table.insert(output, value) end
                end
                return output
            end)(), true)
        end)
    end

    button.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
        if open then
            local height = math.min(210, #values * 32 + 10)
            list.Size = UDim2.new(1, 0, 0, height)
        else
            list.Size = UDim2.new(1, 0, 0, 0)
        end
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "MultiDropdown",
        GetValue = function()
            local result = {}
            for _, item in ipairs(values) do
                if selected[tostring(item)] then table.insert(result, item) end
            end
            return result
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }, ComponentMethods)

    component:_registerState(id, function() return component:GetValue() end, function(newValue)
        setValue(newValue, false)
    end)

    setValue(options.Default or {}, false)
    return component
end

function SectionMethods:AddColorPicker(options)
    options = options or {}
    local id = self.Script:_nextComponentId(options.Id or options.Name or "ColorPicker")
    local value = typeof(options.Default) == "Color3" and options.Default or self.Window.Theme.Accent

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
    }, self.Content)

    addText(row, options.Name or "Color", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -80, 0, 22),
    })
    addText(row, options.Description or "", 10, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -80, 0, 18),
        Position = UDim2.fromOffset(0, 24),
        Visible = options.Description ~= nil,
    })

    local swatch = addButton(row, {
        Size = UDim2.fromOffset(56, 34),
        Position = UDim2.new(1, -56, 0.5, -17),
        BackgroundColor3 = value,
    })
    corner(swatch, 9)
    stroke(swatch, self.Window.Theme.Border, 0.2, 1)

    local popup = new("Frame", {
        Size = UDim2.fromOffset(210, 110),
        Position = UDim2.new(1, -210, 1, 4),
        BackgroundColor3 = self.Window.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 80,
    }, row)
    corner(popup, 10)
    stroke(popup, self.Window.Theme.Border, 0.15, 1)
    padding(popup, 8, 8, 8, 8)

    local function box(labelText, x)
        addText(popup, labelText, 9, self.Window.Theme.Muted, Enum.Font.GothamBold, {
            Size = UDim2.fromOffset(25, 26),
            Position = UDim2.fromOffset(x, 8),
        })
        local box = new("TextBox", {
            Size = UDim2.fromOffset(42, 26),
            Position = UDim2.fromOffset(x + 22, 8),
            BackgroundColor3 = self.Window.Theme.Surface2,
            BorderSizePixel = 0,
            TextColor3 = self.Window.Theme.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            Text = "255",
            ClearTextOnFocus = false,
        }, popup)
        corner(box, 6)
        return box
    end

    local rBox, gBox, bBox = box("R", 8), box("G", 78), box("B", 148)

    local apply = addButton(popup, {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.fromOffset(8, 48),
        BackgroundColor3 = self.Window.Theme.Accent,
        ZIndex = 81,
    })
    corner(apply, 7)
    addText(apply, "Apply", 10, Color3.new(1, 1, 1), Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 82,
    })

    local function setBoxes(color)
        rBox.Text = tostring(math.floor(color.R * 255 + 0.5))
        gBox.Text = tostring(math.floor(color.G * 255 + 0.5))
        bBox.Text = tostring(math.floor(color.B * 255 + 0.5))
    end

    local function setValue(newValue, fire)
        if typeof(newValue) == "Color3" then
            value = newValue
        end
        swatch.BackgroundColor3 = value
        setBoxes(value)
        if fire ~= false then safeCall(options.Callback, value) end
    end

    swatch.MouseButton1Click:Connect(function()
        popup.Visible = not popup.Visible
        if popup.Visible then setBoxes(value) end
    end)

    apply.MouseButton1Click:Connect(function()
        local r = clamp(tonumber(rBox.Text) or 0, 0, 255)
        local g = clamp(tonumber(gBox.Text) or 0, 0, 255)
        local b = clamp(tonumber(bBox.Text) or 0, 0, 255)
        setValue(Color3.fromRGB(r, g, b), true)
        popup.Visible = false
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "ColorPicker",
        GetValue = function() return value end,
        SetValue = function(_, newValue, fire) setValue(newValue, fire) end,
    }, ComponentMethods)

    component:_registerState(id, function() return {R=value.R, G=value.G, B=value.B} end, function(newValue)
        if type(newValue) == "table" and newValue.R then
            setValue(Color3.new(
                clamp(tonumber(newValue.R) or 0, 0, 1),
                clamp(tonumber(newValue.G) or 0, 0, 1),
                clamp(tonumber(newValue.B) or 0, 0, 1)
            ), false)
        end
    end)

    setValue(value, false)
    return component
end

function SectionMethods:AddTooltip(options)
    options = options or {}
    local id = self.Script:_nextComponentId(options.Id or options.Name or "Tooltip")

    local holder = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
    }, self.Content)

    local text = addText(holder, "ⓘ  " .. tostring(options.Name or "Info"), 11, self.Window.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, 0, 1, 0),
        TextWrapped = true,
    })

    local tip = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Window.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 70,
    }, holder)
    corner(tip, 8)
    stroke(tip, self.Window.Theme.Border, 0.2, 1)
    padding(tip, 9, 7, 9, 7)
    addText(tip, options.Description or options.Content or "", 10, self.Window.Theme.Text, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        ZIndex = 71,
    })

    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            tip.Visible = true
        end
    end)
    holder.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            tip.Visible = false
        end
    end)

    return setmetatable({
        Script = self.Script,
        Instance = holder,
        Id = id,
        Type = "Tooltip",
    }, ComponentMethods)
end

function SectionMethods:AddKeybind(options)
    options = options or {}

    local id = self.Script:_nextComponentId(options.Id or options.Name or "Keybind")
    local key = options.Default or Enum.KeyCode.RightShift
    local listening = false

    local row = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 54),
    }, self.Content)

    addText(row, options.Name or "Keybind", 14, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -120, 0, 22),
        Position = UDim2.fromOffset(0, 4),
    })

    addText(row, options.Description or "", 11, self.Window.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -120, 0, 18),
        Position = UDim2.fromOffset(0, 26),
        Visible = options.Description ~= nil,
    })

    local keyButton = addButton(row, {
        Size = UDim2.fromOffset(105, 34),
        Position = UDim2.new(1, -105, 0.5, -17),
    })
    corner(keyButton, 8)
    stroke(keyButton, self.Window.Theme.Border, 0.2, 1)

    local keyLabel = addText(keyButton, key.Name, 11, self.Window.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local function setValue(newKey, fire)
        if typeof(newKey) == "EnumItem" then
            key = newKey
        end
        keyLabel.Text = key.Name
        if fire ~= false then
            safeCall(options.Callback, key)
        end
    end

    keyButton.MouseButton1Click:Connect(function()
        if listening then
            return
        end

        listening = true
        keyLabel.Text = "Press key..."

        local connection
        connection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end

            if input.UserInputType == Enum.UserInputType.Keyboard then
                setValue(input.KeyCode, true)
                listening = false
                connection:Disconnect()
            end
        end)
    end)

    local component = setmetatable({
        Script = self.Script,
        Instance = row,
        Id = id,
        Type = "Keybind",
        GetValue = function()
            return key
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }, ComponentMethods)

    component:_registerState(id, function()
        return key.Name
    end, function(newValue)
        if type(newValue) == "string" and Enum.KeyCode[newValue] then
            setValue(Enum.KeyCode[newValue], false)
        end
    end)

    return component
end

--==================================================
-- SCRIPT PAGE
--==================================================

function ScriptMethods:_nextComponentId(name)
    self.ComponentCounter += 1
    local safeName = tostring(name):gsub("%s+", "_")
    return self.Id .. "." .. safeName .. "." .. tostring(self.ComponentCounter)
end

function ScriptMethods:AddSection(name)
    local section = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Card,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, self.Content)

    corner(section, self.Window.Config.Rounded and 13 or 3)
    local sectionStroke = stroke(section, self.Window.Theme.Border, 0.3, 1)

    local titleRow = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
    }, section)
    padding(titleRow, 14, 0, 14, 0)

    addText(titleRow, tostring(name or "Section"), 14, self.Window.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -30, 1, 0),
    })

    local content = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, section)

    padding(content, 14, 0, 14, 14)

    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local sectionObject = setmetatable({
        Script = self,
        Window = self.Window,
        Name = tostring(name or "Section"),
        Frame = section,
        Content = content,
        Layout = layout,
        PageCanvas = self.Canvas,
        Stroke = sectionStroke,
    }, SectionMethods)

    table.insert(self.Sections, sectionObject)
    return sectionObject
end

function ScriptMethods:AddLabel(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddLabel(options)
end

function ScriptMethods:AddButton(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddButton(options)
end

function ScriptMethods:AddToggle(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddToggle(options)
end

function ScriptMethods:AddSlider(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddSlider(options)
end

function ScriptMethods:AddDropdown(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddDropdown(options)
end

function ScriptMethods:AddKeybind(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddKeybind(options)
end

function ScriptMethods:AddParagraph(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddParagraph(options)
end

function ScriptMethods:AddTextbox(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddTextbox(options)
end

function ScriptMethods:AddMultiDropdown(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddMultiDropdown(options)
end

function ScriptMethods:AddColorPicker(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddColorPicker(options)
end

function ScriptMethods:AddTooltip(options)
    local section = self.Sections[#self.Sections] or self:AddSection("Main")
    return section:AddTooltip(options)
end

function ScriptMethods:Destroy()
    self.Window:RemoveScript(self.Name)
end

--==================================================
-- WINDOW
--==================================================

function WindowMethods:_registerComponentState(id, getter, setter)
    self.ComponentStates[id] = {
        Get = getter,
        Set = setter,
    }

    -- Configs can be loaded before a script has finished registering its
    -- components. Apply any matching pending value as soon as it appears.
    local pending = self._PendingConfig
    if pending and type(pending.Components) == "table" and pending.Components[id] ~= nil then
        pcall(setter, pending.Components[id])
    end
end

function WindowMethods:_collectState()
    local state = {}

    for id, entry in pairs(self.ComponentStates) do
        local ok, value = pcall(entry.Get)
        if ok then
            state[id] = value
        end
    end

    return state
end

function WindowMethods:_applyConfig(data)
    if type(data) ~= "table" then
        return
    end

    if type(data.UI) == "table" then
        for key, value in pairs(data.UI) do
            if key == "ToggleKey" and type(value) == "string" and Enum.KeyCode[value] then
                self.Config.ToggleKey = Enum.KeyCode[value]
            elseif self.Config[key] ~= nil then
                self.Config[key] = value
            end
        end
    end

    if type(data.Profile) == "table" then
        self.Config.Profile = merge(self.Config.Profile, data.Profile)
    end

    if type(data.Theme) == "string" and THEMES[data.Theme] then
        self:SetTheme(data.Theme, false)
    end

    if type(data.Components) == "table" then
        for id, value in pairs(data.Components) do
            local entry = self.ComponentStates[id]
            if entry then
                pcall(entry.Set, value)
            end
        end
    end

    self:_refreshSettingsVisuals()
end

function WindowMethods:_setPage(name)
    if not self.Pages[name] then
        return
    end

    for pageName, page in pairs(self.Pages) do
        page.Visible = pageName == name
    end

    self.CurrentPage = name

    if name == "Main" then
        self:_renderMain()
    end
end

function WindowMethods:_addPage(name, page)
    self.Pages[name] = page
end

function WindowMethods:_buildWindow()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("ZeHubUI")
    if old then
        old:Destroy()
    end

    self.ScreenGui = new("ScreenGui", {
        Name = "ZeHubUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    }, playerGui)

    self.Root = new("Frame", {
        Name = "Root",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 1120, 0, 700),
        BackgroundTransparency = 1,
    }, self.ScreenGui)

    self.Scale = new("UIScale", {
        Scale = self.Config.UIScale,
    }, self.Root)

    self.Shadow = new("Frame", {
        Name = "Shadow",
        Position = UDim2.fromOffset(10, 12),
        Size = UDim2.new(1, -20, 1, -20),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, self.Root)
    corner(self.Shadow, 26)

    self.Window = new("Frame", {
        Name = "Window",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    }, self.Root)
    corner(self.Window, 24)
    self.WindowStroke = stroke(self.Window, self.Theme.Border, 0.05, 1)

    self.BackgroundGradient = gradient(
        self.Window,
        self.Theme.Background,
        self.Theme.Surface,
        25
    )

    -- Top bar
    self.TopBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, self.Window)

    local logoHolder = new("Frame", {
        Size = UDim2.fromOffset(70, 70),
        Position = UDim2.fromOffset(22, 15),
        BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0,
    }, self.TopBar)
    corner(logoHolder, 17)
    stroke(logoHolder, self.Theme.Border, 0.1, 1)
    gradient(logoHolder, self.Theme.Accent, self.Theme.Accent2, 45)

    addText(logoHolder, "Z", 40, Color3.new(1, 1, 1), Enum.Font.GothamBlack, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = 0.8,
    })

    addText(self.TopBar, "ZEHUB", 22, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(190, 27),
        Position = UDim2.fromOffset(105, 20),
    })

    addText(self.TopBar, "Your modular Roblox script hub", 12, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.fromOffset(230, 20),
        Position = UDim2.fromOffset(106, 48),
    })

    -- Search
    self.SearchFrame = new("Frame", {
        Size = UDim2.new(0, 360, 0, 48),
        Position = UDim2.new(0.5, -180, 0.5, -24),
        BackgroundColor3 = self.Theme.Surface2,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, self.TopBar)
    corner(self.SearchFrame, 13)
    self.SearchStroke = stroke(self.SearchFrame, self.Theme.Border, 0.25, 1)

    addText(self.SearchFrame, ICONS.search, 22, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(35, 35),
        Position = UDim2.fromOffset(8, 6),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    self.SearchBox = new("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        PlaceholderText = "Search anything...",
        PlaceholderColor3 = self.Theme.Subtext,
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -55, 1, 0),
        Position = UDim2.fromOffset(45, 0),
        ZIndex = 7,
    }, self.SearchFrame)

    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:_search(self.SearchBox.Text)
    end)

    -- Theme selector
    self.ThemeButton = addButton(self.TopBar, {
        Size = UDim2.fromOffset(130, 48),
        Position = UDim2.new(1, -190, 0.5, -24),
        BackgroundColor3 = self.Theme.Surface2,
        ZIndex = 6,
    })
    corner(self.ThemeButton, 13)
    stroke(self.ThemeButton, self.Theme.Border, 0.25, 1)

    addText(self.ThemeButton, "●", 20, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(35, 35),
        Position = UDim2.fromOffset(7, 7),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    self.ThemeButtonLabel = addText(self.ThemeButton, self.Config.Theme, 12, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(43, 0),
    })

    self.ThemeButton.MouseButton1Click:Connect(function()
        self:_setPage("Themes")
    end)

    -- Minimize / close
    local minimize = addButton(self.TopBar, {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.new(1, -98, 0.5, -20),
        BackgroundColor3 = self.Theme.Surface2,
        ZIndex = 6,
    })
    corner(minimize, 11)
    addText(minimize, ICONS.minus, 20, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local close = addButton(self.TopBar, {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.new(1, -48, 0.5, -20),
        BackgroundColor3 = self.Theme.Surface2,
        ZIndex = 6,
    })
    corner(close, 11)
    addText(close, ICONS.close, 21, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    minimize.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)

    close.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    makeDraggable(self.TopBar, self.Root)

    -- Main body
    self.Body = new("Frame", {
        Size = UDim2.new(1, 0, 1, -100),
        Position = UDim2.fromOffset(0, 100),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, self.Window)

    -- Sidebar
    self.Sidebar = new("Frame", {
        Size = UDim2.new(0, 260, 1, 0),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, self.Body)
    corner(self.Sidebar, 18)

    padding(self.Sidebar, 14, 18, 14, 14)

    self.NavLayout = new("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.Sidebar)

    self.SidebarToggle = addButton(self.Sidebar, {
        Name = "SidebarToggle",
        Size = UDim2.new(1, 0, 0, 42),
        LayoutOrder = 0,
        BackgroundColor3 = self.Theme.Surface2,
        BackgroundTransparency = 0.2,
        ZIndex = 6,
    })
    corner(self.SidebarToggle, 11)
    stroke(self.SidebarToggle, self.Theme.Border, 0.25, 1)

    self.SidebarToggleIcon = addText(self.SidebarToggle, "‹", 22, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(7, 2),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    self.SidebarToggleLabel = addText(self.SidebarToggle, "Collapse sidebar", 11, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -55, 1, 0),
        Position = UDim2.fromOffset(48, 0),
    })
    self.SidebarToggle.MouseButton1Click:Connect(function()
        self.Config.SidebarCollapsed = not self.Config.SidebarCollapsed
        self:_refreshSettingsVisuals()
        if self.Config.AutoSave then
            self.ConfigManager:SaveConfig("autosave")
        end
    end)

    self:_createNavButton("Main", "home", 1)
    self:_createNavButton("Profile", "profile", 2)
    self:_createNavButton("Settings", "settings", 3)
    self:_createNavButton("Themes", "themes", 4)

    local discordButton = addButton(self.Sidebar, {
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = 100,
        BackgroundColor3 = self.Theme.Surface2,
        ZIndex = 5,
    })
    corner(discordButton, 12)
    stroke(discordButton, self.Theme.Border, 0.35, 1)

    addText(discordButton, ICONS.discord, 20, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.fromOffset(7, 5),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    addText(discordButton, "Join Discord", 12, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -55, 0, 20),
        Position = UDim2.fromOffset(52, 5),
    })

    addText(discordButton, "discord.gg/zehub", 10, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -55, 0, 18),
        Position = UDim2.fromOffset(52, 25),
    })

    discordButton.MouseButton1Click:Connect(function()
        self:Notify({
            Title = "ZeHub Discord",
            Description = "Join us at discord.gg/zehub",
            Duration = 4,
            Type = "Info",
        })
        if setclipboard then
            pcall(setclipboard, "https://discord.gg/zehub")
        end
    end)

    -- Content area
    self.Content = new("Frame", {
        Size = UDim2.new(1, -278, 1, -14),
        Position = UDim2.fromOffset(270, 7),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, self.Body)

    self:_buildPages()

    self:_buildToastContainer()
    self:_buildToggleHint()

    self:_setPage("Main")
    self:_refreshSettingsVisuals()

    self:_bindInput()

    local camera = workspace.CurrentCamera
    if camera then
        self.ViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if not self.Destroyed then
                self:_updateResponsiveScale()
            end
        end)
    end

    self:_refreshSettingsVisuals()

    task.defer(function()
        self.Root.Size = UDim2.new(0, 1050, 0, 650)
        tween(self.Root, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 1120, 0, 700),
        })
    end)
end

function WindowMethods:_createNavButton(name, iconName, order)
    local button = addButton(self.Sidebar, {
        Name = name .. "Nav",
        Size = UDim2.new(1, 0, 0, 54),
        LayoutOrder = order,
        BackgroundColor3 = self.Theme.Surface2,
        BackgroundTransparency = name == "Main" and 0.05 or 1,
        ZIndex = 5,
    })
    corner(button, 12)

    local icon = addText(button, resolveIcon(iconName), 21, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.fromOffset(7, 7),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local label = addText(button, name, 13, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -58, 1, 0),
        Position = UDim2.fromOffset(54, 0),
    })

    button.MouseButton1Click:Connect(function()
        self:_setPage(name)
    end)

    self.NavButtons[name] = {
        Button = button,
        Icon = icon,
        Label = label,
    }
end

function WindowMethods:_buildPages()
    -- Main
    self.MainPage = new("ScrollingFrame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = true,
        ZIndex = 5,
    }, self.Content)
    padding(self.MainPage, 12, 12, 12, 20)

    self.MainLayout = new("UIListLayout", {
        Padding = UDim.new(0, 16),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.MainPage)

    self:_addPage("Main", self.MainPage)

    -- Profile
    self.ProfilePage = new("ScrollingFrame", {
        Name = "Profile",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 5,
    }, self.Content)
    padding(self.ProfilePage, 12, 12, 12, 20)
    self:_addPage("Profile", self.ProfilePage)
    self:_buildProfilePage()

    -- Settings
    self.SettingsPage = new("ScrollingFrame", {
        Name = "Settings",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 5,
    }, self.Content)
    padding(self.SettingsPage, 12, 12, 12, 20)
    self:_addPage("Settings", self.SettingsPage)
    self:_buildSettingsPage()

    -- Themes
    self.ThemesPage = new("ScrollingFrame", {
        Name = "Themes",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 5,
    }, self.Content)
    padding(self.ThemesPage, 12, 12, 12, 20)
    self:_addPage("Themes", self.ThemesPage)
    self:_buildThemesPage()
end

function WindowMethods:_buildPageHeader(parent, title, subtitle, order)
    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, 78),
        BackgroundTransparency = 1,
        LayoutOrder = order or 1,
    }, parent)

    addText(header, title, 26, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.fromOffset(0, 4),
    })

    addText(header, subtitle or "", 12, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 42),
    })

    return header
end

function WindowMethods:_buildProfilePage()
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.ProfilePage)

    self:_buildPageHeader(
        self.ProfilePage,
        "Profile",
        "Your Roblox identity, session details and local privacy controls.",
        1
    )

    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 190),
        BackgroundColor3 = self.Theme.Card,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, self.ProfilePage)
    corner(card, 17)
    stroke(card, self.Theme.Border, 0.18, 1)
    gradient(card, self.Theme.Card, self.Theme.Surface, 15)

    local avatar = new("ImageLabel", {
        Size = UDim2.fromOffset(118, 118),
        Position = UDim2.fromOffset(20, 25),
        BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Crop,
    }, card)
    corner(avatar, 20)

    if LocalPlayer then
        task.spawn(function()
            local ok, image = pcall(function()
                return Players:GetUserThumbnailAsync(
                    LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size150x150
                )
            end)
            if ok and image and avatar.Parent then
                avatar.Image = image
            end
        end)
    end

    local displayName = LocalPlayer and LocalPlayer.DisplayName or "Player"
    local username = LocalPlayer and LocalPlayer.Name or "Unknown"
    local userId = LocalPlayer and LocalPlayer.UserId or 0

    addText(card, displayName, 21, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -175, 0, 30),
        Position = UDim2.fromOffset(158, 23),
    })

    self.ProfileUsername = addText(card, "@" .. username, 12, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -290, 0, 22),
        Position = UDim2.fromOffset(158, 54),
    })

    self.ProfileUserId = addText(card, "UserId: " .. tostring(userId), 11, self.Theme.Muted, Enum.Font.Gotham, {
        Size = UDim2.new(1, -290, 0, 20),
        Position = UDim2.fromOffset(158, 77),
    })

    local copyButton = addButton(card, {
        Size = UDim2.fromOffset(104, 34),
        Position = UDim2.new(1, -122, 0, 24),
        BackgroundColor3 = self.Theme.Surface2,
    })
    corner(copyButton, 9)
    stroke(copyButton, self.Theme.Border, 0.25, 1)
    addText(copyButton, ICONS.copy .. "  Copy ID", 10, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    copyButton.MouseButton1Click:Connect(function()
        if setclipboard then
            pcall(setclipboard, tostring(userId))
            self:Notify({Title = "Profile", Description = "UserId copied.", Type = "Success", Duration = 2})
        else
            self:Notify({Title = "Profile", Description = tostring(userId), Type = "Info", Duration = 3})
        end
    end)

    local info = new("Frame", {
        Size = UDim2.new(1, -158, 0, 60),
        Position = UDim2.fromOffset(158, 112),
        BackgroundTransparency = 1,
    }, card)

    local infoLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, info)

    local function stat(title, value)
        local holder = new("Frame", {
            Size = UDim2.new(0.33, -7, 1, 0),
            BackgroundColor3 = self.Theme.Surface2,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        }, info)
        corner(holder, 10)
        addText(holder, title, 9, self.Theme.Muted, Enum.Font.GothamMedium, {
            Size = UDim2.new(1, -12, 0, 17),
            Position = UDim2.fromOffset(8, 5),
        })
        addText(holder, value, 11, self.Theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.new(1, -12, 0, 22),
            Position = UDim2.fromOffset(8, 24),
        })
    end

    local accountAge = LocalPlayer and (tostring(LocalPlayer.AccountAge) .. " days") or "Unknown"
    local gameName = "Unknown"
    pcall(function()
        if game and game.Name and game.Name ~= "" then
            gameName = game.Name
        end
    end)

    stat("ACCOUNT AGE", accountAge)
    stat("CURRENT GAME", gameName)
    stat("USER ID", tostring(userId))

    local privacy = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Card,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, self.ProfilePage)
    corner(privacy, 16)
    stroke(privacy, self.Theme.Border, 0.3, 1)
    padding(privacy, 16, 14, 16, 14)

    addText(privacy, "PRIVACY / DISPLAY", 11, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.new(1, 0, 0, 24),
    })

    local privacyLayout = new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, privacy)

    local function addPrivacyToggle(name, key, description)
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundTransparency = 1,
        }, privacy)

        addText(row, name, 13, self.Theme.Text, Enum.Font.GothamMedium, {
            Size = UDim2.new(1, -65, 0, 20),
        })
        addText(row, description, 10, self.Theme.Subtext, Enum.Font.Gotham, {
            Size = UDim2.new(1, -65, 0, 18),
            Position = UDim2.fromOffset(0, 21),
        })

        local button = addButton(row, {
            Size = UDim2.fromOffset(42, 23),
            Position = UDim2.new(1, -42, 0.5, -11),
            BackgroundColor3 = self.Theme.Surface2,
        })
        corner(button, 99)

        local knob = new("Frame", {
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(3, 3),
            BackgroundColor3 = self.Theme.Text,
            BorderSizePixel = 0,
        }, button)
        corner(knob, 99)

        local function render()
            local value = self.Config.Profile[key] == true
            button.BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface2
            knob.Position = UDim2.fromOffset(value and 22 or 3, 3)
        end

        button.MouseButton1Click:Connect(function()
            self.Config.Profile[key] = not self.Config.Profile[key]
            render()
            if self.Config.AutoSave then
                self.ConfigManager:SaveConfig("autosave")
            end
        end)

        render()
    end

    addPrivacyToggle("Hide username", "HideUsername", "Hide your username in the local profile display.")
    addPrivacyToggle("Hide UserId", "HideUserId", "Hide your Roblox UserId in the profile display.")
    addPrivacyToggle("Hide profile information", "HideProfile", "Minimize profile information shown by ZeHub.")
    addPrivacyToggle("Compact profile", "CompactProfile", "Use a smaller profile card.")
end

function WindowMethods:_buildSettingsPage()
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.SettingsPage)

    self:_buildPageHeader(
        self.SettingsPage,
        "Settings",
        "Control appearance, motion, layout, notifications and saved configurations.",
        1
    )

    local function card(title, description, order)
        local holder = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self.Theme.Card,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, self.SettingsPage)
        corner(holder, 16)
        stroke(holder, self.Theme.Border, 0.3, 1)
        padding(holder, 16, 14, 16, 14)

        addText(holder, title, 11, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.new(1, 0, 0, 22),
        })
        addText(holder, description, 10, self.Theme.Subtext, Enum.Font.Gotham, {
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.fromOffset(0, 22),
            TextWrapped = true,
        })

        local body = new("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.fromOffset(0, 55),
            BackgroundTransparency = 1,
        }, holder)

        new("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, body)

        return holder, body
    end

    local function toggle(parent, name, description, key)
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundTransparency = 1,
        }, parent)

        addText(row, name, 13, self.Theme.Text, Enum.Font.GothamMedium, {
            Size = UDim2.new(1, -65, 0, 20),
        })
        addText(row, description, 10, self.Theme.Subtext, Enum.Font.Gotham, {
            Size = UDim2.new(1, -65, 0, 18),
            Position = UDim2.fromOffset(0, 21),
        })

        local button = addButton(row, {
            Size = UDim2.fromOffset(42, 23),
            Position = UDim2.new(1, -42, 0.5, -11),
            BackgroundColor3 = self.Theme.Surface2,
        })
        corner(button, 99)

        local knob = new("Frame", {
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromOffset(3, 3),
            BackgroundColor3 = self.Theme.Text,
            BorderSizePixel = 0,
        }, button)
        corner(knob, 99)

        local function render()
            local value = self.Config[key] == true
            button.BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface2
            knob.Position = UDim2.fromOffset(value and 22 or 3, 3)
        end

        button.MouseButton1Click:Connect(function()
            self.Config[key] = not self.Config[key]
            render()
            self:_refreshSettingsVisuals()
            if self.Config.AutoSave then
                self.ConfigManager:SaveConfig("autosave")
            end
        end)

        render()
    end

    local appearance, appearanceBody = card(
        "APPEARANCE",
        "Control the overall layout, scale and visual effects.",
        2
    )
    toggle(appearanceBody, "Automatic responsive scaling", "Fit ZeHub to the current Roblox viewport automatically.", "AutoScale")
    toggle(appearanceBody, "Sidebar visible", "Show the main navigation sidebar.", "SidebarVisible")
    toggle(appearanceBody, "Sidebar starts collapsed", "Use the compact icon-only sidebar.", "SidebarCollapsed")
    toggle(appearanceBody, "Compact mode", "Reduce spacing in supported controls.", "CompactMode")
    toggle(appearanceBody, "Glow effects", "Use subtle accent glow and transparency effects.", "Glow")
    toggle(appearanceBody, "Rounded corners", "Use rounded ZeHub cards and controls.", "Rounded")

    local motion, motionBody = card(
        "ANIMATIONS",
        "Adjust how much motion ZeHub uses.",
        3
    )
    toggle(motionBody, "Reduce animations", "Use short transitions and fewer motion effects.", "ReduceAnimations")

    local notifications, notificationBody = card(
        "NOTIFICATIONS",
        "Control ZeHub toast messages.",
        4
    )
    toggle(notificationBody, "Notifications", "Show success, info, warning and error toasts.", "Notifications")

    local configs, configBody = card(
        "CONFIGURATION",
        "Save, load and manage script settings.",
        5
    )

    local configName = new("TextBox", {
        Size = UDim2.new(1, -210, 0, 40),
        BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = "Configuration name...",
        PlaceholderColor3 = self.Theme.Subtext,
        Text = self.ConfigManager.Current or "default",
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
    }, configBody)
    corner(configName, 9)
    padding(configName, 12, 0, 12, 0)

    local save = addButton(configBody, {
        Size = UDim2.fromOffset(96, 40),
        Position = UDim2.new(1, -200, 0, 0),
        BackgroundColor3 = self.Theme.Accent,
    })
    corner(save, 9)
    addText(save, "Save", 11, Color3.new(1, 1, 1), Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local load = addButton(configBody, {
        Size = UDim2.fromOffset(96, 40),
        Position = UDim2.new(1, -96, 0, 0),
        BackgroundColor3 = self.Theme.Surface2,
    })
    corner(load, 9)
    addText(load, "Load", 11, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local listLabel = addText(configBody, "Saved configurations", 11, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.fromOffset(0, 50),
    })

    local configList = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.fromOffset(0, 76),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.fromOffset(0, 0),
    }, configBody)
    corner(configList, 10)
    padding(configList, 8, 8, 8, 8)

    local listLayout = new("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, configList)

    local function refreshConfigList()
        for _, child in ipairs(configList:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end

        local configsList = self.ConfigManager:ListConfigs()
        if #configsList == 0 then
            local empty = addText(configList, "No saved configs yet.", 10, self.Theme.Muted, Enum.Font.Gotham, {
                Size = UDim2.new(1, -10, 0, 24),
                Position = UDim2.fromOffset(5, 5),
            })
            return
        end

        for index, name in ipairs(configsList) do
            local item = addButton(configList, {
                Size = UDim2.new(1, 0, 0, 30),
                LayoutOrder = index,
                BackgroundColor3 = name == self.ConfigManager.Current and self.Theme.Surface2 or self.Theme.Card,
            })
            corner(item, 7)
            addText(item, (name == self.ConfigManager.Current and "●  " or "○  ") .. name, 10, self.Theme.Text, Enum.Font.GothamMedium, {
                Size = UDim2.new(1, -10, 1, 0),
                Position = UDim2.fromOffset(10, 0),
            })
            item.MouseButton1Click:Connect(function()
                configName.Text = name
                local ok, err = self.ConfigManager:LoadConfig(name)
                self:Notify({
                    Title = "Configuration",
                    Description = ok and ("Loaded " .. name) or tostring(err),
                    Duration = 2.5,
                    Type = ok and "Success" or "Error",
                })
                refreshConfigList()
            end)
        end
        configList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 16)
    end

    save.MouseButton1Click:Connect(function()
        local name = configName.Text ~= "" and configName.Text or "default"
        self.ConfigManager:SaveConfig(name)
        refreshConfigList()
        self:Notify({Title = "Configuration", Description = "Saved " .. name, Duration = 2.5, Type = "Success"})
    end)

    load.MouseButton1Click:Connect(function()
        local name = configName.Text ~= "" and configName.Text or "default"
        local ok, err = self.ConfigManager:LoadConfig(name)
        refreshConfigList()
        self:Notify({
            Title = "Configuration",
            Description = ok and ("Loaded " .. name) or tostring(err),
            Duration = 2.5,
            Type = ok and "Success" or "Error",
        })
    end)

    local actions = new("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.fromOffset(0, 205),
        BackgroundTransparency = 1,
    }, configBody)

    local delete = addButton(actions, {
        Size = UDim2.fromOffset(150, 36),
        BackgroundColor3 = self.Theme.Surface2,
    })
    corner(delete, 9)
    addText(delete, "Delete config", 10, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    local reset = addButton(actions, {
        Size = UDim2.fromOffset(150, 36),
        Position = UDim2.fromOffset(160, 0),
        BackgroundColor3 = self.Theme.Surface2,
    })
    corner(reset, 9)
    addText(reset, "Reset interface", 10, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    delete.MouseButton1Click:Connect(function()
        local name = configName.Text ~= "" and configName.Text or "default"
        self.ConfigManager:DeleteConfig(name)
        refreshConfigList()
        self:Notify({Title = "Configuration", Description = "Deleted " .. name, Duration = 2.5, Type = "Info"})
    end)

    reset.MouseButton1Click:Connect(function()
        self.Config = merge(DEFAULTS, {})
        self._PendingConfig = nil
        self.ConfigManager.Current = nil
        self:SetTheme("Midnight", false)
        self:_refreshSettingsVisuals()
        self:Notify({Title = "Settings", Description = "Interface settings reset.", Duration = 2.5, Type = "Info"})
    end)

    toggle(configs and configBody or configBody, "Auto-save", "Automatically save changes to the autosave config.", "AutoSave")
    refreshConfigList()

    local updates, updateBody = card(
        "ABOUT ZEHUB",
        "Library status and build information.",
        6
    )
    addText(updateBody, "ZeHub " .. tostring(self.Config.Version), 16, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, 0, 0, 25),
    })
    addText(updateBody, "Modular script UI • Responsive scaling • Config manager • Theme system", 11, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 28),
        TextWrapped = true,
    })
end

function WindowMethods:_buildThemesPage()
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.ThemesPage)

    self:_buildPageHeader(
        self.ThemesPage,
        "Themes",
        "Choose a complete ZeHub gradient palette. Your selection is saved.",
        1
    )

    local grid = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    }, self.ThemesPage)

    local gridLayout = new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -7, 0, 145),
        CellPadding = UDim2.fromOffset(14, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local order = 0

    for name, theme in pairs(THEMES) do
        order += 1

        local card = addButton(grid, {
            BackgroundColor3 = theme.Surface,
            ZIndex = 5,
            LayoutOrder = order,
        })
        corner(card, 16)
        local cardStroke = stroke(card, theme.Border, name == self.Config.Theme and 0 or 0.3, name == self.Config.Theme and 2 or 1)
        gradient(card, theme.Accent, theme.Accent2, 20)

        local overlay = new("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = theme.Background,
            BackgroundTransparency = 0.22,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, card)
        corner(overlay, 16)

        addText(card, name, 17, theme.Text, Enum.Font.GothamBold, {
            Size = UDim2.new(1, -28, 0, 30),
            Position = UDim2.fromOffset(14, 12),
            ZIndex = 7,
        })

        addText(card, "Complete gradient palette", 11, theme.Subtext, Enum.Font.Gotham, {
            Size = UDim2.new(1, -28, 0, 20),
            Position = UDim2.fromOffset(14, 43),
            ZIndex = 7,
        })

        local swatch = new("Frame", {
            Size = UDim2.new(1, -28, 0, 32),
            Position = UDim2.fromOffset(14, 80),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 7,
        }, card)
        corner(swatch, 8)
        gradient(swatch, theme.Accent, theme.Accent2, 0)

        card.MouseEnter:Connect(function()
            tween(card, TweenInfo.new(tweenTime(self, 0.15)), {
                Size = UDim2.new(1, 4, 0, 149),
            })
            tween(cardStroke, TweenInfo.new(tweenTime(self, 0.15)), {
                Color = theme.Accent,
                Transparency = 0,
            })
        end)

        card.MouseLeave:Connect(function()
            tween(cardStroke, TweenInfo.new(tweenTime(self, 0.15)), {
                Color = theme.Border,
                Transparency = name == self.Config.Theme and 0 or 0.3,
            })
        end)

        card.MouseButton1Click:Connect(function()
            self:SetTheme(name)
        end)

        self.ThemeCards[name] = {
            Button = card,
            Stroke = cardStroke,
        }
    end
end

function WindowMethods:_buildToastContainer()
    self.ToastContainer = new("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(330, 400),
        BackgroundTransparency = 1,
        ZIndex = 200,
    }, self.ScreenGui)

    local layout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.ToastContainer)
end

function WindowMethods:_buildToggleHint()
    self.ToggleHint = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -12),
        Size = UDim2.fromOffset(270, 46),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 150,
    }, self.ScreenGui)
    corner(self.ToggleHint, 13)
    stroke(self.ToggleHint, self.Theme.Border, 0.2, 1)

    addText(self.ToggleHint, "⌨", 18, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.fromOffset(5, 3),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    self.ToggleHintLabel = addText(self.ToggleHint, "RightShift • Toggle UI", 12, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(48, 0),
    })
end

function WindowMethods:_bindInput()
    self.InputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == self.Config.ToggleKey then
            self:SetVisible(not self.Visible)
        end
    end)
end

function WindowMethods:_search(query)
    query = tostring(query or ""):lower()

    if query == "" then
        self.SearchResults = {}
        if self.CurrentPage == "Main" then
            self:_renderMain()
        end
        return
    end

    local results = {}

    for _, script in ipairs(self.ScriptOrder) do
        local haystack = (
            script.Name .. " "
            .. script.Description .. " "
            .. tostring(script.Category or "")
        ):lower()

        local matched = haystack:find(query, 1, true) ~= nil

        if not matched then
            for _, component in pairs(script.ComponentMeta) do
                local text = (component.Name .. " " .. tostring(component.Description or "")):lower()
                if text:find(query, 1, true) then
                    matched = true
                    break
                end
            end
        end

        if matched then
            table.insert(results, script)
        end
    end

    self.SearchResults = results

    if self.CurrentPage == "Main" then
        self:_renderMain()
    end
end

function WindowMethods:_createWelcomeBanner()
    local banner = new("Frame", {
        Size = UDim2.new(1, 0, 0, 138),
        BackgroundColor3 = self.Theme.Surface2,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, self.MainPage)
    corner(banner, self.Config.Rounded and 18 or 3)
    stroke(banner, self.Theme.Border, 0.12, 1)
    gradient(banner, self.Theme.Surface2, self.Theme.Background, 15)

    local logo = new("Frame", {
        Size = UDim2.fromOffset(78, 78),
        Position = UDim2.fromOffset(20, 30),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
    }, banner)
    corner(logo, 20)
    gradient(logo, self.Theme.Accent, self.Theme.Accent2, 45)

    addText(logo, "Z", 42, Color3.new(1, 1, 1), Enum.Font.GothamBlack, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    addText(banner, "Welcome to <font color=\"#8290FF\">ZEHUB</font>", 25, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -160, 0, 36),
        Position = UDim2.fromOffset(120, 26),
    })

    addText(banner, "Your modular Roblox script hub", 13, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -160, 0, 24),
        Position = UDim2.fromOffset(120, 64),
    })

    addText(banner, tostring(#self.ScriptOrder) .. " registered script" .. (#self.ScriptOrder == 1 and "" or "s"), 11, self.Theme.Accent, Enum.Font.GothamMedium, {
        Size = UDim2.new(0, 200, 0, 22),
        Position = UDim2.fromOffset(120, 94),
    })

    local discord = addButton(banner, {
        Size = UDim2.fromOffset(170, 42),
        Position = UDim2.new(1, -190, 0.5, -21),
        BackgroundColor3 = self.Theme.Surface,
        ZIndex = 8,
    })
    corner(discord, 11)
    stroke(discord, self.Theme.Border, 0.2, 1)

    addText(discord, ICONS.discord, 18, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.fromOffset(7, 6),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    addText(discord, "discord.gg/zehub", 11, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.new(1, -45, 1, 0),
        Position = UDim2.fromOffset(42, 0),
    })

    discord.MouseButton1Click:Connect(function()
        if setclipboard then
            pcall(setclipboard, "https://discord.gg/zehub")
        end
        self:Notify({
            Title = "Discord",
            Description = "discord.gg/zehub copied to your clipboard.",
            Duration = 3,
            Type = "Success",
        })
    end)

    return banner
end

function WindowMethods:_createEmptyState(parent)
    local empty = new("Frame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = self.Theme.Card,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, parent)
    corner(empty, 16)
    stroke(empty, self.Theme.Border, 0.35, 1)

    addText(empty, "◆", 30, self.Theme.Accent, Enum.Font.GothamBold, {
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.new(0.5, -30, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    addText(empty, #self.ScriptOrder == 0 and "No scripts registered" or "No matching scripts", 18, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -40, 0, 30),
        Position = UDim2.fromOffset(20, 98),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    addText(empty, #self.ScriptOrder == 0
        and "Use ZeHub:AddScript({...}) to automatically create a page and dashboard card."
        or "Try another search term.",
        11,
        self.Theme.Subtext,
        Enum.Font.Gotham,
        {
            Size = UDim2.new(1, -60, 0, 40),
            Position = UDim2.fromOffset(30, 130),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextWrapped = true,
        }
    )

    return empty
end

function WindowMethods:_createScriptCard(script, index)
    local card = addButton(self.MainPage, {
        Name = "ScriptCard_" .. script.Id,
        Size = UDim2.new(1, 0, 0, 124),
        BackgroundColor3 = self.Theme.Card,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        LayoutOrder = index,
        ZIndex = 7,
    })
    corner(card, self.Config.Rounded and 15 or 3)
    local cardStroke = stroke(card, self.Theme.Border, 0.25, 1)

    local iconHolder = new("Frame", {
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.fromOffset(17, 32),
        BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, card)
    corner(iconHolder, 14)
    stroke(iconHolder, self.Theme.Border, 0.15, 1)

    local iconValue, isAsset = resolveIcon(script.Icon)
    if isAsset then
        new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = iconValue,
            Size = UDim2.fromScale(0.7, 0.7),
            Position = UDim2.fromScale(0.15, 0.15),
            ZIndex = 9,
        }, iconHolder)
    else
        addText(iconHolder, iconValue, 26, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 9,
        })
    end

    addText(card, script.Name, 17, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -125, 0, 26),
        Position = UDim2.fromOffset(92, 20),
        ZIndex = 8,
    })

    addText(card, script.Description, 11, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -160, 0, 42),
        Position = UDim2.fromOffset(92, 52),
        TextWrapped = true,
        ZIndex = 8,
    })

    if script.Category then
        local tag = addText(card, string.upper(script.Category), 9, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromOffset(120, 18),
            Position = UDim2.new(1, -150, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 8,
        })
    end

    if script.Version then
        addText(card, "v" .. tostring(script.Version), 9, self.Theme.Muted, Enum.Font.Gotham, {
            Size = UDim2.fromOffset(100, 18),
            Position = UDim2.new(1, -150, 0, 38),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 8,
        })
    end

    local arrow = addText(card, ICONS.arrow, 28, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(35, 45),
        Position = UDim2.new(1, -49, 0.5, -22),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 9,
    })

    card.MouseEnter:Connect(function()
        tween(card, TweenInfo.new(tweenTime(self, 0.16), Enum.EasingStyle.Quad), {
            BackgroundColor3 = self.Theme.Surface2,
        })
        tween(cardStroke, TweenInfo.new(tweenTime(self, 0.16)), {
            Color = self.Theme.Accent,
            Transparency = 0.05,
        })
        tween(arrow, TweenInfo.new(tweenTime(self, 0.16), Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -43, 0.5, -22),
            TextColor3 = self.Theme.Text,
        })
    end)

    card.MouseLeave:Connect(function()
        tween(card, TweenInfo.new(tweenTime(self, 0.16), Enum.EasingStyle.Quad), {
            BackgroundColor3 = self.Theme.Card,
        })
        tween(cardStroke, TweenInfo.new(tweenTime(self, 0.16)), {
            Color = self.Theme.Border,
            Transparency = 0.25,
        })
        tween(arrow, TweenInfo.new(tweenTime(self, 0.16), Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -49, 0.5, -22),
            TextColor3 = self.Theme.Subtext,
        })
    end)

    card.MouseButton1Click:Connect(function()
        tween(card, TweenInfo.new(0.07), {BackgroundTransparency = 0.25})
        task.delay(0.07, function()
            if card.Parent then
                tween(card, TweenInfo.new(0.12), {BackgroundTransparency = 0.03})
            end
        end)
        self:_openScript(script)
    end)

    return card
end

function WindowMethods:_renderMain()
    if not self.MainPage then
        return
    end

    for _, child in ipairs(self.MainPage:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    self.MainLayout = new("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, self.MainPage)

    self:_createWelcomeBanner()

    local scripts = self.SearchResults or self.ScriptOrder

    if not self.SearchResults and #self.RecentScripts > 0 then
        local recentTitle = new("Frame", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
        }, self.MainPage)
        addText(recentTitle, "RECENT", 11, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.new(1, 0, 0, 20),
        })
        addText(recentTitle, "Continue where you left off.", 10, self.Theme.Subtext, Enum.Font.Gotham, {
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.fromOffset(0, 19),
        })
    end

    if #scripts == 0 then
        self:_createEmptyState(self.MainPage)
        return
    end

    local gridHolder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = self.SearchResults and 3 or 4,
    }, self.MainPage)

    local grid = new("UIGridLayout", {
        CellPadding = UDim2.fromOffset(14, 14),
        CellSize = UDim2.new(0.5, -7, 0, 124),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, gridHolder)

    local function updateGrid()
        local width = gridHolder.AbsoluteSize.X
        if width < 650 then
            grid.CellSize = UDim2.new(1, 0, 0, 124)
        else
            grid.CellSize = UDim2.new(0.5, -7, 0, 124)
        end
    end

    gridHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGrid)
    task.defer(updateGrid)

    for index, script in ipairs(scripts) do
        self:_createScriptCardInGrid(gridHolder, script, index)
    end
end

function WindowMethods:_createScriptCardInGrid(parent, script, index)
    local card = addButton(parent, {
        Name = "ScriptCard_" .. script.Id,
        BackgroundColor3 = self.Theme.Card,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        LayoutOrder = index,
        ZIndex = 7,
    })
    corner(card, self.Config.Rounded and 15 or 3)
    local cardStroke = stroke(card, self.Theme.Border, 0.25, 1)

    local iconHolder = new("Frame", {
        Size = UDim2.fromOffset(54, 54),
        Position = UDim2.fromOffset(15, 16),
        BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, card)
    corner(iconHolder, 13)
    stroke(iconHolder, self.Theme.Border, 0.15, 1)

    local iconValue, isAsset = resolveIcon(script.Icon)
    if isAsset then
        new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = iconValue,
            Size = UDim2.fromScale(0.7, 0.7),
            Position = UDim2.fromScale(0.15, 0.15),
            ZIndex = 9,
        }, iconHolder)
    else
        addText(iconHolder, iconValue, 25, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 9,
        })
    end

    addText(card, script.Name, 16, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -125, 0, 25),
        Position = UDim2.fromOffset(82, 16),
        ZIndex = 8,
    })

    addText(card, script.Description, 11, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -125, 0, 40),
        Position = UDim2.fromOffset(82, 45),
        TextWrapped = true,
        ZIndex = 8,
    })

    if script.Status then
        addText(card, "● " .. tostring(script.Status), 9, self.Theme.Positive, Enum.Font.GothamMedium, {
            Size = UDim2.fromOffset(130, 18),
            Position = UDim2.fromOffset(82, 95),
            ZIndex = 8,
        })
    end

    local arrow = addText(card, ICONS.arrow, 27, self.Theme.Subtext, Enum.Font.GothamMedium, {
        Size = UDim2.fromOffset(32, 42),
        Position = UDim2.new(1, -43, 0.5, -21),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 9,
    })

    card.MouseEnter:Connect(function()
        tween(card, TweenInfo.new(tweenTime(self, 0.15), Enum.EasingStyle.Quad), {
            BackgroundColor3 = self.Theme.Surface2,
        })
        tween(cardStroke, TweenInfo.new(tweenTime(self, 0.15)), {
            Color = self.Theme.Accent,
            Transparency = 0.03,
        })
        tween(arrow, TweenInfo.new(tweenTime(self, 0.15), Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -37, 0.5, -21),
            TextColor3 = self.Theme.Text,
        })
    end)

    card.MouseLeave:Connect(function()
        tween(card, TweenInfo.new(tweenTime(self, 0.15), Enum.EasingStyle.Quad), {
            BackgroundColor3 = self.Theme.Card,
        })
        tween(cardStroke, TweenInfo.new(tweenTime(self, 0.15)), {
            Color = self.Theme.Border,
            Transparency = 0.25,
        })
        tween(arrow, TweenInfo.new(tweenTime(self, 0.15), Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -43, 0.5, -21),
            TextColor3 = self.Theme.Subtext,
        })
    end)

    card.MouseButton1Click:Connect(function()
        self:_openScript(script)
    end)

    script.Card = card
end

function WindowMethods:_markScriptRecent(script)
    if not script then
        return
    end

    for i = #self.RecentScripts, 1, -1 do
        if self.RecentScripts[i] == script then
            table.remove(self.RecentScripts, i)
        end
    end

    table.insert(self.RecentScripts, 1, script)

    while #self.RecentScripts > 6 do
        table.remove(self.RecentScripts)
    end
end

function WindowMethods:_openScript(script)
    if not script or not script.Page then
        return
    end

    self:_markScriptRecent(script)

    for _, page in pairs(self.Pages) do
        page.Visible = false
    end

    script.Page.Visible = true
    self.CurrentPage = script.Id

    -- Script pages get a compact back control at the top.
    if script.BackButton then
        script.BackButton.Visible = true
    end
end

function WindowMethods:_buildScriptPage(script)
    local page = new("ScrollingFrame", {
        Name = script.Id,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Theme.Accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 5,
    }, self.Content)
    padding(page, 12, 12, 12, 20)

    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = self.Theme.Surface2,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, page)
    corner(header, 16)
    stroke(header, self.Theme.Border, 0.15, 1)
    gradient(header, self.Theme.Surface2, self.Theme.Background, 15)

    local back = addButton(header, {
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.fromOffset(12, 28),
        BackgroundColor3 = self.Theme.Surface,
        ZIndex = 7,
    })
    corner(back, 11)
    stroke(back, self.Theme.Border, 0.25, 1)

    addText(back, ICONS.back, 26, self.Theme.Text, Enum.Font.GothamMedium, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    })

    back.MouseButton1Click:Connect(function()
        self:_setPage("Main")
    end)

    script.BackButton = back

    local iconValue, isAsset = resolveIcon(script.Icon)
    local iconHolder = new("Frame", {
        Size = UDim2.fromOffset(58, 58),
        Position = UDim2.fromOffset(68, 21),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
    }, header)
    corner(iconHolder, 13)

    if isAsset then
        new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = iconValue,
            Size = UDim2.fromScale(0.7, 0.7),
            Position = UDim2.fromScale(0.15, 0.15),
        }, iconHolder)
    else
        addText(iconHolder, iconValue, 27, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromScale(1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
        })
    end

    addText(header, script.Name, 22, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -270, 0, 30),
        Position = UDim2.fromOffset(142, 22),
    })

    addText(header, script.Description, 11, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -170, 0, 30),
        Position = UDim2.fromOffset(142, 55),
        TextWrapped = true,
    })

    if script.Version then
        addText(header, "v" .. tostring(script.Version), 9, self.Theme.Muted, Enum.Font.Gotham, {
            Size = UDim2.fromOffset(90, 20),
            Position = UDim2.new(1, -140, 0, 47),
            TextXAlignment = Enum.TextXAlignment.Right,
        })
    end

    if script.Category then
        addText(header, string.upper(script.Category), 9, self.Theme.Accent, Enum.Font.GothamBold, {
            Size = UDim2.fromOffset(120, 20),
            Position = UDim2.new(1, -140, 0, 24),
            TextXAlignment = Enum.TextXAlignment.Right,
        })
    end

    self.Pages[script.Id] = page
    script.Page = page
    script.Canvas = page

    return page
end

function WindowMethods:AddScript(options)
    options = options or {}

    local name = tostring(options.Name or ("Script " .. tostring(#self.ScriptOrder + 1)))

    if self.Scripts[name] then
        return self.Scripts[name]
    end

    local id = "Script_" .. name:gsub("[^%w]+", "_") .. "_" .. tostring(self.NextScriptId)
    self.NextScriptId += 1

    local script = setmetatable({
        Window = self,
        Id = id,
        Name = name,
        Description = tostring(options.Description or "ZeHub script features and utilities."),
        Icon = options.Icon or "script",
        Category = options.Category,
        Version = options.Version,
        Status = options.Status,
        Sections = {},
        ComponentMeta = {},
        ComponentCounter = 0,
        Page = nil,
        Canvas = nil,
        Card = nil,
    }, ScriptMethods)

    self.Scripts[name] = script
    self.ScriptsById[id] = script
    table.insert(self.ScriptOrder, script)

    self:_buildScriptPage(script)

    self:_renderMain()

    return script
end

function WindowMethods:RemoveScript(nameOrScript)
    local script

    if type(nameOrScript) == "table" then
        script = nameOrScript
    else
        script = self.Scripts[tostring(nameOrScript)]
    end

    if not script then
        return false
    end

    if script.Page then
        script.Page:Destroy()
    end

    if script.Card then
        script.Card:Destroy()
    end

    self.Scripts[script.Name] = nil
    self.ScriptsById[script.Id] = nil

    for i, current in ipairs(self.ScriptOrder) do
        if current == script then
            table.remove(self.ScriptOrder, i)
            break
        end
    end

    self.Pages[script.Id] = nil
    self:_setPage("Main")

    return true
end

function WindowMethods:SetTheme(name, notify)
    name = tostring(name)

    local theme = THEMES[name]
    if not theme then
        return false
    end

    self.Config.Theme = name
    self.Theme = theme

    local function updateObject(instance, property, value)
        if instance and instance.Parent then
            pcall(function()
                instance[property] = value
            end)
        end
    end

    updateObject(self.Window, "BackgroundColor3", theme.Background)
    updateObject(self.Shadow, "BackgroundColor3", Color3.new(0, 0, 0))
    updateObject(self.WindowStroke, "Color", theme.Border)

    if self.BackgroundGradient then
        self.BackgroundGradient.Color = ColorSequence.new(theme.Background, theme.Surface)
    end

    if self.TopBar then
        updateObject(self.TopBar, "BackgroundColor3", theme.Surface)
    end

    if self.Sidebar then
        updateObject(self.Sidebar, "BackgroundColor3", theme.Surface)
    end

    if self.SearchFrame then
        updateObject(self.SearchFrame, "BackgroundColor3", theme.Surface2)
        updateObject(self.SearchStroke, "Color", theme.Border)
    end

    if self.SearchBox then
        updateObject(self.SearchBox, "TextColor3", theme.Text)
        updateObject(self.SearchBox, "PlaceholderColor3", theme.Subtext)
    end

    if self.ThemeButton then
        updateObject(self.ThemeButton, "BackgroundColor3", theme.Surface2)
        updateObject(self.ThemeButtonLabel, "TextColor3", theme.Text)
    end

    if self.ToggleHint then
        updateObject(self.ToggleHint, "BackgroundColor3", theme.Surface)
        updateObject(self.ToggleHintLabel, "TextColor3", theme.Subtext)
    end

    for nameKey, nav in pairs(self.NavButtons or {}) do
        updateObject(nav.Button, "BackgroundColor3", theme.Surface2)
        updateObject(nav.Label, "TextColor3", theme.Text)
        updateObject(nav.Icon, "TextColor3", theme.Accent)

        if nameKey == self.CurrentPage then
            updateObject(nav.Button, "BackgroundTransparency", 0.05)
        else
            updateObject(nav.Button, "BackgroundTransparency", 1)
        end
    end

    self:_refreshAllComponents()

    if self.ThemeCards then
        for themeName, info in pairs(self.ThemeCards) do
            local selected = themeName == name
            updateObject(info.Stroke, "Color", THEMES[themeName].Border)
            updateObject(info.Stroke, "Transparency", selected and 0 or 0.3)
            updateObject(info.Stroke, "Thickness", selected and 2 or 1)
        end
    end

    if self.ThemeButtonLabel then
        self.ThemeButtonLabel.Text = name
    end

    if notify ~= false and self.Config.Notifications then
        self:Notify({
            Title = "Theme changed",
            Description = name .. " is now active.",
            Duration = 2.5,
            Type = "Success",
        })
    end

    if self.Config.AutoSave and self.ConfigManager then
        self.ConfigManager:SaveConfig("autosave")
    end

    return true
end

function WindowMethods:_refreshAllComponents()
    -- Rebuild dynamic script pages from their stored definitions. This keeps the
    -- public API small while allowing a theme change to restyle existing controls.
    -- Current component values are captured first so a theme change never resets
    -- toggles, sliders, dropdowns or keybinds.
    local savedState = self:_collectState()

    for _, script in ipairs(self.ScriptOrder) do
        local definitions = deepCopy(script.SectionDefinitions or {})
        local wasVisible = script.Page and script.Page.Visible or false

        if script.Page then
            script.Page:Destroy()
        end

        self.Pages[script.Id] = nil
        script.Page = nil
        script.Canvas = nil
        script.Sections = {}
        script.ComponentStates = {}

        self:_buildScriptPage(script)

        -- Do not mutate SectionDefinitions while iterating it. AddSection normally
        -- records definitions, so temporarily restore the old table while rebuilding.
        script.SectionDefinitions = {}
        script._Rebuilding = true

        for _, sectionDefinition in ipairs(definitions) do
            local section = script:AddSection(sectionDefinition.Name)

            for _, definition in ipairs(sectionDefinition.Components or {}) do
                local options = deepCopy(definition.Options)

                if definition.Type == "Toggle" then
                    section:AddToggle(options)
                elseif definition.Type == "Button" then
                    section:AddButton(options)
                elseif definition.Type == "Slider" then
                    section:AddSlider(options)
                elseif definition.Type == "Dropdown" then
                    section:AddDropdown(options)
                elseif definition.Type == "Keybind" then
                    section:AddKeybind(options)
                elseif definition.Type == "Paragraph" then
                    section:AddParagraph(options)
                elseif definition.Type == "Textbox" then
                    section:AddTextbox(options)
                elseif definition.Type == "MultiDropdown" then
                    section:AddMultiDropdown(options)
                elseif definition.Type == "ColorPicker" then
                    section:AddColorPicker(options)
                elseif definition.Type == "Tooltip" then
                    section:AddTooltip(options)
                elseif definition.Type == "Label" then
                    section:AddLabel(options)
                elseif definition.Type == "Divider" then
                    section:AddDivider()
                end
            end
        end

        script._Rebuilding = false
        script.SectionDefinitions = definitions
        script.Page.Visible = wasVisible
    end

    -- Restore the values captured before the visual rebuild.
    for id, value in pairs(savedState) do
        local entry = self.ComponentStates[id]
        if entry then
            pcall(entry.Set, value)
        end
    end

    self:_renderMain()
end

function WindowMethods:_updateResponsiveScale()
    if not self.Scale or not self.Root then
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

    local manual = clamp(tonumber(self.Config.UIScale) or 1, 0.55, 1.3)

    if self.Config.AutoScale == false then
        self.Scale.Scale = manual
        return
    end

    local minScale = clamp(tonumber(self.Config.MinUIScale) or 0.55, 0.45, 1)
    local maxScale = clamp(tonumber(self.Config.MaxUIScale) or 1.05, minScale, 1.3)

    local widthScale = viewport.X / 1120
    local heightScale = viewport.Y / 700
    local responsive = math.min(widthScale * 0.94, heightScale * 0.88)

    self.Scale.Scale = clamp(math.min(manual, responsive), minScale, maxScale)
end

function WindowMethods:_refreshSettingsVisuals()
    self:_updateResponsiveScale()

    if self.Sidebar then
        self.Sidebar.Visible = self.Config.SidebarVisible ~= false

        local collapsed = self.Config.SidebarCollapsed == true and self.Sidebar.Visible
        local sidebarWidth = collapsed and 78 or 260

        self.Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
        self.Content.Position = self.Sidebar.Visible
            and UDim2.fromOffset(sidebarWidth + 10, 7)
            or UDim2.fromOffset(7, 7)
        self.Content.Size = self.Sidebar.Visible
            and UDim2.new(1, -(sidebarWidth + 18), 1, -14)
            or UDim2.new(1, -14, 1, -14)

        for _, nav in pairs(self.NavButtons or {}) do
            nav.Label.Visible = not collapsed
            nav.Button.Size = UDim2.new(1, 0, 0, 54)
            nav.Icon.Size = UDim2.fromOffset(40, 40)
            nav.Icon.Position = collapsed and UDim2.new(0.5, -20, 0, 7) or UDim2.fromOffset(7, 7)
        end

        if self.SidebarToggle then
            self.SidebarToggleLabel.Visible = not collapsed
            self.SidebarToggleIcon.Text = collapsed and "›" or "‹"
            self.SidebarToggleIcon.Position = collapsed
                and UDim2.new(0.5, -19, 0, 2)
                or UDim2.fromOffset(7, 2)
        end
    end

    if self.ToggleHintLabel then
        self.ToggleHintLabel.Text = self.Config.ToggleKey.Name .. " • Toggle UI"
    end
end


function WindowMethods:Notify(options)
    options = options or {}

    if self.Config.Notifications == false then
        return
    end

    local notificationType = tostring(options.Type or "Info")
    local themeColor = self.Theme.Accent

    if notificationType == "Success" then
        themeColor = self.Theme.Positive
    elseif notificationType == "Warning" then
        themeColor = self.Theme.Warning
    elseif notificationType == "Error" then
        themeColor = self.Theme.Negative
    end

    local toast = new("Frame", {
        Size = UDim2.fromOffset(320, 72),
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        LayoutOrder = os.clock() * 1000,
        ZIndex = 205,
    }, self.ToastContainer)
    corner(toast, 14)
    local toastStroke = stroke(toast, themeColor, 0.05, 1)

    local bar = new("Frame", {
        Size = UDim2.new(0, 4, 1, -20),
        Position = UDim2.fromOffset(8, 10),
        BackgroundColor3 = themeColor,
        BorderSizePixel = 0,
        ZIndex = 206,
    }, toast)
    corner(bar, 99)

    addText(toast, options.Title or "ZeHub", 13, self.Theme.Text, Enum.Font.GothamBold, {
        Size = UDim2.new(1, -38, 0, 22),
        Position = UDim2.fromOffset(23, 10),
        ZIndex = 206,
    })

    addText(toast, options.Description or "", 10, self.Theme.Subtext, Enum.Font.Gotham, {
        Size = UDim2.new(1, -38, 0, 32),
        Position = UDim2.fromOffset(23, 33),
        TextWrapped = true,
        ZIndex = 206,
    })

    toast.Position = UDim2.new(1, 40, 0, 0)

    tween(toast, TweenInfo.new(tweenTime(self, 0.25), Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    })

    local duration = tonumber(options.Duration or 3) or 3

    task.delay(duration, function()
        if toast.Parent then
            local out = tween(toast, TweenInfo.new(tweenTime(self, 0.22), Enum.EasingStyle.Quad), {
                Position = UDim2.new(1, 40, 0, 0),
                BackgroundTransparency = 1,
            })
            if out then
                out.Completed:Connect(function()
                    if toast.Parent then
                        toast:Destroy()
                    end
                end)
            end
        end
    end)

    return toast
end

function WindowMethods:SetVisible(value)
    self.Visible = value == true

    if self.Root then
        if self.Visible then
            self.Root.Visible = true
            self.Root.Size = UDim2.new(0, 1080, 0, 670)
            tween(self.Root, TweenInfo.new(tweenTime(self, 0.22), Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 1120, 0, 700),
            })
        else
            tween(self.Root, TweenInfo.new(tweenTime(self, 0.18), Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 1080, 0, 670),
            })
            task.delay(tweenTime(self, 0.2), function()
                if self.Root and not self.Visible then
                    self.Root.Visible = false
                end
            end)
        end
    end
end

function WindowMethods:Destroy()
    if self.InputConnection then
        self.InputConnection:Disconnect()
        self.InputConnection = nil
    end

    if self.ViewportConnection then
        self.ViewportConnection:Disconnect()
        self.ViewportConnection = nil
    end

    if self.SearchConnection then
        self.SearchConnection:Disconnect()
        self.SearchConnection = nil
    end

    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end

    self.ComponentStates = {}
    self.NavButtons = {}
    self.ThemeCards = {}
    self.Destroyed = true
end

--==================================================
-- PUBLIC LIBRARY
--==================================================

function ZeHub:CreateWindow(options)
    options = options or {}

    if self.Window and not self.Window.Destroyed then
        self.Window:Destroy()
    end

    local config = merge(DEFAULTS, options)
    config.Name = options.Name or DEFAULTS.Name
    config.Version = options.Version or DEFAULTS.Version

    if typeof(options.ToggleKey) == "EnumItem" then
        config.ToggleKey = options.ToggleKey
    end

    local window = setmetatable({
        Library = self,
        Config = config,
        Theme = THEMES[config.Theme] or THEMES.Midnight,

        Scripts = {},
        ScriptsById = {},
        ScriptOrder = {},
        NextScriptId = 1,
        RecentScripts = {},

        Pages = {},
        NavButtons = {},
        ThemeCards = {},
        ComponentStates = {},

        CurrentPage = "Main",
        SearchResults = nil,
        Visible = true,
        Destroyed = false,
    }, WindowMethods)

    self.Window = window
    self.Config = config

    window.ConfigManager = ConfigManager.new(window)
    window:_buildWindow()

    -- Restore interface settings immediately when an executor supports file APIs.
    -- Component state is kept pending and applied automatically as scripts register.
    pcall(function()
        window.ConfigManager:LoadConfig("autosave")
    end)
    window:_refreshSettingsVisuals()

    return window
end

function ZeHub:AddScript(options)
    if not self.Window then
        self:CreateWindow({})
    end

    local script = self.Window:AddScript(options)

    -- Store definitions so theme refreshes can rebuild pages without requiring
    -- the script author to manually recreate its UI.
    if not script.SectionDefinitions then
        script.SectionDefinitions = {}
    end

    -- Wrap the section/component API once for this script so future definitions
    -- are retained for theme rebuilds.
    if not script._DefinitionWrapped then
        script._DefinitionWrapped = true

        local rawAddSection = script.AddSection

        script.AddSection = function(selfScript, sectionName)
            local definition = {
                Name = tostring(sectionName or "Main"),
                Components = {},
            }

            if not selfScript._Rebuilding then
                table.insert(selfScript.SectionDefinitions, definition)
            end

            local section = rawAddSection(selfScript, definition.Name)
            local raw = {
                AddToggle = section.AddToggle,
                AddButton = section.AddButton,
                AddSlider = section.AddSlider,
                AddDropdown = section.AddDropdown,
                AddKeybind = section.AddKeybind,
                AddParagraph = section.AddParagraph,
                AddTextbox = section.AddTextbox,
                AddMultiDropdown = section.AddMultiDropdown,
                AddColorPicker = section.AddColorPicker,
                AddTooltip = section.AddTooltip,
                AddLabel = section.AddLabel,
                AddDivider = section.AddDivider,
            }

            local function remember(typeName, options)
                table.insert(definition.Components, {
                    Type = typeName,
                    Options = deepCopy(options or {}),
                })
            end

            section.AddToggle = function(sec, options)
                remember("Toggle", options)
                return raw.AddToggle(sec, options)
            end

            section.AddButton = function(sec, options)
                remember("Button", options)
                return raw.AddButton(sec, options)
            end

            section.AddSlider = function(sec, options)
                remember("Slider", options)
                return raw.AddSlider(sec, options)
            end

            section.AddDropdown = function(sec, options)
                remember("Dropdown", options)
                return raw.AddDropdown(sec, options)
            end

            section.AddKeybind = function(sec, options)
                remember("Keybind", options)
                return raw.AddKeybind(sec, options)
            end

            section.AddParagraph = function(sec, options)
                remember("Paragraph", options)
                return raw.AddParagraph(sec, options)
            end

            section.AddTextbox = function(sec, options)
                remember("Textbox", options)
                return raw.AddTextbox(sec, options)
            end

            section.AddMultiDropdown = function(sec, options)
                remember("MultiDropdown", options)
                return raw.AddMultiDropdown(sec, options)
            end

            section.AddColorPicker = function(sec, options)
                remember("ColorPicker", options)
                return raw.AddColorPicker(sec, options)
            end

            section.AddTooltip = function(sec, options)
                remember("Tooltip", options)
                return raw.AddTooltip(sec, options)
            end

            section.AddLabel = function(sec, options)
                remember("Label", options)
                return raw.AddLabel(sec, options)
            end

            section.AddDivider = function(sec)
                remember("Divider", {})
                return raw.AddDivider(sec)
            end

            return section
        end
    end

    return script
end

function ZeHub:RemoveScript(script)
    if self.Window then
        return self.Window:RemoveScript(script)
    end
    return false
end

function ZeHub:Notify(options)
    if self.Window then
        return self.Window:Notify(options)
    end
end

function ZeHub:SetTheme(name)
    if self.Window then
        return self.Window:SetTheme(name)
    end
    return false
end

function ZeHub:SaveConfig(name)
    if self.Window then
        return self.Window.ConfigManager:SaveConfig(name)
    end
    return false
end

function ZeHub:LoadConfig(name)
    if self.Window then
        return self.Window.ConfigManager:LoadConfig(name)
    end
    return false
end

function ZeHub:DeleteConfig(name)
    if self.Window then
        return self.Window.ConfigManager:DeleteConfig(name)
    end
    return false
end

function ZeHub:ListConfigs()
    if self.Window then
        return self.Window.ConfigManager:ListConfigs()
    end
    return {}
end

--==================================================
-- FIXUP: preserve component definitions for script
-- pages while allowing normal runtime callbacks.
--==================================================

local originalAddScript = ZeHub.AddScript

ZeHub.AddScript = function(self, options)
    local script = originalAddScript(self, options)

    -- If the developer calls script:AddSection before this wrapper exists,
    -- the wrapper is installed by originalAddScript before returning.
    return script
end

return ZeHub



--==================================================
-- ZeHub UI Library v2 | Executor Preview
-- Run this entire file through your Roblox executor.
-- The production library is embedded above this demo.
--==================================================

local Window = ZeHub:CreateWindow({
    Name = "ZeHub",
    Version = "2.0.0",
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Midnight",
    AutoScale = true,
})

local Demo = ZeHub:AddScript({
    Name = "UI Preview",
    Description = "Test every major ZeHub v2 component.",
    Icon = "gamepad",
    Category = "Demo",
    Version = "2.0.0",
    Status = "Ready",
})

local Main = Demo:AddSection("Controls")

Main:AddParagraph({
    Name = "ZeHub UI Library v2",
    Content = "This is the production library preview. Settings, configs, responsive scaling, themes and components are all enabled.",
})

Main:AddToggle({
    Name = "Example Toggle",
    Description = "Test a standard toggle.",
    Default = false,
    Callback = function(value)
        Window:Notify({
            Title = "Toggle",
            Description = value and "Enabled" or "Disabled",
            Type = value and "Success" or "Info",
            Duration = 2,
        })
    end,
})

Main:AddButton({
    Name = "Test Notification",
    Description = "Test the notification system.",
    Callback = function()
        Window:Notify({
            Title = "ZeHub v2",
            Description = "Notification system is working.",
            Type = "Success",
            Duration = 3,
        })
    end,
})

Main:AddSlider({
    Name = "Slider",
    Description = "Test slider state saving.",
    Min = 0,
    Max = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        print("[ZeHub v2] Slider:", value)
    end,
})

Main:AddDropdown({
    Name = "Dropdown",
    Options = {"Legit", "Rage", "Visuals", "Utility"},
    Default = "Legit",
    Callback = function(value)
        print("[ZeHub v2] Dropdown:", value)
    end,
})

Main:AddMultiDropdown({
    Name = "Multi Dropdown",
    Options = {"ESP", "Tracers", "Boxes", "Names", "Health"},
    Default = {"ESP", "Names"},
    Callback = function(values)
        print("[ZeHub v2] Multi:", table.concat(values, ", "))
    end,
})

Main:AddKeybind({
    Name = "Keybind",
    Description = "Click the key box and press a keyboard key.",
    Default = Enum.KeyCode.F,
    Callback = function(key)
        print("[ZeHub v2] Keybind:", key.Name)
    end,
})

Main:AddTextbox({
    Name = "Textbox",
    Description = "Test text state saving.",
    Placeholder = "Type something...",
    Default = "ZeHub",
    Callback = function(value)
        print("[ZeHub v2] Textbox:", value)
    end,
})

Main:AddColorPicker({
    Name = "Color Picker",
    Description = "Enter RGB values and apply them.",
    Default = Color3.fromRGB(83, 96, 255),
    Callback = function(color)
        print("[ZeHub v2] Color:", color.R, color.G, color.B)
    end,
})

Main:AddTooltip({
    Name = "Hover for help",
    Description = "This is a simple hover tooltip component for explaining a feature without filling the main UI with text.",
})

local Advanced = Demo:AddSection("Advanced")

Advanced:AddParagraph({
    Name = "Config Test",
    Content = "Open Settings and create a config. Then change the controls above, save, change them again and load the config to verify the values return.",
})

Advanced:AddButton({
    Name = "Save Test Config",
    Callback = function()
        ZeHub:SaveConfig("preview")
        Window:Notify({
            Title = "Config",
            Description = "Saved preview config.",
            Type = "Success",
            Duration = 2,
        })
    end,
})

Advanced:AddButton({
    Name = "Load Test Config",
    Callback = function()
        local ok, err = ZeHub:LoadConfig("preview")
        Window:Notify({
            Title = "Config",
            Description = ok and "Loaded preview config." or tostring(err),
            Type = ok and "Success" or "Error",
            Duration = 2.5,
        })
    end,
})

Window:Notify({
    Title = "ZeHub v2 Loaded",
    Description = "Press RightShift to toggle the UI.",
    Type = "Success",
    Duration = 4,
})
