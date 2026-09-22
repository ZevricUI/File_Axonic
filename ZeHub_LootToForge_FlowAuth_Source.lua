if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local Env = type(getgenv) == "function" and getgenv() or _G
if type(Env.__ZEHUB_LOOTFORGE_RUNTIME) == "table"
    and type(Env.__ZEHUB_LOOTFORGE_RUNTIME.Destroy) == "function" then
    pcall(Env.__ZEHUB_LOOTFORGE_RUNTIME.Destroy)
end

local UiLibrary = loadstring(game:HttpGet(
    "https://flowauth.net/v1/ui/465ea7165cc765fb6d66c312f98a2bc4.lua"
))()

-- ZeHub compatibility layer:
-- The current ZeHub UI library uses CreateWindow/CreateTab/CreateSection,
-- while this script was written against the older equivalent API.
do
    local Library = UiLibrary

    if type(Library.CreateWindow) == "function" and type(Library.new) ~= "function" then
        function Library.new(titleText, config)
            config = type(config) == "table" and config or {}

            return Library:CreateWindow({
                Title = titleText or config.Title or config.Name or "ZeHub",
                Subtitle = config.Subtitle or config.BrandName or "ZeHub",
                Width = config.Width or 650,
                Height = config.Height or 430,
                Theme = config.Theme or "Dark",
                Position = config.Position,
                ThemeButton = config.ThemeButton,
                MinimizeButton = config.MinimizeButton,
                CloseButton = config.CloseButton,
            })
        end
    end

    if type(Library.CreateWindow) == "function" then
        local windowCreateTab = Library.WindowMethods
            and Library.WindowMethods.CreateTab

        -- Fallback wrapper for libraries that expose the method through
        -- the returned Window object rather than a public WindowMethods table.
        if windowCreateTab == nil then
            -- The library's returned Window object is patched below after
            -- construction by the helper wrappers.
        end
    end
end

local Window = UiLibrary.new("ZeHub | +1 LOOT TO FORGE", {
    BrandName = "ZeHub",
    Theme = "Graphite",
    Accent = Color3.fromRGB(170, 100, 255),
    AutoGameName = true,
    Width = 650,
    Height = 430,
    ToggleKey = Enum.KeyCode.RightShift,
    Privacy = {
        ScrambleName = false,
    },
    Config = {
        Enabled = true,
        AutoSave = true,
        Folder = "ZeHubConfigs",
        File = "LootToForge",
    },
})

-- Adapt the new ZeHub UI object's table-based API to the calls used below.
do
    local originalCreateTab = Window.CreateTab
    if type(originalCreateTab) == "function" then
        Window.CreateTab = function(self, name, icon, extra)
            return originalCreateTab(self, {
                Name = tostring(name),
                Icon = tostring(icon or ""),
                Description = type(extra) == "table" and extra.Description or nil,
            })
        end
    end

    local originalDestroy = Window.Destroy

    -- New UI tabs expose CreateSection directly. The script also uses
    -- CreateTabSection as a lightweight page/section container.
    local function patchTab(tab)
        if type(tab) ~= "table" then
            return tab
        end

        if type(tab.CreateTabSection) ~= "function"
            and type(tab.CreateSection) == "function" then
            local createSection = tab.CreateSection
            tab.CreateTabSection = function(self, name)
                return createSection(self, {
                    Name = tostring(name),
                })
            end
        end

        return tab
    end

    -- Wrap the result of Window:CreateTab so the compatibility method is
    -- installed before the rest of the script uses it.
    local wrappedCreateTab = Window.CreateTab
    Window.CreateTab = function(self, name, icon, extra)
        local tab = wrappedCreateTab(self, name, icon, extra)
        return patchTab(tab)
    end

    if type(originalDestroy) == "function" then
        Window.Destroy = originalDestroy
    end
end

local Runtime = {
    Alive = true,
    Connections = {},
    Ui = Window,

    BagAreaID = nil,
    LastBagResolve = 0,

    DungeonStage = 1,
    EnteringStage = false,
    DungeonStarted = false,
    DungeonStartedAt = 0,
    DungeonEmptyAt = nil,
    DungeonCompleting = false,
    LastDungeonTry = 0,
    LastDungeonComplete = 0,
    LastTargetOreCollect = 0,
    LastIndexCollect = 0,

    OriginalCollision = setmetatable({}, {__mode = "k"}),
}
Env.__ZEHUB_LOOTFORGE_RUNTIME = Runtime

local State = {
    AutoTrain = false,
    TrainMode = "None",
    TrainDelay = 0.16,

    AutoUpgrade = false,
    UpgradeType = "All",
    UpgradeDelay = 0.45,

    AutoCollectOre = false,
    OreCollectMode = "All",
    TargetOrePriceText = "",
    TargetOrePrice = nil,
    OreDelay = 0.12,

    FarmDistance = 4,
    AttackDelay = 0.16,

    AutoDungeon = false,

    AutoCollectIndex = false,
    IndexDelay = 0.65,

    Speed = false,
    SpeedValue = 28,
    Noclip = false,
}

local function notify(title, description, kind)
    pcall(function()
        Window:Notify({
            Title = title,
            Description = description,
            Type = kind or "Info",
            Duration = 3,
        })
    end)
end

local function safeRequire(instance)
    if not instance or not instance:IsA("ModuleScript") then
        return nil
    end
    local ok, result = pcall(require, instance)
    return ok and result or nil
