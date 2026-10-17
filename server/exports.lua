---@class ServerBlipInfo
---@field id string
---@field data BlipData
---@field targets BlipTargets
---@field owner string
---@field saved boolean

local Schema = require 'shared.schema'
local Registry = require 'server.registry'

---@param id string
---@return RegistryBlip? blip
---@return string? err
local function getEditable(id)
    local blip = Registry.get(id)

    if not blip then return nil, 'unknown id' end
    if blip.saved then return nil, 'saved blips can only be changed in the editor' end

    return blip
end

---@param data table
---@param targets BlipTargets
---@return string? id
---@return string? err
local function AddDynamicBlip(data, targets)
    if type(data) ~= 'table' then return nil, 'data must be a table' end

    data.localEntity = nil

    local merged, err = Schema.merge(nil, data)
    if not merged then return nil, err end

    return Registry.add(data.id, merged, {
        targets = targets,
        owner = GetInvokingResource() or cache.resource,
    })
end

---@param id string
---@param patch table
---@return boolean ok
---@return string? err
local function UpdateDynamicBlip(id, patch)
    local _, err = getEditable(id)
    if err then return false, err end
    if type(patch) ~= 'table' then return false, 'patch must be a table' end

    return Registry.update(id, patch)
end

---@param id string
---@return boolean removed
local function RemoveDynamicBlip(id)
    if not getEditable(id) then return false end

    return Registry.remove(id)
end

---@param id string
---@param targets BlipTargets
---@return boolean ok
local function SetDynamicBlipTargets(id, targets)
    if not getEditable(id) then return false end

    return Registry.setTargets(id, targets)
end

---@param id string
---@return ServerBlipInfo?
local function GetDynamicBlip(id)
    local blip = Registry.get(id)
    if not blip then return end

    local copy = {}

    for k, v in pairs(blip.data) do
        copy[k] = v
    end

    return { id = id, data = copy, targets = blip.targets, owner = blip.owner, saved = blip.saved }
end

---@return ServerBlipInfo[]
local function GetDynamicBlips()
    local list = {}

    for id in pairs(Registry.all()) do
        list[#list + 1] = GetDynamicBlip(id)
    end

    return list
end

---Removes every blip created by the calling resource
local function ClearDynamicBlips()
    local owner = GetInvokingResource() or cache.resource

    for id, blip in pairs(Registry.all()) do
        if blip.owner == owner and not blip.saved then
            Registry.remove(id)
        end
    end
end

---@param name string
---@param source BlipIconSource|false false removes it
---@return boolean ok
local function RegisterBlipIcon(name, source)
    if type(name) ~= 'string' then return false end

    Registry.registerIcon(name, source)

    return true
end

exports('AddDynamicBlip', AddDynamicBlip)
exports('UpdateDynamicBlip', UpdateDynamicBlip)
exports('RemoveDynamicBlip', RemoveDynamicBlip)
exports('SetDynamicBlipTargets', SetDynamicBlipTargets)
exports('GetDynamicBlip', GetDynamicBlip)
exports('GetDynamicBlips', GetDynamicBlips)
exports('ClearDynamicBlips', ClearDynamicBlips)
exports('RegisterBlipIcon', RegisterBlipIcon)
exports('ResyncDynamicBlips', Registry.resync)
