--[[
╔═══════════════════════════════════════════════════════════╗
║  UNBOX A FACTOR — V20 FACTORY EDITION                    ║
║  Executor: Delta Executor (Mobile)                       ║
║  Game: Unbox a Factor (138161219313147)                 ║
║  ✅ يجمع فلوس المصانع (Pads + Drops)                     ║
║  ✅ يشيل الصناديق من الجهتين (Pick Up! فقط)              ║
║  ✅ حماية المصانع: لا Pickup / لا Place / لا لمس         ║
║  ✅ بدون ESP نهائي                                        ║
║  ✅ بدون Auto Sell / بدون Auto Claim                     ║
╚═══════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════
local Alive = true

local function DeltaNotify(text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Unbox V20",
            Text = text,
            Duration = duration or 5,
        })
    end)
end

pcall(function()
    local start = tick()
    while not game:IsLoaded() and tick() - start < 15 do
        task.wait(0.1)
    end
end)

-- ═══════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════
local Config = {
    TapXP = { Enabled = true, Delay = 0.2, UseRemote = true, UseSignRemote = true, UseClick = true, Teleport = false },
    CollectMoney = { Enabled = true, Delay = 0.4, Radius = 250, Batch = 20, Teleport = false, WorldDrops = true, FactoryMoney = true },
    CratePickup = { Enabled = true, Delay = 0.8, Range = 250, MaxPerCycle = 4, Teleport = false, AllowUnknown = false },
    OpenCrates = { Enabled = false, Delay = 1.0, Skip = true, MaxPerCycle = 3 },
    Luck = { Enabled = false, Multiplier = 100 },
    Analyzer = { Enabled = true, SaveInterval = 900 },
    Movement = {
        Speed = { Enabled = false, Speed = 60, VelocityFallback = true, VelocityStrength = 0.65 },
        HighJump = { Enabled = false, JumpPower = 40, VelocityBoost = true },
        AirJump = { Enabled = false, Jumps = 3, Unlimited = false, Power = 90, Mode = "Add", MaxVelocity = 280 },
        InfiniteJump = { Enabled = false },
        NoClip = { Enabled = false },
        Fly = { Enabled = false, Speed = 60, Accel = 100, MaxSpeed = 200 },
    },
    Performance = {
        FPSCap = 60, ShowFPS = false, PostFXOff = false, EffectsOff = false,
        AdaptiveQuality = false,
        FPSCounter = { Size = 16, X = 12, Y = 12, Outline = true, AutoColor = true, Color = Color3.fromRGB(94, 255, 170) },
    },
    Protection = { AntiKickBan = true, AntiAFK = true, ExecutorCloak = true, AutoDeleteReports = true },
    SpamFilter = { Enabled = true },
    Settings = { AutoSave = true, ToggleKey = Enum.KeyCode.RightShift },
}

-- ═══════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

do
    local start = tick()
    while not LocalPlayer and tick() - start < 20 do
        task.wait(0.1)
        LocalPlayer = Players.LocalPlayer
    end
    local camStart = tick()
    while not Camera and tick() - camStart < 10 do
        task.wait(0.1)
        Camera = Workspace.CurrentCamera
    end
end

if not LocalPlayer then
    DeltaNotify("LocalPlayer not found", 8)
    return
end

-- ═══════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════
local function safeCall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[UnboxV20]", err) end
    return ok
end

local function ClampNumber(n, min, max)
    if typeof(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then return min end
    if n < min then return min end
    if n > max then return max end
    return n
end

local function SafeNumber(value, defaultValue)
    if typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
        return value
    end
    return defaultValue
end

local function IsValid(inst)
    return inst ~= nil and typeof(inst) == "Instance" and inst.Parent ~= nil
end

local function GetPath(path)
    local cur = Config
    for key in path:gmatch("[^.]+") do
        if typeof(cur) ~= "table" then return nil end
        cur = cur[key]
    end
    return cur
end

local function GetCharacter() return LocalPlayer.Character end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRoot(humanoid)
    if typeof(humanoid) ~= "Instance" then return nil end
    local root = humanoid.RootPart
    if typeof(root) == "Instance" and root:IsA("BasePart") then return root end
    local character = humanoid.Parent
    if typeof(character) ~= "Instance" then return nil end
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function GetRootDirect()
    return GetRoot(GetHumanoid())
end

local function GetCash()
    local v = 0
    safeCall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("Cash") then v = ls.Cash.Value end
    end)
    return v
end

-- ═══════════════════════════════════════════
-- LIVE STATS + ANALYZER
-- ═══════════════════════════════════════════
local LiveStats = {
    StartTime = tick(), CashStart = 0,
    Taps = 0, Crates = 0, Pickups = 0, Opens = 0, Collects = 0,
}

local function BuildAnalysis()
    local lines = {}
    table.insert(lines, "═══════ Unbox a Factor Hub — Live Analyzer V20 ═══════")
    table.insert(lines, "Time: " .. os.date("%c"))
    table.insert(lines, "PlaceId: " .. tostring(game.PlaceId))
    table.insert(lines, "Player: " .. LocalPlayer.Name)
    table.insert(lines, "Cash Start: " .. tostring(LiveStats.CashStart))
    table.insert(lines, "Cash Now: " .. tostring(GetCash()))
    table.insert(lines, "Cash Gained: " .. tostring(GetCash() - LiveStats.CashStart))
    table.insert(lines, "Taps: " .. LiveStats.Taps .. " | Pickups: " .. LiveStats.Pickups)
    table.insert(lines, "Collects: " .. LiveStats.Collects .. " | Opens: " .. LiveStats.Opens)
    table.insert(lines, "Uptime: " .. math.floor(tick() - LiveStats.StartTime) .. "s")
    return table.concat(lines, "\n")
end

local function SaveAnalysis()
    safeCall(function()
        if type(writefile) == "function" then
            if type(isfolder) == "function" and not isfolder("DeltaHub") then makefolder("DeltaHub") end
            writefile("DeltaHub/UnboxAFactorHub_Analysis.txt", BuildAnalysis())
        end
    end)
end

task.spawn(function()
    task.wait(2)
    LiveStats.CashStart = GetCash()
    SaveAnalysis()
    while Alive do
        task.wait(ClampNumber(Config.Analyzer.SaveInterval, 60, 7200))
        if Config.Analyzer.Enabled then SaveAnalysis() end
    end
end)

-- ═══════════════════════════════════════════
-- CONFIG MANAGER
-- ═══════════════════════════════════════════
local CONFIG_FOLDER = "DeltaHub"
local CONFIG_FILE = "DeltaHub/UnboxV20.json"

local function DeepCopy(t)
    if typeof(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = DeepCopy(v) end
    return copy
end

local DefaultConfig = DeepCopy(Config)

local function SerializeValue(v)
    local t = typeof(v)
    if t == "Color3" then
        return { __type = "Color3", R = v.R, G = v.G, B = v.B }
    elseif t == "EnumItem" then
        return { __type = "EnumItem", EnumType = tostring(v.EnumType):gsub("Enum.", ""), Name = v.Name }
    elseif t == "table" then
        local out = {}
        for k, val in pairs(v) do out[k] = SerializeValue(val) end
        return out
    else
        return v
    end
end

local function DeserializeValue(v)
    if typeof(v) == "table" then
        if v.__type == "Color3" then
            return Color3.new(v.R or 1, v.G or 1, v.B or 1)
        elseif v.__type == "EnumItem" then
            local ok, enum = pcall(function() return Enum[v.EnumType][v.Name] end)
            if ok then return enum end
            return nil
        else
            local out = {}
            for k, val in pairs(v) do out[k] = DeserializeValue(val) end
            return out
        end
    else
        return v
    end
end

local function DeepMerge(target, source)
    for k, v in pairs(source) do
        if typeof(v) == "table" and typeof(target[k]) == "table" then
            DeepMerge(target[k], v)
        else
            if v ~= nil then target[k] = v end
        end
    end
end

local function SaveConfig()
    local ok = false
    safeCall(function()
        if type(isfolder) == "function" and not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        writefile(CONFIG_FILE, HttpService:JSONEncode(SerializeValue(Config)))
        ok = true
    end)
    return ok
end

local function LoadConfig()
    local ok = false
    safeCall(function()
        if type(isfile) == "function" and isfile(CONFIG_FILE) then
            local loaded = DeserializeValue(HttpService:JSONDecode(readfile(CONFIG_FILE)))
            DeepMerge(Config, loaded)
            ok = true
        end
    end)
    return ok
end

local function ResetConfig()
    local defaults = DeepCopy(DefaultConfig)
    for k in pairs(Config) do Config[k] = nil end
    DeepMerge(Config, defaults)
end

LoadConfig()

-- ═══════════════════════════════════════════
-- PATTERNS + تصنيف (صناديق / مصانع / روبوكس)
-- ═══════════════════════════════════════════
local CRATE_PATTERNS = { "crate", "chest", "case", "unbox", "mystery", "loot", "present", "gift", "cube" }
local FACTORY_PATTERNS = { "factory", "machine", "lumber", "copper", "brick", "generator", "worker", "conveyor", "sawmill", "tank" }
local MONEY_PATTERNS = { "coin", "cash", "money", "gem", "token", "drop", "collect", "pad", "hexagon", "candy", "chest", "star" }
local ROBUX_KEYWORDS = { "robux", "r$", "premium", "gamepass", "game pass", "vip", "real money", "purchase", "donate", "support us" }

local function MatchPatterns(name, patterns)
    local lower = name:lower()
    for _, p in ipairs(patterns) do
        if lower:find(p, 1, true) then return true end
    end
    return false
end

local function TextIsRobux(text)
    if typeof(text) ~= "string" then return false end
    local lower = text:lower()
    for _, kw in ipairs(ROBUX_KEYWORDS) do
        if lower:find(kw, 1, true) then return true end
    end
    return false
end

-- تصنيف كائن: crate / factory / robux / unknown
-- الأولوية: crate > robux > factory (إذا اجتمع اسمين، الصندوق يفوز)
local function ClassifyInstance(obj)
    local hasCrate, hasFactory, hasRobux = false, false, false
    local cur = obj
    for _ = 1, 6 do
        if cur == nil or cur == Workspace then break end
        local name = cur.Name
        if typeof(name) == "string" then
            if MatchPatterns(name, CRATE_PATTERNS) then hasCrate = true end
            if MatchPatterns(name, FACTORY_PATTERNS) then hasFactory = true end
            if TextIsRobux(name) then hasRobux = true end
        end
        cur = cur.Parent
    end
    if hasRobux then return "robux" end
    if hasCrate then return "crate" end
    if hasFactory then return "factory" end
    return "unknown"
end

-- ═══════════════════════════════════════════
-- REMOTES (مثبتة من RemoteSpy V6)
-- ═══════════════════════════════════════════
local REM = {}
safeCall(function()
    local ev = ReplicatedStorage:WaitForChild("Events", 10)
    if ev then
        REM.MachineClickEvent = ev:FindFirstChild("MachineClickEvent")
        REM.UpdateUpgradeSignEvent = ev:FindFirstChild("UpdateUpgradeSignEvent")
        REM.PickupCrateEvent = ev:FindFirstChild("PickupCrateEvent")
        REM.OpenBackpackEggEvent = ev:FindFirstChild("OpenBackpackEggEvent")
        REM.DoMachineAnimationEvent = ev:FindFirstChild("DoMachineAnimationEvent")
    end
end)

-- ═══════════════════════════════════════════
-- INTERACTION HELPERS
-- ═══════════════════════════════════════════
local function FireClickReliable(click)
    if typeof(click) ~= "Instance" then return false end
    if type(fireclickdetector) == "function" then
        pcall(function() fireclickdetector(click) end)
        return true
    end
    return false
end

local function FirePromptReliable(prompt)
    if typeof(prompt) ~= "Instance" then return false end
    pcall(function() if not prompt.Enabled then prompt.Enabled = true end end)
    if type(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt) end)
        return true
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.delay(SafeNumber(prompt.HoldDuration, 0) + 0.05, function()
            pcall(function() prompt:InputHoldEnd() end)
        end)
    end)
    return true
