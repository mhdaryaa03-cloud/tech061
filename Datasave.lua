-----------------------------------------------------
-- 🔥 CRASH MODES
-----------------------------------------------------

-- "instant" / "brutal" / "silent" / "lags"
local CrashMode = "brutal"

local function Crash_Instant()
	error("Client terminated by anti-cheat.")
end

local function Crash_Brutal()
	pcall(function()
		game.CoreGui:Destroy()
	end)

	task.spawn(function()
		while true do
			for i = 1, 5e7 do end
		end
	end)

	pcall(function()
		error("FATAL_CLIENT_ERROR_0xDEADDEAD")
	end)

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
			for i = 1, 1e5 do
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
-- 🟢 SETUP
-----------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Rep = game:GetService("ReplicatedStorage")
local CoreGui = game:FindFirstChildOfClass("CoreGui")

local Check = Rep:WaitForChild("Check")
local CheckChildExists = Rep:WaitForChild("CheckChildExists")

-----------------------------------------------------
-- ❤️ HEARTBEAT BALASAN
-----------------------------------------------------

Check.OnClientInvoke = function()
	local a = 1 + 1
	return (a - 1) == 1
end

-----------------------------------------------------
-- 🔍 HELPER
-----------------------------------------------------

local function hasAncestorNamed(inst, name)
	local p = inst
	while p do
		if p.Name == name then
			return true
		end
		p = p.Parent
	end
	return false
end

local SafeStats = {
	"FrameRateManager", "DeviceFeatureLevel", "DeviceShadingLanguage",
	"AverageQualityLevel", "AutoQuality", "NumberOfSettles", "AverageSwitches",
	"FramebufferWidth", "FramebufferHeight", "Batches", "Indices", "MaterialChanges",
	"VideoMemoryInMB", "AverageFPS", "FrameTimeVariance", "FrameSpikeCount", "RenderAverage",
	"PrepareAverage", "PerformAverage", "AveragePresent", "AverageGPU",
	"RenderThreadAverage", "TotalFrameWallAverage", "PerformVariance",
	"PresentVariance", "GpuVariance", "MsFrame0", "MsFrame1", "MsFrame2",
	"MsFrame3", "MsFrame4", "MsFrame5", "MsFrame6", "MsFrame7", "MsFrame8",
	"MsFrame9", "MsFrame10", "MsFrame11", "Render", "Memory", "Video",
	"CursorImage", "LanguageService"
}

local function isSafeStat(n)
	for _, v in ipairs(SafeStats) do
		if v == n then
			return true
		end
	end
	return false
end

-----------------------------------------------------
-- 🟢 UI / SELFVIEW WHITELIST
-----------------------------------------------------

local function isWhitelistedUI(inst)
	-- 1) semua yang ada di bawah SelfView aman
	if hasAncestorNamed(inst, "SelfView") then
		return true
	end

	-- 2) komponennya
	local uiNames = {
		"FaceAnimator",
		"CameraTracking",
		"VideoStreamer",
	}

	for _, n in ipairs(uiNames) do
		if inst.Name == n or hasAncestorNamed(inst, n) then
			return true
		end
	end

	-- 3) UI Roblox default di dalam RobloxGui (CoreGui.RobloxGui.*)
	if CoreGui then
		local robloxGui = CoreGui:FindFirstChild("RobloxGui")
		if robloxGui and inst:IsDescendantOf(robloxGui) then
			return true
		end
	end

	-- 4) GUI dari game-mu sendiri (StarterGui → PlayerGui clone)
	if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
		if inst:IsDescendantOf(LocalPlayer.PlayerGui) then
			return true
		end
	end

	return false
end

-----------------------------------------------------
-- 🔒 AREA YANG DIJAGA (DENGAN EXECUTOR DETECT)
-----------------------------------------------------

local PROTECTED = {
	game:GetService("Workspace"),
	game:GetService("ReplicatedStorage"),
	game:GetService("Lighting"),
}

if CoreGui then
	table.insert(PROTECTED, CoreGui) -- pantau CoreGui (executor GUI)
end

local function isProtected(inst)
	for _, root in ipairs(PROTECTED) do
		if inst:IsDescendantOf(root) then
			return true
		end
	end
	return false
end

-----------------------------------------------------
-- 🛑 DETEKSI INSTANCE BARU
-----------------------------------------------------

task.wait(1)

game.DescendantAdded:Connect(function(obj)
	-- 1. Abaikan UI aman (SelfView, kamera, musik, UI Roblox, UI game)
	if isWhitelistedUI(obj) then
		return
	end

	-- 2. Abaikan stats aman
	if isSafeStat(obj.Name) then
		return
	end

	-- 3. Hanya cek wilayah penting (Workspace, RepStorage, Lighting, CoreGui)
	if not isProtected(obj) then
		return
	end

	-- 4. Cek apakah object ini memang ada di server
	local exist = false
	if obj.Parent then
		local ok, result = pcall(function()
			return CheckChildExists:InvokeServer(obj.Parent.Name, obj.Name)
		end)
		if ok then
			exist = result
		else
			warn("CheckChildExists failed:", result)
			return
		end
	end

	-- 5. Cek Key (signature dari server)
	local keyObj = obj:FindFirstChild("Key")
	local serverKey
	local okKey, resKey = pcall(function()
		return Rep:GetKey:InvokeServer()
	end)

	if not okKey then
		warn("GetKey failed:", resKey)
		return
	end

	serverKey = resKey

	if keyObj and exist then
		-- object asli server, tapi key diubah = exploit
		if keyObj.Value ~= serverKey then
			Rep.AntiCheat:FireServer(obj.Name, "modified key")
			Crash()
		end

	elseif obj.Name == "Key" then
		-- bikin StringValue Key palsu
		if obj.Value ~= serverKey then
			Rep.AntiCheat:FireServer(obj.Name, "invalid client key")
			Crash()
		end

	elseif not keyObj and not exist then
		-- object client-only di area penting (Workspace/RepStorage/Lighting/CoreGui)
		-- biasa dilakukan executor → ban / crash
		Rep.AntiCheat:FireServer(obj.Name, "unauthorized instance")
		Crash()
	end
end)
