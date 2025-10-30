if GetResourceState('ox_core') ~= 'started' then return end

local Ox = require '@ox_core/lib/init'

function HasPermission(permissions)
    local player = Ox.GetPlayer()
    for _, data in pairs(permissions) do
        if player.getGroup(data.value) then
            return true
        end
    end
    return false
end

AddEventHandler('ox:playerLoaded', function(playerId, isNew)
    RefreshBlips()
end)

AddEventHandler('ox:setGroup', function(playerId, groupName, grade)
    RefreshBlips()
end)