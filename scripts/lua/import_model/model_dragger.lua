local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Maid = require("@pkg/Maid")

local maid = Maid.new()

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local selectedModel = nil
local handles, arcHandles
local fakePart
local mode = "move"

-- cleanup old stuff
local function cleanup()
	if handles then handles:Destroy() handles = nil end
	if arcHandles then arcHandles:Destroy() arcHandles = nil end
	if fakePart then fakePart:Destroy() fakePart = nil end
end

-- update fake part position
local function updateHandlePosition()
	if selectedModel and fakePart then
		fakePart.CFrame = selectedModel:GetPivot()
	end
end


-- create gizmos AND connect events properly
local function createHandles()
	cleanup()

	handles = Instance.new("Handles")
	handles.Style = Enum.HandlesStyle.Movement
	handles.Color3 = Color3.fromRGB(0,170,255)

	arcHandles = Instance.new("ArcHandles")
	arcHandles.Color3 = Color3.fromRGB(255,170,0)

	local gui = player:WaitForChild("PlayerGui")
	handles.Parent = gui
	arcHandles.Parent = gui

    local _, size = selectedModel:GetBoundingBox()





	fakePart = Instance.new("Part")
	fakePart.Size = size
	fakePart.Transparency = 1
	fakePart.Anchored = true
	fakePart.CanCollide = false
	fakePart.Parent = workspace

	updateHandlePosition()

	handles.Adornee = fakePart
	arcHandles.Adornee = fakePart

	handles.Visible = (mode == "move")
	arcHandles.Visible = (mode == "rotate")

    maid:GiveTask(handles)
    maid:GiveTask(arcHandles)
    maid:GiveTask(fakePart)

    local dragStartPivot = nil

    local function startDrag()
        if not selectedModel then return end
        
        dragStartPivot = selectedModel:GetPivot()
    end

    maid:GiveTask(handles.MouseButton1Down:Connect(startDrag))
    maid:GiveTask(arcHandles.MouseButton1Down:Connect(startDrag))

    maid:GiveTask(handles.MouseDrag:Connect(function(face, distance)
        if not selectedModel or not dragStartPivot then return end
        if not face then return end

        local axis = Vector3.FromNormalId(face)
        if not axis then return end 

        local move
        local mode = "local"
        if mode == "global" then
            move = axis * distance

        elseif mode == "local" then
            move = dragStartPivot:VectorToWorldSpace(axis * distance)
        end

        if not move then return end

        selectedModel:PivotTo(dragStartPivot + move)
        updateHandlePosition()
    end))

	maid:GiveTask(arcHandles.MouseDrag:Connect(function(axis, angle)
		if not selectedModel or not dragStartPivot then return end

		local pivot = selectedModel:GetPivot()

		local rotation
		if axis == Enum.Axis.X then
			rotation = CFrame.Angles(angle, 0, 0)
		elseif axis == Enum.Axis.Y then
			rotation = CFrame.Angles(0, angle, 0)
		elseif axis == Enum.Axis.Z then
			rotation = CFrame.Angles(0, 0, angle)
		end

		selectedModel:PivotTo(dragStartPivot * rotation)
		updateHandlePosition()
	end))
end

function model_dragger(model)
    selectedModel = model
    createHandles()
    updateHandlePosition()
maid:GiveTask(mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if not target then return end

	local model = target:FindFirstAncestorOfClass("Model")
	if not model then return end

	selectedModel = model
	createHandles()
end))


maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.R then
		mode = (mode == "move") and "rotate" or "move"

		if handles and arcHandles then
			handles.Visible = (mode == "move")
			arcHandles.Visible = (mode == "rotate")
		end
	end
end))
return maid
end

return model_dragger