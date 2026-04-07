local BAGH = require("@src")

local Promise = require("@pkg/Promise")

local LocalPlayer = game.Players.LocalPlayer

local function clone(instance, parent)
    local originalParent = instance.Parent
    return Promise.new(function(res, rej)
        BAGH:GetCloud():andThen(function(cloud)
            cloud:SetProperties(instance, {
                Parent = cloud._tool.Handle
            }):andThen(function()

                cloud:EffectCloud():andThen(function(ec, d)
                    local i = ec:FindFirstChild(instance.Name)
                    cloud:SetProperties(instance, {
                        Parent = originalParent
                    }):catch(rej)

                    cloud:SetProperties(i, {
                        Parent = parent or LocalPlayer.Character
                    }):andThen(function()
                        d()
                        res(i)
                    end):catch(rej)
                end):catch(rej)

            end):catch(rej)
        end):catch(rej)
    end)
end

return clone