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
	TapXP = { Enabled = true, Delay = 0.2, UseRemote = true, UseClick = true },
	Collect = { Enabled = true, Delay = 0.35, Radius = 250, Batch = 20, WorldDrops = true, FactoryMoney = true },
	Magnet = { Enabled = true, Batch = 3, CycleDelay = 0.6, WalkFallback = false },
	OpenCrates = { Enabled = true, Threshold = 10, MaxPerCycle = 3, Skip = true },
	Luck = { Enabled = false, Multiplier = 100 },
	Movement = {
		Speed = { Enabled = false, Speed = 60, VelocityFallback = true, VelocityStrength = 0.65 },
		HighJump = { Enabled = false, JumpPower = 40, VelocityBoost = true },
		AirJump = { Enabled = false, Jumps = 3, Unlimited = false, Power = 90, Mode = "Add", MaxVelocity = 280 },
		InfiniteJump = { Enabled = false },
		NoClip = { Enabled = false },
		Fly = { Enabled = false, Speed = 60, Accel = 100, MaxSpeed = 200 },
	},
	Performance = { FPSCap = 60, ShowFPS = false, Adaptive = false },
	Protection = { AntiKick = true, AntiAFK = true, Cloak = true, DeleteReports = true },
	SpamFilter = true,
	Settings = { AutoSave = true, ToggleKey = Enum.KeyCode.RightShift },
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

-- ═══ 4) CONFIG SAVE/LOAD ═══
local CONFIG_FILE = "DeltaHub/UnboxV35.json"
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
	local ok = safeCall(function()
		if type(isfolder) == "function" and not isfolder("DeltaHub") then makefolder("DeltaHub") end
		writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
	end)
	return ok
end
local function LoadConfig()
	local ok = false
	safeCall(function()
		if type(isfile) == "function" and isfile(CONFIG_FILE) then
			DeepMerge(Config, HttpService:JSONDecode(readfile(CONFIG_FILE)))
			ok = true
		end
	end)
	return ok
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

-- ═══ 9) NAMECALL HOOK (Capture + AntiKick) ═══
local HookOn = false
Safe(function()
	if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then return end
	local mt = getrawmetatable(game)
	if mt == nil then return end
	local old = mt.__namecall
	if old == nil then return end
	if type(setreadonly) == "function" then pcall(function() setreadonly(mt, false) end) end
	mt.__namecall = newcclosure(function(self, ...)
		local method = nil
		if type(getnamecallmethod) == "function" then
			local o, m = pcall(getnamecallmethod)
			if o then method = m end
		end
		if method == "FireServer" and typeof(self) == "Instance" then
			if self.Name == "PickupCrateEvent" then
				local a = table.pack(...)
				if a[1] ~= nil then task.defer(function() Safe(LearnCapture, a[1]) end) end
			elseif Config.Protection.AntiKick and ContainsBadText(self.Name) then
				return nil
			end
		end
		return old(self, ...)
	end)
	if type(setreadonly) == "function" then pcall(function() setreadonly(mt, true) end) end
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

-- ═══ 15) 🚀 MOVEMENT ENGINE (Movement.lua — حرفياً + تحكم كامل) ═══
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
		self._flyConn = RunService.Heartbeat:Connect(function(dt)
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

-- ═══ 16) ⚙️ PERFORMANCE ENGINE ═══
local Perf = {}
Perf.OrigLight = { captured = false }
Perf.SavedFX = setmetatable({}, { __mode = "k" })
Perf.SavedPost = setmetatable({}, { __mode = "k" })
Perf.SavedLights = setmetatable({}, { __mode = "k" })
Perf.FXConn = nil
Perf.LightConn = nil
Perf.FPS = { frames = 0, last = tick(), value = 0, draw = nil, lastAdapt = 0 }
local function SetFPS(n)
	if type(setfpscap) == "function" then pcall(setfpscap, math.floor(ClampNumber(n, 1, 9999))) end
