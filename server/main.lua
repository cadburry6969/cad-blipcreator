local resourceName = GetCurrentResourceName()
local Blips = {}

local function saveBlips()
    GlobalState.blips = Blips
    SaveResourceFile(resourceName, 'blips.json', json.encode(Blips, { indent = true }), -1)
end

CreateThread(function()
    local load_json = json.decode(LoadResourceFile(resourceName, 'blips.json'))
    if type(load_json) == 'table' then
        Blips = load_json
    else
        SaveResourceFile(resourceName, 'blips.json', '[]', -1)
        Blips = {}
    end
end)

RegisterNetEvent('cad-blipcreator:saveBlip', function(data)
    local uniqueId = os.time()
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