--[[
╔═══════════════════════════════════════════════════════╗
║  UNBOX A FACTOR — V35 FINAL MASTER                    ║
║  Delta Executor (Mobile) | اللعبة: Unbox a Factor     ║
║  🧲 Magnet بدون مشي | ⚡ Tap | 💰 Collect | 📦 Open   ║
║  🍀 Luck |  Movement كامل التحكم (Movement.lua)     ║
║  ⚙️ Performance | 🛡 Protection | 🚫 SpamFix          ║
║  🚫 بدون خط أخضر | 💾 حفظ تلقائي | 📄 ملف حالة       ║
╚═══════════════════════════════════════════════════════╝
]]
-- ═══ 1) CONFIG ═══
local Config = {
    TapXP = {
        Enabled = true,
        Delay = 0.2,
        UseRemote = true,
        UseClick = true,
    },
    Collect = {
        Enabled = true,
        Delay = 0.35,
        Radius = 250,
        Batch = 20,
        WorldDrops = true,
        FactoryMoney = true,
    },
    Magnet = {
        Enabled = true,
        Batch = 3,
        CycleDelay = 0.6,
        WalkFallback = false,
    },
    OpenCrates = {
        Enabled = true,
        Threshold = 10,
        MaxPerCycle = 3,
        Skip = true,
    },
    Luck = {
        Enabled = false,
        Multiplier = 100,
    },

    -- Movement.lua merged
    Movement = {
        Speed = {
            Enabled = false,
            Speed = 60,
            VelocityFallback = true,
            VelocityStrength = 0.65,
        },
        HighJump = {
            Enabled = false,
            JumpPower = 40,
            VelocityBoost = true,
        },
        AirJump = {
            Enabled = false,
            Jumps = 3,
            Unlimited = false,
            Power = 90,
            Mode = "Add",
            MaxVelocity = 280,
        },
        InfiniteJump = {
            Enabled = false,
        },
        NoClip = {
            Enabled = false,
        },
        Fly = {
            Enabled = false,
            Speed = 60,
            Accel = 100,
            MaxSpeed = 200,
        },
    },

    -- Movement.lua Performance
    Performance = {
        FPSCap = 60,
        ShowFPS = false,
        PostFXOff = false,
        EffectsOff = false,
        Shadows = true,
        FogDistance = 12000,
        Brightness = 1.5,
        AdaptiveQuality = false,
        LowDetail = false,
        RemoveLights = false,
        LowWater = false,
        FPSCounter = {
            Size = 16,
            X = 12,
            Y = 12,
            Outline = true,
            AutoColor = true,
            Color = Color3.fromRGB(94, 255, 170),
        },
    },

    -- Movement.lua Protection
    Protection = {
        AntiKickBan = true,
        AntiAFK = true,
        ExecutorCloak = true,
        AutoDeleteReports = true,
    },

    SpamFilter = true,

    Settings = {
        AutoSave = true,
        ToggleKey = Enum.KeyCode.RightShift,
    },
}

-- ═══ 2) SERVICES ═══
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
if LocalPlayer == nil then return end

-- ═══ 3) UTILS ═══
local Stats = { Taps = 0, Collects = 0, Fires = 0, Remote = 0, Triggered = 0, Extract = 0, Opens = 0, Skip = 0, NoID = 0, Err = 0, Back = 0 }
local LastErr = "none"
local LastIDs = {}
local IDMap = setmetatable({}, { __mode = "k" })
local ExtractCache = setmetatable({}, { __mode = "k" })
local function Notify(text, dur)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Unbox V35", Text = text, Duration = dur or 5 })
	end)
end
local function safeCall(fn, ...)
	local ok, e = pcall(fn, ...)
	if not ok then
		Stats.Err = Stats.Err + 1
		LastErr = tostring(e):sub(1, 50)
	end
	return ok
end
local Safe = safeCall
local function IsValid(inst) return inst ~= nil and typeof(inst) == "Instance" and inst.Parent ~= nil end
local function ClampNumber(n, min, max)
	if typeof(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then return min end
	if n < min then return min end
	if n > max then return max end
	return n
end
local function SafeNumber(value, defaultValue)
	if typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then return value end
	return defaultValue
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
local function GetRootDirect() return GetRoot(GetHumanoid()) end
local function WriteFile(path, content)
	if type(writefile) ~= "function" then return false end
	return pcall(function() writefile(path, content) end)
end
local function GetNumProp(inst, name, def)
	local ok, v = pcall(function() return inst[name] end)
	if ok and typeof(v) == "number" and v == v and v > 0 then return v end
	return def
end
local function MatchWords(name, words)
	for _, w in ipairs(words) do
		if name:find(w, 1, true) then return true end
	end
	return false
end
local BAD_KEYWORDS = { "report", "abuse", "flag", "ticket", "complaint", "moderation", "detect", "cheat", "exploit", "ban", "kick", "punish", "blacklist", "anticheat", "security" }
local function ContainsBadText(text)
	if typeof(text) ~= "string" then return false end
	local lower = text:lower()
	for i = 1, #BAD_KEYWORDS do
		if lower:find(BAD_KEYWORDS[i], 1, true) then return true end
	end
	return false
end
WriteFile("V35_Heartbeat.txt", os.date("%c") .. " | started")

-- ═══ 4) CONFIG MANAGER (Movement.lua merged) ═══
local CONFIG_FOLDER = "DeltaHub"
local CONFIG_FILE = "DeltaHub/UnboxMovementV35.json"

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
        local enumTypeName = tostring(v.EnumType):gsub("Enum.", "")
        return { __type = "EnumItem", EnumType = enumTypeName, Name = v.Name }
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
        local data = SerializeValue(Config)
        local json = HttpService:JSONEncode(data)
        writefile(CONFIG_FILE, json)
        ok = true
    end)
    return ok
end

local function LoadConfig()
    local ok = false
    safeCall(function()
        if type(isfile) == "function" and isfile(CONFIG_FILE) then
            local json = readfile(CONFIG_FILE)
            local data = HttpService:JSONDecode(json)
            local loaded = DeserializeValue(data)
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

local SaveQueued = false
local function QueueSave()
    if not Config.Settings.AutoSave or SaveQueued then return end
    SaveQueued = true
    task.delay(1, function()
        SaveQueued = false
        SaveConfig()
    end)
end

local function GetPath(path)
    local cur = Config
    for key in path:gmatch("[^.]+") do
        if typeof(cur) ~= "table" then return nil end
        cur = cur[key]
    end
    return cur
end

-- ═══ 5) REMOTES ═══
local REM = { Pickup = nil, Open = nil, Click = nil }
task.spawn(function()
	while REM.Pickup == nil do
		Safe(function()
			local ev = ReplicatedStorage:WaitForChild("Events", 5)
			if ev then
				REM.Pickup = ev:WaitForChild("PickupCrateEvent", 5)
				REM.Click = ev:FindFirstChild("MachineClickEvent")
				for _, n in ipairs({ "OpenBackpackEggEvent", "OpenCrateEvent", "OpenEggEvent", "CrateOpenEvent" }) do
					local r = ev:FindFirstChild(n)
					if r and REM.Open == nil then REM.Open = r end
				end
			end
		end)
		if REM.Pickup == nil then task.wait(3) end
	end
end)

-- ═══ 6) CLASSIFIER + PROMPT CACHE (محسّن) ═══
local CRATE_WORDS = { "crate", "cube", "chest", "case", "present", "gift", "loot", "mystery", "unbox" }
local FACTORY_WORDS = { "factory", "factories", "lumber", "copper", "iron", "brick", "sawmill", "smoothie", "generator", "conveyor", "miner", "windmill", "solar", "tank" }
local WORKER_WORDS = { "worker", "explorer", "farmer", "employee" }
local function NormAct(p)
	local ok, t = pcall(function() return p.ActionText end)
	if not ok or typeof(t) ~= "string" then return "" end
	t = t:lower():gsub("%s+", " ")
	return t:gsub("^ ", ""):gsub(" $", "")
end
local function ClassifyPrompt(prompt)
	local cur = prompt.Parent
	for _ = 1, 6 do
		if cur == nil or cur == Workspace then break end
		local nm = tostring(cur.Name):lower()
		if MatchWords(nm, CRATE_WORDS) then return "crate" end
		if MatchWords(nm, FACTORY_WORDS) then return "factory" end
		if MatchWords(nm, WORKER_WORDS) then return "worker" end
		cur = cur.Parent
	end
	return "unknown"
end
local Cache = {}
local Seen = {}
local function RegisterPrompt(obj)
	if typeof(obj) ~= "Instance" then return end
	if not obj:IsA("ProximityPrompt") then return end
	local act = NormAct(obj)
	if not act:find("pick", 1, true) then return end
	local cls = ClassifyPrompt(obj)
	local allow = (cls == "crate") or (cls == "unknown" and act == "pickup")
	if Seen[obj] == nil then
		Seen[obj] = true
		if not allow then Stats.Skip = Stats.Skip + 1 end
		pcall(function()
			obj.Triggered:Connect(function() Stats.Triggered = Stats.Triggered + 1 end)
		end)
	end
	if allow and #Cache < 40 then table.insert(Cache, obj) end
end
task.spawn(function()
	task.wait(2)
	Safe(function()
		Workspace.DescendantAdded:Connect(function(o)
			if Config.Magnet.Enabled then RegisterPrompt(o) end
		end)
	end)
	while true do
		task.wait(4)
		Safe(function()
			local list = {}
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("ProximityPrompt") then
					local act = NormAct(obj)
					if act:find("pick", 1, true) then
						local cls = ClassifyPrompt(obj)
						local allow = (cls == "crate") or (cls == "unknown" and act == "pickup")
						if Seen[obj] == nil then
							Seen[obj] = true
							if not allow then Stats.Skip = Stats.Skip + 1 end
							pcall(function()
								obj.Triggered:Connect(function() Stats.Triggered = Stats.Triggered + 1 end)
							end)
						end
						if allow and #list < 40 then table.insert(list, obj) end
					end
				end
			end
			Cache = list
		end)
	end
end)

