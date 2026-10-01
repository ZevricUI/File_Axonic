local Library = (function()
-- ============================================================================
-- ZeHub UI Library • Black / White Transparent Edition
-- ============================================================================
--
-- Visual changes:
--   • Black / charcoal / white theme
--   • Transparent / glass-style background
--   • Thin grey/white borders
--   • Minimal monochrome UI
--   • Compact sidebar
--   • Minimize -> floating compact box
--   • Click compact box -> restore
--   • Main window remains draggable
--   • Minimized box is draggable
--   • PC + mobile/touch support
--
-- Public API preserved:
--   Library:CreateWindow
--   Window:CreateTab / AddTab
--   Tab:CreateSection / AddSection
--   Section:CreateToggle
--   Section:CreateButton
--   Section:CreateDropdown
--   Section:CreateMultiDropdown
--   Section:CreateSlider
--   Section:CreateNumberBox
--   Section:CreateInput / CreateTextBox
--   Section:CreateParagraph / CreateInfo / CreateLabel
--   Section:CreateFeatureCard
--   Section:CreateSpacer
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local guiAlive = true

-- ============================================================================
-- THEME
-- ============================================================================

local ThemePresets = {

    Dark = {
        Background = Color3.fromRGB(7, 8, 10),
        Topbar = Color3.fromRGB(10, 11, 14),
        Sidebar = Color3.fromRGB(8, 10, 12),

        Row = Color3.fromRGB(15, 17, 20),
        RowHover = Color3.fromRGB(22, 25, 29),

        Input = Color3.fromRGB(10, 12, 15),

        Border = Color3.fromRGB(48, 51, 57),
        BorderBright = Color3.fromRGB(112, 116, 124),

        Text = Color3.fromRGB(238, 240, 243),
        Muted = Color3.fromRGB(148, 152, 159),
        Placeholder = Color3.fromRGB(91, 96, 104),

        ToggleOn = Color3.fromRGB(232, 234, 238),
        TabActive = Color3.fromRGB(24, 27, 31),

        Accent = Color3.fromRGB(232, 234, 238),
        Shadow = Color3.fromRGB(0, 0, 0)
    },

    Light = {
        Background = Color3.fromRGB(235, 235, 235),
        Topbar = Color3.fromRGB(245, 245, 245),
        Sidebar = Color3.fromRGB(239, 239, 239),

        Row = Color3.fromRGB(248, 248, 248),
        RowHover = Color3.fromRGB(228, 228, 228),

        Input = Color3.fromRGB(232, 232, 232),

        Border = Color3.fromRGB(190, 190, 190),
        BorderBright = Color3.fromRGB(105, 105, 105),

        Text = Color3.fromRGB(18, 18, 19),
        Muted = Color3.fromRGB(105, 105, 108),
        Placeholder = Color3.fromRGB(135, 135, 138),

        ToggleOn = Color3.fromRGB(25, 25, 26),
        TabActive = Color3.fromRGB(220, 220, 220),

        Accent = Color3.fromRGB(25, 25, 26),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

local currentThemeName = "Dark"
local Theme = ThemePresets[currentThemeName]

local themeRefreshers = {}

local activePageName = nil
local minimized = false
local sidebarExpanded = true

-- ============================================================================
-- HELPERS
-- ============================================================================

local function create(className, properties)

    local object = Instance.new(className)

    for property, value in pairs(properties) do
        if property ~= "Parent" then
            object[property] = value
        end
    end

    if properties.Parent then
        object.Parent = properties.Parent
    end

    return object
end

local function corner(parent, radius)

    return create("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent
    })

end

local function stroke(parent, color, transparency)

    return create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1,
        Parent = parent
    })

end

local function tween(object, properties, duration)

    if not object or not object.Parent then
        return
    end

    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.1,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()

    return animation
end

local function registerThemeRefresh(callback)

    table.insert(themeRefreshers, callback)

end

-- ============================================================================
-- GUI PARENT
-- ============================================================================

local function getGuiParent()

    if type(gethui) == "function" then

        local ok, result = pcall(gethui)

        if ok and result then
            return result
        end

    end

    return player:WaitForChild("PlayerGui")

end

local guiParent = getGuiParent()

local oldGui = guiParent:FindFirstChild("ZeHubUILibrary")

if oldGui then
    oldGui:Destroy()
end

-- ============================================================================
-- SCREEN GUI
-- ============================================================================

local gui = create("ScreenGui", {
    Name = "ZeHubUILibrary",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = guiParent
})

gui.Enabled = false

-- ============================================================================
-- WINDOW SETTINGS
-- ============================================================================

local BASE_WIDTH = 500
local BASE_HEIGHT = 430

local TOPBAR_HEIGHT = 48

local SIDEBAR_COLLAPSED = 58
local SIDEBAR_EXPANDED = 150

local CONTENT_GAP = 12

local PAGE_HEADER_HEIGHT = 26
local SECTION_BAR_HEIGHT = 34

-- ============================================================================
-- MAIN WINDOW
-- ============================================================================

local main = create("Frame", {

    Name = "Main",

    AnchorPoint = Vector2.new(0.5, 0.5),

    Position = UDim2.fromScale(0.5, 0.5),

    Size = UDim2.fromOffset(
        BASE_WIDTH,
        BASE_HEIGHT
    ),

    BackgroundColor3 = Theme.Background,

    BackgroundTransparency = 0.15,

    BorderSizePixel = 0,

    ClipsDescendants = true,

    Active = true,

    Parent = gui
})

corner(main, 9)

local mainStroke = stroke(
    main,
    Theme.BorderBright,
    0.35
)

-- ============================================================================
-- TOPBAR
-- ============================================================================

local topbar = create("Frame", {

    Name = "Topbar",

    Size = UDim2.new(
        1,
        0,
        0,
        TOPBAR_HEIGHT
    ),

    BackgroundColor3 = Theme.Topbar,

    BackgroundTransparency = 0.21,

    BorderSizePixel = 0,

    Active = true,

    Parent = main
})

corner(topbar, 9)

local topbarBottom = create("Frame", {

    Position = UDim2.new(
        0,
        0,
        1,
        -7
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        7
    ),

    BackgroundColor3 = Theme.Topbar,

    BackgroundTransparency = 0.21,

    BorderSizePixel = 0,

    Parent = topbar
})

-- ============================================================================
-- MENU
-- ============================================================================

