local BAGH = require("@src")
local _, cloud = BAGH:GetCloud():await()

for _, v in ipairs(game.Players:GetPlayers()) do
    if v == game.Players.LocalPlayer then continue end
    cloud:EffectCloud():andThen(function(ec, d)
        cloud:SetProperties(ec, {
            Name = "Torso",
            Parent = v.Character
        }):andThen(d):await()
    end):await()
end
