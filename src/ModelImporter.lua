
local Promise = require(script.Parent.Promise)
local BAGH = require(script.Parent)
local PropertyDict = require(script.Parent.Properties)

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

local ModelImporter = {}

function ModelImporter:Import(filepath, parent, cloud)
    self._cloud = cloud
    return Promise.new(function(res, rej)
        if not isfile(filepath) then
            rej("File not found")
            return
        end
        local ID = getcustomasset(filepath)
        if not ID then
            rej("Could not import model")
            return
        end
        local Objects = game:GetObjects(ID)
        if not Objects then
            rej("Could not import model")
            return
        end

        ModelImporter:ImportObjects(Objects, cloud, parent):andThen(function() res(parent) end):catch(rej)
    end)
end

function ModelImporter:ImportObjects(Objects, Cloud, Parent)
    print(Parent)
    return Promise.new(function(res, rej)
        local Promises = {}
        local Out = {}
        for _, Object in pairs(Objects) do
            local Promise = self:ImportModel(Object, Cloud, Parent):andThen(function(Model)
                table.insert(Out, Model)
            end):catch(rej)
            table.insert(Promises, Promise)
        end
        Promise.all(Promises):andThen(function() res(Out) end)
    end)
end

function ModelImporter:ImportModel(Model, Cloud, Parent)
    print(Parent)
    return Promise.new(function(res, rej)
        if not Model then
            rej("Could not import model")
            return
        end
        local numParts = 0
        for _, part in pairs(Model:GetDescendants()) do
            if part:IsA("Part") then
                numParts = numParts + 1
            end
        end
        local Promises = {}
        local numTools = #LocalPlayer.Backpack:GetChildren()
        for i = 1, numParts do
            BAGH:GetTool("BeatUpBoombox")
        end
        repeat task.wait(1/0) until
        #LocalPlayer.Backpack:GetChildren() - numTools == numParts

        local count = 0
        local Tools = {}
        for _, Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if count == numParts then break end
            if Tool.Name == "BeatUpBoombox" then
                count = count + 1
                table.insert(Tools, Tool)
                Tool.Parent = LocalPlayer.Character
            end
        end

        
        
      
        while task.wait(1/0) do
            local a = true
            for _, Tool in pairs(Tools) do
                if Tool.Parent ~= Character then a = false end 
            end
            if a then break end
        end
        for _, Tool in pairs(Tools) do
            Tool.Handle:BreakJoints()
        end
        task.wait(.1)
        local count = 0
        local PartPromises = {}
        for _, part in pairs(Model:GetDescendants()) do
            if part:IsA("Part") then
                count = count + 1
                Tools[count].Name = count
                
                self:CreatePart(Tools[count], part, Parent)
            end
        end
        Promise.all(PartPromises):andThen(function()
            res(Parent)
        end)
    end)
end

function ModelImporter:CloneProperties(Instance1, Instance2)
    return Promise.new(function(res, rej)
        if Instance1.ClassName ~= Instance2.ClassName then
            rej()
        end
        print(Instance1.ClassName)
        local Properties = PropertyDict[Instance1.ClassName]
        local Props = {}
        for _, Property in pairs(Properties) do
            local Value = Instance1[Property]
            if Value then
                Props[Property] = Value
            end
        end
        self._cloud:SetProperties(Instance2, Props):andThen(function() res() end):catch(rej)
    end)
end

function ModelImporter:CreatePart(Boombox, Part, Parent, Flag)
    return Promise.new(function(res, rej)
        local Properties = {}
        for _, Property in ipairs(PropertyDict[Part.ClassName]) do
            Properties[Property] = Part[Property]
        end
        Properties.Parent = Parent
        if not Part:FindFirstChildOfClass("SpecialMesh") then
            Boombox.Handle:ClearAllChildren()
        else
            for _,v in ipairs(Boombox.Handle:GetChildren()) do
                if not v:IsA("SpecialMesh") then
                    v:Destroy()
                end
            end
        end
        
        if not Flag then Boombox.Handle:BreakJoints() end
        task.wait(.1)
        self._cloud:SetProperties(Boombox.Handle, Properties):andThen(function(H)
            task.wait(.1)
            Boombox:Destroy()
            if Part:FindFirstChildOfClass("SpecialMesh") then
                self:CloneProperties(Part:FindFirstChildOfClass("SpecialMesh"), H:FindFirstChildOfClass("SpecialMesh")):andThen(res)
            else
                res(H)
            end
        end)
    end)
end

return ModelImporter