# Boys And Girls Hangout Library
written by 7n7o
uses rbxm-suite

## Getting Started

To load the library you can use
```lua
local Library = loadstring(game:HttpGetAsync"https://raw.githubusercontent.com/7n7o/BAGHLibrary/master/main.lua")()
```

## Documentation

### Classes

#### Cloud

Clouds are objects that allow you to change the properties of anything that is a descendant of your character

```lua
<Cloud> Cloud.new(Tool)
``` 
*Returns a cloud class for the specified tool*

```lua
<Promise<Instance>> Cloud:SetProperties(Instance, PropertyTable)
``` 
*Changes the properties of *`Instance`* to the ones described in *`PropertyTable`*, promise is resolved after all properties have been changed.*

```lua
<Promise<EffectCloud>> Cloud:EffectCloud()
```
*Returns an *`EffectCloud`* class*

```lua
<Promise<Part>> Cloud:CreatePart(Parent, PropertyTable)
```
*Creates a Part with the properties described in *`PropertyTable`*, promise is resolved after all properties have been changed.*

#### EffectCloud

Effect clouds are temporary instances that must always be destroyed

```lua
<EffectCloud> EffectCloud.new(Cloud)
```
*Use* `Cloud:EffectCloud()`


```lua
<Promise<EffectCloud>> EffectCloud:SetProperties(PropertyTable)
```
*Same as calling* `Cloud:SetProperties(EffectCloudInstance, PropertyTable)`

```lua
<void> EffectCloud:Destroy()
```
*Destroys the EffectCloud*

### Module functions
```lua
<Promise<Cloud>> module:GetCloud()
```
*Gets a Cloud*

```lua
<Promise<Model>> module:GetHead()
```
*Creates a roleplay name model and returns it*

```lua
<Promise<Tool>> module:GetTool(Name)
```
*Gives you the specified tool*


### Model Importer

Module for importing models into the game

```lua
<Promise<Model>> ModelImporter:Import(Filepath, Parent, Cloud)
```
*Imports the rbxm model and returns it*

```lua
<Promise<Model>> ModelImporter:ImportObjects(Objects, Parent, Cloud)
```
*Imports the objects gvien as a table of Instances, will copy any parts to the server* 

```lua
<Promise<Model>> ModelImporter:ImportModel(Model, Parent, Cloud)
```
*Same as* `ImportObjects` *but only uses a Model*


## Give me an example

### Simple kill

#### Async Version
```lua
-- Load in the library
local Library = loadstring(game:HttpGetAsync"https://raw.githubusercontent.com/7n7o/BAGHLibrary/master/main.lua")()

local Target = "7n7o"

-- Get a cloud
Library:GetCloud():andThen(function(Cloud)
    --Create an effect cloud
    Cloud:EffectCloud():andThen(function(EffectCloud)
        --Set the effect cloud's name to head and parent to target's character which will kill them
        EffectCloud:SetProperties({
          Parent = game.Players[Target].Character,
          Name = "Head"
        }):andThen(function()
            -- Destroy the effect cloud instantly
            EffectCloud:Destroy() 
        end)
    end)
end)
```

#### Synchronous Version
```lua
-- Load in the library
local Library = loadstring(game:HttpGetAsync"https://raw.githubusercontent.com/7n7o/BAGHLibrary/master/main.lua")()

local Target = "7n7o"

-- Get a cloud
local _, Cloud = Library:GetCloud():await()

--Create an effect cloud
local _, EffectCloud = Cloud:EffectCloud():await()
--Set the effect cloud's name to "Head" and parent to target's character which will kill them
EffectCloud:SetProperties({
    Parent = game.Players[Target].Character,
    Name = "Head"
   }):await()
-- Destroy the effect cloud
EffectCloud:Destroy() 
```

## How does it work
dm me for a more in depth tutorial
`7n7o#0010`