local menuButton = create("TextButton", {

    Name = "Navigation",

    Position = UDim2.fromOffset(
        11,
        8
    ),

    Size = UDim2.fromOffset(
        22,
        22
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    AutoButtonColor = false,

    Text = "≡",

    TextColor3 = Theme.Muted,

    Font = Enum.Font.GothamBold,

    TextSize = 16,

    Parent = topbar
})

-- ============================================================================
-- TITLE
-- ============================================================================

local title = create("TextLabel", {

    Name = "Title",

    Position = UDim2.fromOffset(
        40,
        4
    ),

    Size = UDim2.new(
        1,
        -135,
        0,
        18
    ),

    BackgroundTransparency = 1,

    Text = "ZeHub",

    TextColor3 = Theme.Text,

    TextSize = 12,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextTruncate = Enum.TextTruncate.AtEnd,

    Parent = topbar
})

local subtitle = create("TextLabel", {

    Name = "Subtitle",

    Position = UDim2.fromOffset(
        40,
        21
    ),

    Size = UDim2.new(
        1,
        -135,
        0,
        13
    ),

    BackgroundTransparency = 1,

    Text = "UI Library",

    TextColor3 = Theme.Muted,

    TextSize = 9,

    Font = Enum.Font.GothamSemibold,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextTruncate = Enum.TextTruncate.AtEnd,

    Parent = topbar
})

-- ============================================================================
-- THEME BUTTON
-- ============================================================================

local themeButton = create("TextButton", {

    Name = "Theme",

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -61,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        20,
        20
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    Text = "",

    AutoButtonColor = false,

    Parent = topbar
})

local themeCenter = create("Frame", {

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromOffset(
        5,
        5
    ),

    BackgroundColor3 = Theme.Muted,

    BorderSizePixel = 0,

    Parent = themeButton
})

corner(themeCenter, 5)

local themeRays = {}

local rayData = {

    {
        UDim2.new(
            0.5,
            -1,
            0.5,
            -7
        ),

        UDim2.fromOffset(
            2,
            3
        )
    },

    {
        UDim2.new(
            0.5,
            -1,
            0.5,
            4
        ),

        UDim2.fromOffset(
            2,
            3
        )
    },

    {
        UDim2.new(
            0.5,
            -7,
            0.5,
            -1
        ),

        UDim2.fromOffset(
            3,
            2
        )
    },

    {
        UDim2.new(
            0.5,
            4,
            0.5,
            -1
        ),

        UDim2.fromOffset(
            3,
            2
        )
    }
}

for _, data in ipairs(rayData) do

    local ray = create("Frame", {

        Position = data[1],

        Size = data[2],

        BackgroundColor3 = Theme.Muted,

        BorderSizePixel = 0,

        Parent = themeButton
    })

    table.insert(
        themeRays,
        ray
    )

end

-- ============================================================================
-- MINIMIZE BUTTON
-- ============================================================================

local minimizeButton = create("TextButton", {

    Name = "Minimize",

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -34,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        20,
        20
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    Text = "",

    AutoButtonColor = false,

    Parent = topbar
})

local minimizeLine = create("Frame", {

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromOffset(
        9,
        1
    ),

    BackgroundColor3 = Theme.Text,

    BorderSizePixel = 0,

    Parent = minimizeButton
})

-- ============================================================================
-- CLOSE
-- ============================================================================

local close = create("TextButton", {

    Name = "Close",

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -8,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        18,
        18
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    Text = "X",

    TextColor3 = Theme.Text,

    Font = Enum.Font.GothamBold,

    TextSize = 10,

    AutoButtonColor = false,

    Parent = topbar
})

local topLine = create("Frame", {

    Position = UDim2.new(
        0,
        0,
        1,
        -1
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        1
    ),

    BackgroundColor3 = Theme.Border,

    BackgroundTransparency = 0.28,

    BorderSizePixel = 0,

    Parent = topbar
})

-- ============================================================================
-- SIDEBAR
-- ============================================================================

local sidebar = create("Frame", {

    Name = "Sidebar",

    Position = UDim2.fromOffset(
        0,
        TOPBAR_HEIGHT
    ),

    Size = UDim2.new(
        0,
        SIDEBAR_EXPANDED,
        1,
        -TOPBAR_HEIGHT
    ),

    BackgroundColor3 = Theme.Sidebar,

    BackgroundTransparency = 0.28,

    BorderSizePixel = 0,

    ClipsDescendants = true,

    Parent = main
})

local sidebarLine = create("Frame", {

    AnchorPoint = Vector2.new(
        1,
        0
    ),

    Position = UDim2.new(
        1,
        0,
        0,
        0
    ),

    Size = UDim2.new(
        0,
        1,
        1,
        0
    ),

    BackgroundColor3 = Theme.Border,

    BackgroundTransparency = 0.15,

    BorderSizePixel = 0,

    Parent = sidebar
})

local navHolder = create("Frame", {

    Position = UDim2.fromOffset(
        8,
        12
    ),

    Size = UDim2.new(
        1,
        -16,
        1,
        -24
    ),

    BackgroundTransparency = 1,

    Parent = sidebar
})

create("UIListLayout", {

    Padding = UDim.new(
        0,
        4
    ),

    SortOrder = Enum.SortOrder.LayoutOrder,

    Parent = navHolder
})

-- ============================================================================
-- CONTENT
-- ============================================================================

local content = create("Frame", {

    Name = "Content",

    Position = UDim2.fromOffset(
        SIDEBAR_EXPANDED + CONTENT_GAP,
        TOPBAR_HEIGHT + CONTENT_GAP
    ),

    Size = UDim2.new(
        1,
        -(SIDEBAR_EXPANDED + CONTENT_GAP * 2),
        1,
        -(TOPBAR_HEIGHT + CONTENT_GAP * 2)
    ),

    BackgroundTransparency = 1,

    ClipsDescendants = true,

    Parent = main
})

-- ============================================================================
-- DATA
-- ============================================================================

local pages = {}
local sideButtons = {}
local activeSectionByPage = {}

-- ============================================================================
-- ICON COLOR
-- ============================================================================

local function setGlyphColor(glyph, color)

    if not glyph then
        return
    end

    for _, part in ipairs(glyph.Fills or {}) do

        if part and part.Parent then
            part.BackgroundColor3 = color
        end

    end

    for _, line in ipairs(glyph.Strokes or {}) do

        if line and line.Parent then
            line.Color = color
        end

    end

    for _, textPart in ipairs(glyph.Texts or {}) do

        if textPart and textPart.Parent then
            textPart.TextColor3 = color
        end

    end

end

-- ============================================================================
-- NAV ICONS
-- ============================================================================

local function createNavGlyph(parent, kind)

    local root = create("Frame", {

        AnchorPoint = Vector2.new(
            0.5,
            0.5
        ),

        Position = UDim2.fromScale(
            0.5,
            0.5
        ),

        Size = UDim2.fromOffset(
            18,
            18
        ),

        BackgroundTransparency = 1,

        Parent = parent
    })

    local glyph = {
        Root = root,
        Fills = {},
        Strokes = {},
        Texts = {}
    }

    local function fill(position, size, radius)

        local part = create("Frame", {

            Position = position,

            Size = size,

            BackgroundColor3 = Theme.Muted,

            BorderSizePixel = 0,

            Parent = root
        })

        if radius then
            corner(part, radius)
        end

        table.insert(
            glyph.Fills,
            part
        )

        return part
    end

    local function outline(position, size, radius, thickness)

        local part = create("Frame", {

            Position = position,

            Size = size,

            BackgroundTransparency = 1,

            BorderSizePixel = 0,

            Parent = root
        })

        if radius then
            corner(part, radius)
        end

        local partStroke = stroke(
            part,
            Theme.Muted,
            0
        )

        partStroke.Thickness = thickness or 1

        table.insert(
            glyph.Strokes,
            partStroke
        )

        return part
    end

    local function textGlyph(value, textSize)

        local label = create("TextLabel", {

            Size = UDim2.fromScale(
                1,
                1
            ),

            BackgroundTransparency = 1,

            Text = value,

            TextColor3 = Theme.Muted,

            TextSize = textSize or 12,

            Font = Enum.Font.GothamBold,

            Parent = root
        })

        table.insert(
            glyph.Texts,
            label
        )

        return label
    end

    if kind == "Changelog"
        or kind == "Home" then

        outline(
            UDim2.fromOffset(2, 2),
            UDim2.fromOffset(14, 14),
            7,
            1
        )

        fill(
            UDim2.fromOffset(8, 5),
            UDim2.fromOffset(2, 5),
            1
        )

        local hand = fill(
            UDim2.fromOffset(9, 9),
            UDim2.fromOffset(5, 2),
            1
        )

        hand.Rotation = 22

    elseif kind == "Auto Farm"
        or kind == "Farm" then

        outline(
            UDim2.fromOffset(3, 3),
            UDim2.fromOffset(12, 12),
            7,
            1
        )

        fill(
            UDim2.fromOffset(11, 2),
            UDim2.fromOffset(4, 2),
            1
        )

        fill(
            UDim2.fromOffset(14, 2),
            UDim2.fromOffset(2, 5),
            1
        )

        fill(
            UDim2.fromOffset(4, 11),
            UDim2.fromOffset(4, 2),
            1
        )

        fill(
            UDim2.fromOffset(3, 9),
            UDim2.fromOffset(2, 4),
            1
        )

    elseif kind == "Events" then

        outline(
            UDim2.fromOffset(3, 3),
            UDim2.fromOffset(12, 12),
            7,
            1
        )

        textGlyph(
            "!",
            11
        )

    elseif kind == "Pets" then

        fill(
            UDim2.fromOffset(3, 4),
            UDim2.fromOffset(4, 4),
            3
        )

        fill(
            UDim2.fromOffset(7, 2),
            UDim2.fromOffset(4, 4),
            3
        )

        fill(
            UDim2.fromOffset(11, 4),
            UDim2.fromOffset(4, 4),
            3
        )

        fill(
            UDim2.fromOffset(6, 9),
            UDim2.fromOffset(7, 6),
            4
        )

    elseif kind == "Progress"
        or kind == "Stats" then

        fill(
            UDim2.fromOffset(3, 11),
            UDim2.fromOffset(3, 4),
            1
        )

        fill(
            UDim2.fromOffset(8, 7),
            UDim2.fromOffset(3, 8),
            1
        )

        fill(
            UDim2.fromOffset(13, 3),
            UDim2.fromOffset(3, 12),
            1
        )

    elseif kind == "Rewards"
        or kind == "Gift" then

        outline(
            UDim2.fromOffset(3, 6),
            UDim2.fromOffset(12, 9),
            2,
            1
        )

        fill(
            UDim2.fromOffset(8, 6),
            UDim2.fromOffset(2, 9),
            1
        )

        fill(
            UDim2.fromOffset(2, 5),
            UDim2.fromOffset(14, 2),
            1
        )

        fill(
            UDim2.fromOffset(5, 3),
            UDim2.fromOffset(4, 2),
            2
        )

        fill(
            UDim2.fromOffset(9, 3),
            UDim2.fromOffset(4, 2),
            2
        )

    elseif kind == "Visuals"
        or kind == "Eye" then

        outline(
            UDim2.fromOffset(2, 5),
            UDim2.fromOffset(14, 8),
            6,
            1
        )

        fill(
            UDim2.fromOffset(7, 7),
            UDim2.fromOffset(4, 4),
            3
        )

    elseif kind == "Utility"
        or kind == "Settings" then

        fill(
            UDim2.fromOffset(3, 4),
            UDim2.fromOffset(12, 1),
            1
        )

        fill(
            UDim2.fromOffset(3, 9),
            UDim2.fromOffset(12, 1),
            1
        )

        fill(
            UDim2.fromOffset(3, 14),
            UDim2.fromOffset(12, 1),
            1
        )

        fill(
            UDim2.fromOffset(6, 2),
            UDim2.fromOffset(3, 5),
            2
        )

        fill(
            UDim2.fromOffset(11, 7),
            UDim2.fromOffset(3, 5),
            2
        )

        fill(
            UDim2.fromOffset(5, 12),
            UDim2.fromOffset(3, 5),
            2
        )

    else

        fill(
            UDim2.fromOffset(5, 5),
            UDim2.fromOffset(8, 8),
            5
        )

    end

    return glyph
end

-- ============================================================================
-- PAGE SECTION REFRESH
-- ============================================================================

local function refreshPageSections(pageData)

    local activeSection =
        activeSectionByPage[pageData.Name]

    for sectionName, section in pairs(pageData.Sections) do

        section.Visible =
            sectionName == activeSection

    end

    for sectionName, buttonData in pairs(pageData.SectionButtons) do

        local active =
            sectionName == activeSection

        buttonData.Button.BackgroundColor3 =
            active
            and Theme.Row
            or Theme.Background

        buttonData.Button.BackgroundTransparency =
            active
            and 0.15
            or 1

        buttonData.Label.TextColor3 =
            active
            and Theme.Text
            or Theme.Muted

        buttonData.Underline.BackgroundColor3 =
            Theme.Text

        buttonData.Underline.BackgroundTransparency =
            active
            and 0.15
            or 1

    end

end

local function selectSection(pageName, sectionName)

    local pageData = pages[pageName]

    if not pageData
        or not pageData.Sections[sectionName] then
        return
    end

    activeSectionByPage[pageName] =
        sectionName

    refreshPageSections(pageData)

end

-- ============================================================================
-- SIDEBAR REFRESH
-- ============================================================================

local function refreshSideTabs()

    for name, data in pairs(sideButtons) do

        local active =
            name == activePageName

        data.Button.BackgroundColor3 =
            Theme.Sidebar

        data.IconHolder.BackgroundColor3 =
            active
            and Theme.TabActive
            or Theme.Sidebar

        data.IconHolder.BackgroundTransparency =
            active
            and 0
            or 1

        data.IconStroke.Color =
            active
            and Theme.BorderBright
            or Theme.Border

        data.IconStroke.Transparency =
            active
            and 0.45
            or 1

        data.Label.TextColor3 =
            active
            and Theme.Text
            or Theme.Muted

        data.Indicator.BackgroundColor3 =
            Theme.Text

        data.Indicator.BackgroundTransparency =
            active
            and 0
            or 1

        setGlyphColor(
            data.Glyph,
            active
            and Theme.Text
            or Theme.Muted
        )

    end

end

-- ============================================================================
-- SELECT PAGE
-- ============================================================================

local function selectPage(name)

    local pageData = pages[name]

    if not pageData then
        return
    end

    activePageName = name

    for pageName, data in pairs(pages) do

        data.Root.Visible =
            pageName == name

    end

    if not activeSectionByPage[name]
        and pageData.FirstSection then

        activeSectionByPage[name] =
            pageData.FirstSection

    end

    refreshPageSections(pageData)

    refreshSideTabs()

end

-- ============================================================================
-- CREATE PAGE
-- ============================================================================

local function createPage(name, iconAsset)

    local root = create("Frame", {

        Name = name,

        Size = UDim2.fromScale(
            1,
            1
        ),

        BackgroundTransparency = 1,

        Visible = false,

        Parent = content
    })

    local pageHeader = create("Frame", {

        Name = "PageHeader",

        Position = UDim2.fromOffset(
            0,
            SECTION_BAR_HEIGHT + 2
        ),

        Size = UDim2.new(
            1,
            0,
            0,
            PAGE_HEADER_HEIGHT
        ),

        BackgroundTransparency = 1,

        Parent = root
    })

    local headerDot = create("Frame", {

        AnchorPoint = Vector2.new(
            0,
            0.5
        ),

        Position = UDim2.new(
            0,
            3,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            4,
            4
        ),

        BackgroundColor3 = Theme.Text,

        BorderSizePixel = 0,

        Parent = pageHeader
    })

    corner(
        headerDot,
        3
    )

    local headerLabel = create("TextLabel", {

        Position = UDim2.fromOffset(
            13,
            0
        ),

        Size = UDim2.fromOffset(
            92,
            PAGE_HEADER_HEIGHT
        ),

        BackgroundTransparency = 1,

        Text = string.upper(name),

        TextColor3 = Theme.Muted,

        TextSize = 9,

        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        Parent = pageHeader
    })

    local headerLine = create("Frame", {

        Position = UDim2.fromOffset(
            103,
            math.floor(
                PAGE_HEADER_HEIGHT / 2
            )
        ),

        Size = UDim2.new(
            1,
            -106,
            0,
            1
        ),

        BackgroundColor3 = Theme.Border,

        BackgroundTransparency = 0.15,

        BorderSizePixel = 0,

        Parent = pageHeader
    })

    local sectionBar = create("ScrollingFrame", {

        Name = "SectionTabs",

        Position = UDim2.fromOffset(
            0,
            0
        ),

        Size = UDim2.new(
            1,
            0,
            0,
            SECTION_BAR_HEIGHT
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness = 0,

        CanvasSize = UDim2.new(),

        AutomaticCanvasSize = Enum.AutomaticSize.X,

        ScrollingDirection =
            Enum.ScrollingDirection.X,

        Active = true,

        Parent = root
    })

    create("UIListLayout", {

        FillDirection =
            Enum.FillDirection.Horizontal,

        HorizontalAlignment =
            Enum.HorizontalAlignment.Left,

        Padding = UDim.new(
            0,
            3
        ),

        SortOrder =
            Enum.SortOrder.LayoutOrder,

        Parent = sectionBar
    })

    local contentTop =
        SECTION_BAR_HEIGHT
        + PAGE_HEADER_HEIGHT
        + 7

    local sectionContent = create("Frame", {

        Position = UDim2.fromOffset(
            0,
            contentTop
        ),

        Size = UDim2.new(
            1,
            0,
            1,
            -contentTop
        ),

        BackgroundTransparency = 1,

        ClipsDescendants = true,

        Parent = root
    })

    local pageData = {

        Name = name,

        Root = root,

        PageHeader = pageHeader,

        HeaderDot = headerDot,

        HeaderLabel = headerLabel,

        HeaderLine = headerLine,

        SectionBar = sectionBar,

        SectionContent = sectionContent,

        Sections = {},

        SectionButtons = {},

        FirstSection = nil
    }

    pages[name] = pageData

    -- NAV BUTTON

    local navButton = create("TextButton", {

        Name = "Nav_" .. name,

        Size = UDim2.new(
            1,
            0,
            0,
            36
        ),

        BackgroundColor3 = Theme.Sidebar,

        BorderSizePixel = 0,

        Text = "",

        AutoButtonColor = false,

        Parent = navHolder
    })

    corner(
        navButton,
        5
    )

    local indicator = create("Frame", {

        AnchorPoint = Vector2.new(
            0,
            0.5
        ),

        Position = UDim2.new(
            0,
            0,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            2,
            18
        ),

        BackgroundColor3 = Theme.Text,

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Parent = navButton
    })

    corner(
        indicator,
        2
    )

    local iconHolder = create("Frame", {

        AnchorPoint = Vector2.new(
            0,
            0.5
        ),

        Position = UDim2.new(
            0,
            5,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            28,
            28
        ),

        BackgroundColor3 = Theme.Input,

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Parent = navButton
    })

    corner(
        iconHolder,
        5
    )

    local iconStroke =
        stroke(
            iconHolder,
            Theme.Border,
            1
        )

    local glyph =
        createNavGlyph(
            iconHolder,
            iconAsset or name
        )

    local label = create("TextLabel", {

        Position = UDim2.fromOffset(
            40,
            0
        ),

        Size = UDim2.new(
            1,
            -45,
            1,
            0
        ),

        BackgroundTransparency = 1,

        Text = name,

        TextColor3 = Theme.Muted,

        TextTransparency =
            sidebarExpanded
            and 0
            or 1,

        TextSize = 10,

        Font = Enum.Font.GothamSemibold,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = navButton
    })

    sideButtons[name] = {

        Button = navButton,

        IconHolder = iconHolder,

        IconStroke = iconStroke,

        Glyph = glyph,

        Label = label,

        Indicator = indicator
    }

    navButton.Activated:Connect(function()
        selectPage(name)
    end)

    navButton.MouseEnter:Connect(function()

        if activePageName ~= name then

            tween(
                navButton,
                {
                    BackgroundColor3 =
                        Theme.RowHover
                },
                0.08
            )

            tween(
                label,
                {
                    TextColor3 =
                        Theme.Text
                },
                0.08
            )

            setGlyphColor(
                glyph,
                Theme.Text
            )

        end

    end)

    navButton.MouseLeave:Connect(function()
        refreshSideTabs()
    end)

    registerThemeRefresh(function()

        if root.Parent then

            headerDot.BackgroundColor3 =
                Theme.Text

            headerLabel.TextColor3 =
                Theme.Muted

            headerLine.BackgroundColor3 =
                Theme.Border

            refreshPageSections(
                pageData
            )

        end

    end)

    return pageData

end

-- ============================================================================
-- CREATE SECTION
-- ============================================================================

local function createSection(pageData, sectionName)

    local section = create("ScrollingFrame", {

        Name = sectionName,

        Size = UDim2.fromScale(
            1,
            1
        ),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        ScrollBarThickness =
            UserInputService.TouchEnabled
            and 4
            or 2,

        ScrollBarImageColor3 =
            Theme.BorderBright,

        CanvasSize = UDim2.new(),

        AutomaticCanvasSize =
            Enum.AutomaticSize.Y,

        ScrollingDirection =
            Enum.ScrollingDirection.Y,

        Visible = false,

        Parent = pageData.SectionContent
    })

    create("UIPadding", {

        PaddingTop = UDim.new(
            0,
            2
        ),

        PaddingBottom = UDim.new(
            0,
            7
        ),

        PaddingLeft = UDim.new(
            0,
            1
        ),

        PaddingRight = UDim.new(
            0,
            3
        ),

        Parent = section
    })

    create("UIListLayout", {

        Padding = UDim.new(
            0,
            5
        ),

        SortOrder =
            Enum.SortOrder.LayoutOrder,

        Parent = section
    })

    pageData.Sections[sectionName] =
        section

    if not pageData.FirstSection then

        pageData.FirstSection =
            sectionName

        activeSectionByPage[
            pageData.Name
        ] = sectionName

    end

    local tabWidth =
        math.clamp(
            #sectionName * 6 + 25,
            76,
            142
        )

    local tab = create("TextButton", {

        Name = "Section_" .. sectionName,

        Size = UDim2.new(
            0,
            tabWidth,
            0,
            SECTION_BAR_HEIGHT
        ),

        BackgroundColor3 =
            Theme.Background,

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Text = "",

        AutoButtonColor = false,

        Parent = pageData.SectionBar
    })

    corner(
        tab,
        4
    )

    local tabLabel = create("TextLabel", {

        Position = UDim2.fromOffset(
            8,
            0
        ),

        Size = UDim2.new(
            1,
            -16,
            1,
            -2
        ),

        BackgroundTransparency = 1,

        Text = sectionName,

        TextColor3 = Theme.Muted,

        TextSize = 10,

        Font = Enum.Font.GothamSemibold,

        Parent = tab
    })

    local underline = create("Frame", {

        AnchorPoint = Vector2.new(
            0.5,
            1
        ),

        Position = UDim2.new(
            0.5,
            0,
            1,
            -1
        ),

        Size = UDim2.new(
            1,
            -18,
            0,
            2
        ),

        BackgroundColor3 =
            Theme.Text,

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        Parent = tab
    })

    corner(
        underline,
        2
    )

    pageData.SectionButtons[
        sectionName
    ] = {

        Button = tab,

        Label = tabLabel,

        Underline = underline
    }

    tab.Activated:Connect(function()

        selectSection(
            pageData.Name,
            sectionName
        )

    end)

    tab.MouseEnter:Connect(function()

        if activeSectionByPage[
            pageData.Name
        ] ~= sectionName then

            tween(
                tab,
                {
                    BackgroundColor3 =
                        Theme.RowHover,
                    BackgroundTransparency =
                        0.35
                },
                0.08
            )

            tween(
                tabLabel,
                {
                    TextColor3 =
                        Theme.Text
                },
                0.08
            )

        end

    end)

    tab.MouseLeave:Connect(function()

        refreshPageSections(
            pageData
        )

    end)

    registerThemeRefresh(function()

        if section.Parent then

            section.ScrollBarImageColor3 =
                Theme.BorderBright

            refreshPageSections(
                pageData
            )

        end

    end)

    refreshPageSections(
        pageData
    )

    return section

end

-- ============================================================================
-- ROW HOVER
-- ============================================================================

local function bindRowHover(
    buttonObject,
    row,
    rowStroke
)

    buttonObject.MouseEnter:Connect(function()

        tween(
            row,
            {
                BackgroundColor3 =
                    Theme.RowHover
            },
            0.08
        )

        tween(
            rowStroke,
            {
                Color = Theme.Text,
                Transparency = 0.55
            },
            0.08
        )

    end)

    buttonObject.MouseLeave:Connect(function()

        tween(
            row,
            {
                BackgroundColor3 =
                    Theme.Row
            },
            0.08
        )

        tween(
            rowStroke,
            {
                Color = Theme.Border,
                Transparency = 0.38
            },
            0.08
        )

    end)

end

-- ============================================================================
-- TOGGLE
-- ============================================================================

local function toggle(
    parent,
    name,
    callback,
    defaultValue
)

    local enabled =
        defaultValue == true

    local row = create("Frame", {

        Name =
            "Toggle_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            36
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        row,
        5
    )

    local rowStroke =
        stroke(
            row,
            Theme.Border,
            0.38
        )

    local label = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            12,
            0
        ),

        Size = UDim2.new(
            1,
            -64,
            1,
            0
        ),

        Font = Enum.Font.GothamMedium,

        Text = tostring(name),

        TextColor3 = Theme.Text,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = row
    })

    local track = create("Frame", {

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -11,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            30,
            16
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        Parent = row
    })

    corner(
        track,
        8
    )

    local trackStroke =
        stroke(
            track,
            Theme.Border,
            0.12
        )

    local knob = create("Frame", {

        AnchorPoint = Vector2.new(
            0,
            0.5
        ),

        Position = UDim2.new(
            0,
            3,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            10,
            10
        ),

        BackgroundColor3 =
            Theme.Muted,

        BorderSizePixel = 0,

        Parent = track
    })

    corner(
        knob,
        5
    )

    local hitbox = create("TextButton", {

        BackgroundTransparency = 1,

        Size = UDim2.fromScale(
            1,
            1
        ),

        Text = "",

        AutoButtonColor = false,

        Parent = row
    })

    local function render(instant)

        row.BackgroundColor3 =
            Theme.Row

        rowStroke.Color =
            Theme.Border

        label.TextColor3 =
            Theme.Text

        track.BackgroundColor3 =
            enabled
            and Theme.ToggleOn
            or Theme.Input

        trackStroke.Color =
            enabled
            and Theme.ToggleOn
            or Theme.Border

        knob.BackgroundColor3 =
            enabled
            and Theme.Text
            or Theme.Muted

        local x =
            enabled
            and 17
            or 3

        tween(
            knob,
            {
                Position = UDim2.new(
                    0,
                    x,
                    0.5,
                    0
                )
            },
            instant and 0 or 0.12
        )

    end

    hitbox.Activated:Connect(function()

        enabled = not enabled

        render(false)

        if callback then
            task.spawn(
                callback,
                enabled
            )
        end

    end)

    bindRowHover(
        hitbox,
        row,
        rowStroke
    )

    registerThemeRefresh(function()

        if row.Parent then
            render(true)
        end

    end)

    render(true)

    return row

