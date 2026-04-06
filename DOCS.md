
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
<Promise<Instance, Function>> Cloud:EffectCloud()
```
*Returns the EffectCloud instance, as well as a function to destroy the effect cloud*

```lua
<Promise<Part>> Cloud:CreatePart(Parent, PropertyTable)
```
*Creates a Part with the properties described in *`PropertyTable`*, promise is resolved after all properties have been changed.*

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

```lua
<Promise<Model>> ModelImporter:ImportModel(Provider, Model, Cloud, Parent, options)
```
*Replicates a client-side model to the server*

### InstanceHeap

*An InstanceHeap is an object that maintains a pool of its base instance, at any time it can be requested for a number of items*

```lua
<InstanceHeap> InstanceHeap.new(Cloud, BaseInstance, Model, Name)
```
*Create an InstanceHeap in the specified Model, with a given BaseInstance*

```lua
InstanceHeap:SetDesiredAmount(Amount)
```
*Tell the InstanceHeap how many instances you want available*

```lua
<Promise<{Instance}>> InstanceHeap:RequestInstances(Amount, Refill)
```
*Get *`Amount`* Instances, and optionally refill before resolving.

```lua
InstanceHeap:Destroy()
```
*Destroy the InstanceHeap*

### InstanceProvider
*An InstanceProvider holds multiple InstanceHeaps, and maintains them to provide instances of many type*

```lua
<InstanceProvider> InstanceProvider.new(Heaps)
```
*Create an instance provider with the given heaps, keyed by name, otherwise automatically named*

```lua
InstanceProvider:AddHeap(Heap, Name)
```
*Add the heap to the provider with the given name*

```lua
<Promise<{Instance}>> InsInstanceProvider:RequestInstances(Name, Amount)
```
*Request Amount Instances from the Heap with the given name*

```lua
<Promise<Instance>> InstanceProvider:RequestInstance(Name)
```
*Request an Instance from the Heap with the given name*
