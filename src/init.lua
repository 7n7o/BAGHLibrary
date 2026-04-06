local BAGH = require("./BAGH")
local Cloud = require("./Cloud")
local ModelImporter = require("./ModelImporter")
local InstanceHeap = require("./InstanceHeap")
local InstanceProvider = require("./InstanceProvider")
local Maid = require("@pkg/Maid")
local Promise = require("@pkg/Promise")
local Properties = require("./Properties")

return setmetatable({
        Cloud=Cloud,
        ModelImporter=ModelImporter,
        InstanceHeap=InstanceHeap,
        InstanceProvider=InstanceProvider,
        Maid=Maid,
        Promise=Promise,
        Properties=Properties
    }, {
    __index = function(self, key)
        return BAGH[key]
    end
})