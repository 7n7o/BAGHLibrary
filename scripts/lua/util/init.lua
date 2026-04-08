
local clone = require("./clone")
local clearChildren = require("./clearChildren")
local createInstanceHeap = require("./createInstanceHeap")
return {
    clone = clone,
    clearChildren = clearChildren,
    createInstanceHeap = createInstanceHeap
}