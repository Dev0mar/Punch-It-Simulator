--[[
	Player Handler:

	Handles player related functionality,

	# Loads player's TempData and unloads it once they leave,
	# Sets player collision so players don't collide with each other
]]
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Handler = {}

local PlayerTempData

function HandleCharacter(Char)
	local HRP
	repeat
		HRP = Char:WaitForChild("HumanoidRootPart")
	until HRP or not Char:IsDescendantOf(workspace)
	if not Char:IsDescendantOf(workspace) then return end
	for _, Child in ipairs(Char:GetDescendants()) do
		if Child:IsA("BasePart") or Child:IsA("MeshPart") or Child:IsA("UnionOperation") then
			PhysicsService:SetPartCollisionGroup(Child, "PlayerCharacter")
		end
	end
end

function Handler:init(Services, Util)
	PlayerTempData = require(ServerStorage.Config.TempData)
	local DataService = Services.Data

	DataService.DataReady.Event:Connect(function(Player)
		local PlayerData = DataService.GetData(Player)
		if not PlayerData then return end

		-- DataService.UpdateData(Player, "Currency.Cash", 100000)
	end)

	Players.PlayerAdded:Connect(function(Player)
		PlayerTempData.PlayerList[Player] = Util.TableUtil.DeepCopy(PlayerTempData.DefaultData)
		Player.CharacterAdded:Connect(HandleCharacter)
		if Player.Character then
			HandleCharacter(Player.Character)
		end
	end)

	Players.PlayerRemoving:Connect(function(Player)
		PlayerTempData[Player] = nil
	end)

	PhysicsService:CollisionGroupSetCollidable("PlayerCharacter", "PlayerCharacter", false)
end

return Handler