end

-- ============================================================================
-- DROPDOWN
-- ============================================================================

local function dropdown(
    parent,
    name,
    options,
    callback,
    defaultValue
)

    local opened = false

    local selected =
        defaultValue ~= nil
        and defaultValue
        or options[1]

    local ROW_HEIGHT = 32
    local OPTION_HEIGHT = 25
    local GAP = 4

    local holder = create("Frame", {

        Name =
            "Dropdown_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            ROW_HEIGHT
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        ClipsDescendants = true,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.38
        )

    local label = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            9,
            0
        ),

        Size = UDim2.new(
            0.47,
            -8,
            0,
            ROW_HEIGHT
        ),

        Font = Enum.Font.GothamSemibold,

        Text = tostring(name),

        TextColor3 = Theme.Text,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = holder
    })

    local valueBox = create("Frame", {

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -6,
            0,
            ROW_HEIGHT / 2
        ),

        Size = UDim2.new(
            0.50,
            -4,
            0,
            22
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        Parent = holder
    })

    corner(
        valueBox,
        3
    )

    local valueStroke =
        stroke(
            valueBox,
            Theme.Border,
            0.28
        )

    local valueLabel = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            7,
            0
        ),

        Size = UDim2.new(
            1,
            -27,
            1,
            0
        ),

        Font = Enum.Font.GothamSemibold,

        Text =
            selected
            and tostring(selected)
            or "None",

        TextColor3 = Theme.Muted,

        TextSize = 10,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = valueBox
    })

    local arrow = create("TextLabel", {

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -5,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            13,
            18
        ),

        BackgroundTransparency = 1,

        Text = "v",

        TextColor3 = Theme.Muted,

        Font = Enum.Font.GothamBold,

        TextSize = 10,

        Parent = valueBox
    })

    local headerButton = create("TextButton", {

        BackgroundTransparency = 1,

        Size = UDim2.new(
            1,
            0,
            0,
            ROW_HEIGHT
        ),

        Text = "",

        AutoButtonColor = false,

        Parent = holder
    })

    local optionsPanel = create("Frame", {

        Position = UDim2.fromOffset(
            5,
            ROW_HEIGHT + GAP
        ),

        Size = UDim2.new(
            1,
            -10,
            0,
            (#options * OPTION_HEIGHT) + 6
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        Parent = holder
    })

    corner(
        optionsPanel,
        3
    )

    local panelStroke =
        stroke(
            optionsPanel,
            Theme.Border,
            0.22
        )

    create("UIPadding", {

        PaddingTop = UDim.new(
            0,
            3
        ),

        PaddingBottom = UDim.new(
            0,
            3
        ),

        Parent = optionsPanel
    })

    create("UIListLayout", {

        SortOrder =
            Enum.SortOrder.LayoutOrder,

        Parent = optionsPanel
    })

    local optionRows = {}

    local function refreshOptions()

        for option, data in pairs(optionRows) do

            local active =
                option == selected

            data.Button.BackgroundColor3 =
                active
                and Theme.RowHover
                or Theme.Input

            data.Label.TextColor3 =
                active
                and Theme.Text
                or Theme.Muted

            data.Check.Text =
                active
                and "✓"
                or ""

            data.Check.TextColor3 =
                Theme.Text

        end

    end

    local function setOpen(value)

        opened = value == true

        arrow.Text =
            opened
            and "^"
            or "v"

        local expandedHeight =
            ROW_HEIGHT
            + GAP
            + (#options * OPTION_HEIGHT)
            + 10

        tween(
            holder,
            {
                Size = UDim2.new(
                    1,
                    0,
                    0,
                    opened
                    and expandedHeight
                    or ROW_HEIGHT
                )
            },
            0.12
        )

    end

    for index, option in ipairs(options) do

        local optionButton = create("TextButton", {

            Name =
                "Option" ..
                index,

            Size = UDim2.new(
                1,
                0,
                0,
                OPTION_HEIGHT
            ),

            BackgroundColor3 =
                Theme.Input,

            BorderSizePixel = 0,

            Text = "",

            AutoButtonColor = false,

            Parent = optionsPanel
        })

        local optionLabel = create("TextLabel", {

            Position = UDim2.fromOffset(
                8,
                0
            ),

            Size = UDim2.new(
                1,
                -34,
                1,
                0
            ),

            BackgroundTransparency = 1,

            Text = tostring(option),

            TextColor3 =
                Theme.Muted,

            TextSize = 10,

            Font = Enum.Font.GothamSemibold,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            Parent = optionButton
        })

        local check = create("TextLabel", {

            AnchorPoint = Vector2.new(
                1,
                0.5
            ),

            Position = UDim2.new(
                1,
                -8,
                0.5,
                0
            ),

            Size = UDim2.fromOffset(
                14,
                14
            ),

            BackgroundTransparency = 1,

            Text = "",

            TextColor3 =
                Theme.Text,

            TextSize = 11,

            Font = Enum.Font.GothamBold,

            Parent = optionButton
        })

        optionRows[option] = {

            Button = optionButton,

            Label = optionLabel,

            Check = check
        }

        optionButton.Activated:Connect(function()

            selected = option

            valueLabel.Text =
                tostring(option)

            refreshOptions()

            setOpen(false)

            if callback then
                task.spawn(
                    callback,
                    option
                )
            end

        end)

        optionButton.MouseEnter:Connect(function()

            if selected ~= option then

                tween(
                    optionButton,
                    {
                        BackgroundColor3 =
                            Theme.RowHover
                    },
                    0.07
                )

                tween(
                    optionLabel,
                    {
                        TextColor3 =
                            Theme.Text
                    },
                    0.07
                )

            end

        end)

        optionButton.MouseLeave:Connect(
            refreshOptions
        )

    end

    headerButton.Activated:Connect(function()

        setOpen(
            not opened
        )

    end)

    bindRowHover(
        headerButton,
        holder,
        holderStroke
    )

    registerThemeRefresh(function()

        if holder.Parent then

            holder.BackgroundColor3 =
                Theme.Row

            holderStroke.Color =
                Theme.Border

            label.TextColor3 =
                Theme.Text

            valueBox.BackgroundColor3 =
                Theme.Input

            valueStroke.Color =
                Theme.Border

            valueLabel.TextColor3 =
                Theme.Muted

            arrow.TextColor3 =
                Theme.Muted

            optionsPanel.BackgroundColor3 =
                Theme.Input

            panelStroke.Color =
                Theme.Border

            refreshOptions()

        end

    end)

    refreshOptions()

    return holder

end

-- ============================================================================
-- MULTI DROPDOWN
-- ============================================================================

local function multiDropdown(
    parent,
    name,
    options,
    callback,
    defaults
)

    local opened = false

    local selected = {}

    local optionRows = {}

    local ROW_HEIGHT = 32
    local OPTION_HEIGHT = 25
    local GAP = 4

    if defaults == "All" then

        for _, option in ipairs(options) do
            selected[option] = true
        end

    elseif type(defaults) == "table" then

        for key, value in pairs(defaults) do

            if type(key) == "number"
                and type(value) == "string" then

                selected[value] = true

            elseif type(key) == "string"
                and value == true then

                selected[key] = true

            end

        end

    end

    local holder = create("Frame", {

        Name =
            "MultiDropdown_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            ROW_HEIGHT
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        ClipsDescendants = true,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.38
        )

    local label = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            9,
            0
        ),

        Size = UDim2.new(
            0.47,
            -8,
            0,
            ROW_HEIGHT
        ),

        Font = Enum.Font.GothamSemibold,

        Text = tostring(name),

        TextColor3 = Theme.Text,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = holder
    })

    local valueBox = create("Frame", {

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -6,
            0,
            ROW_HEIGHT / 2
        ),

        Size = UDim2.new(
            0.50,
            -4,
            0,
            22
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        Parent = holder
    })

    corner(
        valueBox,
        3
    )

    local valueStroke =
        stroke(
            valueBox,
            Theme.Border,
            0.28
        )

    local valueLabel = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            7,
            0
        ),

        Size = UDim2.new(
            1,
            -27,
            1,
            0
        ),

        Font = Enum.Font.GothamSemibold,

        Text = "None",

        TextColor3 =
            Theme.Muted,

        TextSize = 10,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = valueBox
    })

    local arrow = create("TextLabel", {

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -5,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            13,
            18
        ),

        BackgroundTransparency = 1,

        Text = "v",

        TextColor3 =
            Theme.Muted,

        Font = Enum.Font.GothamBold,

        TextSize = 10,

        Parent = valueBox
    })

    local headerButton = create("TextButton", {

        BackgroundTransparency = 1,

        Size = UDim2.new(
            1,
            0,
            0,
            ROW_HEIGHT
        ),

        Text = "",

        AutoButtonColor = false,

        Parent = holder
    })

    local totalRows =
        #options + 1

    local optionsPanel = create("Frame", {

        Position = UDim2.fromOffset(
            5,
            ROW_HEIGHT + GAP
        ),

        Size = UDim2.new(
            1,
            -10,
            0,
            (totalRows * OPTION_HEIGHT) + 6
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        Parent = holder
    })

    corner(
        optionsPanel,
        3
    )

    local panelStroke =
        stroke(
            optionsPanel,
            Theme.Border,
            0.22
        )

    create("UIPadding", {

        PaddingTop = UDim.new(
            0,
            3
        ),

        PaddingBottom = UDim.new(
            0,
            3
        ),

        Parent = optionsPanel
    })

    create("UIListLayout", {

        SortOrder =
            Enum.SortOrder.LayoutOrder,

        Parent = optionsPanel
    })

    local function snapshot()

        local values = {}

        for _, option in ipairs(options) do

            if selected[option] then
                table.insert(
                    values,
                    option
                )
            end

        end

        return values

    end

    local function isAllSelected()

        if #options == 0 then
            return false
        end

        for _, option in ipairs(options) do

            if not selected[option] then
                return false
            end

        end

        return true

    end

    local allRow

    local function refresh()

        local values =
            snapshot()

        if isAllSelected() then

            valueLabel.Text = "All"

        elseif #values == 0 then

            valueLabel.Text = "None"

        elseif #values == 1 then

            valueLabel.Text =
                tostring(values[1])

        else

            valueLabel.Text =
                tostring(#values)
                .. " selected"

        end

        if allRow then

            local activeAll =
                isAllSelected()

            allRow.Button.BackgroundColor3 =
                activeAll
                and Theme.RowHover
                or Theme.Input

            allRow.Label.TextColor3 =
                activeAll
                and Theme.Text
                or Theme.Muted

            allRow.Fill.BackgroundTransparency =
                activeAll
                and 0
                or 1

            allRow.BoxStroke.Color =
                activeAll
                and Theme.ToggleOn
                or Theme.BorderBright

        end

        for option, data in pairs(optionRows) do

            local active =
                selected[option] == true

            data.Button.BackgroundColor3 =
                active
                and Theme.RowHover
                or Theme.Input

            data.Label.TextColor3 =
                active
                and Theme.Text
                or Theme.Muted

            data.Fill.BackgroundColor3 =
                Theme.ToggleOn

            data.Fill.BackgroundTransparency =
                active
                and 0
                or 1

            data.Box.BackgroundColor3 =
                Theme.Input

            data.BoxStroke.Color =
                active
                and Theme.ToggleOn
                or Theme.BorderBright

        end

    end

    local function setOpen(value)

        opened = value == true

        arrow.Text =
            opened
            and "^"
            or "v"

        local expandedHeight =
            ROW_HEIGHT
            + GAP
            + (totalRows * OPTION_HEIGHT)
            + 10

        tween(
            holder,
            {
                Size = UDim2.new(
                    1,
                    0,
                    0,
                    opened
                    and expandedHeight
                    or ROW_HEIGHT
                )
            },
            0.12
        )

    end

    local function createCheckRow(
        text,
        order,
        onClick
    )

        local optionButton = create(
            "TextButton",
            {

                Name =
                    "Option" ..
                    order,

                LayoutOrder = order,

                Size = UDim2.new(
                    1,
                    0,
                    0,
                    OPTION_HEIGHT
                ),

                BackgroundColor3 =
                    Theme.Input,

                BorderSizePixel = 0,

                Text = "",

                AutoButtonColor = false,

                Parent = optionsPanel
            }
        )

        local optionLabel =
            create(
                "TextLabel",
                {

                    Position =
                        UDim2.fromOffset(
                            8,
                            0
                        ),

                    Size = UDim2.new(
                        1,
                        -38,
                        1,
                        0
                    ),

                    BackgroundTransparency =
                        1,

                    Text =
                        tostring(text),

                    TextColor3 =
                        Theme.Muted,

                    TextSize = 10,

                    Font =
                        Enum.Font.GothamSemibold,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    Parent =
                        optionButton
                }
            )

        local box = create("Frame", {

            AnchorPoint =
                Vector2.new(
                    1,
                    0.5
                ),

            Position = UDim2.new(
                1,
                -8,
                0.5,
                0
            ),

            Size = UDim2.fromOffset(
                13,
                13
            ),

            BackgroundColor3 =
                Theme.Input,

            BorderSizePixel = 0,

            Parent =
                optionButton
        })

        corner(
            box,
            2
        )

        local boxStroke =
            stroke(
                box,
                Theme.BorderBright,
                0.15
            )

        local fill = create("Frame", {

            AnchorPoint =
                Vector2.new(
                    0.5,
                    0.5
                ),

            Position =
                UDim2.fromScale(
                    0.5,
                    0.5
                ),

            Size = UDim2.fromOffset(
                6,
                6
            ),

            BackgroundColor3 =
                Theme.ToggleOn,

            BackgroundTransparency = 1,

            BorderSizePixel = 0,

            Parent = box
        })

        corner(
            fill,
            1
        )

        optionButton.Activated:Connect(
            onClick
        )

        optionButton.MouseEnter:Connect(
            function()

                tween(
                    optionButton,
                    {
                        BackgroundColor3 =
                            Theme.RowHover
                    },
                    0.07
                )

                tween(
                    optionLabel,
                    {
                        TextColor3 =
                            Theme.Text
                    },
                    0.07
                )

            end
        )

        optionButton.MouseLeave:Connect(
            refresh
        )

        return {

            Button =
                optionButton,

            Label =
                optionLabel,

            Box =
                box,

            BoxStroke =
                boxStroke,

            Fill =
                fill
        }

    end

    allRow =
        createCheckRow(
            "All",
            0,
            function()

                local selectAll =
                    not isAllSelected()

                for _, option in ipairs(options) do

                    selected[option] =
                        selectAll
                        or nil

                end

                refresh()

                if callback then

                    task.spawn(
                        callback,
                        snapshot(),
                        isAllSelected()
                    )

                end

            end
        )

    for index, option in ipairs(options) do

        optionRows[option] =
            createCheckRow(
                option,
                index,
                function()

                    selected[option] =
                        not selected[option]
                        or nil

                    refresh()

                    if callback then

                        task.spawn(
                            callback,
                            snapshot(),
                            isAllSelected()
                        )

                    end

                end
            )

    end

    headerButton.Activated:Connect(
        function()

            setOpen(
                not opened
            )

        end
    )

    bindRowHover(
        headerButton,
        holder,
        holderStroke
    )

    registerThemeRefresh(
        function()

            if holder.Parent then

                holder.BackgroundColor3 =
                    Theme.Row

                holderStroke.Color =
                    Theme.Border

                label.TextColor3 =
                    Theme.Text

                valueBox.BackgroundColor3 =
                    Theme.Input

                valueStroke.Color =
                    Theme.Border

                valueLabel.TextColor3 =
                    Theme.Muted

                arrow.TextColor3 =
                    Theme.Muted

                optionsPanel.BackgroundColor3 =
                    Theme.Input

                panelStroke.Color =
                    Theme.Border

                refresh()

            end

        end
    )

    refresh()

    return holder

end

-- ============================================================================
-- SLIDER
-- ============================================================================

local function slider(
    parent,
    name,
    minimum,
    maximum,
    defaultValue,
    step,
    callback
)

    minimum =
        tonumber(minimum)
        or 0

    maximum =
        math.max(
            tonumber(maximum)
                or minimum + 1,
            minimum + 0.0001
        )

    step =
        math.max(
            tonumber(step)
                or 1,
            0.0001
        )

    local value =
        math.clamp(
            tonumber(defaultValue)
                or minimum,
            minimum,
            maximum
        )

    local dragging = false

    local holder = create("Frame", {

        Name =
            "Slider_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            48
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.35
        )

    local label = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            9,
            0
        ),

        Size = UDim2.new(
            1,
            -58,
            0,
            25
        ),

        Font =
            Enum.Font.GothamSemibold,

        Text =
            tostring(name),

        TextColor3 =
            Theme.Text,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = holder
    })

    local valueLabel = create("TextLabel", {

        AnchorPoint =
            Vector2.new(
                1,
                0
            ),

        BackgroundTransparency = 1,

        Position = UDim2.new(
            1,
            -9,
            0,
            0
        ),

        Size = UDim2.fromOffset(
            48,
            25
        ),

        Font =
            Enum.Font.GothamBold,

        Text =
            tostring(value),

        TextColor3 =
            Theme.Muted,

        TextSize = 10,

        TextXAlignment =
            Enum.TextXAlignment.Right,

        Parent = holder
    })

    local bar = create("Frame", {

        Position = UDim2.fromOffset(
            10,
            32
        ),

        Size = UDim2.new(
            1,
            -20,
            0,
            3
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        Parent = holder
    })

    corner(
        bar,
        2
    )

    local fill = create("Frame", {

        Size =
            UDim2.fromScale(
                0,
                1
            ),

        BackgroundColor3 =
            Theme.ToggleOn,

        BorderSizePixel = 0,

        Parent = bar
    })

    corner(
        fill,
        2
    )

    local hitbox = create("TextButton", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            5,
            23
        ),

        Size = UDim2.new(
            1,
            -10,
            0,
            18
        ),

        Text = "",

        AutoButtonColor = false,

        Parent = holder
    })

    local function render()

        local alpha =
            (value - minimum)
            / (maximum - minimum)

        fill.Size =
            UDim2.fromScale(
                alpha,
                1
            )

        if math.abs(
            value
            - math.floor(
                value + 0.5
            )
        ) < 0.0001 then

            valueLabel.Text =
                tostring(
                    math.floor(
                        value + 0.5
                    )
                )

        else

            valueLabel.Text =
                string.format(
                    "%.2f",
                    value
                )

        end

    end

    local function setFromX(
        x,
        fireCallback
    )

        local width =
            math.max(
                bar.AbsoluteSize.X,
                1
            )

        local alpha =
            math.clamp(
                (
                    x
                    - bar.AbsolutePosition.X
                )
                / width,
                0,
                1
            )

        local raw =
            minimum
            + (
                maximum
                - minimum
            )
            * alpha

        value =
            math.clamp(
                math.floor(
                    (
                        raw
                        - minimum
                    )
                    / step
                    + 0.5
                )
                * step
                + minimum,
                minimum,
                maximum
            )

        render()

        if fireCallback
            and callback then

            task.spawn(
                callback,
                value
            )

        end

    end

    hitbox.InputBegan:Connect(
        function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true

                setFromX(
                    input.Position.X,
                    true
                )

            end

        end
    )

    UserInputService.InputChanged:Connect(
        function(input)

            if dragging
                and (
                    input.UserInputType ==
                        Enum.UserInputType.MouseMovement
                    or input.UserInputType ==
                        Enum.UserInputType.Touch
                ) then

                setFromX(
                    input.Position.X,
                    true
                )

            end

        end
    )

    UserInputService.InputEnded:Connect(
        function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = false

            end

        end
    )

    registerThemeRefresh(
        function()

            if holder.Parent then

                holder.BackgroundColor3 =
                    Theme.Row

                holderStroke.Color =
                    Theme.Border

                label.TextColor3 =
                    Theme.Text

                valueLabel.TextColor3 =
                    Theme.Muted

                bar.BackgroundColor3 =
                    Theme.Input

                fill.BackgroundColor3 =
                    Theme.ToggleOn

            end

        end
    )

    render()

    return holder

