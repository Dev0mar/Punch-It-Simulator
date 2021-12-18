--[[
	Punch Mechanic:

	Using UserInputService, this module detects when the player clicks, taps or Presses the X button on a gamepad.
	once the player performs this action their NPC will play a punch animation

	We add a "Punching" attribute to the player while the animation is playing to signal to the other systems that this player is punching
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Handler = {}

local Player = Players.LocalPlayer

local PunchAnimation = Instance.new("Animation")
PunchAnimation.AnimationId = "rbxassetid://8256935615"

local Punch, PunchSound
local Initialized = false

function HandleCharacter(Char)
	local Humanoid = Char:WaitForChild("Humanoid")
	if not Humanoid then return end

	Humanoid.Died:Connect(function()
		Punch = nil
	end)

	PunchSound = Instance.new("Sound")
	PunchSound.SoundId = "rbxassetid://1112042117"
	PunchSound.Parent = Char.HumanoidRootPart

	Punch = Humanoid:LoadAnimation(PunchAnimation)
end

function Handler:init(_, Util)
	if Initialized then return end
	Initialized = true

	local PunchButtons = {
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.Touch,
		Enum.UserInputType.Gamepad1
	}

	Player.CharacterAdded:Connect(HandleCharacter)

	UserInputService.InputBegan:Connect(function(Input, GP)
		if GP then return end
		
		if table.find(PunchButtons, Input.UserInputType) then
			if Input.UserInputType == Enum.UserInputType.Gamepad1 and not Input.KeyCode == Enum.KeyCode.ButtonX then return end
			if Punch and not Punch.IsPlaying then
				if PunchSound then
					PunchSound:Play()
				end
				Punch:Play()
				Player:SetAttribute("Punching", true)
				Util.Promise.race({
					Util.Promise.delay(2),
					Util.Promise.fromEvent(Punch.Stopped)
				}):await()
				Player:SetAttribute("Punching", false)
			end
		end
	end)
	
	if Player.Character then
		HandleCharacter(Player.Character)
	end
end

return Handler