-- ═══ 7) HELPERS ═══
local function GetPartOf(prompt)
	local cur = prompt.Parent
	for _ = 1, 3 do
		if cur == nil then return nil end
		if cur:IsA("BasePart") then return cur end
		if cur:IsA("Model") then return cur.PrimaryPart or cur:FindFirstChildOfClass("BasePart") end
		cur = cur.Parent
	end
	return nil
end
local function PromptRange(p)
	local md = GetNumProp(p, "MaxActivationDistance", 14)
	if md > 30 then md = 30 end
	return math.max(6, md - 2)
end
local function FirePrompt(prompt)
	pcall(function() if not prompt.Enabled then prompt.Enabled = true end end)
	if type(fireproximityprompt) == "function" then
		pcall(function() fireproximityprompt(prompt) end)
	end
	pcall(function()
		prompt:InputHoldBegin()
		task.delay(GetNumProp(prompt, "HoldDuration", 0) + 0.05, function() pcall(function() prompt:InputHoldEnd() end) end)
	end)
	Stats.Fires = Stats.Fires + 1
end
local function WalkTo(part, range, timeout)
	local hum = GetHumanoid()
	if hum == nil then return false end
	local t0 = tick()
	local last = 0
	while tick() - t0 < timeout do
		if not IsValid(part) then return false end
		local r = GetRootDirect()
		if r == nil then
			task.wait(0.2)
		else
			local d = (part.Position - r.Position).Magnitude
			if d <= range then return true end
			if tick() - last > 0.7 then
				last = tick()
				pcall(function() hum:MoveTo(part.Position) end)
			end
			task.wait(0.12)
		end
	end
	return false
end

-- ═══ 8) UPVALUE EXTRACTOR + LEARNER ═══
local function ScanVal(v, depth)
	if depth > 2 then return nil end
	local t = typeof(v)
	if t == "string" then
		if v:match("^%d+$") and #v <= 6 then return v end
	elseif t == "number" then
		if v == math.floor(v) and v >= 1 and v <= 999999 then return tostring(v) end
	elseif t == "Instance" then
		if typeof(v.Name) == "string" and v.Name:match("^%d+$") and #v.Name <= 6 then return v.Name end
	elseif t == "table" then
		for k, val in pairs(v) do
			local ks = tostring(k):lower()
			if ks:find("id", 1, true) or ks:find("crate", 1, true) or ks:find("uid", 1, true) then
				local r = ScanVal(val, depth + 1)
				if r then return r end
			end
		end
	end
	return nil
end
local function ExtractID(prompt)
	if ExtractCache[prompt] then return ExtractCache[prompt] end
	if type(getconnections) ~= "function" then return nil end
	if type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then return nil end
	local okC, conns = pcall(function() return getconnections(prompt.Triggered) end)
	if not okC or type(conns) ~= "table" then return nil end
	local found, fallback = nil, nil
	for _, conn in ipairs(conns) do
		local fn = conn.Function
		if type(fn) == "function" then
			local mine = false
			if type(isexecutorclosure) == "function" then
				local o, r = pcall(isexecutorclosure, fn)
				if o then mine = r end
			end
			if not mine then
				for i = 1, 12 do
					local okU, name, val = pcall(debug.getupvalue, fn, i)
					if not okU or name == nil then break end
					local ln = tostring(name):lower()
					local named = ln:find("id", 1, true) or ln:find("crate", 1, true) or ln:find("uid", 1, true)
					local r = ScanVal(val, 0)
					if r and named then
						found = r
						break
					elseif r and fallback == nil and not ln:find("hold", 1, true) and not ln:find("time", 1, true) and not ln:find("duration", 1, true) then
						fallback = r
					end
				end
				if found then break end
			end
		end
	end
	local id = found or fallback
	if id then
		ExtractCache[prompt] = id
		Stats.Extract = Stats.Extract + 1
	end
	return id
end
local function LearnCapture(rawID)
	local id = tostring(rawID)
	if not id:match("^%d+$") then return end
	table.insert(LastIDs, id)
	if #LastIDs > 8 then table.remove(LastIDs, 1) end
	local root = GetRootDirect()
	if root == nil then return end
	local best, bestD = nil, 14
	for _, p in ipairs(Cache) do
		if IsValid(p) then
			local part = GetPartOf(p)
			if part then
				local d = (part.Position - root.Position).Magnitude
				if d < bestD then bestD, best = d, p end
			end
		end
	end
	if best then IDMap[best] = id end
end

-- ═══ 9) NAMECALL HOOK (Capture + Movement.lua Protection merged) ═══
local HookOn = false
Safe(function()
    if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then return end
    local mt = getrawmetatable(game)
    if mt == nil then return end
    local old = mt.__namecall
    if old == nil then return end

    if type(setreadonly) == "function" then
        pcall(function() setreadonly(mt, false) end)
    end

    mt.__namecall = newcclosure(function(self, ...)
        local method = nil
        if type(getnamecallmethod) == "function" then
            local o, m = pcall(getnamecallmethod)
            if o then method = m end
        end

        if method == "FireServer" and typeof(self) == "Instance" then
            if self.Name == "PickupCrateEvent" then
                local a = table.pack(...)
                if a[1] ~= nil then
                    task.defer(function()
                        Safe(LearnCapture, a[1])
                    end)
                end
            end

            if (Config.Protection.AntiKickBan or Config.Protection.AutoDeleteReports) and ContainsBadText(self.Name) then
                return nil
            end
        end

        return old(self, ...)
    end)

    if type(setreadonly) == "function" then
        pcall(function() setreadonly(mt, true) end)
    end

    HookOn = true
end)

-- ═══ 10) 🧲 MAGNET (بدون مشي) ═══
local function CountCrates()
	local n = 0
	pcall(function()
		for _, cont in ipairs({ LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character }) do
			if IsValid(cont) then
				for _, t in ipairs(cont:GetChildren()) do
					if t:IsA("Tool") and tostring(t.Name):match("^%d+$") then n = n + 1 end
				end
			end
		end
	end)
	return n
end
local Busy = false
local function MagnetCycle()
	if Busy or #Cache == 0 then return end
	Busy = true
	task.spawn(function()
		Safe(function()
			local done = 0
			for _, p in ipairs(Cache) do
				if done >= Config.Magnet.Batch then break end
				if IsValid(p) then
					local id = ExtractID(p) or IDMap[p]
					if id and REM.Pickup then
						pcall(function() REM.Pickup:FireServer(id) end)
						Stats.Remote = Stats.Remote + 1
					else
						if Config.Magnet.WalkFallback then
							local part = GetPartOf(p)
							if part then
								local r = GetRootDirect()
								if r and (part.Position - r.Position).Magnitude > PromptRange(p) then
									WalkTo(part, PromptRange(p), 5)
								end
							end
						end
						FirePrompt(p)
						Stats.NoID = Stats.NoID + 1
					end
					done = done + 1
					task.wait(0.2)
				end
			end
		end)
		Busy = false
	end)
end
task.spawn(function()
	task.wait(2)
	while true do
		task.wait(Config.Magnet.CycleDelay)
		if Config.Magnet.Enabled then Safe(MagnetCycle) end
	end
end)

-- ═══ 11) 📦 AUTO OPEN ══
local function ClickSkip()
	Safe(function()
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pg == nil then return end
		local ui = pg:FindFirstChild("EggCrateOpeningUI")
		local btn = ui and ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("SkipButton")
		if btn == nil then return end
		pcall(function() btn:Activate() end)
	end)
end
task.spawn(function()
	task.wait(3)
	while true do
		task.wait(1)
		if Config.OpenCrates.Enabled and REM.Open then
			Safe(function()
				local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
				if bp == nil then return end
				local tools = {}
				for _, t in ipairs(bp:GetChildren()) do
					if t:IsA("Tool") and tostring(t.Name):match("^%d+$") then table.insert(tools, t) end
				end
				if #tools < Config.OpenCrates.Threshold then return end
				local opened = 0
				for _, t in ipairs(tools) do
					if opened >= Config.OpenCrates.MaxPerCycle then break end
					pcall(function() REM.Open:FireServer(t.Name) end)
					opened = opened + 1
					Stats.Opens = Stats.Opens + 1
				end
				if opened > 0 and Config.OpenCrates.Skip then task.delay(0.3, ClickSkip) end
			end)
		end
	end
end)

-- ═══ 12) ⚡ AUTO TAP ═══
local TapCache = { Click = nil, Last = 0 }
local function RefreshTapCache()
	local root = GetRootDirect()
	local best, bestD = nil, math.huge
	pcall(function()
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
task.spawn(function()
	task.wait(2)
	RefreshTapCache()
	while true do
		task.wait(Config.TapXP.Delay)
		if Config.TapXP.Enabled then
			Safe(function()
				if Config.TapXP.UseRemote and REM.Click then
					REM.Click:FireServer("ManualMachine")
					Stats.Taps = Stats.Taps + 1
				end
				if Config.TapXP.UseClick then
					if tick() - TapCache.Last > 20 then RefreshTapCache() end
					if TapCache.Click and IsValid(TapCache.Click) then
						local parent = TapCache.Click.Parent
						local root = GetRootDirect()
						if parent and root and (parent.Position - root.Position).Magnitude <= 16 then
							if type(fireclickdetector) == "function" then
								pcall(function() fireclickdetector(TapCache.Click) end)
								Stats.Taps = Stats.Taps + 1
							end
						end
					end
				end
			end)
		end
	end
end)

-- ═══ 13) 💰 AUTO COLLECT ═══
local WORLD_FOLDERS = { "FoodDrops", "ClientCoinsGems", "TouchHexagons", "FishIndexChests", "SunshineMysteryBoxHexagons", "HiddenChests", "FallenCandy", "PondRewardSigns" }
local MONEY_WORDS = { "coin", "cash", "money", "gem", "token", "drop", "collect", "candy", "star" }
local CollectParts = {}
local function GetPlayerPlot()
	local plots = Workspace:FindFirstChild("Plots")
	if plots == nil then return nil end
	for _, p in ipairs(plots:GetChildren()) do
		if p.Name:find(LocalPlayer.Name, 1, true) then return p end
	end
	return nil
