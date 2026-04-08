-- local BAGH = require("@src")
-- local Cloud = BAGH.Cloud
-- local ModelImporter = BAGH.ModelImporter
-- local InstanceHeap = BAGH.InstanceHeap
-- local InstanceProvider = BAGH.InstanceProvider
-- local Properties = BAGH.Properties

-- local Promise = require("@pkg/Promise")
-- local Maid = require("@pkg/Maid")

local rbxmSuite = loadstring(game:HttpGet("https://github.com/richie0866/rbxm-suite/releases/latest/download/rbxm-suite.lua"))()
local path = rbxmSuite.download("7n7o/BAGHLibrary@snapshot", "BAGHLibrary_prod.rbxm")
local Model = rbxmSuite.launch(path)
local Packages, Library = Model.Packages, Model.Library

local require = rbxmSuite.require

local BAGH = require(Library)
local Cloud = require(Library.Cloud)
local ModelImporter = require(Library.ModelImporter)
local InstanceHeap = require(Library.InstanceHeap)
local InstanceProvider = require(Library.InstanceProvider)

local Promise = require(Packages.Promise)

local util = require("@util")
local model_dragger = require("./model_dragger")

local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character

local model = BAGH:GetHead():expect()
local cloud = BAGH:GetCloud(false, false):expect()
cloud._tool.Parent = Character

cloud:SetProperties(model, {
    Name = "Model"
})
util.clearChildren(model):expect()

local modelHeap = util.createInstanceHeap(model, model, {
    Name = "Model",
}):expect()

local Provider = InstanceProvider.new({
    modelHeap
})

local function addToProvider(Heap)
    Provider:AddHeap(Heap)
end

local function createNewHeap(instance, props)
    return util.createInstanceHeap(instance, Provider:RequestInstance("Model"):expect(), props):andThen(addToProvider)
end
local nc = BAGH:GetCloud(true):expect()

nc:EffectCloud():andThen(function(ec, d)
    
    
    local pInst = Instance.new("Part")
    local propTable = {}
    for _, prop in ipairs(Properties.Part) do
        
        if ec[prop] ~= pInst[prop] then
           propTable[prop] = pInst[prop] 
        end
    end
    local cl = util.clone(ec):expect()
    util.clearChildren(cl):expect()
    nc:SetProperties(cl, {
        Size = Vector3.new(1024, 12, 1024),
        Anchored = true,
        CanCollide = true,
        CFrame = CFrame.new(0, 10e5, 0),
        Name = "pOpBOb HaS hACkeD ThIs SeRvER",
        Parent = workspace
    }):await()
    propTable.CFrame = cl.CFrame * CFrame.new(0, 6 + propTable.Size.Y / 2, 0)
    propTable.Velocity = Vector3.new(0,0,0)
    propTable.Anchored = false
    propTable.CanCollide = false
    Promise.all({
        createNewHeap(ec:FindFirstChild("Weld"), {
            Part0 = ec,
            Part1 = ec,
            C0 = CFrame.new(),
            C1 = CFrame.new()
        }),
        createNewHeap(ec:FindFirstChild("Mesh"), {
            MeshId = "rbxassetid://0",
            Scale = Vector3.new(1,1,1),
            TextureId = "rbxassetid://0",
        }),
        createNewHeap(ec, propTable),
        createNewHeap(util.clone(Character.Torso.roblox):expect(), {
            Color3 = Color3.new(1,1,1),
            Texture = "",
            Transparency = 0,
            Name = "Decal",
        })
    }):await()
    d()
end):await()

nc:Destroy()



local object = Instance.new("Model")
for _, v in game:GetObjects(getcustomasset("Brainrot.rbxm")) do
    v.Parent = object
end

for _, v in ipairs(object:GetDescendants()) do
    if v:IsA("BasePart") then
        v.Anchored = true
    end
end
object.Parent = workspace
local _,size = object:GetBoundingBox()
object:MoveTo((Character.HumanoidRootPart.CFrame * CFrame.new(0, size.Y*2, 0)).Position)
local model_dragger_maid
task.delay(3, function()
    model_dragger_maid = model_dragger(object)
end)


local UIS = game:GetService("UserInputService")

local con; con = UIS.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.F10 then
        con:Disconnect()
        model_dragger_maid:Destroy()
        cloud._tool.Parent = Character
        task.wait()
        
        ModelImporter:ImportModel(Provider, object, cloud, 
        Provider:RequestInstance("Model"):andThen(function(m)
            cloud:SetProperties(m, {Name = "ImportedModel", Parent = workspace}):await()
            return m
        end):expect(), {
            useDefer = true,
            batchSize = 1000,
            batchSleep = 1
        })
    end
end)