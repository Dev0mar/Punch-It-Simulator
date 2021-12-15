local Handler = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local Initialized = false

local character
local humanoid
local Roll, RollTrack
 
local canDoubleJump = false
local hasDoubleJumped = false
local oldPower
local TIME_BETWEEN_JUMPS = 0.2
local DOUBLE_JUMP_POWER_MULTIPLIER = 4
 
function onJumpRequest()
	if not character or not humanoid or not character:IsDescendantOf(workspace) or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end

	if canDoubleJump and not hasDoubleJumped then
		if RollTrack then
			RollTrack:Play()
		end
		hasDoubleJumped = true
		humanoid.JumpPower = oldPower * DOUBLE_JUMP_POWER_MULTIPLIER
		humanoid.WalkSpeed = 24
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end
 
local function characterAdded(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	hasDoubleJumped = false
	canDoubleJump = false
	oldPower = humanoid.JumpPower

	RollTrack = humanoid:LoadAnimation(Roll)
	RollTrack.Looped = false
	
	humanoid.StateChanged:connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed then
			canDoubleJump = false
			hasDoubleJumped = false
			humanoid.JumpPower = oldPower
			humanoid.WalkSpeed = 16
		elseif new == Enum.HumanoidStateType.Freefall then
			task.wait(TIME_BETWEEN_JUMPS)
			canDoubleJump = true
		end
	end)
end

function Handler:init()
	if Initialized then return end
	Initialized = true
	localPlayer.CharacterAdded:Connect(characterAdded)
	UserInputService.JumpRequest:Connect(onJumpRequest)

	Roll = Instance.new("Animation")
	Roll.AnimationId = "rbxassetid://" .. 8044267335

	if localPlayer.Character then
		characterAdded(localPlayer.Character)
	end
end
return Handler