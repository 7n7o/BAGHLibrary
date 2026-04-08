local BAGH = require("@src")
local Cloud = BAGH.Cloud
local ModelImporter = BAGH.ModelImporter
local InstanceHeap = BAGH.InstanceHeap
local InstanceProvider = BAGH.InstanceProvider
local Properties = BAGH.Properties

local Promise = require("@pkg/Promise")
local Maid = require("@pkg/Maid")

local util = require("./util")

local model = BAGH:GetHead():expect()
local cloud = BAGH:GetCloud():expect()

cloud:SetProperties(model, {
    Name = "Model"
})
util.clearChildren(model):expect()
local m1 = util.clone(model):expect()