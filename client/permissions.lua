---@class FrameworkBridge
---@field hasGroup fun(names: string[]): boolean true if the player has one of the jobs / gangs / groups
---@field onGroupChange fun(cb: fun()) runs cb when the player loads or their job / gang changes

local Permissions = {}

local FRAMEWORKS = {
    { resource = 'qbx_core', bridge = 'client.bridge.qbox' },
    { resource = 'qb-core', bridge = 'client.bridge.qb' },
    { resource = 'es_extended', bridge = 'client.bridge.esx' },
    { resource = 'ox_core', bridge = 'client.bridge.ox' },
}

---@type FrameworkBridge?
local bridge

for _, framework in ipairs(FRAMEWORKS) do
    if GetResourceState(framework.resource) == 'started' then
        bridge = require(framework.bridge)
        break
    end
end

---Turns 'police', { 'police' } or { { value = 'police' } } into { 'police' }
---@param perms any
---@return string[]
local function toNames(perms)
    local list = type(perms) == 'table' and perms or { perms }
    local names = {}

    for _, entry in ipairs(list) do
        local name = type(entry) == 'table' and entry.value or entry

        if type(name) == 'string' then
            names[#names + 1] = name
        end
    end

    return names
end

---@param perms any 'none', a job name, a list of names or { value = name } entries
---@return boolean
function Permissions.canView(perms)
    if perms == nil or perms == 'none' then return true end
    if not bridge then return false end

    local ok, allowed = pcall(bridge.hasGroup, toNames(perms))

    return ok and allowed == true
end

---@param cb fun()
function Permissions.onChange(cb)
    if bridge then
        bridge.onGroupChange(cb)
    end
end

return Permissions