end

local function path(root, ...)
    local current = root
    for _, name in ipairs({...}) do
        current = current and current:FindFirstChild(name)
        if not current then
            return nil
        end
    end
    return current
end

local TrainCTRL = safeRequire(path(ReplicatedStorage, "CTRL", "TrainCTRL"))
local TrainAreaHelper = safeRequire(path(ReplicatedStorage, "Config", "TrainArea", "Helper"))

local UpgradeData = safeRequire(path(ReplicatedStorage, "LocalData", "UpgradeData"))
local UpgradeHelper = safeRequire(path(ReplicatedStorage, "Config", "Upgrade", "Helper"))

local BackpackData = safeRequire(path(ReplicatedStorage, "LocalData", "BackpackData"))
local LeftInfoGUI = safeRequire(path(ReplicatedStorage, "GuiUtils", "LeftInfoGUI"))
local OreHelper = safeRequire(path(ReplicatedStorage, "Config", "Ore", "Helper"))

local IndexData = safeRequire(path(ReplicatedStorage, "LocalData", "IndexData"))
local WeaponHelper = safeRequire(path(ReplicatedStorage, "Config", "Weapon", "Helper"))
local ArmorHelper = safeRequire(path(ReplicatedStorage, "Config", "Armor", "Helper"))

local StageHelper = safeRequire(path(ReplicatedStorage, "Config", "Stage", "Helper"))
local HPCTRL = safeRequire(path(ReplicatedStorage, "CTRL", "HPCTRL"))

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local StageUtils = safeRequire(path(PlayerScripts, "Manager", "StageManager", "StageUtils"))

local SkillCTRL = safeRequire(path(ReplicatedStorage, "SkillSystemNew", "SkillCTRL"))

local function getCharacter()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and (
        character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )

    if not character or not humanoid or humanoid.Health <= 0 or not root then
        return nil
    end

    return character, humanoid, root
end

local function getEcoValue(name)
    local eco = LocalPlayer:FindFirstChild("Eco")
    local value = eco and eco:FindFirstChild(name)
    return value and tonumber(value.Value) or 0
end

local function stopBagTraining()
    Runtime.BagAreaID = nil

    if TrainCTRL then
        if type(TrainCTRL.GetIsAutoing) == "function" then
            local ok, autoing = pcall(TrainCTRL.GetIsAutoing)
            if ok and autoing and type(TrainCTRL.ExitAutoTrain) == "function" then
                pcall(TrainCTRL.ExitAutoTrain)
            end
        elseif type(TrainCTRL.ExitAutoTrain) == "function" then
            pcall(TrainCTRL.ExitAutoTrain)
        end
    end

    if LocalPlayer:GetAttribute("AutoTrainAreaID") ~= nil then
        LocalPlayer:SetAttribute("AutoTrainAreaID", nil)
    end
end

local function bestUnlockedBagArea()
    if not TrainAreaHelper
        or type(TrainAreaHelper.GetConfig) ~= "function"
        or type(TrainAreaHelper.GetNeedRebirth) ~= "function" then
        return nil
    end

    local ok, config = pcall(TrainAreaHelper.GetConfig)
    if not ok or type(config) ~= "table" then
        return nil
    end

    local rebirth = getEcoValue("rebirth")
    local bestID = nil
    local bestBasic = -math.huge

    for id, info in pairs(config) do
        local numericID = tonumber(id)
        if numericID and type(info) == "table" then
            local isPay = false
            if type(TrainAreaHelper.GetIsPay) == "function" then
                local payOK, pay = pcall(TrainAreaHelper.GetIsPay, numericID)
                isPay = payOK and pay == true
            end

            if not isPay then
                local reqOK, needRebirth = pcall(TrainAreaHelper.GetNeedRebirth, numericID)
                needRebirth = reqOK and tonumber(needRebirth) or math.huge
                local basic = tonumber(info.Basic) or numericID

                if rebirth >= needRebirth and basic > bestBasic then
                    bestBasic = basic
                    bestID = numericID
                end
            end
        end
    end

    return bestID
end

local function ensureBagTraining()
    if not TrainCTRL or type(TrainCTRL.StartAutoTrain) ~= "function" then
        return
    end

    local now = os.clock()
    if now - Runtime.LastBagResolve < 0.6 then
        return
    end
    Runtime.LastBagResolve = now

    local areaID = bestUnlockedBagArea()
    if not areaID then
        return
    end

    local currentID = tonumber(LocalPlayer:GetAttribute("AutoTrainAreaID"))
    local isAutoing = false
    if type(TrainCTRL.GetIsAutoing) == "function" then
        local ok, result = pcall(TrainCTRL.GetIsAutoing)
        isAutoing = ok and result == true
    end

    if currentID ~= areaID then
        if isAutoing and type(TrainCTRL.ExitAutoTrain) == "function" then
            pcall(TrainCTRL.ExitAutoTrain)
        end
        LocalPlayer:SetAttribute("AutoTrainAreaID", areaID)
        Runtime.BagAreaID = areaID
        isAutoing = false
    end

    if not isAutoing then
        pcall(TrainCTRL.StartAutoTrain)
    end
end

local function trainOnce()
    if TrainCTRL and type(TrainCTRL.TrainOnce) == "function" then
        pcall(TrainCTRL.TrainOnce, nil, true)
    end
end