end
local function IsMoneyPart(obj)
	if not obj:IsA("BasePart") then return false end
	if MatchWords(obj.Name:lower(), MONEY_WORDS) then return true end
	local ok, kids = pcall(function() return obj:GetChildren() end)
	if not ok then return false end
	for _, child in ipairs(kids) do
		if child:IsA("BillboardGui") then
			local label = child:FindFirstChildOfClass("TextLabel")
			if label and typeof(label.Text) == "string" and label.Text:find("$", 1, true) then return true end
		end
	end
	return false
end
task.spawn(function()
	while true do
		task.wait(3)
		if Config.Collect.Enabled then
			Safe(function()
				local list = {}
				if Config.Collect.WorldDrops then
					for _, fn in ipairs(WORLD_FOLDERS) do
						local folder = Workspace:FindFirstChild(fn)
						if folder then
							local ok, desc = pcall(function() return folder:GetDescendants() end)
							if ok then
								for _, obj in ipairs(desc) do
									if obj:IsA("BasePart") and #list < 300 then table.insert(list, obj) end
								end
							end
						end
					end
				end
				if Config.Collect.FactoryMoney then
					local plot = GetPlayerPlot()
					if plot then
						local ok, desc = pcall(function() return plot:GetDescendants() end)
						if ok then
							for _, obj in ipairs(desc) do
								if #list >= 300 then break end
								if IsValid(obj) and IsMoneyPart(obj) then table.insert(list, obj) end
							end
						end
					end
				end
				CollectParts = list
			end)
		end
	end
end)
task.spawn(function()
	task.wait(2)
	while true do
		task.wait(Config.Collect.Delay)
		if Config.Collect.Enabled and type(firetouchinterest) == "function" then
			Safe(function()
				local root = GetRootDirect()
				if root == nil then return end
				local touched = 0
				for idx = #CollectParts, 1, -1 do
					if touched >= Config.Collect.Batch then break end
					local obj = CollectParts[idx]
					if not IsValid(obj) then
						table.remove(CollectParts, idx)
					else
						local d = (obj.Position - root.Position).Magnitude
						if d <= Config.Collect.Radius then
							pcall(function() firetouchinterest(root, obj, 0) end)
							task.wait(0.04)
							pcall(function() firetouchinterest(root, obj, 1) end)
							touched = touched + 1
							Stats.Collects = Stats.Collects + 1
							table.remove(CollectParts, idx)
						end
					end
				end
			end)
		end
	end
end)

-- ═══ 14) 🍀 LUCK ═══
task.spawn(function()
	task.wait(3)
	while true do
		task.wait(5)
		if Config.Luck.Enabled then
			Safe(function()
				for _, target in ipairs({ LocalPlayer, GetHumanoid() }) do
					if IsValid(target) then
						for name, val in pairs(target:GetAttributes()) do
							if type(val) == "number" and name:lower():find("luck", 1, true) then
								pcall(function() target:SetAttribute(name, val * Config.Luck.Multiplier) end)
							end
						end
					end
				end
			end)
		end
	end
end)

-- ═══ 15) MOVEMENT ENGINE + FLY GUI V3 (Movement.lua merged) ═══
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

