local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = ReplicatedStorage:FindFirstChild("Util")
local Fusion = require(Util:FindFirstChild("Fusion"))

local Player = Players.LocalPlayer

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local State = Fusion.State
local Spring = Fusion.Spring
local PlayerCash = State(0)
local SmoothCash = Spring(PlayerCash)

if RunService:IsClient() and Player then
	PlayerCash:set(Player:GetAttribute("Cash") or 0)
	Player:GetAttributeChangedSignal("Cash"):Connect(function()
		PlayerCash:set(Player:GetAttribute("Cash") or 0)
	end)
end

return function(Props)
	return New("Frame"){
		Parent = Props.Parent,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(.2, 0, .1,0),
		Position = UDim2.new(0, 0, 0.435, 0),
		BackgroundColor3 = Color3.fromRGB(204, 201, 0),
		[Children] = {
			New("UICorner"){
				Scale = 8
			},
			New("Frame"){
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Color3.fromRGB(204, 201, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
			},
			New("TextLabel"){
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0.95, 0, 0.95, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Text = Computed(function()
					return "$" .. math.round(SmoothCash:get())
				end),
				TextScaled = true,
				[Children] = {
					New("UIPadding"){
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8)
					}
				}
			}
		}
	}
end