local UpgradeTypes = {"Train", "Luck", "OrePack"}

local function getNextUpgradePrice(upgradeType)
    if not UpgradeData or not UpgradeHelper then
        return nil
    end

    local okLevel, level = pcall(UpgradeData.GetLevel, upgradeType)
    if not okLevel then
        return nil
    end
    level = tonumber(level) or 0

    if type(UpgradeHelper.CheckIsMax) == "function" then
        local okMax, isMax = pcall(UpgradeHelper.CheckIsMax, upgradeType, level)
        if okMax and isMax then
            return nil
        end
    end

    if type(UpgradeHelper.GetPrice) ~= "function" then
        return nil
    end

    local okPrice, price = pcall(UpgradeHelper.GetPrice, upgradeType, level + 1)
    return okPrice and tonumber(price) or nil
end

local function upgradeOnce()
    if not UpgradeData or type(UpgradeData.UpgradeOnce) ~= "function" then
        return
    end

    local budget = getEcoValue("coin")

    if State.UpgradeType == "All" then
        for _, upgradeType in ipairs(UpgradeTypes) do
            local price = getNextUpgradePrice(upgradeType)
            if price and budget >= price then
                local ok = pcall(UpgradeData.UpgradeOnce, upgradeType)
                if ok then
                    budget -= price
                end
            end
        end
        return
    end

    local price = getNextUpgradePrice(State.UpgradeType)
    if price and budget >= price then
        pcall(UpgradeData.UpgradeOnce, State.UpgradeType)
    end
end

local function getOrePackCount()
    if LeftInfoGUI and type(LeftInfoGUI.GetOrePack) == "function" then
        local ok, amount = pcall(LeftInfoGUI.GetOrePack)
        if ok then
            return tonumber(amount) or 0
        end
    end
    return 0
end

local function getOrePackMax()
    if UpgradeData and type(UpgradeData.GetMaxNum) == "function" then
        local ok, max = pcall(UpgradeData.GetMaxNum, "OrePack")
        if ok then
            return tonumber(max) or 0
        end
    end
    return 0
end

local function backpackIsFull()
    local max = getOrePackMax()
    return max > 0 and getOrePackCount() >= max
end

local function sellAll()
    if not BackpackData or type(BackpackData.SellAll) ~= "function" then
        return false
    end

    local ok = pcall(BackpackData.SellAll)
    if ok and LeftInfoGUI and type(LeftInfoGUI.UpdateOrePack) == "function" then
        task.delay(0.25, function()
            if Runtime.Alive then
                pcall(LeftInfoGUI.UpdateOrePack, 0)
            end
        end)
    end
    return ok
end

local function parseAmount(value)
    local text = tostring(value or ""):lower():gsub("%s+", ""):gsub(",", "")
    if text == "" then
        return nil
    end

    local number, suffix = text:match("^([%d%.]+)([kmbt]?)$")
    number = tonumber(number)
    if not number then
        return nil
    end

    local multipliers = {
        k = 1e3,
        m = 1e6,
        b = 1e9,
        t = 1e12,
    }

    return math.floor(number * (multipliers[suffix] or 1) + 0.5)
end

local function getOreModelFromPrompt(prompt)
    local cache = Workspace:FindFirstChild("OreCache")
    if not cache or not prompt then
        return nil
    end

    local current = prompt.Parent
    while current and current ~= cache do
        if current:IsA("Model") and current.Parent == cache then
            return current
        end
        current = current.Parent
    end

    return nil
end

local function getOrePrice(model)
    if not model or not OreHelper or type(OreHelper.GetPrice) ~= "function" then
        return nil
    end

    local ok, price = pcall(OreHelper.GetPrice, model.Name)
    return ok and tonumber(price) or nil
end

local function oreMatchesMode(prompt)
    if State.OreCollectMode ~= "Price" then
        return true
    end

    local target = tonumber(State.TargetOrePrice)
    if not target or target <= 0 then
        return false
    end

    local model = getOreModelFromPrompt(prompt)
    local price = getOrePrice(model)
    return price ~= nil and price == target
end

