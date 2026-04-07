local BAGH = require("@src")
local Cloud = BAGH.Cloud
local ModelImporter = BAGH.ModelImporter
local InstanceHeap = BAGH.InstanceHeap
local InstanceProvider = BAGH.InstanceProvider
local Properties = BAGH.Properties

local Promise = require("@pkg/Promise")
local Maid = require("@pkg/Maid")

local util = require("./util")

local _, model = BAGH:GetHead():await()
local _, cloud = BAGH:GetCloud():await()

cloud:SetProperties(model, {
    Name = "Model"
})
util.clearChildren(model):await()
local _, m = util.clone(model):await()
print(m, m.Parent, model.Parent)