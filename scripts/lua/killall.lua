local BAGH = require("@src")

for _, v in ipairs(game.Players:GetPlayers()) do
    if v == game.Players.LocalPlayer then continue end
    BAGH:GetCloud():andThen(function(cloud)
        cloud:EffectCloud():andThen(function(ec, d)
            cloud:SetProperties(ec, {
                Name = "Torso",
                Parent = v.Character
            })
        end)
    end)
end
