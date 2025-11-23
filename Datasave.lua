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
-- FAST DETECTION (Executor API exposure)
-----------------------------------------------------
local function fastExploitCheck()
	local g = getfenv(0)

	if g.identifyexecutor then return true end
	if g.getgenv then return true end
	if g.getconnections then return true end
	if g.getloadedmodules then return true end

	return false
end

if fastExploitCheck() then
	AntiCheat:FireServer("InstantDetect", "Executor signature detected")
	return
end

-----------------------------------------------------
-- WHITELIST
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
-- SAFE: Detector hanya bekerja untuk item DI DALAM
-- ReplicatedStorage > scripts buatan player
-----------------------------------------------------
local function isSuspicious(inst)
	-- bukan UI
	if isRobloxUI(inst) then return false end

	-- karakter player aman
	if inst:IsDescendantOf(LocalPlayer.Character) then return false end

	-- playergui aman
	if inst:IsDescendantOf(LocalPlayer:WaitForChild("PlayerGui")) then return false end

	-- hanya detect item yang ditempatkan LANGSUNG oleh exploit
	if inst.Parent == Replicated then
		return true
	end

	return false
end

-----------------------------------------------------
-- MAIN DETECTION (HANYA DETECT YANG BENAR-BENAR JANGGAL)
-----------------------------------------------------
game.DescendantAdded:Connect(function(inst)

	-- whitelist UI
	if isRobloxUI(inst) then return end

	-- kalau bukan suspicious → skip
	if not isSuspicious(inst) then return end

	-- KEY VALIDATION
	local existsOnServer = false
	pcall(function()
		existsOnServer = CheckChild:InvokeServer(inst.Parent.Name, inst.Name)
	end)

	local key = inst:FindFirstChild("Key")
	local correctKey

	pcall(function()
		correctKey = GetKey:InvokeServer()
	end)

	-- valid kalau instance benar-benar milik server
	if existsOnServer then
		if key and key.Value == correctKey then
			return
		else
			AntiCheat:FireServer("WrongKey", inst:GetFullName())
			return
		end
	end

	-- selain itu = injected object
	AntiCheat:FireServer("InjectedInstance", inst:GetFullName())
end)
