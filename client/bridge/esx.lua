local ESX = exports.es_extended:getSharedObject()

---@type FrameworkBridge
local Bridge = {}

---@param names string[]
---@return boolean
function Bridge.hasGroup(names)
    local player = ESX.GetPlayerData()
    local job = player and player.job and player.job.name

    for _, name in ipairs(names) do
        if name == job then return true end
    end

    return false
end

---@param cb fun()
function Bridge.onGroupChange(cb)
    RegisterNetEvent('esx:playerLoaded', cb)
    RegisterNetEvent('esx:setJob', cb)
end

return Bridge
