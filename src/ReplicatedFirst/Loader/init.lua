--[[
	Loading Handler:

	Shows loading screen until player's data is ready, then shows the main UI

	TODO: preload essential assets
]]

local Players = game:GetService("Players")
local Loader = {}

local Player = Players.LocalPlayer
local LoadingUI = script:WaitForChild("GameLoading")

LoadingUI.Parent = Player.PlayerGui
local MainUI = Player.PlayerGui:WaitForChild("Main")
local PlayButton = LoadingUI:FindFirstChild("Play", true)
local PlayConnection
PlayButton.Visible = false

repeat
	task.wait()
until Player:GetAttribute("DataReady") == true

PlayButton.Visible = true

PlayConnection = PlayButton.MouseButton1Click:Connect(function()
	PlayConnection:Disconnect()
	PlayConnection = nil
	LoadingUI.Enabled = false
	MainUI.Enabled = true
end)

return Loader