
## Give me an example

### Loading the library
The recommended way to load the library is via rbxm-suite:
```lua
local rbxmSuite = loadstring(game:HttpGetAsync("https://github.com/richie0866/rbxm-suite/releases/latest/download/rbxm-suite.lua"))()
local path = rbxmSuite.download("7n7o/BAGHLibrary@snapshot", "BAGHLibrary.rbxm")
local Library = rbxmSuite.launch(path).BAGHLibrary

local require = rbxmSuite.require

local Promise = require(Library.Promise)

local BAGH = require(Library)
local Cloud = require(Library.Cloud)
local ModelImporter = require(Library.ModelImporter)
local InstanceHeap = require(Library.InstanceHeap)
local InstanceProvider = require(Library.InstanceProvider)
```


### Simple kill

#### Async Version
```lua
--... Load in the library

local Target = "7n7o"

-- Get a cloud
Library:GetCloud():andThen(function(Cloud)
    --Create an effect cloud
    Cloud:EffectCloud():andThen(function(EffectCloud, DestroyEC)
        --Set the effect cloud's name to head and parent to target's character which will kill them
        Cloud:SetProperties(EffectCloud, {
          Parent = game.Players[Target].Character,
          Name = "Head"
        }):andThen(DestroyEC) -- Instantly destroy it once completed.
    end)
end)
```

#### Synchronous Version
```lua
--... Load in the library

local Target = "7n7o"

-- Get a cloud
local _, Cloud = Library:GetCloud():await()

--Create an effect cloud
local _, EffectCloud, DestroyEC = Cloud:EffectCloud():await()
--Set the effect cloud's name to "Head" and parent to target's character which will kill them
Cloud:SetProperties(EffectCloud, {
    Parent = game.Players[Target].Character,
    Name = "Head"
}):await()
-- Destroy the effect cloud
DestroyEC()
```