local function getCollectibleOrePrompts(onlyTargetPrice)
    local cache = Workspace:FindFirstChild("OreCache")
    local prompts = {}

    if not cache then
        return prompts
    end

    for _, descendant in ipairs(cache:GetDescendants()) do
        if descendant:IsA("ProximityPrompt")
            and descendant.Enabled
            and descendant.ActionText == "Collect" then

            local matches = true

            if onlyTargetPrice then
                local model = getOreModelFromPrompt(descendant)
                local price = getOrePrice(model)
                matches = price ~= nil and price == tonumber(State.TargetOrePrice)
            else
                matches = oreMatchesMode(descendant)
            end

            if matches then
                prompts[#prompts + 1] = descendant
            end
        end
    end

    return prompts
end

local function collectPrompts(prompts)
    if backpackIsFull() then
        return 0
    end

    local collected = 0

    for _, prompt in ipairs(prompts) do
        if not Runtime.Alive or not State.AutoCollectOre or backpackIsFull() then
            break
        end

        if prompt and prompt.Parent and prompt.Enabled and type(fireproximityprompt) == "function" then
            local ok = pcall(fireproximityprompt, prompt, 0, true)
            if ok then
                collected += 1
            end
        end
    end

    return collected
end

local function collectVisibleOres()
    if backpackIsFull() then
        return 0
    end

    return collectPrompts(getCollectibleOrePrompts(false))
end

local function getAllVisibleOrePrompts()
    local cache = Workspace:FindFirstChild("OreCache")
    local prompts = {}

    if not cache then
        return prompts
    end

    for _, descendant in ipairs(cache:GetDescendants()) do
        if descendant:IsA("ProximityPrompt")
            and descendant.Enabled
            and descendant.ActionText == "Collect" then
            prompts[#prompts + 1] = descendant
        end
    end

    return prompts
end

local function targetPriceOrePending()
    if not State.AutoCollectOre or State.OreCollectMode ~= "Price" then
        return false
    end

    local target = tonumber(State.TargetOrePrice)
    if not target or target <= 0 then
        return false
    end

    return #getCollectibleOrePrompts(true) > 0
end

local function collectTargetPriceOres()
    if not State.AutoCollectOre or State.OreCollectMode ~= "Price" then
        return 0
    end

    local amount = collectPrompts(getCollectibleOrePrompts(true))
    if amount > 0 then
        Runtime.LastTargetOreCollect = os.clock()
    end
    return amount
end

local function enemyAlive(model)
    if not model or not model:IsA("Model") or not model:IsDescendantOf(Workspace) then
        return false
    end
    if model:GetAttribute("Dead") == true then
        return false
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    return humanoid ~= nil and humanoid.Health > 0 and root ~= nil
end

local function nearestEnemy()
    local _, _, root = getCharacter()
    local folder = Workspace:FindFirstChild("EnemyFolder")
    if not root or not folder then
        return nil
    end

    local best, bestDistance = nil, math.huge
    local seen = {}
    for _, item in ipairs(folder:GetDescendants()) do
        local model = item:IsA("Model") and item or item:FindFirstAncestorOfClass("Model")
        if model and not seen[model] and model:IsDescendantOf(folder) and enemyAlive(model) then
            seen[model] = true
            local targetRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            if targetRoot then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if distance < bestDistance then
                    best = model
                    bestDistance = distance
                end
            end
        end
    end

    return best, bestDistance
end

local function countAliveEnemies()
    local folder = Workspace:FindFirstChild("EnemyFolder")
    if not folder then
        return 0
    end

    local count = 0
    local seen = {}
    for _, item in ipairs(folder:GetDescendants()) do
        local model = item:IsA("Model") and item or item:FindFirstAncestorOfClass("Model")
        if model and not seen[model] and model:IsDescendantOf(folder) and enemyAlive(model) then
            seen[model] = true
            count += 1
        end
    end
    return count
end

local function moveToEnemy(model)
    local character, humanoid, root = getCharacter()
    local targetRoot = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
    if not character or not humanoid or not root or not targetRoot then
        return false
    end

    local distance = math.max(2, tonumber(State.FarmDistance) or 4)
    local desired = targetRoot.CFrame * CFrame.new(0, 0, distance)
    character:PivotTo(CFrame.lookAt(desired.Position, targetRoot.Position))
    return true
end

local function attackEnemyOnce(model)
    if not SkillCTRL or type(SkillCTRL.ATK) ~= "function" then
        return
    end

    local character = getCharacter()
    if not character or not model or not enemyAlive(model) then
        return
    end

    moveToEnemy(model)

    pcall(SkillCTRL.ATK, LocalPlayer, {
        Char = character,
        Target = model,
    })
end

local function maxDungeonStage()
    if StageHelper and type(StageHelper.GetStageEnemyConfig) == "function" then
        local ok, config = pcall(StageHelper.GetStageEnemyConfig)
        if ok and type(config) == "table" then
            local highest = 0
            for stageID in pairs(config) do
                local n = tonumber(tostring(stageID):match("Stage_(%d+)"))
                if n and n > highest then
                    highest = n
                end
            end
            if highest > 0 then
                return highest
            end
        end
    end
    return 22
end

local function stageID(number)
    return "Stage_" .. tostring(number)
end

local function getStageArea(number)
    local world = Workspace:FindFirstChild("WorldModel")
    local map = world and world:FindFirstChild("StageMap")
    local areas = map and map:FindFirstChild("AreaPart")
    return areas and areas:FindFirstChild(stageID(number)) or nil
end

local function stageForwardVector(number, part)
    if not part then
        return nil
    end

    local nextArea = getStageArea(number + 1)
    local previousArea = number > 1 and getStageArea(number - 1) or nil

    local direction
    if nextArea then
        direction = nextArea.Position - part.Position
    elseif previousArea then
        direction = part.Position - previousArea.Position
    end

    if direction then
        direction = Vector3.new(direction.X, 0, direction.Z)
        if direction.Magnitude > 0.05 then
            return direction.Unit
        end
    end

    local fallback = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z)
    return fallback.Magnitude > 0.05 and fallback.Unit or Vector3.new(0, 0, -1)
end

local function stageGateHalfExtent(part, forward)
    local right = part.CFrame.RightVector
    local look = part.CFrame.LookVector

    return math.abs(forward:Dot(right)) * part.Size.X * 0.5
        + math.abs(forward:Dot(look)) * part.Size.Z * 0.5
end

local function gatePoints(part, number, rootPosition)
    if not part or not part:IsA("BasePart") then
        return nil, nil, nil, nil
    end

    local forward = stageForwardVector(number, part)
    local half = stageGateHalfExtent(part, forward)
    local y = math.max(part.Position.Y + 2, rootPosition.Y)

    local approach = Vector3.new(
        part.Position.X - forward.X * (half + 7),
        y,
        part.Position.Z - forward.Z * (half + 7)
    )
    local through = Vector3.new(
        part.Position.X + forward.X * (half + 9),
        y,
        part.Position.Z + forward.Z * (half + 9)
    )

    return approach, through, forward, half
end

local function alreadyPastStageGate(part, number, rootPosition)
    if not part then
        return false
    end

    local forward = stageForwardVector(number, part)
    local half = stageGateHalfExtent(part, forward)
    local offset = Vector3.new(
        rootPosition.X - part.Position.X,
        0,
        rootPosition.Z - part.Position.Z
    )

    return offset:Dot(forward) > half + 1.5
end

local function resetDungeonSession()
    Runtime.DungeonStage = 1
    Runtime.EnteringStage = false
    Runtime.DungeonStarted = false
    Runtime.DungeonStartedAt = 0
    Runtime.DungeonEmptyAt = nil
    Runtime.DungeonCompleting = false
end

local function stageEnemyModels()
    local folder = Workspace:FindFirstChild("EnemyFolder")
    local result = {}
    local seen = {}

    if not folder then
        return result
    end

    for _, item in ipairs(folder:GetDescendants()) do
        local model = item:IsA("Model") and item or item:FindFirstAncestorOfClass("Model")
        if model and model:IsDescendantOf(folder) and not seen[model] and enemyAlive(model) then
            seen[model] = true
            result[#result + 1] = model
        end
    end

    return result
end

local function killStageEnemy(model)
    if not model or not enemyAlive(model) or not StageUtils or type(StageUtils.HurtEnemy) ~= "function" then
        return false
    end

    local _, _, root = getCharacter()
    local targetRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if root and targetRoot then
        local distance = math.max(2, tonumber(State.FarmDistance) or 4)
        local desired = targetRoot.CFrame * CFrame.new(0, 0, distance)
        LocalPlayer.Character:PivotTo(CFrame.lookAt(desired.Position, targetRoot.Position))
    end

    local hp = nil
    if HPCTRL and type(HPCTRL.GetCurrentHP) == "function" then
        local ok, value = pcall(HPCTRL.GetCurrentHP, model)
        if ok then
            hp = tonumber(value)
        end
    end
    hp = math.max(1, hp or 999999999)

    return pcall(StageUtils.HurtEnemy, model.Name, hp, {
        Damage = hp,
    })
end

local function stageFromAttribute()
    local id = LocalPlayer:GetAttribute("StageID")
    return tonumber(tostring(id or ""):match("Stage_(%d+)"))
end

local function stageFromLiveEnemies()
    local enemies = stageEnemyModels()
    if #enemies == 0 then
        return nil
    end

    local world = Workspace:FindFirstChild("WorldModel")
    local map = world and world:FindFirstChild("StageMap")
    local pointsRoot = map and map:FindFirstChild("EnemyPoint")
    if not pointsRoot then
        return nil
    end

    local bestStage
    local bestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
        if enemyRoot then
            for _, stageFolder in ipairs(pointsRoot:GetChildren()) do
                local number = tonumber(stageFolder.Name:match("Stage_(%d+)"))
                if number then
                    for _, point in ipairs(stageFolder:GetChildren()) do
                        if point:IsA("BasePart") then
                            local distance = (enemyRoot.Position - point.Position).Magnitude
                            if distance < bestDistance then
                                bestDistance = distance
                                bestStage = number
                            end
                        end
                    end
                end
            end
        end
    end

    return bestStage
end

local function detectCurrentDungeonStage()
    return stageFromAttribute()
        or stageFromLiveEnemies()
        or tonumber(Runtime.DungeonStage)
        or 1
end

local function startStage(number)
    if Runtime.EnteringStage or not StageUtils then
        return false
    end

    local id = stageID(number)
    local area = getStageArea(number)
    local character, humanoid, root = getCharacter()
    if not area or not character or not humanoid or not root then
        return false
    end

    Runtime.EnteringStage = true

    task.spawn(function()
        local ok = pcall(function()
            local approach, through = gatePoints(area, number, root.Position)
            if not approach or not through then
                return
            end

            local touchedCurrentGate = LocalPlayer:GetAttribute("StageID") == id
            local alreadyInside = alreadyPastStageGate(area, number, root.Position)

            if not touchedCurrentGate and not alreadyInside then
                if (root.Position - approach).Magnitude > 18 then
                    character:PivotTo(CFrame.lookAt(approach, through))
                    root.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.12)
                else
                    humanoid:MoveTo(approach)
                    local approachDeadline = os.clock() + 2.5
                    repeat
                        task.wait(0.05)
                    until not Runtime.Alive
                        or not State.AutoDungeon
                        or (root.Position - approach).Magnitude <= 5
                        or os.clock() >= approachDeadline
                end

                if not Runtime.Alive or not State.AutoDungeon then
                    return
                end

                humanoid:MoveTo(through)

                local touchDeadline = os.clock() + 4
                repeat
                    task.wait(0.04)
                until not Runtime.Alive
                    or not State.AutoDungeon
                    or LocalPlayer:GetAttribute("StageID") == id
                    or alreadyPastStageGate(area, number, root.Position)
                    or os.clock() >= touchDeadline
            end

            if LocalPlayer:GetAttribute("StageID") ~= id
                and not alreadyPastStageGate(area, number, root.Position) then
                return
            end

            if number == 1 and not LocalPlayer:GetAttribute("IntoFight") then
                if type(StageUtils.StartFight) == "function" then
                    StageUtils.StartFight(id)
                end
            elseif type(StageUtils.StartStage) == "function" then
                StageUtils.StartStage(id)
            end

            Runtime.DungeonStage = number
            Runtime.DungeonStarted = true
            Runtime.DungeonStartedAt = os.clock()
            Runtime.DungeonEmptyAt = nil
            Runtime.DungeonCompleting = false
        end)

        Runtime.EnteringStage = false

        if not ok then
            Runtime.DungeonStarted = false
        end
    end)

    return true
end

local function finishDungeonRun()
    Runtime.DungeonCompleting = true

    task.delay(0.8, function()
        if not Runtime.Alive then
            return
        end

        if StageUtils and type(StageUtils.ExitFight) == "function" then
            pcall(StageUtils.ExitFight, true)
        end

        resetDungeonSession()

        Runtime.LastDungeonTry = os.clock()
    end)
end

local function startDungeonIfNeeded()
    if not State.AutoDungeon or not StageUtils then
        return
    end

    local now = os.clock()
    local current = math.clamp(tonumber(Runtime.DungeonStage) or 1, 1, maxDungeonStage())

    if not Runtime.DungeonStarted then
        if Runtime.EnteringStage then
            return
        end
        if now - Runtime.LastDungeonTry < 0.8 then
            return
        end
        Runtime.LastDungeonTry = now
        startStage(current)
        return
    end

    if Runtime.DungeonCompleting then
        return
    end

    local enemies = stageEnemyModels()
    if #enemies > 0 then
        Runtime.DungeonEmptyAt = nil
        return
    end

    if now - Runtime.DungeonStartedAt < 1.0 then
        return
    end

    Runtime.DungeonEmptyAt = Runtime.DungeonEmptyAt or now

    local emptyFor = now - Runtime.DungeonEmptyAt
    local allOrePrompts = getAllVisibleOrePrompts()

    if State.AutoCollectOre then
        if State.OreCollectMode == "All" then
            if #allOrePrompts > 0 then
                collectVisibleOres()
                return
            end

            if emptyFor < 4 then
                return
            end
        elseif State.OreCollectMode == "Price" then
            if targetPriceOrePending() then
                collectTargetPriceOres()
                return
            end

            if #allOrePrompts == 0 and emptyFor < 4 then
                return
            end

            if now - Runtime.LastTargetOreCollect < 0.75 then
                return
            end
        end
    elseif emptyFor < 0.45 then
        return
    end

    if now - Runtime.LastDungeonComplete < 0.5 then
        return
    end
    Runtime.LastDungeonComplete = now

    local maxStage = maxDungeonStage()
    if current >= maxStage then
        finishDungeonRun()
        return
    end

    Runtime.DungeonStage = current + 1
    Runtime.DungeonStarted = false
    Runtime.DungeonEmptyAt = nil
    Runtime.LastDungeonTry = now - 0.8
end

local function collectIndexOnce()
    if not IndexData then
        return 0
    end

    if type(IndexData.GetData) == "function" then
        local ok, data = pcall(IndexData.GetData)
        if (not ok or data == nil) and type(IndexData.init) == "function" then
            pcall(IndexData.init)
        end
    end

    local claimed = 0
    local maxPerPass = 12

    local function scan(helper, indexType, armorMode)
        if claimed >= maxPerPass or not helper or type(helper.GetConfig) ~= "function" then
            return
        end

        local okConfig, config = pcall(helper.GetConfig)
        if not okConfig or type(config) ~= "table" then
            return
        end

        for itemID in pairs(config) do
            if claimed >= maxPerPass then
                break
            end

            local entryType = indexType
            if armorMode and type(helper.GetBigType) == "function" then
                local okType, bigType = pcall(helper.GetBigType, itemID)
                if okType and bigType then
                    entryType = bigType
                end
            end

            if entryType then
                local okUnlocked, unlocked = pcall(IndexData.IsUnlocked, entryType, itemID)
                local okClaimed, alreadyClaimed = pcall(IndexData.IsClaimed, entryType, itemID)

                if okUnlocked and unlocked and okClaimed and not alreadyClaimed then
                    local okCollect, result = pcall(IndexData.TryClaimedExp, entryType, itemID)
                    if okCollect and result ~= false then
                        claimed += 1
                    end
                end
            end
        end
    end

    scan(WeaponHelper, "Weapon", false)
    scan(ArmorHelper, nil, true)
    scan(OreHelper, "Ore", false)

    if type(IndexData.TryClaimedLevel) == "function" then
        pcall(IndexData.TryClaimedLevel)
    end

    return claimed
end


local function applyNoclip(character)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if Runtime.OriginalCollision[descendant] == nil then
                Runtime.OriginalCollision[descendant] = descendant.CanCollide
            end
            descendant.CanCollide = false
        end
    end
end

local function restoreCollision()
    for part, old in pairs(Runtime.OriginalCollision) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = old
            end)
        end
        Runtime.OriginalCollision[part] = nil
    end
