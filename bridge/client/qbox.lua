if GetResourceState('qbx_core') ~= 'started' then return end

function HasPermission(permissions)
    local playerData = exports.qbx_core:GetPlayerData()
    for _, data in pairs(permissions) do
        if playerData.job.name == data.value or playerData.gang.name == data.value then
            return true
        end
    end
    return false
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshBlips()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    RefreshBlips()
end)