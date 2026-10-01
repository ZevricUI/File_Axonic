--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║  ZeHub — Modular Client UI Framework (AAA Liquid Glass) (AAA Liquid Glass)   ║
    ║  Aesthetic: Sleek Dark Obsidian · Dynamic 7-Theme Dual Gradients     ║
    ║  2-Column Modular Cards · Expandable Settings Drawer · Live Search  ║
    ║  Dynamic Theme Engine · Watermark · Keybinds HUD · Notifications    ║
    ╚══════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
--  Services & Core References
-- ═══════════════════════════════════════════════════════════════

local function safeService(serviceName)
	local s, srv = pcall(function() return game:GetService(serviceName) end)
	if s and srv then
		if cloneref then
			local cs, cref = pcall(cloneref, srv)
			if cs and cref then return cref end
		end
		return srv
	end
	return nil
end

local Players              = safeService("Players") or game:GetService("Players")
local UserInputService     = safeService("UserInputService") or game:GetService("UserInputService")
local TweenService         = safeService("TweenService") or game:GetService("TweenService")
local RunService           = safeService("RunService") or game:GetService("RunService")
local StatsService         = safeService("Stats") or game:GetService("Stats")
local Lighting             = safeService("Lighting") or game:GetService("Lighting")
local ContextActionService = safeService("ContextActionService") or game:GetService("ContextActionService")
local Workspace            = safeService("Workspace") or workspace

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	local _ = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

-- Block ShiftLock trigger on RightShift so RShift cleanly toggles menu
pcall(function()
	ContextActionService:BindActionAtPriority(
		"ZeHub_BlockShiftLockRShift",
		function(actionName, inputState, inputObject)
			if inputObject.KeyCode == Enum.KeyCode.RightShift then
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value + 2000,
		Enum.KeyCode.RightShift
	)
end)

-- Remove RightShift from default MouseLockController
pcall(function()
	local pScripts = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts")
	local pModule = pScripts and pScripts:FindFirstChild("PlayerModule")
	if pModule then
		local pm = require(pModule)
		local cameras = pm and pm.GetCameras and pm:GetCameras()
		local mlc = cameras and (cameras.activeMouseLockController or (cameras.GetMouseLockController and cameras:GetMouseLockController()))
		if mlc and mlc.boundKeys then
			local newKeys = {}
			for _, k in ipairs(mlc.boundKeys) do
				if k ~= Enum.KeyCode.RightShift then
					table.insert(newKeys, k)
				end
			end
			mlc.boundKeys = newKeys
			ContextActionService:UnbindAction("MouseLockSwitchAction")
			if mlc.CreateMouseLockFunc and #newKeys > 0 then
				ContextActionService:BindActionAtPriority(
					"MouseLockSwitchAction",
					mlc:CreateMouseLockFunc(),
					false,
					mlc.priority or Enum.ContextActionPriority.Medium.Value,
					unpack(newKeys)
				)
			end
		end
	end
end)

-- Safe GUI container resolution
local function getGuiContainer()
	if gethui then
		local s, res = pcall(gethui)
		if s and res then return res end
	end
	local s, core = pcall(function()
		local cg = game:GetService("CoreGui")
		return (cloneref and cloneref(cg)) or cg
	end)
	if s and core then return core end
	if LocalPlayer then
		return LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end
	return core
end

-- ═══════════════════════════════════════════════════════════════
--  Typography
-- ═══════════════════════════════════════════════════════════════

local function applyFont(obj, style)
	if style == "Bold" or style == "SemiBold" then
		obj.Font = Enum.Font.GothamBold
	elseif style == "Medium" then
		obj.Font = Enum.Font.GothamMedium
	else
		obj.Font = Enum.Font.Gotham
	end
end

-- ═══════════════════════════════════════════════════════════════
--  Verified Lucide Vector Icons (Roblox CDN)
-- ═══════════════════════════════════════════════════════════════

local Icons = {
	Logo        = "rbxassetid://10734887901", -- Crosshair Reticle
	Search      = "rbxassetid://10734898126", -- Magnifying Glass
	Combat      = "rbxassetid://10734887901", -- Crosshair / Target
	Movement    = "rbxassetid://10734979177", -- Zap / Lightning
	Render      = "rbxassetid://10734895698", -- Eye / Visuals
	World       = "rbxassetid://10734919532", -- Globe / World
	Player      = "rbxassetid://10734924185", -- User / Profile
	Configs     = "rbxassetid://10723387563", -- Folder
	Themes      = "rbxassetid://10734900011", -- Color Palette
	Util        = "rbxassetid://10734950309", -- Sliders / Cog
	Gear        = "rbxassetid://10734950309", -- Settings Cog Gear
	Link        = "rbxassetid://10723416652", -- Keyboard Keycap / Keybind
	Keybind     = "rbxassetid://10723416652", -- Keyboard Keycap
	Power       = "rbxassetid://10734923298", -- Power / Exit
	Checkmark   = "rbxassetid://10709790644", -- Checkmark
	ChevronDown = "rbxassetid://10709790948", -- Chevron Down
	ChevronUp   = "rbxassetid://10709791523", -- Chevron Up
}

-- ═══════════════════════════════════════════════════════════════
--  Theme Engine & Curated Dynamic Palettes
-- ═══════════════════════════════════════════════════════════════

