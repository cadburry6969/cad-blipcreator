local Blips = require 'client.blips'
local Icons = require 'client.icons'

---@param id string
---@param data BlipData
RegisterNetEvent('cad-blipcreator:blip:set', function(id, data)
    Blips.upsert(id, data, 'server')
end)

---@param id string
RegisterNetEvent('cad-blipcreator:blip:remove', function(id)
    local e = Blips.get(id)

    if e and e.source == 'server' then
        Blips.remove(id)
    end
end)

---@param batch table<string, vector3>
RegisterNetEvent('cad-blipcreator:blip:coords', function(batch)
    for id, coords in pairs(batch) do
        Blips.setCoords(id, coords)
    end
end)

---@param name string
---@param source BlipIconSource?
RegisterNetEvent('cad-blipcreator:icon', function(name, source)
    if source then
        Icons.register(name, source)
    else
        Icons.remove(name)
    end
end)

---@param icons table<string, BlipIconSource>
---@param blips table<string, BlipData>
RegisterNetEvent('cad-blipcreator:snapshot', function(icons, blips)
    for name, source in pairs(icons) do
        Icons.register(name, source)
    end

    for id, e in pairs(Blips.all()) do
        if e.source == 'server' and not blips[id] then
            Blips.remove(id)
        end
    end

    for id, data in pairs(blips) do
        Blips.upsert(id, data, 'server')
    end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    TriggerServerEvent('cad-blipcreator:request')
end)