local Fly = nil

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
    MovementEnv.DeltaMovementJumpRequest = nil
    MovementEnv.DeltaMovementCharacterAdded = nil
    MovementEnv.DeltaMovementCharacterRemoving = nil
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
        local speedValue = ClampNumber(SafeNumber(cfg.Speed, 60), 16, 1000)
        pcall(function() humanoid.WalkSpeed = speedValue end)
    else
        local restoreValue = ClampNumber(SafeNumber(original and original.WalkSpeed, 16), 0, 1000)
        pcall(function() humanoid.WalkSpeed = restoreValue end)
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
        else
            pcall(function() humanoid.JumpPower = 50 end)
            pcall(function() humanoid.JumpHeight = 7.2 end)
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
            if typeof(part) == "Instance" and part.Parent then
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
            if typeof(obj) == "Instance" and obj:IsA("BasePart") then
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
                if typeof(part) == "Instance" and part.Parent and part.CanCollide then
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
    if Fly and Fly.Flying then return end
    if not Config.Movement.Fly.Enabled then return end

    local root = GetRootDirect()
    if typeof(root) ~= "Instance" or not root.Parent then return end

    safeCall(function()
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(
            Config.Movement.Fly.MaxSpeed * 100,
            Config.Movement.Fly.MaxSpeed * 100,
            Config.Movement.Fly.MaxSpeed * 100
        )
        bv.Velocity = Vector3.zero
        bv.Parent = root
        self._flyBody = bv
    end)

    safeCall(function()
        self._flyConn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Movement.Fly.Enabled then return end
            if Fly and Fly.Flying then
                task.defer(function() Movement:StopFly() end)
                return
            end

            local r = GetRootDirect()
            if not r or not self._flyBody or not self._flyBody.Parent then return end

            local cam = Workspace.CurrentCamera
            if not cam then return end

            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end

            local speed = ClampNumber(SafeNumber(Config.Movement.Fly.Speed, 60), 1, 500)
            local target = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
            local accel = ClampNumber(SafeNumber(Config.Movement.Fly.Accel, 100), 1, 1000)
            local alpha = math.min(1, accel * (dt or 0.016))

            self._flyBody.Velocity = self._flyBody.Velocity:Lerp(target, alpha)
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
        self._airStateConn = humanoid.StateChanged:Connect(function(_, newState)
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
        self._highJumpStateConn = humanoid.StateChanged:Connect(function(_, newState)
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
        self._loopConn = RunService.Heartbeat:Connect(function(_)
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
        if Config.Movement.InfiniteJump.Enabled then
            local hum = GetHumanoid()
            if hum then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            end
        end
        Movement:TryAirJump(Movement.Humanoid or GetHumanoid())
    end)
    if MovementEnv then MovementEnv.DeltaMovementJumpRequest = jumpConnection end
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
        MovementEnv.DeltaMovementJumpRequest = nil
        MovementEnv.DeltaMovementCharacterAdded = nil
        MovementEnv.DeltaMovementCharacterRemoving = nil
    end
end

-- ═══ FLY GUI V3 from Movement.lua ═══
Fly = {}
Fly.Gui = nil
Fly.ToggleBtn = nil
Fly.SpeedLabel = nil
Fly.Speed = 1
Fly.Flying = false
Fly.Up = false
Fly.Down = false
Fly.BodyVel = nil
Fly.BodyGyro = nil
Fly.CharacterConn = nil

function Fly:IsActive()
    return typeof(self.Gui) == "Instance" and self.Gui.Parent ~= nil
end

function Fly:SetToggleVisual(active)
    if typeof(self.ToggleBtn) ~= "Instance" or not self.ToggleBtn.Parent then return end
    pcall(function()
        if active then
            self.ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
            self.ToggleBtn.Text = "ON"
        else
            self.ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
            self.ToggleBtn.Text = "fly"
        end
    end)
end

function Fly:StopFlight()
    self.Flying = false
    self:SetToggleVisual(false)

    pcall(function() if self.BodyVel then self.BodyVel:Destroy() end end)
    pcall(function() if self.BodyGyro then self.BodyGyro:Destroy() end end)
    self.BodyVel = nil
    self.BodyGyro = nil
    self.Up = false
    self.Down = false

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid.PlatformStand = false end)
    end

    safeCall(function()
        if Movement and Movement.UpdateFly then Movement:UpdateFly() end
    end)
end

function Fly:Destroy()
    self:StopFlight()

    if self.CharacterConn then
        pcall(function() self.CharacterConn:Disconnect() end)
        self.CharacterConn = nil
    end

    if self.Gui then
        pcall(function() self.Gui:Destroy() end)
        self.Gui = nil
    end

    self.ToggleBtn = nil
    self.SpeedLabel = nil
end

function Fly:StartFlight()
    if self.Flying then return end

    safeCall(function()
        if Movement and Movement.StopFly then Movement:StopFly() end
    end)

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not hrp or not humanoid then
        Notify("Fly: الشخصية غير جاهزة ❌", 3)
        return
    end

    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Velocity = Vector3.zero

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = hrp.CFrame

    pcall(function() bodyVel.Parent = hrp end)
    pcall(function() bodyGyro.Parent = hrp end)

    if not bodyVel.Parent or not bodyGyro.Parent then
        pcall(function() bodyVel:Destroy() end)
        pcall(function() bodyGyro:Destroy() end)
        Notify("Fly: فشل إنشاء BodyVelocity/BodyGyro ❌", 4)
        return
    end

    self.Flying = true
    self.BodyVel = bodyVel
    self.BodyGyro = bodyGyro
    self:SetToggleVisual(true)

    task.spawn(function()
        while self.Flying and character and character.Parent and hrp and hrp.Parent and humanoid and humanoid.Parent and humanoid.Health > 0 do
            RunService.RenderStepped:Wait()
            if not self.Flying then break end

            pcall(function()
                humanoid.PlatformStand = true

                local cam = Workspace.CurrentCamera
                if cam and self.BodyGyro and self.BodyGyro.Parent then
                    self.BodyGyro.CFrame = cam.CFrame
                end

                local speedMulti = (self.Speed or 1) * 35
                local vertical = 0
                if self.Up then vertical = 1 end
                if self.Down then vertical = -1 end

                local moveDir = humanoid.MoveDirection
                local velocity = Vector3.new(0, vertical * speedMulti, 0)

                if cam and typeof(moveDir) == "Vector3" and moveDir.Magnitude > 0 then
                    velocity = (cam.CFrame.LookVector * speedMulti) + Vector3.new(0, vertical * speedMulti, 0)
                end

                if self.BodyVel and self.BodyVel.Parent then
                    self.BodyVel.Velocity = velocity
                end
            end)
        end

        pcall(function() if self.BodyVel then self.BodyVel:Destroy() end end)
        pcall(function() if self.BodyGyro then self.BodyGyro:Destroy() end end)
        self.BodyVel = nil
        self.BodyGyro = nil
        self.Flying = false
        self.Up = false
        self.Down = false

        if humanoid and humanoid.Parent then
            pcall(function() humanoid.PlatformStand = false end)
        end

        self:SetToggleVisual(false)
    end)
end

function Fly:ToggleFlight()
    if self.Flying then
        self:StopFlight()
    else
        self:StartFlight()
    end
end

function Fly:Show()
    if self:IsActive() then return end

    self:Destroy()
    self.Speed = 1
    self.Up = false
    self.Down = false

    local parent = nil
    safeCall(function()
        if type(gethui) == "function" then
            local ok, h = pcall(gethui)
            if ok and typeof(h) == "Instance" then
                parent = h
            end
        end

        if not parent then
            local ok, core = pcall(function() return game:GetService("CoreGui") end)
            if ok and core then
                parent = core
            end
        end

        if not parent then
            parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
    end)

    if not parent then
        Notify("Fly: لا يوجد مكان آمن للواجهة ❌", 4)
        return
    end

    local main = Instance.new("ScreenGui")
    main.Name = "FlyGuiV3_UnboxHub"
    main.ResetOnSpawn = false
    main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    main.DisplayOrder = 999999
    pcall(function() main.IgnoreGuiInset = true end)

    pcall(function()
        local old = parent:FindFirstChild(main.Name)
        if old then old:Destroy() end
    end)

    local Frame = Instance.new("Frame")
    Frame.Name = "Main"
    Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
    Frame.Position = UDim2.new(0.05, 0, 0.2, 0)
    Frame.Size = UDim2.new(0, 190, 0, 115)
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = main

    local Close = Instance.new("TextButton")
    Close.Name = "Close"
    Close.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
    Close.Position = UDim2.new(0, 5, 0, 5)
    Close.Size = UDim2.new(0, 45, 0, 45)
    Close.Font = Enum.Font.SourceSansBold
    Close.Text = "X"
    Close.TextColor3 = Color3.fromRGB(255, 255, 255)
    Close.TextSize = 20
    Close.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.BackgroundColor3 = Color3.fromRGB(255, 85, 127)
    Title.Position = UDim2.new(0, 55, 0, 5)
    Title.Size = UDim2.new(0, 130, 0, 45)
    Title.Font = Enum.Font.SourceSansBold
    Title.Text = "FLY GUI V3"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Parent = Frame

    local Up = Instance.new("TextButton")
    Up.Name = "Up"
    Up.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
    Up.Position = UDim2.new(0, 5, 0, 55)
    Up.Size = UDim2.new(0, 45, 0, 25)
    Up.Font = Enum.Font.SourceSansBold
    Up.Text = "UP"
    Up.TextColor3 = Color3.fromRGB(255, 255, 255)
    Up.TextSize = 12
    Up.Parent = Frame

    local Down = Instance.new("TextButton")
    Down.Name = "Down"
    Down.BackgroundColor3 = Color3.fromRGB(255, 255, 127)
    Down.Position = UDim2.new(0, 5, 0, 85)
    Down.Size = UDim2.new(0, 45, 0, 25)
    Down.Font = Enum.Font.SourceSansBold
    Down.Text = "DOWN"
    Down.TextColor3 = Color3.fromRGB(0, 0, 0)
    Down.TextSize = 10
    Down.Parent = Frame

    local Plus = Instance.new("TextButton")
    Plus.Name = "Plus"
    Plus.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
    Plus.Position = UDim2.new(0, 55, 0, 55)
    Plus.Size = UDim2.new(0, 35, 0, 55)
    Plus.Font = Enum.Font.SourceSansBold
    Plus.Text = "+"
    Plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    Plus.TextSize = 18
    Plus.Parent = Frame

    local SpeedBox = Instance.new("TextBox")
    SpeedBox.Name = "Speed"
    SpeedBox.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
    SpeedBox.Position = UDim2.new(0, 95, 0, 55)
    SpeedBox.Size = UDim2.new(0, 40, 0, 25)
    SpeedBox.Font = Enum.Font.SourceSansBold
    SpeedBox.Text = tostring(self.Speed)
    SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedBox.TextSize = 16
    SpeedBox.Parent = Frame

    local Minus = Instance.new("TextButton")
    Minus.Name = "Minus"
    Minus.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
    Minus.Position = UDim2.new(0, 95, 0, 85)
    Minus.Size = UDim2.new(0, 40, 0, 25)
    Minus.Font = Enum.Font.SourceSansBold
    Minus.Text = "-"
    Minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    Minus.TextSize = 18
    Minus.Parent = Frame

    local Toggle = Instance.new("TextButton")
    Toggle.Name = "Toggle"
    Toggle.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
    Toggle.Position = UDim2.new(0, 140, 0, 55)
    Toggle.Size = UDim2.new(0, 45, 0, 55)
    Toggle.Font = Enum.Font.SourceSansBold
    Toggle.Text = "fly"
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.TextSize = 16
    Toggle.Parent = Frame

    local function UpdateSpeedLabel()
        if typeof(self.SpeedLabel) == "Instance" and self.SpeedLabel.Parent then
            pcall(function() self.SpeedLabel.Text = tostring(self.Speed) end)
        end
    end

    Close.MouseButton1Click:Connect(function()
        task.defer(function()
            self:Destroy()
        end)
    end)

    Plus.MouseButton1Click:Connect(function()
        if self.Speed < 100 then
            self.Speed = self.Speed + 1
        end
        UpdateSpeedLabel()
    end)

    Minus.MouseButton1Click:Connect(function()
        if self.Speed > 1 then
            self.Speed = self.Speed - 1
        end
        UpdateSpeedLabel()
    end)

    SpeedBox.FocusLost:Connect(function()
        local value = tonumber(SpeedBox.Text)
        if value then
            self.Speed = math.floor(ClampNumber(value, 1, 100))
        end
        UpdateSpeedLabel()
    end)

    local function BindHold(button, setter)
        button.MouseButton1Down:Connect(function() setter(true) end)
        button.MouseButton1Up:Connect(function() setter(false) end)
        button.MouseLeave:Connect(function() setter(false) end)
        button.InputEnded:Connect(function(input)
            if input and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
                setter(false)
            end
        end)
    end

    BindHold(Up, function(v) self.Up = v end)
    BindHold(Down, function(v) self.Down = v end)

    Toggle.MouseButton1Click:Connect(function()
        self:ToggleFlight()
    end)

    local okParent = pcall(function() main.Parent = parent end)
    if not okParent or not main.Parent then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            pcall(function() main.Parent = playerGui end)
        end
    end

    if not main.Parent then
        pcall(function() main:Destroy() end)
        Notify("Fly: فشل إظهار الواجهة ❌", 4)
        return
    end

    self.Gui = main
    self.ToggleBtn = Toggle
    self.SpeedLabel = SpeedBox

    self.CharacterConn = LocalPlayer.CharacterRemoving:Connect(function()
        self:StopFlight()
    end)

    Notify("FLY GUI V3 جاهز ✅", 3)
end

if MovementEnv then
    safeCall(function()
        if MovementEnv.UnboxFlyCleanup then
            MovementEnv.UnboxFlyCleanup()
        end
    end)

    MovementEnv.UnboxFlyCleanup = function()
        safeCall(function() Fly:Destroy() end)
    end
end

-- ═══ 16) PERFORMANCE ENGINE PRO (Movement.lua merged) ═══
local Perf = {}
Perf.OriginalLighting = { captured = false }
Perf.OriginalWater = { captured = false }
Perf.OriginalCap = nil
Perf.SavedPostFX = setmetatable({}, { __mode = "k" })
Perf.SavedEffects = setmetatable({}, { __mode = "k" })
Perf.SavedLights = setmetatable({}, { __mode = "k" })
Perf.SavedVisuals = setmetatable({}, { __mode = "k" })
Perf.EffectConn = nil
Perf.LightConn = nil
Perf.VisualConn = nil
Perf.FPS = { frames = 0, last = tick(), value = 0, draw = nil, lastAdaptive = 0 }

safeCall(function() RunService:UnbindFromRenderStep("DeltaPerfStyle") end)
safeCall(function() RunService:UnbindFromRenderStep("DeltaPerf") end)
safeCall(function() RunService:UnbindFromRenderStep("V35FPS") end)

local function EnsurePerformanceConfig()
    Config.Performance = Config.Performance or {}
    Config.Performance.FPSCap = ClampNumber(SafeNumber(Config.Performance.FPSCap, 60), 20, 9999)
    Config.Performance.ShowFPS = Config.Performance.ShowFPS == true
    Config.Performance.PostFXOff = Config.Performance.PostFXOff == true
    Config.Performance.EffectsOff = Config.Performance.EffectsOff == true
    Config.Performance.Shadows = Config.Performance.Shadows ~= false
    Config.Performance.FogDistance = ClampNumber(SafeNumber(Config.Performance.FogDistance, 12000), 100, 100000)
    Config.Performance.Brightness = ClampNumber(SafeNumber(Config.Performance.Brightness, 1.5), 0, 3)
    Config.Performance.AdaptiveQuality = Config.Performance.AdaptiveQuality == true
    Config.Performance.LowDetail = Config.Performance.LowDetail == true
    Config.Performance.RemoveLights = Config.Performance.RemoveLights == true
    Config.Performance.LowWater = Config.Performance.LowWater == true

    Config.Performance.FPSCounter = Config.Performance.FPSCounter or {}
    Config.Performance.FPSCounter.Size = ClampNumber(SafeNumber(Config.Performance.FPSCounter.Size, 16), 10, 32)
    Config.Performance.FPSCounter.X = ClampNumber(SafeNumber(Config.Performance.FPSCounter.X, 12), 0, 2000)
    Config.Performance.FPSCounter.Y = ClampNumber(SafeNumber(Config.Performance.FPSCounter.Y, 12), 0, 2000)
    Config.Performance.FPSCounter.Outline = Config.Performance.FPSCounter.Outline ~= false
    Config.Performance.FPSCounter.AutoColor = Config.Performance.FPSCounter.AutoColor ~= false

    if typeof(Config.Performance.FPSCounter.Color) ~= "Color3" then
        Config.Performance.FPSCounter.Color = Color3.fromRGB(94, 255, 170)
    end
end

local function SetFPS(n)
    if type(setfpscap) == "function" then
        pcall(setfpscap, math.floor(ClampNumber(SafeNumber(n, 60), 1, 9999)))
    end
end

safeCall(function()
    if type(getfpscap) == "function" then
        local ok, v = pcall(getfpscap)
        if ok and type(v) == "number" then Perf.OriginalCap = v end
    end
end)

local function CaptureLighting()
    if Perf.OriginalLighting.captured then return end
    local o = Perf.OriginalLighting
    o.captured = true
    safeCall(function() o.GlobalShadows = Lighting.GlobalShadows end)
    safeCall(function() o.ShadowSoftness = Lighting.ShadowSoftness end)
    safeCall(function() o.Brightness = Lighting.Brightness end)
    safeCall(function() o.Ambient = Lighting.Ambient end)
    safeCall(function() o.OutdoorAmbient = Lighting.OutdoorAmbient end)
    safeCall(function() o.FogEnd = Lighting.FogEnd end)
    safeCall(function() o.FogStart = Lighting.FogStart end)
    safeCall(function() o.FogColor = Lighting.FogColor end)
    safeCall(function() o.ExposureCompensation = Lighting.ExposureCompensation end)
    safeCall(function() o.Technology = Lighting.Technology end)
end

local function CaptureWater()
    if Perf.OriginalWater.captured then return end
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    local o = Perf.OriginalWater
    o.captured = true
    safeCall(function() o.WaterWaveSize = terrain.WaterWaveSize end)
    safeCall(function() o.WaterWaveSpeed = terrain.WaterWaveSpeed end)
    safeCall(function() o.WaterReflectance = terrain.WaterReflectance end)
    safeCall(function() o.WaterTransparency = terrain.WaterTransparency end)
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
        if Perf.EffectConn then
            pcall(function() Perf.EffectConn:Disconnect() end)
            Perf.EffectConn = nil
        end
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
        if Perf.LightConn then
            pcall(function() Perf.LightConn:Disconnect() end)
            Perf.LightConn = nil
        end
        for obj, en in pairs(Perf.SavedLights) do pcall(function() obj.Enabled = en end) end
        table.clear(Perf.SavedLights)
    end
end

local function HideVisual(obj)
    if typeof(obj) ~= "Instance" then return end
    if obj:IsA("Texture") or obj:IsA("Decal") then
        if Perf.SavedVisuals[obj] == nil then
            local data = {}
            pcall(function() data.Enabled = obj.Enabled end)
            pcall(function() data.Transparency = obj.Transparency end)
            Perf.SavedVisuals[obj] = data
        end
        pcall(function()
            if obj:IsA("Decal") then obj.Enabled = false end
        end)
        pcall(function() obj.Transparency = 1 end)
    end
end

local function RestoreVisual(obj, data)
    if typeof(obj) ~= "Instance" or not obj.Parent or typeof(data) ~= "table" then return end
    if data.Enabled ~= nil then pcall(function() obj.Enabled = data.Enabled end) end
    if data.Transparency ~= nil then pcall(function() obj.Transparency = data.Transparency end) end
end

local function SetLowDetail(off)
    if off then
        task.spawn(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do pcall(HideVisual, obj) end
        end)
        if not Perf.VisualConn then
            Perf.VisualConn = Workspace.DescendantAdded:Connect(function(obj) pcall(HideVisual, obj) end)
        end
    else
        if Perf.VisualConn then
            pcall(function() Perf.VisualConn:Disconnect() end)
            Perf.VisualConn = nil
        end
        for obj, data in pairs(Perf.SavedVisuals) do pcall(RestoreVisual, obj, data) end
        table.clear(Perf.SavedVisuals)
    end
end

local function SetLowWater(off)
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    CaptureWater()
    if off then
        pcall(function() terrain.WaterWaveSize = 0 end)
        pcall(function() terrain.WaterWaveSpeed = 0 end)
        pcall(function() terrain.WaterReflectance = 0 end)
        pcall(function() terrain.WaterTransparency = 0 end)
    else
        local o = Perf.OriginalWater
        if o.captured then
            pcall(function() terrain.WaterWaveSize = o.WaterWaveSize or 0 end)
            pcall(function() terrain.WaterWaveSpeed = o.WaterWaveSpeed or 0 end)
            pcall(function() terrain.WaterReflectance = o.WaterReflectance or 0 end)
            pcall(function() terrain.WaterTransparency = o.WaterTransparency or 0 end)
        end
    end
end

local function SetShadows(on)
    CaptureLighting()
    Config.Performance.Shadows = on
    pcall(function() Lighting.GlobalShadows = on end)
end

local function SetFog(dist)
    CaptureLighting()
    Config.Performance.FogDistance = dist
    pcall(function()
        Lighting.FogEnd = dist
        Lighting.FogStart = 0
    end)
end

local function SetBright(v)
    CaptureLighting()
    Config.Performance.Brightness = v
    pcall(function() Lighting.Brightness = v end)
end

local PRESETS = {
    Ultra = {
        GlobalShadows = true, ShadowSoftness = 1, Brightness = 2, FogEnd = 100000,
        Tech = "ShadowMap", PostFXOff = false, EffectsOff = false,
        RemoveLights = false, LowDetail = false, LowWater = false,
    },
    High = {
        GlobalShadows = true, ShadowSoftness = 0.5, Brightness = 2, FogEnd = 40000,
        Tech = "ShadowMap", PostFXOff = false, EffectsOff = false,
        RemoveLights = false, LowDetail = false, LowWater = false,
    },
    Medium = {
        GlobalShadows = false, ShadowSoftness = 0, Brightness = 1.5, FogEnd = 12000,
        Tech = "ShadowMap", PostFXOff = true, EffectsOff = true,
        RemoveLights = false, LowDetail = false, LowWater = false,
    },
    Low = {
        GlobalShadows = false, ShadowSoftness = 0, Brightness = 1, FogEnd = 3000,
        Tech = "Voxel", PostFXOff = true, EffectsOff = true,
        RemoveLights = true, LowDetail = true, LowWater = true,
    },
    Potato = {
        GlobalShadows = false, ShadowSoftness = 0, Brightness = 1, FogEnd = 800,
        Tech = "Legacy", PostFXOff = true, EffectsOff = true,
        RemoveLights = true, LowDetail = true, LowWater = true,
    },
}

local function ApplyQuality(name)
    CaptureLighting()
    CaptureWater()
    local p = PRESETS[name]
    if not p then return end

    pcall(function() Lighting.GlobalShadows = p.GlobalShadows end)
    pcall(function() Lighting.ShadowSoftness = p.ShadowSoftness end)
    pcall(function() Lighting.Brightness = p.Brightness end)
    pcall(function() Lighting.FogEnd = p.FogEnd end)
    pcall(function() Lighting.FogStart = 0 end)

    Config.Performance.Shadows = p.GlobalShadows
    Config.Performance.FogDistance = p.FogEnd
    Config.Performance.Brightness = p.Brightness

    if p.Tech then
        local ok, tech = pcall(function() return Enum.Technology[p.Tech] end)
        if ok and tech then pcall(function() Lighting.Technology = tech end) end
    end

    SetPostFX(p.PostFXOff)
    Config.Performance.PostFXOff = p.PostFXOff
    SetEffects(p.EffectsOff)
    Config.Performance.EffectsOff = p.EffectsOff
    SetLights(p.RemoveLights)
    Config.Performance.RemoveLights = p.RemoveLights
    SetLowDetail(p.LowDetail)
    Config.Performance.LowDetail = p.LowDetail
    SetLowWater(p.LowWater)
    Config.Performance.LowWater = p.LowWater
end

local function RestoreAll()
    local o = Perf.OriginalLighting
    if o.captured then
        pcall(function() Lighting.GlobalShadows = o.GlobalShadows end)
        pcall(function() Lighting.ShadowSoftness = o.ShadowSoftness end)
        pcall(function() Lighting.Brightness = o.Brightness end)
        pcall(function() Lighting.Ambient = o.Ambient end)
        pcall(function() Lighting.OutdoorAmbient = o.OutdoorAmbient end)
        pcall(function() Lighting.FogEnd = o.FogEnd end)
        pcall(function() Lighting.FogStart = o.FogStart end)
        pcall(function() Lighting.FogColor = o.FogColor end)
        pcall(function() Lighting.ExposureCompensation = o.ExposureCompensation end)
        if o.Technology then pcall(function() Lighting.Technology = o.Technology end) end

        Config.Performance.Shadows = o.GlobalShadows
        Config.Performance.FogDistance = o.FogEnd
        Config.Performance.Brightness = o.Brightness
    end

    SetPostFX(false)
    SetEffects(false)
    SetLights(false)
    SetLowDetail(false)
    SetLowWater(false)

    if Perf.OriginalCap then SetFPS(Perf.OriginalCap) else SetFPS(9999) end

    Config.Performance.PostFXOff = false
    Config.Performance.EffectsOff = false
    Config.Performance.RemoveLights = false
    Config.Performance.LowDetail = false
    Config.Performance.LowWater = false
    Config.Performance.AdaptiveQuality = false
end

local function UpdateFPSDraw()
    if typeof(Perf.FPS.draw) ~= "table" then return end
    local c = Config.Performance.FPSCounter
    pcall(function()
        Perf.FPS.draw.Size = c.Size
        Perf.FPS.draw.Position = Vector2.new(c.X, c.Y)
        Perf.FPS.draw.Outline = c.Outline
        Perf.FPS.draw.Visible = Config.Performance.ShowFPS
    end)
end

local function ApplyPerformanceSettings()
    EnsurePerformanceConfig()
    CaptureLighting()
    CaptureWater()
    SetFPS(Config.Performance.FPSCap)
    SetPostFX(Config.Performance.PostFXOff)
    SetEffects(Config.Performance.EffectsOff)
    SetLights(Config.Performance.RemoveLights)
    SetLowDetail(Config.Performance.LowDetail)
    SetLowWater(Config.Performance.LowWater)

    pcall(function() Lighting.GlobalShadows = Config.Performance.Shadows end)
    pcall(function()
        Lighting.FogEnd = Config.Performance.FogDistance
        Lighting.FogStart = 0
    end)
    pcall(function() Lighting.Brightness = Config.Performance.Brightness end)

    UpdateFPSDraw()
end

safeCall(function()
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

EnsurePerformanceConfig()
CaptureLighting()
CaptureWater()
ApplyPerformanceSettings()

safeCall(function()
    local styleAccum = 0
    RunService:BindToRenderStep("DeltaPerfStyle", 200, function(dt)
        styleAccum = styleAccum + (dt or 0)
        if styleAccum < 0.25 then return end
        styleAccum = 0

        UpdateFPSDraw()

        if Perf.FPS.draw and Config.Performance.ShowFPS then
            local c = Config.Performance.FPSCounter
            pcall(function()
                Perf.FPS.draw.Text = "FPS: " .. tostring(Perf.FPS.value)
                if c.AutoColor then
                    if Perf.FPS.value >= 50 then
                        Perf.FPS.draw.Color = Color3.fromRGB(94, 255, 170)
                    elseif Perf.FPS.value >= 30 then
                        Perf.FPS.draw.Color = Color3.fromRGB(255, 210, 90)
                    else
                        Perf.FPS.draw.Color = Color3.fromRGB(255, 94, 98)
                    end
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

function Perf.Destroy()
    safeCall(function() RunService:UnbindFromRenderStep("DeltaPerfStyle") end)
    safeCall(function() RunService:UnbindFromRenderStep("DeltaPerf") end)
    safeCall(function()
        if Perf.FPS.draw then Perf.FPS.draw:Remove() end
    end)
end

-- ═══ 17) PROTECTION ENGINE (Movement.lua merged — no duplicate namecall) ═══
local ProtectionEnv = nil
if type(getgenv) == "function" then
    pcall(function() ProtectionEnv = getgenv() end)
end

local ProtectionConnections = {}
local ReportHookedContainers = {}

if ProtectionEnv then
    safeCall(function()
        if ProtectionEnv.DeltaProtectionCleanup then
            ProtectionEnv.DeltaProtectionCleanup()
        end
    end)
end

local function AddProtectionConnection(conn)
    if conn then table.insert(ProtectionConnections, conn) end
    return conn
end

local function DisconnectProtectionConnections()
    for _, conn in ipairs(ProtectionConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(ProtectionConnections)
end

if ProtectionEnv then
    ProtectionEnv.DeltaProtectionConnections = ProtectionConnections
    ProtectionEnv.DeltaProtectionCleanup = function()
        safeCall(DisconnectProtectionConnections)
    end
end

-- Executor Cloak
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

-- Anti-AFK
safeCall(function()
    if not Config.Protection.AntiAFK then return end
    local vu = game:GetService("VirtualUser")
    local conn = LocalPlayer.Idled:Connect(function()
        if not Config.Protection.AntiAFK then return end
        pcall(function() vu:CaptureController() end)
        pcall(function() vu:ClickButton2(Vector2.new()) end)
        pcall(function()
            local cf = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()
            vu:Button2Down(Vector2.new(), cf)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(), cf)
        end)
    end)
    AddProtectionConnection(conn)
end)

-- Auto Delete Reports (PlayerGui only)
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

local function CleanReportContainer(container)
    if typeof(container) ~= "Instance" then return end
    if not Config.Protection.AutoDeleteReports then return end
    safeCall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            RemoveReportObject(obj)
        end
    end)
end

local function EnsureReportProtection()
    if not Config.Protection.AutoDeleteReports then return end

    local function HookContainer(container)
        if typeof(container) ~= "Instance" then return end
        CleanReportContainer(container)
        if ReportHookedContainers[container] then return end
        ReportHookedContainers[container] = true

        local conn = container.DescendantAdded:Connect(function(obj)
            if Config.Protection.AutoDeleteReports then
                task.defer(function() RemoveReportObject(obj) end)
            end
        end)
        AddProtectionConnection(conn)
    end

    safeCall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            HookContainer(playerGui)
        else
            task.spawn(function()
                local gui = LocalPlayer:WaitForChild("PlayerGui", 10)
                if typeof(gui) == "Instance" then HookContainer(gui) end
            end)
        end
    end)
end

EnsureReportProtection()

-- ═══ 18) 🚫 SPAM FILTER (مصلّح + محسّن) ═══
local SPAM_PHRASES = { "you have not reached", "gift expired", "you can't afford", "not enough cash", "you need more cash" }
local SPAM_GUIS = { "OnScreenTextUI", "TextOnScreen", "CentreMessage", "MainUi", "OnScreenText" }
local function IsSpamText(t)
	local lower = t:lower()
	for _, ph in ipairs(SPAM_PHRASES) do
		if lower:find(ph, 1, true) then return true end
	end
	return false
end
local function HideSpam(obj)
	if typeof(obj) ~= "Instance" then return end
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
	local ok, t = pcall(function() return obj.Text end)
	if ok and typeof(t) == "string" and IsSpamText(t) then
		pcall(function() obj.Visible = false end)
	end
end
Safe(function()
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then
		pg.DescendantAdded:Connect(function(o)
			if Config.SpamFilter then task.defer(HideSpam, o) end
		end)
	end
end)
task.spawn(function()
	while true do
		task.wait(5)
		if Config.SpamFilter then
			Safe(function()
				local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
				if pg == nil then return end
				for _, gn in ipairs(SPAM_GUIS) do
					local gui = pg:FindFirstChild(gn)
					if gui then
						for _, obj in ipairs(gui:GetDescendants()) do
							if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
								HideSpam(obj)
							end
						end
					end
				end
			end)
		end
	end
end)

-- ═══ 19) 📄 STATUS FILE (بدون خط أخضر) ═══
local MagnetOK = false
local BaseB = nil
local function StatusLine()
	return ("V35 | B:%d R:%d X:%d F:%d T:%d ⚡%d 💵%d 📦%d S:%d Err:%d | %s"):format(
		Stats.Back, Stats.Remote, Stats.Extract, Stats.Fires, Stats.Triggered,
		Stats.Taps, Stats.Collects, Stats.Opens, Stats.Skip, Stats.Err, LastErr
	)
