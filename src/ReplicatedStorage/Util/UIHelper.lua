local CollectionService = game:GetService("CollectionService")

local Util = {}

local function GetCameraOffset(fov, target_size)
	local x, y, z = target_size.x, target_size.y, target_size.Z
	local max_size = math.sqrt(x^2 + y^2 + z^2)
	local fac = math.tan(math.rad(fov)/2)
	local depth = 0.5 * max_size/fac
	return depth + max_size/2
end

-- @param item: The {BasePart} or {Model} to display
-- @param viewport: The {ViewportFrame} used for display
function Util.SetViewport(item, viewport)
	local model = item:Clone()
	
	viewport:ClearAllChildren()
	
	if not item:IsA("Model") then
		model = Instance.new("Model")
		item.Parent = model
		model.PrimaryPart = item
	end
	
	model.Parent = viewport

	local viewport_camera = Instance.new("Camera")
	viewport_camera.FieldOfView = 1
	viewport_camera.CameraType = Enum.CameraType.Scriptable
	viewport_camera.CameraSubject = model.PrimaryPart
	viewport.CurrentCamera = viewport_camera
	
	model:PivotTo(CFrame.new(0,0,0))
	
	local CF = model.PrimaryPart.CFrame * CFrame.new(0,0,-GetCameraOffset(viewport_camera.FieldOfView, model:GetExtentsSize()))
	viewport_camera.CFrame = CFrame.lookAt(CF.Position, model.PrimaryPart.Position)

	viewport_camera.Parent = viewport
end

function Util.FindFirstByTag(TagName, TargetParent)
	local Result
	for _, UI in ipairs(CollectionService:GetTagged(TagName)) do
		if TargetParent then
			if UI:IsDescendantOf(TargetParent) then
				Result = UI
				break
			end
		else
			Result = UI
			break
		end
	end
	return Result
end

local Suffixes = {"k","M","B","T","qd","Qn","sx","Sp","O","N","de","Ud","DD","tdD","qdD","QnD","sxD","SpD","OcD","NvD","Vgn","UVg","DVg","TVg","qtV","QnV","SeV","SPG","OVG","NVG","TGN","UTG","DTG","tsTG","qtTG","QnTG","ssTG","SpTG","OcTG","NoTG","QdDR","uQDR","dQDR","tQDR","qdQDR","QnQDR","sxQDR","SpQDR","OQDDr","NQDDr","qQGNT","uQGNT","dQGNT","tQGNT","qdQGNT","QnQGNT","sxQGNT","SpQGNT", "OQQGNT","NQQGNT","SXGNTL"}

function Util.ShortenNumber(Input)
    local Negative = Input < 0
    Input = math.abs(Input)
    
    local strSub = string.sub
    local strFind = string.find


    local Paired = false
    for i, _ in pairs(Suffixes) do
        if not (Input >= 10^(3*i)) then
            Input = Input / 10^(3*(i-1))
            local isComplex = (strFind(tostring(Input),".") and strSub(tostring(Input),4,4) ~= ".")
            Input = strSub(tostring(Input),1,(isComplex and 4) or 3) .. (Suffixes[i-1] or "")
            Paired = true
            break;
        end
    end
    if not Paired then
        local Rounded = math.floor(Input)
        Input = tostring(Rounded)
    end

    if Negative then
        return "-"..Input
    end
    return Input
end

return Util