end
local function CaptureLight()
	if Perf.OrigLight.captured then return end
	local o = Perf.OrigLight
	o.captured = true
	pcall(function() o.GS = Lighting.GlobalShadows end)
	pcall(function() o.SS = Lighting.ShadowSoftness end)
	pcall(function() o.B = Lighting.Brightness end)
	pcall(function() o.FE = Lighting.FogEnd end)
	pcall(function() o.T = Lighting.Technology end)
end
local POST_CLASSES = { "BloomEffect", "BlurEffect", "ColorCorrectionEffect", "SunRaysEffect", "DepthOfFieldEffect" }
local function SetPostFX(off)
	if off then
		for _, obj in ipairs(Lighting:GetDescendants()) do
			for _, cls in ipairs(POST_CLASSES) do
				if obj:IsA(cls) then
					local ok, en = pcall(function() return obj.Enabled end)
					Perf.SavedPost[obj] = ok and en or true
					pcall(function() obj.Enabled = false end)
				end
			end
		end
	else
		for obj, en in pairs(Perf.SavedPost) do pcall(function() obj.Enabled = en end) end
		table.clear(Perf.SavedPost)
	end
end
local FX_CLASSES = { "ParticleEmitter", "Beam", "Trail", "Fire", "Smoke", "Sparkles" }
local function KillFX(obj)
	for _, cls in ipairs(FX_CLASSES) do
		if obj:IsA(cls) then
			local ok, en = pcall(function() return obj.Enabled end)
			Perf.SavedFX[obj] = ok and en or true
			pcall(function() obj.Enabled = false end)
		end
	end
end
local function SetEffects(off)
	if off then
		task.spawn(function()
			for _, obj in ipairs(Workspace:GetDescendants()) do pcall(KillFX, obj) end
		end)
		if not Perf.FXConn then Perf.FXConn = Workspace.DescendantAdded:Connect(function(o) pcall(KillFX, o) end) end
	else
		if Perf.FXConn then pcall(function() Perf.FXConn:Disconnect() end) Perf.FXConn = nil end
		for obj, en in pairs(Perf.SavedFX) do pcall(function() obj.Enabled = en end) end
		table.clear(Perf.SavedFX)
	end
end
local LIGHT_CLASSES = { "PointLight", "SpotLight", "SurfaceLight" }
local function KillLight(obj)
	for _, cls in ipairs(LIGHT_CLASSES) do
		if obj:IsA(cls) then
			local ok, en = pcall(function() return obj.Enabled end)
			Perf.SavedLights[obj] = ok and en or true
			pcall(function() obj.Enabled = false end)
		end
	end
end
local function SetLights(off)
	if off then
		task.spawn(function()
			for _, obj in ipairs(Workspace:GetDescendants()) do pcall(KillLight, obj) end
		end)
		if not Perf.LightConn then Perf.LightConn = Workspace.DescendantAdded:Connect(function(o) pcall(KillLight, o) end) end
	else
		if Perf.LightConn then pcall(function() Perf.LightConn:Disconnect() end) Perf.LightConn = nil end
		for obj, en in pairs(Perf.SavedLights) do pcall(function() obj.Enabled = en end) end
		table.clear(Perf.SavedLights)
	end
end
local PRESETS = {
	Ultra = { GS = true, SS = 1, B = 2, FE = 100000, Tech = "ShadowMap", Post = false, FX = false, Lights = false },
	High = { GS = true, SS = 0.5, B = 2, FE = 40000, Tech = "ShadowMap", Post = false, FX = false, Lights = false },
	Medium = { GS = false, SS = 0, B = 1.5, FE = 12000, Tech = "ShadowMap", Post = true, FX = true, Lights = false },
	Low = { GS = false, SS = 0, B = 1, FE = 3000, Tech = "Voxel", Post = true, FX = true, Lights = true },
	Potato = { GS = false, SS = 0, B = 1, FE = 800, Tech = "Legacy", Post = true, FX = true, Lights = true },
}
local function ApplyQuality(name)
	CaptureLight()
	local p = PRESETS[name]
	if not p then return end
	pcall(function() Lighting.GlobalShadows = p.GS end)
	pcall(function() Lighting.ShadowSoftness = p.SS end)
	pcall(function() Lighting.Brightness = p.B end)
	pcall(function() Lighting.FogEnd = p.FE end)
	if p.Tech then
		local ok, tech = pcall(function() return Enum.Technology[p.Tech] end)
		if ok and tech then pcall(function() Lighting.Technology = tech end) end
	end
	SetPostFX(p.Post)
	SetEffects(p.FX)
	SetLights(p.Lights)
