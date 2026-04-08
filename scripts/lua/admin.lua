local BAGH = require("@src")
local Cloud = BAGH.Cloud
local ModelImporter = BAGH.ModelImporter
local InstanceHeap = BAGH.InstanceHeap
local InstanceProvider = BAGH.InstanceProvider
local Properties = BAGH.Properties

local Promise = require("@pkg/Promise")
local Maid = require("@pkg/Maid")



local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character

local num = 100

local _, model = BAGH:GetHead():await()
local _, Cloud = BAGH:GetCloud():await()
task.wait(1)
for _,v in ipairs(model:GetChildren()) do
	Cloud:SetProperties(v, {Parent = game.TestService})
end
print(model)
Cloud:SetProperties(model, {
	Parent = Cloud._tool.Handle,
	Name = "cache"
}):await()

local models = {}

for i = 1, 10 do
	Cloud:EffectCloud():andThen(function(e, delete)
		local s = e:WaitForChild("cache")
		models[i] = s
		Cloud:SetProperties(s, {Parent = Character}):await()
		delete()
	end):await()
end

local partCache, weldCache, meshCache, decalCache = table.remove(models), table.remove(models), table.remove(models), table.remove(models)

Cloud:SetProperties(partCache, {Name = "PartHeap"})
Cloud:SetProperties(weldCache, {Name = "WeldHeap"})
Cloud:SetProperties(meshCache, {Name = "MeshHeap"})
Cloud:SetProperties(decalCache, {Name = "DecalHeap"})


local function default(INST)
	local propNames = Properties[INST.ClassName]
	if propNames ~= nil then
		local d = Instance.new(INST.ClassName)

		local pTable = {}

		for _, name in propNames do
			if INST[name] ~= d[name] then
				pTable[name] = d[name]
			end
		end

		return Cloud:SetProperties(INST, pTable)
	end
end

local j = Cloud:EffectCloud():andThen(function (e)
	task.wait(1)
	Cloud:SetProperties(e, {
		Parent = partCache,
		Name = "Part",
		Anchored = true,
		CanCollide = false
	}):await()

	Cloud:SetProperties(e:WaitForChild("Weld"), {
		Parent = weldCache,
		C0 = CFrame.new(),
		C1 = CFrame.new(),
		Part0 = e,
		Part1 = e
	}):await()

	Cloud:SetProperties(e:WaitForChild("Mesh"), {
		Parent = meshCache,     
		Name = "SpecialMesh"   
	}):await()

	for _, v in ipairs(e:GetChildren()) do
		Cloud:SetProperties(v, {Parent = game.TestService}):await()
	end


	Cloud:SetProperties(e, { CFrame = CFrame.new(10000, 10000, 10000) })

end)

Cloud:SetProperties(Character.Torso.roblox, {
	Parent = decalCache,
	Name = "Decal"
})

j:await()
task.wait(0.5)
Cloud:Destroy()
task.wait(1)
local _, Cloud = BAGH:GetCloud():await()
task.wait(1)    
local partHeap = InstanceHeap.new(Cloud, partCache:WaitForChild("Part"), partCache)
local weldHeap = InstanceHeap.new(Cloud, weldCache:WaitForChild("Weld"), weldCache)
local meshHeap = InstanceHeap.new(Cloud, meshCache:WaitForChild("SpecialMesh"), meshCache)
local decalHeap = InstanceHeap.new(Cloud, decalCache:WaitForChild("Decal"), decalCache)


partHeap:SetDesiredAmount(100)
weldHeap:SetDesiredAmount(100)
meshHeap:SetDesiredAmount(100)
decalHeap:SetDesiredAmount(100)

function weld(cloud, heap, p0, p1, c0, c1)
	heap:RequestInstances(1):andThen(function(instances)
		local w = instances[1]
		cloud:SetProperties(w, {
			Part0 = p0,
			Part1 = p1,
			C0 = c0 or CFrame.new(),
			C1 = c1 or CFrame.new()
		})
	end)
end

local AmountParts = 0
for x = -20000, 20000, 2000 do
	for z = -20000, 20000, 2000 do
		AmountParts = AmountParts + 1
	end
