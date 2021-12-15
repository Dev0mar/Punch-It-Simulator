--[[
	Data Service:
	
	This Service handles the player's data loading, fetching and updating. Using Profile Service by Loleris

	The following is a run down of how this Service works,

	Key:
	* Variable
	[*] Function
	# Note

	-----
	* Service.DataReady: BindableEvent
	
	You can listen to this event to signal other systems in the game that a new player's data has been loaded and ready for use
	------
	* [Dictionary] DataTemplate

	The default data dictionary which is used for players and should be saved
	------
	* [Dictionary] TempData

	Temporary data given to the player which is used during the session, however does not save cross sessions
	------
	* [Table] ReplicatedData

	A table holding data names which you wish the client to read and keep updated on any changes.
	
	# These strings can be from either one of the above data tables,
	# If you wish to replicate a data item nested deep inside other data, use "." to write the path to given data item, Example [Inventory.Currency.Cash]
	# These items are turned into Attributes given to the player
	# Due to lack of Roblox Support, Dictionary or Table items are turned into JSON and set as a string attribute, however, the client will decode the JSON and use the item value as intended
	------

	[*] Service.GetData(Instance: Player) -> Returns: Dictionary

	Returns a copy of the player's [Saveable] Data.

	# Returned data is not directly associated with the player's data, must update player's data via Service.UpdateData

	-----

	[*] Service.UpdateData(Instance: Player, String: DataName, Any: DataValue)

	Updates player's data and replicates to the client if necessary.

	# If you need to update a specific key nested in the dictionary, you may use "." to set the data path, Example: Inventory.Weapons.Melee.Knife.Damage
	# If DataName does not include a period, system will assume it's directly inside the dictionary and not nested.
	# You may use this to update TempData keys.
	# If you have key names that are identical in both TempData and PlayerData (Saveable data), then only the TempData key will be updated. [It is advised to not have conflicting names between the two dictionaries]
	-----

	[*] RegisterPlayer(Instance: Player)

	Internal Function called on PlayerAdded, takes the Player Instance and loads their profile via ProfileService,
	Once data is loaded it will replicate all the needed data to the client, then fire a DataReady signal to the server letting other systems know this player is fully loaded
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Service = {}
Service.DataReady = Instance.new("BindableEvent")
Service.DataReady.Name = "DataReady"
Service.DataReady.Parent = script

local ProfileService = require(script.ProfileService)
local DataTemplate = require(ServerStorage.Config.PlayerData)
local TempData = require(ServerStorage.Config.TempData)

local Util = {}
local Profiles = {}
local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	DataTemplate
)

local ReplicatedData = {"Currency.Cash", "Strength"}

do
	for _, UtilModule in ipairs(ReplicatedStorage.Util:GetChildren()) do
		if not UtilModule:IsA("ModuleScript") then continue end
		local Success, Result = pcall(function()
			return require(UtilModule)
		end)

		if not Success then
			warn("[DataService] Unable to load Util module [ " .. UtilModule:GetFullName() .. " ] caught error:\n " .. tostring(Result))
			continue
		end
		Util[UtilModule.Name] = Result
	end
end

function Service.GetData(Player)
	if not Player then return end
	if not Profiles[Player] then
		warn("[DataService] Attempt to fetch player data, unable to find data for player [ " .. Player.UserId .. " ]")
		return
	end
	return Util.TableUtil.DeepCopy(Profiles[Player].Data)
end

function Service.UpdateData(Player, DataName, DataValue)
	assert(Player and Players:FindFirstChild(Player.Name), "[DataService] Unable to update player data, player not found")
	assert(typeof(DataName) == "string", "[DataService] Unable to update player data invalid data name [ " .. tostring(DataName) .. " ] must be a string got [ " .. typeof(DataName) .. " ]")
	assert(Profiles[Player], "[DataService] Unable to update player data, player data not found")
	
	if TempData.PlayerList[Player] and Util.TableUtil.DeepFind(TempData.PlayerList[Player], DataName, false) then
		Util.TableUtil.DeepSet(TempData.PlayerList[Player], DataName, DataValue)
	else
		if Profiles[Player] then
			Util.TableUtil.DeepSet(Profiles[Player].Data, DataName, DataValue)
		end
	end

	if table.find(ReplicatedData, DataName) then
		if typeof(DataValue) == "table" then
			DataValue = HttpService:JSONEncode(DataValue)
		end
		if string.find(DataName, "%.") then
			local Path = string.split(DataName, ".")
			Player:SetAttribute(Path[#Path], DataValue)
		else
			Player:SetAttribute(DataName, DataValue)
		end
	end
end

function RegisterPlayer(Player)

	local profile = ProfileStore:LoadProfileAsync("Player_" .. Player.UserId)
	if profile ~= nil then
		profile:AddUserId(Player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			if Profiles[Player] then
				Profiles[Player]:SetMetaTag("LastUpdated", os.time())
				Profiles[Player] = nil
			end

			Player:Kick("Your data was accessed in another server, if this isn't intentional please contact an admin or developer")
		end)

		if Player:IsDescendantOf(Players) then
			Profiles[Player] = profile
		else
			profile:Release()
			return
		end
	else
		Player:Kick("Unable to load player data Error Code [ 500 ] contact admin or developer")
		return
	end

	Util.TableUtil.AddMissing(Profiles[Player].Data, DataTemplate)

	Service.UpdateData(Player, "version", DataTemplate.version)
	Service.UpdateData(Player, "LoginCount", Profiles[Player].Data.LoginCount+1)
	if os.time() - Profiles[Player].Data.LastLogin <= (60*60*24) then
		Service.UpdateData(Player, "LoginStreak", Profiles[Player].Data.LoginStreak+1)
	else
		Service.UpdateData(Player, "LoginStreak", 1)
	end
	Service.UpdateData(Player, "LastLogin", os.time())
	
	Service.UpdateData(Player, "LoginCount",1)
	local PData = Service.GetData(Player)
	for _, ReplicatedDataName in ipairs(ReplicatedData) do
		-- print(PData,ReplicatedDataName)
		local TargetData = Util.TableUtil.DeepFind(PData, ReplicatedDataName)
		TargetData = (TargetData == nil and Util.TableUtil.DeepFind(TempData.PlayerList[Player], ReplicatedDataName)) or TargetData
		if TargetData then
			if typeof(TargetData) == "table" then
				TargetData = HttpService:JSONEncode(TargetData)
			end
			if string.find(ReplicatedDataName, "%.") then
				local Path = string.split(ReplicatedDataName, ".")
				Player:SetAttribute(Path[#Path], TargetData)
			else
				Player:SetAttribute(ReplicatedDataName, TargetData)
			end
		end
	end
	Service.DataReady:Fire(Player)
end

Players.PlayerAdded:Connect(RegisterPlayer)

Players.PlayerRemoving:Connect(function(Player)
	local TotalTime = math.floor(Profiles[Player].Data.TotalPlaytime + ((os.time() - Profiles[Player].Data.LastLogin)/60))
	Service.UpdateData(Player, "TotalPlaytime",  TotalTime)
	TotalTime = nil
	if Profiles[Player] then
		Profiles[Player]:Release()
	end
end)

for _, ExistingPlayer in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		RegisterPlayer(ExistingPlayer)
	end)
end

print("[PlayerDataService] LOADED")

return Service