end

local MainTab = Window:CreateTab("Main", "rbxassetid://10734934585", {Description = "Train"})
local FarmTab = Window:CreateTab("Farm", "rbxassetid://10723407389", {Description = "Farm"})
local PlayerTab = Window:CreateTab("Player", "rbxassetid://10747373176", {Description = "Move"})

local TrainingPage = MainTab:CreateTabSection("Training")
local BuyPage = MainTab:CreateTabSection("Auto Buy")
local IndexPage = MainTab:CreateTabSection("Index")

local TrainMain = TrainingPage:CreateSection("Auto Train", {Side = "Left"})
local TrainSettings = TrainingPage:CreateSection("Settings", {Side = "Right"})

TrainMain:CreateToggle({
    Name = "Auto Train",
    Default = false,
    Flag = "LTF_AutoTrain",
    Callback = function(value)
        State.AutoTrain = value == true
        if not State.AutoTrain then
            stopBagTraining()
        end
    end,
})

TrainMain:CreateDropdown({
    Name = "Train Mode",
    Options = {"None", "Bag"},
    Default = "None",
    Flag = "LTF_TrainMode",
    Callback = function(value)
        State.TrainMode = value or "None"
        if State.TrainMode ~= "Bag" then
            stopBagTraining()
        else
            Runtime.LastBagResolve = 0
        end
    end,
})

