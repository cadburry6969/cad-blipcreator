local QBCore = exports['qb-core']:GetCoreObject()

---@type FrameworkBridge
local Bridge = {}

---@param names string[]
---@return boolean
function Bridge.hasGroup(names)
    local player = QBCore.Functions.GetPlayerData()
    if not player then return false end

    local job = player.job and player.job.name
    local gang = player.gang and player.gang.name

    for _, name in ipairs(names) do
        if name == job or name == gang then return true end
    end

    return false
end

---@param cb fun()
function Bridge.onGroupChange(cb)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', cb)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', cb)
    RegisterNetEvent('QBCore:Client:OnGangUpdate', cb)
end

return Bridge
