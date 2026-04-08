
local Promise = require("@pkg/Promise")
local BAGH = require("./BAGH")
local PropertyDict = require("./Properties")

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

local ModelImporter = {}

function buildPropertyDictionary(i1, i2)
	local pDict = PropertyDict[i1.ClassName]
	if pDict == nil then
		warn(i1.ClassName.." is not supported")
		return false
	end
	
	local Properties = {}
	for _, Property in ipairs(pDict) do
		if i1[Property] ~= i2[Property] then
			Properties[Property] = i2[Property]
		end
	end
	
	return Properties
	
end


function ModelImporter:ImportModel(Provider, Model, Cloud, Parent, options)
	local Character = LocalPlayer.Character
	options = options or {}
	
	local useDefer = options.useDefer or false
	local batchSize = options.batchSize or 100
	local batchSleep = options.batchSleep or 0
	
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
		
		

		
		local _, partRef = Provider:RequestInstance("Part"):await()
		local m = Model:Clone()
		Model:Destroy()
		Model = m
		
		local partHeap = Provider:GetHeap("Part")
		partHeap:SetDesiredAmount(numParts)
		local parts = partHeap:RequestInstances(numParts):expect()
		local count = 0
		local Assigns = {}
		for _, part in pairs(Model:GetDescendants()) do
			if part:IsA("Part") then
				count = count + 1
				


				local Properties = buildPropertyDictionary(partRef, part)
				if Properties == false then
					count -= 1
					continue
				end

				local hasAfter = false
				for _, v in ipairs(part:GetChildren()) do
					if Provider:GetHeap(v.ClassName) then
						hasAfter = true
						break
					end
				end
				
				local peePee = count
				
				local After = function()
					local ps = {}
					for _, v in ipairs(part:GetChildren()) do
						if Provider:GetHeap(v.ClassName) then
							
							local _, ins = Provider:RequestInstance(v.ClassName):await()
							local Properties = buildPropertyDictionary(ins, v)
							
							if Properties == false then
								continue
							end
							
							Properties.Parent = nil
							local p = Cloud:SetProperties(ins, Properties):andThen(function()
								Cloud:SetProperties(ins, {
									Parent = peePee
								})
							end)
							table.insert(ps, p)
						end
					end
					return Promise.all(ps)
				end
			
				Properties.Parent = Parent
				table.insert(Assigns, {part, parts[count], Properties, hasAfter and After or nil})
				
			end
		end
		
		print(count)
		
		local centre = Model:GetBoundingBox()
		
		-- sort assigns by distance to model pivot and size of part
		table.sort(Assigns, function(a, b)
			local A, B = a[1], b[1]
			
			local distA = (A.Position - centre.p).Magnitude
			local distB = (B.Position - centre.p).Magnitude
			
			local sizeA = A.Size.X * A.Size.Y * A.Size.Z
			local sizeB = B.Size.X * B.Size.Y * B.Size.Z
			
			return (distA - sizeA) > (distB - sizeB)
		end)
		
		local spawner = useDefer and task.defer or task.spawn
		
		local ctr = 0
		
		
		local afters = {}
		local Promises = {}
		repeat
		
		if #Assigns == 0 then break end
		local _, p, prop, after = unpack(table.remove(Assigns))
		ctr = ctr + 1
		afters[ctr] = after
		local promise = Cloud:SetProperties(p, prop)
		table.insert(Promises, promise)
		if ctr%batchSize == 0 then
			Promise.all(Promises):await()
			Promises = {}
			task.wait(batchSleep)
		end
		


			
		until #Assigns == 0 
		Promise.all(Promises):await()
		for _, after in pairs(afters) do
			after():await()
		end
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

function ModelImporter:CreateParts(Cloud, Num)
	
end

function ModelImporter:CreatePart(P1, Part, Parent, Flag)
	return Promise.new(function(res, rej)
		if (PropertyDict[Part.ClassName] == nil) then
			rej(warn("Class not supported", Part.ClassName))
		end
		
        local Properties = {}
        for _, Property in ipairs(PropertyDict[Part.ClassName]) do
            Properties[Property] = Part[Property]
        end
        Properties.Parent = Parent



        self._cloud:SetProperties(P1, Properties)
    end)
end

return ModelImporter