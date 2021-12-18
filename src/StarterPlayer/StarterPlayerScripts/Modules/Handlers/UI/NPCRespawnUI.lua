local Handler = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Util.Fusion)
local Pages = ReplicatedStorage.Shared.UI.Pages

local Main  = require(Pages.NPCRespawn)

local Player = Players.LocalPlayer

local New = Fusion.New
local Children = Fusion.Children

function CreateDisplay()

	New("ScreenGui"){
		Name = "NPCRespawn",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		Parent = Player.PlayerGui,
		[Children] = {
			Main{}
		}
	}
end

Player.CharacterAdded:Connect(function()
	CreateDisplay()
end)

if Player.Character then
	CreateDisplay()
end

return Handler