local ThemeEngine = {
	Themes = {
		["Liquid Sunset"] = {
			Name = "Liquid Sunset",
			Grad1 = Color3.fromRGB(255, 56, 96),   -- Vibrant Rose Red (#FF3860)
			Grad2 = Color3.fromRGB(58, 134, 255),  -- Royal Electric Blue (#3A86FF)
			Accent = Color3.fromRGB(255, 56, 96),
			Glow = Color3.fromRGB(58, 134, 255),
		},
		["Electric Cyan"] = {
			Name = "Electric Cyan",
			Grad1 = Color3.fromRGB(0, 210, 255),   -- Electric Cyan (#00D2FF)
			Grad2 = Color3.fromRGB(58, 123, 213),  -- Vivid Deep Blue (#3A7BD5)
			Accent = Color3.fromRGB(0, 210, 255),
			Glow = Color3.fromRGB(0, 230, 255),
		},
		["Neon Amethyst"] = {
			Name = "Neon Amethyst",
			Grad1 = Color3.fromRGB(142, 45, 226),  -- Radiant Purple (#8E2DE2)
			Grad2 = Color3.fromRGB(74, 0, 224),    -- Deep Electric Indigo (#4A00E0)
			Accent = Color3.fromRGB(142, 45, 226),
			Glow = Color3.fromRGB(180, 80, 255),
		},
		["Emerald Matrix"] = {
			Name = "Emerald Matrix",
			Grad1 = Color3.fromRGB(0, 242, 96),    -- Mint Neon Green (#00F260)
			Grad2 = Color3.fromRGB(5, 117, 230),   -- Ocean Blue (#0575E6)
			Accent = Color3.fromRGB(0, 242, 96),
			Glow = Color3.fromRGB(46, 213, 115),
		},
		["Crimson Rage"] = {
			Name = "Crimson Rage",
			Grad1 = Color3.fromRGB(255, 65, 108),  -- Hot Coral Red (#FF416C)
			Grad2 = Color3.fromRGB(255, 75, 43),   -- Fiery Orange Red (#FF4B2B)
			Accent = Color3.fromRGB(255, 65, 108),
			Glow = Color3.fromRGB(255, 75, 43),
		},
		["Amber Gold"] = {
			Name = "Amber Gold",
			Grad1 = Color3.fromRGB(255, 179, 0),   -- Gold (#FFB300)
			Grad2 = Color3.fromRGB(255, 87, 34),   -- Blaze Orange (#FF5722)
			Accent = Color3.fromRGB(255, 179, 0),
			Glow = Color3.fromRGB(255, 158, 27),
		},
		["Monochrome Slate"] = {
			Name = "Monochrome Slate",
			Grad1 = Color3.fromRGB(224, 224, 224), -- Pure White Silver (#E0E0E0)
			Grad2 = Color3.fromRGB(67, 67, 67),    -- Deep Carbon (#434343)
			Accent = Color3.fromRGB(224, 224, 224),
			Glow = Color3.fromRGB(180, 180, 180),
		},
	},

	ActiveThemeName = "Monochrome Slate",

	-- Base Surfaces (Liquid Obsidian Glass)
	BackdropBg        = Color3.fromRGB(4, 5, 8),
	MainBg            = Color3.fromRGB(12, 13, 19),
	SidebarBg         = Color3.fromRGB(10, 11, 16),
	SidebarCardBg     = Color3.fromRGB(16, 18, 25),
	SidebarCardHover  = Color3.fromRGB(24, 27, 38),
	HeaderBg          = Color3.fromRGB(12, 13, 19),
	SectionBg         = Color3.fromRGB(16, 18, 26),
	ModuleCardBg      = Color3.fromRGB(18, 20, 29),
	ModuleCardHover   = Color3.fromRGB(24, 27, 40),
	ModuleSettingsBg  = Color3.fromRGB(11, 12, 18),
	ElementBg         = Color3.fromRGB(20, 23, 33),
	ElementHover      = Color3.fromRGB(28, 32, 46),
	ElementActive     = Color3.fromRGB(36, 42, 60),

	-- Borders & Strokes
	Border            = Color3.fromRGB(28, 32, 46),
	BorderLight       = Color3.fromRGB(45, 52, 75),
	GlassStroke       = Color3.fromRGB(255, 255, 255),

	-- Status Colors
	Success           = Color3.fromRGB(46, 213, 115),
	Warning           = Color3.fromRGB(255, 171, 0),
	Danger            = Color3.fromRGB(255, 71, 87),

	-- Typography Colors
	TextPrimary       = Color3.fromRGB(245, 248, 255),
	TextSecondary     = Color3.fromRGB(135, 145, 170),
	TextMuted         = Color3.fromRGB(80, 90, 110),
	TextCategory      = Color3.fromRGB(70, 78, 98),

	-- Geometry
	RadiusSmall       = UDim.new(0, 6),
	RadiusMedium      = UDim.new(0, 8),
	RadiusCard        = UDim.new(0, 10),
	RadiusWindow      = UDim.new(0, 14),
	RadiusPill        = UDim.new(1, 0),
	StrokeThickness   = 1,

	-- Tweens
	TweenQuick        = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TweenSmooth       = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TweenBounce       = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	TweenBlur         = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

function ThemeEngine.GetActiveTheme()
	return ThemeEngine.Themes[ThemeEngine.ActiveThemeName] or ThemeEngine.Themes["Electric Cyan"]
end

function ThemeEngine.SetTheme(name)
	if ThemeEngine.Themes[name] then
		ThemeEngine.ActiveThemeName = name
		return true
	end
	return false
end

-- ═══════════════════════════════════════════════════════════════
--  Helper Utilities
-- ═══════════════════════════════════════════════════════════════

local function playTween(obj, tweenInfo, props)
	if not obj then return nil end
	local tw = TweenService:Create(obj, tweenInfo, props)
	tw:Play()
	return tw
end

local function createGradient(parent, c1, c2, rot)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(c1, c2)
	grad.Rotation = rot or 0
	grad.Parent = parent
	return grad
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or ThemeEngine.Border
	stroke.Thickness = thickness or ThemeEngine.StrokeThickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function formatNumber(val, step)
	if step >= 1 then
		return tostring(math.floor(val + 0.5))
	end
	local dec = math.max(1, math.ceil(-math.log10(step + 1e-9)))
	return string.format("%." .. tostring(dec) .. "f", val)
end

local function snapValue(val, min, max, step)
	if step > 0 then
		val = math.floor((val - min) / step + 0.5) * step + min
	end
	return math.clamp(val, min, max)
end

local function getKeyName(key)
	if not key then return "None" end
	if typeof(key) == "EnumItem" then
		if key == Enum.KeyCode.Unknown then return "None" end
		if key == Enum.UserInputType.MouseButton1 then return "MB1" end
		if key == Enum.UserInputType.MouseButton2 then return "MB2" end
		if key == Enum.UserInputType.MouseButton3 then return "MB3" end
		local str = tostring(key.Name)
		if str == "RightShift" then return "RShift" end
		if str == "LeftShift" then return "LShift" end
		if str == "RightControl" then return "RCtrl" end
		if str == "LeftControl" then return "LCtrl" end
		if str == "RightAlt" then return "RAlt" end
		if str == "LeftAlt" then return "LAlt" end
		if str == "CapsLock" then return "Caps" end
		if str == "PageUp" then return "PgUp" end
		if str == "PageDown" then return "PgDn" end
		if str == "Backspace" then return "Bcksp" end
		if str == "Delete" then return "Del" end
		if str == "Insert" then return "Ins" end
		if string.sub(str, 1, 6) == "Keypad" then
			return "KP" .. string.sub(str, 7)
		end
		return str
	end
	return tostring(key)
end

local function createIcon(parent, assetId, size, pos, color)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.Size = size or UDim2.fromOffset(16, 16)
	img.Position = pos or UDim2.fromOffset(0, 0)
	img.BackgroundTransparency = 1
	img.Image = assetId or Icons.Logo
	img.ImageColor3 = color or ThemeEngine.TextSecondary
	img.ScaleType = Enum.ScaleType.Fit
	img.BorderSizePixel = 0
	img.ZIndex = (parent and parent.ZIndex or 1) + 1
	img.Parent = parent
	return img
end

-- ═══════════════════════════════════════════════════════════════
--  Library Constructor
-- ═══════════════════════════════════════════════════════════════

local Library = {}
local defaultInstance = nil

function Library.new()
	local container = getGuiContainer()

	local connections = {}
	local instances = {}
	local themeChangeListeners = {}

	local function connect(sig, fn)
		local conn = sig:Connect(fn)
		table.insert(connections, conn)
		return conn
	end

	-- Depth-of-field BlurEffect behind menu
	local menuBlur = Instance.new("BlurEffect")
	menuBlur.Name = "ZeHub_MenuBlur"
	menuBlur.Size = 0
	menuBlur.Enabled = true
	menuBlur.Parent = Lighting
	table.insert(instances, menuBlur)

	-- 1. Main Gui
	local mainGui = Instance.new("ScreenGui")
	mainGui.Name = "ZeHub_Main"
	mainGui.DisplayOrder = 100
	mainGui.ResetOnSpawn = false
	mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainGui.IgnoreGuiInset = true
	mainGui.Parent = container
	table.insert(instances, mainGui)

	-- Full-screen modal shade behind the window
	local backdropShade = Instance.new("Frame")
	backdropShade.Name = "ModalBackdrop"
	backdropShade.Size = UDim2.new(1, 0, 1, 0)
	backdropShade.Position = UDim2.new(0, 0, 0, 0)
	backdropShade.BackgroundColor3 = ThemeEngine.BackdropBg
	backdropShade.BackgroundTransparency = 1
	backdropShade.BorderSizePixel = 0
	backdropShade.ZIndex = 1
	backdropShade.Visible = false
	backdropShade.Parent = mainGui

	-- 2. Overlay Gui (Popups, Dropdowns, Colorpickers)
	local overlayGui = Instance.new("ScreenGui")
	overlayGui.Name = "ZeHub_Overlay"
	overlayGui.DisplayOrder = 1000
	overlayGui.ResetOnSpawn = false
	overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	overlayGui.IgnoreGuiInset = true
	overlayGui.Parent = container
	table.insert(instances, overlayGui)

	-- 3. HUD Gui (Watermark, Keybinds list, Toasts)
	local hudGui = Instance.new("ScreenGui")
	hudGui.Name = "ZeHub_HUD"
	hudGui.DisplayOrder = 2000
	hudGui.ResetOnSpawn = false
	hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hudGui.IgnoreGuiInset = true
	hudGui.Parent = container
	table.insert(instances, hudGui)

	-- Global popup closer for overlay
	local activeOverlayCloser = nil
	local function closeActiveOverlay()
		if activeOverlayCloser then
			activeOverlayCloser()
			activeOverlayCloser = nil
		end
	end

	-- Keybinds HUD registry
	local registeredKeybinds = {}
	local updateKeybindListUI = nil

	-- ─────────────────────────────────────────────────────────
	--  Notifications System (Floating Toasts)
	-- ─────────────────────────────────────────────────────────

	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "NotificationContainer"
	notifContainer.Size = UDim2.new(0, 280, 1, -40)
	notifContainer.Position = UDim2.new(1, -295, 0, 20)
	notifContainer.BackgroundTransparency = 1
	notifContainer.Parent = hudGui

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.FillDirection = Enum.FillDirection.Vertical
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.Padding = UDim.new(0, 8)
	notifLayout.Parent = notifContainer

	-- ─────────────────────────────────────────────────────────
	--  Drag Helper
	-- ─────────────────────────────────────────────────────────

	local function makeDraggable(gui, handle)
		handle = handle or gui
		local dragging = false
		local dragStart = nil
		local startPos = nil

		connect(handle.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position

				local changedConn
				changedConn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						if changedConn then
							changedConn:Disconnect()
							changedConn = nil
						end
					end
				end)
			end
		end)

		connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				gui.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	local function showNotification(nCfg)
		nCfg = nCfg or {}
		local nTitle = nCfg.Title or "Notification"
		local nContent = nCfg.Content or ""
		local nDuration = nCfg.Duration or 3.0
		local nType = nCfg.Type or "Info"

		local nFrame = Instance.new("Frame")
		nFrame.Name = "Toast"
		nFrame.Size = UDim2.new(1, 0, 0, 56)
		nFrame.BackgroundColor3 = ThemeEngine.MainBg
		nFrame.BackgroundTransparency = 0.08
		nFrame.BorderSizePixel = 0
		nFrame.ClipsDescendants = true
		nFrame.Position = UDim2.new(1, 40, 0, 0)
		nFrame.ZIndex = 10

		local nCorner = Instance.new("UICorner")
		nCorner.CornerRadius = ThemeEngine.RadiusMedium
		nCorner.Parent = nFrame

		local _nStroke = createStroke(nFrame, ThemeEngine.Border)

		-- Left Accent Bar with Active Theme Gradient
		local leftBar = Instance.new("Frame")
		leftBar.Name = "AccentBar"
		leftBar.Size = UDim2.new(0, 4, 1, 0)
		leftBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		leftBar.BorderSizePixel = 0
		leftBar.ZIndex = 11

		local barGrad = createGradient(leftBar, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 90)
		leftBar.Parent = nFrame

		local typeColor = if nType == "Success" then ThemeEngine.Success
			elseif nType == "Warning" then ThemeEngine.Warning
			elseif nType == "Danger" then ThemeEngine.Danger
			else ThemeEngine.GetActiveTheme().Grad1

		local nIcon = createIcon(nFrame, Icons.Checkmark, UDim2.fromOffset(18, 18), UDim2.fromOffset(12, 12), typeColor)
		nIcon.ZIndex = 11

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(1, -40, 0, 16)
		titleLabel.Position = UDim2.fromOffset(36, 10)
		titleLabel.BackgroundTransparency = 1
		applyFont(titleLabel, "Bold")
		titleLabel.TextSize = 12
		titleLabel.TextColor3 = ThemeEngine.TextPrimary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Text = nTitle
		titleLabel.ZIndex = 11
		titleLabel.Parent = nFrame

		local msgLabel = Instance.new("TextLabel")
		msgLabel.Name = "Content"
		msgLabel.Size = UDim2.new(1, -40, 0, 18)
		msgLabel.Position = UDim2.fromOffset(36, 28)
		msgLabel.BackgroundTransparency = 1
		applyFont(msgLabel, "Medium")
		msgLabel.TextSize = 11
		msgLabel.TextColor3 = ThemeEngine.TextSecondary
		msgLabel.TextXAlignment = Enum.TextXAlignment.Left
		msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
		msgLabel.Text = nContent
		msgLabel.ZIndex = 11
		msgLabel.Parent = nFrame

		-- Progress Bar
		local pBar = Instance.new("Frame")
		pBar.Name = "Progress"
		pBar.Size = UDim2.new(1, 0, 0, 2)
		pBar.Position = UDim2.new(0, 0, 1, -2)
		pBar.BackgroundColor3 = typeColor
		pBar.BorderSizePixel = 0
		pBar.ZIndex = 12
		pBar.Parent = nFrame

		nFrame.Parent = notifContainer

		playTween(nFrame, ThemeEngine.TweenSmooth, { Position = UDim2.new(0, 0, 0, 0) })
		playTween(pBar, TweenInfo.new(nDuration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })

		task.delay(nDuration, function()
			playTween(nFrame, ThemeEngine.TweenQuick, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
			task.delay(0.15, function()
				nFrame:Destroy()
			end)
		end)
	end

	-- ─────────────────────────────────────────────────────────
	--  Keybinds Floating HUD
	-- ─────────────────────────────────────────────────────────

	local keybindsFrame = Instance.new("Frame")
	keybindsFrame.Name = "KeybindsHUD"
	keybindsFrame.Size = UDim2.fromOffset(170, 30)
	keybindsFrame.Position = UDim2.new(0, 20, 0.45, 0)
	keybindsFrame.BackgroundColor3 = ThemeEngine.MainBg
	keybindsFrame.BackgroundTransparency = 0.12
	keybindsFrame.BorderSizePixel = 0
	keybindsFrame.AutomaticSize = Enum.AutomaticSize.Y
	keybindsFrame.ZIndex = 100
	keybindsFrame.Visible = true

	local kbCorner = Instance.new("UICorner")
	kbCorner.CornerRadius = ThemeEngine.RadiusMedium
	kbCorner.Parent = keybindsFrame
	local _kbStroke = createStroke(keybindsFrame, ThemeEngine.Border)

	local kbHeader = Instance.new("Frame")
	kbHeader.Name = "Header"
	kbHeader.Size = UDim2.new(1, 0, 0, 28)
	kbHeader.BackgroundTransparency = 1
	kbHeader.ZIndex = 101
	kbHeader.Parent = keybindsFrame

	local kbTitle = Instance.new("TextLabel")
	kbTitle.Name = "Title"
	kbTitle.Size = UDim2.new(1, -24, 1, 0)
	kbTitle.Position = UDim2.fromOffset(10, 0)
	kbTitle.BackgroundTransparency = 1
	applyFont(kbTitle, "Bold")
	kbTitle.TextSize = 11
	kbTitle.TextColor3 = ThemeEngine.TextPrimary
	kbTitle.TextXAlignment = Enum.TextXAlignment.Left
	kbTitle.Text = "KEYBINDS"
	kbTitle.ZIndex = 102
	kbTitle.Parent = kbHeader

	local kbList = Instance.new("Frame")
	kbList.Name = "List"
	kbList.Size = UDim2.new(1, -12, 0, 0)
	kbList.Position = UDim2.fromOffset(6, 28)
	kbList.BackgroundTransparency = 1
	kbList.AutomaticSize = Enum.AutomaticSize.Y
	kbList.ZIndex = 101

	local kbLayout = Instance.new("UIListLayout")
	kbLayout.FillDirection = Enum.FillDirection.Vertical
	kbLayout.SortOrder = Enum.SortOrder.LayoutOrder
	kbLayout.Padding = UDim.new(0, 4)
	kbLayout.Parent = kbList
	kbList.Parent = keybindsFrame

	makeDraggable(keybindsFrame, kbHeader)
	keybindsFrame.Parent = hudGui

	updateKeybindListUI = function()
		for _, child in ipairs(kbList:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local count = 0
		for name, data in pairs(registeredKeybinds) do
			if data.Key and data.Key ~= Enum.KeyCode.Unknown then
				count = count + 1
				local row = Instance.new("Frame")
				row.Name = "Item_" .. name
				row.Size = UDim2.new(1, 0, 0, 22)
				row.BackgroundColor3 = ThemeEngine.ElementBg
				row.BackgroundTransparency = 0.5
				row.BorderSizePixel = 0
				row.ZIndex = 102

				local rCorner = Instance.new("UICorner")
				rCorner.CornerRadius = ThemeEngine.RadiusSmall
				rCorner.Parent = row

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "Name"
				nameLabel.Size = UDim2.new(1, -55, 1, 0)
				nameLabel.Position = UDim2.fromOffset(8, 0)
				nameLabel.BackgroundTransparency = 1
				applyFont(nameLabel, "Medium")
				nameLabel.TextSize = 10
				nameLabel.TextColor3 = ThemeEngine.TextPrimary
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.Text = name
				nameLabel.ZIndex = 103
				nameLabel.Parent = row

				local keyTag = Instance.new("TextLabel")
				keyTag.Name = "KeyTag"
				keyTag.Size = UDim2.new(0, 45, 1, -4)
				keyTag.Position = UDim2.new(1, -49, 0, 2)
				keyTag.BackgroundColor3 = if data.Active then ThemeEngine.GetActiveTheme().Grad1 else ThemeEngine.SidebarCardBg
				keyTag.BackgroundTransparency = if data.Active then 0.1 else 0.4
				keyTag.BorderSizePixel = 0
				applyFont(keyTag, "Bold")
				keyTag.TextSize = 9
				keyTag.TextColor3 = Color3.fromRGB(255, 255, 255)
				keyTag.Text = "[" .. getKeyName(data.Key) .. "]"
				keyTag.ZIndex = 103

				local ktCorner = Instance.new("UICorner")
				ktCorner.CornerRadius = ThemeEngine.RadiusSmall
				ktCorner.Parent = keyTag
				keyTag.Parent = row

				row.Parent = kbList
			end
		end

		keybindsFrame.Visible = (count > 0)
	end

	-- ─────────────────────────────────────────────────────────
	--  Public Library Object
	-- ─────────────────────────────────────────────────────────

	local lib = {}
	local configState = {Theme = ThemeEngine.ActiveThemeName, Scale = 1, Opacity = 95, ReducedMotion = false}
	local configFolder, configFile = "ZeHub", "ZeHub/config.json"

	local function configAvailable()
		return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
	end

	function lib:SetConfigValue(key, value)
		if type(key) ~= "string" or key == "" then return false end
		configState[key] = value
		return true
	end

	function lib:GetConfig()
		local copy = {}
		for k, v in pairs(configState) do copy[k] = v end
		return copy
	end

	function lib:SaveConfig(name)
		if not configAvailable() or type(game:GetService("HttpService").JSONEncode) ~= "function" then return false, "File APIs unavailable" end
		local HttpService = game:GetService("HttpService")
		local folder = configFolder
		local file = folder .. "/" .. tostring(name or "default"):gsub("[^%w_%-]", "") .. ".json"
		local ok, err = pcall(function()
			if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then makefolder(folder) end
			writefile(file, HttpService:JSONEncode(configState))
		end)
		return ok, err
	end

	function lib:LoadConfig(name)
		if not configAvailable() then return false, "File APIs unavailable" end
		local HttpService = game:GetService("HttpService")
		local file = configFolder .. "/" .. tostring(name or "default"):gsub("[^%w_%-]", "") .. ".json"
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
		if not ok or type(data) ~= "table" then return false, "Config not found or invalid" end
		for k, v in pairs(data) do configState[k] = v end
		return true, configState
	end

	function lib:Notify(cfg)
		showNotification(cfg)
	end

	function lib:SetTheme(name)
		if ThemeEngine.SetTheme(name) then
			local t = ThemeEngine.GetActiveTheme()
			for _, listener in ipairs(themeChangeListeners) do
				task.spawn(listener, t)
			end
			return true
		end
		return false
	end

	function lib:GetTheme()
		return ThemeEngine.ActiveThemeName
	end

	function lib:GetThemes()
		local tList = {}
		for k, _ in pairs(ThemeEngine.Themes) do
			table.insert(tList, k)
		end
		table.sort(tList)
		return tList
	end

	-- Watermark HUD
	function lib:Watermark(cfg)
		cfg = cfg or {}
		local wmText = cfg.Name or "ZeHub"
		local showFps = if cfg.ShowFps ~= nil then cfg.ShowFps else true
		local showPing = if cfg.ShowPing ~= nil then cfg.ShowPing else true

		local wmFrame = Instance.new("Frame")
		wmFrame.Name = "Watermark"
		wmFrame.Size = UDim2.fromOffset(210, 26)
		wmFrame.Position = UDim2.fromOffset(20, 20)
		wmFrame.BackgroundColor3 = ThemeEngine.MainBg
		wmFrame.BackgroundTransparency = 0.12
		wmFrame.BorderSizePixel = 0
		wmFrame.ZIndex = 150

		local wmCorner = Instance.new("UICorner")
		wmCorner.CornerRadius = ThemeEngine.RadiusSmall
		wmCorner.Parent = wmFrame

		local _wmStroke = createStroke(wmFrame, ThemeEngine.Border)

		-- Left glowing gradient indicator
		local wmIndicator = Instance.new("Frame")
		wmIndicator.Name = "Indicator"
		wmIndicator.Size = UDim2.new(0, 3, 1, -8)
		wmIndicator.Position = UDim2.new(0, 4, 0, 4)
		wmIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		wmIndicator.BorderSizePixel = 0
		wmIndicator.ZIndex = 151

		local wiCorner = Instance.new("UICorner")
		wiCorner.CornerRadius = ThemeEngine.RadiusPill
		wiCorner.Parent = wmIndicator

		local wiGrad = createGradient(wmIndicator, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 90)
		wmIndicator.Parent = wmFrame

		local wmLabel = Instance.new("TextLabel")
		wmLabel.Name = "Text"
		wmLabel.Size = UDim2.new(1, -16, 1, 0)
		wmLabel.Position = UDim2.fromOffset(14, 0)
		wmLabel.BackgroundTransparency = 1
		applyFont(wmLabel, "Bold")
		wmLabel.TextSize = 11
		wmLabel.TextColor3 = ThemeEngine.TextPrimary
		wmLabel.TextXAlignment = Enum.TextXAlignment.Left
		wmLabel.Text = wmText
		wmLabel.ZIndex = 151
		wmLabel.Parent = wmFrame

		table.insert(themeChangeListeners, function(theme)
			wiGrad.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
		end)

		makeDraggable(wmFrame)
		wmFrame.Parent = hudGui

		local fps = 60
		local frameCount = 0
		local lastUpdate = os.clock()

		connect(RunService.RenderStepped, function()
			frameCount = frameCount + 1
			local now = os.clock()
			if now - lastUpdate >= 0.5 then
				fps = math.floor(frameCount / (now - lastUpdate) + 0.5)
				frameCount = 0
				lastUpdate = now

				local str = wmText
				if showFps then
					str = str .. "  |  " .. tostring(fps) .. " fps"
				end
				if showPing then
					local ping = 45
					pcall(function()
						local net = StatsService and StatsService.Network
						if net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"] then
							ping = math.floor(net.ServerStatsItem["Data Ping"]:GetValue())
						end
					end)
					str = str .. "  |  " .. tostring(ping) .. " ms"
				end
				wmLabel.Text = str
				local textLen = #str * 6.5 + 30
				wmFrame.Size = UDim2.fromOffset(math.max(160, textLen), 26)
			end
		end)

		return wmFrame
	end

	-- ═════════════════════════════════════════════════════════
	--  Main Window Constructor (ZeHub Liquid Glass Architecture)
	-- ═════════════════════════════════════════════════════════

	function lib:Window(cfg)
		cfg = cfg or {}
		local brandTitle = cfg.Title or "ZeHub"
		local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
		local winSize = cfg.Size or UDim2.fromOffset(900, 620)
		local isOpen = true
		local isKeybindListVisible = true

		local windowHandle = {}

		-- Shadow Behind Main Window (9-slice soft bloom)
		local shadowFrame = Instance.new("ImageLabel")
		shadowFrame.Name = "WindowShadow"
		shadowFrame.Size = winSize + UDim2.fromOffset(36, 36)
		shadowFrame.Position = UDim2.new(0.5, -winSize.X.Offset / 2 - 18, 0.5, -winSize.Y.Offset / 2 - 14)
		shadowFrame.BackgroundTransparency = 1
		shadowFrame.Image = "rbxassetid://6015897843"
		shadowFrame.SliceCenter = Rect.new(49, 49, 450, 450)
		shadowFrame.ScaleType = Enum.ScaleType.Slice
		shadowFrame.ImageColor3 = Color3.fromRGB(0, 0, 0)
		shadowFrame.ImageTransparency = 0.35
		shadowFrame.ZIndex = 1
		shadowFrame.Parent = mainGui

		-- Main Window Container
		local mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainWindow"
		mainFrame.Size = winSize
		mainFrame.Position = UDim2.new(0.5, -winSize.X.Offset / 2, 0.5, -winSize.Y.Offset / 2)
		mainFrame.BackgroundColor3 = ThemeEngine.MainBg
		mainFrame.BackgroundTransparency = 0.05
		mainFrame.BorderSizePixel = 0
		mainFrame.ClipsDescendants = true
		mainFrame.ZIndex = 2
		mainFrame.Parent = mainGui

		local mainScale = Instance.new("UIScale")
		mainScale.Name = "ZeHubResponsiveScale"
		mainScale.Scale = 1
		mainScale.Parent = mainFrame

		local mCorner = Instance.new("UICorner")
		mCorner.CornerRadius = ThemeEngine.RadiusWindow
		mCorner.Parent = mainFrame

		local mStroke = createStroke(mainFrame, ThemeEngine.Border)

		-- Specular Rim Highlight Gradient
		local _mStrokeGrad = createGradient(mStroke, Color3.fromRGB(85, 95, 125), Color3.fromRGB(22, 25, 36), 115)

		-- Custom Background Image Decal Container
		local bgImageDecal = Instance.new("ImageLabel")
		bgImageDecal.Name = "BackgroundDecal"
		bgImageDecal.Size = UDim2.new(1, 0, 1, 0)
		bgImageDecal.BackgroundTransparency = 1
		bgImageDecal.Image = ""
		bgImageDecal.ImageTransparency = 0.85
		bgImageDecal.ScaleType = Enum.ScaleType.Crop
		bgImageDecal.ZIndex = 2
		bgImageDecal.Parent = mainFrame

		-- ─── Left Sidebar Container (135px) ───
		local sidebar = Instance.new("Frame")
		sidebar.Name = "Sidebar"
		sidebar.Size = UDim2.new(0, 190, 1, 0)
		sidebar.BackgroundColor3 = ThemeEngine.SidebarBg
		sidebar.BackgroundTransparency = 0.1
		sidebar.BorderSizePixel = 0
		sidebar.ZIndex = 3
		sidebar.Parent = mainFrame

		local sbBorder = Instance.new("Frame")
		sbBorder.Name = "RightBorder"
		sbBorder.Size = UDim2.new(0, 1, 1, 0)
		sbBorder.Position = UDim2.new(1, -1, 0, 0)
		sbBorder.BackgroundColor3 = ThemeEngine.Border
		sbBorder.BorderSizePixel = 0
		sbBorder.ZIndex = 4
		sbBorder.Parent = sidebar

		-- Brand Header in Sidebar (Avatar Logo + Brand Name)
		local brandHeader = Instance.new("Frame")
		brandHeader.Name = "BrandHeader"
		brandHeader.Size = UDim2.new(1, 0, 0, 48)
		brandHeader.BackgroundTransparency = 1
		brandHeader.ZIndex = 4
		brandHeader.Parent = sidebar

		local logoBox = Instance.new("Frame")
		logoBox.Name = "LogoBox"
		logoBox.Size = UDim2.fromOffset(28, 28)
		logoBox.Position = UDim2.fromOffset(12, 10)
		logoBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		logoBox.BorderSizePixel = 0
		logoBox.ZIndex = 5

		local lbCorner = Instance.new("UICorner")
		lbCorner.CornerRadius = ThemeEngine.RadiusMedium
		lbCorner.Parent = logoBox

		local lbGrad = createGradient(logoBox, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 45)
		local lbIcon = createIcon(logoBox, Icons.Logo, UDim2.fromOffset(18, 18), UDim2.fromOffset(5, 5), Color3.fromRGB(255, 255, 255))
		lbIcon.ZIndex = 6
		logoBox.Parent = brandHeader

		local brandLabel = Instance.new("TextLabel")
		brandLabel.Name = "BrandLabel"
		brandLabel.Size = UDim2.new(1, -50, 1, 0)
		brandLabel.Position = UDim2.fromOffset(48, 0)
		brandLabel.BackgroundTransparency = 1
		applyFont(brandLabel, "Bold")
		brandLabel.TextSize = 14
		brandLabel.TextColor3 = ThemeEngine.TextPrimary
		brandLabel.TextXAlignment = Enum.TextXAlignment.Left
		brandLabel.Text = brandTitle
		brandLabel.ZIndex = 5
		brandLabel.Parent = brandHeader

		-- Tab List Scrolling Container
		local tabListFrame = Instance.new("ScrollingFrame")
		tabListFrame.Name = "TabList"
		tabListFrame.Size = UDim2.new(1, -12, 1, -94)
		tabListFrame.Position = UDim2.fromOffset(6, 48)
		tabListFrame.BackgroundTransparency = 1
		tabListFrame.BorderSizePixel = 0
		tabListFrame.ScrollBarThickness = 0
		tabListFrame.CanvasSize = UDim2.new()
		tabListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabListFrame.ZIndex = 4

		local sbLayout = Instance.new("UIListLayout")
		sbLayout.FillDirection = Enum.FillDirection.Vertical
		sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
		sbLayout.Padding = UDim.new(0, 3)
		sbLayout.Parent = tabListFrame
		tabListFrame.Parent = sidebar

		-- Bottom Sidebar Unload Button (Unload Script)
		local unloadBtn = Instance.new("TextButton")
		unloadBtn.Name = "UnloadBtn"
		unloadBtn.Size = UDim2.new(1, -16, 0, 30)
		unloadBtn.Position = UDim2.new(0, 8, 1, -38)
		unloadBtn.BackgroundColor3 = ThemeEngine.SidebarCardBg
		unloadBtn.BackgroundTransparency = 0.5
		unloadBtn.AutoButtonColor = false
		unloadBtn.BorderSizePixel = 0
		unloadBtn.ZIndex = 5
		unloadBtn.Text = ""

		local ubCorner = Instance.new("UICorner")
		ubCorner.CornerRadius = ThemeEngine.RadiusSmall
		ubCorner.Parent = unloadBtn
		local _ubStroke = createStroke(unloadBtn, ThemeEngine.Border)

		local ubIcon = createIcon(unloadBtn, Icons.Power, UDim2.fromOffset(13, 13), UDim2.new(0, 8, 0.5, -6.5), ThemeEngine.TextSecondary)
		ubIcon.ZIndex = 6

		local ubText = Instance.new("TextLabel")
		ubText.Name = "Text"
		ubText.Size = UDim2.new(1, -30, 1, 0)
		ubText.Position = UDim2.fromOffset(28, 0)
		ubText.BackgroundTransparency = 1
		applyFont(ubText, "SemiBold")
		ubText.TextSize = 11
		ubText.TextColor3 = ThemeEngine.TextSecondary
		ubText.TextXAlignment = Enum.TextXAlignment.Left
		ubText.Text = "Unload"
		ubText.ZIndex = 6
		ubText.Parent = unloadBtn

		connect(unloadBtn.MouseEnter, function()
			playTween(unloadBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.Danger, BackgroundTransparency = 0.2 })
			playTween(ubText, ThemeEngine.TweenQuick, { TextColor3 = Color3.fromRGB(255, 255, 255) })
			playTween(ubIcon, ThemeEngine.TweenQuick, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
		end)
		connect(unloadBtn.MouseLeave, function()
			playTween(unloadBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.SidebarCardBg, BackgroundTransparency = 0.5 })
			playTween(ubText, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextSecondary })
			playTween(ubIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
		end)
		connect(unloadBtn.Activated, function()
			if cfg.OnUnload then
				cfg.OnUnload()
			else
				lib:Destroy()
			end
		end)

		unloadBtn.Parent = sidebar

		-- ─── Bottom-left Player Profile Card ───
		local profileCard = Instance.new("Frame")
		profileCard.Name = "ProfileCard"
		profileCard.Size = UDim2.new(1, -16, 0, 58)
		profileCard.Position = UDim2.new(0, 8, 1, -104)
		profileCard.BackgroundColor3 = ThemeEngine.SidebarCardBg
		profileCard.BackgroundTransparency = 0.12
		profileCard.BorderSizePixel = 0
		profileCard.ZIndex = 5
		profileCard.Parent = sidebar
		local pcCorner = Instance.new("UICorner")
		pcCorner.CornerRadius = ThemeEngine.RadiusMedium
		pcCorner.Parent = profileCard
		local _pcStroke = createStroke(profileCard, ThemeEngine.Border)

		local profileAvatar = Instance.new("ImageLabel")
		profileAvatar.Name = "Avatar"
		profileAvatar.Size = UDim2.fromOffset(36, 36)
		profileAvatar.Position = UDim2.fromOffset(8, 11)
		profileAvatar.BackgroundColor3 = ThemeEngine.ElementBg
		profileAvatar.BorderSizePixel = 0
		profileAvatar.ZIndex = 6
		profileAvatar.Parent = profileCard
		local paCorner = Instance.new("UICorner")
		paCorner.CornerRadius = UDim.new(1, 0)
		paCorner.Parent = profileAvatar
		pcall(function()
			local image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			profileAvatar.Image = image
		end)

		local profileName = Instance.new("TextLabel")
		profileName.Name = "Username"
		profileName.Size = UDim2.new(1, -56, 0, 18)
		profileName.Position = UDim2.fromOffset(52, 11)
		profileName.BackgroundTransparency = 1
		applyFont(profileName, "SemiBold")
		profileName.TextSize = 11
		profileName.TextColor3 = ThemeEngine.TextPrimary
		profileName.TextXAlignment = Enum.TextXAlignment.Left
		profileName.TextTruncate = Enum.TextTruncate.AtEnd
		profileName.Text = LocalPlayer.DisplayName or LocalPlayer.Name
		profileName.ZIndex = 6
		profileName.Parent = profileCard

		local profileStatus = Instance.new("TextLabel")
		profileStatus.Name = "Status"
		profileStatus.Size = UDim2.new(1, -56, 0, 15)
		profileStatus.Position = UDim2.fromOffset(52, 29)
		profileStatus.BackgroundTransparency = 1
		applyFont(profileStatus, "Regular")
		profileStatus.TextSize = 9
		profileStatus.TextColor3 = ThemeEngine.TextMuted
		profileStatus.TextXAlignment = Enum.TextXAlignment.Left
		profileStatus.Text = "●  ZeHub user"
		profileStatus.ZIndex = 6
		profileStatus.Parent = profileCard

		-- ─── Top Bar in Right Area (Search & Quick Action Icons) ───
		local topBar = Instance.new("Frame")
		topBar.Name = "TopBar"
		topBar.Size = UDim2.new(1, -190, 0, 64)
		topBar.Position = UDim2.fromOffset(190, 0)
		topBar.BackgroundTransparency = 1
		topBar.ZIndex = 4
		topBar.Parent = mainFrame

		-- Search Bar Container
		local searchBox = Instance.new("Frame")
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(0, 300, 0, 38)
		searchBox.Position = UDim2.new(0.5, -150, 0.5, -19)
		searchBox.BackgroundColor3 = ThemeEngine.ElementBg
		searchBox.BackgroundTransparency = 0.4
		searchBox.BorderSizePixel = 0
		searchBox.ZIndex = 5

		local sCorner = Instance.new("UICorner")
		sCorner.CornerRadius = ThemeEngine.RadiusMedium
		sCorner.Parent = searchBox
		local sStroke = createStroke(searchBox, ThemeEngine.Border)

		local sIcon = createIcon(searchBox, Icons.Search, UDim2.fromOffset(14, 14), UDim2.new(0, 8, 0.5, -7), ThemeEngine.TextMuted)
		sIcon.ZIndex = 6

		local searchInput = Instance.new("TextBox")
		searchInput.Name = "Input"
		searchInput.Size = UDim2.new(1, -28, 1, 0)
		searchInput.Position = UDim2.fromOffset(26, 0)
		searchInput.BackgroundTransparency = 1
		applyFont(searchInput, "Medium")
		searchInput.TextSize = 11
		searchInput.TextColor3 = ThemeEngine.TextPrimary
		searchInput.PlaceholderText = "Search modules..."
		searchInput.PlaceholderColor3 = ThemeEngine.TextMuted
		searchInput.Text = ""
		searchInput.ClearTextOnFocus = false
		searchInput.BorderSizePixel = 0
		searchInput.ZIndex = 6
		searchInput.Parent = searchBox
		searchBox.Parent = topBar

		connect(searchInput.Focused, function()
			playTween(sStroke, ThemeEngine.TweenQuick, { Color = ThemeEngine.GetActiveTheme().Grad1 })
			playTween(sIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.GetActiveTheme().Grad1 })
		end)
		connect(searchInput.FocusLost, function()
			playTween(sStroke, ThemeEngine.TweenQuick, { Color = ThemeEngine.Border })
			playTween(sIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextMuted })
		end)

		-- Top Right Quick Action Buttons
		local actionTray = Instance.new("Frame")
		actionTray.Name = "ActionTray"
		actionTray.Size = UDim2.new(0, 150, 1, 0)
		actionTray.Position = UDim2.new(1, -160, 0, 0)
		actionTray.BackgroundTransparency = 1
		actionTray.ZIndex = 5

		local atLayout = Instance.new("UIListLayout")
		atLayout.FillDirection = Enum.FillDirection.Horizontal
		atLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		atLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		atLayout.SortOrder = Enum.SortOrder.LayoutOrder
		atLayout.Padding = UDim.new(0, 6)
		atLayout.Parent = actionTray
		actionTray.Parent = topBar

		-- Quick button: Themes
		local themeQuickBtn = Instance.new("ImageButton")
		themeQuickBtn.Name = "ThemeBtn"
		themeQuickBtn.Size = UDim2.fromOffset(32, 32)
		themeQuickBtn.BackgroundColor3 = ThemeEngine.ElementBg
		themeQuickBtn.BackgroundTransparency = 0.4
		themeQuickBtn.AutoButtonColor = false
		themeQuickBtn.BorderSizePixel = 0
		themeQuickBtn.ZIndex = 6

		local tqbCorner = Instance.new("UICorner")
		tqbCorner.CornerRadius = ThemeEngine.RadiusSmall
		tqbCorner.Parent = themeQuickBtn
		local _tqbStroke = createStroke(themeQuickBtn, ThemeEngine.Border)

		local tqbIcon = createIcon(themeQuickBtn, Icons.Themes, UDim2.fromOffset(14, 14), UDim2.new(0.5, -7, 0.5, -7), ThemeEngine.TextSecondary)
		tqbIcon.ZIndex = 7

		connect(themeQuickBtn.MouseEnter, function()
			playTween(themeQuickBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementHover })
			playTween(tqbIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextPrimary })
		end)
		connect(themeQuickBtn.MouseLeave, function()
			playTween(themeQuickBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementBg })
			playTween(tqbIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
		end)
		themeQuickBtn.Parent = actionTray

		-- Quick button: Keybinds HUD Toggle
		local kbQuickBtn = Instance.new("ImageButton")
		kbQuickBtn.Name = "KeybindsBtn"
		kbQuickBtn.Size = UDim2.fromOffset(32, 32)
		kbQuickBtn.BackgroundColor3 = ThemeEngine.ElementBg
		kbQuickBtn.BackgroundTransparency = 0.4
		kbQuickBtn.AutoButtonColor = false
		kbQuickBtn.BorderSizePixel = 0
		kbQuickBtn.ZIndex = 6

		local kqbCorner = Instance.new("UICorner")
		kqbCorner.CornerRadius = ThemeEngine.RadiusSmall
		kqbCorner.Parent = kbQuickBtn
		local _kqbStroke = createStroke(kbQuickBtn, ThemeEngine.Border)

		local kqbIcon = createIcon(kbQuickBtn, Icons.Keybind, UDim2.fromOffset(13, 13), UDim2.new(0.5, -6.5, 0.5, -6.5), ThemeEngine.TextSecondary)
		kqbIcon.ZIndex = 7

		connect(kbQuickBtn.MouseEnter, function()
			playTween(kbQuickBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementHover })
			playTween(kqbIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextPrimary })
		end)
		connect(kbQuickBtn.MouseLeave, function()
			playTween(kbQuickBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementBg })
			playTween(kqbIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
		end)
		connect(kbQuickBtn.Activated, function()
			isKeybindListVisible = not isKeybindListVisible
			keybindsFrame.Visible = isKeybindListVisible
			playTween(kqbIcon, ThemeEngine.TweenQuick, {
				ImageColor3 = if isKeybindListVisible then ThemeEngine.GetActiveTheme().Grad1 else ThemeEngine.TextSecondary
			})
		end)

		kbQuickBtn.Parent = actionTray

		local function makeWindowAction(name, glyph, order)
			local button = Instance.new("TextButton")
			button.Name = name
			button.Size = UDim2.fromOffset(32, 32)
			button.BackgroundColor3 = ThemeEngine.ElementBg
			button.BackgroundTransparency = 0.4
			button.AutoButtonColor = false
			button.BorderSizePixel = 0
			button.Text = glyph
			button.TextSize = 18
			button.TextColor3 = ThemeEngine.TextSecondary
			button.Font = Enum.Font.Gotham
			button.LayoutOrder = order
			button.ZIndex = 6
			local corner = Instance.new("UICorner")
			corner.CornerRadius = ThemeEngine.RadiusSmall
			corner.Parent = button
			createStroke(button, ThemeEngine.Border)
			connect(button.MouseEnter, function()
				playTween(button, ThemeEngine.TweenQuick, {BackgroundColor3 = ThemeEngine.ElementHover, TextColor3 = ThemeEngine.TextPrimary})
			end)
			connect(button.MouseLeave, function()
				playTween(button, ThemeEngine.TweenQuick, {BackgroundColor3 = ThemeEngine.ElementBg, TextColor3 = ThemeEngine.TextSecondary})
			end)
			button.Parent = actionTray
			return button
		end

		local minimizeButton = makeWindowAction("MinimizeButton", "—", 3)
		local closeButton = makeWindowAction("CloseButton", "×", 4)

		-- ─── Main Pages Viewport Container ───
		local pagesContainer = Instance.new("Frame")
		pagesContainer.Name = "PagesContainer"
		pagesContainer.Size = UDim2.new(1, -190, 1, -64)
		pagesContainer.Position = UDim2.fromOffset(190, 64)
		pagesContainer.BackgroundTransparency = 1
		pagesContainer.ZIndex = 3
		pagesContainer.Parent = mainFrame

		-- Tab Switching State
		local tabButtons = {}
		local tabGradients = {}
		local tabPages = {}
		local tabIconLabels = {}
		local tabTextLabels = {}
		local activeTabIndex = 1

		local allRegisteredModules = {} -- For live search filtering

		local function switchTab(index)
			if tabPages[index] == nil then return end
			activeTabIndex = index

			for i, page in ipairs(tabPages) do
				local isActive = (i == index)
				page.Visible = isActive

				local btn = tabButtons[i]
				local grad = tabGradients[i]
				local icon = tabIconLabels[i]
				local txt = tabTextLabels[i]

				if isActive then
					grad.Enabled = true
					playTween(btn, ThemeEngine.TweenQuick, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0 })
					playTween(txt, ThemeEngine.TweenQuick, { TextColor3 = Color3.fromRGB(255, 255, 255) })
					playTween(icon, ThemeEngine.TweenQuick, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
				else
					grad.Enabled = false
					playTween(btn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.SidebarBg, BackgroundTransparency = 1 })
					playTween(txt, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextSecondary })
					playTween(icon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
				end
			end
		end

		-- Live Search Filtering
		connect(searchInput:GetPropertyChangedSignal("Text"), function()
			local q = string.lower(searchInput.Text)
			for _, mData in ipairs(allRegisteredModules) do
				if q == "" then
					mData.Frame.Visible = true
				else
					local match = string.find(string.lower(mData.Name), q, 1, true) or string.find(string.lower(mData.Desc), q, 1, true)
					mData.Frame.Visible = (match ~= nil)
				end
			end
		end)

		-- Drag Window by Header or Sidebar
		makeDraggable(mainFrame, topBar)
		makeDraggable(mainFrame, brandHeader)

		-- Window Toggle Open/Close Animations
		local function setWindowOpen(open)
			isOpen = open
			if isOpen then
				mainFrame.Visible = true
				shadowFrame.Visible = true
				backdropShade.Visible = true
				playTween(backdropShade, ThemeEngine.TweenSmooth, { BackgroundTransparency = 0.65 })
				playTween(menuBlur, ThemeEngine.TweenSmooth, { Size = 16 })
				mainFrame.Size = winSize - UDim2.fromOffset(20, 20)
				mainFrame.Position = UDim2.new(0.5, -winSize.X.Offset / 2 + 10, 0.5, -winSize.Y.Offset / 2 + 10)
				playTween(mainFrame, ThemeEngine.TweenBounce, {
					Size = winSize,
					Position = UDim2.new(0.5, -winSize.X.Offset / 2, 0.5, -winSize.Y.Offset / 2)
				})
			else
				playTween(backdropShade, ThemeEngine.TweenQuick, { BackgroundTransparency = 1 })
				playTween(menuBlur, ThemeEngine.TweenQuick, { Size = 0 })
				closeActiveOverlay()
				playTween(mainFrame, ThemeEngine.TweenQuick, {
					Size = winSize - UDim2.fromOffset(20, 20),
					Position = UDim2.new(0.5, -winSize.X.Offset / 2 + 10, 0.5, -winSize.Y.Offset / 2 + 10)
				})
				task.delay(0.12, function()
					if not isOpen then
						mainFrame.Visible = false
						shadowFrame.Visible = false
						backdropShade.Visible = false
					end
				end)
			end
		end


		connect(minimizeButton.Activated, function()
			setWindowOpen(false)
		end)
		connect(closeButton.Activated, function()
			setWindowOpen(false)
		end)

		-- Keyboard Toggle Hook
		connect(UserInputService.InputBegan, function(input, processed)
			if input.KeyCode == toggleKey then
				setWindowOpen(not isOpen)
			end
		end)

		-- Dynamic Theme Updater for Window
		table.insert(themeChangeListeners, function(theme)
			lbGrad.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
			for i, grad in ipairs(tabGradients) do
				grad.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
			end
		end)


		function windowHandle:SetProfileCardVisible(visible)
			profileCard.Visible = visible == true
		end

		function windowHandle:SetProfileAvatarVisible(visible)
			profileAvatar.Visible = visible == true
		end

		function windowHandle:SetProfileNameVisible(visible)
			profileName.Visible = visible == true
			profileStatus.Position = if visible then UDim2.fromOffset(52, 29) else UDim2.fromOffset(52, 20)
		end

		function windowHandle:SetOpen(open)
			setWindowOpen(open)
		end

		function windowHandle:ToggleOpen()
			setWindowOpen(not isOpen)
		end

		function windowHandle:SetKeybindListVisible(visible)
			isKeybindListVisible = visible
			keybindsFrame.Visible = visible
		end

		function windowHandle:Notify(notifCfg)
			showNotification(notifCfg)
		end

		function windowHandle:SetTheme(themeName)
			lib:SetTheme(themeName)
		end

		function windowHandle:GetTheme()
			return lib:GetTheme()
		end

		function windowHandle:GetThemes()
			return lib:GetThemes()
		end

		function windowHandle:SetToggleKey(newKey)
			toggleKey = newKey
		end

		function windowHandle:GetToggleKey()
			return toggleKey
		end

		function windowHandle:OnToggleKeyChanged(fn)
			-- Hook
		end

		function windowHandle:SetBackgroundImage(decalId, trans)
			if decalId and decalId ~= "" then
				local assetStr = if string.find(decalId, "rbxassetid://") then decalId else "rbxassetid://" .. tostring(decalId)
				bgImageDecal.Image = assetStr
				bgImageDecal.ImageTransparency = trans or 0.85
				bgImageDecal.Visible = true
			else
				bgImageDecal.Visible = false
			end
		end

		function windowHandle:SetBackgroundTransparency(trans)
			bgImageDecal.ImageTransparency = trans or 0.85
		end

		-- Runtime appearance controls (safe clamping prevents unusable layouts).
		function windowHandle:SetUIScale(value)
			local n = tonumber(value) or 1
			mainScale.Scale = math.clamp(n, 0.65, 1.15)
			return mainScale.Scale
		end

		function windowHandle:GetUIScale()
			return mainScale.Scale
		end

		function windowHandle:SetOpacity(value)
			local n = math.clamp(tonumber(value) or 95, 60, 100)
			mainFrame.BackgroundTransparency = 1 - (n / 100)
			return n
		end

		function windowHandle:SetReducedMotion(enabled)
			self.ReducedMotion = enabled == true
			return self.ReducedMotion
		end

		-- Public tab selector for dashboard shortcuts
		function windowHandle:SelectTab(tabName)
			for index, button in ipairs(tabButtons) do
				local title = button:FindFirstChild("Title")
				if title and title.Text == tostring(tabName) then
					switchTab(index)
					return true
				end
			end
			return false
		end

		-- Category Divider Label in Sidebar
		function windowHandle:Category(catName)
			local catLabel = Instance.new("TextLabel")
			catLabel.Name = "Cat_" .. catName
			catLabel.Size = UDim2.new(1, -12, 0, 18)
			catLabel.BackgroundTransparency = 1
			applyFont(catLabel, "Bold")
			catLabel.TextSize = 9
			catLabel.TextColor3 = ThemeEngine.TextCategory
			catLabel.TextXAlignment = Enum.TextXAlignment.Left
			catLabel.Text = string.upper(catName)
			catLabel.ZIndex = 4

			local catPad = Instance.new("UIPadding")
			catPad.PaddingLeft = UDim.new(0, 8)
			catPad.PaddingTop = UDim.new(0, 4)
			catPad.Parent = catLabel
			catLabel.Parent = tabListFrame
			return catLabel
		end

		-- Tab Constructor
		function windowHandle:Tab(tabCfg)
			tabCfg = tabCfg or {}
			local tabName = tabCfg.Name or "Tab"
			local tabIcon = tabCfg.Icon or Icons[tabName] or Icons.Util

			local tabIndex = #tabButtons + 1
			local tabModuleCount = 0

			-- Sidebar Tab Pill Button
			local tabBtn = Instance.new("TextButton")
			tabBtn.Name = "TabBtn_" .. tabName
			tabBtn.Size = UDim2.new(1, -10, 0, 32)
			tabBtn.BackgroundColor3 = ThemeEngine.SidebarBg
			tabBtn.BackgroundTransparency = 1
			tabBtn.AutoButtonColor = false
			tabBtn.BorderSizePixel = 0
			tabBtn.ZIndex = 5
			tabBtn.Text = ""

			local tbCorner = Instance.new("UICorner")
			tbCorner.CornerRadius = ThemeEngine.RadiusMedium
			tbCorner.Parent = tabBtn

			-- Gradient Pill when Active
			local tabGrad = createGradient(tabBtn, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 0)
			tabGrad.Enabled = false

			local tIcon = createIcon(tabBtn, tabIcon, UDim2.fromOffset(15, 15), UDim2.new(0, 8, 0.5, -7.5), ThemeEngine.TextSecondary)
			tIcon.ZIndex = 6

			local tTitle = Instance.new("TextLabel")
			tTitle.Name = "Title"
			tTitle.Size = UDim2.new(1, -30, 1, 0)
			tTitle.Position = UDim2.fromOffset(28, 0)
			tTitle.BackgroundTransparency = 1
			applyFont(tTitle, "SemiBold")
			tTitle.TextSize = 11
			tTitle.TextColor3 = ThemeEngine.TextSecondary
			tTitle.TextXAlignment = Enum.TextXAlignment.Left
			tTitle.Text = tabName
			tTitle.ZIndex = 6
			tTitle.Parent = tabBtn

			connect(tabBtn.MouseEnter, function()
				if activeTabIndex ~= tabIndex then
					playTween(tabBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.SidebarCardHover, BackgroundTransparency = 0.5 })
					playTween(tTitle, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextPrimary })
					playTween(tIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextPrimary })
				end
			end)
			connect(tabBtn.MouseLeave, function()
				if activeTabIndex ~= tabIndex then
					playTween(tabBtn, ThemeEngine.TweenQuick, { BackgroundTransparency = 1 })
					playTween(tTitle, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextSecondary })
					playTween(tIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
				end
			end)
			connect(tabBtn.Activated, function()
				switchTab(tabIndex)
			end)

			tabBtn.Parent = tabListFrame

			-- ─── Tab Page (Unified Scrolling 2-Column Grid) ───
			local tabPage = Instance.new("ScrollingFrame")
			tabPage.Name = "Page_" .. tabName
			tabPage.Size = UDim2.new(1, 0, 1, 0)
			tabPage.BackgroundTransparency = 1
			tabPage.BorderSizePixel = 0
			tabPage.ScrollBarThickness = 3
			tabPage.ScrollBarImageColor3 = ThemeEngine.Border
			tabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
			tabPage.CanvasSize = UDim2.new()
			tabPage.Visible = false
			tabPage.ZIndex = 2
			tabPage.Parent = pagesContainer

			local pagePadding = Instance.new("UIPadding")
			pagePadding.PaddingTop = UDim.new(0, 8)
			pagePadding.PaddingBottom = UDim.new(0, 14)
			pagePadding.PaddingLeft = UDim.new(0, 14)
			pagePadding.PaddingRight = UDim.new(0, 14)
			pagePadding.Parent = tabPage

			-- Two Columns inside ONE unified scrolling container
			local leftColumn = Instance.new("Frame")
			leftColumn.Name = "LeftColumn"
			leftColumn.Size = UDim2.new(0.5, -6, 0, 0)
			leftColumn.Position = UDim2.new(0, 0, 0, 0)
			leftColumn.BackgroundTransparency = 1
			leftColumn.AutomaticSize = Enum.AutomaticSize.Y
			leftColumn.ZIndex = 2
			leftColumn.Parent = tabPage

			local leftLayout = Instance.new("UIListLayout")
			leftLayout.FillDirection = Enum.FillDirection.Vertical
			leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
			leftLayout.Padding = UDim.new(0, 8)
			leftLayout.Parent = leftColumn

			local rightColumn = Instance.new("Frame")
			rightColumn.Name = "RightColumn"
			rightColumn.Size = UDim2.new(0.5, -6, 0, 0)
			rightColumn.Position = UDim2.new(0.5, 6, 0, 0)
			rightColumn.BackgroundTransparency = 1
			rightColumn.AutomaticSize = Enum.AutomaticSize.Y
			rightColumn.ZIndex = 2
			rightColumn.Parent = tabPage

			local rightLayout = Instance.new("UIListLayout")
			rightLayout.FillDirection = Enum.FillDirection.Vertical
			rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
			rightLayout.Padding = UDim.new(0, 8)
			rightLayout.Parent = rightColumn

			table.insert(tabButtons, tabBtn)
			table.insert(tabGradients, tabGrad)
			table.insert(tabPages, tabPage)
			table.insert(tabIconLabels, tIcon)
			table.insert(tabTextLabels, tTitle)

			if tabIndex == 1 then
				switchTab(1)
			end

			local tabHandle = {}
			tabHandle.Name = tabName

			-- ═════════════════════════════════════════════════
			--  ZeHub Module Card Implementation
			-- ═════════════════════════════════════════════════

			function tabHandle:Module(mCfg)
				mCfg = mCfg or {}
				tabModuleCount = tabModuleCount + 1
				local modName = mCfg.Name or "Module"
				local modDesc = mCfg.Desc or ""
				local isEnabled = if mCfg.Default ~= nil then mCfg.Default else false
				
				-- Auto-balance columns if Side is omitted or "Auto"
				local side = mCfg.Side
				if not side or (side ~= "Left" and side ~= "Right") then
					side = if (tabModuleCount % 2 == 1) then "Left" else "Right"
				end
				local parentCol = if side == "Right" then rightColumn else leftColumn
				local keybind = mCfg.Keybind
				local keybindMode = mCfg.KeybindMode or "Toggle"
				local isExpanded = false

				-- Outer Module Card Frame
				local modCard = Instance.new("Frame")
				modCard.Name = "Mod_" .. modName
				modCard.Size = UDim2.new(1, 0, 0, 44)
				modCard.AutomaticSize = Enum.AutomaticSize.Y
				modCard.BackgroundColor3 = if isEnabled then Color3.fromRGB(255, 255, 255) else ThemeEngine.ModuleCardBg
				modCard.BackgroundTransparency = if isEnabled then 0 else 0.05
				modCard.BorderSizePixel = 0
				modCard.ClipsDescendants = true
				modCard.ZIndex = 3

				local mcCorner = Instance.new("UICorner")
				mcCorner.CornerRadius = ThemeEngine.RadiusMedium
				mcCorner.Parent = modCard

				local mcStroke = createStroke(modCard, if isEnabled then ThemeEngine.GetActiveTheme().Grad1 else ThemeEngine.Border)

				-- Active Horizontal Dual Gradient Fill
				local modGrad = createGradient(modCard, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 0)
				modGrad.Enabled = isEnabled

				-- Header / Clickable Hitbox for the card
				local headerHitbox = Instance.new("TextButton")
				headerHitbox.Name = "HeaderHitbox"
				headerHitbox.Size = UDim2.new(1, 0, 0, 44)
				headerHitbox.BackgroundTransparency = 1
				headerHitbox.AutoButtonColor = false
				headerHitbox.Text = ""
				headerHitbox.ZIndex = 4
				headerHitbox.Parent = modCard

				-- Module Title
				local mTitle = Instance.new("TextLabel")
				mTitle.Name = "Title"
				mTitle.Size = UDim2.new(1, -65, 0, 18)
				mTitle.Position = UDim2.fromOffset(10, 6)
				mTitle.BackgroundTransparency = 1
				applyFont(mTitle, "Bold")
				mTitle.TextSize = 12
				mTitle.TextColor3 = if isEnabled then Color3.fromRGB(255, 255, 255) else ThemeEngine.TextPrimary
				mTitle.TextXAlignment = Enum.TextXAlignment.Left
				mTitle.Text = modName
				mTitle.ZIndex = 5
				mTitle.Parent = modCard

				-- Module Description
				local mDesc = Instance.new("TextLabel")
				mDesc.Name = "Description"
				mDesc.Size = UDim2.new(1, -65, 0, 14)
				mDesc.Position = UDim2.fromOffset(10, 24)
				mDesc.BackgroundTransparency = 1
				applyFont(mDesc, "Regular")
				mDesc.TextSize = 10
				mDesc.TextColor3 = if isEnabled then Color3.fromRGB(240, 245, 255) else ThemeEngine.TextMuted
				mDesc.TextTransparency = if isEnabled then 0.2 else 0
				mDesc.TextXAlignment = Enum.TextXAlignment.Left
				mDesc.TextTruncate = Enum.TextTruncate.AtEnd
				mDesc.Text = modDesc
				mDesc.ZIndex = 5
				mDesc.Parent = modCard

				-- Top Right Buttons: Gear (Settings) & Keybind
				local gearBtn = Instance.new("TextButton")
				gearBtn.Name = "GearBtn"
				gearBtn.Size = UDim2.fromOffset(22, 22)
				gearBtn.Position = UDim2.new(1, -28, 0, 11)
				gearBtn.BackgroundTransparency = 1
				gearBtn.AutoButtonColor = false
				gearBtn.Text = ""
				gearBtn.ZIndex = 6

				local gearIcon = createIcon(gearBtn, Icons.Gear, UDim2.fromOffset(14, 14), UDim2.fromOffset(4, 4), if isEnabled then Color3.fromRGB(255, 255, 255) else ThemeEngine.TextSecondary)
				gearIcon.ZIndex = 7
				gearBtn.Parent = modCard

				local keyTagBtn = Instance.new("TextButton")
				keyTagBtn.Name = "KeyTagBtn"
				keyTagBtn.Size = UDim2.fromOffset(22, 22)
				keyTagBtn.Position = UDim2.new(1, -52, 0, 11)
				keyTagBtn.BackgroundTransparency = 1
				keyTagBtn.AutoButtonColor = false
				keyTagBtn.Text = ""
				keyTagBtn.ZIndex = 6

				local keyIcon = createIcon(keyTagBtn, Icons.Link, UDim2.fromOffset(13, 13), UDim2.fromOffset(4.5, 4.5), if isEnabled then Color3.fromRGB(255, 255, 255) else ThemeEngine.TextSecondary)
				keyIcon.ZIndex = 7
				keyTagBtn.Parent = modCard

				-- Nested Settings Drawer (Expanded under the card)
				local settingsTray = Instance.new("Frame")
				settingsTray.Name = "SettingsTray"
				settingsTray.Size = UDim2.new(1, -12, 0, 0)
				settingsTray.Position = UDim2.fromOffset(6, 44)
				settingsTray.BackgroundColor3 = ThemeEngine.ModuleSettingsBg
				settingsTray.BackgroundTransparency = 0.2
				settingsTray.BorderSizePixel = 0
				settingsTray.AutomaticSize = Enum.AutomaticSize.Y
				settingsTray.Visible = false
				settingsTray.ZIndex = 4

				local stCorner = Instance.new("UICorner")
				stCorner.CornerRadius = ThemeEngine.RadiusSmall
				stCorner.Parent = settingsTray

				local _stStroke = createStroke(settingsTray, ThemeEngine.Border)

				local stLayout = Instance.new("UIListLayout")
				stLayout.FillDirection = Enum.FillDirection.Vertical
				stLayout.SortOrder = Enum.SortOrder.LayoutOrder
				stLayout.Padding = UDim.new(0, 6)
				stLayout.Parent = settingsTray

				local stPad = Instance.new("UIPadding")
				stPad.PaddingTop = UDim.new(0, 8)
				stPad.PaddingBottom = UDim.new(0, 8)
				stPad.PaddingLeft = UDim.new(0, 8)
				stPad.PaddingRight = UDim.new(0, 8)
				stPad.Parent = settingsTray
				settingsTray.Parent = modCard

				local function updateModuleVisual()
					if isEnabled then
						modGrad.Enabled = true
						modGrad.Color = ColorSequence.new(ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2)
						playTween(modCard, ThemeEngine.TweenQuick, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0 })
						playTween(mcStroke, ThemeEngine.TweenQuick, { Color = ThemeEngine.GetActiveTheme().Grad1 })
						playTween(mTitle, ThemeEngine.TweenQuick, { TextColor3 = Color3.fromRGB(255, 255, 255) })
						playTween(mDesc, ThemeEngine.TweenQuick, { TextColor3 = Color3.fromRGB(240, 245, 255), TextTransparency = 0.2 })
						playTween(gearIcon, ThemeEngine.TweenQuick, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
						playTween(keyIcon, ThemeEngine.TweenQuick, { ImageColor3 = Color3.fromRGB(255, 255, 255) })
					else
						modGrad.Enabled = false
						playTween(modCard, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ModuleCardBg, BackgroundTransparency = 0.05 })
						playTween(mcStroke, ThemeEngine.TweenQuick, { Color = ThemeEngine.Border })
						playTween(mTitle, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextPrimary })
						playTween(mDesc, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextMuted, TextTransparency = 0 })
						playTween(gearIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
						playTween(keyIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
					end

					if keybind and registeredKeybinds[modName] then
						registeredKeybinds[modName].Active = isEnabled
						if updateKeybindListUI then updateKeybindListUI() end
					end
				end

				-- Immediately initialize visual state so default-enabled modules render with gradient right away
				updateModuleVisual()

				local function toggleModule()
					isEnabled = not isEnabled
					updateModuleVisual()
					if mCfg.Callback then
						mCfg.Callback(isEnabled)
					end
				end

				local function toggleSettings()
					isExpanded = not isExpanded
					settingsTray.Visible = isExpanded
					playTween(gearIcon, ThemeEngine.TweenQuick, {
						ImageColor3 = if isExpanded then ThemeEngine.GetActiveTheme().Grad1 else (if isEnabled then Color3.fromRGB(255, 255, 255) else ThemeEngine.TextSecondary)
					})
				end

				connect(headerHitbox.Activated, toggleModule)
				connect(headerHitbox.MouseButton2Click, toggleSettings)
				connect(gearBtn.Activated, toggleSettings)

				connect(headerHitbox.MouseEnter, function()
					if not isEnabled then
						playTween(modCard, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ModuleCardHover })
					end
				end)
				connect(headerHitbox.MouseLeave, function()
					if not isEnabled then
						playTween(modCard, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ModuleCardBg })
					end
				end)

				-- Keybind Listener
				if keybind then
					registeredKeybinds[modName] = {
						Name = modName,
						Key = keybind,
						Mode = keybindMode,
						Active = isEnabled,
					}
					if updateKeybindListUI then updateKeybindListUI() end

					connect(UserInputService.InputBegan, function(input, processed)
						if processed then return end
						if keybind ~= Enum.KeyCode.Unknown and (input.KeyCode == keybind or input.UserInputType == keybind) then
							if keybindMode == "Toggle" then
								toggleModule()
							elseif keybindMode == "Hold" then
								isEnabled = true
								updateModuleVisual()
								if mCfg.Callback then mCfg.Callback(isEnabled) end
							end
						end
					end)

					connect(UserInputService.InputEnded, function(input)
						if keybind ~= Enum.KeyCode.Unknown and (input.KeyCode == keybind or input.UserInputType == keybind) and keybindMode == "Hold" then
							isEnabled = false
							updateModuleVisual()
							if mCfg.Callback then mCfg.Callback(isEnabled) end
						end
					end)
				end

				-- Keybind Button Rebind Dialog
				local isRebinding = false
				connect(keyTagBtn.Activated, function()
					if isRebinding then return end
					isRebinding = true
					playTween(keyIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.GetActiveTheme().Grad1 })

					local bindConn = nil
					bindConn = UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode == Enum.KeyCode.Escape then
								-- cancel
							elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
								keybind = Enum.KeyCode.Unknown
								if registeredKeybinds[modName] then
									registeredKeybinds[modName].Key = keybind
									if updateKeybindListUI then updateKeybindListUI() end
								end
							else
								keybind = input.KeyCode
								if registeredKeybinds[modName] then
									registeredKeybinds[modName].Key = keybind
									if updateKeybindListUI then updateKeybindListUI() end
								end
								showNotification({
									Title = modName,
									Content = "Bound to [" .. getKeyName(keybind) .. "]",
									Duration = 2,
									Type = "Success",
								})
							end
							if bindConn then bindConn:Disconnect(); bindConn = nil end
						end
						isRebinding = false
						playTween(keyIcon, ThemeEngine.TweenQuick, { ImageColor3 = ThemeEngine.TextSecondary })
					end)
				end)

				table.insert(themeChangeListeners, function(theme)
					if isEnabled then
						modGrad.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
						mcStroke.Color = theme.Grad1
					end
				end)

				table.insert(allRegisteredModules, {
					Name = modName,
					Desc = modDesc,
					Frame = modCard,
				})

				modCard.Parent = parentCol

				-- ─────────────────────────────────────────────
				--  Module Nested Controls (Inside Tray)
				-- ─────────────────────────────────────────────

				local modHandle = {}
				modHandle.Frame = modCard

				function modHandle:SetValue(val)
					isEnabled = val
					updateModuleVisual()
				end

				function modHandle:GetValue()
					return isEnabled
				end

				function modHandle:SetVisible(vis)
					modCard.Visible = vis
				end

				-- 1. Nested Slider
				function modHandle:Slider(sCfg)
					sCfg = sCfg or {}
					local sText = sCfg.Text or "Value"
					local minVal = sCfg.Min or 0
					local maxVal = sCfg.Max or 100
					local step = sCfg.Step or 1
					local suffix = sCfg.Suffix or ""
					local val = snapValue(sCfg.Default or minVal, minVal, maxVal, step)

					local sRow = Instance.new("Frame")
					sRow.Name = "Slider_" .. sText
					sRow.Size = UDim2.new(1, 0, 0, 36)
					sRow.BackgroundTransparency = 1
					sRow.ZIndex = 5

					local sTitle = Instance.new("TextLabel")
					sTitle.Name = "Label"
					sTitle.Size = UDim2.new(1, -60, 0, 16)
					sTitle.BackgroundTransparency = 1
					applyFont(sTitle, "Medium")
					sTitle.TextSize = 11
					sTitle.TextColor3 = ThemeEngine.TextSecondary
					sTitle.TextXAlignment = Enum.TextXAlignment.Left
					sTitle.Text = sText
					sTitle.ZIndex = 6
					sTitle.Parent = sRow

					local sValLabel = Instance.new("TextLabel")
					sValLabel.Name = "ValLabel"
					sValLabel.Size = UDim2.new(0, 60, 0, 16)
					sValLabel.Position = UDim2.new(1, -60, 0, 0)
					sValLabel.BackgroundTransparency = 1
					applyFont(sValLabel, "SemiBold")
					sValLabel.TextSize = 11
					sValLabel.TextColor3 = ThemeEngine.GetActiveTheme().Grad1
					sValLabel.TextXAlignment = Enum.TextXAlignment.Right
					sValLabel.Text = formatNumber(val, step) .. suffix
					sValLabel.ZIndex = 6
					sValLabel.Parent = sRow

					local sTrack = Instance.new("Frame")
					sTrack.Name = "Track"
					sTrack.Size = UDim2.new(1, 0, 0, 6)
					sTrack.Position = UDim2.new(0, 0, 0, 22)
					sTrack.BackgroundColor3 = ThemeEngine.ElementBg
					sTrack.BorderSizePixel = 0
					sTrack.ZIndex = 6

					local trCorner = Instance.new("UICorner")
					trCorner.CornerRadius = ThemeEngine.RadiusPill
					trCorner.Parent = sTrack

					local sFill = Instance.new("Frame")
					sFill.Name = "Fill"
					local pct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
					sFill.Size = UDim2.new(pct, 0, 1, 0)
					sFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					sFill.BorderSizePixel = 0
					sFill.ZIndex = 7

					local sfCorner = Instance.new("UICorner")
					sfCorner.CornerRadius = ThemeEngine.RadiusPill
					sfCorner.Parent = sFill

					local sfGrad = createGradient(sFill, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 0)
					sFill.Parent = sTrack

					local sKnob = Instance.new("Frame")
					sKnob.Name = "Knob"
					sKnob.Size = UDim2.fromOffset(12, 12)
					sKnob.Position = UDim2.new(1, -6, 0.5, -6)
					sKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					sKnob.BorderSizePixel = 0
					sKnob.ZIndex = 8

					local kCorner = Instance.new("UICorner")
					kCorner.CornerRadius = ThemeEngine.RadiusPill
					kCorner.Parent = sKnob
					sKnob.Parent = sFill
					sTrack.Parent = sRow

					local function updateSlider(xPos)
						local absX = sTrack.AbsolutePosition.X
						local absW = sTrack.AbsoluteSize.X
						local p = math.clamp((xPos - absX) / absW, 0, 1)
						val = snapValue(minVal + (maxVal - minVal) * p, minVal, maxVal, step)
						local snappedPct = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
						sFill.Size = UDim2.new(snappedPct, 0, 1, 0)
						sValLabel.Text = formatNumber(val, step) .. suffix
						if sCfg.Callback then sCfg.Callback(val) end
					end

					local isDragging = false
					connect(sTrack.InputBegan, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							isDragging = true
							updateSlider(input.Position.X)
						end
					end)

					connect(UserInputService.InputChanged, function(input)
						if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							updateSlider(input.Position.X)
						end
					end)

					connect(UserInputService.InputEnded, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							isDragging = false
						end
					end)

					table.insert(themeChangeListeners, function(theme)
						sfGrad.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
						sValLabel.TextColor3 = theme.Grad1
					end)

					sRow.Parent = settingsTray
					return sRow
				end

				-- 2. Nested Dropdown
				function modHandle:Dropdown(dCfg)
					dCfg = dCfg or {}
					local dText = dCfg.Text or "Dropdown"
					local dItems = dCfg.Items or dCfg.Options or {}
					local selected = dCfg.Default or dItems[1] or ""
					local isOpenDD = false

					local dRow = Instance.new("Frame")
					dRow.Name = "Dropdown_" .. dText
					dRow.Size = UDim2.new(1, 0, 0, 48)
					dRow.BackgroundTransparency = 1
					dRow.AutomaticSize = Enum.AutomaticSize.Y
					dRow.ZIndex = 5

					local dLabel = Instance.new("TextLabel")
					dLabel.Name = "Label"
					dLabel.Size = UDim2.new(1, 0, 0, 16)
					dLabel.BackgroundTransparency = 1
					applyFont(dLabel, "Medium")
					dLabel.TextSize = 11
					dLabel.TextColor3 = ThemeEngine.TextSecondary
					dLabel.TextXAlignment = Enum.TextXAlignment.Left
					dLabel.Text = dText
					dLabel.ZIndex = 6
					dLabel.Parent = dRow

					local dBtn = Instance.new("TextButton")
					dBtn.Name = "SelectBtn"
					dBtn.Size = UDim2.new(1, 0, 0, 26)
					dBtn.Position = UDim2.new(0, 0, 0, 18)
					dBtn.BackgroundColor3 = ThemeEngine.ElementBg
					dBtn.BackgroundTransparency = 0.4
					dBtn.AutoButtonColor = false
					dBtn.BorderSizePixel = 0
					dBtn.Text = ""
					dBtn.ZIndex = 6

					local dbCorner = Instance.new("UICorner")
					dbCorner.CornerRadius = ThemeEngine.RadiusSmall
					dbCorner.Parent = dBtn
					local _dbStroke = createStroke(dBtn, ThemeEngine.Border)

					local dValText = Instance.new("TextLabel")
					dValText.Name = "ValText"
					dValText.Size = UDim2.new(1, -26, 1, 0)
					dValText.Position = UDim2.fromOffset(8, 0)
					dValText.BackgroundTransparency = 1
					applyFont(dValText, "SemiBold")
					dValText.TextSize = 10
					dValText.TextColor3 = ThemeEngine.TextPrimary
					dValText.TextXAlignment = Enum.TextXAlignment.Left
					dValText.TextTruncate = Enum.TextTruncate.AtEnd
					dValText.Text = selected
					dValText.ZIndex = 7
					dValText.Parent = dBtn

					local dChevron = createIcon(dBtn, Icons.ChevronDown, UDim2.fromOffset(11, 11), UDim2.new(1, -19, 0.5, -5.5), ThemeEngine.TextSecondary)
					dChevron.ZIndex = 7
					dBtn.Parent = dRow

					-- Options Accordion Menu
					local optContainer = Instance.new("Frame")
					optContainer.Name = "Options"
					optContainer.Size = UDim2.new(1, 0, 0, 0)
					optContainer.Position = UDim2.new(0, 0, 0, 48)
					optContainer.BackgroundColor3 = ThemeEngine.ElementBg
					optContainer.BackgroundTransparency = 0.2
					optContainer.BorderSizePixel = 0
					optContainer.AutomaticSize = Enum.AutomaticSize.Y
					optContainer.Visible = false
					optContainer.ZIndex = 8

					local ocCorner = Instance.new("UICorner")
					ocCorner.CornerRadius = ThemeEngine.RadiusSmall
					ocCorner.Parent = optContainer
					local _ocStroke = createStroke(optContainer, ThemeEngine.Border)

					local ocLayout = Instance.new("UIListLayout")
					ocLayout.FillDirection = Enum.FillDirection.Vertical
					ocLayout.SortOrder = Enum.SortOrder.LayoutOrder
					ocLayout.Padding = UDim.new(0, 2)
					ocLayout.Parent = optContainer

					local ocPad = Instance.new("UIPadding")
					ocPad.PaddingTop = UDim.new(0, 4)
					ocPad.PaddingBottom = UDim.new(0, 4)
					ocPad.PaddingLeft = UDim.new(0, 4)
					ocPad.PaddingRight = UDim.new(0, 4)
					ocPad.Parent = optContainer

					local function renderOptions()
						for _, child in ipairs(optContainer:GetChildren()) do
							if child:IsA("TextButton") then child:Destroy() end
						end

						for _, item in ipairs(dItems) do
							local isSel = (item == selected)
							local oBtn = Instance.new("TextButton")
							oBtn.Name = "Opt_" .. tostring(item)
							oBtn.Size = UDim2.new(1, 0, 0, 22)
							oBtn.BackgroundColor3 = if isSel then ThemeEngine.ElementHover else ThemeEngine.ElementBg
							oBtn.BackgroundTransparency = if isSel then 0.2 else 1
							oBtn.AutoButtonColor = false
							oBtn.BorderSizePixel = 0
							oBtn.ZIndex = 9
							oBtn.Text = ""

							local obCorner = Instance.new("UICorner")
							obCorner.CornerRadius = ThemeEngine.RadiusSmall
							obCorner.Parent = oBtn

							local oText = Instance.new("TextLabel")
							oText.Name = "Text"
							oText.Size = UDim2.new(1, -20, 1, 0)
							oText.Position = UDim2.fromOffset(6, 0)
							oText.BackgroundTransparency = 1
							applyFont(oText, if isSel then "Bold" else "Medium")
							oText.TextSize = 10
							oText.TextColor3 = if isSel then ThemeEngine.GetActiveTheme().Grad1 else ThemeEngine.TextSecondary
							oText.TextXAlignment = Enum.TextXAlignment.Left
							oText.Text = tostring(item)
							oText.ZIndex = 10
							oText.Parent = oBtn

							connect(oBtn.MouseEnter, function()
								playTween(oBtn, ThemeEngine.TweenQuick, { BackgroundTransparency = 0.3, BackgroundColor3 = ThemeEngine.ElementHover })
							end)
							connect(oBtn.MouseLeave, function()
								playTween(oBtn, ThemeEngine.TweenQuick, { BackgroundTransparency = if item == selected then 0.2 else 1 })
							end)
							connect(oBtn.Activated, function()
								selected = item
								dValText.Text = selected
								isOpenDD = false
								optContainer.Visible = false
								renderOptions()
								if dCfg.Callback then dCfg.Callback(selected) end
							end)

							oBtn.Parent = optContainer
						end
					end

					renderOptions()
					optContainer.Parent = dRow

					connect(dBtn.Activated, function()
						isOpenDD = not isOpenDD
						optContainer.Visible = isOpenDD
						playTween(dChevron, ThemeEngine.TweenQuick, {
							ImageColor3 = if isOpenDD then ThemeEngine.GetActiveTheme().Grad1 else ThemeEngine.TextSecondary
						})
					end)

					dRow.Parent = settingsTray
					return dRow
				end

				-- 3. Nested Toggle Switch
				function modHandle:Toggle(tCfg)
					tCfg = tCfg or {}
					local tText = tCfg.Text or "Sub Toggle"
					local isTOn = if tCfg.Default ~= nil then tCfg.Default else false

					local tRow = Instance.new("Frame")
					tRow.Name = "Toggle_" .. tText
					tRow.Size = UDim2.new(1, 0, 0, 26)
					tRow.BackgroundTransparency = 1
					tRow.ZIndex = 5

					local tLabel = Instance.new("TextLabel")
					tLabel.Name = "Label"
					tLabel.Size = UDim2.new(1, -38, 1, 0)
					tLabel.BackgroundTransparency = 1
					applyFont(tLabel, "Medium")
					tLabel.TextSize = 11
					tLabel.TextColor3 = ThemeEngine.TextSecondary
					tLabel.TextXAlignment = Enum.TextXAlignment.Left
					tLabel.Text = tText
					tLabel.ZIndex = 6
					tLabel.Parent = tRow

					-- iOS Style Switch Pill
					local swFrame = Instance.new("TextButton")
					swFrame.Name = "Switch"
					swFrame.Size = UDim2.fromOffset(28, 15)
					swFrame.Position = UDim2.new(1, -28, 0.5, -7.5)
					swFrame.BackgroundColor3 = if isTOn then Color3.fromRGB(255, 255, 255) else ThemeEngine.ElementBg
					swFrame.AutoButtonColor = false
					swFrame.BorderSizePixel = 0
					swFrame.Text = ""
					swFrame.ZIndex = 6

					local swCorner = Instance.new("UICorner")
					swCorner.CornerRadius = ThemeEngine.RadiusPill
					swCorner.Parent = swFrame

					local swGrad = createGradient(swFrame, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 0)
					swGrad.Enabled = isTOn

					local swKnob = Instance.new("Frame")
					swKnob.Name = "Knob"
					swKnob.Size = UDim2.fromOffset(11, 11)
					swKnob.Position = if isTOn then UDim2.new(1, -13, 0.5, -5.5) else UDim2.new(0, 2, 0.5, -5.5)
					swKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					swKnob.BorderSizePixel = 0
					swKnob.ZIndex = 7

					local skCorner = Instance.new("UICorner")
					skCorner.CornerRadius = ThemeEngine.RadiusPill
					skCorner.Parent = swKnob
					swKnob.Parent = swFrame
					swFrame.Parent = tRow

					local function updateSwitchVisual()
						if isTOn then
							swGrad.Enabled = true
							playTween(swKnob, ThemeEngine.TweenQuick, { Position = UDim2.new(1, -13, 0.5, -5.5) })
						else
							swGrad.Enabled = false
							playTween(swKnob, ThemeEngine.TweenQuick, { Position = UDim2.new(0, 2, 0.5, -5.5) })
							playTween(swFrame, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementBg })
						end
					end

					connect(swFrame.Activated, function()
						isTOn = not isTOn
						updateSwitchVisual()
						if tCfg.Callback then tCfg.Callback(isTOn) end
					end)

					table.insert(themeChangeListeners, function(theme)
						swGrad.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
					end)

					tRow.Parent = settingsTray
					return tRow
				end

				-- 4. Nested Colorpicker
				function modHandle:Colorpicker(cpCfg)
					cpCfg = cpCfg or {}
					local cpText = cpCfg.Text or "Color"
					local currColor = cpCfg.Default or Color3.fromRGB(0, 210, 255)

					local cpRow = Instance.new("Frame")
					cpRow.Name = "Colorpicker_" .. cpText
					cpRow.Size = UDim2.new(1, 0, 0, 26)
					cpRow.BackgroundTransparency = 1
					cpRow.ZIndex = 5

					local cpLabel = Instance.new("TextLabel")
					cpLabel.Name = "Label"
					cpLabel.Size = UDim2.new(1, -38, 1, 0)
					cpLabel.BackgroundTransparency = 1
					applyFont(cpLabel, "Medium")
					cpLabel.TextSize = 11
					cpLabel.TextColor3 = ThemeEngine.TextSecondary
					cpLabel.TextXAlignment = Enum.TextXAlignment.Left
					cpLabel.Text = cpText
					cpLabel.ZIndex = 6
					cpLabel.Parent = cpRow

					local cpSwatch = Instance.new("TextButton")
					cpSwatch.Name = "Swatch"
					cpSwatch.Size = UDim2.fromOffset(24, 15)
					cpSwatch.Position = UDim2.new(1, -24, 0.5, -7.5)
					cpSwatch.BackgroundColor3 = currColor
					cpSwatch.AutoButtonColor = false
					cpSwatch.BorderSizePixel = 0
					cpSwatch.Text = ""
					cpSwatch.ZIndex = 6

					local swCorner = Instance.new("UICorner")
					swCorner.CornerRadius = ThemeEngine.RadiusSmall
					swCorner.Parent = cpSwatch
					local _swStroke = createStroke(cpSwatch, ThemeEngine.BorderLight)
					cpSwatch.Parent = cpRow

					-- Palette Preset Swatches Popup
					local cpPalette = Instance.new("Frame")
					cpPalette.Name = "Palette"
					cpPalette.Size = UDim2.new(1, 0, 0, 30)
					cpPalette.BackgroundColor3 = ThemeEngine.ElementBg
					cpPalette.BackgroundTransparency = 0.2
					cpPalette.BorderSizePixel = 0
					cpPalette.Visible = false
					cpPalette.ZIndex = 8

					local cppCorner = Instance.new("UICorner")
					cppCorner.CornerRadius = ThemeEngine.RadiusSmall
					cppCorner.Parent = cpPalette

					local cppLayout = Instance.new("UIListLayout")
					cppLayout.FillDirection = Enum.FillDirection.Horizontal
					cppLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
					cppLayout.VerticalAlignment = Enum.VerticalAlignment.Center
					cppLayout.Padding = UDim.new(0, 6)
					cppLayout.Parent = cpPalette

					local colorPresets = {
						Color3.fromRGB(255, 56, 96),
						Color3.fromRGB(0, 210, 255),
						Color3.fromRGB(142, 45, 226),
						Color3.fromRGB(0, 242, 96),
						Color3.fromRGB(255, 179, 0),
						Color3.fromRGB(255, 255, 255),
						Color3.fromRGB(255, 75, 43),
					}

					for _, pCol in ipairs(colorPresets) do
						local pBtn = Instance.new("TextButton")
						pBtn.Size = UDim2.fromOffset(16, 16)
						pBtn.BackgroundColor3 = pCol
						pBtn.BorderSizePixel = 0
						pBtn.AutoButtonColor = false
						pBtn.Text = ""
						pBtn.ZIndex = 9

						local pbCorner = Instance.new("UICorner")
						pbCorner.CornerRadius = ThemeEngine.RadiusPill
						pbCorner.Parent = pBtn

						connect(pBtn.Activated, function()
							currColor = pCol
							cpSwatch.BackgroundColor3 = currColor
							cpPalette.Visible = false
							if cpCfg.Callback then cpCfg.Callback(currColor) end
						end)
						pBtn.Parent = cpPalette
					end

					cpPalette.Parent = cpRow

					connect(cpSwatch.Activated, function()
						cpPalette.Visible = not cpPalette.Visible
					end)

					cpRow.Parent = settingsTray
					return cpRow
				end

				-- 5. Nested Button
				function modHandle:Button(bCfg)
					bCfg = bCfg or {}
					local bText = bCfg.Text or "Button"

					local bBtn = Instance.new("TextButton")
					bBtn.Name = "Btn_" .. bText
					bBtn.Size = UDim2.new(1, 0, 0, 24)
					bBtn.BackgroundColor3 = ThemeEngine.ElementBg
					bBtn.BackgroundTransparency = 0.4
					bBtn.AutoButtonColor = false
					bBtn.BorderSizePixel = 0
					applyFont(bBtn, "SemiBold")
					bBtn.TextSize = 10
					bBtn.TextColor3 = ThemeEngine.TextPrimary
					bBtn.Text = bText
					bBtn.ZIndex = 5

					local bbCorner = Instance.new("UICorner")
					bbCorner.CornerRadius = ThemeEngine.RadiusSmall
					bbCorner.Parent = bBtn
					local _bbStroke = createStroke(bBtn, ThemeEngine.Border)

					connect(bBtn.MouseEnter, function()
						playTween(bBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementHover, BackgroundTransparency = 0.2 })
					end)
					connect(bBtn.MouseLeave, function()
						playTween(bBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementBg, BackgroundTransparency = 0.4 })
					end)
					connect(bBtn.Activated, function()
						playTween(bBtn, TweenInfo.new(0.06), { BackgroundColor3 = ThemeEngine.GetActiveTheme().Grad1 })
						task.delay(0.08, function()
							playTween(bBtn, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementBg })
						end)
						if bCfg.Callback then bCfg.Callback() end
					end)

					bBtn.Parent = settingsTray
					return bBtn
				end

				-- 6. Nested Keybind
				function modHandle:Keybind(kCfg)
					kCfg = kCfg or {}
					local kText = kCfg.Text or "Keybind"
					local kKey = kCfg.Default or Enum.KeyCode.Unknown

					local kRow = Instance.new("Frame")
					kRow.Name = "Keybind_" .. kText
					kRow.Size = UDim2.new(1, 0, 0, 26)
					kRow.BackgroundTransparency = 1
					kRow.ZIndex = 5

					local kLabel = Instance.new("TextLabel")
					kLabel.Name = "Label"
					kLabel.Size = UDim2.new(1, -55, 1, 0)
					kLabel.BackgroundTransparency = 1
					applyFont(kLabel, "Medium")
					kLabel.TextSize = 11
					kLabel.TextColor3 = ThemeEngine.TextSecondary
					kLabel.TextXAlignment = Enum.TextXAlignment.Left
					kLabel.Text = kText
					kLabel.ZIndex = 6
					kLabel.Parent = kRow

					local kPill = Instance.new("TextButton")
					kPill.Name = "Pill"
					kPill.Size = UDim2.fromOffset(45, 18)
					kPill.Position = UDim2.new(1, -45, 0.5, -9)
					kPill.BackgroundColor3 = ThemeEngine.ElementBg
					kPill.BorderSizePixel = 0
					applyFont(kPill, "Bold")
					kPill.TextSize = 9
					kPill.TextColor3 = ThemeEngine.TextPrimary
					kPill.Text = "[" .. getKeyName(kKey) .. "]"
					kPill.ZIndex = 6

					local kpCorner = Instance.new("UICorner")
					kpCorner.CornerRadius = ThemeEngine.RadiusSmall
					kpCorner.Parent = kPill
					local _kpStroke = createStroke(kPill, ThemeEngine.Border)

					local isListening = false
					connect(kPill.Activated, function()
						if isListening then return end
						isListening = true
						kPill.Text = "[...]"
						playTween(kPill, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.GetActiveTheme().Grad1 })

						local bindConn = nil
						bindConn = UserInputService.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.Keyboard then
								if input.KeyCode == Enum.KeyCode.Escape then
									-- cancel
								elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
									kKey = Enum.KeyCode.Unknown
								else
									kKey = input.KeyCode
								end
								kPill.Text = "[" .. getKeyName(kKey) .. "]"
								if bindConn then bindConn:Disconnect(); bindConn = nil end
								if kCfg.Callback then kCfg.Callback(kKey) end
							end
							isListening = false
							playTween(kPill, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ElementBg })
						end)
					end)

					kPill.Parent = kRow
					kRow.Parent = settingsTray
					return kRow
				end

				-- 7. Nested Input Text Box
				function modHandle:Input(iCfg)
					iCfg = iCfg or {}
					local iText = iCfg.Text or "Input"
					local iPlaceholder = iCfg.Placeholder or "Enter value..."
					local iDef = iCfg.Default or ""

					local iRow = Instance.new("Frame")
					iRow.Name = "Input_" .. iText
					iRow.Size = UDim2.new(1, 0, 0, 48)
					iRow.BackgroundTransparency = 1
					iRow.ZIndex = 5

					local iLabel = Instance.new("TextLabel")
					iLabel.Name = "Label"
					iLabel.Size = UDim2.new(1, 0, 0, 16)
					iLabel.BackgroundTransparency = 1
					applyFont(iLabel, "Medium")
					iLabel.TextSize = 11
					iLabel.TextColor3 = ThemeEngine.TextSecondary
					iLabel.TextXAlignment = Enum.TextXAlignment.Left
					iLabel.Text = iText
					iLabel.ZIndex = 6
					iLabel.Parent = iRow

					local iBox = Instance.new("TextBox")
					iBox.Name = "TextBox"
					iBox.Size = UDim2.new(1, 0, 0, 24)
					iBox.Position = UDim2.new(0, 0, 0, 18)
					iBox.BackgroundColor3 = ThemeEngine.ElementBg
					iBox.BackgroundTransparency = 0.4
					iBox.BorderSizePixel = 0
					applyFont(iBox, "Medium")
					iBox.TextSize = 10
					iBox.TextColor3 = ThemeEngine.TextPrimary
					iBox.PlaceholderText = iPlaceholder
					iBox.PlaceholderColor3 = ThemeEngine.TextMuted
					iBox.Text = iDef
					iBox.ClearTextOnFocus = false
					iBox.ZIndex = 6

					local ibCorner = Instance.new("UICorner")
					ibCorner.CornerRadius = ThemeEngine.RadiusSmall
					ibCorner.Parent = iBox
					local ibStroke = createStroke(iBox, ThemeEngine.Border)

					local ibPad = Instance.new("UIPadding")
					ibPad.PaddingLeft = UDim.new(0, 8)
					ibPad.PaddingRight = UDim.new(0, 8)
					ibPad.Parent = iBox

					connect(iBox.Focused, function()
						playTween(ibStroke, ThemeEngine.TweenQuick, { Color = ThemeEngine.GetActiveTheme().Grad1 })
					end)
					connect(iBox.FocusLost, function(enterPressed)
						playTween(ibStroke, ThemeEngine.TweenQuick, { Color = ThemeEngine.Border })
						if iCfg.Callback then iCfg.Callback(iBox.Text) end
					end)

					iBox.Parent = iRow
					iRow.Parent = settingsTray
					return iRow
				end

				return modHandle
			end

			-- ZeHub Home Dashboard Components
			function tabHandle:DashboardHero(cfg)
				cfg = cfg or {}
				local hero = Instance.new("Frame")
				hero.Name = "DashboardHero"
				hero.Size = UDim2.new(1, -28, 0, cfg.Height or 112)
				hero.Position = UDim2.fromOffset(14, 8)
				hero.BackgroundColor3 = ThemeEngine.ModuleCardBg
				hero.BackgroundTransparency = 0
				hero.BorderSizePixel = 0
				hero.ClipsDescendants = true
				hero.ZIndex = 4

				local corner = Instance.new("UICorner")
				corner.CornerRadius = ThemeEngine.RadiusLarge
				corner.Parent = hero
				local stroke = createStroke(hero, ThemeEngine.Border)

				local glow = Instance.new("Frame")
				glow.Size = UDim2.fromScale(0.72, 1.8)
				glow.Position = UDim2.new(0.48, 0, -0.38, 0)
				glow.BackgroundColor3 = ThemeEngine.GetActiveTheme().Grad1
				glow.BackgroundTransparency = 0.86
				glow.BorderSizePixel = 0
				glow.Rotation = -12
				glow.ZIndex = 4
				glow.Parent = hero

				local gradient = createGradient(glow, ThemeEngine.GetActiveTheme().Grad1, ThemeEngine.GetActiveTheme().Grad2, 0)
				gradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.15),
					NumberSequenceKeypoint.new(1, 1),
				})

				local icon = createIcon(hero, Icons.Logo, UDim2.fromOffset(54, 54), UDim2.fromOffset(24, 19), ThemeEngine.GetActiveTheme().Grad1)
				icon.ZIndex = 7

				local title = Instance.new("TextLabel")
				title.Size = UDim2.new(1, -190, 0, 30)
				title.Position = UDim2.fromOffset(92, 22)
				title.BackgroundTransparency = 1
				applyFont(title, "Bold")
				title.TextSize = 20
				title.TextColor3 = ThemeEngine.TextPrimary
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.Text = cfg.Title or "Welcome to ZeHub"
				title.ZIndex = 7
				title.Parent = hero

				local desc = Instance.new("TextLabel")
				desc.Size = UDim2.new(1, -210, 0, 34)
				desc.Position = UDim2.fromOffset(92, 55)
				desc.TextWrapped = true
				desc.TextYAlignment = Enum.TextYAlignment.Top
				desc.BackgroundTransparency = 1
				applyFont(desc, "Medium")
				desc.TextSize = 10
				desc.TextColor3 = ThemeEngine.TextSecondary
				desc.TextTruncate = Enum.TextTruncate.AtEnd
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.Text = cfg.Desc or "Your modular Roblox client — everything organised from one place."
				desc.ZIndex = 7
				desc.Parent = hero

				local badge = Instance.new("TextLabel")
				badge.Size = UDim2.fromOffset(112, 28)
				badge.Position = UDim2.new(1, -128, 0, 12)
				badge.BackgroundColor3 = ThemeEngine.ElementBg
				badge.BackgroundTransparency = 0.15
				badge.BorderSizePixel = 0
				applyFont(badge, "SemiBold")
				badge.TextSize = 10
				badge.TextColor3 = ThemeEngine.TextPrimary
				badge.Text = cfg.Badge or "7 Themes"
				badge.ZIndex = 7
				badge.Parent = hero
				local bc = Instance.new("UICorner")
				bc.CornerRadius = ThemeEngine.RadiusMedium
				bc.Parent = badge
				createStroke(badge, ThemeEngine.Border)

				table.insert(themeChangeListeners, function(theme)
					icon.ImageColor3 = theme.Grad1
					glow.BackgroundColor3 = theme.Grad1
					gradient.Color = ColorSequence.new(theme.Grad1, theme.Grad2)
					stroke.Color = theme.Border
				end)

				return hero
			end

			function tabHandle:DashboardLayout(topOffset)
				local offset = tonumber(topOffset) or 0
				leftColumn.Position = UDim2.new(0, 0, 0, offset)
				rightColumn.Position = UDim2.new(0.5, 6, 0, offset)
				return tabHandle
			end

			function tabHandle:DashboardCard(cfg)
				cfg = cfg or {}
				tabModuleCount = tabModuleCount + 1
				local side = if cfg.Side == "Right" then "Right" else "Left"
				local parentCol = if side == "Right" then rightColumn else leftColumn

				local card = Instance.new("Frame")
				card.Name = "DashboardCard_" .. tostring(cfg.Name or "Card")
				card.Size = UDim2.new(1, 0, 0, cfg.Height or 104)
				card.BackgroundColor3 = ThemeEngine.ModuleCardBg
				card.BackgroundTransparency = 0.02
				card.BorderSizePixel = 0
				card.ClipsDescendants = true
				card.ZIndex = 4

				local cc = Instance.new("UICorner")
				cc.CornerRadius = ThemeEngine.RadiusLarge
				cc.Parent = card
				local cs = createStroke(card, ThemeEngine.Border)

				local hit = Instance.new("TextButton")
				hit.Size = UDim2.fromScale(1, 1)
				hit.BackgroundTransparency = 1
				hit.BorderSizePixel = 0
				hit.AutoButtonColor = false
				hit.Text = ""
				hit.ZIndex = 5
				hit.Parent = card

				local iconBox = Instance.new("Frame")
				iconBox.Size = UDim2.fromOffset(46, 46)
				iconBox.Position = UDim2.fromOffset(14, 16)
				iconBox.BackgroundColor3 = ThemeEngine.ElementBg
				iconBox.BackgroundTransparency = 0.05
				iconBox.BorderSizePixel = 0
				iconBox.ZIndex = 6
				iconBox.Parent = card
				local ibc = Instance.new("UICorner")
				ibc.CornerRadius = ThemeEngine.RadiusMedium
				ibc.Parent = iconBox
				local ibs = createStroke(iconBox, ThemeEngine.GetActiveTheme().Grad1)

				local icon = createIcon(iconBox, cfg.Icon or Icons.Util, UDim2.fromOffset(24, 24), UDim2.new(0.5, -12, 0.5, -12), ThemeEngine.GetActiveTheme().Grad1)
				icon.ZIndex = 7

				local title = Instance.new("TextLabel")
				title.Size = UDim2.new(1, -118, 0, 24)
				title.Position = UDim2.fromOffset(72, 16)
				title.BackgroundTransparency = 1
				applyFont(title, "SemiBold")
				title.TextSize = 13
				title.TextColor3 = ThemeEngine.TextPrimary
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.Text = cfg.Name or "Card"
				title.ZIndex = 7
				title.Parent = card

				local desc = Instance.new("TextLabel")
				desc.Size = UDim2.new(1, -116, 0, 38)
				desc.Position = UDim2.fromOffset(72, 42)
				desc.BackgroundTransparency = 1
				desc.Font = Enum.Font.Gotham
				desc.TextSize = 10
				desc.TextColor3 = ThemeEngine.TextSecondary
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.TextYAlignment = Enum.TextYAlignment.Top
				desc.TextWrapped = true
				desc.Text = cfg.Desc or ""
				desc.ZIndex = 7
				desc.Parent = card

				local arrow = Instance.new("TextLabel")
				arrow.Size = UDim2.fromOffset(22, 30)
				arrow.Position = UDim2.new(1, -30, 0.5, -15)
				arrow.BackgroundTransparency = 1
				applyFont(arrow, "Bold")
				arrow.TextSize = 20
				arrow.TextColor3 = ThemeEngine.TextSecondary
				arrow.Text = ">"
				arrow.ZIndex = 7
				arrow.Parent = card

				connect(hit.MouseEnter, function()
					playTween(card, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ModuleCardHover })
					playTween(cs, ThemeEngine.TweenQuick, { Color = ThemeEngine.GetActiveTheme().Grad1 })
					playTween(ibs, ThemeEngine.TweenQuick, { Color = ThemeEngine.GetActiveTheme().Grad2 })
					playTween(arrow, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.GetActiveTheme().Grad1 })
				end)
				connect(hit.MouseLeave, function()
					playTween(card, ThemeEngine.TweenQuick, { BackgroundColor3 = ThemeEngine.ModuleCardBg })
					playTween(cs, ThemeEngine.TweenQuick, { Color = ThemeEngine.Border })
					playTween(ibs, ThemeEngine.TweenQuick, { Color = ThemeEngine.GetActiveTheme().Grad1 })
					playTween(arrow, ThemeEngine.TweenQuick, { TextColor3 = ThemeEngine.TextSecondary })
				end)
				connect(hit.Activated, function()
					if cfg.Callback then cfg.Callback() end
				end)

				table.insert(themeChangeListeners, function(theme)
					icon.ImageColor3 = theme.Grad1
					ibs.Color = theme.Grad1
				end)

				card.Parent = parentCol
				return card
			end

			-- Backward Compatibility Section Wrapper
			function tabHandle:Section(secCfg)
				secCfg = secCfg or {}
				local secName = secCfg.Name or "Section"
				local secSide = secCfg.Side or "Left"

				local parentCol = if secSide == "Right" then rightColumn else leftColumn

				local secHandle = {}

				function secHandle:Toggle(tCfg)
					tCfg = tCfg or {}
					return tabHandle:Module({
						Name = tCfg.Text or "Toggle",
						Desc = tCfg.Desc or "",
						Default = tCfg.Default,
						Side = secSide,
						Callback = tCfg.Callback,
					})
				end

				function secHandle:Module(mCfg)
					mCfg = mCfg or {}
					mCfg.Side = secSide
					return tabHandle:Module(mCfg)
				end

				function secHandle:Button(bCfg)
					bCfg = bCfg or {}
					local m = tabHandle:Module({
						Name = bCfg.Text or "Button",
						Desc = bCfg.Desc or "Click to execute action",
						Default = false,
						Side = secSide,
						Callback = function()
							if bCfg.Callback then bCfg.Callback() end
						end,
					})
					return m
				end

				function secHandle:Slider(sCfg)
					sCfg = sCfg or {}
					local m = tabHandle:Module({
						Name = sCfg.Text or "Slider",
						Desc = "Adjust value parameter",
						Default = false,
						Side = secSide,
					})
					m:Slider(sCfg)
					return m
				end

				function secHandle:Dropdown(dCfg)
					dCfg = dCfg or {}
					local m = tabHandle:Module({
						Name = dCfg.Text or "Dropdown",
						Desc = "Select from options",
						Default = false,
						Side = secSide,
					})
					m:Dropdown(dCfg)
					return m
				end

				function secHandle:Colorpicker(cpCfg)
					cpCfg = cpCfg or {}
					local m = tabHandle:Module({
						Name = cpCfg.Text or "Colorpicker",
						Desc = "Pick custom color",
						Default = false,
						Side = secSide,
					})
					m:Colorpicker(cpCfg)
					return m
				end

				function secHandle:Keybind(kCfg)
					kCfg = kCfg or {}
					local m = tabHandle:Module({
						Name = kCfg.Text or "Keybind",
						Desc = "Bind activation shortcut",
						Default = false,
						Side = secSide,
						Keybind = kCfg.Default,
					})
					return m
				end

				function secHandle:Input(iCfg)
					iCfg = iCfg or {}
					local m = tabHandle:Module({
						Name = iCfg.Text or "Input",
						Desc = "Enter text parameter",
						Default = false,
						Side = secSide,
					})
					m:Input(iCfg)
					return m
				end

				function secHandle:Label(text)
					local l = Instance.new("TextLabel")
					l.Size = UDim2.new(1, 0, 0, 20)
					l.BackgroundTransparency = 1
					applyFont(l, "Medium")
					l.TextSize = 10
					l.TextColor3 = ThemeEngine.TextMuted
					l.TextXAlignment = Enum.TextXAlignment.Left
					l.Text = tostring(text)
					l.ZIndex = 3
					l.Parent = parentCol
					return l
				end

				return secHandle
			end

			return tabHandle
		end

		return windowHandle
	end

	function lib:Destroy()
		for _, conn in ipairs(connections) do
			pcall(function() conn:Disconnect() end)
		end
		table.clear(connections)

		for _, inst in ipairs(instances) do
			pcall(function() inst:Destroy() end)
		end
		table.clear(instances)

		if menuBlur then
			pcall(function() menuBlur:Destroy() end)
		end
	end

	defaultInstance = lib
	return lib
