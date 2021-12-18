--[[
	NPC Controller:

	Check server side for documentation [Sorry, not sorry for any exploiter snooping...]
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Handler = {}

local Player = Players.LocalPlayer

local Cache = {}
local Remotes, NPCRemote, DamageSound
local Initialized = false
local NPCRange = 20

function RegisterNPC(NPC)
	if not NPC:IsDescendantOf(workspace) then return end
	if not Cache[NPC] then
		Cache[NPC] = {
			Active = true,
			Object = NPC,
			Humanoid = NPC:FindFirstChild("Humanoid"),
			Animator = Instance.new("Animation"),
			AnimationTrakcs = {},
			Target = nil,
			Exe = function(self)
				task.spawn(function()
					self.Humanoid = self.Humanoid or self.Object:WaitForChild("Humanoid")
					if not self.Humanoid then
						return
					end

					self.Animator.AnimationId = "rbxassetid://8257390581"
					self.AnimationTrakcs["Damaged"] = self.Humanoid.Animator:LoadAnimation(Cache[NPC].Animator)

					self.Animator.AnimationId = "rbxassetid://913376220"
					self.AnimationTrakcs["Run"] = self.Humanoid.Animator:LoadAnimation(Cache[NPC].Animator)
					self.Running = self.Humanoid.Running:Connect(function(Speed)
						if not self.AnimationTrakcs["Run"] then return end
						if Speed > 0 then
							if not self.AnimationTrakcs["Run"].IsPlaying then
								self.AnimationTrakcs["Run"]:Play()
							end
						else
							self.AnimationTrakcs["Run"]:Stop()
						end
					end)
					while self and self.Active do
						local Target = self.Object:GetAttribute("Target")
						local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
						local DistBetween = HRP and self.Object.PrimaryPart and (HRP.Position - self.Object.PrimaryPart.Position).Magnitude
						
						if not Target or Target == 0 then
							if DistBetween and DistBetween <= NPCRange then
								NPCRemote:FireServer(self.Object)
								task.wait()
								continue
							end
						elseif Target and Target == Player.UserId then
							if DistBetween and DistBetween <= 5 then
								task.wait(1)
								continue
							end
							self.Humanoid:MoveTo(HRP.Position - Vector3.new(0,0,5))
							task.wait(0.1)
						end
						task.wait()
					end
				end)
			end
		}
		Cache[NPC].Animator.Parent = NPC.PrimaryPart
		Cache[NPC]:Exe()
	end
end

function HandlePlayerCharacter(Char)
	task.spawn(function()
		local Humanoid = Char:WaitForChild("Humanoid")
		if not Humanoid then return end
		DamageSound = Instance.new("Sound")
		DamageSound.SoundId = "rbxassetid://4958430221"
		DamageSound.Parent = Char.HumanoidRootPart
		local LastHit = 0
		Humanoid.Touched:Connect(function(Obj)
			local Target = Obj.Parent
			if Player:GetAttribute("Punching") and CollectionService:HasTag(Target, "NPC") and Cache[Target] and Cache[Target].Active then
				if os.time() - LastHit <= 0.15 then return end
				LastHit = os.time()
				if Cache[Target].AnimationTrakcs["Damaged"] and not Cache[Target].AnimationTrakcs["Damaged"].IsPlaying then
					Cache[Target].AnimationTrakcs["Damaged"]:Play()
					DamageSound:Play()
				end
			end
		end)
	end)
end

function Handler:init(_, _)
	if Initialized then return end
	Initialized = true

	Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	NPCRemote = Remotes:WaitForChild("NPC")

	CollectionService:GetInstanceAddedSignal("NPC"):Connect(RegisterNPC)

	CollectionService:GetInstanceRemovedSignal("NPC"):Connect(function(NPC)
		if Cache[NPC] then
			Cache[NPC].Active = false
			if Cache[NPC].Running then
				Cache[NPC].Running:Disconnect()
			end
			Cache[NPC] = nil
		end
	end)

	Player.CharacterAdded:Connect(HandlePlayerCharacter)

	for _, ExistingNPC in ipairs(CollectionService:GetTagged("NPC")) do
		RegisterNPC(ExistingNPC)
	end

	if Player.Character then
		HandlePlayerCharacter(Player.Character)
	end
end

return Handler