end

-- ============================================================================
-- NUMBER BOX
-- ============================================================================

local function numberBox(
    parent,
    name,
    defaultValue,
    callback
)

    local holder = create("Frame", {

        Name =
            "NumberBox_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            48
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.35
        )

    local label = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            9,
            0
        ),

        Size = UDim2.new(
            1,
            -18,
            0,
            22
        ),

        Font =
            Enum.Font.GothamSemibold,

        Text =
            tostring(name),

        TextColor3 =
            Theme.Text,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        Parent = holder
    })

    local box = create("TextBox", {

        Position = UDim2.fromOffset(
            7,
            23
        ),

        Size = UDim2.new(
            1,
            -14,
            0,
            20
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        ClearTextOnFocus = false,

        Font =
            Enum.Font.GothamSemibold,

        Text =
            tostring(
                defaultValue
                or 0
            ),

        TextColor3 =
            Theme.Text,

        PlaceholderText = "0",

        PlaceholderColor3 =
            Theme.Placeholder,

        TextSize = 10,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        Parent = holder
    })

    corner(
        box,
        3
    )

    box.FocusLost:Connect(
        function()

            local value =
                tonumber(
                    box.Text
                )
                or 0

            box.Text =
                tostring(value)

            if callback then

                task.spawn(
                    callback,
                    value
                )

            end

        end
    )

    registerThemeRefresh(
        function()

            if holder.Parent then

                holder.BackgroundColor3 =
                    Theme.Row

                holderStroke.Color =
                    Theme.Border

                label.TextColor3 =
                    Theme.Text

                box.BackgroundColor3 =
                    Theme.Input

                box.TextColor3 =
                    Theme.Text

                box.PlaceholderColor3 =
                    Theme.Placeholder

            end

        end
    )

    return holder

end

-- ============================================================================
-- TEXT BOX
-- ============================================================================

local function textBox(
    parent,
    name,
    placeholder,
    callback
)

    local holder = create("Frame", {

        Name =
            "TextBox_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            48
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.35
        )

    local label = create("TextLabel", {

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(
            9,
            0
        ),

        Size = UDim2.new(
            1,
            -18,
            0,
            22
        ),

        Font =
            Enum.Font.GothamSemibold,

        Text =
            tostring(name),

        TextColor3 =
            Theme.Text,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = holder
    })

    local box = create("TextBox", {

        Position = UDim2.fromOffset(
            7,
            23
        ),

        Size = UDim2.new(
            1,
            -14,
            0,
            20
        ),

        BackgroundColor3 =
            Theme.Input,

        BorderSizePixel = 0,

        ClearTextOnFocus = false,

        Font =
            Enum.Font.GothamSemibold,

        Text = "",

        TextColor3 =
            Theme.Text,

        PlaceholderText =
            tostring(
                placeholder
                or ""
            ),

        PlaceholderColor3 =
            Theme.Placeholder,

        TextSize = 10,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        Parent = holder
    })

    corner(
        box,
        3
    )

    box.FocusLost:Connect(
        function()

            if callback then

                task.spawn(
                    callback,
                    box.Text
                )

            end

        end
    )

    registerThemeRefresh(
        function()

            if holder.Parent then

                holder.BackgroundColor3 =
                    Theme.Row

                holderStroke.Color =
                    Theme.Border

                label.TextColor3 =
                    Theme.Text

                box.BackgroundColor3 =
                    Theme.Input

                box.TextColor3 =
                    Theme.Text

                box.PlaceholderColor3 =
                    Theme.Placeholder

            end

        end
    )

    return holder

end

-- ============================================================================
-- INFO CARD
-- ============================================================================

local function infoCard(
    parent,
    text,
    height,
    textColor
)

    local holder = create("Frame", {

        Size = UDim2.new(
            1,
            0,
            0,
            height or 46
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.35
        )

    local label = create("TextLabel", {

        Position = UDim2.fromOffset(
            9,
            0
        ),

        Size = UDim2.new(
            1,
            -18,
            1,
            0
        ),

        BackgroundTransparency = 1,

        Text =
            tostring(
                text or ""
            ),

        TextWrapped = true,

        TextColor3 =
            textColor
            or Theme.Text,

        Font =
            Enum.Font.GothamSemibold,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextYAlignment =
            Enum.TextYAlignment.Center,

        Parent = holder
    })

    registerThemeRefresh(
        function()

            if holder.Parent then

                holder.BackgroundColor3 =
                    Theme.Row

                holderStroke.Color =
                    Theme.Border

                if not textColor then

                    label.TextColor3 =
                        Theme.Text

                end

            end

        end
    )

    return label

end

-- ============================================================================
-- FEATURE CARD
-- ============================================================================

local function featureCard(
    parent,
    titleText,
    items
)

    local itemHeight = 18

    local height =
        31
        + (#items * itemHeight)
        + 8

    local holder = create("Frame", {

        Size = UDim2.new(
            1,
            0,
            0,
            height
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        holder,
        5
    )

    local holderStroke =
        stroke(
            holder,
            Theme.Border,
            0.32
        )

    local titleLabel = create(
        "TextLabel",
        {

            Position =
                UDim2.fromOffset(
                    11,
                    7
                ),

            Size =
                UDim2.new(
                    1,
                    -22,
                    0,
                    17
                ),

            BackgroundTransparency =
                1,

            Text =
                string.upper(
                    tostring(
                        titleText
                        or "FEATURES"
                    )
                ),

            TextColor3 =
                Theme.Muted,

            Font =
                Enum.Font.GothamBold,

            TextSize = 9,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            Parent = holder
        }
    )

    local dots = {}
    local labels = {}

    for index, item in ipairs(items) do

        local y =
            29
            + (
                (index - 1)
                * itemHeight
            )

        local dot = create("Frame", {

            Position =
                UDim2.fromOffset(
                    12,
                    y + 6
                ),

            Size =
                UDim2.fromOffset(
                    4,
                    4
                ),

            BackgroundColor3 =
                Theme.Text,

            BorderSizePixel = 0,

            Parent = holder
        })

        corner(
            dot,
            3
        )

        table.insert(
            dots,
            dot
        )

        local itemLabel =
            create(
                "TextLabel",
                {

                    Position =
                        UDim2.fromOffset(
                            23,
                            y
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -34,
                            0,
                            itemHeight
                        ),

                    BackgroundTransparency =
                        1,

                    Text =
                        tostring(item),

                    TextColor3 =
                        Theme.Text,

                    Font =
                        Enum.Font.GothamSemibold,

                    TextSize = 10,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextTruncate =
                        Enum.TextTruncate.AtEnd,

                    Parent =
                        holder
                }
            )

        table.insert(
            labels,
            itemLabel
        )

    end

    registerThemeRefresh(
        function()

            if holder.Parent then

                holder.BackgroundColor3 =
                    Theme.Row

                holderStroke.Color =
                    Theme.Border

                titleLabel.TextColor3 =
                    Theme.Muted

                for _, dot in ipairs(dots) do

                    dot.BackgroundColor3 =
                        Theme.Text

                end

                for _, itemLabel in ipairs(labels) do

                    itemLabel.TextColor3 =
                        Theme.Text

                end

            end

        end
    )

    return holder

end

-- ============================================================================
-- ACTION BUTTON
-- ============================================================================

local function actionButton(
    parent,
    name,
    callback
)

    local row = create("Frame", {

        Name =
            "Button_" ..
            tostring(name),

        Size = UDim2.new(
            1,
            0,
            0,
            32
        ),

        BackgroundColor3 =
            Theme.Row,

        BackgroundTransparency =
            0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(
        row,
        5
    )

    local rowStroke =
        stroke(
            row,
            Theme.Border,
            0.38
        )

    local label = create("TextLabel", {

        Position =
            UDim2.fromOffset(
                9,
                0
            ),

        Size =
            UDim2.new(
                1,
                -34,
                1,
                0
            ),

        BackgroundTransparency = 1,

        Text =
            tostring(name),

        TextColor3 =
            Theme.Text,

        Font =
            Enum.Font.GothamSemibold,

        TextSize = 11,

        TextXAlignment =
            Enum.TextXAlignment.Left,

        TextTruncate =
            Enum.TextTruncate.AtEnd,

        Parent = row
    })

    local arrow = create("TextLabel", {

        AnchorPoint =
            Vector2.new(
                1,
                0.5
            ),

        Position =
            UDim2.new(
                1,
                -9,
                0.5,
                0
            ),

        Size =
            UDim2.fromOffset(
                14,
                18
            ),

        BackgroundTransparency = 1,

        Text = ">",

        TextColor3 =
            Theme.Muted,

        Font =
            Enum.Font.GothamBold,

        TextSize = 11,

        Parent = row
    })

    local hitbox = create("TextButton", {

        Size =
            UDim2.fromScale(
                1,
                1
            ),

        BackgroundTransparency = 1,

        Text = "",

        AutoButtonColor = false,

        Parent = row
    })

    hitbox.Activated:Connect(
        function()

            tween(
                row,
                {
                    BackgroundColor3 =
                        Theme.RowHover
                },
                0.06
            )

            task.delay(
                0.08,
                function()

                    if row.Parent then

                        tween(
                            row,
                            {
                                BackgroundColor3 =
                                    Theme.Row
                            },
                            0.08
                        )

                    end

                end
            )

            if callback then
                task.spawn(callback)
            end

        end
    )

    bindRowHover(
        hitbox,
        row,
        rowStroke
    )

    registerThemeRefresh(
        function()

            if row.Parent then

                row.BackgroundColor3 =
                    Theme.Row

                rowStroke.Color =
                    Theme.Border

                label.TextColor3 =
                    Theme.Text

                arrow.TextColor3 =
                    Theme.Muted

            end

        end
    )

    return row

end

-- ============================================================================
-- SPACER
-- ============================================================================

local function spacer(parent, height)

    return create("Frame", {

        Name = "Spacer",

        Size = UDim2.new(
            1,
            0,
            0,
            math.max(
                0,
                tonumber(height)
                or 6
            )
        ),

        BackgroundTransparency = 1,

        Parent = parent
    })

end

-- ============================================================================
-- SIDEBAR GEOMETRY
-- ============================================================================

local function updateSidebarGeometry(
    instant
)

    local sidebarWidth =
        sidebarExpanded
        and SIDEBAR_EXPANDED
        or SIDEBAR_COLLAPSED

    local sidebarTarget =
        UDim2.new(
            0,
            sidebarWidth,
            1,
            -TOPBAR_HEIGHT
        )

    local contentPosition =
        UDim2.fromOffset(
            sidebarWidth + CONTENT_GAP,
            TOPBAR_HEIGHT + CONTENT_GAP
        )

    local contentSize =
        UDim2.new(
            1,
            -(
                sidebarWidth
                + CONTENT_GAP * 2
            ),
            1,
            -(
                TOPBAR_HEIGHT
                + CONTENT_GAP * 2
            )
        )

    if instant then

        sidebar.Size =
            sidebarTarget

        content.Position =
            contentPosition

        content.Size =
            contentSize

    else

        tween(
            sidebar,
            {
                Size =
                    sidebarTarget
            },
            0.14
        )

        tween(
            content,
            {
                Position =
                    contentPosition,

                Size =
                    contentSize
            },
            0.14
        )

    end

    for _, data in pairs(sideButtons) do

        tween(
            data.Label,
            {
                TextTransparency =
                    sidebarExpanded
                    and 0
                    or 1
            },
            instant
            and 0
            or 0.1
        )

    end

end

-- ============================================================================
-- MINIMIZED FLOATING BOX
-- ============================================================================

local miniBox = create("TextButton", {

    Name = "MiniBox",

    AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        ),

    Position =
        UDim2.fromScale(
            0.5,
            0.5
        ),

    Size =
        UDim2.fromOffset(
            58,
            42
        ),

    BackgroundColor3 =
        Theme.Background,

    BackgroundTransparency =
        0.08,

    BorderSizePixel = 0,

    Text = "",

    AutoButtonColor = false,

    Visible = false,

    Active = true,

    Parent = gui
})

corner(
    miniBox,
    9
)

local miniStroke =
    stroke(
        miniBox,
        Theme.BorderBright,
        0.35
    )

local miniLogo = create("TextLabel", {

    AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        ),

    Position =
        UDim2.fromScale(
            0.5,
            0.5
        ),

    Size =
        UDim2.fromScale(
            0.9,
            0.8
        ),

    BackgroundTransparency = 1,

    Text = "ZH",

    TextColor3 =
        Theme.Text,

    Font =
        Enum.Font.GothamBold,

    TextSize = 14,

    Parent = miniBox
})

local miniDot = create("Frame", {

    AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        ),

    Position =
        UDim2.new(
            1,
            -7,
            0,
            7
        ),

    Size =
        UDim2.fromOffset(
            4,
            4
        ),

    BackgroundColor3 =
        Theme.Text,

    BorderSizePixel = 0,

    Parent = miniBox
})

corner(
    miniDot,
    4
)

-- ============================================================================
-- THEME
-- ============================================================================

local function applyTheme(name)

    if not ThemePresets[name] then
        return
    end

    currentThemeName =
        name

    Theme =
        ThemePresets[name]

    main.BackgroundColor3 =
        Theme.Background

    mainStroke.Color =
        Theme.BorderBright

    topbar.BackgroundColor3 =
        Theme.Topbar

    topbarBottom.BackgroundColor3 =
        Theme.Topbar

    sidebar.BackgroundColor3 =
        Theme.Sidebar

    sidebarLine.BackgroundColor3 =
        Theme.Border

    title.TextColor3 =
        Theme.Text

    subtitle.TextColor3 =
        Theme.Muted

    topLine.BackgroundColor3 =
        Theme.Border

    minimizeLine.BackgroundColor3 =
        Theme.Text

    close.TextColor3 =
        Theme.Text

    menuButton.TextColor3 =
        Theme.Muted

    themeCenter.BackgroundColor3 =
        Theme.Muted

    miniBox.BackgroundColor3 =
        Theme.Background

    miniStroke.Color =
        Theme.BorderBright

    miniLogo.TextColor3 =
        Theme.Text

    miniDot.BackgroundColor3 =
        Theme.Text

    for _, ray in ipairs(themeRays) do

        ray.BackgroundColor3 =
            Theme.Muted

    end

    for _, refresh in ipairs(
        themeRefreshers
    ) do

        pcall(refresh)

    end

    refreshSideTabs()

    for _, pageData in pairs(
        pages
    ) do

        refreshPageSections(
            pageData
        )

    end

end

-- ============================================================================
-- RESPONSIVE SIZE
-- ============================================================================

local function updateResponsiveSize(
    instant
)

    local camera =
        workspace.CurrentCamera

    local viewport =
        camera
        and camera.ViewportSize
        or Vector2.new(
            BASE_WIDTH + 40,
            BASE_HEIGHT + 40
        )

    local width =
        math.min(
            BASE_WIDTH,
            math.max(
                330,
                viewport.X - 20
            )
        )

    local height =
        math.min(
            BASE_HEIGHT,
            math.max(
                300,
                viewport.Y - 30
            )
        )

    local target =
        minimized

        and UDim2.fromOffset(
            width,
            TOPBAR_HEIGHT
        )

        or UDim2.fromOffset(
            width,
            height
        )

    if instant then

        main.Size =
            target

    else

        tween(
            main,
            {
                Size = target
            },
            0.14
        )

    end

    updateSidebarGeometry(
        instant
    )

end

-- ============================================================================
-- MINIMIZE / RESTORE
-- ============================================================================

local function setMinimized(value)

    minimized =
        value == true

    if minimized then

        sidebar.Visible = false
        content.Visible = false

        topbar.Visible = false

        miniBox.Visible = true

        tween(
            main,
            {
                Size = UDim2.fromOffset(
                    58,
                    42
                )
            },
            0.16
        )

        task.delay(
            0.02,
            function()

                if main.Parent
                    and minimized then

                    main.Visible = false

                end

            end
        )

    else

        main.Visible = true

        topbar.Visible = true

        sidebar.Visible = true
        content.Visible = true

        miniBox.Visible = false

        updateResponsiveSize(false)

    end

end

-- ============================================================================
-- BUTTON CONNECTIONS
-- ============================================================================

menuButton.Activated:Connect(
    function()

        sidebarExpanded =
            not sidebarExpanded

        updateSidebarGeometry(
            false
        )

    end
)

menuButton.MouseEnter:Connect(
    function()

        tween(
            menuButton,
            {
                TextColor3 =
                    Theme.Text
            },
            0.08
        )

    end
)

menuButton.MouseLeave:Connect(
    function()

        tween(
            menuButton,
            {
                TextColor3 =
                    Theme.Muted
            },
            0.08
        )

    end
)

themeButton.Activated:Connect(
    function()

        applyTheme(
            currentThemeName == "Dark"
            and "Light"
            or "Dark"
        )

    end
)

themeButton.MouseEnter:Connect(
    function()

        themeCenter.BackgroundColor3 =
            Theme.Text

        for _, ray in ipairs(
            themeRays
        ) do

            ray.BackgroundColor3 =
                Theme.Text

        end

    end
)

themeButton.MouseLeave:Connect(
    function()

        themeCenter.BackgroundColor3 =
            Theme.Muted

        for _, ray in ipairs(
            themeRays
        ) do

            ray.BackgroundColor3 =
                Theme.Muted

        end

    end
)

minimizeButton.Activated:Connect(
    function()

        setMinimized(
            not minimized
        )

    end
)

minimizeButton.MouseEnter:Connect(
    function()

        tween(
            minimizeLine,
            {
                BackgroundColor3 =
                    Theme.Muted
            },
            0.08
        )

    end
)

minimizeButton.MouseLeave:Connect(
    function()

        tween(
            minimizeLine,
            {
                BackgroundColor3 =
                    Theme.Text
            },
            0.08
        )

    end
)

close.MouseEnter:Connect(
    function()

        tween(
            close,
            {
                TextColor3 =
                    Color3.fromRGB(
                        255,
                        100,
                        100
                    )
            },
            0.08
        )

    end
)

close.MouseLeave:Connect(
    function()

        tween(
            close,
            {
                TextColor3 =
                    Theme.Text
            },
            0.08
        )

    end
)

close.Activated:Connect(
    function()

        guiAlive = false

        gui:Destroy()

    end
)

-- ============================================================================
-- MINI BOX HOVER
-- ============================================================================

miniBox.MouseEnter:Connect(
    function()

        tween(
            miniBox,
            {
                BackgroundColor3 =
                    Theme.RowHover
            },
            0.1
        )

        tween(
            miniLogo,
            {
                TextColor3 =
                    Theme.Text
            },
            0.1
        )

    end
)

miniBox.MouseLeave:Connect(
    function()

        tween(
            miniBox,
            {
                BackgroundColor3 =
                    Theme.Background
            },
            0.1
        )

    end
)

miniBox.Activated:Connect(
    function()

        setMinimized(false)

    end
)

-- ============================================================================
-- CAMERA RESIZE
-- ============================================================================

local camera =
    workspace.CurrentCamera

if camera then

    camera:GetPropertyChangedSignal(
        "ViewportSize"
    ):Connect(
        function()

            updateResponsiveSize(
                true
            )

        end
    )

end

-- ============================================================================
-- MAIN WINDOW DRAGGING
-- ============================================================================

local windowDragging = false
local windowDragStart = nil
local windowStartPosition = nil

topbar.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            windowDragging = true

            windowDragStart =
                input.Position

            windowStartPosition =
                main.Position

        end

    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if windowDragging
            and (
                input.UserInputType ==
                    Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                    Enum.UserInputType.Touch
            ) then

            local delta =
                input.Position
                - windowDragStart

            main.Position =
                UDim2.new(

                    windowStartPosition.X.Scale,

                    windowStartPosition.X.Offset
                        + delta.X,

                    windowStartPosition.Y.Scale,

                    windowStartPosition.Y.Offset
                        + delta.Y
                )

        end

    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            windowDragging = false

        end

    end
)

-- ============================================================================
-- MINI BOX DRAGGING
-- ============================================================================

local miniDragging = false
local miniDragStart = nil
local miniStartPosition = nil
local miniMoved = false

miniBox.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            miniDragging = true
            miniMoved = false

            miniDragStart =
                input.Position

            miniStartPosition =
                miniBox.Position

        end

    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if miniDragging
            and (
                input.UserInputType ==
                    Enum.UserInputType.MouseMovement
                or input.UserInputType ==
                    Enum.UserInputType.Touch
            ) then

            local delta =
                input.Position
                - miniDragStart

            if delta.Magnitude > 5 then
                miniMoved = true
            end

            miniBox.Position =
                UDim2.new(

                    miniStartPosition.X.Scale,

                    miniStartPosition.X.Offset
                        + delta.X,

                    miniStartPosition.Y.Scale,

                    miniStartPosition.Y.Offset
                        + delta.Y
                )

        end

    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            miniDragging = false

        end

    end
)

-- ============================================================================
-- LIBRARY
-- ============================================================================

local Library = {

    Version = "2.0.0",

    Themes = {
        "Dark",
        "Light"
    },

    Icons = {

        "Home",
        "Farm",
        "Events",
        "Pets",
        "Stats",
        "Gift",
        "Eye",
        "Settings"
    }
}

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TabMethods = {}
TabMethods.__index = TabMethods

local SectionMethods = {}
SectionMethods.__index = SectionMethods

-- ============================================================================
-- NORMALIZE CONFIG
-- ============================================================================

local function normalizeConfig(
    value,
    fallbackName
)

    if type(value) == "table" then
        return value
    end

    return {

        Name =
            value ~= nil
            and tostring(value)
            or fallbackName
    }

end

-- ============================================================================
-- CREATE WINDOW
-- ============================================================================

-- ============================================================================
-- BUILT-IN ZEHUB UTILITY TABS
-- ============================================================================

local function cleanSubtitle(value)

    local text = tostring(value or "")

    text = text:gsub("%s*[Ll][Ii][Tt][Ee]%s*", " ")
    text = text:gsub("%s+", " ")

    return text:match("^%s*(.-)%s*$") or ""

end

local function createUtilityCard(parent, height)

    local holder = create("Frame", {

        Size = UDim2.new(
            1,
            0,
            0,
            height or 58
        ),

        BackgroundColor3 = Theme.Row,

        BackgroundTransparency = 0.08,

        BorderSizePixel = 0,

        Parent = parent
    })

    corner(holder, 6)

    local holderStroke = stroke(
        holder,
        Theme.Border,
        0.35
    )

    registerThemeRefresh(function()

        if holder.Parent then
            holder.BackgroundColor3 = Theme.Row
            holderStroke.Color = Theme.Border
        end

    end)

    return holder

end

local function createUtilityLabel(parent, text, position, size, textSize, color, bold)

    return create("TextLabel", {

        Position = position,

        Size = size,

        BackgroundTransparency = 1,

        Text = tostring(text or ""),

        TextColor3 = color or Theme.Text,

        Font = bold and Enum.Font.GothamSemibold or Enum.Font.GothamMedium,

        TextSize = textSize or 11,

        TextXAlignment = Enum.TextXAlignment.Left,

        TextYAlignment = Enum.TextYAlignment.Center,

        TextTruncate = Enum.TextTruncate.AtEnd,

        Parent = parent
    })

end

local function createDynamicInfoCard(parent, titleText, initialText)

    local holder = createUtilityCard(parent, 58)

    local titleLabel = createUtilityLabel(
        holder,
        titleText,
        UDim2.fromOffset(13, 8),
        UDim2.new(1, -26, 0, 18),
        11,
        Theme.Text,
        true
    )

    local valueLabel = createUtilityLabel(
        holder,
        initialText,
        UDim2.fromOffset(13, 29),
        UDim2.new(1, -26, 0, 18),
        10,
        Theme.Muted,
        false
    )

    registerThemeRefresh(function()

        if holder.Parent then
            titleLabel.TextColor3 = Theme.Text
            valueLabel.TextColor3 = Theme.Muted
        end

    end)

    return {
        Root = holder,
        Title = titleLabel,
        Value = valueLabel
    }

end

local infoUserCard
local infoAvatarCard

local function addBuiltInTabs(window)

    local state = {
        HideUsername = false,
        HideAvatar = false
    }

    local profileTab = window:CreateTab({
        Name = "Profile",
        Icon = "Profile"
    })

    local profileSection = profileTab:CreateSection({
        Name = "Profile"
    })

    local profileCard = createUtilityCard(profileSection.Root, 76)

    local avatar = create("ImageLabel", {

        Position = UDim2.fromOffset(12, 12),

        Size = UDim2.fromOffset(52, 52),

        BackgroundColor3 = Theme.Input,

        BackgroundTransparency = 0.05,

        BorderSizePixel = 0,

        Image = "",

        ScaleType = Enum.ScaleType.Crop,

        Parent = profileCard
    })

    corner(avatar, 8)

    local avatarStroke = stroke(
        avatar,
        Theme.Border,
        0.25
    )

    local displayLabel = createUtilityLabel(
        profileCard,
        "",
        UDim2.fromOffset(76, 14),
        UDim2.new(1, -90, 0, 20),
        12,
        Theme.Text,
        true
    )

    local usernameLabel = createUtilityLabel(
        profileCard,
        "",
        UDim2.fromOffset(76, 37),
        UDim2.new(1, -90, 0, 18),
        10,
        Theme.Muted,
        false
    )

    local hideUsernameToggle = profileSection:CreateToggle({
        Name = "Hide Username",
        Default = false,
        Callback = function(value)
            state.HideUsername = value == true

            if state.HideUsername then
                usernameLabel.Text = "Username hidden"
                displayLabel.Text = "ZeHub Player"
            else
                usernameLabel.Text = "@" .. tostring(player.Name)
                displayLabel.Text = tostring(player.DisplayName or player.Name)
            end

            local status = infoUserCard
            if status then
                status.Value.Text = state.HideUsername and "Username hidden" or ("@" .. tostring(player.Name))
            end
        end
    })

    local hideAvatarToggle = profileSection:CreateToggle({
        Name = "Hide Avatar",
        Default = false,
        Callback = function(value)
            state.HideAvatar = value == true
            avatar.ImageTransparency = state.HideAvatar and 1 or 0

            if state.HideAvatar then
                avatar.BackgroundColor3 = Theme.Input
            end

            if infoAvatarCard then
                infoAvatarCard.Value.Text = state.HideAvatar and "Avatar hidden" or "Avatar visible"
            end
        end
    })

    local profileNote = profileSection:CreateParagraph({
        Text = "Your profile privacy settings are local to this UI. Changes are reflected on the Info page immediately.",
        Height = 48
    })

    local infoTab = window:CreateTab({
        Name = "Info",
        Icon = "Info"
    })

    local infoSection = infoTab:CreateSection({
        Name = "User"
    })

    infoUserCard = createDynamicInfoCard(
        infoSection.Root,
        "User",
        "@" .. tostring(player.Name)
    )

    infoAvatarCard = createDynamicInfoCard(
        infoSection.Root,
        "Avatar",
        "Avatar visible"
    )

    local accountCard = createDynamicInfoCard(
        infoSection.Root,
        "Account",
        "User ID: " .. tostring(player.UserId)
    )

    local usefulSection = infoTab:CreateSection({
        Name = "Useful Info"
    })

    usefulSection:CreateFeatureCard({
        Title = "Useful Info",
        Items = {
            "Settings are grouped into separate tabs.",
            "Profile privacy changes update the Info page.",
            "The window supports mouse, touch and minimize controls.",
            "Theme changes are applied without rebuilding the window."
        }
    })

    usefulSection:CreateParagraph({
        Text = "ZeHub is designed around a compact glass layout with simple controls and low visual noise.",
        Height = 50
    })

    local configTab = window:CreateTab({
        Name = "Configs",
        Icon = "Settings"
    })

    local configSection = configTab:CreateSection({
        Name = "Appearance"
    })

    configSection:CreateButton({
        Name = "Toggle Theme",
        Callback = function()
            window:ToggleTheme()
        end
    })

    configSection:CreateButton({
        Name = "Expand Sidebar",
        Callback = function()
            window:SetSidebarExpanded(true)
        end
    })

    configSection:CreateButton({
        Name = "Collapse Sidebar",
        Callback = function()
            window:SetSidebarExpanded(false)
        end
    })

    configSection:CreateButton({
        Name = "Minimize Window",
        Callback = function()
            window:SetMinimized(true)
        end
    })

    configSection:CreateParagraph({
        Text = "Configuration controls affect the current window session. Your existing game controls and callbacks are not changed.",
        Height = 50
    })

    local changelogTab = window:CreateTab({
        Name = "Changelog",
        Icon = "Changelog"
    })

    local changelogSection = changelogTab:CreateSection({
        Name = "Updates"
    })

    changelogSection:CreateFeatureCard({
        Title = "Recent",
        Items = {
            "Refined glass transparency and contrast.",
            "Added Profile privacy controls.",
            "Added Configs and Info tabs.",
            "Added a compact changelog and useful info."
        }
    })

    changelogSection:CreateParagraph({
        Text = "ZeHub UI • Natural Glass edition",
        Height = 42
    })

    local function updateProfile()

        if state.HideUsername then
            displayLabel.Text = "ZeHub Player"
            usernameLabel.Text = "Username hidden"
        else
            displayLabel.Text = tostring(player.DisplayName or player.Name)
            usernameLabel.Text = "@" .. tostring(player.Name)
        end

        avatar.ImageTransparency = state.HideAvatar and 1 or 0

        infoUserCard.Value.Text = state.HideUsername
            and "Username hidden"
            or ("@" .. tostring(player.Name))

        infoAvatarCard.Value.Text = state.HideAvatar
            and "Avatar hidden"
            or "Avatar visible"

    end

    task.spawn(function()

        local ok, image = pcall(function()
            local content = Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
            return content
        end)

        if ok and image then
            avatar.Image = image
        end

        updateProfile()

    end)

    -- Keep references alive for the callbacks above.
    return {
        Profile = profileTab,
        Configs = configTab,
        Info = infoTab,
        Changelog = changelogTab
    }

end

function Library:CreateWindow(config)

    config =
        type(config) == "table"
        and config
        or {}

    if self._window
        and self._window._alive then

        self._window:SetTitle(
            config.Title
                or config.Name,
            config.Subtitle
        )

        if config.Theme then

            self._window:SetTheme(
                config.Theme
            )

        end

        gui.Enabled = true

        return self._window

    end

    BASE_WIDTH =
        math.max(
            330,
            tonumber(
                config.Width
            )
            or 500
        )

    BASE_HEIGHT =
        math.max(
            300,
            tonumber(
                config.Height
            )
            or 430
        )

    title.Text =
        tostring(
            config.Title
            or config.Name
            or "ZeHub"
        )

    subtitle.Text =
        cleanSubtitle(
            config.Subtitle
            or "UI Library"
        )

    if typeof(
        config.Position
    ) == "UDim2" then

        main.Position =
            config.Position

    end

    themeButton.Visible =
        config.ThemeButton
        ~= false

    minimizeButton.Visible =
        config.MinimizeButton
        ~= false

    close.Visible =
        config.CloseButton
        ~= false

    local window =
        setmetatable(
            {

                _alive = true,

                _tabs = {},

                Gui = gui,

                Main = main

            },
            WindowMethods
        )

    self._window =
        window

    if config.BuiltInTabs ~= false then
        addBuiltInTabs(window)

        -- Built-in tabs are added without stealing the first custom tab
        -- created by the user's existing script.
        activePageName = nil

        for _, pageData in pairs(pages) do
            pageData.Root.Visible = false
        end

        refreshSideTabs()
    end

    gui.Enabled = true

    applyTheme(
        ThemePresets[
            config.Theme
        ]
        and config.Theme
        or "Dark"
    )

    updateResponsiveSize(
        true
    )

    return window

end

-- ============================================================================
-- WINDOW METHODS
-- ============================================================================

function WindowMethods:SetTitle(
    newTitle,
    newSubtitle
)

    if newTitle ~= nil then

        title.Text =
            tostring(
                newTitle
            )

    end

    if newSubtitle ~= nil then

        subtitle.Text =
            cleanSubtitle(
                newSubtitle
            )

    end

    return self

end

function WindowMethods:SetTheme(
    themeName
)

    if ThemePresets[
        themeName
    ] then

        applyTheme(
            themeName
        )

    end

    return self

end

function WindowMethods:ToggleTheme()

    applyTheme(
        currentThemeName == "Dark"
        and "Light"
        or "Dark"
    )

    return self

end

function WindowMethods:SetMinimized(
    value
)

    setMinimized(
        value
    )

    return self

end

function WindowMethods:SetSidebarExpanded(
    value
)

    sidebarExpanded =
        value == true

    updateSidebarGeometry(
        false
    )

    return self

end

function WindowMethods:SelectTab(
    name
)

    selectPage(
        tostring(name)
    )

    return self

end

-- ============================================================================
-- CREATE TAB
-- ============================================================================

function WindowMethods:CreateTab(
    config
)

    config =
        normalizeConfig(
            config,
            "Tab"
        )

    local name =
        tostring(
            config.Name
            or "Tab"
        )

    local icon =
        config.Icon
        or config.IconType
        or name

    if self._tabs[name] then
        return self._tabs[name]
    end

    local pageData =
        createPage(
            name,
            icon
        )

    local tab =
        setmetatable(
            {

                Name = name,

                _page = pageData,

                _sections = {},

                Window = self

            },
            TabMethods
        )

    self._tabs[name] =
        tab

    if not activePageName then

        selectPage(
            name
        )

    end

    return tab

end

-- ============================================================================
-- DESTROY
-- ============================================================================

function WindowMethods:Destroy()

    if not self._alive then
        return
    end

    self._alive = false

    guiAlive = false

    if gui
        and gui.Parent then

        gui:Destroy()

    end

end

-- ============================================================================
-- TAB METHODS
-- ============================================================================

function TabMethods:Select()

    selectPage(
        self.Name
    )

    return self

end

function TabMethods:CreateSection(
    config
)

    config =
        normalizeConfig(
            config,
            "Section"
        )

    local name =
        tostring(
            config.Name
            or "Section"
        )

    if self._sections[name] then
        return self._sections[name]
    end

    local root =
        createSection(
            self._page,
            name
        )

    local section =
        setmetatable(
            {

                Name = name,

                Root = root,

                Tab = self

            },
            SectionMethods
        )

    self._sections[name] =
        section

    return section

end

-- ============================================================================
-- SECTION METHODS
-- ============================================================================

function SectionMethods:CreateToggle(
    config
)

    config =
        normalizeConfig(
            config,
            "Toggle"
        )

    return toggle(

        self.Root,

        config.Name
            or "Toggle",

        config.Callback,

        config.Default
    )

end

function SectionMethods:CreateButton(
    config
)

    config =
        normalizeConfig(
            config,
            "Button"
        )

    return actionButton(

        self.Root,

        config.Name
            or "Button",

        config.Callback
    )

end

function SectionMethods:CreateDropdown(
    config
)

    config =
        normalizeConfig(
            config,
            "Dropdown"
        )

    return dropdown(

        self.Root,

        config.Name
            or "Dropdown",

        config.Options
            or config.Values
            or {},

        config.Callback,

        config.Default
    )

end

function SectionMethods:CreateMultiDropdown(
    config
)

    config =
        normalizeConfig(
            config,
            "Multi Dropdown"
        )

    return multiDropdown(

        self.Root,

        config.Name
            or "Multi Dropdown",

        config.Options
            or config.Values
            or {},

        config.Callback,

        config.Default
            or config.Defaults
    )

end

function SectionMethods:CreateSlider(
    config
)

    config =
        normalizeConfig(
            config,
            "Slider"
        )

    return slider(

        self.Root,

        config.Name
            or "Slider",

        config.Min
            or config.Minimum
            or 0,

        config.Max
            or config.Maximum
            or 100,

        config.Default
            or config.Value
            or 0,

        config.Step
            or 1,

        config.Callback
    )

end

function SectionMethods:CreateNumberBox(
    config
)

    config =
        normalizeConfig(
            config,
            "Number"
        )

    return numberBox(

        self.Root,

        config.Name
            or "Number",

        config.Default
            or config.Value
            or 0,

        config.Callback
    )

end

function SectionMethods:CreateInput(
    config
)

    config =
        normalizeConfig(
            config,
            "Input"
        )

    return textBox(

        self.Root,

        config.Name
            or "Input",

        config.Placeholder
            or "",

        config.Callback
    )

end

SectionMethods.CreateTextBox =
    SectionMethods.CreateInput

function SectionMethods:CreateParagraph(
    config
)

    if type(config) ~= "table" then

        config = {
            Text =
                tostring(
                    config
                    or ""
                )
        }

    end

    return infoCard(

        self.Root,

        config.Text
            or config.Content
            or "",

        config.Height
            or 46,

        config.TextColor
    )

end

SectionMethods.CreateInfo =
    SectionMethods.CreateParagraph

SectionMethods.CreateLabel =
    SectionMethods.CreateParagraph

function SectionMethods:CreateFeatureCard(
    config
)

    config =
        type(config) == "table"
        and config
        or {}

    return featureCard(

        self.Root,

        config.Title
            or config.Name
            or "Features",

        config.Items
            or {}
    )

end

function SectionMethods:CreateSpacer(
    height
)

    return spacer(
        self.Root,
        height
    )

end

-- ============================================================================
-- API ALIASES
-- ============================================================================

WindowMethods.AddTab =
    WindowMethods.CreateTab

TabMethods.AddSection =
    TabMethods.CreateSection

SectionMethods.AddToggle =
    SectionMethods.CreateToggle

SectionMethods.AddButton =
    SectionMethods.CreateButton

SectionMethods.AddDropdown =
    SectionMethods.CreateDropdown

SectionMethods.AddMultiDropdown =
    SectionMethods.CreateMultiDropdown

SectionMethods.AddSlider =
    SectionMethods.CreateSlider

SectionMethods.AddNumberBox =
    SectionMethods.CreateNumberBox

SectionMethods.AddInput =
    SectionMethods.CreateInput

SectionMethods.AddParagraph =
    SectionMethods.CreateParagraph

SectionMethods.AddFeatureCard =
    SectionMethods.CreateFeatureCard

-- ============================================================================
-- INITIAL THEME
-- ============================================================================

applyTheme("Dark")

updateResponsiveSize(true)

-- ============================================================================
-- RETURN LIBRARY
-- ============================================================================

return Library
end)()

-- ZeHub UI is loaded above; no separate WindUI window is created.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============================
-- AURA VARIABLES
-- ============================
local killAuraToggle = false
local chopAuraToggle = false
local auraRadius = 50
local currentammount = 0

-- ============================
-- TOOL DAMAGE IDs
-- ============================
local toolsDamageIDs = {
    ["Old Axe"] = "3_7367831688",
    ["Good Axe"] = "112_7367831688",
    ["Strong Axe"] = "116_7367831688",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

-- ============================
-- AUTO FEED VARIABLES
-- ============================
local autoFeedToggle = false
local selectedFood = "Carrot"
local hungerThreshold = 75
local alwaysFeedEnabledItems = {}
local alimentos = {
    "Apple",
    "Berry",
    "Carrot",
    "Cake",
    "Chili",
    "Cooked Morsel",
    "Cooked Steak"
}

-- ============================
-- ESP LISTS
-- ============================
local ie = {
    "Bandage", "Bolt", "Broken Fan", "Broken Microwave", "Cake", "Carrot", "Chair", "Coal", "Coin Stack",
    "Cooked Morsel", "Cooked Steak", "Fuel Canister", "Iron Body", "Leather Armor", "Log", "MadKit", "Metal Chair",
    "MedKit", "Old Car Engine", "Old Flashlight", "Old Radio", "Revolver", "Revolver Ammo", "Rifle", "Rifle Ammo",
    "Morsel", "Sheet Metal", "Steak", "Tyre", "Washing Machine"
}
local me = {"Bunny", "Wolf", "Alpha Wolf", "Bear", "Cultist", "Crossbow Cultist", "Alien"}

-- ============================
-- BRING LISTS
-- ============================
local junkItems = {"Tyre", "Bolt", "Broken Fan", "Broken Microwave", "Sheet Metal", "Old Radio", "Washing Machine", "Old Car Engine"}
local selectedJunkItems = {}
local fuelItems = {"Log", "Chair", "Coal", "Fuel Canister", "Oil Barrel"}
local selectedFuelItems = {}
local foodItems = {"Cake", "Cooked Steak", "Cooked Morsel", "Steak", "Morsel", "Berry", "Carrot"}
local selectedFoodItems = {}
local medicalItems = {"Bandage", "MedKit"}
local selectedMedicalItems = {}
local equipmentItems = {"Revolver", "Rifle", "Leather Body", "Iron Body", "Revolver Ammo", "Rifle Ammo", "Giant Sack", "Good Sack", "Strong Axe", "Good Axe"}
local selectedEquipmentItems = {}

-- ============================
-- CAMPFIRE VARIABLES
-- ============================
local campfireFuelItems = {"Log", "Coal", "Fuel Canister", "Oil Barrel", "Biofuel"}
local campfireDropPos = Vector3.new(0, 19, 0)

-- ============================
-- AUTO COOK VARIABLES
-- ============================
local autocookItems = {"Morsel", "Steak"}
local autoCookEnabledItems = {}
local autoCookEnabled = false

-- ============================
-- TOOL FUNCTIONS
-- ============================
local function getAnyToolWithDamageID(isChopAura)
    for toolName, damageID in pairs(toolsDamageIDs) do
        if isChopAura and toolName ~= "Old Axe" and toolName ~= "Good Axe" and toolName ~= "Strong Axe" then
            continue
        end
        local tool = LocalPlayer:FindFirstChild("Inventory") and LocalPlayer.Inventory:FindFirstChild(toolName)
        if tool then
            return tool, damageID
        end
    end
    return nil, nil
end

local function equipTool(tool)
    if tool then
        ReplicatedStorage:WaitForChild("RemoteEvents").EquipItemHandle:FireServer("FireAllClients", tool)
    end
end

local function unequipTool(tool)
    if tool then
        ReplicatedStorage:WaitForChild("RemoteEvents").UnequipItemHandle:FireServer("FireAllClients", tool)
    end
end

-- ============================
-- AURA LOOPS
-- ============================
local function killAuraLoop()
    while killAuraToggle do
        local character = LocalPlayer.Character
        if not character then
            character = LocalPlayer.CharacterAdded:Wait()
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local tool, damageID = getAnyToolWithDamageID(false)
            if tool and damageID then
                equipTool(tool)
                for _, mob in ipairs(Workspace.Characters:GetChildren()) do
                    if not killAuraToggle then break end
                    if mob:IsA("Model") then
                        local part = mob:FindFirstChildWhichIsA("BasePart")
                        if part and (part.Position - hrp.Position).Magnitude <= auraRadius then
                            pcall(function()
                                ReplicatedStorage:WaitForChild("RemoteEvents").ToolDamageObject:InvokeServer(
                                    mob,
                                    tool,
                                    damageID,
                                    CFrame.new(part.Position)
                                )
                            end)
                            task.wait(0.05)
                        end
                    end
                end
                task.wait(0.1)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end

local function chopAuraLoop()
    while chopAuraToggle do
        local character = LocalPlayer.Character
        if not character then
            character = LocalPlayer.CharacterAdded:Wait()
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local tool, baseDamageID = getAnyToolWithDamageID(true)
            if tool and baseDamageID then
                equipTool(tool)
                currentammount = currentammount + 1
                local trees = {}
                local map = Workspace:FindFirstChild("Map")
                if map then
                    if map:FindFirstChild("Foliage") then
                        for _, obj in ipairs(map.Foliage:GetChildren()) do
                            if obj:IsA("Model") and obj.Name == "Small Tree" then
                                table.insert(trees, obj)
                            end
                        end
                    end
                    if map:FindFirstChild("Landmarks") then
                        for _, obj in ipairs(map.Landmarks:GetChildren()) do
                            if obj:IsA("Model") and obj.Name == "Small Tree" then
                                table.insert(trees, obj)
                            end
                        end
                    end
                end
                
                for _, tree in ipairs(trees) do
                    if not chopAuraToggle then break end
                    local trunk = tree:FindFirstChild("Trunk")
                    if trunk and trunk:IsA("BasePart") and (trunk.Position - hrp.Position).Magnitude <= auraRadius then
                        local alreadyammount = false
                        task.spawn(function()
                            while chopAuraToggle and tree and tree.Parent and not alreadyammount do
                                alreadyammount = true
                                currentammount = currentammount + 1
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("RemoteEvents").ToolDamageObject:InvokeServer(
                                        tree,
                                        tool,
                                        tostring(currentammount) .. "_7367831688",
                                        CFrame.new(-2.962610244751, 4.5547881126404, -75.950843811035, 0.89621275663376, -1.3894891459643e-08, 0.44362446665764, -7.994568895775e-10, 1, 3.293635941759e-08, -0.44362446665764, -2.9872644802253e-08, 0.89621275663376)
                                    )
                                end)
                                task.wait(0.3)
                            end
                        end)
                    end
                end
                task.wait(0.2)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end

-- ============================
-- AUTO FEED FUNCTIONS
-- ============================
function wiki(nome)
    local c = 0
    for _, i in ipairs(Workspace.Items:GetChildren()) do
        if i.Name == nome then
            c = c + 1
        end
    end
    return c
end

function ghn()
    return math.floor(LocalPlayer.PlayerGui.Interface.StatBars.HungerBar.Bar.Size.X.Scale * 100)
end

function feed(nome)
    for _, item in ipairs(Workspace.Items:GetChildren()) do
        if item.Name == nome then
            ReplicatedStorage.RemoteEvents.RequestConsumeItem:InvokeServer(item)
            break
        end
    end
end

function notifeed(nome)
    WindUI:Notify({
        Title = "Auto Food Paused",
        Content = "The food is gone",
        Duration = 3
    })
end

-- ============================
-- ITEM MOVEMENT
-- ============================
local function moveItemToPos(item, position)
    if not item or not item:IsDescendantOf(workspace) or not item:IsA("BasePart") and not item:IsA("Model") then return end
    local part = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")) or item
    if not part or not part:IsA("BasePart") then return end

    if item:IsA("Model") and not item.PrimaryPart then
        pcall(function() item.PrimaryPart = part end)
    end

    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents").RequestStartDraggingItem:FireServer(item)
        if item:IsA("Model") then
            item:SetPrimaryPartCFrame(CFrame.new(position))
        else
            part.CFrame = CFrame.new(position)
        end
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents").StopDraggingItem:FireServer(item)
    end)
end

-- ============================
-- GET CHESTS & MOBS
-- ============================
local function getChests()
    local chests = {}
    local chestNames = {}
    local index = 1
    for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
        if item.Name:match("^Item Chest") and not item:GetAttribute("8721081708Opened") then
            table.insert(chests, item)
            table.insert(chestNames, "Chest " .. index)
            index = index + 1
        end
    end
    return chests, chestNames
end

local currentChests, currentChestNames = getChests()
local selectedChest = currentChestNames[1] or nil

local function getMobs()
    local mobs = {}
    local mobNames = {}
    local index = 1
    for _, character in ipairs(workspace:WaitForChild("Characters"):GetChildren()) do
        if character.Name:match("^Lost Child") and character:GetAttribute("Lost") == true then
            table.insert(mobs, character)
            table.insert(mobNames, character.Name)
            index = index + 1
        end
    end
    return mobs, mobNames
end

local currentMobs, currentMobNames = getMobs()
local selectedMob = currentMobNames[1] or nil

-- ============================
-- TELEPORT FUNCTIONS
-- ============================
function tp1()
	(game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart").CFrame =
CFrame.new(0.43132782, 15.77634621, -1.88620758, -0.270917892, 0.102997094, 0.957076371, 0.639657021, 0.762253821, 0.0990355015, -0.719334781, 0.639031112, -0.272391081)
end

local function tp2()
    local targetPart = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Landmarks")
        and workspace.Map.Landmarks:FindFirstChild("Stronghold")
        and workspace.Map.Landmarks.Stronghold:FindFirstChild("Functional")
        and workspace.Map.Landmarks.Stronghold.Functional:FindFirstChild("EntryDoors")
        and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors:FindFirstChild("DoorRight")
        and workspace.Map.Landmarks.Stronghold.Functional.EntryDoors.DoorRight:FindFirstChild("Model")
    if targetPart then
        local children = targetPart:GetChildren()
        local destination = children[5]
        if destination and destination:IsA("BasePart") then
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = destination.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end
end

-- ============================
-- FLY SYSTEM
-- ============================
local flyToggle = false
local flySpeed = 1
local FLYING = false
local flyKeyDown, flyKeyUp, mfly1, mfly2
local IYMouse = game:GetService("UserInputService")

local function sFLY()
    repeat task.wait() until Players.LocalPlayer and Players.LocalPlayer.Character and Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart") and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    repeat task.wait() until IYMouse
    if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect(); flyKeyUp:Disconnect() end

    local T = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local SPEED = flySpeed

    local function FLY()
        FLYING = true
        local BG = Instance.new('BodyGyro')
        local BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            while FLYING do
                task.wait()
                if not flyToggle and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
                    Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
                end
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = flySpeed
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                    SPEED = 0
                end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.Velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BV.Velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                else
                    BV.Velocity = Vector3.new(0, 0, 0)
                end
                BG.CFrame = workspace.CurrentCamera.CoordinateFrame
            end
            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()
            if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
                Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
            end
        end)
    end
    flyKeyDown = IYMouse.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local KEY = input.KeyCode.Name
            if KEY == "W" then
                CONTROL.F = flySpeed
            elseif KEY == "S" then
                CONTROL.B = -flySpeed
            elseif KEY == "A" then
                CONTROL.L = -flySpeed
            elseif KEY == "D" then 
                CONTROL.R = flySpeed
            elseif KEY == "E" then
                CONTROL.Q = flySpeed * 2
            elseif KEY == "Q" then
                CONTROL.E = -flySpeed * 2
            end
            pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
        end
    end)
    flyKeyUp = IYMouse.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local KEY = input.KeyCode.Name
            if KEY == "W" then
                CONTROL.F = 0
            elseif KEY == "S" then
                CONTROL.B = 0
            elseif KEY == "A" then
                CONTROL.L = 0
            elseif KEY == "D" then
                CONTROL.R = 0
            elseif KEY == "E" then
                CONTROL.Q = 0
            elseif KEY == "Q" then
                CONTROL.E = 0
            end
        end
    end)
    FLY()
