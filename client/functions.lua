local Blips = GlobalState.blips or {}
local BlipObjects = {}

---Cut short the decimalPlaces
---@return any
function Round(num, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(num + 0.5) end
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- create blip with uniqueId and data
---@param uniqueId any
---@param data table
function CreateBlip(uniqueId, data)
    if not uniqueId or not data then return end
    if HasAccess(data.permissions) then
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        BlipObjects[uniqueId] = blip
        SetBlipSprite(blip, data.sprite or 1)
        SetBlipScale(blip, (data.scale/100) or 1)
        SetBlipColour(blip, data.colour or 1)
        SetBlipDisplay(blip, data.display or 8)
        SetBlipAsShortRange(blip, data.srange or true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(data.name or 'Unknown')
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

---remove the blip if uniqueID id provided or else remove all exisiting blips
---@param uniqueId any
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

---refreshes all blips
---@param uniqueId any
function RefreshBlips(uniqueId)
    RemoveBlips(uniqueId or false)
    if uniqueId then
        CreateBlip(uniqueId, Blips[uniqueId])
    else
        CreateBlips()
    end
end

---get coordinates from waypoint or current player position
---@param teleport boolean
---@return vector3
function GetCoords(teleport)
    local pcoords = GetEntityCoords(PlayerPedId()).xyz
    local blip = GetFirstBlipInfoId(8)
    if blip ~= 0 then
        local bcoords = GetBlipCoords(blip)
        pcoords = vec3(bcoords.x, bcoords.y, pcoords.z)
    end
    if teleport then SetEntityCoords(PlayerPedId(), Round(pcoords.x, 2), Round(pcoords.y, 2), Round(pcoords.z, 2), false, false, false, false) end
    return pcoords
end

-- listens the blips from server side and adds it to local table on client
AddStateBagChangeHandler('blips', 'global', function(_, _, value)
    Blips = value
    RefreshBlips()
end)

-- exports to create / delete / refresh blips externally
exports('CreateBlip', CreateBlip)
exports('RemoveBlips', RemoveBlips)
exports('RefreshBlips', RefreshBlips)
exports('GetCoords', GetCoords)