end

function Library:Window(cfg)
	if not defaultInstance then Library.new() end
	return defaultInstance:Window(cfg)
end

function Library:Watermark(cfg)
	if not defaultInstance then Library.new() end
	return defaultInstance:Watermark(cfg)
end

function Library:Notify(cfg)
	if not defaultInstance then Library.new() end
	return defaultInstance:Notify(cfg)
end

function Library:SetTheme(name)
	if not defaultInstance then Library.new() end
	return defaultInstance:SetTheme(name)
end

function Library:GetTheme()
	if not defaultInstance then Library.new() end
	return defaultInstance:GetTheme()
end

function Library:GetThemes()
	if not defaultInstance then Library.new() end
	return defaultInstance:GetThemes()
end

function Library:Destroy()
	if defaultInstance then
		defaultInstance:Destroy()
		defaultInstance = nil
	end
end

-- ═══════════════════════════════════════════════════════════════
--  ZeHub Home Dashboard Entry Point
--  Original framework/components remain intact.
-- ═══════════════════════════════════════════════════════════════

local _ZeHubPreview = Library.new()
local _ZeHubWindow = _ZeHubPreview:Window({
	Title = "ZeHub",
	ToggleKey = Enum.KeyCode.RightShift,
	Size = UDim2.fromOffset(900, 620),
})

