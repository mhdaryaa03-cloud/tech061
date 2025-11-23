-----------------------------------------------------
-- SERVICES
-----------------------------------------------------
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local CheckChild = Replicated:WaitForChild("CheckChildExists")
local AntiCheat = Replicated:WaitForChild("AntiCheat")
local GetKey = Replicated:WaitForChild("GetKey")

-----------------------------------------------------
-- FAST EXECUTOR SIGNATURE DETECTION
-----------------------------------------------------
local function fastExploitCheck()
	local ok, env = pcall(getfenv, 0)
	if not ok or type(env) ~= "table" then return false end

	if env.identifyexecutor then return true end
	if env.getgenv then return true end
	if env.getconnections then return true end
	if env.getloadedmodules then return true end
	if env.gethui then return true end

	return false
end

if fastExploitCheck() then
	AntiCheat:FireServer("InstantDetect", "Executor signature detected BEFORE load")
	return
end


-----------------------------------------------------
-- COREGUI DETECTOR (UI EXECUTOR)
-----------------------------------------------------
local CoreGui
pcall(function()
	CoreGui = game:GetService("CoreGui")
end)


-----------------------------------------------------
-- ROBLOX SYSTEM UI WHITELIST
-----------------------------------------------------
local RobloxSystemWhitelist = {

	-- Core Roblox UI
	["RobloxGui"] = true,
	["CoreGui"] = true,

	-- Chat System
	["Chat"] = true,
	["ChatWindow"] = true,
	["BubbleChat"] = true,

	-- TopBar / Menu
	["TopBar"] = true,
	["PlayerList"] = true,
	["PlayerListManager"] = true,
	["InGameMenu"] = true,
	["InGameMenuV3"] = true,

	-- SafeView / Camera Systems
	["SelfView"] = true,
	["FaceAnimator"] = true,
	["CameraTracking"] = true,
	["VideoStreamer"] = true,

	-- Avatar Editor
	["AvatarEditor"] = true,
	["AvatarEditorInGame"] = true,
	["AvatarEditorPrompts"] = true,
	["AvatarEditorPrompt"] = true,

	-- Emotes
	["EmotesMenu"] = true,
	["EmotesList"] = true,

	-- Prompts
	["PromptUI"] = true,
	["PurchasePrompt"] = true,

	-- Notifications
	["NotificationScreenGui"] = true,

	-- Tools / Backpack
	["Backpack"] = true,
	["BackpackUI"] = true,
}


local function isCoreGuiWhitelisted(inst)
	local p = inst
	while p and p ~= game do
		if RobloxSystemWhitelist[p.Name] then
			return true
		end
		p = p.Parent
	end
	return false
end


-----------------------------------------------------
-- DETEKSI UI EXECUTOR
-----------------------------------------------------
local function detectExecutorUI(inst)
	if not CoreGui then return end

	if not inst:IsDescendantOf(CoreGui) then
		return
	end

	if isCoreGuiWhitelisted(inst) then
		return
	end

	local name = inst:GetFullName()
	AntiCheat:FireServer("CoreGuiInjected", name)
end


if CoreGui then
	for _, v in ipairs(CoreGui:GetDescendants()) do
		detectExecutorUI(v)
	end

	CoreGui.DescendantAdded:Connect(detectExecutorUI)
end


-----------------------------------------------------
-- OPTIONAL CHECK: EXPLOIT INJECT REPLICATED STORAGE
-----------------------------------------------------
local function isReplicatedSuspicious(inst)
	if inst.Parent ~= Replicated then
		return false
	end

	local n = inst.Name

	-- whitelist file game kamu
	if n == "AntiCheat"
		or n == "CheckChildExists"
		or n == "GetKey"
		or n == "Loadstring"
		or n == "PlayerAdded"
		or n == "Check" then
		return false
	end

	return true
end


local function handleReplicatedInjection(inst)
	if not isReplicatedSuspicious(inst) then return end

	local exists = false

	pcall(function()
		exists = CheckChild:InvokeServer("ReplicatedStorage", inst.Name)
	end)

	if not exists then
		AntiCheat:FireServer("InjectedIntoReplicated", inst:GetFullName())
	end
end

for _, v in ipairs(Replicated:GetChildren()) do
	handleReplicatedInjection(v)
end

Replicated.DescendantAdded:Connect(handleReplicatedInjection)
