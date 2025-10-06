if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports.es_extended:getSharedObject()

function HasPermission(permissions)
    local playerData = ESX.GetPlayerData()
    for _, data in pairs(permissions) do
        if playerData.job.name == data.value then
            return true
        end
    end
    return false
end

RegisterNetEvent("esx:setJob")
AddEventHandler('esx:setJob', function(job, lastJob)
    RefreshBlips()
end)