_ZeHubPreview:Watermark({Name = "ZeHub", ShowFps = true, ShowPing = true})

-- Fit the default preview on smaller displays without changing its layout proportions.
pcall(function()
	local camera = Workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		local fit = math.min(1, viewport.X / 940, viewport.Y / 660)
		_ZeHubWindow:SetUIScale(math.clamp(fit, 0.65, 1))
		_ZeHubPreview:SetConfigValue("Scale", math.clamp(fit, 0.65, 1))
	end
end)

_ZeHubWindow:Category("Workspace")
local _home = _ZeHubWindow:Tab({Name = "Home", Icon = Icons.Logo})
_home:DashboardHero({
	Title = "Welcome to ZeHub",
	Desc = "Your workspace, tools and preferences — organised in one place.",
	Badge = "VERSION 5",
	Height = 112,
})
_home:DashboardLayout(128)

local function _open(name)
	return function()
		_ZeHubWindow:SelectTab(name)
	end
end

_home:DashboardCard({Name = "Combat", Desc = "Enhance your combat experience with powerful features.", Icon = Icons.Combat, Side = "Left", Callback = _open("Combat")})
_home:DashboardCard({Name = "Movement", Desc = "Control your movement with advanced options.", Icon = Icons.Movement, Side = "Right", Callback = _open("Movement")})
_home:DashboardCard({Name = "Visuals", Desc = "See more, find more, get the edge.", Icon = Icons.Render, Side = "Left", Callback = _open("Visuals")})
_home:DashboardCard({Name = "World", Desc = "Interact with the game world like never before.", Icon = Icons.World, Side = "Right", Callback = _open("World")})
_home:DashboardCard({Name = "Player", Desc = "Manage your player settings and preferences.", Icon = Icons.Player, Side = "Left", Callback = _open("Player")})
_home:DashboardCard({Name = "Settings", Desc = "Customize your UI, themes and configuration.", Icon = Icons.Configs, Side = "Right", Callback = _open("Settings")})