end
print(AmountParts)
partHeap:SetDesiredAmount(AmountParts)


function moveUnanchored(effect, weld, p, cf)
	Cloud:SetProperties(weld, {
		Part0 = p,
	})
	Cloud:SetProperties(effect, {
		CFrame = cf
	})
end

local function EmptyMap()
	local _, Effect = Cloud:EffectCloud():await()
	local Weld = Effect:WaitForChild("Weld")

	for _,v in ipairs(game.Players:GetPlayers()) do
		moveUnanchored(Effect, Weld, v.Character.HumanoidRootPart, CFrame.new(0, 6e5, 0))
	end

	Cloud:SetProperties(Weld, {
		Part1 = Effect,
		C0 = CFrame.new(),
		C1 = CFrame.new()
	}):await()
	
	local mapOffset = CFrame.new(2384572938, -2580723845, 2348712348)

	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("SpawnLocation") then
			local cf = CFrame.new(0, 51, 0)
			moveUnanchored(Effect, Weld, v, cf)
		elseif not v:IsDescendantOf(Character) and v:IsA("BasePart") and v.Anchored then
			moveUnanchored(Effect, Weld, v, v.CFrame * mapOffset)    
		end
	end

	for _,v in ipairs(game.Players:GetPlayers()) do
		moveUnanchored(Effect, Weld, v.Character.HumanoidRootPart, CFrame.new(0, 60, 0))
	end
end

local function baseplate()
	local _, nCloud = BAGH:GetCloud(true):await()
	task.wait(.1)
	local _, Effect = nCloud:EffectCloud():await()
	local Weld = Effect:WaitForChild("Weld")
	
	for _,v in ipairs(game.Players:GetPlayers()) do
		moveUnanchored(Effect, Weld, v.Character.HumanoidRootPart, CFrame.new(0, 6e5, 0))
	end
	
	Cloud:SetProperties(Weld, {
		Part1 = Effect,
		C0 = CFrame.new(),
		C1 = CFrame.new()
	}):await()


	partHeap:RequestInstances(AmountParts,true):andThen(function(instances)
		for x = -20000, 20000, 2000 do
			for z = -20000, 20000, 2000 do
				local base = table.remove(instances)
				Cloud:SetProperties(base, {
					Anchored = true,
					Locked = true,
					BrickColor = BrickColor.Green(),
					Size = Vector3.new(2000, 16, 2000),
					Material = "Grass",
					CFrame = CFrame.new(x, 50, z),
					Parent = workspace,
					CanCollide = true,
					AssemblyLinearVelocity = Vector3.zero,
					AssemblyAngularVelocity = Vector3.zero
				})
			end
		end
	end)



	local mapOffset = CFrame.new(2384572938, -2580723845, 2348712348)

	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("SpawnLocation") then
			local cf = CFrame.new(0, 51, 0)
			moveUnanchored(Effect, Weld, v, cf)
		elseif not v:IsDescendantOf(Character) and v:IsA("BasePart") and v.Anchored then
			moveUnanchored(Effect, Weld, v, v.CFrame * mapOffset)    
		end
	end

	for _,v in ipairs(game.Players:GetPlayers()) do
		moveUnanchored(Effect, Weld, v.Character.HumanoidRootPart, CFrame.new(0, 60, 0))
	end
	
	task.wait(1)
	
	nCloud:Destroy()
end

local function kill(char)

	Cloud:EffectCloud():andThen(function(effectCloud, destroy)
		Cloud:SetProperties(effectCloud, {Parent = char, Name = "Head"}):andThen(destroy)
	end)

end

local function void(char)
	local _, Effect = Cloud:EffectCloud():await()
	local Weld = Effect:WaitForChild("Weld")

	moveUnanchored(Effect, Weld, char.HumanoidRootPart, CFrame.new(0, -6e5, 0))
end

local jailed = {}

