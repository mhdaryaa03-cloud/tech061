-----------------------------------------------------
-- SERVICES
-----------------------------------------------------
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CheckChild = Replicated:WaitForChild("CheckChildExists")
local AntiCheat = Replicated:WaitForChild("AntiCheat")
local GetKey = Replicated:WaitForChild("GetKey") -- sekarang dipakai hanya kalau perlu nanti

-----------------------------------------------------
-- FAST DETECTION (Executor API exposure)
-----------------------------------------------------
local function fastExploitCheck()
	local ok, env = pcall(getfenv, 0)
	if not ok or type(env) ~= "table" then
		return false
	end

	-- API umum executor
	if env.identifyexecutor then return true end
	if env.getgenv then return true end
	if env.getconnections then return true end
	if env.getloadedmodules then return true end
	if env.gethui then return true end

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

	-- ROOT
	["CoreGui"] = true,
	["RobloxGui"] = true,
}

local function isWhitelistedCoreGui(inst)
	if not CoreGui then return false end

	local p = inst
	while p and p ~= CoreGui and p ~= game do
		if RobloxSystemWhitelist[p.Name] then
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

	if not inst:IsDescendantOf(CoreGui) then
		return
	end

	if isWhitelistedCoreGui(inst) then
		return
	end

	local fullName
	pcall(function()
		fullName = inst:GetFullName()
	end)

	fullName = fullName or tostring(inst)

	AntiCheat:FireServer("CoreGuiInjected", fullName)
end

if CoreGui then
	for _, inst in ipairs(CoreGui:GetDescendants()) do
		handleCoreGuiInstance(inst)
	end

	CoreGui.DescendantAdded:Connect(function(inst)
		handleCoreGuiInstance(inst)
	end)
end

-----------------------------------------------------
-- DETEKSI INJECTION LANGSUNG KE REPLICATEDSTORAGE
-----------------------------------------------------
local function isSuspiciousReplicatedChild(inst)
	if inst.Parent ~= Replicated then
		return false
	end

	local name = inst.Name

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

for _, child in ipairs(Replicated:GetChildren()) do
	handleReplicatedChild(child)
end

Replicated.DescendantAdded:Connect(function(inst)
	handleReplicatedChild(inst)
end)

-----------------------------------------------------
-- CATATAN:
-- Fokus:
-- 1) Deteksi UI executor di CoreGui (selain UI Roblox)
-- 2) Deteksi object aneh yang langsung muncul di ReplicatedStorage
-- Tanpa spam WrongKey/InjectedInstance ke seluruh Workspace.
-----------------------------------------------------