-- Real destination tabs for the Home dashboard shortcuts.
local _combat = _ZeHubWindow:Tab({Name = "Combat", Icon = Icons.Combat})
_combat:Module({Name = "Combat Features", Desc = "Add your combat modules here.", Side = "Left"})
_combat:Module({Name = "Combat Settings", Desc = "Configure combat behaviour and keybinds.", Side = "Right"})

local _movement = _ZeHubWindow:Tab({Name = "Movement", Icon = Icons.Movement})
_movement:Module({Name = "Movement Features", Desc = "Add your movement modules here.", Side = "Left"})
_movement:Module({Name = "Movement Settings", Desc = "Configure movement behaviour and keybinds.", Side = "Right"})

local _visuals = _ZeHubWindow:Tab({Name = "Visuals", Icon = Icons.Render})
_visuals:Module({Name = "Visual Features", Desc = "ESP, rendering and visual modules go here.", Side = "Left"})
_visuals:Module({Name = "Visual Settings", Desc = "Configure visual appearance and options.", Side = "Right"})

local _world = _ZeHubWindow:Tab({Name = "World", Icon = Icons.World})
_world:Module({Name = "World Features", Desc = "Interact with and customise the game world.", Side = "Left"})
_world:Module({Name = "World Settings", Desc = "Configure world and environment options.", Side = "Right"})

