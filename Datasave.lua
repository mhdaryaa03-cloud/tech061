-----------------------------------------------------
-- 🔥 SERVICES
-----------------------------------------------------
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CheckChild = Replicated:WaitForChild("CheckChildExists")
local AntiCheat = Replicated:WaitForChild("AntiCheat")
local GetKey = Replicated:WaitForChild("GetKey")

-----------------------------------------------------
-- 🔥 FAST EXECUTOR FINGERPRINT (AMAN)
-----------------------------------------------------
local function fastExploitCheck()
	-- cek beberapa API khas executor; player normal biasanya tidak punya ini
	local env = getfenv and getfenv(0) or _G

	if env.identifyexecutor
		or env.gethui
		or env.getgenv
		or env.getrenv
		or env.getgc
		or env.getloadedmodules
	then
		AntiCheat:FireServer("FastDetect", "Executor environment detected (global API)")
		return true
	end

	return false
end

-- kalau ketahuan dari awal, langsung lapor ke server. Biar server yang ban/kick.
if fastExploitCheck() then
	return
end

-----------------------------------------------------
-- 🟢 WHITELIST UI / SISTEM ROBLOX (CLIENT)
-----------------------------------------------------
local allowedNames = {
	-- kamera / self view
	SelfView = true,
	FaceAnimator = true,
	CameraTracking = true,
	VideoStreamer = true,

	-- menu utama Roblox
	RobloxGui = true,
	InGameMenu = true,
	InGameMenuV3 = true,
	InGameMenuV4 = true,
	MenuIcon = true,
	TopBar = true,
	TopBarApp = true,
	PlayerList = true,
	PlayerListManager = true,

	-- chat & notifikasi
	Chat = true,
	ChatWindow = true,
	BubbleChat = true,
	NotificationScreenGui = true,

	-- control & context
	ContextActionGui = true,
	ControlFrame = true,

	-- emote / avatar / inventory / music
	EmotesMenu = true,
	EmotesList = true,
	AvatarEditorInGame = true,
	AvatarEditor = true,
	Inventory = true,
	Music = true,
	Media = true,
	Party = true,

	-- lain-lain bawaan Roblox
	Backpack = true,
	BackpackUI = true,
	PurchasePrompt = true,
	PromptOverlay = true,
	PromptUI = true,
	Leaderboard = true,
	RecordTab = true,
	ReportDialog = true,
	CoreGui = true,
	PlayerGui = true,
}

local allowedAncestorNames = {
	RobloxGui = true,
	InGameMenu = true,
	InGameMenuV3 = true,
	InGameMenuV4 = true,
	SelfView = true,
	EmotesMenu = true,
	AvatarEditorInGame = true,
	Chat = true,
	TopBar = true,
	PlayerGui = true,
	CoreGui = true,
}

local function isRobloxSystemInstance(inst)
	if not inst or not inst.Name then
		return false
	end

	-- kalau namanya sendiri ada di whitelist → aman
	if allowedNames[inst.Name] then
		return true
	end

	-- kalau salah satu ancestor-nya UI Roblox → aman
	local parent = inst.Parent
	while parent do
		if allowedAncestorNames[parent.Name] then
			return true
		end
		parent = parent.Parent
	end

	return false
end

-----------------------------------------------------
-- 🟢 BANTUAN: ROOT DI BAWAH game (Workspace / Replicated, dll.)
-----------------------------------------------------
local function getRootUnderGame(inst)
	local current = inst
	local last = inst

	while current and current.Parent do
		last = current
		if current.Parent == game then
			break
		end
		current = current.Parent
	end

	return last or inst
end

-----------------------------------------------------
-- 🟢 CEK KEY & KEANEHAN INSTANCE
-----------------------------------------------------
local function checkInstance(inst)
	if not inst or not inst.Parent then
		return
	end

	-- Abaikan semua UI / sistem Roblox
	if isRobloxSystemInstance(inst) then
		return
	end

	-- Hanya peduli object yang terhubung ke Workspace / ReplicatedStorage (wilayah server)
	local root = getRootUnderGame(inst)
	if root ~= workspace and root ~= Replicated then
		-- artinya ini di area lain (misal PlayerGui) → jangan dianggap exploit
		return
	end

	-- Ambil key server saat ini
	local okKey, correctKey = pcall(function()
		return GetKey:InvokeServer()
	end)

	if not okKey or not correctKey then
		return
	end

	-- Cek apakah object punya "Key"
	local key = inst:FindFirstChild("Key")

	-------------------------------------------------
	-- 1) Object ada di Workspace/Replicated TAPI tidak punya Key → sangat mencurigakan
	-------------------------------------------------
	if not key then
		-- Supaya tidak false positive untuk object baru dari server,
		-- tanya dulu ke server: object ini seharusnya ada atau tidak?
		local existsOnServer = false

		local okCheck, result = pcall(function()
			-- kita kirim nama parent langsung, sama seperti server script-mu
			local parent = inst.Parent
			if parent and parent.Name then
				return CheckChild:InvokeServer(parent.Name, inst.Name)
			end
			return false
		end)

		if okCheck then
			existsOnServer = result
		end

		-- Kalau server bilang TIDAK ADA dan tidak UI Roblox → kemungkinan besar exploit
		if not existsOnServer then
			AntiCheat:FireServer("InjectedInstance_NoKey", inst:GetFullName())
		end

		return
	end

	-------------------------------------------------
	-- 2) Punya Key tetapi nilainya salah → exploit ubah Key
	-------------------------------------------------
	if key.Value ~= correctKey then
		AntiCheat:FireServer("WrongKey", inst:GetFullName())
		return
	end
end

-----------------------------------------------------
-- 🟢 DELAY KECIL UNTUK INSTANCE BARU
-----------------------------------------------------
local function scheduleCheck(inst)
	-- sedikit delay supaya server sempat menempelkan Key dulu
	task.delay(0.3, function()
		-- Pastikan instance masih ada
		if inst.Parent then
			checkInstance(inst)
		end
	end)
end

-----------------------------------------------------
-- MAIN DETECTOR (AMAN, TANPA CRASH)
-----------------------------------------------------
game.DescendantAdded:Connect(function(inst)
	scheduleCheck(inst)
end)

-- Cek ulang semua object yang sudah ada saat script load
for _, inst in ipairs(game:GetDescendants()) do
	scheduleCheck(inst)
end
