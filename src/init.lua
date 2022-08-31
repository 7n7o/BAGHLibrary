local Promise = require(script.Promise)

local Cloud = require(script.Cloud)

local BAGH = {}

local Players = game:FindService("Players")
local LocalPlayer = Players.LocalPlayer

function BAGH:GetCloud()
    return Promise.new(function(res, rej)
        local Character = LocalPlayer.Character
        local Backpack = LocalPlayer.Backpack
        if Backpack:FindFirstChild("Homebrew_Cloud") then
            res(Cloud.new(Backpack.Homebrew_Cloud))
        end
        if Character:FindFirstChild("Homebrew_Cloud") then
            res(Cloud.new(Character.Homebrew_Cloud))
        end
        self:GetTool("PompousTheCloud"):andThen(function(tool) res(Cloud.new(tool)) end):catch(rej)
    end)
end

function BAGH:GetHead()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer.Backpack
    return Promise.new(function(res, rej)
        workspace.GuiEvent:FireServer("Hvmebrew")
        local Model = Character:WaitForChild("Hvmebrew", 5)
        if Model then res(Model) else rej() end 
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
                task.defer(function()
                    res(child)
                end)
            end
        end)
    end)
end

function BAGH:CreateModel(Name, Parent)
    return Promise.new(function(res, rej)
        BAGH:GetHead():andThen(function(Model)
            self:GetCloud():SetProperties(Model, {
                Parent = Parent,
                Name = Name
            }):andThen(function(Model)
                self:GetCloud():SetProperties(Model.Humanoid, {
                    DisplayName = ""
                }):andThen(function(H)
                    res(H.Parent)
                end):catch(rej)
            end):catch(rej)
        end):catch(res)
    end)
end

return BAGH