end

local function TouchPart(root, part)
    if type(firetouchinterest) == "function" then
        pcall(function() firetouchinterest(root, part, 0) end)
        task.wait(0.04)
        pcall(function() firetouchinterest(root, part, 1) end)
        return true
    end
    return false
end

local function SafeTeleport(root, part, range)
    local dist = (part.Position - root.Position).Magnitude
    if dist <= range then return false end
    pcall(function() root.CFrame = part.CFrame + Vector3.new(0, 4, 0) end)
    task.wait(0.05)
    return true
end

local function GetPartOf(obj)
    if typeof(obj) ~= "Instance" then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart") end
    local p = obj:FindFirstAncestorOfClass("Model")
    if p then return p.PrimaryPart or p:FindFirstChildOfClass("BasePart") end
    return obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent or nil
end

-- ═══════════════════════════════════════════
-- CACHE: فلوس المصانع + دروب العالم
-- ═══════════════════════════════════════════
local WORLD_DROP_FOLDERS = {
    "FoodDrops", "ClientCoinsGems", "TouchHexagons", "FishIndexChests",
    "SunshineMysteryBoxHexagons", "HiddenChests", "FallenCandy", "PondRewardSigns",
}

local CollectCache = { Parts = {}, Building = false }

local function GetPlayerPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, p in ipairs(plots:GetChildren()) do
        if p.Name:find(LocalPlayer.Name, 1, true) then return p end
    end
    return nil
end

local function IsMoneyPart(obj)
    if not obj:IsA("BasePart") then return false end
    if MatchPatterns(obj.Name, MONEY_PATTERNS) then return true end
    local ok, kids = pcall(function() return obj:GetChildren() end)
    if not ok then return false end
    for _, child in ipairs(kids) do
        if child:IsA("BillboardGui") then
            local label = child:FindFirstChildOfClass("TextLabel")
            if label and typeof(label.Text) == "string" then
                if label.Text:find("$", 1, true) or label.Text:lower():find("token", 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

local function BuildCollectCache()
    if CollectCache.Building then return end
    CollectCache.Building = true
    task.spawn(function()
        local list = {}
        -- 1) دروب العالم (مجلدات معروفة)
        if Config.CollectMoney.WorldDrops then
            for _, folderName in ipairs(WORLD_DROP_FOLDERS) do
                local folder = Workspace:FindFirstChild(folderName)
                if folder then
                    local ok, desc = pcall(function() return folder:GetDescendants() end)
                    if ok then
                        for _, obj in ipairs(desc) do
                            if obj:IsA("BasePart") and #list < 300 then
                                table.insert(list, obj)
                            end
                        end
                    end
                end
            end
        end
        -- 2) فلوس المصانع داخل الـ Plot (منصات + دروب)
        if Config.CollectMoney.FactoryMoney then
            local plot = GetPlayerPlot()
            if plot then
                local ok, desc = pcall(function() return plot:GetDescendants() end)
                if ok then
                    local i = 0
                    for _, obj in ipairs(desc) do
                        i = i + 1
                        if i % 150 == 0 then task.wait(0.03) end
                        if #list >= 300 then break end
                        if IsValid(obj) and obj:IsA("BasePart") and IsMoneyPart(obj) then
                            table.insert(list, obj)
                        end
                    end
                end
            end
        end
        CollectCache.Parts = list
        CollectCache.Building = false
    end)
end

-- ═══════════════════════════════════════════
-- CACHE: بromptات الصناديق (Pick Up! فقط)
-- ═══════════════════════════════════════════
local PromptCache = { Prompts = {}, Building = false }

local function IsPickupAction(text)
    if typeof(text) ~= "string" then return false end
    local lower = text:lower()
    -- "pick up!" / "pick up" فقط — لا "pickup" (هذا للمصانع)
    return lower:find("pick up", 1, true) ~= nil
end

local function BuildPromptCache()
    if PromptCache.Building then return end
    PromptCache.Building = true
    task.spawn(function()
        local list = {}
        local ok, desc = pcall(function() return Workspace:GetDescendants() end)
        if ok then
            local i = 0
            for _, obj in ipairs(desc) do
                i = i + 1
                if i % 400 == 0 then task.wait(0.03) end
                if obj:IsA("ProximityPrompt") and IsPickupAction(obj.ActionText) then
                    local cls = ClassifyInstance(obj)
                    if cls == "crate" or (cls == "unknown" and Config.CratePickup.AllowUnknown) then
                        if #list < 30 then
                            table.insert(list, obj)
                        end
                    end
                end
            end
        end
        PromptCache.Prompts = list
        PromptCache.Building = false
    end)
end

-- ═══════════════════════════════════════════
-- AUTO TAP XP (ريموت مثبت + ClickDetector)
-- ═══════════════════════════════════════════
local TapCache = { Click = nil, Last = 0 }

local function RefreshTapCache()
    local root = GetRootDirect()
    local best, bestD = nil, math.huge
    safeCall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                local parent = obj.Parent
                if parent and parent:IsA("BasePart") then
                    local d = root and (parent.Position - root.Position).Magnitude or 0
                    if d < bestD then bestD = d; best = obj end
                end
            end
        end
    end)
    TapCache.Click = best
    TapCache.Last = tick()
end

local function DoTapCycle()
    local root = GetRootDirect()
    local tapped = false
    if Config.TapXP.UseRemote and REM.MachineClickEvent then
        safeCall(function() REM.MachineClickEvent:FireServer("ManualMachine") end)
        tapped = true
    end
    if Config.TapXP.UseSignRemote and REM.UpdateUpgradeSignEvent then
        safeCall(function() REM.UpdateUpgradeSignEvent:FireServer("ManualMachine", 15) end)
        tapped = true
    end
    if tapped then LiveStats.Taps = LiveStats.Taps + 1 end
    if Config.TapXP.UseClick then
        if tick() - TapCache.Last > 15 then RefreshTapCache() end
        if TapCache.Click and root then
            local parent = TapCache.Click.Parent
            if parent and parent:IsA("BasePart") then
                local d = (parent.Position - root.Position).Magnitude
                if d > 14 and Config.TapXP.Teleport then
                    SafeTeleport(root, parent, 12)
                    d = (parent.Position - root.Position).Magnitude
                end
                if d <= 16 then
                    if FireClickReliable(TapCache.Click) then LiveStats.Taps = LiveStats.Taps + 1 end
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(2)
    RefreshTapCache()
    while Alive do
        task.wait(ClampNumber(Config.TapXP.Delay, 0.1, 5))
        if Config.TapXP.Enabled then safeCall(DoTapCycle) end
    end
end)

