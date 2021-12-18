local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = ReplicatedStorage:FindFirstChild("Util")
local Fusion = require(Util:FindFirstChild("Fusion"))
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NPCSpawn")

local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local State = Fusion.State
local Event = Fusion.OnEvent
local Spring = Fusion.Spring
local BtnColor = State(Color3.fromRGB(26, 230, 135))
local SmoothColor = Spring(BtnColor)
local TextColor = State(Color3.fromRGB(0,0,0))
local SmoothTextColor = Spring(TextColor)

return function(Props)
	local CanClick = State(true)
	
	return New("TextButton"){
		Parent = Props.Parent,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(.15, 0, .075,0),
		Position = UDim2.new(0, 0, 0.55, 0),
		BackgroundColor3 = Computed(function()
			return SmoothColor:get()
		end),
		Text = "",
		[Event"Activated"] = function()
			CanClick:set(false)
			BtnColor:set(Color3.fromRGB(230, 26, 60))
			TextColor:set(Color3.fromRGB(255, 255, 255))
			Remote:FireServer()
			task.wait(2)
			BtnColor:set(Color3.fromRGB(26, 230, 135))
			TextColor:set(Color3.fromRGB(0,0,0))
			CanClick:set(true)
		end,
		[Children] = {
			New("UICorner"){
				Scale = 8
			},
			New("Frame"){
				AnchorPoint = Vector2.new(0, 0),
				BackgroundColor3 = Computed(function()
					return SmoothColor:get()
				end),
				Size = UDim2.new(0.5, 0, 1, 0),
			},
			New("TextLabel"){
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0.95, 0, 0.95, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Text = Computed(function()
					return CanClick:get() == true and "Respawn NPC" or "Respawning..."
				end),
				TextColor3 = Computed(function()
					return SmoothTextColor:get()
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