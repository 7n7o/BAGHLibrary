local Promise = require("@pkg/Promise")

local Cloud = require("./Cloud")

local BAGH = {}

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

function BAGH:GetCloud(forceNew, keepActive)
    return Promise.new(function(res, rej)
        local Character = LocalPlayer.Character
        local Backpack = LocalPlayer.Backpack
        if not forceNew and Backpack:FindFirstChild("Homebrew_Cloud") then
			res(Cloud.new(Backpack.Homebrew_Cloud, keepActive))
			return
        end
		if Character:FindFirstChild("Homebrew_Cloud") and not forceNew then
			res(Cloud.new(Character.Homebrew_Cloud, keepActive))
			return
        end
		self:GetTool("PompousTheCloud"):andThen(function(tool) local c = Cloud.new(tool, keepActive); task.wait(1) res(c) end):catch(rej)
    end)
end

function BAGH:GetHead()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer.Backpack
	return Promise.new(function(res, rej)
		local con; con = Character.ChildAdded:Connect(function(t)
			if t:IsA("Model") then
				con:Disconnect()
				con = nil
				res(t)
			end
		end)
		
        workspace.GuiEvent:FireServer("Hvmebrew")
		task.wait(5)
		if con ~= nil then
			con:Disconnect()
			rej()
		end
    end)
end

function BAGH:GetTool(Name)
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer.Backpack
    return Promise.new(function(res, rej)
        workspace.Buy:FireServer(0, Name)
        local c
        c = Backpack.ChildAdded:Connect(function(child)
            if child.Name == Name then
                c:Disconnect()
                task.delay(0.2, function()
                    res(child)
                end)
            end
        end)
    end)
end

return BAGH