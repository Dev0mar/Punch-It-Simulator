local Util = {}

function Util.AddMissing(Target, Default)
	for DataName, DataValue in pairs(Default) do
		if Target[DataName] == nil then
			Target[DataName] = DataValue
		else
			if typeof(DataValue) == "table" then
				Util.AddMissing(Target[DataName], DataValue)
			end
		end
	end
end

function Util.DeepCopy(T)
	local Result = {}
	for index, value in pairs(T) do
		if typeof(value) == "table" then
			Result[index] = Util.DeepCopy(value)
		else
			Result[index] = value
		end
	end
	return Result
end

function Util.DeepFind(T, DataName, ShouldWarn)
	local Result
	ShouldWarn = (ShouldWarn == nil and true) or ShouldWarn
	if not T or not DataName then return end
	if string.find(DataName, "%.") then
		local Path = string.split(DataName, '.')
		local Target = T
		local PathLength = #Path
		for PathIndex, PathName in pairs(Path) do
			if not Target or Target[PathName] == nil and PathIndex ~= PathLength then
				if ShouldWarn then
					warn(debug.traceback("[TableUtil] Unable to get data, data name not found [ " .. DataName .. " ] failed at [ " .. tostring(PathName) .. "]"))
				end
				break
			end

			if PathIndex == PathLength then
				Result = Target[PathName]
			else
				Target = Target[PathName]
			end
		end
	else
		Result = T[DataName]
	end

	return Result
end

function Util.DeepSet(T, DataName, DataValue)
	if string.find(DataName, "%.") then
		local Path = string.split(DataName, ".")
		local Target = T
		local PathLength = #Path
		for PathIndex, PathName in ipairs(Path) do
			if Target[PathName] == nil and PathIndex ~= PathLength then
				warn("[DataService] Unable to update data, data name not found [ " .. DataName .. " ] failed at [ " .. tostring(PathName) .. "]")
				break
			end

			if PathIndex == PathLength then
				Target[PathName] = DataValue
			else
				Target = Target[PathName]
			end
		end
	else
		T[DataName] = DataValue
	end
end

return Util