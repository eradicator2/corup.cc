local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local mRemote = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("XMHH.2")
local serverTick = game:GetService("ReplicatedStorage"):WaitForChild("Values"):WaitForChild("ServerTick")
local isBlocking, blockCache = false, {}
local lastTrigger = 0

game:GetService("RunService").Heartbeat:Connect(function()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local tool = char and char:FindFirstChildOfClass("Tool")
	
	if not tool or not hrp then
		if isBlocking then 
			mRemote:InvokeServer("🍞", math.floor(serverTick.Value - 81919), currentTool, "BZLZSTI2")
			isBlocking = false 
		end
		return
	end

	if blockCache[tool] == nil then
		local can = false
		pcall(function()
			local cfg = require(tool:FindFirstChild("Config"))
			if cfg.BlockSettings and cfg.BlockSettings.Enabled then can = true end
		end)
		if not can and tool:FindFirstChild("AnimsFolder") and tool.AnimsFolder:FindFirstChild("BlockStart") then can = true end
		if tool:GetAttribute("CanBlock") == false then can = false end
		blockCache[tool] = can
	end

	if not blockCache[tool] then
		if isBlocking then
			mRemote:InvokeServer("🍞", math.floor(serverTick.Value - 81919), tool, "BZLZSTI2")
			isBlocking = false
		end
		return
	end

	local shouldBlock = false
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local eHrp = p.Character.HumanoidRootPart
			if (eHrp.Position - hrp.Position).Magnitude <= 15 then
				local eTool = p.Character:FindFirstChildOfClass("Tool")
				if eTool and not (eTool:GetAttribute("Unblockable") or eTool:GetAttribute("IgnoreBlock")) then
					local attacking = false
					local v = eTool:FindFirstChild("Values")
					if v then
						if (v:FindFirstChild("Slashing1") and v.Slashing1.Value) or (v:FindFirstChild("Attacking") and v.Attacking.Value) then
							attacking = true
						else
							for _, val in ipairs(v:GetChildren()) do
								if val.Name:find("Slashing") and val.Value == true then attacking = true break end
							end
						end
					end
					if not attacking then
						local h = p.Character:FindFirstChildOfClass("Humanoid")
						if h then
							for _, t in ipairs(h:GetPlayingAnimationTracks()) do
								local n = t.Name:lower()
								if n:find("slash") or n:find("swing") or n:find("attack") or n:find("lunge") or n:find("heavy") then
									attacking = true
									break
								end
							end
						end
					end
					if attacking then shouldBlock = true break end
				end
			end
		end
	end

	if shouldBlock then
		lastTrigger = tick()
		if not isBlocking then
			isBlocking = true
			task.spawn(function()
				while isBlocking and char and tool.Parent == char do
					mRemote:InvokeServer("🍞", math.floor(serverTick.Value - 81919), tool, "BLSTAX1")
					task.wait(0.1)
					if tick() - lastTrigger > 0.2 then break end
				end
				isBlocking = false
			end)
		end
	elseif isBlocking and tick() - lastTrigger > 0.2 then
		isBlocking = false
		mRemote:InvokeServer("🍞", math.floor(serverTick.Value - 81919), tool, "BZLZSTI2")
	end
end)
