--[[
	Market Service:

	Connects to essential events and Functions of Marketplace Service, and hooks it with the MarketData module
	to allow for a less bloated Service handling

	# Very simple implementation, it is meant to be expanded upon later on.
]]
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local Service = {}

local MarketData = require(ServerStorage.Config.MarketData)

MarketplaceService.ProcessReceipt = function(info)
	local Product = MarketData.Products[info.ProductId]
	if Product then
		Product(info.PlayerId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player, PassID, DidPurchase)
	if not DidPurchase then return end
	local Pass = MarketData.Gamepasses[PassID]
	if Pass then
		Pass(Player.UserId)
	end
end)

print("Marketplace Service Loaded")

return Service