-- ═══════════════════════════════════════════
-- AUTO COLLECT (فلوس المصانع + دروب العالم)
-- ═══════════════════════════════════════════
local function CollectCycle()
    local root = GetRootDirect()
    if not root then return end
    local touched = 0
    local list = CollectCache.Parts
    for idx = #list, 1, -1 do
        if touched >= Config.CollectMoney.Batch then break end
        local obj = list[idx]
        if not IsValid(obj) then
            table.remove(list, idx)
        else
            local d = (obj.Position - root.Position).Magnitude
            if d <= Config.CollectMoney.Radius then
                if d > 8 and Config.CollectMoney.Teleport then
                    SafeTeleport(root, obj, 6)
                end
                if TouchPart(root, obj) then
                    touched = touched + 1
                    LiveStats.Collects = LiveStats.Collects + 1
                    table.remove(list, idx)
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(2)
    BuildCollectCache()
    while Alive do
        task.wait(ClampNumber(Config.CollectMoney.Delay, 0.1, 5))
        if Config.CollectMoney.Enabled then
            safeCall(CollectCycle)
            if (tick() % 2) < Config.CollectMoney.Delay then BuildCollectCache() end
        end
    end
end)

task.spawn(function()
    while Alive do
        task.wait(1.5)
        if Config.CollectMoney.Enabled then BuildCollectCache() end
    end
end)

-- ═══════════════════════════════════════════
-- AUTO PICKUP CRATES (الصناديق فقط — المصانع محمية)
-- ═══════════════════════════════════════════
local function CratePickupCycle()
    local root = GetRootDirect()
    if not root then return end
    local fired = 0
    local list = PromptCache.Prompts
    for idx = #list, 1, -1 do
        if fired >= Config.CratePickup.MaxPerCycle then break end
        local prompt = list[idx]
        if not IsValid(prompt) then
            table.remove(list, idx)
        else
            local part = GetPartOf(prompt)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d <= Config.CratePickup.Range then
                    if d > 12 and Config.CratePickup.Teleport then
                        SafeTeleport(root, part, 10)
                    end
                    if FirePromptReliable(prompt) then
                        fired = fired + 1
                        LiveStats.Pickups = LiveStats.Pickups + 1
                    end
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(2)
    BuildPromptCache()
    while Alive do
        task.wait(ClampNumber(Config.CratePickup.Delay, 0.3, 10))
        if Config.CratePickup.Enabled then safeCall(CratePickupCycle) end
    end
end)

task.spawn(function()
    while Alive do
        task.wait(2.5)
        if Config.CratePickup.Enabled then BuildPromptCache() end
    end
end)

-- ═══════════════════════════════════════════
-- AUTO OPEN CRATES (backpack فقط)
-- ═══════════════════════════════════════════
local function GetGuiByPath(path)
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local cur = pg
    for seg in path:gmatch("[^.]+") do
        if not cur then return nil end
        cur = cur:FindFirstChild(seg)
    end
    return cur
end

local function ResolveButton(container)
    if typeof(container) ~= "Instance" then return nil end
    if container:IsA("TextButton") or container:IsA("ImageButton") then return container end
    local sh = container:FindFirstChild("Shadow")
    if sh and (sh:IsA("TextButton") or sh:IsA("ImageButton")) then return sh end
    return container:FindFirstChildOfClass("TextButton") or container:FindFirstChildOfClass("ImageButton")
end

local function ClickGuiButton(btn)
    if typeof(btn) ~= "Instance" then return false end
    local done = false
    pcall(function() btn:Activate() done = true end)
    if not done then
        pcall(function()
            local pos = btn.AbsolutePosition
            local size = btn.AbsoluteSize
            game:GetService("VirtualInputManager"):SendMouseButtonEvent(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5, 0, true, game, 0)
            task.wait(0.05)
            game:GetService("VirtualInputManager"):SendMouseButtonEvent(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5, 0, false, game, 0)
            done = true
        end)
    end
    return done
end

