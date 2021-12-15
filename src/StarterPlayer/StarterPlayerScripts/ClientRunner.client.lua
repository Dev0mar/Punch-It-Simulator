--[[
	Client GameRunner:

	Starts up the game's systems, first loading Utility modules, then Services then Handlers.

	# If any module throws an error it will output a warning explaining what module and what is the issue
	# Services and Utils are stored and passed onto handlers to be able to use
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = script.Parent:WaitForChild("Modules")

local ServiceList, UtilList = {}, {}

for _, Util in ipairs(ReplicatedStorage.Util:GetChildren()) do
	local Success, Result = pcall(function()
		return require(Util)
	end)
	
	if not Success then
		warn("Unable to load util module [ " .. Util:GetFullName() .. " ] got error:\n " .. tostring(Result))
		continue
	end
	UtilList[Util.Name] = Result
end
print("Loaded Utilities")

for _, Service in ipairs(Modules.Services:GetChildren()) do
	local Success, Result = pcall(function()
		return require(Service)
	end)

	if not Success then
		warn("Failed to load service [ " .. Service:GetFullName() .. " ] got error:\n " .. tostring(Result))
		continue
	end

	if Result.init then
		local InitializeSuccess, InitializeResult = pcall(function()
			return Result:init(UtilList)
		end)

		if not InitializeSuccess then
			warn("Failed to initialize Service [ " .. Service:GetFullName() .. " ] got error:\n" .. tostring(InitializeResult))
			continue
		end
	end

	ServiceList[Service.Name] = Result
end
print("Loaded Services")

for _, Handler in ipairs(Modules.Handlers:GetChildren()) do
	task.spawn(function()
		local Success, Result = pcall(function()
			return require(Handler)
		end)
		
		if not Success then
			warn("Failed to load handler [ " .. Handler:GetFullName() .. " ] got error:\n " .. tostring(Result))
			return
		end

		if Result.init then
			local InitSuccess, InitResult = pcall(function()
				return Result:init(ServiceList, UtilList)
			end)

			if not InitSuccess then
				warn("Failed to initialize handler [ " .. Handler:GetFullName() .. " ] got error:\n " .. tostring(InitResult))
				return
			end
		end
	end)
end