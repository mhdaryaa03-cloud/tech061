-----------------------------------------------------
-- 🔥 SERVICES
-----------------------------------------------------
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-----------------------------------------------------
-- 🔥 DETEKSI INSTAN SEBELUM APA PUN JALAN (LEGAL)
-----------------------------------------------------
local function fastExploitCheck()
	-- Solara mem-block identifyexecutor/getgenv,
	-- Tapi dia tetap expose gethui() dan getconnections()
	local global = getfenv(0)

	if global.gethui then
		return true
	end
	if global.getconnections then
		return true
	end

	return false
end

if fastExploitCheck() then
	Replicated.AntiCheat:FireServer("InstantDetect", "Executor detected before load")
	return
end

-----------------------------------------------------
-- 🟢 ROBLOX UI WHITELIST YANG BENAR (Tidak terlalu luas)
-----------------------------------------------------
local function isRobloxSystemInstance(inst)
	if not inst then return false end

	local allowedNames = {
		["SelfView"] = true,
		["FaceAnimator"] = true,
		["CameraTracking"] = true,
		["VideoStreamer"] = true,

		["InGameMenu"] = true,
		["InGameMenuV3"] = true,
		["TopBar"] = true,
		["PlayerList"] = true,
		["Backpack"] = true,
		["ChatWindow"] = true,
		["BubbleChat"] = true,
		["NotificationScreenGui"] = true,
		["ContextActionGui"] = true,
		["EmotesMenu"] = true,
		["AvatarEditorInGame"] = true,
		["PurchasePrompt"] = true,
		["PromptUI"] = true,
		["Leaderboard"] = true,

		["RobloxGui"] = true,
		["CoreGui"] = true,
	}

	-- Nama sesuai whitelist
	if allowedNames[inst.Name] then
		return true
	end

	-- WHITELIST HANYA UI ROBLOX (BUKAN SEMUA)
	-- TAPI *TIDAK* whitelist seluruh CoreGui/PlayerGui
	local parent = inst.Parent
	if parent and allowedNames[parent.Name] then
		return true
	end

	return false
end

-----------------------------------------------------
-- ✨ INTERNAL ROBLOX WHITELIST (Statistik)
-----------------------------------------------------
local ROBLOX_Internal = {
	"FrameRateManager",
	"DeviceFeatureLevel",
	"DeviceShadingLanguage",
	"AverageQualityLevel",
	"AutoQuality",
	"VideoMemoryInMB",
	"Memory",
	"Render",
}

local function isRobloxInternal(name)
	for _, v in ipairs(ROBLOX_Internal) do
		if name == v then return true end
	end
	return false
end

-----------------------------------------------------
-- 🔎 GET PARENTS
-----------------------------------------------------
local function getParents(inst)
	local list = {}
	local p = inst.Parent
	while p do
		table.insert(list, p)
		p = p.Parent
	end
	return list
end

local CheckChild = Replicated:WaitForChild("CheckChildExists")

task.wait(1)

-----------------------------------------------------
-- 🔥 DESCENDANT ADDED DETECTOR
-----------------------------------------------------
game.DescendantAdded:Connect(function(inst)

	-- Whitelist UI Roblox
	if isRobloxSystemInstance(inst) then
		return
	end

	-- Whitelist internal statistik Roblox
	if isRobloxInternal(inst.Name) then
		return
	end

	-- Jika berada di ReplicatedStorage → exploit hampir pasti
	for _, p in ipairs(getParents(inst)) do
		if p.Name == "ReplicatedStorage" then
			Replicated.AntiCheat:FireServer("ReplicatedInject", inst.Name)
			return
		end
	end

	-- Key validation
	local existsOnServer = false
	local ok = pcall(function()
		existsOnServer = CheckChild:InvokeServer(inst.Parent.Name, inst.Name)
	end)

	local key = inst:FindFirstChild("Key")
	local correctKey = nil
	pcall(function()
		correctKey = Replicated.GetKey:InvokeServer()
	end)

	if key and existsOnServer then
		if key.Value ~= correctKey then
			Replicated.AntiCheat:FireServer("WrongKey", inst.Name)
			return
		end
	elseif not key and not existsOnServer then
		Replicated.AntiCheat:FireServer("InjectedInstance", inst.Name)
		return
	end
end)