end
task.spawn(function()
	while true do
		task.wait(1)
		Stats.Back = CountCrates()
		if BaseB == nil then BaseB = Stats.Back end
		if not MagnetOK and Stats.Back > BaseB and (Stats.Remote > 0 or Stats.Triggered > 0) then
			MagnetOK = true
			Notify("🧲 المغناطيس يشتغل! الصناديق تجيك وأنت واقف", 7)
		end
	end
end)
local function BuildStatus()
	local L = {}
	table.insert(L, "═══ V35 STATUS ═══")
	table.insert(L, "Time: " .. os.date("%c"))
	table.insert(L, StatusLine())
	table.insert(L, "FPS: " .. Perf.FPS.value)
	table.insert(L, "Pickup: " .. (REM.Pickup and "FOUND" or "MISSING") .. " | Open: " .. (REM.Open and "FOUND" or "MISSING"))
	table.insert(L, "Hook: " .. (HookOn and "ON" or "OFF") .. " | MagnetConfirmed: " .. tostring(MagnetOK))
	table.insert(L, "CapturedIDs: " .. table.concat(LastIDs, ", "))
	for i, p in ipairs(Cache) do
		if i > 6 then break end
		pcall(function()
			if IsValid(p) then
				table.insert(L, ("P%d act[%s] cls=%s xid=%s"):format(i, NormAct(p), ClassifyPrompt(p), tostring(ExtractCache[p] or "—")))
			end
		end)
	end
	return table.concat(L, "\n")
