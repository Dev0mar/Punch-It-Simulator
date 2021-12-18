--[[
	NPC Spawner:

	Using CollectionService this module detects new spawns by the "NPCSpawn" tag.
	Each spawner will keep track of the NPC it spawns, once the NPC dies or is removed from the game it will spawn another,

	When the spawner is removed or its tag is removed then the spawner will be disabled and removed from cache

	Spawner Object in cache:
	Cache[Instance: Spawner] = {
		[Boolean] Active: When set to false the Executor loop will terminate to allow for the Cache to be cleared.
		[Instance] Object: The spawner object
		[Integer] LastSpawned: Time of when the NPC was last spawned, used as a debounce
		[Instance] CurrentNPC: The NPC that is currently spawned in this spawner
		[Function] Exe: a Function that has a loop which makes sure there is always an NPC spawned, terminates if Active state is set to false
	}

	
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Handler = {}

local Cache = {}
local NPCControl, Util, SpawningRemote
local Initialized = false

function RegisterSpawn(Spawner)
	if not Spawner:IsDescendantOf(workspace) then return end

	if not Cache[Spawner] then
		Cache[Spawner] = {
			Active = true,
			Object = Spawner,
			LastSpawned = 0,
			CurrentNPC = nil,
			Exe = function(self)
				task.spawn(function()
					while self and self.Active do
						if not self.CurrentNPC and os.time() - self.LastSpawned >= 5 then
							self.LastSpawned = os.time()
							local NPC = NPCControl.Create()
							if not NPC then
								task.wait()
								continue
							end
							self.CurrentNPC = NPC
							local XSize, ZSize = self.Object.Size.X/2, self.Object.Size.Z/2
							NPC.Object:MoveTo(self.Object.Position + Vector3.new(math.random(-XSize, XSize), 1, math.random(-ZSize, ZSize)))
							Util.Promise.race({
								Util.Promise.fromEvent(NPC.Object.AncestryChanged),
								Util.Promise.fromEvent(NPC.Humanoid.Died),
							}):await()
							self.CurrentNPC = nil
						end
						task.wait(1)
					end
				end)
			end
		}
		Cache[Spawner]:Exe()
	end
end

function Handler:init(_, Utils)
	if Initialized then return end
	Initialized = true
	Util = Utils
	SpawningRemote = Instance.new("RemoteEvent")
	SpawningRemote.Name = "NPCSpawn"
	SpawningRemote.Parent = ReplicatedStorage.Remotes

	NPCControl = require(script.Parent.NPC)

	local LastFired = 0
	SpawningRemote.OnServerEvent:Connect(function()
		if os.time() - LastFired <= 2 then return end
		LastFired = os.time()
		for _, Data in pairs(Cache) do
			if Data.CurrentNPC then
				Data.CurrentNPC.Object:Destroy()
			end
		end
	end)

	CollectionService:GetInstanceAddedSignal("NPCSpawn"):Connect(RegisterSpawn)

	CollectionService:GetInstanceRemovedSignal("NPCSpawn"):Connect(function(Spawner)
		if Cache[Spawner] then
			Cache[Spawner].Active = false
			Cache[Spawner] = nil
		end
	end)

	for _, ExistingSpawner in ipairs(CollectionService:GetTagged("NPCSpawn")) do
		RegisterSpawn(ExistingSpawner)
	end
end

return Handler