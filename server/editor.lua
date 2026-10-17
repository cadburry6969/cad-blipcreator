---@class EditorBlipRecord
---@field id string
---@field saved boolean
---@field owner string
---@field data table BlipData with plain { x, y, z } coords

---@class EditorResult
---@field ok boolean
---@field id string?
---@field error string?

local config = require 'config'
local Schema = require 'shared.schema'
local Registry = require 'server.registry'
local Store = require 'server.store'

local ACE = ('command.%s'):format(config.editor.command)

local DISPLAYS = { [2] = true, [3] = true, [4] = true, [5] = true, [8] = true }

---@type table<string, true>
local allowedPermissions = {}

for _, permission in ipairs(config.permissions) do
    allowedPermissions[permission.value] = true
end

---@param src number
---@return boolean
local function canEdit(src)
    if not config.editor.adminOnly then return true end

    return IsPlayerAceAllowed(tostring(src), ACE)
end

---@param value any
---@param min number
---@param max number
---@return boolean
local function isInt(value, min, max)
    return type(value) == 'number' and value == math.floor(value) and value >= min and value <= max
end

---@param value any
---@param min number
---@param max number
---@return boolean
local function isNumber(value, min, max)
    return type(value) == 'number' and value == value and value >= min and value <= max
end

---Checks a blip sent by the editor and returns the data to save
---@param input any
---@return BlipData? data
---@return string? err
local function parseEditorBlip(input)
    if type(input) ~= 'table' then return nil, 'invalid blip' end

    local coords = Schema.toVec3(input.coords)
    if not coords or math.abs(coords.x) > 10000 or math.abs(coords.y) > 10000 then return nil, 'invalid position' end

    if type(input.label) ~= 'string' or #input.label < 1 or #input.label > 64 then return nil, 'name must be 1 to 64 characters' end
    if not isInt(input.sprite, 0, 2000) then return nil, 'invalid sprite' end
    if not isInt(input.colour, 0, 255) then return nil, 'invalid colour' end
    if not isNumber(input.scale, 0.1, 5) then return nil, 'scale must be between 0.1 and 5' end
    if not isInt(input.alpha, 0, 255) then return nil, 'invalid opacity' end
    if not DISPLAYS[input.display] then return nil, 'invalid display mode' end
    if type(input.shortRange) ~= 'boolean' then return nil, 'invalid short range' end
    if type(input.permissions) ~= 'string' or not allowedPermissions[input.permissions] then return nil, 'unknown permission' end

    local data = {
        coords = coords,
        label = input.label,
        sprite = input.sprite,
        colour = input.colour,
        scale = input.scale + 0.0,
        alpha = input.alpha,
        display = input.display,
        shortRange = input.shortRange,
        flash = input.flash == true,
        permissions = input.permissions,
    }

    if input.category ~= nil then
        if not isInt(input.category, 1, 255) then return nil, 'invalid category' end

        data.category = input.category

        if input.categoryLabel ~= nil then
            if type(input.categoryLabel) ~= 'string' or #input.categoryLabel > 32 then return nil, 'category name is too long' end

            data.categoryLabel = input.categoryLabel
        end
    end

    if input.radius ~= nil then
        if not isNumber(input.radius, 1, 5000) then return nil, 'radius must be between 1 and 5000' end
        if input.radiusColour ~= nil and not isInt(input.radiusColour, 0, 255) then return nil, 'invalid radius colour' end
        if input.radiusAlpha ~= nil and not isInt(input.radiusAlpha, 0, 255) then return nil, 'invalid radius opacity' end

        data.radius = input.radius + 0.0
        data.radiusColour = input.radiusColour
        data.radiusAlpha = input.radiusAlpha
    end

    if input.icon ~= nil then
        if type(input.icon) ~= 'string' or not Registry.iconExists(input.icon) then return nil, 'unknown icon' end
        if input.iconSize ~= nil and not isInt(input.iconSize, 8, 128) then return nil, 'icon size must be between 8 and 128' end

        data.icon = input.icon
        data.iconSize = input.iconSize
    end

    return Schema.merge(nil, data)
end

---@param src number
---@param action string
---@param id string
local function logEdit(src, action, id)
    lib.print.info(('%s (%d) %s blip %s'):format(GetPlayerName(src) or 'unknown', src, action, id))
end