end
task.spawn(function()
	task.wait(3)
	local announced = false
	while true do
		Safe(function()
			local content = BuildStatus()
			local a = WriteFile("V35_Status.txt", content)
			if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("DeltaHub") then
				pcall(function() makefolder("DeltaHub") end)
			end
			local b = WriteFile("DeltaHub/V35_Status.txt", content)
			if not announced then
				announced = true
				Notify((a or b) and "📄 V35_Status.txt ✅" or "📄 فشل حفظ الملف", 5)
			end
		end)
		task.wait(10)
	end
end)

-- ═══ 20) WINDUI MENU (Movement.lua merged — NO ESP) ═══
Safe(function()
    local WindUISource
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

    if not WindUISource then error("WindUI download failed") end

    local WindUI = loadstring(WindUISource)()

    local Window = WindUI:CreateWindow({
        Title = "Unbox Movement Hub",
        Author = "V35 + Movement.lua",
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

    -- AUTO TAB
    local AutoTab = Window:Tab({ Title = "Auto", Icon = "zap" })

    local TapSec = AutoTab:Section({ Title = "⚡ Tap + 💰 Collect", Box = true, BoxBorder = true, Opened = true })
    Reg("TapXP.Enabled", TapSec:Toggle({
        Title = "Auto Tap XP",
        Value = Config.TapXP.Enabled,
        Callback = function(v) Config.TapXP.Enabled = v; QueueSave() end
    }))
    Reg("TapXP.Delay", TapSec:Slider({
        Title = "Tap Delay",
        Step = 0.05,
        Value = { Min = 0.05, Max = 2, Default = Config.TapXP.Delay },
        Callback = function(v) Config.TapXP.Delay = v; QueueSave() end
    }))
    Reg("TapXP.UseRemote", TapSec:Toggle({
        Title = "Tap Use Remote",
        Value = Config.TapXP.UseRemote,
        Callback = function(v) Config.TapXP.UseRemote = v; QueueSave() end
    }))
    Reg("TapXP.UseClick", TapSec:Toggle({
        Title = "Tap Use Click",
        Value = Config.TapXP.UseClick,
        Callback = function(v) Config.TapXP.UseClick = v; QueueSave() end
    }))

    Reg("Collect.Enabled", TapSec:Toggle({
        Title = "Auto Collect",
        Value = Config.Collect.Enabled,
        Callback = function(v) Config.Collect.Enabled = v; QueueSave() end
    }))
    Reg("Collect.Delay", TapSec:Slider({
        Title = "Collect Delay",
        Step = 0.05,
        Value = { Min = 0.1, Max = 3, Default = Config.Collect.Delay },
        Callback = function(v) Config.Collect.Delay = v; QueueSave() end
    }))
    Reg("Collect.Radius", TapSec:Slider({
        Title = "Collect Radius",
        Step = 10,
        Value = { Min = 50, Max = 500, Default = Config.Collect.Radius },
        Callback = function(v) Config.Collect.Radius = v; QueueSave() end
    }))
    Reg("Collect.Batch", TapSec:Slider({
        Title = "Collect Batch",
        Step = 1,
        Value = { Min = 1, Max = 50, Default = Config.Collect.Batch },
        Callback = function(v) Config.Collect.Batch = v; QueueSave() end
    }))
    Reg("Collect.WorldDrops", TapSec:Toggle({
        Title = "World Drops",
        Value = Config.Collect.WorldDrops,
        Callback = function(v) Config.Collect.WorldDrops = v; QueueSave() end
    }))
    Reg("Collect.FactoryMoney", TapSec:Toggle({
        Title = "Factory Money",
        Value = Config.Collect.FactoryMoney,
        Callback = function(v) Config.Collect.FactoryMoney = v; QueueSave() end
    }))

    local MagnetSec = AutoTab:Section({ Title = "🧲 Crate Magnet", Box = true, BoxBorder = true, Opened = true })
    Reg("Magnet.Enabled", MagnetSec:Toggle({
        Title = "Magnet (بدون مشي)",
        Value = Config.Magnet.Enabled,
        Callback = function(v) Config.Magnet.Enabled = v; QueueSave() end
    }))
    Reg("Magnet.WalkFallback", MagnetSec:Toggle({
        Title = "Walk Fallback",
        Value = Config.Magnet.WalkFallback,
        Callback = function(v) Config.Magnet.WalkFallback = v; QueueSave() end
    }))
    Reg("Magnet.Batch", MagnetSec:Slider({
        Title = "Magnet Batch",
        Step = 1,
        Value = { Min = 1, Max = 10, Default = Config.Magnet.Batch },
        Callback = function(v) Config.Magnet.Batch = v; QueueSave() end
    }))
    Reg("Magnet.CycleDelay", MagnetSec:Slider({
        Title = "Magnet Cycle Delay",
        Step = 0.1,
        Value = { Min = 0.2, Max = 3, Default = Config.Magnet.CycleDelay },
        Callback = function(v) Config.Magnet.CycleDelay = v; QueueSave() end
    }))

    local CrateSec = AutoTab:Section({ Title = "📦 Open + 🍀 Luck", Box = true, BoxBorder = true, Opened = true })
    Reg("OpenCrates.Enabled", CrateSec:Toggle({
        Title = "Auto Open Crates",
        Value = Config.OpenCrates.Enabled,
        Callback = function(v) Config.OpenCrates.Enabled = v; QueueSave() end
    }))
    Reg("OpenCrates.Threshold", CrateSec:Slider({
        Title = "Open Threshold",
        Step = 1,
        Value = { Min = 1, Max = 20, Default = Config.OpenCrates.Threshold },
        Callback = function(v) Config.OpenCrates.Threshold = v; QueueSave() end
    }))
    Reg("OpenCrates.MaxPerCycle", CrateSec:Slider({
        Title = "Max Open Per Cycle",
        Step = 1,
        Value = { Min = 1, Max = 10, Default = Config.OpenCrates.MaxPerCycle },
        Callback = function(v) Config.OpenCrates.MaxPerCycle = v; QueueSave() end
    }))
    Reg("OpenCrates.Skip", CrateSec:Toggle({
        Title = "Auto Skip",
        Value = Config.OpenCrates.Skip,
        Callback = function(v) Config.OpenCrates.Skip = v; QueueSave() end
    }))

    Reg("Luck.Enabled", CrateSec:Toggle({
        Title = "Luck Boost",
        Value = Config.Luck.Enabled,
        Callback = function(v) Config.Luck.Enabled = v; QueueSave() end
    }))
    Reg("Luck.Multiplier", CrateSec:Slider({
        Title = "Luck Multiplier",
        Step = 10,
        Value = { Min = 10, Max = 1000, Default = Config.Luck.Multiplier },
        Callback = function(v) Config.Luck.Multiplier = v; QueueSave() end
    }))

    -- MOVEMENT TAB
    local MoveTab = Window:Tab({ Title = "Movement", Icon = "zap" })

    local NoClipSec = MoveTab:Section({ Title = "NoClip", Box = true, BoxBorder = true, Opened = true })
    Reg("Movement.NoClip.Enabled", NoClipSec:Toggle({
        Title = "Enable NoClip",
        Value = Config.Movement.NoClip.Enabled,
        Callback = function(v) Config.Movement.NoClip.Enabled = v; Movement:Refresh(); QueueSave() end
    }))

    local FlyGuiSec = MoveTab:Section({ Title = "Fly GUI V3", Box = true, BoxBorder = true, Opened = true })
    FlyGuiSec:Button({
        Title = "فتح / إغلاق Fly GUI V3",
        Icon = "zap",
        Callback = function()
            if Fly and Fly:IsActive() then
                Fly:Destroy()
            elseif Fly then
                Fly:Show()
            end
        end
    })
    FlyGuiSec:Button({
        Title = "إيقاف الطيران",
        Icon = "x",
        Color = Color3.fromRGB(255, 120, 80),
        Callback = function()
            if Fly then Fly:StopFlight() end
        end
    })

    local FlyKeySec = MoveTab:Section({ Title = "Fly Keyboard (PC)", Box = true, BoxBorder = true, Opened = false })
    Reg("Movement.Fly.Enabled", FlyKeySec:Toggle({
        Title = "Enable Keyboard Fly",
        Value = Config.Movement.Fly.Enabled,
        Callback = function(v) Config.Movement.Fly.Enabled = v; Movement:Refresh(); QueueSave() end
    }))
    Reg("Movement.Fly.Speed", FlyKeySec:Slider({
        Title = "Fly Speed",
        Step = 5,
        Value = { Min = 10, Max = 500, Default = Config.Movement.Fly.Speed },
        Callback = function(v) Config.Movement.Fly.Speed = v; Movement:Refresh() end
    }))
    Reg("Movement.Fly.Accel", FlyKeySec:Slider({
        Title = "Fly Accel",
        Step = 5,
        Value = { Min = 1, Max = 500, Default = Config.Movement.Fly.Accel },
        Callback = function(v) Config.Movement.Fly.Accel = v; Movement:Refresh() end
    }))
    Reg("Movement.Fly.MaxSpeed", FlyKeySec:Slider({
        Title = "Fly Max Speed",
        Step = 10,
        Value = { Min = 50, Max = 1000, Default = Config.Movement.Fly.MaxSpeed },
        Callback = function(v) Config.Movement.Fly.MaxSpeed = v; Movement:Refresh() end
    }))

    local AirSec = MoveTab:Section({ Title = "AirJump PRO", Box = true, BoxBorder = true, Opened = true })
    Reg("Movement.AirJump.Enabled", AirSec:Toggle({
        Title = "Enable AirJump",
        Value = Config.Movement.AirJump.Enabled,
        Callback = function(v) Config.Movement.AirJump.Enabled = v; Movement:Refresh(); QueueSave() end
    }))
    Reg("Movement.AirJump.Unlimited", AirSec:Toggle({
        Title = "Unlimited AirJump",
        Value = Config.Movement.AirJump.Unlimited,
        Callback = function(v) Config.Movement.AirJump.Unlimited = v; Movement:Refresh(); QueueSave() end
    }))
    Reg("Movement.AirJump.Jumps", AirSec:Slider({
        Title = "Jumps Count",
        Step = 1,
        Value = { Min = 1, Max = 50, Default = Config.Movement.AirJump.Jumps },
        Callback = function(v) Config.Movement.AirJump.Jumps = v; Movement:Refresh() end
    }))
    Reg("Movement.AirJump.Power", AirSec:Slider({
        Title = "AirJump Power",
        Step = 5,
        Value = { Min = 20, Max = 500, Default = Config.Movement.AirJump.Power },
        Callback = function(v) Config.Movement.AirJump.Power = v; Movement:Refresh() end
    }))
    Reg("Movement.AirJump.MaxVelocity", AirSec:Slider({
        Title = "AirJump Max Velocity",
        Step = 10,
        Value = { Min = 50, Max = 2000, Default = Config.Movement.AirJump.MaxVelocity },
        Callback = function(v) Config.Movement.AirJump.MaxVelocity = v; Movement:Refresh() end
    }))
    Reg("Movement.AirJump.Mode", AirSec:Dropdown({
        Title = "AirJump Mode",
        Values = { "Add", "Set" },
        Value = Config.Movement.AirJump.Mode,
        Callback = function(v) Config.Movement.AirJump.Mode = v; Movement:Refresh() end
    }))

    local SpeedSec = MoveTab:Section({ Title = "Speed PRO", Box = true, BoxBorder = true, Opened = true })
    Reg("Movement.Speed.Enabled", SpeedSec:Toggle({
        Title = "Enable Speed",
        Value = Config.Movement.Speed.Enabled,
        Callback = function(v) Config.Movement.Speed.Enabled = v; Movement:Refresh(); QueueSave() end
    }))
    Reg("Movement.Speed.Speed", SpeedSec:Slider({
        Title = "Walk Speed",
        Step = 1,
        Value = { Min = 16, Max = 500, Default = Config.Movement.Speed.Speed },
        Callback = function(v) Config.Movement.Speed.Speed = v; Movement:Refresh() end
    }))
    Reg("Movement.Speed.VelocityFallback", SpeedSec:Toggle({
        Title = "Velocity Fallback",
        Value = Config.Movement.Speed.VelocityFallback,
        Callback = function(v) Config.Movement.Speed.VelocityFallback = v; Movement:Refresh() end
    }))
    Reg("Movement.Speed.VelocityStrength", SpeedSec:Slider({
        Title = "Velocity Strength",
        Step = 0.05,
        Value = { Min = 0.1, Max = 1, Default = Config.Movement.Speed.VelocityStrength },
        Callback = function(v) Config.Movement.Speed.VelocityStrength = v; Movement:Refresh() end
    }))

    local JumpSec = MoveTab:Section({ Title = "HighJump PRO", Box = true, BoxBorder = true, Opened = true })
    Reg("Movement.HighJump.Enabled", JumpSec:Toggle({
        Title = "Enable HighJump",
        Value = Config.Movement.HighJump.Enabled,
        Callback = function(v) Config.Movement.HighJump.Enabled = v; Movement:Refresh(); QueueSave() end
    }))
    Reg("Movement.HighJump.JumpPower", JumpSec:Slider({
        Title = "Jump Power",
        Step = 5,
        Value = { Min = 50, Max = 500, Default = Config.Movement.HighJump.JumpPower },
        Callback = function(v) Config.Movement.HighJump.JumpPower = v; Movement:Refresh() end
    }))
    Reg("Movement.HighJump.VelocityBoost", JumpSec:Toggle({
        Title = "Velocity Boost",
        Value = Config.Movement.HighJump.VelocityBoost,
        Callback = function(v) Config.Movement.HighJump.VelocityBoost = v; Movement:Refresh() end
    }))

    local MiscMoveSec = MoveTab:Section({ Title = "Misc", Box = true, BoxBorder = true, Opened = true })
    Reg("Movement.InfiniteJump.Enabled", MiscMoveSec:Toggle({
        Title = "Infinite Jump",
        Value = Config.Movement.InfiniteJump.Enabled,
        Callback = function(v) Config.Movement.InfiniteJump.Enabled = v; Movement:Refresh(); QueueSave() end
    }))

    -- PERFORMANCE TAB
    local PerfTab = Window:Tab({ Title = "Performance", Icon = "gauge" })

    local FPSsec = PerfTab:Section({ Title = "FPS Control", Box = true, BoxBorder = true, Opened = true })
    Reg("Performance.ShowFPS", FPSsec:Toggle({
        Title = "Show FPS Counter",
        Value = Config.Performance.ShowFPS,
        Callback = function(v) Config.Performance.ShowFPS = v; QueueSave() end
    }))
    Reg("Performance.FPSCap", FPSsec:Slider({
        Title = "FPS Cap",
        Step = 5,
        Value = { Min = 20, Max = 144, Default = Config.Performance.FPSCap },
        Callback = function(v) Config.Performance.FPSCap = v; SetFPS(v); QueueSave() end
    }))
    FPSsec:Button({
        Title = "Unlimited FPS",
        Icon = "zap",
        Callback = function()
            Config.Performance.FPSCap = 9999
            SetFPS(9999)
            QueueSave()
        end
    })
    FPSsec:Button({
        Title = "Battery Saver",
        Icon = "battery",
        Color = Color3.fromRGB(255, 210, 90),
        Callback = function()
            Config.Performance.FPSCap = 30
            SetFPS(30)
            ApplyQuality("Low")
            QueueSave()
        end
    })
    Reg("Performance.AdaptiveQuality", FPSsec:Toggle({
        Title = "Adaptive Quality",
        Value = Config.Performance.AdaptiveQuality,
        Callback = function(v) Config.Performance.AdaptiveQuality = v; QueueSave() end
    }))

    local QualSec = PerfTab:Section({ Title = "Graphics Quality", Box = true, BoxBorder = true, Opened = true })
    QualSec:Dropdown({
        Title = "Quality Preset",
        Values = { "Ultra", "High", "Medium", "Low", "Potato" },
        Value = "Medium",
        Callback = function(v) ApplyQuality(v) end
    })
    Reg("Performance.PostFXOff", QualSec:Toggle({
        Title = "Disable Post-FX",
        Value = Config.Performance.PostFXOff,
        Callback = function(v) Config.Performance.PostFXOff = v; SetPostFX(v); QueueSave() end
    }))
    Reg("Performance.EffectsOff", QualSec:Toggle({
        Title = "Disable Particles",
        Value = Config.Performance.EffectsOff,
        Callback = function(v) Config.Performance.EffectsOff = v; SetEffects(v); QueueSave() end
    }))
    Reg("Performance.RemoveLights", QualSec:Toggle({
        Title = "Remove Extra Lights",
        Value = Config.Performance.RemoveLights,
        Callback = function(v) Config.Performance.RemoveLights = v; SetLights(v); QueueSave() end
    }))
    Reg("Performance.LowDetail", QualSec:Toggle({
        Title = "Low Detail",
        Value = Config.Performance.LowDetail,
        Callback = function(v) Config.Performance.LowDetail = v; SetLowDetail(v); QueueSave() end
    }))
    Reg("Performance.LowWater", QualSec:Toggle({
        Title = "Low Water Quality",
        Value = Config.Performance.LowWater,
        Callback = function(v) Config.Performance.LowWater = v; SetLowWater(v); QueueSave() end
    }))

    local LightSec = PerfTab:Section({ Title = "Lighting & World", Box = true, BoxBorder = true, Opened = false })
    Reg("Performance.Shadows", LightSec:Toggle({
        Title = "Shadows",
        Value = Config.Performance.Shadows,
        Callback = function(v) SetShadows(v); QueueSave() end
    }))
    Reg("Performance.FogDistance", LightSec:Slider({
        Title = "Fog Distance",
        Step = 100,
        Value = { Min = 100, Max = 100000, Default = Config.Performance.FogDistance },
        Callback = function(v) SetFog(v); QueueSave() end
    }))
    Reg("Performance.Brightness", LightSec:Slider({
        Title = "Brightness",
        Step = 0.1,
        Value = { Min = 0, Max = 3, Default = Config.Performance.Brightness },
        Callback = function(v) SetBright(v); QueueSave() end
    }))

    local ResetSec = PerfTab:Section({ Title = "Reset", Box = true, BoxBorder = true, Opened = true })
    ResetSec:Button({
        Title = "Restore Original",
        Icon = "rotate-ccw",
        Color = Color3.fromRGB(255, 180, 80),
        Callback = function()
            RestoreAll()
            safeCall(function() RefreshUI() end)
            QueueSave()
        end
    })

    -- PROTECTION TAB
    local ProtTab = Window:Tab({ Title = "Protection", Icon = "shield" })
    local ProtSec = ProtTab:Section({ Title = "Protection", Box = true, BoxBorder = true, Opened = true })

    Reg("Protection.AntiKickBan", ProtSec:Toggle({
        Title = "Anti Kick / Ban",
        Value = Config.Protection.AntiKickBan,
        Callback = function(v) Config.Protection.AntiKickBan = v; QueueSave() end
    }))
    Reg("Protection.AntiAFK", ProtSec:Toggle({
        Title = "Anti-AFK",
        Value = Config.Protection.AntiAFK,
        Callback = function(v) Config.Protection.AntiAFK = v; QueueSave() end
    }))
    Reg("Protection.ExecutorCloak", ProtSec:Toggle({
        Title = "Executor Cloak",
        Value = Config.Protection.ExecutorCloak,
        Callback = function(v) Config.Protection.ExecutorCloak = v; QueueSave() end
    }))
    Reg("Protection.AutoDeleteReports", ProtSec:Toggle({
        Title = "Auto Delete Reports",
        Value = Config.Protection.AutoDeleteReports,
        Callback = function(v)
            Config.Protection.AutoDeleteReports = v
            if v then safeCall(function() EnsureReportProtection() end) end
            QueueSave()
        end
    }))
    Reg("SpamFilter", ProtSec:Toggle({
        Title = "Hide Spam",
        Value = Config.SpamFilter,
        Callback = function(v) Config.SpamFilter = v; QueueSave() end
    }))

    -- SETTINGS TAB
    local SetTab = Window:Tab({ Title = "Settings", Icon = "settings" })
    local ConfigSec = SetTab:Section({ Title = "Config Manager", Box = true, BoxBorder = true, Opened = true })

    Reg("Settings.AutoSave", ConfigSec:Toggle({
        Title = "Auto Save",
        Value = Config.Settings.AutoSave,
        Callback = function(v) Config.Settings.AutoSave = v end
    }))

    ConfigSec:Button({
        Title = "Save Settings",
        Icon = "save",
        Color = Color3.fromRGB(94, 255, 170),
        Callback = function()
            local ok = SaveConfig()
            Notify(ok and "تم حفظ الإعدادات ✅" or "فشل الحفظ ❌", 3)
        end
    })

    ConfigSec:Button({
        Title = "Load Settings",
        Icon = "folder-open",
        Callback = function()
            local ok = LoadConfig()
            if ok then
                ApplyPerformanceSettings()
                Movement:Refresh()
                safeCall(function() RefreshUI() end)
                pcall(function() Window:SetToggleKey(Config.Settings.ToggleKey) end)
            end
            Notify(ok and "تم تحميل الإعدادات ✅" or "ما في ملف محفوظ ❌", 3)
        end
    })

    ConfigSec:Button({
        Title = "Reset to Default",
        Icon = "rotate-ccw",
        Color = Color3.fromRGB(255, 180, 80),
        Callback = function()
            ResetConfig()
            ApplyPerformanceSettings()
            Movement:Refresh()
            safeCall(function() RefreshUI() end)
            pcall(function() Window:SetToggleKey(Config.Settings.ToggleKey) end)
            SaveConfig()
            Notify("تم إعادة الإعدادات للافتراضي ✅", 3)
        end
    })

    local MenuSec = SetTab:Section({ Title = "Menu", Box = true, BoxBorder = true, Opened = true })

    MenuSec:Keybind({
        Title = "Toggle Menu Key",
        Value = "RightShift",
        Callback = function(keyName)
            local key = GetKeyCode(keyName)
            if key then pcall(function() Window:SetToggleKey(key) end) end
        end
    })

    MenuSec:Button({
        Title = "Close Menu",
        Icon = "x",
        Callback = function() pcall(function() Window:Close() end) end
    })

    MenuSec:Button({
        Title = "Destroy Script",
        Icon = "trash",
        Color = Color3.fromRGB(255, 80, 80),
        Callback = function()
            if Config.Settings.AutoSave then SaveConfig() end

            safeCall(function() RunService:UnbindFromRenderStep("DeltaPerf") end)
            safeCall(function() RunService:UnbindFromRenderStep("DeltaPerfStyle") end)
            safeCall(function() RunService:UnbindFromRenderStep("DeltaMovement") end)
            safeCall(function() RunService:UnbindFromRenderStep("V35FPS") end)

            safeCall(function()
                if type(getgenv) == "function" then
                    local env = getgenv()
                    if env then
                        if env.DeltaMovementDestroy then env.DeltaMovementDestroy() end
                        if env.DeltaProtectionCleanup then env.DeltaProtectionCleanup() end
                        if env.UnboxFlyCleanup then env.UnboxFlyCleanup() end
                    end
                end
            end)

            safeCall(function()
                if Fly and Fly.Destroy then Fly:Destroy() end
            end)

            safeCall(function() RestoreAll() end)
            safeCall(function()
                if Perf and Perf.Destroy then Perf.Destroy() end
            end)

            safeCall(function() Window:Destroy() end)
        end
    })

    MoveTab:Select()

    Notify("✅ Unbox Movement Hub — Movement.lua merged | No ESP", 5)
end)
