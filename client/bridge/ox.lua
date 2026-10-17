local Ox = require '@ox_core.lib.init'

---@type FrameworkBridge
local Bridge = {}

---@param names string[]
---@return boolean
function Bridge.hasGroup(names)
    local player = Ox.GetPlayer()
    if not player then return false end

    for _, name in ipairs(names) do
        if player.getGroup(name) then return true end
    end

    return false
end

---@param cb fun()
function Bridge.onGroupChange(cb)
    AddEventHandler('ox:playerLoaded', cb)
    AddEventHandler('ox:setGroup', cb)
end

return Bridge