TrainSettings:CreateSlider({
    Name = "Train Delay",
    Min = 0.15,
    Max = 1,
    Default = 0.16,
    Step = 0.01,
    Flag = "LTF_TrainDelay",
    Callback = function(value)
        State.TrainDelay = math.max(0.15, tonumber(value) or 0.16)
    end,
})

TrainSettings:CreateParagraph({
    Title = "Bag",
    Text = "Best unlocked bag.",
})

local BuyMain = BuyPage:CreateSection("Auto Buy", {Side = "Left"})
local BuyInfo = BuyPage:CreateSection("Info", {Side = "Right"})

BuyMain:CreateDropdown({
    Name = "Buy Type",
    Options = {"All", "Train", "Luck", "OrePack"},
    Default = "All",
    Flag = "LTF_UpgradeType",
    Callback = function(value)
        State.UpgradeType = value or "All"
    end,
})

BuyMain:CreateToggle({
    Name = "Auto Buy",
    Default = false,
    Flag = "LTF_AutoUpgrade",
    Callback = function(value)
        State.AutoUpgrade = value == true
    end,
})

BuyMain:CreateSlider({
    Name = "Buy Delay",
    Min = 0.15,
    Max = 3,
    Default = 0.45,
    Step = 0.05,
    Flag = "LTF_UpgradeDelay",
    Callback = function(value)
        State.UpgradeDelay = tonumber(value) or 0.45
    end,
})

