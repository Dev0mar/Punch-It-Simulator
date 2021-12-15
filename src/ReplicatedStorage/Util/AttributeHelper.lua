local Helper = {}

function Helper.GetWithAttributeOfValue(Target, AttributeName, AttributeValue, Recursive)
	local Result
	local Tb = (Recursive and Target:GetDescendants()) or Target:GetChildren()
	for _, Child in ipairs(Tb) do
		local Attrib = Child:GetAttribute(AttributeName)
		if Attrib and Attrib == AttributeValue then
			Result = Child
			break
		end
	end
	return Result
end

function Helper.GetAllWithAttributeOfValue(Target, AttributeName, AttributeValue, recursive)
	local Result = {}
	local Tb = (recursive and Target:GetDescendants()) or Target:GetChildren()
	for _, Child in ipairs(Tb) do
		local Attrib = Child:GetAttribute(AttributeName)
		if Attrib and Attrib == AttributeValue then
			table.insert(Result, Child)
		end
	end
	return Result
end

return Helper