end
local function RestoreAll()
	local o = Perf.OrigLight
	if o.captured then
		pcall(function() Lighting.GlobalShadows = o.GS end)
		pcall(function() Lighting.ShadowSoftness = o.SS end)
		pcall(function() Lighting.Brightness = o.B end)
		pcall(function() Lighting.FogEnd = o.FE end)
		if o.T then pcall(function() Lighting.Technology = o.T end) end
	end
	SetPostFX(false); SetEffects(false); SetLights(false)
	SetFPS(9999)
end
Safe(function()
	if type(Drawing) ~= "table" and type(Drawing) ~= "userdata" then return end
	Perf.FPS.draw = Drawing.new("Text")
	Perf.FPS.draw.Center = false
	Perf.FPS.draw.Outline = true
	Perf.FPS.draw.Position = Vector2.new(12, 12)
	Perf.FPS.draw.Size = 14
	Perf.FPS.draw.Visible = false
end)
CaptureLight()
SetFPS(Config.Performance.FPSCap)
Safe(function()
	RunService:BindToRenderStep("V35FPS", 100, function()
		Perf.FPS.frames = Perf.FPS.frames + 1
		local now = tick()
		if now - Perf.FPS.last >= 0.5 then
			Perf.FPS.value = math.floor(Perf.FPS.frames / (now - Perf.FPS.last))
			Perf.FPS.frames = 0
			Perf.FPS.last = now
			if Perf.FPS.draw then
				Perf.FPS.draw.Visible = Config.Performance.ShowFPS
				Perf.FPS.draw.Text = "FPS: " .. Perf.FPS.value
				if Perf.FPS.value >= 50 then Perf.FPS.draw.Color = Color3.fromRGB(94, 255, 170)
				elseif Perf.FPS.value >= 30 then Perf.FPS.draw.Color = Color3.fromRGB(255, 210, 90)
				else Perf.FPS.draw.Color = Color3.fromRGB(255, 94, 98) end
			end
			if Config.Performance.Adaptive then
				if now - Perf.FPS.lastAdapt >= 1.5 then
					Perf.FPS.lastAdapt = now
					local f = Perf.FPS.value
					if f > 0 then
						if f < 28 then ApplyQuality("Potato")
						elseif f < 42 then ApplyQuality("Low")
						elseif f < 52 then ApplyQuality("Medium") end
					end
				end
			end
		end
	end)
end)

-- ═══ 17) 🛡 PROTECTION ENGINE ═══
Safe(function()
	if not Config.Protection.Cloak then return end
	if type(hookfunction) ~= "function" then return end
	if type(getexecutorname) == "function" then
		hookfunction(getexecutorname, function() return "Roblox" end)
	end
	if type(identifyexecutor) == "function" then
		hookfunction(identifyexecutor, function() return "Roblox", {} end)
	end
end)
Safe(function()
	LocalPlayer.Idled:Connect(function()
		if Config.Protection.AntiAFK then
			pcall(function() VirtualUser:CaptureController() end)
			pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
		end
	end)
end)
local ReportHooked = {}
local function RemoveReport(obj)
	if not Config.Protection.DeleteReports then return end
	if typeof(obj) ~= "Instance" then return end
	if not ContainsBadText(obj.Name) then return end
	if obj:IsA("LayerCollector") or obj:IsA("GuiObject") then
		pcall(function() obj:Destroy() end)
	end