end

local function NOFLY()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end
    if mfly1 then mfly1:Disconnect() end
    if mfly2 then mfly2:Disconnect() end
    if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
        Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

local function UnMobileFly()
    pcall(function()
        FLYING = false
        local root = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        if root:FindFirstChild("BodyVelocity") then root:FindFirstChild("BodyVelocity"):Destroy() end
        if root:FindFirstChild("BodyGyro") then root:FindFirstChild("BodyGyro"):Destroy() end
        if Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
            Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
        end
        if mfly1 then mfly1:Disconnect() end
        if mfly2 then mfly2:Disconnect() end
    end)
end

local function MobileFly()
    UnMobileFly()
    FLYING = true

    local root = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    local v3none = Vector3.new()
    local v3zero = Vector3.new(0, 0, 0)
    local v3inf = Vector3.new(9e9, 9e9, 9e9)

    local controlModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    local bv = Instance.new("BodyVelocity")
    bv.Name = "BodyVelocity"
    bv.Parent = root
    bv.MaxForce = v3zero
    bv.Velocity = v3zero

    local bg = Instance.new("BodyGyro")
    bg.Name = "BodyGyro"
    bg.Parent = root
    bg.MaxTorque = v3inf
    bg.P = 1000
    bg.D = 50

    mfly1 = Players.LocalPlayer.CharacterAdded:Connect(function()
        local newRoot = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        local newBv = Instance.new("BodyVelocity")
        newBv.Name = "BodyVelocity"
        newBv.Parent = newRoot
        newBv.MaxForce = v3zero
        newBv.Velocity = v3zero

        local newBg = Instance.new("BodyGyro")
        newBg.Name = "BodyGyro"
        newBg.Parent = newRoot
        newBg.MaxTorque = v3inf
        newBg.P = 1000
        newBg.D = 50
    end)

    mfly2 = game:GetService("RunService").RenderStepped:Connect(function()
        root = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        camera = workspace.CurrentCamera
        if Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid") and root and root:FindFirstChild("BodyVelocity") and root:FindFirstChild("BodyGyro") then
            local humanoid = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            local VelocityHandler = root:FindFirstChild("BodyVelocity")
            local GyroHandler = root:FindFirstChild("BodyGyro")

            VelocityHandler.MaxForce = v3inf
            GyroHandler.MaxTorque = v3inf
            humanoid.PlatformStand = true
            GyroHandler.CFrame = camera.CoordinateFrame
            VelocityHandler.Velocity = v3none

            local direction = controlModule:GetMoveVector()
            if direction.X > 0 then
                VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * (flySpeed * 50))
            end
            if direction.X < 0 then
                VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * (flySpeed * 50))
            end
            if direction.Z > 0 then
                VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * (flySpeed * 50))
            end
            if direction.Z < 0 then
                VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * (flySpeed * 50))
            end
        end
    end)
