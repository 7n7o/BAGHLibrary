
local Cloud = {}
Cloud.__index = Cloud

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

local Promise = require("@pkg/Promise")
local Maid = require("@pkg/Maid")


local function assertw(condition, message)
    if not condition then
        warn(message)
        return true
    end
end

function Cloud.new(CloudTool, keepActive)
    local self = setmetatable({}, Cloud)
    self._tool = CloudTool
	self._maid = Maid.new()
	self._keepActive = keepActive == nil and true or keepActive
    self:Init()
    return self
end

function Cloud:Init()
	local Character = LocalPlayer.Character
	local Backpack = LocalPlayer.Backpack



	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    local Tool = self._tool
    if Tool.Parent == nil then
        warn("Cloud tool is not attached to a player")
        return
    end
    if Tool.Parent == Backpack and self._keepActive then
        Tool.Parent = Character
    end
    self._control = Tool:WaitForChild("ServerControl", 5)
    if assertw(self._control, "Cloud tool does not have a ServerControl") then return end
    if assertw(self._control:IsA("RemoteFunction"), "ServerControl is not a RemoteFunction") then return end
    if assertw(Tool:FindFirstChild("Handle") and Tool.Handle:IsA("Part"), "Tool's Handle is Invalid") then return end
    
    if Tool.Parent == Character and not (Tool.Handle:FindFirstChildOfClass("SpecialMesh") and Tool.Handle:FindFirstChildOfClass("SpecialMesh").MeshId == "rbxassetid://0") then
        self:SetProperties(Tool.Handle:FindFirstChildOfClass("SpecialMesh"), {
            MeshId = "rbxassetid://0"
        }):andThen(function()
            for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do track:Stop() end
        end)
    end
    Tool.Name = "Homebrew_Cloud"
    if self._keepActive then
	    self._maid:GiveTask(Tool:GetPropertyChangedSignal("Parent"):Connect(function()
	        task.defer(function()
		        if Tool.Parent == Backpack and Humanoid.Health > 0 then
		           Tool.Parent = Character 
		        end
		    end)
		end))
	end
	
	self._maid:GiveTask(function()
		Tool.Parent = Character
		if Tool.Parent ~= nil then
			self:SetProperties(Tool, {Parent = game.TestService})
		end
	end)

end

function Cloud:SetProperties(object, propertyTable)
	local Character = LocalPlayer.Character
	local Backpack = LocalPlayer.Backpack



	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    return Promise.new(function(res, rej)
        if not object:IsDescendantOf(Character) then rej("Object is not a descendant of the character") end
        local Parent = propertyTable.Parent or object.Parent
        propertyTable.Parent = nil
        local bools = {}
        for k, v in pairs(propertyTable) do
            task.defer(function()
                bools[k] = false
                self._control: InvokeServer("SetProperty", {
                    Value = v,
                    Property = k,
                    Object = object
                })
                bools[k] = true
            end)
        end
        local timer = 0
        while true do
            local dt = game.RunService.Heartbeat:Wait()
            timer = timer + dt
            if timer > 5 then
                rej("Timed out")
                break
            end
            local a = true
            for k, v in pairs(bools) do
                if not v then a = false end
            end
            if a then
                self._control:InvokeServer("SetProperty", {
                    Value = Parent,
                    Property = "Parent",
                    Object = object
                })
                res(object)
                break
            end
        end
	end):catch(function(reason)
		if reason ~= "Timed out" then
			error(reason)	
		end
	end)
end

function Cloud:EffectCloud()
    return Promise.new(function(res, rej)
        self._control:InvokeServer("Fly", {Flying = true})
        local EffectCloud = self._tool:WaitForChild("EffectCloud")
		
		task.defer(res, EffectCloud, function() self._control:InvokeServer("Fly", {Flying = false}) end)
    end)
end

function Cloud:Destroy()
    self._maid:Destroy()
end

return Cloud