local function jail(player)
	local _, pt = partHeap:RequestInstances(1):await()
	local _, mt = meshHeap:RequestInstances(1):await()
	
	local part = pt[1]
	local mesh = mt[1]
	
	local targetCF = CFrame.new(0,1000,0)
	
	if player.Character then
		targetCF = player.Character:GetPivot()
	end
	
	Cloud:SetProperties(mesh,{
		Scale = Vector3.new(1,1.8,1),
		MeshType = 'FileMesh',
		MeshId = 'rbxassetid://5092503663',
		TextureId = '',
		Parent = part
	})
	
	Cloud:SetProperties(part,{
		Size = Vector3.new(4,8,4),
		BrickColor = BrickColor.Random(),
		Transparency = .5,
		CanCollide = true,
		Anchored = true,
		CFrame = targetCF,
		Parent = Character,
		Name = 'a',
		CastShadow = false
	}):await()
	
	local function trap()
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		task.wait(1)
		for i = 1, 10 do
			weld(Cloud, weldHeap, part, root)
		end
	end
	
	trap()
	local con = player.CharacterAdded:Connect(trap)
	jailed[player.UserId] = {
		Part = part,
		Target = player,
		Connection = con
	}
end

local function Delete(Object)
	if not Object:IsDescendantOf(Character) then
		return warn(string.format("%s is not descendant of character", Object:GetFullName()))
	end
	return Cloud:SetProperties(Object,{
		Parent = game.TestService
	})
end

local function unjail(player)
	local data = jailed[player.UserId]
	if not data then return end
	local part = data.Part
	Cloud:SetProperties(part,{
		Parent = game.TestService
	}):await()
	pcall(function()
		data.Connection:Disconnect()
	end)
	jailed[player.UserId] = nil
	--kill(player.Character)
end

local Players = game:GetService("Players")

local commands = {}
commands.list = {}
commands.dict = {}

function commands:add_cmd(name, aliases, func, args)
	local cmd = {
		name = name,
		aliases = aliases or {},
		func = func,
		args = args or {}
	}
	table.insert(self.list, cmd)
	self.dict[name] = cmd

	for _,alias in ipairs(cmd.aliases) do
		self.dict[alias] = cmd
	end
end

function commands:find_command(name)
	return self.dict[name:lower()]
end


local function find_player(str, speaker)
	str = str:lower()

	if str == "me" then
		return speaker
	elseif str == "all" then
		return Players:GetPlayers()
	elseif str == "others" then
		local t = {}
		for _,p in ipairs(Players:GetPlayers()) do
			if p ~= speaker then
				table.insert(t, p)
			end
		end
		return t
	end

	for _,p in ipairs(Players:GetPlayers()) do
		if p.Name:lower():sub(1, #str) == str then
			return p
		end
	end
end

local function resolve_arg(argType, raw, speaker)
	if argType == "player" then
		return find_player(raw, speaker)
	elseif argType == "number" then
		return tonumber(raw)
	elseif argType == "string" then
		return raw
	end

	return raw
end

function commands:exec_command(speaker, name, rawArgs)
	local cmd = self:find_command(name)
	if not cmd then return end

	local resolved = {}

	for i, argType in ipairs(cmd.args) do
		local raw = rawArgs[i]
		if not raw then return end

		local val = resolve_arg(argType, raw, speaker)
		if not val then return end

		table.insert(resolved, val)
	end

	local function run(args)
		cmd.func(speaker, unpack(args))
	end

	local function expand(index, current)
		if index > #resolved then
			run(current)
			return
		end

		local val = resolved[index]

		if typeof(val) == "table" then
			for _,v in ipairs(val) do
				local new = table.clone(current)
				new[index] = v
				expand(index + 1, new)
			end
		else
			current[index] = val
			expand(index + 1, current)
		end
	end

	expand(1, {})
end

local prefix = '!'
local admins = {[123808010]=true}
admins[LocalPlayer.UserId] = true

commands:add_cmd('kill', {}, function(speaker, target)
	kill(target.Character)
end, {'player'})

commands:add_cmd('void', {}, function(speaker, target)
	void(target.Character)
end, {'player'})

commands:add_cmd('jail', {}, function(speaker, target)
	jail(target)
end, {'player'})

commands:add_cmd('unjail', {}, function(speaker, target)
	unjail(target)
end, {'player'})

commands:add_cmd('baseplate',{},function(speaker)
	baseplate()
end)

commands:add_cmd("rejoin", {}, function(speaker)
	local job = game.JobId
	game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, job, speaker)
end)

