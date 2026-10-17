---@class ClientBlipInfo
---@field id string
---@field source 'server'|'local'
---@field handle number?
---@field visible boolean
---@field data BlipData

local Schema = require 'shared.schema'
local Blips = require 'client.blips'
local Icons = require 'client.icons'

local localSeq = 0

---@param id string?
---@return string
local function newId(id)
    if id then return tostring(id) end

    localSeq = localSeq + 1

    return ('local_%d'):format(localSeq)
end

---@param data table
---@return string? id
---@return string? err
local function AddDynamicBlip(data)
    if type(data) ~= 'table' then return nil, 'data must be a table' end

    local merged, err = Schema.merge(nil, data)
    if not merged then return nil, err end

    local id = newId(data.id)
    if Blips.get(id) then return nil, 'id already exists' end

    Blips.upsert(id, merged, 'local', GetInvokingResource() or cache.resource)

    return id
end

---@param id string
---@param patch table
---@return boolean ok
---@return string? err
local function UpdateDynamicBlip(id, patch)
    local e = Blips.get(id)

    if not e then return false, 'unknown id' end
    if e.source ~= 'local' then return false, 'server blips must be updated from the server' end

    local merged, err = Schema.merge(e.data, patch)
    if not merged then return false, err end

    Blips.upsert(id, merged, 'local', e.owner)

    return true
end

---@param id string
---@return boolean removed
local function RemoveDynamicBlip(id)
    local e = Blips.get(id)
    if not e or e.source ~= 'local' then return false end

    return Blips.remove(id)
end

---@param id string
---@return ClientBlipInfo?
local function GetDynamicBlip(id)
    local e = Blips.get(id)
    if not e then return end

    local copy = {}

    for k, v in pairs(e.data) do
        copy[k] = v
    end

    return { id = id, source = e.source, handle = e.handle, visible = e.visible == true, data = copy }
end

---@return ClientBlipInfo[]
local function GetDynamicBlips()
    local list = {}

    for id in pairs(Blips.all()) do
        list[#list + 1] = GetDynamicBlip(id)
    end

    return list
end

---Removes the local blips created by the calling resource
local function ClearDynamicBlips()
    local owner = GetInvokingResource() or cache.resource

    for id, e in pairs(Blips.all()) do
        if e.source == 'local' and e.owner == owner then
            Blips.remove(id)
        end
    end
end

---@param id string
---@return number?
local function GetDynamicBlipHandle(id)
    local e = Blips.get(id)

    return e and e.handle
end

exports('AddDynamicBlip', AddDynamicBlip)
exports('UpdateDynamicBlip', UpdateDynamicBlip)
exports('RemoveDynamicBlip', RemoveDynamicBlip)
exports('GetDynamicBlip', GetDynamicBlip)
exports('GetDynamicBlips', GetDynamicBlips)
exports('GetDynamicBlipHandle', GetDynamicBlipHandle)
exports('ClearDynamicBlips', ClearDynamicBlips)
exports('RegisterBlipIcon', Icons.register)
exports('RemoveBlipIcon', function(name) Icons.remove(name) end)
exports('IsBlipIconReady', Icons.isReady)
