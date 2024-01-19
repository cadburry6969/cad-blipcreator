local resourceName = GetCurrentResourceName()
local Blips = {}

-- update the blips to json file and state bag
local function saveBlips()
    GlobalState.blips = Blips
    SaveResourceFile(resourceName, 'blips.json', json.encode(Blips, { indent = true }), -1)
end

-- initially load the blips to the local table
CreateThread(function()
    Wait(100)
    local blipsData = json.decode(LoadResourceFile(resourceName, 'blips.json'))
    if type(blipsData) == 'table' then
        Blips = blipsData
    else
        SaveResourceFile(resourceName, 'blips.json', '[]', -1)
        Blips = {}
    end
    GlobalState.blips = Blips
end)

-- save the created blip to file and add the local table
RegisterNetEvent('cad-blipcreator:saveBlip', function(_uniqueId, data)
    local uniqueId = _uniqueId or os.time()
    Blips[uniqueId] = data
    Wait(100)
    saveBlips()
end)

-- remove the blip with certain uniqueId
RegisterNetEvent('cad-blipcreator:removeBlip', function(uniqueId)
    if Blips[uniqueId] then
        Blips[uniqueId] = nil
        Wait(100)
        saveBlips()
    end
end)

-- command to open blip manager
lib.addCommand('blipcreator', {
    help = 'Create blips without server restart',
    restricted = Config.AdminOnlyCommand and 'group.admin' or false
}, function(source, args, raw)
    TriggerClientEvent('cad-blipcreator:openMenu', source)
end)