commands:add_cmd("fling", {}, function(speaker, target)
	local _, pt = partHeap:RequestInstances(1):await()
	local part = pt[1]
	Cloud:SetProperties(part,{
		AssemblyLinearVelocity = Vector3.new(500,500,500),
		AssemblyAngularVelocity = Vector3.new(500,500,500),
		CFrame = target.Character.HumanoidRootPart.CFrame,
		CanCollide = true,
		Anchored = false,
		Size = Vector3.new(4,4,4),
		Transparency = 0.5,
		BrickColor = BrickColor.Random(),
		Parent = Character,
		Name = 'Flinga'
	}):await()
	repeat
		local mv = (target.Character.HumanoidRootPart.AssemblyLinearVelocity * Vector3.new(1,0,1)).magnitude
		Cloud:SetProperties(part,{
			CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0,-2,-(mv/20))
		})
		task.wait()
	until target.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude >= 100
	task.delay(1, function()
		Delete(part)
	end)
end, {'player'})

commands:add_cmd("bring", {}, function(speaker, target)
	local _, nCloud = BAGH:GetCloud(true):await()
	task.wait(.1)
	local _, Effect = nCloud:EffectCloud():await()
	local Weld = Effect:WaitForChild("Weld")
	
	local targetRoot = target.Character.HumanoidRootPart
	moveUnanchored(Effect, Weld, targetRoot, speaker.Character.HumanoidRootPart.CFrame)
	task.delay(1, function()
		nCloud:Destroy()
	end)
end, {'player'})

commands:add_cmd("to", {}, function(speaker, target)
	local _, nCloud = BAGH:GetCloud(true):await()
	task.wait(.1)
	local _, Effect = nCloud:EffectCloud():await()
	local Weld = Effect:WaitForChild("Weld")

	local targetRoot = target.Character.HumanoidRootPart
	moveUnanchored(Effect, Weld, speaker.Character.HumanoidRootPart, targetRoot.CFrame)
	task.delay(1, function()
		nCloud:Destroy()
	end)
end, {'player'})

local flingbricks = {}

commands:add_cmd('flingbrick',{'fbrick','fb'}, function(speaker)
	local _, pt = partHeap:RequestInstances(1):await()
	local part = pt[1]
	Cloud:SetProperties(part,{
		AssemblyLinearVelocity = Vector3.new(500,500,500),
		AssemblyAngularVelocity = Vector3.new(500,500,500),
		CFrame = speaker.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-5),
		CanCollide = true,
		Anchored = false,
		Size = Vector3.new(4,4,4),
		Transparency = 0.5,
		BrickColor = BrickColor.Random(),
		Parent = Character,
		Name = 'Flinga'
	}):await()
	table.insert(flingbricks, part)
end)

commands:add_cmd('removeflingbricks',{'rbricks','rmbricks','rmfb'}, function(speaker)
	for i,v in pairs(flingbricks) do
		if v == nil then
			continue
		end
		local p = Delete(v)
		p:await()
	end
	print("removed bricks")
	table.clear(flingbricks)
end)

local function chat_hook(plr)
	plr.Chatted:Connect(function(msg)
        print(msg, admins[plr.UserId], prefix)
		if msg:sub(1,1) ~= prefix then return end
        print("prefix")
		if not admins[plr.UserId] then return end
        print("PASS", msg)
		local split = msg:sub(2):split(" ")
		local cmdName = split[1]
		table.remove(split, 1)

		commands:exec_command(plr, cmdName, split)
	end)
end

-- hook existing + future players
for _,p in ipairs(Players:GetPlayers()) do
	chat_hook(p)
end

Players.PlayerAdded:Connect(chat_hook)

for i,v in pairs(Character:GetDescendants()) do
	local ancestorTool = v:FindFirstAncestorWhichIsA("Tool")
	if ancestorTool then
		if v:IsA("Sound") then
			Cloud:SetProperties(v,{
				Volume=0,
				Looped=false
			})
		elseif v:IsA("Smoke") then
			Cloud:SetProperties(v,{
				Parent = game.TestService
			})
		end
	end
end

print("admin ready")