local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Pages = Shared.UI.Pages
local UI = require(Pages.CashDisplay)

return function(Target)
	local Main = UI{
		Parent = Target
	}
	return function()
		Main:Destroy()
	end
end