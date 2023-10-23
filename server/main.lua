local resourceName = GetCurrentResourceName()
local Blips = {}

local function saveBlips()
    GlobalState.blips = Blips
    SaveResourceFile(resourceName, 'blips.json', json.encode(Blips, { indent = true }), -1)
end

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

RegisterNetEvent('cad-blipcreator:saveBlip', function(_uniqueId, data)
    local uniqueId = _uniqueId or os.time()
    Blips[uniqueId] = data
    Wait(100)
    saveBlips()
end)

RegisterNetEvent('cad-blipcreator:removeBlip', function(uniqueId)
    if Blips[uniqueId] then
        Blips[uniqueId] = nil
        Wait(100)
        saveBlips()
    end
end)