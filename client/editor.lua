---@class EditorDraft table of BlipData fields sent by the UI, coords as { x, y, z }

---@class EditorList
---@field blips table[]
---@field linkIcons string[] icons added from a link in the editor

local config = require 'config'
local Schema = require 'shared.schema'
local Blips = require 'client.blips'
local Icons = require 'client.icons'

local PREVIEW_ID = '__editor_preview'

local isOpen = false
---@type string? saved blip hidden while its preview is shown
local previewing
---@type string[]
local linkIcons = {}

---@return table[]? blips
local function fetchList()
    local list = lib.callback.await('cad-blipcreator:editor:list', false) --[[@as EditorList?]]
    if not list then return end

    linkIcons = list.linkIcons or {}

    return list.blips
end

---@param coords vector3
---@return { x: number, y: number, z: number }
local function plainCoords(coords)
    return { x = coords.x, y = coords.y, z = coords.z }
end

---@return vector3?
local function waypointCoords()
    local waypoint = GetFirstBlipInfoId(8)
    if waypoint == 0 or not DoesBlipExist(waypoint) then return end

    return GetBlipInfoIdCoord(waypoint)
end

---Finds the ground height at a point, which only works where the map is loaded
---@param x number
---@param y number
---@param fallback number
---@return number
local function groundZ(x, y, fallback)
    for _, height in ipairs({ 1000.0, 500.0, 200.0, 100.0 }) do
        local found, z = GetGroundZFor_3dCoord(x, y, height, false)

        if found then return z end
    end

    return fallback
end

---Removes the preview blip and shows the blip it replaced again
local function clearPreview()
    Blips.remove(PREVIEW_ID)

    if previewing then
        Blips.setSuppressed(previewing, false)
        previewing = nil
    end
end

---@param visible boolean
local function setFocus(visible)
    SetNuiFocus(visible, visible)
end

---Hides the editor and opens the pause map with a hint on screen. Waits until the map closes,
---or until `watch` returns something, then closes the map and shows the editor again.
---@param hint string
---@param watch (fun(): any)? called every 100 ms while the map is open
---@return any result what `watch` returned, or nil if the player closed the map
local function usePauseMap(hint, watch)
    SendNUIMessage({ action = 'hide', data = { hint = hint } })
    setFocus(false)
    ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, -1)

    local timeout = GetGameTimer() + 2000
    local result

    while not IsPauseMenuActive() and GetGameTimer() < timeout do
        Wait(50)
    end

    while IsPauseMenuActive() do
        result = watch and watch()

        if result ~= nil then
            SetFrontendActive(false)
            break
        end

        Wait(100)
    end

    while IsPauseMenuActive() do
        Wait(50)
    end

    if isOpen then
        setFocus(true)
        SendNUIMessage({ action = 'show' })
    end

    return result
end

---Closes the editor and gives control back to the game
local function close()
    if not isOpen then return end

    isOpen = false
    clearPreview()
    setFocus(false)
    SendNUIMessage({ action = 'close' })
end

---Loads the blip list from the server and opens the editor
local function open()
    local blips = fetchList()

    if not blips then
        lib.notify({ type = 'error', description = 'You are not allowed to edit blips' })
        return
    end

    isOpen = true
    setFocus(true)

    SendNUIMessage({
        action = 'open',
        data = {
            blips = blips,
            icons = Icons.list(linkIcons),
            permissions = config.permissions,
            player = plainCoords(GetEntityCoords(cache.ped)),
        },
    })
end

RegisterNetEvent('cad-blipcreator:editor:open', open)

RegisterNUICallback('close', function(_, cb)
    close()
    cb(true)
end)

---@param body { id: string?, blip: EditorDraft }
RegisterNUICallback('save', function(body, cb)
    local result = lib.callback.await('cad-blipcreator:editor:save', false, body.id, body.blip)

    if result and result.ok then
        clearPreview()
    end

    cb({ result = result, blips = fetchList() })
end)

---@param body { id: string }
RegisterNUICallback('delete', function(body, cb)
    local result = lib.callback.await('cad-blipcreator:editor:delete', false, body.id)

    if result and result.ok then
        clearPreview()
    end

    cb({ result = result, blips = fetchList() })
end)

RegisterNUICallback('refresh', function(_, cb)
    cb(fetchList())
end)

---@param body { name: string, url: string }
RegisterNUICallback('addIcon', function(body, cb)
    local result = lib.callback.await('cad-blipcreator:editor:addIcon', false, body.name, body.url)

    -- load it now so the preview can use it before the server's update arrives
    if result and result.ok then
        Icons.register(body.name, body.url)
        fetchList()
    end

    cb({ result = result, icons = Icons.list(linkIcons) })
end)

---@param body { name: string }
RegisterNUICallback('removeIcon', function(body, cb)
    local result = lib.callback.await('cad-blipcreator:editor:removeIcon', false, body.name)

    if result and result.ok then
        Icons.remove(body.name)
        fetchList()
    end

    cb({ result = result, icons = Icons.list(linkIcons) })
end)

---Shows the blip being edited on the map before it is saved
---@param body { id: string?, blip: EditorDraft? }
RegisterNUICallback('preview', function(body, cb)
    cb(true)

    if not body.blip then
        clearPreview()
        return
    end

    local data = Schema.merge(nil, body.blip)

    if not data then
        Blips.remove(PREVIEW_ID)
        return
    end

    if body.id ~= previewing then
        if previewing then Blips.setSuppressed(previewing, false) end
        if body.id then Blips.setSuppressed(body.id, true) end

        previewing = body.id
    end

    Blips.upsert(PREVIEW_ID, data, 'local', cache.resource)
end)

---@param body { source: 'player'|'waypoint' }
RegisterNUICallback('position', function(body, cb)
    local coords = GetEntityCoords(cache.ped)

    if body.source == 'waypoint' then
        local point = waypointCoords()

        if not point then
            cb(false)
            return
        end

        coords = vec3(point.x, point.y, groundZ(point.x, point.y, coords.z))
    end

    cb(plainCoords(coords))
end)

---Lets the player click a point on the pause map, then fills in its coordinates
---@param body { z: number? } current height, kept when the ground height can't be found
RegisterNUICallback('pickOnMap', function(body, cb)
    local before = waypointCoords()

    local picked = usePauseMap('Place a waypoint where the blip should go. Close the map to cancel.', function()
        local now = waypointCoords()
        if not now then return end
        if before and #(now.xy - before.xy) < 0.5 then return end

        return now
    end)

    if not picked then
        cb(false)
        return
    end

    -- only remove the waypoint if the player didn't have one before
    if not before then
        SetWaypointOff()
    end

    local fallback = tonumber(body.z) or GetEntityCoords(cache.ped).z

    cb(plainCoords(vec3(picked.x, picked.y, groundZ(picked.x, picked.y, fallback))))
end)

---@param body { coords: { x: number, y: number, z: number } }
RegisterNUICallback('teleport', function(body, cb)
    local coords = Schema.toVec3(body.coords)

    if coords then
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    end

    cb(coords ~= nil)
end)

RegisterNUICallback('viewMap', function(_, cb)
    cb(true)
    usePauseMap('Close the map to go back to the editor.')
end)

AddEventHandler('onResourceStop', function(res)
    if res == cache.resource then
        close()
    end
end)