end

-- ============================
-- ESP SYSTEM
-- ============================
function createESPText(part, text, color)
    if part:FindFirstChild("ESPTexto") then return end

    local esp = Instance.new("BillboardGui")
    esp.Name = "ESPTexto"
    esp.Adornee = part
    esp.Size = UDim2.new(0, 100, 0, 20)
    esp.StudsOffset = Vector3.new(0, 2.5, 0)
    esp.AlwaysOnTop = true
    esp.MaxDistance = 300

    local label = Instance.new("TextLabel")
    label.Parent = esp
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255,255,0)
    label.TextStrokeTransparency = 0.2
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold

    esp.Parent = part
end

local function Aesp(nome, tipo)
    local container
    local color
    if tipo == "item" then
        container = workspace:FindFirstChild("Items")
        color = Color3.fromRGB(0, 255, 0)
    elseif tipo == "mob" then
        container = workspace:FindFirstChild("Characters")
        color = Color3.fromRGB(255, 255, 0)
    else
        return
    end
    if not container then return end

    for _, obj in ipairs(container:GetChildren()) do
        if obj.Name == nome then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                createESPText(part, obj.Name, color)
            end
        end
    end
end

local function Desp(nome, tipo)
    local container
    if tipo == "item" then
        container = workspace:FindFirstChild("Items")
    elseif tipo == "mob" then
        container = workspace:FindFirstChild("Characters")
    else
        return
    end
    if not container then return end

    for _, obj in ipairs(container:GetChildren()) do
        if obj.Name == nome then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                for _, gui in ipairs(part:GetChildren()) do
                    if gui:IsA("BillboardGui") and gui.Name == "ESPTexto" then
                        gui:Destroy()
                    end
                end
            end
        end
    end
