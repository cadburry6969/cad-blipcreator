---@class BlipEntry
---@field id string
---@field data BlipData
---@field source 'server'|'local'
---@field owner string? resource that created a local blip
---@field handle number? GTA blip
---@field radiusHandle number? GTA radius blip
---@field attachedTo number|false|nil entity the blip follows, false when placed at coords
---@field visible boolean? passed the permission check
---@field suppressed boolean? hidden while the editor previews a change to it
---@field debugBoth boolean? show the GTA sprite and the icon together (calibration)

---@class IconPlan
---@field screen boolean icon drawn over the minimap with DrawSprite
---@field map boolean icon placed with MINIMAP_LOADER.gfx
---@field nativeMain boolean GTA sprite shown on the pause map
---@field nativeMini boolean GTA sprite shown on the minimap

local config = require 'config'
local Icons = require 'client.icons'
local Permissions = require 'client.permissions'
local Overlay = require 'client.render.overlay'
local MapOverlay = require 'client.render.mapoverlay'

local Blips = {}

---@type table<string, BlipEntry>
local entries = {}

-- SetBlipDisplay values that show on the pause map / the minimap
local SHOWS_MAIN = { [2] = true, [3] = true, [4] = true, [6] = true, [8] = true, [10] = true }
local SHOWS_MINI = { [2] = true, [5] = true, [6] = true, [8] = true, [9] = true, [10] = true }

-- changing any of these needs the blip to be created again
local REBUILD_KEYS = { 'entity', 'player', 'localEntity', 'radius', 'permissions' }

---Finds the entity a blip follows, if it is near this player
---@param d BlipData
---@return number?
local function resolveEntity(d)
    if d.localEntity then
        return DoesEntityExist(d.localEntity) and d.localEntity or nil
    end

    if d.player then
        local idx = GetPlayerFromServerId(d.player)
        if idx == -1 then return end

        local ped = GetPlayerPed(idx)

        return ped ~= 0 and DoesEntityExist(ped) and ped or nil
    end

    if d.entity and NetworkDoesEntityExistWithNetworkId(d.entity) then
        local ent = NetworkGetEntityFromNetworkId(d.entity)

        return ent ~= 0 and DoesEntityExist(ent) and ent or nil
    end
end

---Decides what is drawn on each map for this blip
---@param d BlipData
---@return IconPlan
function Blips.iconPlan(d)
    local iconOk = d.icon ~= nil and Icons.exists(d.icon)
    local onMain, onMini = SHOWS_MAIN[d.display] == true, SHOWS_MINI[d.display] == true
    local map = iconOk and onMain and MapOverlay.available()
    local mapOnMini = map and config.mapOverlay.showOnMinimap
    local screen = iconOk and onMini and config.overlay.enabled and not mapOnMini

    return {
        screen = screen,
        map = map,
        nativeMain = onMain and not map and (not screen or d.iconFallback),
        nativeMini = onMini and not screen and not mapOnMini,
    }
end

---@param main boolean
---@param mini boolean
---@param original number
---@return number
local function displayFor(main, mini, original)
    if main and mini then return original end
    if main then return 3 end
    if mini then return 5 end

    return 0
end

---@param e BlipEntry
---@param plan IconPlan
local function applyIcons(e, plan)
    local b, d = e.handle --[[@as number]], e.data

    if plan.map then
        MapOverlay.set(e.id, {
            handle = b,
            icon = d.icon --[[@as string]],
            px = d.iconSize + 0.0,
            fixed = d.mapIconSize and d.mapIconSize + 0.0,
            rotate = d.iconRotate,
            heading = d.heading,
            entity = e.attachedTo or nil,
        })
    else
        MapOverlay.remove(e.id)
    end

    if plan.screen then
        Overlay.set(e.id, {
            handle = b,
            icon = d.icon --[[@as string]],
            size = d.iconSize,
            tint = d.iconTint,
            rotate = d.iconRotate,
            heading = d.heading,
            entity = e.attachedTo or nil,
            shortRange = d.shortRange,
            alpha = d.alpha,
        })
    else
        Overlay.remove(e.id)
    end
end

---Applies all blip settings and icons
---@param e BlipEntry
local function style(e)
    local b, d = e.handle, e.data
    if not b then return end

    SetBlipSprite(b, d.sprite)
    SetBlipColour(b, d.colour)
    SetBlipScale(b, d.scale + 0.0)
    SetBlipAlpha(b, d.alpha)
    SetBlipAsShortRange(b, d.shortRange)
    SetBlipFlashes(b, d.flash == true)
    SetBlipRoute(b, d.route == true)
    ShowHeadingIndicatorOnBlip(b, d.headingIndicator == true)

    if d.priority then SetBlipPriority(b, d.priority) end
    if d.flash and d.flashInterval then SetBlipFlashInterval(b, d.flashInterval) end
    if d.route and d.routeColour then SetBlipRouteColour(b, d.routeColour) end
    if d.heading and not e.attachedTo then SetBlipRotation(b, math.floor(d.heading)) end

    if d.category then
        if d.categoryLabel then
            AddTextEntry(('BLIP_CAT_%d'):format(d.category), d.categoryLabel)
        end

        SetBlipCategory(b, d.category)
    end

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(d.label)
    EndTextCommandSetBlipName(b)

    local plan = Blips.iconPlan(d)

    SetBlipDisplay(b, e.debugBoth and d.display or displayFor(plan.nativeMain, plan.nativeMini, d.display))
    applyIcons(e, plan)

    if e.radiusHandle then
        SetBlipColour(e.radiusHandle, d.radiusColour or d.colour)
        SetBlipAlpha(e.radiusHandle, d.radiusAlpha)
    end