BuyInfo:CreateParagraph({
    Title = "Auto Buy",
    Text = "Buys only if affordable.",
})

local IndexMain = IndexPage:CreateSection("Index", {Side = "Left"})
local IndexInfo = IndexPage:CreateSection("Info", {Side = "Right"})

IndexMain:CreateToggle({
    Name = "Auto Collect Index",
    Default = false,
    Flag = "LTF_AutoCollectIndex",
    Callback = function(value)
        State.AutoCollectIndex = value == true
        Runtime.LastIndexCollect = 0
    end,
})

IndexMain:CreateButton({
    Name = "Collect Index Now",
    Callback = function()
        local amount = collectIndexOnce()
        notify("Index", "Collected " .. tostring(amount) .. " entr" .. (amount == 1 and "y." or "ies."), "Success")
    end,
})

IndexInfo:CreateParagraph({
    Title = "Index",
    Text = "Claims unlocked entries + level rewards.",
})

local OrePage = FarmTab:CreateTabSection("Ores")
local SellPage = FarmTab:CreateTabSection("Sell")
local DungeonPage = FarmTab:CreateTabSection("Dungeon")

local OreMain = OrePage:CreateSection("Ore Farm", {Side = "Left"})
local OreSettings = OrePage:CreateSection("Settings", {Side = "Right"})

OreMain:CreateToggle({
    Name = "Auto Collect Ore",
    Default = false,
    Flag = "LTF_AutoOre",
    Callback = function(value)
        State.AutoCollectOre = value == true
    end,
})

OreMain:CreateDropdown({
    Name = "Collect Mode",
    Options = {"All", "Price"},
    Default = "All",
    Flag = "LTF_OreCollectMode",
    Callback = function(value)
        State.OreCollectMode = value or "All"
    end,
})

OreMain:CreateInput({
    Name = "Target Price",
    Placeholder = "Enter ore value (ex: 5k, 25k, 2.5m)",
    Default = "",
    Flag = "LTF_TargetOrePrice",
    Callback = function(value)
        local parsed = parseAmount(value)
        State.TargetOrePriceText = tostring(value or "")
        State.TargetOrePrice = parsed and parsed > 0 and parsed or nil
    end,
})

OreMain:CreateButton({
    Name = "Sell All",
    Callback = function()
        if sellAll() then
            notify("Backpack", "Sold.", "Success")
        end
    end,
})

OreSettings:CreateSlider({
    Name = "Ore Delay",
    Min = 0.08,
    Max = 1,
    Default = 0.12,
    Step = 0.01,
    Flag = "LTF_OreDelay",
    Callback = function(value)
        State.OreDelay = tonumber(value) or 0.12
    end,
})

OreSettings:CreateParagraph({
    Title = "Price Examples",
    Text = "Examples: 5k, 25k, 1m, 1b",
})

