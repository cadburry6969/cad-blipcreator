local Blips = {}
local BlipObjects = {}

-- create blip with uniqueId and data
local function CreateBlip(uniqueId, data)
    if HasAccess(data.permissions) then
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        BlipObjects[uniqueId] = blip
        SetBlipSprite(blip, data.Sprite)
        SetBlipScale(blip, data.scale/10)
        SetBlipColour(blip, data.sColor)
        SetBlipAsShortRange(blip, data.sRange)

        ShowTickOnBlip(blip, data.tickb)
        ShowOutlineIndicatorOnBlip(blip, data.outline)
        SetBlipAlpha(blip, data.alpha)

        if data.bflash then
            SetBlipFlashes(blip, true)
            SetBlipFlashInterval(blip, data.ftimer)
        end

        if data.hideb then
            SetBlipDisplay(blip, 3)
        else
            SetBlipDisplay(blip, 2)
        end

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(data.name)
        EndTextCommandSetBlipName(blip)
    else
        RemoveBlips(uniqueId)
    end
end

-- create all blips which were stored on the server side
function CreateBlips()
    for uniqueId, data in pairs(Blips) do
        CreateBlip(uniqueId, data)
    end
end

-- remove the blip if uniqueID id provided or else remove all exisiting blips
function RemoveBlips(uniqueId)
    if uniqueId then
        if BlipObjects[uniqueId] then
            RemoveBlip(BlipObjects[uniqueId])
            Wait(100)
            BlipObjects[uniqueId] = nil
        end
    else
        for _, object in pairs(BlipObjects) do
            RemoveBlip(object)
        end
        Wait(100)
        BlipObjects = {}
    end
end

-- refreshes all blips
function RefreshBlips(uniqueId)
    RemoveBlips(uniqueId or false)
    if uniqueId then
        CreateBlip(uniqueId, Blips[uniqueId])
    else
        CreateBlips()
    end
end

-- listens the blips from server side and adds it to local table on client
AddStateBagChangeHandler(nil, 'global', function(bagName, key, value, reserved, replicated)
    if key == 'blips' then
        Blips = value
        RefreshBlips()
    end
end)

-- exports to create / delete / refresh blips externally
exports('CreateBlip', CreateBlip)
exports('RemoveBlips', RemoveBlips)
exports('RefreshBlips', RefreshBlips)