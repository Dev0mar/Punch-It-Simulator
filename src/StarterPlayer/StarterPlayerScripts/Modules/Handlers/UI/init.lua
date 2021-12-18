local Handler = {}

function Handler:init()
	for _, Child in ipairs(script:GetChildren()) do
		if not Child:IsA("ModuleScript") then continue end
		local ReqSuccess, Result = pcall(function()
			return require(Child)
		end)

		if not ReqSuccess then
			warn("Unable to start UI module [ " .. Child:GetFullName() .. " ] caught error:\n" .. tostring(Result))
		end
	end
end

return Handler