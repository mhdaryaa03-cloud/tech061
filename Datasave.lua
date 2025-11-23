-----------------------------------------------------
-- 🔥 SERVICES
-----------------------------------------------------
local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-----------------------------------------------------
-- 🔥 DETEKSI INSTAN SEBELUM APA PUN JALAN (LEGAL)
-----------------------------------------------------
local function fastExploitCheck()
	-- Deteksi environment executor → lapor ke server
	if identifyexecutor or getgenv or getrenv or getgc then
		return true
	end
	return false
end

if fastExploitCheck() then
	Replicated.AntiCheat:FireServer("InstantDetect", "Executor detected before load")
	-- Biar server yang ban/kick
	return
end

-----------------------------------------------------
-- 🟢 ROBLOX SYSTEM UI WHITELIST (SelfView, Menu, Emote, Musik, Avatar etc)
-----------------------------------------------------
local function isRobloxSystemInstance(inst)
	if not inst or not inst.Name then
		return false
	end

	local allowed = {
		-- SelfView / kamera
		["SelfView"] = true,
		["FaceAnimator"] = true,
		["CameraTracking"] = true,
		["VideoStreamer"] = true,

		-- Menu / UI Roblox
		["InGameMenu"] = true,
		["InGameMenuV3"] = true,
		["TopBar"] = true,
		["PlayerList"] = true,
		["PlayerListManager"] = true,
		["Backpack"] = true,
		["BackpackUI"] = true,
		["Chat"] = true,
		["ChatWindow"] = true,
		["BubbleChat"] = true,
		["NotificationScreenGui"] = true,
		["ContextActionGui"] = true,
		["EmotesMenu"] = true,
		["EmotesList"] = true,
		["AvatarEditorInGame"] = true,
		["AvatarEditor"] = true,
		["PurchasePrompt"] = true,
		["PromptUI"] = true,
		["RecordTab"] = true,
		["ReportDialog"] = true,
		["Leaderboard"] = true,

		-- Core Roblox GUI
		["RobloxGui"] = true,
		["CoreGui"] = true,
	}

	if allowed[inst.Name] then
		return true
	end
	if inst.Parent and allowed[inst.Parent.Name] then
		return true
	end

	-- Semua yang berada di dalam CoreGui = aman
	if inst:IsDescendantOf(game.CoreGui) then
		return true
	end

	-- Semua yang berada di dalam PlayerGui = UI pemain (aman)
	local lp = Players.LocalPlayer
	if lp then
		local pg = lp:FindFirstChild("PlayerGui")
		if pg and inst:IsDescendantOf(pg) then
			return true
		end
	end

	return false
end

-----------------------------------------------------
-- ✨ ORIGINAL CLIENT TAMPER DETECTION (LEGAL)
-----------------------------------------------------

local CheckFuncName = "Check"
local a = Replicated
local b = CheckFuncName

a[b].OnClientInvoke = function()
	local c = 1 + 1
	local d = c - 1
	return d == 1
end

local function getParents(node)
	local list = {}
	local parent = node.Parent
	while parent do
		table.insert(list, parent)
		parent = parent.Parent
	end
	return list
end

local CheckChild = Replicated:WaitForChild("CheckChildExists")

local ROBLOX_Whitelist = {
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
	"LanguageService",
}

local function isRobloxInternal(name)
	for _, j in ipairs(ROBLOX_Whitelist) do
		if name == j then
			return true
		end
	end
	return false
end

task.wait(1)

-----------------------------------------------------
-- MAIN DETECTOR (LEGAL – TANPA CRASH)
-----------------------------------------------------
game.DescendantAdded:Connect(function(inst)
	-- Whitelist semua UI sistem Roblox
	if isRobloxSystemInstance(inst) then
		return
	end

	-- Whitelist internal ROBLOX (statistik dll)
	if isRobloxInternal(inst.Name) then
		return
	end

	-- Server check
	local parentName = inst.Parent and inst.Parent.Name or "nil"
	local existsOnServer = false

	local ok, err = pcall(function()
		existsOnServer = CheckChild:InvokeServer(parentName, inst.Name)
	end)
	if not ok then
		warn("[AntiCheatClient] CheckChildExists error:", err)
	end

	-- Kalau ada di dalam ReplicatedStorage → sangat mencurigakan
	local parents = getParents(inst)
	for _, p in ipairs(parents) do
		if p.Name == "ReplicatedStorage" then
			Replicated.AntiCheat:FireServer("ReplicatedStorageInject", "using exploit.")
			return
		end
	end

	-- Key validation
	local key = inst:FindFirstChild("Key")
	local correctKey

	local ok2, err2 = pcall(function()
		correctKey = Replicated.GetKey:InvokeServer()
	end)
	if not ok2 then
		warn("[AntiCheatClient] GetKey error:", err2)
		return
	end

	if key and existsOnServer then
		if key.Value ~= correctKey then
			Replicated.AntiCheat:FireServer(inst.Name, "wrong key - exploit")
			return
		end
	elseif inst.Name == "Key" then
		if inst.Value ~= correctKey then
			Replicated.AntiCheat:FireServer(inst.Name, "key override - exploit")
			return
		end
	elseif not key and not existsOnServer then
		Replicated.AntiCheat:FireServer(inst.Name, "adding instance with exploit")
		return
	end
end)
