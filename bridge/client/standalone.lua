if GetResourceState('es_extended') ~= 'missing' then return end
if GetResourceState('ox_core') ~= 'missing' then return end
if GetResourceState('qb-core') ~= 'missing' then return end
if GetResourceState('qbx_core') ~= 'missing' then return end

AddEventHandler('playerSpawned', function()
    RefreshBlips()
end)