local _player = _ZeHubWindow:Tab({Name = "Player", Icon = Icons.Player})
_player:Module({Name = "Player Features", Desc = "Player and character features live here.", Side = "Left"})
_player:Module({Name = "Player Settings", Desc = "Configure player preferences and options.", Side = "Right"})

local _settings = _ZeHubWindow:Tab({Name = "Settings", Icon = Icons.Configs})
local _general = _settings:Module({
	Name = "General Settings",
	Desc = "Interface preferences and accessibility.",
	Side = "Left",
})
_general:Toggle({Text = "Show keybind HUD", Default = true, Callback = function(v)
	_ZeHubWindow:SetKeybindListVisible(v)
end})
_general:Toggle({Text = "Show player card", Default = true, Callback = function(v)
	_ZeHubWindow:SetProfileCardVisible(v)
end})
_general:Toggle({Text = "Show avatar", Default = true, Callback = function(v)
	_ZeHubWindow:SetProfileAvatarVisible(v)
end})
local _themeModule = _settings:Module({
	Name = "Appearance",
	Desc = "Choose one of the framework's seven themes.",
	Side = "Right",
})
_themeModule:Dropdown({
	Text = "Theme",
	Items = _ZeHubPreview:GetThemes(),
	Default = _ZeHubPreview:GetTheme(),
	Callback = function(name) _ZeHubWindow:SetTheme(name); _ZeHubPreview:SetConfigValue("Theme", name) end,
})

