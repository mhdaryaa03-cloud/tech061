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
-- FAST DETECTION (Solara exposes gethui)
-----------------------------------------------------
local function fastExploitCheck()
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
	AntiCheat:FireServer("InstantDetect", "Executor detected before load")
	return
end

-----------------------------------------------------
-- SAFE WHITELIST (tanpa akses CoreGui)
-----------------------------------------------------
local RobloxWhitelist = {
	["SelfView"] = true,
	["FaceAnimator"] = true,
	["CameraTracking"] = true,
	["VideoStreamer"] = true,

	["InGameMenu"] = true,
	["TopBar"] = true,
	["Chat"] = true,
	["EmotesMenu"] = true,
	["AvatarEditorInGame"] = true,
}

local function isRobloxUI(inst)
	if RobloxWhitelist[inst.Name] then
		return true
	end
	if inst.Parent and RobloxWhitelist[inst.Parent.Name] then
		return true
	end
	return false
end

-----------------------------------------------------
-- SAFE PARENT CHECK (Tanpa CoreGui)
-----------------------------------------------------
local function safeParentCheck(inst)
	local p = inst.Parent
	while p do
		if p == game or p == workspace then
			return false
		end

		if p.Name == "ReplicatedStorage" then
			return "Replicated"
		end

		if RobloxWhitelist[p.Name] then
			return "RobloxUI"
		end

		p = p.Parent
	end

	return false
end

-----------------------------------------------------
-- MAIN DETECTION (Tanpa CoreGui access)
-----------------------------------------------------
game.DescendantAdded:Connect(function(inst)
	
	if isRobloxUI(inst) then
		return
	end

	local parentType = safeParentCheck(inst)

	-- UI Roblox
	if parentType == "RobloxUI" then 
		return
	end

	-- Solara selalu inject sesuatu ke ReplicatedStorage
	if parentType == "Replicated" then
		AntiCheat:FireServer("InjectedIntoReplicated", inst.Name)
		return
	end

	-- Key validation
	local existsOnServer = false
	pcall(function()
		existsOnServer = CheckChild:InvokeServer(inst.Parent.Name, inst.Name)
	end)

	local key = inst:FindFirstChild("Key")
	local correctKey = nil

	pcall(function()
		correctKey = GetKey:InvokeServer()
	end)

	if key and existsOnServer then
		if key.Value ~= correctKey then
			AntiCheat:FireServer("WrongKey", inst.Name)
		end
		return
	end

	if not key and not existsOnServer then
		AntiCheat:FireServer("InjectedInstance", inst.Name)
		return
	end
end)