task.spawn(function()
    task.wait(3)
    while Alive do
        task.wait(ClampNumber(Config.OpenCrates.Delay, 0.5, 10))
        if Config.OpenCrates.Enabled and REM.OpenBackpackEggEvent then
            safeCall(function()
                local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                if not bp then return end
                local opened = 0
                for _, tool in ipairs(bp:GetChildren()) do
                    if opened >= Config.OpenCrates.MaxPerCycle then break end
                    if tool:IsA("Tool") and tonumber(tool.Name) then
                        safeCall(function() REM.OpenBackpackEggEvent:FireServer(tool.Name) end)
                        opened = opened + 1
                        LiveStats.Opens = LiveStats.Opens + 1
                    end
                end
                if opened > 0 and Config.OpenCrates.Skip then
                    task.wait(0.3)
                    ClickGuiButton(ResolveButton(GetGuiByPath("EggCrateOpeningUI.Frame.SkipButton")))
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════
-- LUCK BOOST
-- ═══════════════════════════════════════════
local function ApplyLuck()
    if not Config.Luck.Enabled then return end
    local mult = ClampNumber(Config.Luck.Multiplier, 1, 1000)
    safeCall(function()
        for _, target in ipairs({ LocalPlayer, GetHumanoid() }) do
            if IsValid(target) then
                local attrs = target:GetAttributes()
                for name, val in pairs(attrs) do
                    if type(val) == "number" and name:lower():find("luck", 1, true) then
                        pcall(function() target:SetAttribute(name, val * mult) end)
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    task.wait(3)
    ApplyLuck()
    while Alive do
        task.wait(5)
        if Config.Luck.Enabled then ApplyLuck() end
    end
end)

-- ═══════════════════════════════════════════
-- SPAM FILTER
-- ═══════════════════════════════════════════
local SPAM_PHRASES = { "you have not reached all the requirements", "gift expired" }

local function IsSpamText(text)
    if typeof(text) ~= "string" then return false end
    local lower = text:lower()
    for _, phrase in ipairs(SPAM_PHRASES) do
        if lower:find(phrase, 1, true) then return true end
    end
    return false
end

task.spawn(function()
    while Alive do
        task.wait(1)
        if Config.SpamFilter.Enabled then
            safeCall(function()
                local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
                if not pg then return end
                for _, guiName in ipairs({ "OnScreenTextUI", "CentreMessage", "MainUi" }) do
                    local gui = pg:FindFirstChild(guiName)
                    if gui then
                        for _, obj in ipairs(gui:GetDescendants()) do
                            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
                                if IsSpamText(obj.Text) then
                                    pcall(function() obj.Visible = false end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════
-- MOVEMENT ENGINE
-- ═══════════════════════════════════════════
Config.Movement = Config.Movement or {}
Config.Movement.Speed = Config.Movement.Speed or {}
Config.Movement.HighJump = Config.Movement.HighJump or {}
Config.Movement.AirJump = Config.Movement.AirJump or {}
Config.Movement.InfiniteJump = Config.Movement.InfiniteJump or {}
Config.Movement.NoClip = Config.Movement.NoClip or {}
Config.Movement.Fly = Config.Movement.Fly or {}

Config.Movement.Speed.Enabled = Config.Movement.Speed.Enabled == true
Config.Movement.Speed.Speed = Config.Movement.Speed.Speed or 60
if Config.Movement.Speed.VelocityFallback == nil then Config.Movement.Speed.VelocityFallback = true end
Config.Movement.Speed.VelocityStrength = Config.Movement.Speed.VelocityStrength or 0.65
Config.Movement.HighJump.Enabled = Config.Movement.HighJump.Enabled == true
Config.Movement.HighJump.JumpPower = Config.Movement.HighJump.JumpPower or 40
if Config.Movement.HighJump.VelocityBoost == nil then Config.Movement.HighJump.VelocityBoost = true end
Config.Movement.AirJump.Enabled = Config.Movement.AirJump.Enabled == true
Config.Movement.AirJump.Jumps = Config.Movement.AirJump.Jumps or 3
if Config.Movement.AirJump.Unlimited == nil then Config.Movement.AirJump.Unlimited = false end
Config.Movement.AirJump.Power = Config.Movement.AirJump.Power or 90
Config.Movement.AirJump.Mode = Config.Movement.AirJump.Mode or "Add"
Config.Movement.AirJump.MaxVelocity = Config.Movement.AirJump.MaxVelocity or 280
Config.Movement.InfiniteJump.Enabled = Config.Movement.InfiniteJump.Enabled == true
Config.Movement.NoClip.Enabled = Config.Movement.NoClip.Enabled == true
Config.Movement.Fly.Enabled = Config.Movement.Fly.Enabled == true
Config.Movement.Fly.Speed = Config.Movement.Fly.Speed or 60
Config.Movement.Fly.Accel = Config.Movement.Fly.Accel or 100
Config.Movement.Fly.MaxSpeed = Config.Movement.Fly.MaxSpeed or 200

local Movement = {}
Movement.Humanoid = nil
Movement.Root = nil
Movement.JumpCount = 0
Movement.LastJumpTrigger = 0
Movement._airStateConn = nil
Movement._airJumpPropConn = nil
Movement._loopConn = nil
Movement._highJumpStateConn = nil
Movement._noclipConn = nil
Movement._noclipAddConn = nil
Movement._noclipParts = {}
Movement._flyConn = nil
Movement._flyBody = nil

local MovementEnv = nil
if type(getgenv) == "function" then
    pcall(function() MovementEnv = getgenv() end)
end

local function DisconnectMovementSignal(signal)
    if signal then pcall(function() signal:Disconnect() end) end
end

if MovementEnv then
    safeCall(function()
        if MovementEnv.DeltaMovementCleanup then MovementEnv.DeltaMovementCleanup() end
    end)
    DisconnectMovementSignal(MovementEnv.DeltaMovementJumpRequest)
    DisconnectMovementSignal(MovementEnv.DeltaMovementCharacterAdded)
    DisconnectMovementSignal(MovementEnv.DeltaMovementCharacterRemoving)
end

local MovementOriginals = MovementEnv and MovementEnv.DeltaMovementOriginals or nil
if type(MovementOriginals) ~= "table" then
    MovementOriginals = setmetatable({}, { __mode = "k" })
end
if MovementEnv then MovementEnv.DeltaMovementOriginals = MovementOriginals end
Movement.Originals = MovementOriginals
Movement.NoClipOriginals = setmetatable({}, { __mode = "k" })

local function IsGroundedState(state)
    return state == Enum.HumanoidStateType.Landed
        or state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.RunningNoPhysics
        or state == Enum.HumanoidStateType.Climbing
        or state == Enum.HumanoidStateType.Seated
end

local function GetVelocity(root)
    local vel = Vector3.zero
    local ok, v = pcall(function() return root.AssemblyLinearVelocity end)
    if not ok then ok, v = pcall(function() return root.Velocity end) end
    if ok and typeof(v) == "Vector3" then vel = v end
    return vel
end

local function SetRootVelocity(root, vel)
    if typeof(root) ~= "Instance" or typeof(vel) ~= "Vector3" then return end
    pcall(function() root.AssemblyLinearVelocity = vel end)
    pcall(function() root.Velocity = vel end)
end

local function CaptureOriginal(humanoid)
    if typeof(humanoid) ~= "Instance" or Movement.Originals[humanoid] then return end
    local original = {}
    pcall(function() original.WalkSpeed = humanoid.WalkSpeed end)
    pcall(function() original.JumpPower = humanoid.JumpPower end)
    pcall(function() original.JumpHeight = humanoid.JumpHeight end)
    pcall(function() original.UseJumpPower = humanoid.UseJumpPower end)
    Movement.Originals[humanoid] = original
end

local function ApplySpeed(humanoid)
    if typeof(humanoid) ~= "Instance" then return end
    CaptureOriginal(humanoid)
    local cfg = Config.Movement.Speed
    local original = Movement.Originals[humanoid]
    if cfg.Enabled then
        pcall(function() humanoid.WalkSpeed = ClampNumber(SafeNumber(cfg.Speed, 60), 16, 1000) end)
    else
        pcall(function() humanoid.WalkSpeed = ClampNumber(SafeNumber(original and original.WalkSpeed, 16), 0, 1000) end)
    end
end

local function ApplyHighJump(humanoid)
    if typeof(humanoid) ~= "Instance" then return end
    CaptureOriginal(humanoid)
    local cfg = Config.Movement.HighJump
    local original = Movement.Originals[humanoid]
    if cfg.Enabled then
        local jumpValue = ClampNumber(SafeNumber(cfg.JumpPower, 40), 50, 2000)
        pcall(function() humanoid.UseJumpPower = true end)
        pcall(function() humanoid.JumpPower = jumpValue end)
        local gravity = SafeNumber(Workspace.Gravity, 196.2)
        if gravity > 0 then
            pcall(function() humanoid.JumpHeight = (jumpValue * jumpValue) / (2 * gravity) end)
        end
    else
        if original then
            pcall(function() humanoid.UseJumpPower = original.UseJumpPower end)
            pcall(function() humanoid.JumpPower = SafeNumber(original.JumpPower, 50) end)
            pcall(function() humanoid.JumpHeight = SafeNumber(original.JumpHeight, 7.2) end)
        end
    end
end

local function GetJumpVelocity(humanoid)
    local jumpVelocity = 50
    local usePower = true
    pcall(function() usePower = humanoid.UseJumpPower end)
    if usePower then
        pcall(function()
            local jp = humanoid.JumpPower
            if typeof(jp) == "number" and jp == jp and jp > 0 then jumpVelocity = jp end
        end)
    else
        pcall(function()
            local jh = humanoid.JumpHeight
            local gravity = SafeNumber(Workspace.Gravity, 196.2)
            if typeof(jh) == "number" and jh == jh and jh > 0 and gravity > 0 then
                jumpVelocity = math.sqrt(2 * gravity * jh)
            end
        end)
    end
    return ClampNumber(jumpVelocity, 20, 2000)
end

local function GetAirJumpVelocity(humanoid)
    local airCfg = Config.Movement.AirJump
    local power = SafeNumber(airCfg.Power, 0)
    if power <= 0 then power = GetJumpVelocity(humanoid) end
    return ClampNumber(power, 20, 2000)
end

function Movement:DisconnectAir()
    DisconnectMovementSignal(self._airStateConn)
    DisconnectMovementSignal(self._airJumpPropConn)
    self._airStateConn = nil
    self._airJumpPropConn = nil
end

function Movement:DisconnectLoop()
    DisconnectMovementSignal(self._loopConn)
    self._loopConn = nil
end

function Movement:DisconnectHighJumpBoost()
    DisconnectMovementSignal(self._highJumpStateConn)
    self._highJumpStateConn = nil
end

function Movement:StopNoClip(restore)
    DisconnectMovementSignal(self._noclipConn)
    DisconnectMovementSignal(self._noclipAddConn)
    self._noclipConn = nil
    self._noclipAddConn = nil
    if restore then
        for _, part in ipairs(self._noclipParts) do
            if IsValid(part) then
                local original = self.NoClipOriginals[part]
                if original == nil then original = true end
                pcall(function() part.CanCollide = original end)
            end
        end
    end
    table.clear(self._noclipParts)
end

function Movement:StartNoClip()
    self:StopNoClip(false)
    local character = GetCharacter()
    if typeof(character) ~= "Instance" or not Config.Movement.NoClip.Enabled then return end
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(self._noclipParts, obj)
            if self.NoClipOriginals[obj] == nil then
                pcall(function() self.NoClipOriginals[obj] = obj.CanCollide end)
            end
        end
    end
    safeCall(function()
        self._noclipAddConn = character.DescendantAdded:Connect(function(obj)
            if not Config.Movement.NoClip.Enabled then return end
            if IsValid(obj) and obj:IsA("BasePart") then
                table.insert(self._noclipParts, obj)
                if self.NoClipOriginals[obj] == nil then
                    pcall(function() self.NoClipOriginals[obj] = obj.CanCollide end)
                end
            end
        end)
    end)
    safeCall(function()
        self._noclipConn = RunService.Stepped:Connect(function()
            if not Config.Movement.NoClip.Enabled then return end
            for _, part in ipairs(self._noclipParts) do
                if IsValid(part) and part.CanCollide then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end)
    end)
end

function Movement:UpdateNoClip()
    if Config.Movement.NoClip.Enabled then self:StartNoClip() else self:StopNoClip(true) end
end

function Movement:StopFly()
    DisconnectMovementSignal(self._flyConn)
    self._flyConn = nil
    if self._flyBody then
        pcall(function() self._flyBody:Destroy() end)
        self._flyBody = nil
    end
end

function Movement:StartFly()
    self:StopFly()
    local root = GetRootDirect()
    if typeof(root) ~= "Instance" or not Config.Movement.Fly.Enabled then return end
    safeCall(function()
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(Config.Movement.Fly.MaxSpeed * 100, Config.Movement.Fly.MaxSpeed * 100, Config.Movement.Fly.MaxSpeed * 100)
        bv.Velocity = Vector3.zero
        bv.Parent = root
        self._flyBody = bv
    end)
    safeCall(function()
        self._flyConn = RunService.Heartbeat:Connect(function()
            if not Config.Movement.Fly.Enabled then return end
            local r = GetRootDirect()
            if not r or not self._flyBody then return end
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local move = Vector3.zero
            local uis = UserInputService
            if uis:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
            local speed = ClampNumber(SafeNumber(Config.Movement.Fly.Speed, 60), 1, 500)
            if move.Magnitude > 0 then
                self._flyBody.Velocity = move.Unit * speed
            else
                self._flyBody.Velocity = Vector3.zero
            end
        end)
    end)
end

function Movement:UpdateFly()
    if Config.Movement.Fly.Enabled then self:StartFly() else self:StopFly() end
end

function Movement:TryAirJump(humanoid)
    local cfg = Config.Movement.AirJump
    if not cfg.Enabled then return end
    if typeof(humanoid) ~= "Instance" or not (humanoid.Health > 0) then return end
    local now = tick()
    if now - (self.LastJumpTrigger or 0) < 0.05 then return end
    self.LastJumpTrigger = now
    local ok, state = pcall(function() return humanoid:GetState() end)
    if not ok then return end
    if state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Flying then return end
    if IsGroundedState(state) then
        self.JumpCount = 1
        return
    end
    if cfg.Unlimited ~= true then
        local maxJumps = math.floor(ClampNumber(SafeNumber(cfg.Jumps, 3), 1, 999))
        if self.JumpCount >= maxJumps then return end
        self.JumpCount = self.JumpCount + 1
    end
    pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local root = GetRoot(humanoid)
    if typeof(root) ~= "Instance" then return end
    local currentVelocity = GetVelocity(root)
    local power = GetAirJumpVelocity(humanoid)
    local maxVelocity = ClampNumber(SafeNumber(cfg.MaxVelocity, 280), 50, 5000)
    local mode = tostring(cfg.Mode or "Add"):lower()
    local newY
    if mode == "set" then
        newY = power
    else
        newY = ClampNumber(currentVelocity.Y + power, -maxVelocity, maxVelocity)
    end
    SetRootVelocity(root, Vector3.new(currentVelocity.X, newY, currentVelocity.Z))
end

function Movement:SetupAir(humanoid)
    self:DisconnectAir()
    self.JumpCount = 0
    self.LastJumpTrigger = 0
    if typeof(humanoid) ~= "Instance" or not Config.Movement.AirJump.Enabled then return end
    safeCall(function()
        self._airStateConn = humanoid.StateChanged:Connect(function(_old, newState)
            if not Config.Movement.AirJump.Enabled then return end
            if IsGroundedState(newState) then self.JumpCount = 0 end
        end)
    end)
    safeCall(function()
        self._airJumpPropConn = humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
            if not Config.Movement.AirJump.Enabled then return end
            local jumpActive = false
            pcall(function() jumpActive = humanoid.Jump end)
            if jumpActive then self:TryAirJump(humanoid) end
        end)
    end)
end

function Movement:SetupHighJumpBoost(humanoid)
    self:DisconnectHighJumpBoost()
    local cfg = Config.Movement.HighJump
    if typeof(humanoid) ~= "Instance" or not cfg.Enabled or not cfg.VelocityBoost then return end
    safeCall(function()
        self._highJumpStateConn = humanoid.StateChanged:Connect(function(_old, newState)
            local currentCfg = Config.Movement.HighJump
            if not currentCfg.Enabled or not currentCfg.VelocityBoost then return end
            if newState ~= Enum.HumanoidStateType.Jumping then return end
            local root = GetRoot(humanoid)
            if typeof(root) ~= "Instance" then return end
            local currentVelocity = GetVelocity(root)
            local power = ClampNumber(SafeNumber(currentCfg.JumpPower, 40), 50, 2000)
            local newY = math.max(currentVelocity.Y, power)
            SetRootVelocity(root, Vector3.new(currentVelocity.X, newY, currentVelocity.Z))
        end)
    end)
end

function Movement:UpdateLoop()
    local needLoop = Config.Movement.Speed.Enabled or Config.Movement.HighJump.Enabled
    if not needLoop then
        self:DisconnectLoop()
        return
    end
    if self._loopConn then return end
    safeCall(function()
        self._loopConn = RunService.Heartbeat:Connect(function(_dt)
            local humanoid = self.Humanoid or GetHumanoid()
            if typeof(humanoid) ~= "Instance" or not (humanoid.Health > 0) then return end
            if Config.Movement.Speed.Enabled then
                local cfg = Config.Movement.Speed
                local speedValue = ClampNumber(SafeNumber(cfg.Speed, 60), 16, 1000)
                pcall(function()
                    if humanoid.WalkSpeed ~= speedValue then humanoid.WalkSpeed = speedValue end
                end)
                if cfg.VelocityFallback then
                    local root = GetRoot(humanoid)
                    if typeof(root) == "Instance" then
                        local okState, state = pcall(function() return humanoid:GetState() end)
                        if okState and not (
                            state == Enum.HumanoidStateType.Seated
                            or state == Enum.HumanoidStateType.Swimming
                            or state == Enum.HumanoidStateType.Flying
                        ) then
                            local moveDirection = humanoid.MoveDirection
                            if typeof(moveDirection) == "Vector3" and moveDirection.Magnitude > 0.01 then
                                local currentVelocity = GetVelocity(root)
                                local dir = moveDirection.Unit
                                local targetX = dir.X * speedValue
                                local targetZ = dir.Z * speedValue
                                local strength = ClampNumber(SafeNumber(cfg.VelocityStrength, 0.65), 0, 1)
                                local newX = currentVelocity.X + (targetX - currentVelocity.X) * strength
                                local newZ = currentVelocity.Z + (targetZ - currentVelocity.Z) * strength
                                SetRootVelocity(root, Vector3.new(newX, currentVelocity.Y, newZ))
                            end
                        end
                    end
                end
            end
            if Config.Movement.HighJump.Enabled then
                local cfg = Config.Movement.HighJump
                local jumpValue = ClampNumber(SafeNumber(cfg.JumpPower, 40), 50, 2000)
                pcall(function()
                    if humanoid.UseJumpPower ~= true then humanoid.UseJumpPower = true end
                end)
                pcall(function()
                    if humanoid.JumpPower ~= jumpValue then humanoid.JumpPower = jumpValue end
                end)
                local gravity = SafeNumber(Workspace.Gravity, 196.2)
                if gravity > 0 then
                    pcall(function() humanoid.JumpHeight = (jumpValue * jumpValue) / (2 * gravity) end)
                end
            end
        end)
    end)
end

function Movement:Apply(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
    if typeof(humanoid) ~= "Instance" then return end
    self.Humanoid = humanoid
    self.Root = GetRoot(humanoid)
    CaptureOriginal(humanoid)
    ApplySpeed(humanoid)
    ApplyHighJump(humanoid)
    self:SetupAir(humanoid)
    self:SetupHighJumpBoost(humanoid)
    self:UpdateLoop()
    self:UpdateNoClip()
    self:UpdateFly()
end

function Movement:Refresh()
    local character = GetCharacter()
    if typeof(character) == "Instance" then
        self:Apply(character)
    else
        self:Cleanup()
    end
end

function Movement:Cleanup()
    self:DisconnectAir()
    self:DisconnectLoop()
    self:DisconnectHighJumpBoost()
    self:StopNoClip(true)
    self:StopFly()
    self.Humanoid = nil
    self.Root = nil
    self.JumpCount = 0
    self.LastJumpTrigger = 0
end

safeCall(function()
    local jumpConnection = UserInputService.JumpRequest:Connect(function()
        Movement:TryAirJump(Movement.Humanoid or GetHumanoid())
    end)
    if MovementEnv then MovementEnv.DeltaMovementJumpRequest = jumpConnection end
end)

safeCall(function()
    UserInputService.JumpRequest:Connect(function()
        if Config.Movement.InfiniteJump.Enabled then
            local hum = GetHumanoid()
            if hum then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
    end)
end)

safeCall(function()
    local characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        task.spawn(function()
            local humanoid = character and character:WaitForChild("Humanoid", 5)
            if typeof(humanoid) == "Instance" then
                task.wait(0.1)
                safeCall(function() Movement:Apply(character) end)
            end
        end)
    end)
    if MovementEnv then MovementEnv.DeltaMovementCharacterAdded = characterAddedConnection end
end)

safeCall(function()
    local characterRemovingConnection = LocalPlayer.CharacterRemoving:Connect(function()
        safeCall(function()
            Movement:DisconnectAir()
            Movement:DisconnectLoop()
            Movement:DisconnectHighJumpBoost()
            Movement:StopNoClip(false)
            Movement:StopFly()
            Movement.Humanoid = nil
            Movement.Root = nil
            Movement.JumpCount = 0
            Movement.LastJumpTrigger = 0
        end)
    end)
    if MovementEnv then MovementEnv.DeltaMovementCharacterRemoving = characterRemovingConnection end
end)

if LocalPlayer.Character then
    task.spawn(function()
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if typeof(humanoid) ~= "Instance" and character then
            humanoid = character:WaitForChild("Humanoid", 5)
        end
        if typeof(humanoid) == "Instance" then
            safeCall(function() Movement:Apply(character) end)
        end
    end)
end

if MovementEnv then
    MovementEnv.DeltaMovementCleanup = function()
        safeCall(function() Movement:Cleanup() end)
    end
    MovementEnv.DeltaMovementDestroy = function()
        safeCall(function() Movement:Cleanup() end)
        DisconnectMovementSignal(MovementEnv.DeltaMovementJumpRequest)
        DisconnectMovementSignal(MovementEnv.DeltaMovementCharacterAdded)
        DisconnectMovementSignal(MovementEnv.DeltaMovementCharacterRemoving)
    end
end

-- ═══════════════════════════════════════════
-- PERFORMANCE ENGINE
-- ═══════════════════════════════════════════
local Perf = {}
Perf.OriginalLighting = { captured = false }
Perf.SavedPostFX = setmetatable({}, { __mode = "k" })
Perf.SavedEffects = setmetatable({}, { __mode = "k" })
Perf.SavedLights = setmetatable({}, { __mode = "k" })
Perf.EffectConn = nil
Perf.LightConn = nil
Perf.FPS = { frames = 0, last = tick(), value = 0, draw = nil, lastAdaptive = 0 }

local function SetFPS(n)
    if type(setfpscap) == "function" then
        pcall(setfpscap, math.floor(ClampNumber(n, 1, 9999)))
    end
end

local function CaptureLighting()
    if Perf.OriginalLighting.captured then return end
    local o = Perf.OriginalLighting
    o.captured = true
    safeCall(function() o.GlobalShadows = Lighting.GlobalShadows end)
    safeCall(function() o.ShadowSoftness = Lighting.ShadowSoftness end)
    safeCall(function() o.Brightness = Lighting.Brightness end)
    safeCall(function() o.FogEnd = Lighting.FogEnd end)
    safeCall(function() o.FogStart = Lighting.FogStart end)
    safeCall(function() o.Technology = Lighting.Technology end)
end

local function SetPostFX(off)
    local classes = { "BloomEffect", "BlurEffect", "ColorCorrectionEffect", "SunRaysEffect", "DepthOfFieldEffect" }
    if off then
        for _, obj in ipairs(Lighting:GetDescendants()) do
            for _, cls in ipairs(classes) do
                if obj:IsA(cls) then
                    local ok, enabled = pcall(function() return obj.Enabled end)
                    Perf.SavedPostFX[obj] = ok and enabled or true
                    pcall(function() obj.Enabled = false end)
                end
            end
        end
    else
        for obj, en in pairs(Perf.SavedPostFX) do pcall(function() obj.Enabled = en end) end
        table.clear(Perf.SavedPostFX)
    end
end

local EFFECT_CLASSES = { "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles" }

local function KillEffect(obj)
    for _, cls in ipairs(EFFECT_CLASSES) do
        if obj:IsA(cls) then
            local ok, enabled = pcall(function() return obj.Enabled end)
            Perf.SavedEffects[obj] = ok and enabled or true
            pcall(function() obj.Enabled = false end)
        end
    end
end

local function SetEffects(off)
    if off then
        task.spawn(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do pcall(KillEffect, obj) end
        end)
        if not Perf.EffectConn then
            Perf.EffectConn = Workspace.DescendantAdded:Connect(function(obj) pcall(KillEffect, obj) end)
        end
    else
        if Perf.EffectConn then pcall(function() Perf.EffectConn:Disconnect() end) Perf.EffectConn = nil end
        for obj, en in pairs(Perf.SavedEffects) do pcall(function() obj.Enabled = en end) end
        table.clear(Perf.SavedEffects)
    end
end

local LIGHT_CLASSES = { "PointLight", "SpotLight", "SurfaceLight" }

local function KillLight(obj)
    for _, cls in ipairs(LIGHT_CLASSES) do
        if obj:IsA(cls) then
            local ok, enabled = pcall(function() return obj.Enabled end)
            Perf.SavedLights[obj] = ok and enabled or true
            pcall(function() obj.Enabled = false end)
        end
    end
end

local function SetLights(off)
    if off then
        task.spawn(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do pcall(KillLight, obj) end
        end)
        if not Perf.LightConn then
            Perf.LightConn = Workspace.DescendantAdded:Connect(function(obj) pcall(KillLight, obj) end)
        end
    else
        if Perf.LightConn then pcall(function() Perf.LightConn:Disconnect() end) Perf.LightConn = nil end
        for obj, en in pairs(Perf.SavedLights) do pcall(function() obj.Enabled = en end) end
        table.clear(Perf.SavedLights)
    end
end

local PRESETS = {
    ["Ultra"] = { GlobalShadows = true, ShadowSoftness = 1, Brightness = 2, FogEnd = 100000, Tech = "ShadowMap", PostFXOff = false, EffectsOff = false, RemoveLights = false },
    ["High"] = { GlobalShadows = true, ShadowSoftness = 0.5, Brightness = 2, FogEnd = 40000, Tech = "ShadowMap", PostFXOff = false, EffectsOff = false, RemoveLights = false },
    ["Medium"] = { GlobalShadows = false, ShadowSoftness = 0, Brightness = 1.5, FogEnd = 12000, Tech = "ShadowMap", PostFXOff = true, EffectsOff = true, RemoveLights = false },
    ["Low"] = { GlobalShadows = false, ShadowSoftness = 0, Brightness = 1, FogEnd = 3000, Tech = "Voxel", PostFXOff = true, EffectsOff = true, RemoveLights = true },
    ["Potato"] = { GlobalShadows = false, ShadowSoftness = 0, Brightness = 1, FogEnd = 800, Tech = "Legacy", PostFXOff = true, EffectsOff = true, RemoveLights = true },
}

local function ApplyQuality(name)
    CaptureLighting()
    local p = PRESETS[name]
    if not p then return end
    pcall(function() Lighting.GlobalShadows = p.GlobalShadows end)
    pcall(function() Lighting.ShadowSoftness = p.ShadowSoftness end)
    pcall(function() Lighting.Brightness = p.Brightness end)
    pcall(function() Lighting.FogEnd = p.FogEnd end)
    pcall(function() Lighting.FogStart = 0 end)
    if p.Tech then
        local tech = Enum.Technology[p.Tech]
        if tech then pcall(function() Lighting.Technology = tech end) end
    end
    SetPostFX(p.PostFXOff)
    SetEffects(p.EffectsOff)
    SetLights(p.RemoveLights)
end

local function RestoreAll()
    local o = Perf.OriginalLighting
    if o.captured then
        pcall(function() Lighting.GlobalShadows = o.GlobalShadows end)
        pcall(function() Lighting.ShadowSoftness = o.ShadowSoftness end)
        pcall(function() Lighting.Brightness = o.Brightness end)
        pcall(function() Lighting.FogEnd = o.FogEnd end)
        pcall(function() Lighting.FogStart = o.FogStart end)
        if o.Technology then pcall(function() Lighting.Technology = o.Technology end) end
    end
    SetPostFX(false)
    SetEffects(false)
    SetLights(false)
    SetFPS(9999)
end

safeCall(function()
    if type(Drawing) ~= "table" and type(Drawing) ~= "userdata" then return end
    Perf.FPS.draw = Drawing.new("Text")
    Perf.FPS.draw.Text = "FPS: 0"
    Perf.FPS.draw.Center = false
    Perf.FPS.draw.Outline = true
    Perf.FPS.draw.OutlineColor = Color3.fromRGB(0, 0, 0)
    Perf.FPS.draw.Color = Color3.fromRGB(94, 255, 170)
    Perf.FPS.draw.Font = Drawing.Fonts.Plex
    Perf.FPS.draw.Position = Vector2.new(12, 12)
    Perf.FPS.draw.Size = 16
    Perf.FPS.draw.Visible = false
end)

CaptureLighting()
SetFPS(Config.Performance.FPSCap)

safeCall(function()
    local styleAccum = 0
    RunService:BindToRenderStep("DeltaPerfStyle", 200, function(dt)
        styleAccum = styleAccum + (dt or 0)
        if styleAccum < 0.25 then return end
        styleAccum = 0
        if typeof(Perf.FPS.draw) ~= "table" and typeof(Perf.FPS.draw) ~= "userdata" then return end
        local c = Config.Performance.FPSCounter
        pcall(function()
            Perf.FPS.draw.Size = c.Size
            Perf.FPS.draw.Position = Vector2.new(c.X, c.Y)
            Perf.FPS.draw.Outline = c.Outline
            Perf.FPS.draw.Visible = Config.Performance.ShowFPS
        end)
        if Perf.FPS.draw and Config.Performance.ShowFPS then
            pcall(function()
                Perf.FPS.draw.Text = "FPS: " .. tostring(Perf.FPS.value)
                if c.AutoColor then
                    if Perf.FPS.value >= 50 then Perf.FPS.draw.Color = Color3.fromRGB(94, 255, 170)
                    elseif Perf.FPS.value >= 30 then Perf.FPS.draw.Color = Color3.fromRGB(255, 210, 90)
                    else Perf.FPS.draw.Color = Color3.fromRGB(255, 94, 98) end
                else
                    Perf.FPS.draw.Color = c.Color
                end
            end)
        end
        if Config.Performance.AdaptiveQuality then
            local now = tick()
            if now - Perf.FPS.lastAdaptive >= 1.5 then
                Perf.FPS.lastAdaptive = now
                local fps = Perf.FPS.value
                if fps > 0 then
                    if fps < 28 then ApplyQuality("Potato")
                    elseif fps < 42 then ApplyQuality("Low")
                    elseif fps < 52 then ApplyQuality("Medium") end
                end
            end
        end
    end)
end)

safeCall(function()
    RunService:BindToRenderStep("DeltaPerf", 100, function()
        Perf.FPS.frames = Perf.FPS.frames + 1
        local now = tick()
        if now - Perf.FPS.last >= 0.5 then
            Perf.FPS.value = math.floor(Perf.FPS.frames / (now - Perf.FPS.last))
            Perf.FPS.frames = 0
            Perf.FPS.last = now
        end
    end)
end)

-- ═══════════════════════════════════════════
-- PROTECTION ENGINE
-- ═══════════════════════════════════════════
Config.Protection = Config.Protection or {}
Config.Protection.AntiKickBan = Config.Protection.AntiKickBan ~= false
Config.Protection.AntiAFK = Config.Protection.AntiAFK ~= false
Config.Protection.ExecutorCloak = Config.Protection.ExecutorCloak ~= false
Config.Protection.AutoDeleteReports = Config.Protection.AutoDeleteReports ~= false

local ProtectionEnv = nil
if type(getgenv) == "function" then
    pcall(function() ProtectionEnv = getgenv() end)
end

local ProtectionConnections = {}
local ReportHookedContainers = {}

if ProtectionEnv then
    safeCall(function()
        if ProtectionEnv.DeltaProtectionCleanup then ProtectionEnv.DeltaProtectionCleanup() end
    end)
end

local function AddProtectionConnection(conn)
    if conn then table.insert(ProtectionConnections, conn) end
    return conn
end

local function DisconnectProtectionConnections()
    for _, conn in ipairs(ProtectionConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(ProtectionConnections)
end

if ProtectionEnv then
    ProtectionEnv.DeltaProtectionConnections = ProtectionConnections
    ProtectionEnv.DeltaProtectionCleanup = function()
        safeCall(DisconnectProtectionConnections)
    end
end

local BAD_KEYWORDS = {
    "report", "abuse", "flag", "ticket", "complaint",
    "moderation", "detect", "cheat", "exploit", "ban",
    "kick", "punish", "blacklist", "anticheat", "security",
}

local function ContainsBadText(text)
    if typeof(text) ~= "string" then return false end
    local lower = text:lower()
    for i = 1, #BAD_KEYWORDS do
        if lower:find(BAD_KEYWORDS[i], 1, true) then return true end
    end
    return false
end

safeCall(function()
    if not Config.Protection.ExecutorCloak then return end
    if type(hookfunction) ~= "function" then return end
    if type(getexecutorname) == "function" then
        local oldGetName
        oldGetName = hookfunction(getexecutorname, function(...)
            if Config.Protection.ExecutorCloak then return "Roblox" end
            if type(oldGetName) == "function" then return oldGetName(...) end
            return ""
        end)
    end
    if type(identifyexecutor) == "function" then
        local oldIdentify
        oldIdentify = hookfunction(identifyexecutor, function(...)
            if Config.Protection.ExecutorCloak then return "Roblox", {} end
            if type(oldIdentify) == "function" then return oldIdentify(...) end
            return "", {}
        end)
    end
end)

safeCall(function()
    if not Config.Protection.AntiKickBan then return end
    if type(getrawmetatable) ~= "function" or type(newcclosure) ~= "function" then return end
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    if not oldNamecall then return end
    if type(setreadonly) == "function" then pcall(function() setreadonly(mt, false) end) end
    mt.__namecall = newcclosure(function(self, ...)
        local method = ""
        if type(getnamecallmethod) == "function" then
            local ok, m = pcall(getnamecallmethod)
            if ok and typeof(m) == "string" then method = m end
        end
        if Config.Protection.AntiKickBan then
            if typeof(self) == "Instance" and (method == "FireServer" or method == "InvokeServer") then
                if ContainsBadText(self.Name) then return nil end
            end
        end
        return oldNamecall(self, ...)
    end)
    if type(setreadonly) == "function" then pcall(function() setreadonly(mt, true) end) end
end)

safeCall(function()
    if not Config.Protection.AntiAFK then return end
    local conn = LocalPlayer.Idled:Connect(function()
        if not Config.Protection.AntiAFK then return end
        pcall(function() VirtualUser:CaptureController() end)
        pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
    end)
    AddProtectionConnection(conn)
end)

local function IsReportGuiObject(obj)
    if typeof(obj) ~= "Instance" then return false end
    if not Config.Protection.AutoDeleteReports then return false end
    if not ContainsBadText(obj.Name) then return false end
    return obj:IsA("LayerCollector") or obj:IsA("GuiObject")
end

local function RemoveReportObject(obj)
    if not IsReportGuiObject(obj) then return end
    pcall(function()
        if obj:IsA("LayerCollector") then obj.Enabled = false end
        if obj:IsA("GuiObject") then obj.Visible = false end
    end)
    pcall(function() obj:Destroy() end)
end

local function EnsureReportProtection()
    if not Config.Protection.AutoDeleteReports then return end
    local function HookContainer(container)
        if typeof(container) ~= "Instance" then return end
        if ReportHookedContainers[container] then return end
        ReportHookedContainers[container] = true
        safeCall(function()
            for _, obj in ipairs(container:GetDescendants()) do RemoveReportObject(obj) end
        end)
        local conn = container.DescendantAdded:Connect(function(obj)
            if Config.Protection.AutoDeleteReports then
                task.defer(function() RemoveReportObject(obj) end)
            end
        end)
        AddProtectionConnection(conn)
    end
    safeCall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then HookContainer(playerGui) end
    end)
end

EnsureReportProtection()

-- ═══════════════════════════════════════════
-- MENU (WindUI) — V20 بدون ESP
-- ═══════════════════════════════════════════
safeCall(function()
    local WindUISource = nil

    safeCall(function()
        WindUISource = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
    end)

    if not WindUISource and type(request) == "function" then
        safeCall(function()
            local res = request({
                Url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
                Method = "GET",
            })
            if res and res.Body then WindUISource = res.Body end
        end)
    end

    if not WindUISource and type(syn) == "table" and type(syn.request) == "function" then
        safeCall(function()
            local res = syn.request({
                Url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
                Method = "GET",
            })
            if res and res.Body then WindUISource = res.Body end
        end)
    end

    if not WindUISource then
        DeltaNotify("WindUI download failed - scripts still running", 8)
        return
    end

    local loadOk, WindUI = pcall(function() return loadstring(WindUISource)() end)
    if not loadOk or type(WindUI) ~= "table" then
        DeltaNotify("WindUI load failed - scripts still running", 8)
        return
    end

    local Window = WindUI:CreateWindow({
        Title = "Unbox a Factor Hub",
        Author = "V20 — FACTORY EDITION",
        Icon = "box",
        Theme = "Dark",
    })

    pcall(function() Window:SetToggleKey(Config.Settings.ToggleKey) end)

    local UIControls = {}

    local function Reg(path, ctrl)
        if ctrl then UIControls[#UIControls + 1] = { path = path, ctrl = ctrl } end
        return ctrl
    end

    local function RefreshUI()
        for _, item in ipairs(UIControls) do
            pcall(function()
                local val = GetPath(item.path)
                if val ~= nil and item.ctrl and item.ctrl.SetValue then
                    item.ctrl:SetValue(val)
                end
            end)
        end
    end

    local function GetKeyCode(name)
        local ok, key = pcall(function() return Enum.KeyCode[name] end)
        return ok and key or nil
    end

    -- ═══ AUTO TAB ═══
    local AutoTab = Window:Tab({ Title = "Auto", Icon = "zap" })

    local TapSec = AutoTab:Section({ Title = "⚡ Auto Tap XP", Box = true, BoxBorder = true, Opened = true })
    TapSec:Toggle({ Title = "Auto Tap XP", Value = Config.TapXP.Enabled, Callback = function(v) Config.TapXP.Enabled = v end })
    TapSec:Toggle({ Title = "Tap Remote", Value = Config.TapXP.UseRemote, Callback = function(v) Config.TapXP.UseRemote = v end })
    TapSec:Toggle({ Title = "Sign Remote (XP)", Value = Config.TapXP.UseSignRemote, Callback = function(v) Config.TapXP.UseSignRemote = v end })
    TapSec:Toggle({ Title = "ClickDetector", Value = Config.TapXP.UseClick, Callback = function(v) Config.TapXP.UseClick = v end })
    TapSec:Toggle({ Title = "Teleport to Machine", Value = Config.TapXP.Teleport, Callback = function(v) Config.TapXP.Teleport = v end })
    TapSec:Slider({ Title = "Delay (s)", Min = 0.1, Max = 3, Default = Config.TapXP.Delay, Rounding = 2, Callback = function(v) Config.TapXP.Delay = v end })

    local CollectSec = AutoTab:Section({ Title = "💰 Collect (فلوس المصانع)", Box = true, BoxBorder = true, Opened = true })
    CollectSec:Toggle({ Title = "Auto Collect", Value = Config.CollectMoney.Enabled, Callback = function(v) Config.CollectMoney.Enabled = v end })
    CollectSec:Toggle({ Title = "Factory Money", Value = Config.CollectMoney.FactoryMoney, Callback = function(v) Config.CollectMoney.FactoryMoney = v end })
    CollectSec:Toggle({ Title = "World Drops", Value = Config.CollectMoney.WorldDrops, Callback = function(v) Config.CollectMoney.WorldDrops = v end })
    CollectSec:Toggle({ Title = "Teleport", Value = Config.CollectMoney.Teleport, Callback = function(v) Config.CollectMoney.Teleport = v end })
    CollectSec:Slider({ Title = "Radius", Min = 20, Max = 500, Default = Config.CollectMoney.Radius, Rounding = 0, Callback = function(v) Config.CollectMoney.Radius = v end })
    CollectSec:Slider({ Title = "Batch", Min = 1, Max = 40, Default = Config.CollectMoney.Batch, Rounding = 0, Callback = function(v) Config.CollectMoney.Batch = v end })

    local PickupSec = AutoTab:Section({ Title = "📦 Crate Pickup (بدون المصانع)", Box = true, BoxBorder = true, Opened = true })
    PickupSec:Toggle({ Title = "Auto Pickup Crates", Value = Config.CratePickup.Enabled, Callback = function(v) Config.CratePickup.Enabled = v end })
    PickupSec:Toggle({ Title = "Teleport to Crate", Value = Config.CratePickup.Teleport, Callback = function(v) Config.CratePickup.Teleport = v end })
    PickupSec:Toggle({ Title = "Allow Unknown", Value = Config.CratePickup.AllowUnknown, Callback = function(v) Config.CratePickup.AllowUnknown = v end })
    PickupSec:Slider({ Title = "Range", Min = 20, Max = 500, Default = Config.CratePickup.Range, Rounding = 0, Callback = function(v) Config.CratePickup.Range = v end })
    PickupSec:Slider({ Title = "Max Per Cycle", Min = 1, Max = 10, Default = Config.CratePickup.MaxPerCycle, Rounding = 0, Callback = function(v) Config.CratePickup.MaxPerCycle = v end })

    local CrateSec2 = AutoTab:Section({ Title = " Auto Open Crates", Box = true, BoxBorder = true, Opened = true })
    CrateSec2:Toggle({ Title = "Auto Open Crates", Value = Config.OpenCrates.Enabled, Callback = function(v) Config.OpenCrates.Enabled = v end })
    CrateSec2:Toggle({ Title = "Skip Animation", Value = Config.OpenCrates.Skip, Callback = function(v) Config.OpenCrates.Skip = v end })
    CrateSec2:Slider({ Title = "Max Per Cycle", Min = 1, Max = 10, Default = Config.OpenCrates.MaxPerCycle, Rounding = 0, Callback = function(v) Config.OpenCrates.MaxPerCycle = v end })

    local LuckSec = AutoTab:Section({ Title = "🍀 Luck Boost", Box = true, BoxBorder = true, Opened = true })
    LuckSec:Toggle({ Title = "Luck Boost", Value = Config.Luck.Enabled, Callback = function(v) Config.Luck.Enabled = v; if v then ApplyLuck() end end })
    LuckSec:Slider({ Title = "Multiplier", Min = 1, Max = 1000, Default = Config.Luck.Multiplier, Rounding = 0, Callback = function(v) Config.Luck.Multiplier = v; ApplyLuck() end })

    local StatsSec = AutoTab:Section({ Title = "📊 Live Stats", Box = true, BoxBorder = true, Opened = true })
    StatsSec:Button({ Title = "Show Live Stats", Icon = "bar-chart", Callback = function()
        DeltaNotify("💰+" .. math.floor(GetCash() - LiveStats.CashStart)
            .. " | ⚡" .. LiveStats.Taps
            .. " | 📦" .. LiveStats.Pickups
            .. " | 💵" .. LiveStats.Collects, 6)
    end })
    StatsSec:Button({ Title = "Save Analysis Now", Icon = "save", Callback = function()
        SaveAnalysis()
        DeltaNotify("تم حفظ التحليل ✅", 4)
    end })

    -- ═══ MOVEMENT TAB ═══
    local MoveTab = Window:Tab({ Title = "Movement", Icon = "wind" })
    local MvSec = MoveTab:Section({ Title = "Movement (متطور)", Box = true, BoxBorder = true, Opened = true })
    MvSec:Toggle({ Title = "Speed", Value = Config.Movement.Speed.Enabled, Callback = function(v) Config.Movement.Speed.Enabled = v; Movement:Refresh() end })
    MvSec:Slider({ Title = "Walk Speed", Min = 16, Max = 500, Default = Config.Movement.Speed.Speed, Rounding = 0, Callback = function(v) Config.Movement.Speed.Speed = v; Movement:Refresh() end })
    MvSec:Toggle({ Title = "HighJump", Value = Config.Movement.HighJump.Enabled, Callback = function(v) Config.Movement.HighJump.Enabled = v; Movement:Refresh() end })
    MvSec:Slider({ Title = "Jump Power", Min = 50, Max = 500, Default = Config.Movement.HighJump.JumpPower, Rounding = 0, Callback = function(v) Config.Movement.HighJump.JumpPower = v; Movement:Refresh() end })
    MvSec:Toggle({ Title = "AirJump", Value = Config.Movement.AirJump.Enabled, Callback = function(v) Config.Movement.AirJump.Enabled = v; Movement:Refresh() end })
    MvSec:Slider({ Title = "AirJump Power", Min = 50, Max = 500, Default = Config.Movement.AirJump.Power, Rounding = 0, Callback = function(v) Config.Movement.AirJump.Power = v; Movement:Refresh() end })
    MvSec:Toggle({ Title = "Infinite Jump", Value = Config.Movement.InfiniteJump.Enabled, Callback = function(v) Config.Movement.InfiniteJump.Enabled = v end })
    MvSec:Toggle({ Title = "NoClip", Value = Config.Movement.NoClip.Enabled, Callback = function(v) Config.Movement.NoClip.Enabled = v; Movement:Refresh() end })
    MvSec:Toggle({ Title = "Fly", Value = Config.Movement.Fly.Enabled, Callback = function(v) Config.Movement.Fly.Enabled = v; Movement:Refresh() end })
    MvSec:Slider({ Title = "Fly Speed", Min = 10, Max = 500, Default = Config.Movement.Fly.Speed, Rounding = 0, Callback = function(v) Config.Movement.Fly.Speed = v end })

    -- ═══ PERFORMANCE TAB ═══
    local PerfTab = Window:Tab({ Title = "Performance", Icon = "gauge" })
    local PfSec = PerfTab:Section({ Title = "FPS", Box = true, BoxBorder = true, Opened = true })
    PfSec:Toggle({ Title = "Show FPS", Value = Config.Performance.ShowFPS, Callback = function(v) Config.Performance.ShowFPS = v end })
    PfSec:Slider({ Title = "FPS Cap", Min = 20, Max = 144, Default = Config.Performance.FPSCap, Rounding = 0, Callback = function(v) Config.Performance.FPSCap = v; SetFPS(v) end })
    PfSec:Button({ Title = "Unlimited FPS", Icon = "zap", Callback = function() SetFPS(9999) end })
    PfSec:Toggle({ Title = "Adaptive Quality", Value = Config.Performance.AdaptiveQuality, Callback = function(v) Config.Performance.AdaptiveQuality = v end })

    local QualSec = PerfTab:Section({ Title = "Graphics", Box = true, BoxBorder = true, Opened = true })
    QualSec:Dropdown({ Title = "Quality Preset", Values = { "Ultra", "High", "Medium", "Low", "Potato" }, Value = "Medium", Callback = function(v) ApplyQuality(v) end })
    QualSec:Toggle({ Title = "Disable Post-FX", Value = Config.Performance.PostFXOff, Callback = function(v) Config.Performance.PostFXOff = v; SetPostFX(v) end })
    QualSec:Toggle({ Title = "Disable Particles", Value = Config.Performance.EffectsOff, Callback = function(v) Config.Performance.EffectsOff = v; SetEffects(v) end })

    local ResetSec = PerfTab:Section({ Title = "Reset", Box = true, BoxBorder = true, Opened = true })
    ResetSec:Button({ Title = "Restore Original", Icon = "rotate-ccw", Color = Color3.fromRGB(255, 180, 80), Callback = function() RestoreAll() end })

    -- ═══ PROTECTION TAB ═══
    local ProtTab = Window:Tab({ Title = "Protection", Icon = "shield" })
    local PrSec = ProtTab:Section({ Title = "Protection", Box = true, BoxBorder = true, Opened = true })
    PrSec:Toggle({ Title = "Hide Spam Messages", Value = Config.SpamFilter.Enabled, Callback = function(v) Config.SpamFilter.Enabled = v end })
    PrSec:Toggle({ Title = "Anti Kick/Ban", Value = Config.Protection.AntiKickBan, Callback = function(v) Config.Protection.AntiKickBan = v end })
    PrSec:Toggle({ Title = "Anti-AFK", Value = Config.Protection.AntiAFK, Callback = function(v) Config.Protection.AntiAFK = v end })
    PrSec:Toggle({ Title = "Executor Cloak", Value = Config.Protection.ExecutorCloak, Callback = function(v) Config.Protection.ExecutorCloak = v end })
    PrSec:Toggle({ Title = "Auto Delete Reports", Value = Config.Protection.AutoDeleteReports, Callback = function(v) Config.Protection.AutoDeleteReports = v; if v then EnsureReportProtection() end end })

    -- ═══ SETTINGS TAB ═══
    local SetTab = Window:Tab({ Title = "Settings", Icon = "settings" })
    local ConfigSec = SetTab:Section({ Title = "Config", Box = true, BoxBorder = true, Opened = true })
    Reg("Settings.AutoSave", ConfigSec:Toggle({ Title = "Auto Save", Value = Config.Settings.AutoSave, Callback = function(v) Config.Settings.AutoSave = v end }))
    ConfigSec:Button({ Title = "Save", Icon = "save", Color = Color3.fromRGB(94, 255, 170), Callback = function()
        local ok = SaveConfig()
        safeCall(function() WindUI:Notify({ Title = "Unbox V20", Content = ok and "تم الحفظ ✅" or "فشل ❌", Duration = 3 }) end)
    end })
    ConfigSec:Button({ Title = "Load", Icon = "folder-open", Callback = function()
        local ok = LoadConfig()
        if ok then Movement:Refresh(); safeCall(RefreshUI) end
        safeCall(function() WindUI:Notify({ Title = "Unbox V20", Content = ok and "تم التحميل ✅" or "ما في ملف ❌", Duration = 3 }) end)
    end })
    ConfigSec:Button({ Title = "Reset", Icon = "rotate-ccw", Color = Color3.fromRGB(255, 180, 80), Callback = function()
        ResetConfig(); Movement:Refresh(); safeCall(RefreshUI)
    end })

    local MenuSec = SetTab:Section({ Title = "Menu", Box = true, BoxBorder = true, Opened = true })
    MenuSec:Keybind({ Title = "Toggle Key", Default = Enum.KeyCode.RightShift, Callback = function(key)
        local k = key
        if type(key) == "string" then k = GetKeyCode(key) end
        if k then pcall(function() Window:SetToggleKey(k) end) end
    end })
    MenuSec:Button({ Title = "Close Menu", Icon = "x", Callback = function() pcall(function() Window:Close() end) end })
    MenuSec:Button({ Title = "Destroy Script", Icon = "trash", Color = Color3.fromRGB(255, 80, 80), Callback = function()
        if Config.Settings.AutoSave then SaveConfig() end
        SaveAnalysis()
        Alive = false
        safeCall(function() RunService:UnbindFromRenderStep("DeltaPerf") end)
        safeCall(function() RunService:UnbindFromRenderStep("DeltaPerfStyle") end)
        safeCall(function() Movement:Cleanup() end)
        safeCall(function()
            if type(getgenv) == "function" then
                local env = getgenv()
                if env then
                    if env.DeltaMovementDestroy then env.DeltaMovementDestroy() end
                    if env.DeltaProtectionCleanup then env.DeltaProtectionCleanup() end
                end
            end
        end)
        safeCall(function() Window:Destroy() end)
    end })

    AutoTab:Select()

    safeCall(function()
        WindUI:Notify({
            Title = "Unbox a Factor V20",
            Content = "FACTORY EDITION ✅ فلوس + صناديق + حماية المصانع",
            Icon = "check",
            Duration = 6,
        })
    end)
end)

DeltaNotify("✅ Unbox V20 Loaded!", 5)