local _layoutModule = _settings:Module({Name = "Layout & Accessibility", Desc = "Adjust the interface to your screen and preferences.", Side = "Left"})
_layoutModule:Slider({Text = "UI scale", Min = 65, Max = 115, Step = 5, Default = 100, Suffix = "%", Callback = function(v)
	_ZeHubWindow:SetUIScale(v / 100)
	_ZeHubPreview:SetConfigValue("Scale", v / 100)
end})
_layoutModule:Slider({Text = "Window opacity", Min = 60, Max = 100, Step = 5, Default = 95, Suffix = "%", Callback = function(v)
	_ZeHubWindow:SetOpacity(v)
	_ZeHubPreview:SetConfigValue("Opacity", v)
end})
_layoutModule:Toggle({Text = "Reduced motion", Default = false, Callback = function(v)
	_ZeHubWindow:SetReducedMotion(v)
	_ZeHubPreview:SetConfigValue("ReducedMotion", v)
end})
local _configModule = _settings:Module({Name = "Configuration", Desc = "Save or restore your interface preferences. File APIs are required.", Side = "Right"})
_configModule:Button({Text = "Save default config", Callback = function()
	_ZeHubPreview:SetConfigValue("Theme", _ZeHubWindow:GetTheme())
	_ZeHubPreview:SetConfigValue("Scale", _ZeHubWindow:GetUIScale())
	local ok, err = _ZeHubPreview:SaveConfig("default")
	_ZeHubPreview:Notify({Title = "Configuration", Content = ok and "Default config saved." or tostring(err), Type = ok and "Success" or "Error", Duration = 4})
end})
_configModule:Button({Text = "Load default config", Callback = function()
	local ok, data = _ZeHubPreview:LoadConfig("default")
	if ok then
		if data.Theme then _ZeHubWindow:SetTheme(data.Theme) end
		if data.Scale then _ZeHubWindow:SetUIScale(data.Scale) end
		if data.Opacity then _ZeHubWindow:SetOpacity(data.Opacity) end
		if data.ReducedMotion ~= nil then _ZeHubWindow:SetReducedMotion(data.ReducedMotion) end
	end
	_ZeHubPreview:Notify({Title = "Configuration", Content = ok and "Default config loaded." or tostring(data), Type = ok and "Success" or "Error", Duration = 4})
end})