---@param source number
---@return { blips: EditorBlipRecord[], linkIcons: string[] }?
lib.callback.register('cad-blipcreator:editor:list', function(source)
    if not canEdit(source) then return end

    local blips = {}
    local linkIcons = {}

    for id, blip in pairs(Registry.all()) do
        blips[#blips + 1] = {
            id = id,
            saved = blip.saved,
            owner = blip.owner,
            data = Schema.toPlain(blip.data),
        }
    end

    for name in pairs(Registry.savedIcons()) do
        linkIcons[#linkIcons + 1] = name
    end

    return { blips = blips, linkIcons = linkIcons }
end)

local ICON_TYPES = { png = true, svg = true, jpg = true, jpeg = true, webp = true }

---Checks a link to a PNG / SVG image
---@param url any
---@return string? url
---@return string? err
local function parseIconLink(url)
    if type(url) ~= 'string' or #url > 512 or not url:find('^https://[^%s]+$') then
        return nil, 'the link must start with https:// and have no spaces'
    end

    local path = url:match('^https://[^/]+(/[^?#]*)') or ''
    local ext = (path:match('%.(%w+)$') or ''):lower()

    if not ICON_TYPES[ext] then return nil, 'the link must end in .png, .svg, .jpg or .webp' end

    return url
end

---@param source number
---@param name any
---@param url any
---@return EditorResult
lib.callback.register('cad-blipcreator:editor:addIcon', function(source, name, url)
    if not canEdit(source) then return { ok = false, error = 'you are not allowed to edit blips' } end

    if type(name) ~= 'string' or not name:find('^[%w_]+$') or #name > 32 then
        return { ok = false, error = 'icon name can only use letters, numbers and _ (max 32)' }
    end

    if config.icons[name] then return { ok = false, error = 'that name is used by an icon in config.lua' } end

    local link, err = parseIconLink(url)
    if not link then return { ok = false, error = err } end

    Registry.registerIcon(name, link, true)
    Store.save()
    logEdit(source, 'added icon', name)

    return { ok = true, id = name }
end)

---@param source number
---@param name any
---@return EditorResult
lib.callback.register('cad-blipcreator:editor:removeIcon', function(source, name)
    if not canEdit(source) then return { ok = false, error = 'you are not allowed to edit blips' } end
    if type(name) ~= 'string' or not Registry.isSavedIcon(name) then return { ok = false, error = 'icon not found' } end

    for _, blip in pairs(Registry.all()) do
        if blip.saved and blip.data.icon == name then
            return { ok = false, error = ('"%s" uses this icon, change that blip first'):format(blip.data.label) }
        end
    end

    Registry.registerIcon(name, false)
    Store.save()
    logEdit(source, 'removed icon', name)

    return { ok = true, id = name }
end)

---@param source number
---@param id any nil for a new blip
---@param input any
---@return EditorResult
lib.callback.register('cad-blipcreator:editor:save', function(source, id, input)
    if not canEdit(source) then return { ok = false, error = 'you are not allowed to edit blips' } end

    if id ~= nil then
        local existing = type(id) == 'string' and Registry.get(id)

        if not existing or not existing.saved then
            return { ok = false, error = 'blip not found' }
        end
    end

    local data, err = parseEditorBlip(input)
    if not data then return { ok = false, error = err } end

    if id then
        Registry.replace(id, data)
        logEdit(source, 'edited', id)
    else
        id = Registry.add(nil, data, { owner = cache.resource, saved = true })
        logEdit(source, 'created', id)
    end

    Store.save()

    return { ok = true, id = id }
end)

---@param source number
---@param id any
---@return EditorResult
lib.callback.register('cad-blipcreator:editor:delete', function(source, id)
    if not canEdit(source) then return { ok = false, error = 'you are not allowed to edit blips' } end

    local existing = type(id) == 'string' and Registry.get(id)
    if not existing or not existing.saved then return { ok = false, error = 'blip not found' } end

    Registry.remove(id)
    Store.save()
    logEdit(source, 'deleted', id)

    return { ok = true, id = id }
end)

lib.addCommand(config.editor.command, {
    help = 'Open the blip editor',
    restricted = config.editor.adminOnly and 'group.admin' or false,
}, function(source)
    TriggerClientEvent('cad-blipcreator:editor:open', source)
end)
