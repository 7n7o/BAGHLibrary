## Info
This is a library to interface with a vulnerable version of the pompous the cloud gear found in some roblox games.

## Building
To build the RBXM run build.sh <(dev|prod|all)?>
To build the bundle run bundle.sh <(dev|prod|all)?>

### Scripts
To build a script bundle, run scripts/bundle.sh <script name> <(dev|prod|all)?>
Example: `scripts/bundle.sh killall dev`

## Loading the library
The recommended way to load the library is via rbxm-suite:
```lua
local rbxmSuite = loadstring(game:HttpGet("https://github.com/richie0866/rbxm-suite/releases/latest/download/rbxm-suite.lua"))()
local path = rbxmSuite.download("7n7o/BAGHLibrary@latest", "BAGHLibrary_prod.rbxm")
local Model = rbxmSuite.launch(path)
local Packages, Library = Model.Packages, Model.Library

local require = rbxmSuite.require

local BAGH = require(Library)
local Cloud = require(Library.Cloud)
local ModelImporter = require(Library.ModelImporter)
local InstanceHeap = require(Library.InstanceHeap)
local InstanceProvider = require(Library.InstanceProvider)

local Promise = require(Packages.Promise)
```

You may also load it via the bundle:
```lua
local BAGH = loadstring(game:HttpGet("https://github.com/7n7o/BAGHLibrary/releases/latest/download/bundle.prod.lua"))()
local Cloud = BAGH.Cloud
local ModelImporter = BAGH.ModelImporter
local InstanceHeap = BAGH.InstanceHeap
local InstanceProvider = BAGH.InstanceProvider

local Promise = BAGH.Promise
```