--[[
	NPC Controller:

	Server Documentation:

	[*] Handler.Create() -> Returns [Dictionary]:
		- [Boolean] Active: If set to false the Executor loop will terminate which allows you to clean up the NPC
		- [Instance] Object: The NPC Model
		- [Instance] Humanoid: NPC's Humanoid
		- [Instance] Target: Player Instance that the NPC is targetting
		- [Instance] NPCRot: BodyGyro that rotates the NPC to face towards its target
		- [RBXScriptConnection] Running: Connection to the humanoid to track whether or not the NPC is moving, to enable and disable the bodygyro
		- [RBXScriptConnection] Touched: When touched it checks if the object is a player and if that player is punching it, if so it'll take damage based on the player's strength
		- [RBXScriptConnection] Died: When the NPC dies, this gives the target the NPC is after some cash reward
		- [Function] Exe: a Function with a loop to continously check the NPC's position based on its target, If too far away the NPC will stop chasing the player
		
	[*] Handler:init()

	Runs once on server load to initialize the module.

	Creates an NPCFolder to hold NPCs, and a Remote Event in ReplicatedStorage -> Remotes

	NPCRemote: Listens to any client requests to get NPCs to target the requestee, this validates the request by checking if the NPC does not yet have a target, 
	then it calculates the distance between the player and NPC (taking note of the player's ping) to make sure the player isn't calling it from across the world
	If all is valid this gives network ownership of the NPC to the requesting player.
	
	When an NPC's tag is removed (when the NPC dies) the module will disconnect all events and cleans up the NPC from cache

	When a player leaves it removes the player from any NPC that may have the player as its target

	# Known Caveats:
		- Anyone can damage the NPC but only the NPC's target player will receive the reward
	-----------------------------
	Client Documentation:
	Using CollectionService this module detects when new NPCs are added and registers them in the cache.
	Each NPC has an executor "thread" which handles playing the animations, running proximity checks, and moves the NPC should it need to be moved

	When an NPC gets hit it will play a damaged animation on the client and validates it on the server.

	When an player gets within range of the NPC and it is not targetting anyone already, it will notify the server
	Once the server validates the request, the server will give the player network ownership
	The client handles following its target and playing the appropriate animations meanwhile the server
	continously validates what the NPC is doing
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Handler = {}

local Cache = {}
local Service, NPCFolder, NPCRemote
local Initialized = false
local NPCRange = 20 -- NPCs can detect players within this range

function Handler.Create()
	local ModelSuccess, NPC = pcall(function()
		return Players:CreateHumanoidModelFromUserId(10380653)
	end)

	if not ModelSuccess then
		warn(debug.traceback("Unable to create NPC"))
		return
	end

	Cache[NPC] = {
		Active = true,
		Object = NPC,
		Humanoid = NPC:FindFirstChild("Humanoid"),
		Target = nil,
		Exe = function(self)
			task.spawn(function()
				while self and self.Active and self.Target do
					local TargetHRP = self.Target.Character and self.Target.Character:FindFirstChild("HumanoidRootPart")
					local DistBetween = TargetHRP and (TargetHRP.Position - self.Object.PrimaryPart.Position).Magnitude
					if not TargetHRP or DistBetween >= NPCRange then
						self.Target = nil
						self.Object:SetAttribute("Target", 0)
						continue
					end

					self.NPCRot.CFrame = CFrame.lookAt(self.Object.PrimaryPart.Position, TargetHRP.Position)

					-- if DistBetween <= 5 then
					-- 	-- print("NPC is attacking")
					-- end
					task.wait(.25)
				end
			end)
		end
	}
	Cache[NPC].NPCRot = Instance.new("BodyGyro")

	Cache[NPC].NPCRot.MaxTorque = Vector3.new(400000, 40000000, 400000)
	Cache[NPC].NPCRot.D = 100
	Cache[NPC].NPCRot.Parent = NPC.PrimaryPart
	
	Cache[NPC].Running = NPC.Humanoid.Running:Connect(function(Speed)
		Cache[NPC].NPCRot.P = (Speed == 0 and 30000) or 0
	end)
	Cache[NPC].LastHit = 0
	Cache[NPC].Touched = NPC.Humanoid.Touched:Connect(function(Obj)
		local TouchedPlayer = Players:GetPlayerFromCharacter(Obj.Parent)
		if TouchedPlayer  then
			local PlayerData = Service.Data.GetData(TouchedPlayer)
			if not PlayerData then return end
			local Animator = TouchedPlayer.Character and TouchedPlayer.Character:FindFirstChild("Animator", true)
			local Tracks = Animator and Animator:GetPlayingAnimationTracks()
			if not Tracks then return end
			for _, Animation in ipairs(Tracks) do
				if Animation.Animation.AnimationId == "rbxassetid://8256935615" then
					if Cache[NPC] and  os.time() - Cache[NPC].LastHit >= 1 then
						Cache[NPC].LastHit = os.time()
						NPC.Humanoid:TakeDamage(PlayerData.Strength)
					end
					break
				end
			end
		end
	end)

	Cache[NPC].Died = NPC.Humanoid.Died:Connect(function()
		local PlayerData = Cache[NPC].Target and Service.Data.GetData(Cache[NPC].Target)
		if PlayerData then
			Service.Data.UpdateData(Cache[NPC].Target, "Currency.Cash", PlayerData.Currency.Cash+10)
		end
		NPC:Destroy()
	end)

	CollectionService:AddTag(NPC, "NPC")
	NPC.Parent = NPCFolder

	return Cache[NPC]
end

function Handler:init(Services, _)
	if Initialized then return end
	Initialized = true
	Service = Services

	NPCFolder = workspace:FindFirstChild("NPCFolder") or Instance.new("Folder")
	NPCFolder.Name = "NPCFolder"
	NPCFolder.Parent = workspace

	NPCRemote = Instance.new("RemoteEvent")
	NPCRemote.Name = "NPC"
	NPCRemote.Parent = ReplicatedStorage.Remotes

	NPCRemote.OnServerEvent:Connect(function(Player, NPC)
		if Cache[NPC] and Cache[NPC].Active then
			if not Cache[NPC].Target then
				local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
				local Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
				local DistBetween = HRP and NPC.PrimaryPart and math.floor((HRP.Position - NPC.PrimaryPart.Position).Magnitude)
				if Humanoid and DistBetween then
					DistBetween = DistBetween - (Humanoid.WalkSpeed*Player:GetNetworkPing())
				end
				if HRP and NPC.PrimaryPart and DistBetween <= NPCRange then
					task.spawn(function()
						NPC.PrimaryPart:SetNetworkOwner(Player)
						NPC:SetAttribute("Target", Player.UserId)
					end)
					Cache[NPC].Target = Player
					Cache[NPC]:Exe()
				end
			end
		end
	end)

	CollectionService:GetInstanceRemovedSignal("NPC"):Connect(function(NPC)
		if Cache[NPC] then
			Cache[NPC].Active = false
			for _, DataType in pairs(Cache[NPC]) do
				if typeof(DataType) == "RBXScriptConnection" then
					DataType:Disconnect()
				end
			end
			Cache[NPC] = nil
		end
	end)

	Players.PlayerRemoving:Connect(function(Player)
		for NPC, Data in pairs(Cache) do
			if Data.Target == Player then
				if NPC.PrimaryPart then
					NPC.PrimaryPart:SetNetworkOwner(nil)
				end
				NPC:SetAttribute("Target", 0)
				Cache[NPC].Target = nil
			end
		end
	end)
end

return Handler