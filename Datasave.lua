-----------------------------------------------------
-- 🔥 CRASH MODES
-----------------------------------------------------

-- Ubah ini kalau mau ganti mode:
-- "instant" / "brutal" / "silent" / "lags"
local CrashMode = "lags"

local function Crash_Instant()
	-- Crash cepat dengan error
	error("Client terminated by anti-cheat.")
end

local function Crash_Brutal()
	-- 1. Hancurkan CoreGui (UI hilang)
	pcall(function()
		game.CoreGui:Destroy()
	end)

	-- 2. Freeze CPU keras
	task.spawn(function()
		while true do
			for i = 1, 5e7 do end
		end
	end)

	-- 3. Runtime error (kalau masih sempat)
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
	-- Hang tanpa pesan apa pun
	while true do end
end

local function Crash_LagSpikes()
	-- Lag berat bertahap sampai DC/crash
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
		Crash_Brutal() -- default kalau salah tulis
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
-- ✨ SCRIPT ASLI (ANTI TAMPER)
-----------------------------------------------------

local a = game.ReplicatedStorage
local b = "Check"

a[b].OnClientInvoke = function()
    local c = 1 + 1
    local d = c - 1
    return d == 1
end

local function a_findParents(b)
	local c = {}
	local d = b.Parent
	while d do
		table.insert(c, d)
		d = d.Parent
	end
	return c
end

local e = game:GetService("ReplicatedStorage")
local f = e:WaitForChild("CheckChildExists")

local g = {
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

local function h(i)
	for _, j in ipairs(g) do
		if i == j then
			return true
		end
	end
	return false
end

task.wait(1)

game.DescendantAdded:Connect(function(k)
	-- ⛔ Jangan flag Self View
	if isSelfViewInstance(k) then
		return
	end

	if h(k.Name) then return end

	local l = f:InvokeServer(k.Parent.Name, k.Name)

	local m = a_findParents(k)
	for _, n in ipairs(m) do
		if n.Name == "ReplicatedStorage" then
			e.AntiCheat:FireServer("???", "using exploit.")
			Crash()
			return
		end
	end

	local o = k:FindFirstChild("Key")
	local p = e.GetKey:InvokeServer()

	if o and l then
		if o.Value ~= p then
			e.AntiCheat:FireServer(k.Name, "adding instance with wrong key - exploit.")
			Crash()
			return
		end
	elseif k.Name == "Key" then
		if k.Value and k.Value ~= p then
			e.AntiCheat:FireServer(k.Name, "adding instance with wrong key - exploit.")
			Crash()
			return
		end
	elseif not o and not l then
		e.AntiCheat:FireServer(k.Name, "adding instance with exploit.")
		Crash()
		return
	end
end)
