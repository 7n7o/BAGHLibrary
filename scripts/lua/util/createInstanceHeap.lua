local BAGH = require("@src")

local ModelImporter = BAGH.ModelImporter
local InstanceHeap = BAGH.InstanceHeap
local InstanceProvider = BAGH.InstanceProvider
local Properties = BAGH.Properties

local Promise = require("@pkg/Promise")

local clone = require("@util/clone")
local clearChildren = require("@util/clearChildren")

local function createInstanceHeap(instance, model, props, name)
    return Promise.new(function(res, rej)
        local _, Cloud = BAGH:GetCloud(false, false):catch(rej):await()
        local _, cl = clone(instance):catch(rej):await()
        print(cl)
        Cloud:SetProperties(cl, props):catch(rej)
        clearChildren(cl):andThen(function()
            res(InstanceHeap.new(Cloud, cl, model, name))
        end):catch(rej)
    end)

end

return createInstanceHeap