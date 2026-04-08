local BAGH = require("@src")

local Promise = require("@pkg/Promise")

local function clearChildren(instance, parent)
    return Promise.new(function(res, rej)
        BAGH:GetCloud(false, false):andThen(function(cloud)
            local ps = {}
            for _, v in ipairs(instance:GetChildren()) do
                ps[#ps+1] = cloud:SetProperties(v, {Parent = parent or game.TestService})
            end
            Promise.all(ps):andThen(res):catch(rej)
        end):catch(rej)
    end)
end

return clearChildren