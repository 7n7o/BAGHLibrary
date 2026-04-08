local Promise = require("@pkg/Promise")
local InstanceHeap = require("./InstanceHeap")

local InstanceProvider = {}
InstanceProvider.__index = InstanceProvider

function InstanceProvider.new(Heaps)
	local self = setmetatable({
		_heaps = {}
	}, InstanceProvider)
	
	for k, Heap in pairs(Heaps) do
		local index = Heap.Name
		if typeof(k) == "string" then
			index = k
		end
		
		self._heaps[index] = Heap
	end
	
	return self
end


function InstanceProvider:AddHeap(Heap, Name)
	self._heaps[Name or Heap.Name] = Heap
end

function InstanceProvider:RequestInstances(Name, Amount)
	return Promise.new(function(res, rej)
		local Heap = self:GetHeap(Name)
		if not Heap then
			rej("Heap "..Name.." does not exist")
		end
		
		if not Heap:CanFulfill(Amount) then
			Heap:SetDesiredAmount(Heap:GetDesiredAmount() * 2)
			
			print("Increasing capacity of heap "..Name)
			
			self:RequestInstances(Name, Amount):andThen(res, rej)
			return
		end
		
		Heap:RequestInstances(Amount, true):andThen(res, rej)
	end)
end

function InstanceProvider:RequestInstance(Name)
	return self:RequestInstances(Name, 1):andThen(function(Instances)
		return Instances[1]
	end)
end

function InstanceProvider:SetDesiredAmount(Name, Amount)
	local Heap = self:GetHeap(Name)
	if not Heap then
		error("Heap "..Name.." does not exist")
	end
	Heap:SetDesiredAmount(Amount)
end

function InstanceProvider:GetHeap(Name)
	return self._heaps[Name]
end

return InstanceProvider