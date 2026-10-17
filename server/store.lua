---@class StoreFile
---@field icons table<string, string> link icons, name -> url
---@field blips table<string, table> saved blips, id -> BlipData with plain { x, y, z } coords

local Schema = require 'shared.schema'
local Registry = require 'server.registry'

local Store = {}

local FILE = 'store/blips.json'

---@param raw string
---@return StoreFile?
local function decode(raw)
    local ok, result = pcall(json.decode, raw)
    if not ok or type(result) ~= 'table' or type(result.blips) ~= 'table' then return end

    return result
end

---Registers the icons added from links in the editor
---@param icons any
local function loadIcons(icons)
    if type(icons) ~= 'table' then return end

    for name, url in pairs(icons) do
        if type(name) == 'string' and type(url) == 'string' then
            Registry.registerIcon(name, url, true)
        end
    end
end

---Writes every saved blip and link icon to the file
function Store.save()
    local blips = {}

    for id, blip in pairs(Registry.all()) do
        if blip.saved then
            blips[id] = Schema.toPlain(blip.data)
        end
    end

    ---@type StoreFile
    local file = {
        icons = Registry.savedIcons(),
        blips = blips,
    }

    SaveResourceFile(cache.resource, FILE, json.encode(file, { indent = true }), -1)
end

---Loads saved blips and link icons into the registry
function Store.load()
    local raw = LoadResourceFile(cache.resource, FILE)

    if not raw then
        Store.save()
        return
    end

    local file = decode(raw)

    if not file then
        lib.print.error(('%s could not be read, starting with no saved blips. Fix it before saving in the editor, or it is replaced.'):format(FILE))
        return
    end

    loadIcons(file.icons)

    for id, stored in pairs(file.blips) do
        local data, err = Schema.merge(nil, stored)

        if data then
            Registry.add(id, data, { owner = cache.resource, saved = true })
        else
            lib.print.warn(('skipped saved blip %s: %s'):format(id, err))
        end
    end
end

return Store
