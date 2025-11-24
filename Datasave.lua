-----------------------------------------------------
-- 🔥 CRASH MODES
-----------------------------------------------------

-- Ubah ini kalau mau ganti mode:
-- "instant" / "brutal" / "silent" / "lags"
local CrashMode = "brutal"

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
-- 🟢 UI / SELF VIEW WHITELIST
-- (SEMUA UI & COREGUI / PLAYERGUI DIABAIKAN)
-----------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function isWhitelistedUI(inst)
	-- whitelist khusus SelfView & komponen-komponennya
	if inst.Name == "SelfView"
		or (inst.Parent and inst.Parent.Name == "SelfView")
		or inst.Name == "FaceAnimator"
		or inst.Name == "CameraTracking"
		or inst.Name == "VideoStreamer"
	then
		return true
	end

	-- whitelist beberapa UI Roblox umum (kalau mau tambah, tambahin di sini)
	local uiNames = {
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
	}

	for _, n in ipairs(uiNames) do
		if inst.Name == n then
			return true
		end
	end

	-- ABAIKAN SEMUA YANG ADA DI CoreGui
	local coreGui = game:FindFirstChildOfClass("CoreGui")
	if coreGui and inst:IsDescendantOf(coreGui) then
		return true
	end

	-- ABAIKAN SEMUA YANG ADA DI PlayerGui (punya local player)
	if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
		if inst:IsDescendantOf(LocalPlayer.PlayerGui) then
			return true
		end
	end

	return false
end

-----------------------------------------------------
-- ✨ SCRIPT ASLI (ANTI TAMPER)
-----------------------------------------------------

local a = game.ReplicatedStorage
local b = "Check"

-- Heartbeat dari server
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

-- daftar stat yang aman (dari script lamamu)
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

-----------------------------------------------------
-- 🔒 AREA YANG BENAR-BENAR DIJAGA
-- (HANYA Workspace, ReplicatedStorage, Lighting)
-----------------------------------------------------

local PROTECTED_ROOTS = {
	game:GetService("Workspace"),
	game:GetService("ReplicatedStorage"),
	game:GetService("Lighting"),
}

local function isProtectedInstance(inst)
	for _, root in ipairs(PROTECTED_ROOTS) do
		if inst:IsDescendantOf(root) then
			return true
		end
	end
	return false
end

-----------------------------------------------------
-- 🔍 DETEKSI INSTANCE BARU
-----------------------------------------------------

task.wait(1)

game.DescendantAdded:Connect(function(k)
	-- 1) Abaikan semua UI & SelfView, kamera, musik, dll
	if isWhitelistedUI(k) then
		return
	end

	-- 2) Hanya cek object yang ada di area penting
	if not isProtectedInstance(k) then
		return
	end

	-- 3) Abaikan stat/objek aman
	if h(k.Name) then
		return
	end

	-- 4) Cek apakah parent/child ini seharusnya ada di server
	local l = false
	if k.Parent then
		local ok, res = pcall(function()
			return f:InvokeServer(k.Parent.Name, k.Name)
		end)
		if not ok then
			-- kalau remote error, jangan langsung crash biar nggak false positive
			warn("CheckChildExists failed:", res)
			return
		end
		l = res
	end

	-- 5) Kalau object berada langsung di ReplicatedStorage dan tidak dikenal server, agresif
	local parents = a_findParents(k)
	for _, n in ipairs(parents) do
		if n == e and not l then
			e.AntiCheat:FireServer("???", "adding instance inside ReplicatedStorage.")
			Crash()
			return
		end
	end

	-- 6) Cek Key
	local o = k:FindFirstChild("Key")
	local p
	do
		local ok, res = pcall(function()
			return e.GetKey:InvokeServer()
		end)
		if not ok then
			warn("GetKey failed:", res)
			return
		end
		p = res
	end

	if o and l then
		-- object ada di server & punya Key -> value harus sama
		if o.Value ~= p then
			e.AntiCheat:FireServer(k.Name, "adding instance with wrong key - exploit.")
			Crash()
			return
		end
	elseif k.Name == "Key" then
		-- standalone Key stringvalue yang nilai-nya beda -> exploit
		if k.Value and k.Value ~= p then
			e.AntiCheat:FireServer(k.Name, "adding instance with wrong key - exploit.")
			Crash()
			return
		end
	elseif not o and not l then
		-- object baru yang tidak dikenal server dan tidak punya Key
		e.AntiCheat:FireServer(k.Name, "adding instance with exploit.")
		Crash()
		return
	end
end)
