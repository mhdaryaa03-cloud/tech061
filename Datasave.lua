-----------------------------------------------------
-- SERVICES
-----------------------------------------------------
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local CheckChild = Replicated:WaitForChild("CheckChildExists")
local AntiCheat = Replicated:WaitForChild("AntiCheat")
local GetKey = Replicated:WaitForChild("GetKey")

-----------------------------------------------------
-- FAST DETECTION (Executor API exposure)
-----------------------------------------------------
local function fastExploitCheck()
	-- sebagian besar executor naruh API di global env script mereka sendiri,
	-- tapi kalau ada yang bocor ke env kita, langsung ke-detect
	local ok, env = pcall(getfenv, 0)
	if not ok or type(env) ~= "table" then
		return false
	end

	if env.identifyexecutor then return true end
	if env.getgenv then return true end
	if env.getconnections then return true end
	if env.getloadedmodules then return true end

	return false
end

if fastExploitCheck() then
	AntiCheat:FireServer("InstantDetect", "Executor signature detected (global env)")
	return
end

-----------------------------------------------------
-- CORE GUI SERVICE (TEMPAT UI EXECUTOR BIASA NANGKRING)
-----------------------------------------------------
local CoreGui
pcall(function()
	CoreGui = game:GetService("CoreGui")
end)

-----------------------------------------------------
-- WHITELIST UI ROBLOX DI COREGUI
-- (BIAR SELF VIEW, MENU, CHAT, DLL NGGAK KEDETECT)
-----------------------------------------------------
local RobloxSystemWhitelist = {
    -- SELF VIEW SISTEM
    ["SelfView"] = true,
    ["FaceAnimator"] = true,
    ["CameraTracking"] = true,
    ["VideoStreamer"] = true,

    -- UI MENU / CORE PACKAGES
    ["InGameMenu"] = true,
    ["InGameMenuV3"] = true,
    ["MenuIcon"] = true,
    ["TopBar"] = true,
    ["PlayerList"] = true,
    ["PlayerListManager"] = true,
    ["Chat"] = true,
    ["ChatWindow"] = true,
    ["BubbleChat"] = true,

    -- AVATAR EDITOR
    ["AvatarEditor"] = true,
    ["AvatarEditorInGame"] = true,
    ["AvatarEditorPrompts"] = true,
    ["AvatarEditorPrompt"] = true,

    -- PURCHASE UI
    ["PurchasePrompt"] = true,
    ["PromptUI"] = true,

    -- REPORT / SETTINGS
    ["ReportDialog"] = true,
    ["SettingsHub"] = true,

    -- EMOTES
    ["EmotesMenu"] = true,
    ["EmotesList"] = true,

    -- NOTIFICATIONS
    ["NotificationScreenGui"] = true,

    -- BACKPACK / TOOLBAR
    ["Backpack"] = true,
    ["BackpackUI"] = true,

    -- Query hanya CoreGui
    ["CoreGui"] = true,
    ["RobloxGui"] = true,

}

local function isWhitelistedCoreGui(inst)
	if not CoreGui then return false end

	local p = inst
	while p and p ~= CoreGui and p ~= game do
		if CoreGuiWhitelist[p.Name] then
			return true
		end
		p = p.Parent
	end

	return false
end

-----------------------------------------------------
-- DETEKSI UI EXECUTOR DI COREGUI
-----------------------------------------------------
local function handleCoreGuiInstance(inst)
	if not CoreGui then return end

	-- hanya peduli kalau benar2 di bawah CoreGui
	if not inst:IsDescendantOf(CoreGui) then
		return
	end

	-- kalau bagian dari UI roblox → aman
	if isWhitelistedCoreGui(inst) then
		return
	end

	-- kadang executor bikin ScreenGui/Frame/Button custom
	-- nama aneh2 / gak ada di whitelist → kita anggap mencurigakan
	local fullName
	pcall(function()
		fullName = inst:GetFullName()
	end)

	fullName = fullName or tostring(inst)

	AntiCheat:FireServer("CoreGuiInjected", fullName)
end

-- scan awal: kalau executor inject UI SEBELUM script ini jalan
if CoreGui then
	for _, inst in ipairs(CoreGui:GetDescendants()) do
		handleCoreGuiInstance(inst)
	end

	-- listen kalau ada yang nambah ke CoreGui (setelah game jalan)
	CoreGui.DescendantAdded:Connect(function(inst)
		handleCoreGuiInstance(inst)
	end)
end

-----------------------------------------------------
-- OPTIONAL: DETEKSI INJECTION LANGSUNG KE REPLICATEDSTORAGE
-- (tanpa sentuh Key system, biar nggak flood)
-----------------------------------------------------
local function isSuspiciousReplicatedChild(inst)
	-- hanya cek anak langsung ReplicatedStorage,
	-- karena child lain di dalam folder game kamu bisa apa saja
	if inst.Parent ~= Replicated then
		return false
	end

	-- remote / folder bawaan game kamu bisa di-whitelist manual kalau mau
	local name = inst.Name

	-- contoh whitelist minimal:
	if name == "AntiCheat"
		or name == "CheckChildExists"
		or name == "GetKey"
		or name == "Loadstring"
		or name == "PlayerAdded"
		or name == "Check" then
		return false
	end

	return true
end

local function handleReplicatedChild(inst)
	if not isSuspiciousReplicatedChild(inst) then
		return
	end

	-- tanya ke server: beneran ada object dengan nama ini di ReplicatedStorage server?
	local existsOnServer = false
	pcall(function()
		existsOnServer = CheckChild:InvokeServer("ReplicatedStorage", inst.Name)
	end)

	local fullName
	pcall(function()
		fullName = inst:GetFullName()
	end)
	fullName = fullName or tostring(inst)

	if not existsOnServer then
		AntiCheat:FireServer("InjectedIntoReplicated", fullName)
	end
end

-- cek anak awal di ReplicatedStorage
for _, child in ipairs(Replicated:GetChildren()) do
	handleReplicatedChild(child)
end

-- listen kalau ada yang inject ke ReplicatedStorage
Replicated.DescendantAdded:Connect(function(inst)
	handleReplicatedChild(inst)
end)

-----------------------------------------------------
-- CATATAN:
-- Di script client ini kita SENGAJA tidak pakai sistem Key
-- untuk Workspace / Character dsb supaya tidak auto ban semua object.
-- Fokus utama:
-- 1) UI executor di CoreGui
-- 2) Object aneh yang langsung muncul di ReplicatedStorage
-----------------------------------------------------
