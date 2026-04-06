--[=[
    @class InstanceHeap
]=]
local InstanceHeap = {}
InstanceHeap.__index = InstanceHeap

local Promise = require("@pkg/Promise")

--[=[
    @within InstanceHeap
    @function new
    @param F3X F3X
    @param BaseInstances {T}
    @param Parent Instance

    @return InstanceHeap<{T}>
]=]
function InstanceHeap.new(Cloud, BaseInstance, Model, Name)
	local self = setmetatable({
		_cloud = Cloud,
		_heap = {},
		_model = Model,
		Name = Name or BaseInstance.ClassName,
	}, InstanceHeap)



	self._heap = { 
		Instances = { BaseInstance }, 
		DesiredAmount = 1,
		FulfillingRequest = false 
	}
	
	Cloud:SetProperties(BaseInstance, {Parent = Model})
	Cloud:SetProperties(Model, {Name = self.Name, Parent = Cloud._tool.Handle}):await()

	return self
end
--[=[
    @within InstanceHeap
    @method SetDesiredAmount
    @param ClassName string
    @param Amount amount
]=]
function InstanceHeap:SetDesiredAmount(Amount)
	local Heap = self._heap

	Heap.DesiredAmount = Amount
	self:_updateAmount()
end

function InstanceHeap:GetDesiredAmount()
	return self._heap.DesiredAmount
end

function InstanceHeap:_doubleIt()
	return self._cloud:EffectCloud():andThen(function(e)
		local ps = {}
		local is = {}
		for _,v in ipairs(e:WaitForChild(self._model.Name):GetChildren()) do
			local p = self._cloud:SetProperties(v, {Parent = self._model})
			table.insert(ps, p)
			table.insert(is, v)
		end
		Promise.all(ps):await()
		return is
	end)
end

function InstanceHeap:_updateAmount()
	local Heap = self._heap

	if Heap.FulfillingRequest then
		repeat task.wait() until Heap.FulfillingRequest == false
	end

	Heap.FulfillingRequest = true

	local cloud = self._cloud
	local Instances = Heap.Instances
	local amt = Heap.DesiredAmount + 1
	if not (#Instances >= amt) then
		if #Instances < amt / 2  then
			repeat
				local _,clones = self:_doubleIt():await()
				for _, v in ipairs(clones) do table.insert(Instances, v) end
			until #Instances >= amt
		end
	end
	Heap.FulfillingRequest = false
	print("Succesfully refilled heap for "..self.Name.." to "..#Instances)
end


--[=[
    @within InstanceHeap
    @method RequestInstances
    @param ClassName string
    @param Amount number
    @param Refill boolean

    @return Promise<{T}, Promise>
]=]
function InstanceHeap:RequestInstances(Amount, Refill)
	return Promise.new(function(res, rej)
		local Heap = self._heap
		if Heap.FulfillingRequest then
			repeat task.wait() until Heap.FulfillingRequest == false
		end

		if not self:CanFulfill(Amount) then
			rej("Not enough instances in heap.")
			return
		end

		local Instances = {}
		for _ = 1, Amount do 
			local i = table.remove(Heap.Instances)
			self._cloud:SetProperties(i, {Parent = self._cloud._tool.Script})
			table.insert(Instances, i) 
		end
		local onRefill
		if Refill then onRefill = Promise.new(function(res) self:_updateAmount() res() end) end
		res(Instances, onRefill)
	end)
end

function InstanceHeap:CanFulfill(Amount)
	local Heap = self._heap
	if Heap.FulfillingRequest then
		repeat task.wait() until Heap.FulfillingRequest == false
	end
	
	return not (Amount > #Heap.Instances - 1)
end


--[=[
    @within InstanceHeap
    @method Destroy
]=]
function InstanceHeap:Destroy()
	--local heaps = self._heap
	--local toRemove = {}
	--for _,heap in ipairs(heaps) do
	--	for _ = 1, #heap.Instances do table.insert(toRemove, table.remove(heap.Instances)) end
	--end
	self._cloud:Destroy()
end

return InstanceHeap
