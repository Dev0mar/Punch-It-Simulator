local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Util = {}

if not RunService:IsClient() then return {} end

local Player = Players.LocalPlayer

function Util.GetMouseTarget(FilterType, Filter)
	local cursorPosition = UserInputService:GetMouseLocation()
	local oray = workspace.CurrentCamera:ViewportPointToRay(cursorPosition.X, cursorPosition.Y, 0)
	local raycastParams = RaycastParams.new()
	if FilterType then
		raycastParams.FilterType = FilterType
	end
	if Filter then
		raycastParams.FilterDescendantsInstances = Filter
	end
	raycastParams.IgnoreWater = true
	return workspace:Raycast(workspace.CurrentCamera.CFrame.Position,(oray.Direction * 1000), raycastParams)
end

return Util