end

---Removes the GTA blips and icons but keeps the entry
---@param e BlipEntry
local function destroy(e)
    Overlay.remove(e.id)
    MapOverlay.remove(e.id)

    if e.handle and DoesBlipExist(e.handle) then RemoveBlip(e.handle) end
    if e.radiusHandle and DoesBlipExist(e.radiusHandle) then RemoveBlip(e.radiusHandle) end

    e.handle, e.radiusHandle, e.attachedTo = nil, nil, nil
end

---Creates the GTA blips for an entry from scratch
---@param e BlipEntry
local function build(e)
    destroy(e)

    local d = e.data

    e.visible = Permissions.canView(d.permissions)
    if not e.visible or e.suppressed then return end

    local ent = resolveEntity(d)
    local pos = ent and GetEntityCoords(ent) or d.coords
    if not pos then return end -- entity far away and no position from the server yet

    e.handle = ent and AddBlipForEntity(ent) or AddBlipForCoord(pos.x, pos.y, pos.z)
    e.attachedTo = ent or false

    if d.radius then
        e.radiusHandle = AddBlipForRadius(pos.x, pos.y, pos.z, d.radius + 0.0)
    end

    style(e)
end

---Compares values, tables by content
---@param a any
---@param b any
---@return boolean
local function same(a, b)
    if type(a) == 'table' or type(b) == 'table' then
        return json.encode(a) == json.encode(b)
    end

    return a == b
end

---@param e BlipEntry
---@param coords vector3
local function moveTo(e, coords)
    if not e.handle or e.attachedTo then return end

    SetBlipCoords(e.handle, coords.x, coords.y, coords.z)

    if e.radiusHandle then
        SetBlipCoords(e.radiusHandle, coords.x, coords.y, coords.z)
    end
end

---Adds a blip or updates an existing one
---@param id string
---@param data BlipData
---@param source 'server'|'local'
---@param owner string?
---@return BlipEntry
function Blips.upsert(id, data, source, owner)
    local e = entries[id]

    if not e then
        e = { id = id, data = data, source = source, owner = owner }
        entries[id] = e
        build(e)

        return e
    end

    local old = e.data
    local rebuild = not e.handle

    e.data = data

    for _, k in ipairs(REBUILD_KEYS) do
        if not same(old[k], data[k]) then
            rebuild = true
            break
        end
    end

    if rebuild then
        build(e)
        return e
    end

    if data.coords then
        moveTo(e, data.coords)
    end

    style(e)

    return e
end

---Updates the position of blips the server tracks (players / vehicles far away)
---@param id string
---@param coords vector3
function Blips.setCoords(id, coords)
    local e = entries[id]
    if not e then return end

    e.data.coords = coords

    if e.handle then
        moveTo(e, coords)
    elseif e.visible then
        build(e)
    end
end

---@param id string
---@return boolean removed
function Blips.remove(id)
    local e = entries[id]
    if not e then return false end

    destroy(e)
    entries[id] = nil

    return true
end

---@param id string
---@return BlipEntry?
function Blips.get(id)
    return entries[id]
end

---@return table<string, BlipEntry>
function Blips.all()
    return entries
end

---Hides or shows a blip, used by the editor while previewing changes to it
---@param id string
---@param suppressed boolean
function Blips.setSuppressed(id, suppressed)
    local e = entries[id]
    if not e or e.suppressed == suppressed then return end

    e.suppressed = suppressed
    build(e)
end

---Re-applies settings, for example after debug flags change
---@param e BlipEntry
function Blips.restyle(e)
    style(e)
end

---Checks permissions again, for example after a job change
function Blips.reapply()
    for _, e in pairs(entries) do
        local allowed = Permissions.canView(e.data.permissions)

        if allowed and not e.handle then
            build(e)
        elseif not allowed and e.handle then
            destroy(e)
            e.visible = false
        end
    end
end

Icons.onChange(function(name)
    for _, e in pairs(entries) do
        if e.data.icon == name then
            style(e)
        end
    end
end)

MapOverlay.onReady(function()
    for _, e in pairs(entries) do
        style(e)
    end
end)

Permissions.onChange(function()
    Blips.reapply()
end)

-- follows entities as they come near or move away from this player
CreateThread(function()
    while true do
        Wait(config.tracking.attachCheckInterval)

        for _, e in pairs(entries) do
            local d = e.data

            if (d.entity or d.player or d.localEntity) and e.visible and not e.suppressed then
                local ent = resolveEntity(d)

                if (ent or false) ~= e.attachedTo or not e.handle or not DoesBlipExist(e.handle) then
                    build(e)
                elseif ent and e.radiusHandle then
                    local p = GetEntityCoords(ent)
                    SetBlipCoords(e.radiusHandle, p.x, p.y, p.z)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    for id, e in pairs(entries) do
        if res == cache.resource or e.owner == res then
            Blips.remove(id)
        end
    end
end)

return Blips
