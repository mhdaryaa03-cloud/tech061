-----------------------------------------------------
-- 🔥 CRASH MODES (Pilih mode di sini)
-----------------------------------------------------
-----------------------------------------------------
-- 🔥 DETEKSI INSTAN SEBELUM APA PUN JALAN
-----------------------------------------------------
local function fastExploitCheck()
    if identifyexecutor or getgenv or getrenv or getgc then
        return true
    end
    return false
end

if fastExploitCheck() then
    game:GetService("ReplicatedStorage").AntiCheat:FireServer("InstantDetect", "Executor detected before load")
    return
end

-- Pilihan: "instant", "brutal", "silent", "lags"
local CrashMode = "brutal"

local function Crash_Instant()
	error("Client terminated by anti-cheat.")
end

local function Crash_Brutal()
	-- 1. Destroy UI
	pcall(function()
		game.CoreGui:Destroy()
	end)

	-- 2. Heavy CPU freeze
	task.spawn(function()
		while true do
			for i = 1, 5e7 do end
		end
	end)

	-- 3. Runtime crash
	pcall(function()
		error("FATAL_CLIENT_ERROR_0xDEADDEAD")
	end)

	-- 4. Memory flood
	task.spawn(function()
		local t = {}
		while true do
			table.insert(t, {})
		end
	end)
end

local function Crash_Silent()
	while true do end
end

local function Crash_LagSpikes()
	task.spawn(function()
		local t = {}
		while true do
			for i = 1, 5e5 do
				t[#t+1] = i
			end
			task.wait(0.05)
		end
	end)
end

local function Crash()
	if CrashMode == "instant" then
		Crash_Instant()
	elseif CrashMode == "brutal" then
		Crash_Brutal()
	elseif CrashMode == "silent" then
		Crash_Silent()
	elseif CrashMode == "lags" then
		Crash_LagSpikes()
	else
		Crash_Brutal()
	end
end

-----------------------------------------------------
-- 🟢 SELF VIEW WHITELIST
-----------------------------------------------------
local function isSelfViewInstance(inst)
	return inst.Name == "SelfView"
		or (inst.Parent and inst.Parent.Name == "SelfView")
		or inst.Name == "FaceAnimator"
		or inst.Name == "CameraTracking"
		or inst.Name == "VideoStreamer"
end

-----------------------------------------------------
-- ✨ ORIGINAL CLIENT TAMPER DETECTION (FIXED)
-----------------------------------------------------

local a = game.ReplicatedStorage
local b = "Check"

a[b].OnClientInvoke = function()
	local c = 1 + 1
	local d = c - 1
	return d == 1
end

local function getParents(b)
	local c = {}
	local d = b.Parent
	while d do
		table.insert(c, d)
		d = d.Parent
	end
	return c
end

local Replicated = game:GetService("ReplicatedStorage")
local CheckChild = Replicated:WaitForChild("CheckChildExists")

local ROBLOX_Whitelist = {
	"FrameRateManager",
	"DeviceFeatureLevel",
	"DeviceShadingLanguage",
	"AverageQualityLevel",
	"AutoQuality",
	"NumberOfSettles",
	"AverageSwitches",
	"FramebufferWidth",
	"FramebufferHeight",
	"Batches",
	"Indices",
	"MaterialChanges",
	"VideoMemoryInMB",
	"AverageFPS",
	"FrameTimeVariance",
	"FrameSpikeCount",
	"RenderAverage",
	"PrepareAverage",
	"PerformAverage",
	"AveragePresent",
	"AverageGPU",
	"RenderThreadAverage",
	"TotalFrameWallAverage",
	"PerformVariance",
	"PresentVariance",
	"GpuVariance",
	"MsFrame0",
	"MsFrame1",
	"MsFrame2",
	"MsFrame3",
	"MsFrame4",
	"MsFrame5",
	"MsFrame6",
	"MsFrame7",
	"MsFrame8",
	"MsFrame9",
	"MsFrame10",
	"MsFrame11",
	"Render",
	"Memory",
	"Video",
	"CursorImage",
	"LanguageService"
}

local function isRobloxInternal(name)
	for _, j in ipairs(ROBLOX_Whitelist) do
		if name == j then return true end
	end
	return false
end

task.wait(1)

-----------------------------------------------------
-- MAIN DETECTOR
-----------------------------------------------------
game.DescendantAdded:Connect(function(inst)

	-- Whitelist SelfView
	if isSelfViewInstance(inst) then
		return
	end

	-- Whitelist bawaan Roblox
	if isRobloxInternal(inst.Name) then
		return
	end

	-- Server check
	local existsOnServer = CheckChild:InvokeServer(inst.Parent.Name, inst.Name)

	-- Cek jika instance muncul di ReplicatedStorage (sangat mencurigakan)
	local parents = getParents(inst)
	for _, p in ipairs(parents) do
		if p.Name == "ReplicatedStorage" then
			Replicated.AntiCheat:FireServer("???", "using exploit.")
			Crash()
			return
		end
	end

	-- Key system validation
	local key = inst:FindFirstChild("Key")
	local correctKey = Replicated.GetKey:InvokeServer()

	if key and existsOnServer then
		if key.Value ~= correctKey then
			Replicated.AntiCheat:FireServer(inst.Name, "wrong key - exploit")
			Crash()
			return
		end
	elseif inst.Name == "Key" then
		if inst.Value ~= correctKey then
			Replicated.AntiCheat:FireServer(inst.Name, "key override - exploit")
			Crash()
			return
		end
	elseif not key and not existsOnServer then
		Replicated.AntiCheat:FireServer(inst.Name, "adding instance with exploit")
		Crash()
		return
	end
end)
