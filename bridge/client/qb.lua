if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function HasPermission(permissions)
    local playerData = QBCore.Functions.GetPlayerData()
    for _, data in pairs(permissions) do
        if playerData.job.name == data.value or playerData.gang.name == data.value then
            return true
        end
    end
    return false
end