end
Safe(function()
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg == nil or ReportHooked[pg] then return end
	ReportHooked[pg] = true
	for _, obj in ipairs(pg:GetDescendants()) do RemoveReport(obj) end
	pg.DescendantAdded:Connect(function(o) task.defer(RemoveReport, o) end)
end)

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

-- ═══ 20) 🎛 WINDUI MENU (تحكم كامل) ═══
Safe(function()
	local src = nil
	pcall(function() src = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua") end)
	if src == nil and type(request) == "function" then
		pcall(function()
			local r = request({ Url = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", Method = "GET" })
			if r and r.Body then src = r.Body end
		end)
	end
	if src == nil then
		Notify("WindUI فشل — الميزات تعمل بدون قائمة", 6)
		return
	end
	local ok, WindUI = pcall(function() return loadstring(src)() end)
	if not ok or type(WindUI) ~= "table" then return end
	local Win = WindUI:CreateWindow({ Title = "Unbox a Factor Hub", Author = "V35 FINAL MASTER", Icon = "box", Theme = "Dark" })
	pcall(function() Win:SetToggleKey(Config.Settings.ToggleKey) end)
	-- AUTO
	pcall(function()
		local Auto = Win:Tab({ Title = "Auto", Icon = "zap" })
		local s1 = Auto:Section({ Title = "⚡ Tap + 💰 Collect", Box = true, Opened = true })
		s1:Toggle({ Title = "Auto Tap XP", Value = Config.TapXP.Enabled, Callback = function(v) Config.TapXP.Enabled = v; QueueSave() end })
		s1:Toggle({ Title = "Auto Collect", Value = Config.Collect.Enabled, Callback = function(v) Config.Collect.Enabled = v; QueueSave() end })
		s1:Slider({ Title = "Collect Radius", Min = 20, Max = 500, Default = Config.Collect.Radius, Rounding = 0, Callback = function(v) Config.Collect.Radius = v end })
		local s2 = Auto:Section({ Title = "🧲 Crate Magnet", Box = true, Opened = true })
		s2:Toggle({ Title = "Magnet (بدون مشي)", Value = Config.Magnet.Enabled, Callback = function(v) Config.Magnet.Enabled = v; QueueSave() end })
		s2:Toggle({ Title = "Walk Fallback", Value = Config.Magnet.WalkFallback, Callback = function(v) Config.Magnet.WalkFallback = v end })
		s2:Slider({ Title = "Batch", Min = 1, Max = 10, Default = Config.Magnet.Batch, Rounding = 0, Callback = function(v) Config.Magnet.Batch = v end })
		local s3 = Auto:Section({ Title = "📦 Open +  Luck", Box = true, Opened = true })
		s3:Toggle({ Title = "Auto Open (عند الامتلاء)", Value = Config.OpenCrates.Enabled, Callback = function(v) Config.OpenCrates.Enabled = v; QueueSave() end })
		s3:Slider({ Title = "Open Threshold", Min = 1, Max = 20, Default = Config.OpenCrates.Threshold, Rounding = 0, Callback = function(v) Config.OpenCrates.Threshold = v end })
		s3:Toggle({ Title = "Luck Boost", Value = Config.Luck.Enabled, Callback = function(v) Config.Luck.Enabled = v; QueueSave() end })
		Auto:Select()
	end)
	-- MOVEMENT (تحكم كامل)
	pcall(function()
		local Move = Win:Tab({ Title = "Movement", Icon = "wind" })
		local m1 = Move:Section({ Title = "🏃 Speed", Box = true, Opened = true })
		m1:Toggle({ Title = "Speed", Value = Config.Movement.Speed.Enabled, Callback = function(v) Config.Movement.Speed.Enabled = v; Movement:Refresh(); QueueSave() end })
		m1:Slider({ Title = "Walk Speed", Min = 16, Max = 500, Default = Config.Movement.Speed.Speed, Rounding = 0, Callback = function(v) Config.Movement.Speed.Speed = v; Movement:Refresh() end })
		m1:Toggle({ Title = "Velocity Fallback", Value = Config.Movement.Speed.VelocityFallback, Callback = function(v) Config.Movement.Speed.VelocityFallback = v end })
		m1:Slider({ Title = "Velocity Strength", Min = 0, Max = 1, Default = Config.Movement.Speed.VelocityStrength, Rounding = 2, Callback = function(v) Config.Movement.Speed.VelocityStrength = v end })
		local m2 = Move:Section({ Title = "⬆️ High Jump", Box = true, Opened = true })
		m2:Toggle({ Title = "HighJump", Value = Config.Movement.HighJump.Enabled, Callback = function(v) Config.Movement.HighJump.Enabled = v; Movement:Refresh(); QueueSave() end })
		m2:Slider({ Title = "Jump Power", Min = 50, Max = 500, Default = Config.Movement.HighJump.JumpPower, Rounding = 0, Callback = function(v) Config.Movement.HighJump.JumpPower = v; Movement:Refresh() end })
		m2:Toggle({ Title = "Velocity Boost", Value = Config.Movement.HighJump.VelocityBoost, Callback = function(v) Config.Movement.HighJump.VelocityBoost = v; Movement:Refresh() end })
		local m3 = Move:Section({ Title = "🌬 Air Jump", Box = true, Opened = true })
		m3:Toggle({ Title = "AirJump", Value = Config.Movement.AirJump.Enabled, Callback = function(v) Config.Movement.AirJump.Enabled = v; Movement:Refresh(); QueueSave() end })
		m3:Slider({ Title = "AirJump Power", Min = 50, Max = 500, Default = Config.Movement.AirJump.Power, Rounding = 0, Callback = function(v) Config.Movement.AirJump.Power = v; Movement:Refresh() end })
		m3:Slider({ Title = "Jumps Count", Min = 1, Max = 20, Default = Config.Movement.AirJump.Jumps, Rounding = 0, Callback = function(v) Config.Movement.AirJump.Jumps = v end })
		m3:Toggle({ Title = "Unlimited Jumps", Value = Config.Movement.AirJump.Unlimited, Callback = function(v) Config.Movement.AirJump.Unlimited = v end })
		m3:Dropdown({ Title = "Mode", Values = { "Add", "Set" }, Value = tostring(Config.Movement.AirJump.Mode), Callback = function(v) Config.Movement.AirJump.Mode = v end })
		m3:Slider({ Title = "Max Velocity", Min = 50, Max = 1000, Default = Config.Movement.AirJump.MaxVelocity, Rounding = 0, Callback = function(v) Config.Movement.AirJump.MaxVelocity = v end })
		local m4 = Move:Section({ Title = "🔧 Misc + Fly", Box = true, Opened = true })
		m4:Toggle({ Title = "Infinite Jump", Value = Config.Movement.InfiniteJump.Enabled, Callback = function(v) Config.Movement.InfiniteJump.Enabled = v; QueueSave() end })
		m4:Toggle({ Title = "NoClip", Value = Config.Movement.NoClip.Enabled, Callback = function(v) Config.Movement.NoClip.Enabled = v; Movement:Refresh(); QueueSave() end })
		m4:Toggle({ Title = "Fly", Value = Config.Movement.Fly.Enabled, Callback = function(v) Config.Movement.Fly.Enabled = v; Movement:Refresh(); QueueSave() end })
		m4:Slider({ Title = "Fly Speed", Min = 10, Max = 500, Default = Config.Movement.Fly.Speed, Rounding = 0, Callback = function(v) Config.Movement.Fly.Speed = v end })
		m4:Slider({ Title = "Accel (نعومة)", Min = 1, Max = 500, Default = Config.Movement.Fly.Accel, Rounding = 0, Callback = function(v) Config.Movement.Fly.Accel = v end })
		m4:Slider({ Title = "Max Speed", Min = 50, Max = 1000, Default = Config.Movement.Fly.MaxSpeed, Rounding = 0, Callback = function(v) Config.Movement.Fly.MaxSpeed = v; Movement:Refresh() end })
	end)
	-- PERFORMANCE
	pcall(function()
		local Pf = Win:Tab({ Title = "Performance", Icon = "gauge" })
		local sp = Pf:Section({ Title = "⚙️ Performance", Box = true, Opened = true })
		sp:Toggle({ Title = "Show FPS", Value = Config.Performance.ShowFPS, Callback = function(v) Config.Performance.ShowFPS = v end })
		sp:Slider({ Title = "FPS Cap", Min = 20, Max = 144, Default = Config.Performance.FPSCap, Rounding = 0, Callback = function(v) Config.Performance.FPSCap = v; SetFPS(v) end })
		sp:Toggle({ Title = "Adaptive Quality (ضد التقطيع)", Value = Config.Performance.Adaptive, Callback = function(v) Config.Performance.Adaptive = v end })
		sp:Dropdown({ Title = "Quality Preset", Values = { "Ultra", "High", "Medium", "Low", "Potato" }, Value = "High", Callback = function(v) ApplyQuality(v) end })
		sp:Button({ Title = "Restore Original", Icon = "rotate-ccw", Callback = function() RestoreAll() end })
	end)
	-- PROTECTION
	pcall(function()
		local Pr = Win:Tab({ Title = "Protection", Icon = "shield" })
		local sh = Pr:Section({ Title = "🛡 Protection", Box = true, Opened = true })
		sh:Toggle({ Title = "Anti Kick/Ban", Value = Config.Protection.AntiKick, Callback = function(v) Config.Protection.AntiKick = v; QueueSave() end })
		sh:Toggle({ Title = "Anti-AFK", Value = Config.Protection.AntiAFK, Callback = function(v) Config.Protection.AntiAFK = v end })
		sh:Toggle({ Title = "Executor Cloak", Value = Config.Protection.Cloak, Callback = function(v) Config.Protection.Cloak = v end })
		sh:Toggle({ Title = "Delete Reports", Value = Config.Protection.DeleteReports, Callback = function(v) Config.Protection.DeleteReports = v end })
		sh:Toggle({ Title = "Hide Spam", Value = Config.SpamFilter, Callback = function(v) Config.SpamFilter = v end })
	end)
	-- SETTINGS
	pcall(function()
		local St = Win:Tab({ Title = "Settings", Icon = "settings" })
		local ss = St:Section({ Title = "💾 Config", Box = true, Opened = true })
		ss:Toggle({ Title = "Auto Save", Value = Config.Settings.AutoSave, Callback = function(v) Config.Settings.AutoSave = v end })
		ss:Button({ Title = "Save Now", Icon = "save", Callback = function()
			Notify(SaveConfig() and "تم الحفظ ✅" or "فشل ❌", 3)
		end })
		ss:Button({ Title = "Load", Icon = "folder-open", Callback = function()
			local okL = LoadConfig()
			if okL then Movement:Refresh() end
			Notify(okL and "تم التحميل ✅" or "ما في ملف ❌", 3)
		end })
		ss:Button({ Title = "Restore Original", Icon = "rotate-ccw", Color = Color3.fromRGB(255, 180, 80), Callback = function()
			Config.Movement.Speed.Enabled = false
			Config.Movement.HighJump.Enabled = false
			Config.Movement.AirJump.Enabled = false
			Config.Movement.InfiniteJump.Enabled = false
			Config.Movement.NoClip.Enabled = false
			Config.Movement.Fly.Enabled = false
			Movement:Refresh()
			QueueSave()
			Notify("تم إرجاع القيم الأصلية ✅", 4)
		end })
		ss:Button({ Title = "Close Menu", Icon = "x", Callback = function() pcall(function() Win:Close() end) end })
	end)
	Notify("🏆 V35 FINAL MASTER loaded", 6)
end)
Notify("✅ V35 — الكود الكامل النهائي", 5)