end

local selectedItems = {}
local selectedMobs = {}
local espItemsEnabled = false
local espMobsEnabled = false
local espConnections = {}

-- ============================
-- ZEHUB WINDOW + WINDUI COMPATIBILITY ADAPTER
-- ============================
local Window = Library:CreateWindow({
    Title = "ZeHub",
    Subtitle = "99 Nights in the Forest",
    Theme = "Dark",
    Width = 500,
    Height = 430
})
local nativeSelectTab = Window.SelectTab

local function makeTab(name, icon)
    local nativeTab = Window:CreateTab({Name = name, Icon = icon})
    local tab = {}
    function tab:Section(config)
        local nativeSection = nativeTab:CreateSection({Name=(config and (config.Title or config.Name)) or "Section"})
        local section = {}
        function section:Toggle(c)
            return nativeSection:CreateToggle({Name=c.Title or c.Name, Default=c.Value, Callback=c.Callback})
        end
        function section:Button(c)
            return nativeSection:CreateButton({Name=c.Title or c.Name, Callback=c.Callback})
        end
        function section:Slider(c)
            local v=c.Value or {}
            return nativeSection:CreateSlider({Name=c.Title or c.Name, Min=v.Min or c.Min or 0,
                Max=v.Max or c.Max or 100, Default=v.Default or c.Default or 0, Step=c.Step or 1, Callback=c.Callback})
        end
        function section:Dropdown(c)
            local values=c.Values or c.Options or {}
            if c.Multi then
                return nativeSection:CreateMultiDropdown({Name=c.Title or c.Name, Options=values,
                    Default=c.Value or {}, Callback=c.Callback})
            end
            return nativeSection:CreateDropdown({Name=c.Title or c.Name, Options=values,
                Default=(type(c.Value)=="table" and c.Value[1]) or c.Value,
                Callback=function(value)
                    if c.Callback then c.Callback(type(value)=="table" and value or {value}) end
                end})
        end
        function section:Input(c)
            return nativeSection:CreateInput({Name=c.Title or c.Name, Placeholder=c.Placeholder or "", Callback=c.Callback})
        end
        return section
    end
    return tab
end
function Window:Tab(config)
    return makeTab(config.Title or config.Name or "Tab", config.Icon)
end
function Window:SelectTab(index)
    local names={"Combat","Main","Auto","ESP","Bring","Teleport","Player","Discord"}
    local name=type(index)=="number" and names[index] or index
    if name and nativeSelectTab then nativeSelectTab(self,name) end
