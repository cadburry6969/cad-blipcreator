---@class RegistryBlip
---@field id string
---@field data BlipData
---@field targets BlipTargets
---@field owner string resource that created the blip
---@field saved boolean saved to store/blips.json

local Schema = require 'shared.schema'
local config = require 'config'

local Registry = {}

---@type table<string, RegistryBlip>
local blips = {}
---@type table<string, BlipIconSource>
local registeredIcons = {}
---@type table<string, true> icons added from a link in the editor, saved to store/blips.json
local savedIcons = {}
local seq = 0

---@param src number
---@param targets BlipTargets
---@return boolean
local function canSee(src, targets)
    if targets == nil or targets == -1 then return true end

    local t = type(targets)

    if t == 'number' then return src == targets end
    if t ~= 'table' then return false end
    if targets.ace then return IsPlayerAceAllowed(tostring(src), targets.ace) end

    for _, id in ipairs(targets) do
        if tonumber(id) == src then return true end
    end

    return false
end

---@return number[]
local function players()
    local list = {}

    for _, src in ipairs(GetPlayers()) do
        list[#list + 1] = tonumber(src)
    end

    return list
end

---@param targets any
---@return boolean
local function validTargets(targets)
    if targets == nil or targets == -1 or type(targets) == 'number' then return true end

    return type(targets) == 'table'
end

---Sends the blip to everyone allowed to see it
---@param blip RegistryBlip
local function broadcast(blip)
    for _, src in ipairs(players()) do
        if canSee(src, blip.targets) then
            TriggerClientEvent('cad-blipcreator:blip:set', src, blip.id, blip.data)
        end
    end
end

---@param id string?
---@return string
local function newId(id)
    if id then return tostring(id) end

    seq = seq + 1

    return ('blip_%d_%d'):format(os.time(), seq)
end

---@param id string?
---@param data BlipData already validated
---@param opts { targets: BlipTargets?, owner: string, saved: boolean? }
---@return string? id
---@return string? err
function Registry.add(id, data, opts)
    if not validTargets(opts.targets) then return nil, 'invalid targets' end

    local blipId = newId(id)
    if blips[blipId] then return nil, 'id already exists' end

    local blip = {
        id = blipId,
        data = data,
        targets = opts.targets,
        owner = opts.owner,
        saved = opts.saved == true,
    }

    blips[blipId] = blip
    broadcast(blip)

    return blipId
end

---Replaces all of a blip's data
---@param id string
---@param data BlipData already validated
---@return boolean ok
function Registry.replace(id, data)
    local blip = blips[id]
    if not blip then return false end

    blip.data = data
    broadcast(blip)

    return true
end

---Changes some fields of a blip
---@param id string
---@param patch table
---@return boolean ok
---@return string? err
function Registry.update(id, patch)
    local blip = blips[id]
    if not blip then return false, 'unknown id' end

    patch.localEntity = nil

    local merged, err = Schema.merge(blip.data, patch)
    if not merged then return false, err end

    return Registry.replace(id, merged)
end

---@param id string
---@return boolean removed
function Registry.remove(id)
    local blip = blips[id]
    if not blip then return false end

    blips[id] = nil

    for _, src in ipairs(players()) do
        if canSee(src, blip.targets) then
            TriggerClientEvent('cad-blipcreator:blip:remove', src, id)
        end
    end

    return true
end

---Changes who can see a blip. Players who lose access have it removed.
---@param id string
---@param targets BlipTargets
---@return boolean ok
function Registry.setTargets(id, targets)
    local blip = blips[id]
    if not blip or not validTargets(targets) then return false end

    local old = blip.targets
    blip.targets = targets

    for _, src in ipairs(players()) do
        if canSee(src, targets) then
            TriggerClientEvent('cad-blipcreator:blip:set', src, id, blip.data)
        elseif canSee(src, old) then
            TriggerClientEvent('cad-blipcreator:blip:remove', src, id)
        end
    end

    return true
end

---@param id string
---@return RegistryBlip?
function Registry.get(id)
    return blips[id]
end

---@return table<string, RegistryBlip>
function Registry.all()
    return blips
end

---Registers an icon for every player, including players who join later
---@param name string
---@param source BlipIconSource|false false removes it
---@param saved boolean? added in the editor, so it is written to the save file
function Registry.registerIcon(name, source, saved)
    registeredIcons[name] = source or nil
    savedIcons[name] = (source and saved) and true or nil

    TriggerClientEvent('cad-blipcreator:icon', -1, name, source or nil)
end

---@param name string
---@return boolean
function Registry.iconExists(name)
    return config.icons[name] ~= nil or registeredIcons[name] ~= nil
end

---@param name string
---@return boolean
function Registry.isSavedIcon(name)
    return savedIcons[name] == true
end

---Icons added in the editor, by name
---@return table<string, BlipIconSource>
function Registry.savedIcons()
    local out = {}

    for name in pairs(savedIcons) do
        out[name] = registeredIcons[name]
    end

    return out
end

---Sends a player everything they can see, for example when they join or their permissions change
---@param src number|string
function Registry.resync(src)
    src = tonumber(src)
    if not src then return end

    local visible = {}

    for id, blip in pairs(blips) do
        if canSee(src, blip.targets) then
            visible[id] = blip.data
        end
    end

    TriggerClientEvent('cad-blipcreator:snapshot', src, registeredIcons, visible)
end

RegisterNetEvent('cad-blipcreator:request', function()
    Registry.resync(source)
end)

AddEventHandler('playerDropped', function()
    local src = source

    for id, blip in pairs(blips) do
        if (blip.data.player == src and blip.data.removeOnDrop) or blip.targets == src then
            Registry.remove(id)
        end
    end
end)

-- blips made by another resource are removed when it stops
AddEventHandler('onResourceStop', function(res)
    if res == cache.resource then return end

    for id, blip in pairs(blips) do
        if blip.owner == res then
            Registry.remove(id)
        end
    end
end)

-- keeps blips on players / vehicles moving for players who are too far away to see them (needs OneSync)
CreateThread(function()
    while true do
        Wait(config.tracking.serverInterval)

        ---@type table<string, vector3>?
        local moved

        for id, blip in pairs(blips) do
            local d = blip.data
            local ent

            if d.player then
                ent = GetPlayerPed(d.player)
            elseif d.entity then
                ent = NetworkGetEntityFromNetworkId(d.entity)
            end

            if ent and ent ~= 0 and DoesEntityExist(ent) then
                local coords = GetEntityCoords(ent)

                if not d.coords or #(coords - d.coords) > config.tracking.serverMinDistance then
                    d.coords = coords
                    moved = moved or {}
                    moved[id] = coords
                end
            end
        end

        if moved then
            for _, src in ipairs(players()) do
                local batch, any = {}, false

                for id, coords in pairs(moved) do
                    if canSee(src, blips[id].targets) then
                        batch[id] = coords
                        any = true
                    end
                end

                if any then
                    TriggerClientEvent('cad-blipcreator:blip:coords', src, batch)
                end
            end
        end
    end
end)

return Registry
