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

local function Crash_Silent() while true do end end

local function Crash_LagSpikes()
	task.spawn(function()
		local t = {}
		while true do
			for i = 1, 1e5 do t[#t+1] = i end
			task.wait(0.05)
		end
	end)
end

local function Crash()
	if CrashMode == "instant" then Crash_Instant()
	elseif CrashMode == "brutal" then Crash_Brutal()
	elseif CrashMode == "silent" then Crash_Silent()
	elseif CrashMode == "lags" then Crash_LagSpikes()
	else Crash_Brutal() end
end

-----------------------------------------------------
-- 🟢 UI WHITELIST (PENTING)
-----------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function isWhitelistedUI(inst)
	-- SelfView components
	if inst.Name == "SelfView"
		or (inst.Parent and inst.Parent.Name == "SelfView")
		or inst.Name == "FaceAnimator"
		or inst.Name == "CameraTracking"
		or inst.Name == "VideoStreamer"
	then
		return true
	end

	-- UI Roblox lain
	local whitelist = {
		"PlayerList",
		"TopBar",
		"InGameMenu",
		"Chat",
		"TouchGui",
		"Backpack",
		"EmotesMenu",
		"ControlFrame",
		"MediaPrompt",
		"Music",
		"PurchasePrompt",
		"ContextActionGui",
		"CameraUI",
	}

	for _, v in ipairs(whitelist) do
		if inst.Name == v then
			return true
		end
	end

	-- Semua UI di CoreGui aman
	local CoreGui = game:FindFirstChildOfClass("CoreGui")
	if CoreGui and inst:IsDescendantOf(CoreGui) then
		return true
	end

	-- Semua UI di PlayerGui aman
	if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
		if inst:IsDescendantOf(LocalPlayer.PlayerGui) then
			return true
		end
	end

	return false
end

-----------------------------------------------------
-- 🧠 SCRIPT ANTI-TAMPER
-----------------------------------------------------

local Rep = game:GetService("ReplicatedStorage")
local Check = Rep:WaitForChild("Check")

Check.OnClientInvoke = function()
	local a = 1 + 1
	return (a - 1) == 1
end

local function findParents(child)
	local list = {}
	local p = child.Parent
	while p do
		table.insert(list, p)
		p = p.Parent
	end
	return list
end

local CheckChildExists = Rep:WaitForChild("CheckChildExists")

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
-- 🔒 AREA YANG BENAR-BENAR DIJAGA
-----------------------------------------------------

local PROTECTED = {
	game:GetService("Workspace"),
	game:GetService("ReplicatedStorage"),
	game:GetService("Lighting"),
}

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

	-- 1. Abaikan semua UI
	if isWhitelistedUI(obj) then return end

	-- 2. Abaikan stats aman
	if isSafeStat(obj.Name) then return end

	-- 3. Hanya cek wilayah penting
	if not isProtected(obj) then return end

	-- 4. Cek apakah object di server memang ada
	local exist = false
	if obj.Parent then
		local ok, result = pcall(function()
			return CheckChildExists:InvokeServer(obj.Parent.Name, obj.Name)
		end)
		if ok then exist = result else return end
	end

	-- 5. Cek Key (signature)
	local keyObj = obj:FindFirstChild("Key")
	local serverKey = Rep:GetKey:InvokeServer()

	if keyObj and exist then
		if keyObj.Value ~= serverKey then
			Rep.AntiCheat:FireServer(obj.Name, "modified key")
			Crash()
		end

	elseif obj.Name == "Key" then
		if obj.Value ~= serverKey then
			Rep.AntiCheat:FireServer(obj.Name, "invalid client key")
			Crash()
		end

	elseif not keyObj and not exist then
		Rep.AntiCheat:FireServer(obj.Name, "unauthorized instance")
		Crash()
	end
end)