end
local WindUI={}
function WindUI:Notify(config)
    local msg=(config and (config.Content or config.Title)) or "Notification"
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="ZeHub", Text=tostring(msg), Duration=(config and config.Duration) or 3
        })
    end)
end

-- ============================
-- DISCORD TAB
-- ============================
Discord:Section({ Title = "Join Discord Server" })
Discord:Button({
    Title = "Discord Invite",
    Desc = "Copy Invite Link",
    Locked = false,
    Callback = function()
        setclipboard("https://discord.gg/zehub")
        WindUI:Notify({
            Title = "ZeHub",
            Icon = "rbxassetid://126340148670872",
            Content = "✓ Link Copied!",
            Duration = 4
        })
    end
})

-- ============================
-- COMBAT TAB
-- ============================
Combat:Section({ Title = "Aura", Icon = "star" })

Combat:Toggle({
    Title = "Kill Aura",
    Value = false,
    Callback = function(state)
        killAuraToggle = state
        if state then
            task.spawn(killAuraLoop)
        else
            local tool, _ = getAnyToolWithDamageID(false)
            unequipTool(tool)
        end
    end
})

Combat:Toggle({
    Title = "Chop Aura",
    Value = false,
    Callback = function(state)
        chopAuraToggle = state
        if state then
            task.spawn(chopAuraLoop)
        else
            local tool, _ = getAnyToolWithDamageID(true)
            unequipTool(tool)
        end
    end
})

Combat:Section({ Title = "Settings", Icon = "settings" })

Combat:Slider({
    Title = "Aura Radius",
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(value)
        auraRadius = math.clamp(value, 10, 500)
    end
})

-- ============================
-- MAIN TAB - AUTO FEED
-- ============================
Main:Section({ Title = "Auto Feed", Icon = "utensils" })

Main:Dropdown({
    Title = "Select Food",
    Desc = "Choose the food",
    Values = alimentos,
    Value = selectedFood,
    Multi = false,
    Callback = function(value)
        selectedFood = value
    end
})

Main:Input({
    Title = "Feed %",
    Desc = "Eat when hunger reaches this %",
    Value = tostring(hungerThreshold),
    Placeholder = "Ex: 75",
    Numeric = true,
    Callback = function(value)
        local n = tonumber(value)
        if n then
            hungerThreshold = math.clamp(n, 0, 100)
        end
    end
})

Main:Toggle({
    Title = "Auto Feed",
    Value = false,
    Callback = function(state)
        autoFeedToggle = state
        if state then
            task.spawn(function()
                while autoFeedToggle do
                    task.wait(0.1)
                    if wiki(selectedFood) == 0 then
                        autoFeedToggle = false
                        Combat:Find("Auto Feed"):SetValue(false)
                        notifeed(selectedFood)
                        break
                    end
                    if ghn() <= hungerThreshold then
                        feed(selectedFood)
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
})

-- ============================
-- MAIN TAB - MISC
-- ============================
Main:Section({ Title = "Misc", Icon = "settings" })

local instantInteractEnabled = false
local originalHoldDurations = {}

Main:Toggle({
    Title = "Instant Interact",
    Value = false,
    Callback = function(state)
        instantInteractEnabled = state

        if state then
            originalHoldDurations = {}
            instantInteractConnection = task.spawn(function()
                while instantInteractEnabled do
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if not instantInteractEnabled then break end
                        if obj:IsA("ProximityPrompt") then
                            if originalHoldDurations[obj] == nil then
                                originalHoldDurations[obj] = obj.HoldDuration
                            end
                            obj.HoldDuration = 0
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            if instantInteractConnection then
                instantInteractEnabled = false
            end
            for obj, value in pairs(originalHoldDurations) do
                if obj and obj:IsA("ProximityPrompt") then
                    obj.HoldDuration = value
                end
            end
            originalHoldDurations = {}
        end
    end
})

local RunService = game:GetService("RunService")
local torchLoop = nil

Main:Toggle({
    Title = "Auto Stun Deer",
    Value = false,
    Callback = function(state)
        if state then
            torchLoop = RunService.RenderStepped:Connect(function()
                pcall(function()
                    local remote = ReplicatedStorage:FindFirstChild("RemoteEvents")
                        and ReplicatedStorage.RemoteEvents:FindFirstChild("DeerHitByTorch")
                    local deer = workspace:FindFirstChild("Characters")
                        and workspace.Characters:FindFirstChild("Deer")
                    if remote and deer then
                        remote:InvokeServer(deer)
                    end
                end)
                task.wait(0.2)
            end)
        else
            if torchLoop then
                torchLoop:Disconnect()
                torchLoop = nil
            end
        end
    end
})

-- ============================
-- AUTO TAB - CAMPFIRE
-- ============================
Auto:Section({ Title = "Auto Upgrade Campfire", Icon = "flame" })

local autoUpgradeCampfireEnabled = false

Auto:Dropdown({
    Title = "Auto Upgrade Campfire",
    Desc = "Choose the items",
    Values = campfireFuelItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        for _, itemName in ipairs(campfireFuelItems) do
            alwaysFeedEnabledItems[itemName] = table.find(options, itemName) ~= nil
        end
    end
})

Auto:Toggle({
    Title = "Auto Upgrade Campfire",
    Value = false,
    Callback = function(checked)
        autoUpgradeCampfireEnabled = checked
        if checked then
            task.spawn(function()
                while autoUpgradeCampfireEnabled do
                    for itemName, enabled in pairs(alwaysFeedEnabledItems) do
                        if not autoUpgradeCampfireEnabled then break end
                        if enabled then
                            for _, item in ipairs(workspace:WaitForChild("Items"):GetChildren()) do
                                if item.Name == itemName then
                                    moveItemToPos(item, campfireDropPos)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end
    end
})

-- ============================
-- AUTO TAB - AUTO COOK
-- ============================
Auto:Section({ Title = "Auto Cook Food", Icon = "flame" })

Auto:Dropdown({
    Title = "Auto Cook Food",
    Values = autocookItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        for _, itemName in ipairs(autocookItems) do
            autoCookEnabledItems[itemName] = table.find(options, itemName) ~= nil
        end
    end
})

Auto:Toggle({
    Title = "Auto Cook Food",
    Value = false,
    Callback = function(state)
        autoCookEnabled = state
    end
})

coroutine.wrap(function()
    while true do
        if autoCookEnabled then
            for itemName, enabled in pairs(autoCookEnabledItems) do
                if enabled then
                    for _, item in ipairs(Workspace:WaitForChild("Items"):GetChildren()) do
                        if item.Name == itemName then
                            moveItemToPos(item, campfireDropPos)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)()

-- ============================
-- ESP TAB
-- ============================
ESP:Section({ Title = "Esp Items", Icon = "package" })

ESP:Dropdown({
    Title = "Esp Items",
    Values = ie,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedItems = options
        if espItemsEnabled then
            for _, name in ipairs(ie) do
                if table.find(selectedItems, name) then
                    Aesp(name, "item")
                else
                    Desp(name, "item")
                end
            end
        else
            for _, name in ipairs(ie) do
                Desp(name, "item")
            end
        end
    end
})

ESP:Toggle({
    Title = "Enable Esp",
    Value = false,
    Callback = function(state)
        espItemsEnabled = state
        for _, name in ipairs(ie) do
            if state and table.find(selectedItems, name) then
                Aesp(name, "item")
            else
                Desp(name, "item")
            end
        end

        if state then
            if not espConnections["Items"] then
                local container = workspace:FindFirstChild("Items")
                if container then
                    espConnections["Items"] = container.ChildAdded:Connect(function(obj)
                        if table.find(selectedItems, obj.Name) then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                            if part then
                                createESPText(part, obj.Name, Color3.fromRGB(0, 255, 0))
                            end
                        end
                    end)
                end
            end
        else
            if espConnections["Items"] then
                espConnections["Items"]:Disconnect()
                espConnections["Items"] = nil
            end
        end
    end
})

ESP:Section({ Title = "Esp Entity", Icon = "user" })

ESP:Dropdown({
    Title = "Esp Entity",
    Values = me,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedMobs = options
        if espMobsEnabled then
            for _, name in ipairs(me) do
                if table.find(selectedMobs, name) then
                    Aesp(name, "mob")
                else
                    Desp(name, "mob")
                end
            end
        else
            for _, name in ipairs(me) do
                Desp(name, "mob")
            end
        end
    end
})

ESP:Toggle({
    Title = "Enable Esp",
    Value = false,
    Callback = function(state)
        espMobsEnabled = state
        for _, name in ipairs(me) do
            if state and table.find(selectedMobs, name) then
                Aesp(name, "mob")
            else
                Desp(name, "mob")
            end
        end

        if state then
            if not espConnections["Mobs"] then
                local container = workspace:FindFirstChild("Characters")
                if container then
                    espConnections["Mobs"] = container.ChildAdded:Connect(function(obj)
                        if table.find(selectedMobs, obj.Name) then
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                            if part then
                                createESPText(part, obj.Name, Color3.fromRGB(255, 255, 0))
                            end
                        end
                    end)
                end
            end
        else
            if espConnections["Mobs"] then
                espConnections["Mobs"]:Disconnect()
                espConnections["Mobs"] = nil
            end
        end
    end
})

-- ============================
-- BRING TAB
-- ============================
Bring:Section({ Title = "Junk", Icon = "box" })

Bring:Dropdown({
    Title = "Select Junk Items",
    Desc = "Choose items to bring",
    Values = junkItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedJunkItems = options
    end
})

Bring:Button({
    Title = "Bring Junk Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedJunkItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                    task.wait(0.05)
                end
            end
        end
    end
})

Bring:Section({ Title = "Fuel", Icon = "flame" })

Bring:Dropdown({
    Title = "Select Fuel Items",
    Desc = "Choose items to bring",
    Values = fuelItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedFuelItems = options
    end
})

Bring:Button({
    Title = "Bring Fuel Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedFuelItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) then
                    moveItemToPos(item, targetPos)
                    task.wait(0.05)
                end
            end
        end
    end
})

Bring:Section({ Title = "Food", Icon = "utensils" })

Bring:Dropdown({
    Title = "Select Food Items",
    Desc = "Choose items to bring",
    Values = foodItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedFoodItems = options
    end
})

Bring:Button({
    Title = "Bring Food Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedFoodItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                    task.wait(0.05)
                end
            end
        end
    end
})

Bring:Section({ Title = "Medicine", Icon = "bandage" })

Bring:Dropdown({
    Title = "Select Medical Items",
    Desc = "Choose items to bring",
    Values = medicalItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedMedicalItems = options
    end
})

Bring:Button({
    Title = "Bring Medical Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedMedicalItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                    task.wait(0.05)
                end
            end
        end
    end
})

Bring:Section({ Title = "Equipment", Icon = "sword" })

Bring:Dropdown({
    Title = "Select Equipment Items",
    Desc = "Choose items to bring",
    Values = equipmentItems,
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedEquipmentItems = options
    end
})

Bring:Button({
    Title = "Bring Equipment Items",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + Vector3.new(2, 0, 0)
        for _, itemName in ipairs(selectedEquipmentItems) do
            for _, item in ipairs(workspace:GetDescendants()) do
                if item.Name == itemName and (item:IsA("BasePart") or item:IsA("Model")) and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) then
                    moveItemToPos(item, targetPos)
                    task.wait(0.05)
                end
            end
        end
    end
})

-- ============================
-- TELEPORT TAB
-- ============================
Teleport:Section({ Title = "Teleport", Icon = "map" })

Teleport:Button({
    Title = "Teleport to Campfire",
    Locked = false,
    Callback = function()
        tp1()
    end
})

Teleport:Button({
    Title = "Teleport to Stronghold",
    Locked = false,
    Callback = function()
        tp2()
    end
})

Teleport:Section({ Title = "Children", Icon = "eye" })

local MobDropdown = Teleport:Dropdown({
    Title = "Select Child",
    Values = currentMobNames,
    Multi = false,
    AllowNone = true,
    Callback = function(options)
        selectedMob = options[#options] or currentMobNames[1] or nil
    end
})

Teleport:Button({
    Title = "Refresh List",
    Locked = false,
    Callback = function()
        currentMobs, currentMobNames = getMobs()
        if #currentMobNames > 0 then
            selectedMob = currentMobNames[1]
            MobDropdown:Refresh(currentMobNames)
        else
            selectedMob = nil
            MobDropdown:Refresh({ "No child found" })
        end
    end
})

Teleport:Button({
    Title = "Teleport to Child",
    Locked = false,
    Callback = function()
        if selectedMob and currentMobs then
            for i, name in ipairs(currentMobNames) do
                if name == selectedMob then
                    local targetMob = currentMobs[i]
                    if targetMob then
                        local part = targetMob.PrimaryPart or targetMob:FindFirstChildWhichIsA("BasePart")
                        if part and game.Players.LocalPlayer.Character then
                            local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                            end
                        end
                    end
                    break
                end
            end
        end
    end
})

Teleport:Section({ Title = "Chest", Icon = "box" })

local ChestDropdown = Teleport:Dropdown({
    Title = "Select Chest",
    Values = currentChestNames,
    Multi = false,
    AllowNone = true,
    Callback = function(options)
        selectedChest = options[#options] or currentChestNames[1] or nil
    end
})

Teleport:Button({
    Title = "Refresh List",
    Locked = false,
    Callback = function()
        currentChests, currentChestNames = getChests()
        if #currentChestNames > 0 then
            selectedChest = currentChestNames[1]
            ChestDropdown:Refresh(currentChestNames)
        else
            selectedChest = nil
            ChestDropdown:Refresh({ "No chests found" })
        end
    end
})

Teleport:Button({
    Title = "Teleport to Chest",
    Locked = false,
    Callback = function()
        if selectedChest and currentChests then
            local chestIndex = 1
            for i, name in ipairs(currentChestNames) do
                if name == selectedChest then
                    chestIndex = i
                    break
                end
            end
            local targetChest = currentChests[chestIndex]
            if targetChest then
                local part = targetChest.PrimaryPart or targetChest:FindFirstChildWhichIsA("BasePart")
                if part and game.Players.LocalPlayer.Character then
                    local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                    end
                end
            end
        end
    end
})

-- ============================
-- PLAYER TAB
-- ============================
Player:Section({ Title = "Main", Icon = "eye" })

Player:Slider({
    Title = "Fly Speed",
    Value = { Min = 1, Max = 20, Default = 1 },
    Callback = function(value)
        flySpeed = value
        if FLYING then
            task.spawn(function()
                while FLYING do
                    task.wait(0.1)
                    if game:GetService("UserInputService").TouchEnabled then
                        local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if root and root:FindFirstChild("BodyVelocity") then
                            local bv = root:FindFirstChild("BodyVelocity")
                            bv.Velocity = bv.Velocity.Unit * (flySpeed * 50)
                        end
                    end
                end
            end)
        end
    end
})

Player:Toggle({
    Title = "Enable Fly",
    Value = false,
    Callback = function(state)
        flyToggle = state
        if flyToggle then
            if game:GetService("UserInputService").TouchEnabled then
                MobileFly()
            else
                sFLY()
            end
        else
            NOFLY()
            UnMobileFly()
        end
    end
})

local speed = 16
local function setSpeed(val)
    local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = val end
end

Player:Slider({
    Title = "Speed",
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(value)
        speed = value
    end
})

Player:Toggle({
    Title = "Enable Speed",
    Value = false,
    Callback = function(state)
        setSpeed(state and speed or 16)
    end
})

local noclipConnection = nil
Player:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(state)
        if state then
            noclipConnection = RunService.Stepped:Connect(function()
                local char = Players.LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
        end
    end
})

local infJumpConnection = nil
Player:Toggle({
    Title = "Inf Jump",
    Value = false,
    Callback = function(state)
        if state then
            infJumpConnection = UserInputService.JumpRequest:Connect(function()
                local char = Players.LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if infJumpConnection then
                infJumpConnection:Disconnect()
                infJumpConnection = nil
            end
        end
    end
})

-- ============================
-- SELECT INITIAL TAB
-- ============================
Window:SelectTab(1)