_ZeHubWindow:Category("Personal")
local _profile = _ZeHubWindow:Tab({Name = "Profile", Icon = Icons.Player})
local _profileCard = _profile:Module({
	Name = "Profile Display",
	Desc = "Control the player card in the lower-left sidebar.",
	Side = "Left",
})
_profileCard:Toggle({Text = "Show profile card", Default = true, Callback = function(v) _ZeHubWindow:SetProfileCardVisible(v) end})
_profileCard:Toggle({Text = "Show avatar", Default = true, Callback = function(v) _ZeHubWindow:SetProfileAvatarVisible(v) end})
_profileCard:Toggle({Text = "Show display name", Default = true, Callback = function(v) _ZeHubWindow:SetProfileNameVisible(v) end})
_profileCard:Toggle({Text = "Show keybind HUD", Default = true, Callback = function(v) _ZeHubWindow:SetKeybindListVisible(v) end})
local _profileInfo = _profile:Module({
	Name = "Account Information",
	Desc = "Your Roblox profile details.",
	Side = "Right",
})
_profileInfo:Input({Text = "Username", Placeholder = LocalPlayer.Name, Default = LocalPlayer.Name})
_profileInfo:Input({Text = "Display name", Placeholder = LocalPlayer.DisplayName, Default = LocalPlayer.DisplayName})
_profileInfo:Input({Text = "User ID", Placeholder = tostring(LocalPlayer.UserId), Default = tostring(LocalPlayer.UserId)})

local _components = _ZeHubWindow:Tab({Name = "Components", Icon = Icons.Util})
local _demo = _components:Module({
	Name = "Component Preview",
	Desc = "Try the original controls without changing the framework.",
})
_demo:Slider({Text = "Slider", Min = 0, Max = 100, Step = 1, Default = 50, Suffix = "%"})
_demo:Dropdown({Text = "Dropdown", Items = {"Option 1", "Option 2", "Option 3"}, Default = "Option 1"})
_demo:Toggle({Text = "Toggle", Default = false})
_demo:Colorpicker({Text = "Accent colour", Default = Color3.fromRGB(80, 120, 255)})
_demo:Button({Text = "Test notification", Callback = function()
	_ZeHubPreview:Notify({Title = "ZeHub", Content = "Notification preview works.", Duration = 3, Type = "Success"})
end})
_demo:Keybind({Text = "Example keybind", Default = Enum.KeyCode.G})
_demo:Input({Text = "Text input", Placeholder = "Type something...", Default = ""})

_ZeHubWindow:Notify({
	Title = "ZeHub",
	Content = "Home dashboard loaded — use the cards or sidebar to navigate.",
	Duration = 4,
	Type = "Success",
})

return Library
