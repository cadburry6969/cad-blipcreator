---@alias BlipTargets nil|number|number[]|{ ace: string } nil or -1 means everyone

---@alias BlipIconSource string|{ src: string, size: number? }

---@class BlipData
---@field coords vector3?
---@field entity number? network id
---@field player number? server id
---@field localEntity number? client only, local entity handle
---@field radius number?
---@field label string
---@field sprite number
---@field colour number
---@field scale number
---@field alpha number
---@field display number
---@field shortRange boolean
---@field category number?
---@field categoryLabel string?
---@field priority number?
---@field flash boolean?
---@field flashInterval number?
---@field route boolean?
---@field routeColour number?
---@field heading number?
---@field headingIndicator boolean?
---@field radiusColour number?
---@field radiusAlpha number
---@field permissions any 'none', a job name, a list of names or { value = name } entries
---@field icon string? registered icon name
---@field iconSize number size in pixels at 1080p
---@field iconTint number[]?
---@field iconRotate boolean?
---@field iconFallback boolean keep the GTA sprite on the pause map when the icon can't be shown there
---@field mapIconSize number? fixed size on the ground in metres instead of a fixed screen size
---@field removeOnDrop boolean

local Schema = {}

---@type table<string, 'vector'|'number'|'string'|'boolean'|'table'|'any'>
local FIELDS = {
    coords = 'vector',
    entity = 'number',
    player = 'number',
    localEntity = 'number',
    radius = 'number',
    label = 'string',
    sprite = 'number',
    colour = 'number',
    scale = 'number',
    alpha = 'number',
    display = 'number',
    shortRange = 'boolean',
    category = 'number',
    categoryLabel = 'string',
    priority = 'number',
    flash = 'boolean',
    flashInterval = 'number',
    route = 'boolean',
    routeColour = 'number',
    heading = 'number',
    headingIndicator = 'boolean',
    radiusColour = 'number',
    radiusAlpha = 'number',
    permissions = 'any',
    icon = 'string',
    iconSize = 'number',
    iconTint = 'table',
    iconRotate = 'boolean',
    iconFallback = 'boolean',
    mapIconSize = 'number',
    removeOnDrop = 'boolean',
}

---@type BlipData
local DEFAULTS = {
    label = 'Blip',
    sprite = 1,
    colour = 0,
    scale = 1.0,
    alpha = 255,
    display = 2,
    shortRange = true,
    radiusAlpha = 128,
    permissions = 'none',
    iconSize = 24,
    iconFallback = true,
    removeOnDrop = true,
}

---Converts a vector or { x, y, z } table to a vector3
---@param v any
---@return vector3?
function Schema.toVec3(v)
    local t = type(v)

    if t == 'vector3' or t == 'vector4' then return vec3(v.x, v.y, v.z) end
    if t ~= 'table' or not tonumber(v.x) or not tonumber(v.y) then return end

    return vec3(v.x + 0.0, v.y + 0.0, (tonumber(v.z) or 0.0) + 0.0)
end

---Applies `patch` on top of `base` (or the defaults) and checks the result.
---Setting an optional field to `false` clears it, for example `icon = false`.
---@param base BlipData?
---@param patch table
---@return BlipData? data
---@return string? err
function Schema.merge(base, patch)
    if type(patch) ~= 'table' then return nil, 'data must be a table' end

    local out = {}

    for k, v in pairs(base or DEFAULTS) do
        out[k] = v
    end

    for k, v in pairs(patch) do
        local expected = FIELDS[k]

        if not expected then
            if k ~= 'id' then return nil, ('unknown field "%s"'):format(k) end
        elseif v == false and expected ~= 'boolean' then
            out[k] = nil
        elseif expected == 'vector' then
            local vec = Schema.toVec3(v)
            if not vec then return nil, ('field "%s" must be a vector3'):format(k) end

            out[k] = vec
        elseif expected ~= 'any' and type(v) ~= expected then
            return nil, ('field "%s" must be a %s'):format(k, expected)
        else
            out[k] = v
        end
    end

    if not (out.coords or out.entity or out.player or out.localEntity) then
        return nil, 'one of coords / entity / player / localEntity is required'
    end

    if out.categoryLabel and not out.category then return nil, 'categoryLabel requires category' end
    if out.scale <= 0 then return nil, 'scale must be > 0' end

    out.alpha = math.max(0, math.min(255, math.floor(out.alpha)))

    return out
end

---Copies blip data into plain tables so it can be saved as JSON or sent to the UI
---@param data BlipData
---@return table
function Schema.toPlain(data)
    local out = {}

    for k, v in pairs(data) do
        local t = type(v)

        if t == 'vector3' or t == 'vector4' then
            out[k] = { x = v.x, y = v.y, z = v.z }
        else
            out[k] = v
        end
    end

    return out
end

return Schema