local SellMain = SellPage:CreateSection("Sell", {Side = "Left"})
local SellInfo = SellPage:CreateSection("Backpack", {Side = "Right"})

SellMain:CreateButton({
    Name = "Sell All",
    Callback = function()
        if sellAll() then
            notify("Backpack", "Sold.", "Success")
        end
    end,
})

SellInfo:CreateParagraph({
    Title = "Manual Sell",
    Text = "Selling is manual only. Use Sell All here or from the Ores tab whenever your backpack is full.",
})

local DungeonMain = DungeonPage:CreateSection("Auto Dungeon", {Side = "Left"})
local DungeonSettings = DungeonPage:CreateSection("Settings", {Side = "Right"})

DungeonMain:CreateToggle({
    Name = "Auto Dungeon",
    Default = false,
    Flag = "LTF_AutoDungeon",
    Callback = function(value)
        State.AutoDungeon = value == true
        Runtime.EnteringStage = false
        Runtime.DungeonEmptyAt = nil
        Runtime.DungeonCompleting = false

        if State.AutoDungeon then
            Runtime.DungeonStage = detectCurrentDungeonStage()
            Runtime.DungeonStarted = #stageEnemyModels() > 0
            Runtime.DungeonStartedAt = Runtime.DungeonStarted and os.clock() or 0
            Runtime.LastDungeonTry = 0
        else
            Runtime.DungeonStarted = false
        end

    end,
})

DungeonMain:CreateParagraph({
    Title = "Progress",
    Text = "Enter → kill → next.",
})

DungeonSettings:CreateSlider({
    Name = "Farm Distance",
    Min = 2,
    Max = 12,
    Default = 4,
    Step = 0.5,
    Flag = "LTF_FarmDistance",
    Callback = function(value)
        State.FarmDistance = tonumber(value) or 4
    end,
})

DungeonSettings:CreateSlider({
    Name = "Attack Delay",
    Min = 0.08,
    Max = 1,
    Default = 0.16,
    Step = 0.01,
    Flag = "LTF_AttackDelay",
    Callback = function(value)
        State.AttackDelay = tonumber(value) or 0.16
    end,
})

local MoveMain = PlayerTab:CreateSection("Movement", {Side = "Left"})

MoveMain:CreateToggle({
    Name = "CFrame Speed",
    Default = false,
    Flag = "LTF_Speed",
    Callback = function(value)
        State.Speed = value == true
    end,
})

MoveMain:CreateSlider({
    Name = "Speed",
    Min = 5,
    Max = 100,
    Default = 28,
    Step = 1,
    Flag = "LTF_SpeedValue",
    Callback = function(value)
        State.SpeedValue = tonumber(value) or 28
    end,
})

MoveMain:CreateToggle({
    Name = "Noclip",
    Default = false,
    Flag = "LTF_Noclip",
    Callback = function(value)
        State.Noclip = value == true
        if not State.Noclip then
            restoreCollision()
        end
    end,
})

local lastTrain = 0
local lastUpgrade = 0
local lastOre = 0
local lastAttack = 0

table.insert(Runtime.Connections, RunService.Heartbeat:Connect(function(dt)
    if not Runtime.Alive then
        return
    end

    local now = os.clock()

    if State.AutoTrain then
        if State.TrainMode == "Bag" then
            ensureBagTraining()
        elseif now - lastTrain >= State.TrainDelay then
            lastTrain = now
            trainOnce()
        end
    end

    if State.AutoUpgrade and now - lastUpgrade >= State.UpgradeDelay then
        lastUpgrade = now
        upgradeOnce()
    end

    if State.AutoCollectOre and now - lastOre >= State.OreDelay then
        lastOre = now
        task.spawn(collectVisibleOres)
    end

    if State.AutoDungeon then
        startDungeonIfNeeded()
    end

    if State.AutoCollectIndex and now - Runtime.LastIndexCollect >= State.IndexDelay then
        Runtime.LastIndexCollect = now
        task.spawn(collectIndexOnce)
    end

    local shouldFarmEnemy = State.AutoDungeon
        and Runtime.DungeonStarted
        and not Runtime.DungeonCompleting

    if shouldFarmEnemy and now - lastAttack >= State.AttackDelay then
        lastAttack = now
        local enemies = stageEnemyModels()
        local enemy = enemies[1]
        if enemy then
            killStageEnemy(enemy)
        end
    end

    local character, humanoid, root = getCharacter()
    if character and humanoid and root then
        if State.Speed and humanoid.MoveDirection.Magnitude > 0 then
            root.CFrame += humanoid.MoveDirection * ((State.SpeedValue or 28) * dt)
        end

        if State.Noclip then
            applyNoclip(character)
        end
    end
end))

function Runtime.Destroy()
    if not Runtime.Alive then
        return
    end

    Runtime.Alive = false
    State.AutoTrain = false
    State.AutoDungeon = false
    State.Noclip = false

    stopBagTraining()
    restoreCollision()

    for _, connection in ipairs(Runtime.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Runtime.Connections)

    if Runtime.Ui and type(Runtime.Ui.Destroy) == "function" then
        pcall(Runtime.Ui.Destroy, Runtime.Ui)
    end

    if Env.__ZEHUB_LOOTFORGE_RUNTIME == Runtime then
        Env.__ZEHUB_LOOTFORGE_RUNTIME = nil
    end
end

notify("ZeHub", "Loaded.", "Success")