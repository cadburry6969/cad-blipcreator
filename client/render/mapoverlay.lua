---@class MapOverlayItem
---@field handle number blip handle
---@field icon string
---@field px number size in pixels at 1080p
---@field fixed number? fixed size in metres instead of a screen size
---@field rotate boolean?
---@field heading number?
---@field entity number?
---@field placed MapOverlayPlaced?

---@class MapOverlayPlaced
---@field x number
---@field y number
---@field rot number
---@field scale number
---@field txn string
---@field tw number texture width
---@field th number texture height

local config = require 'config'
local Icons = require 'client.icons'
local Overlay = require 'client.render.overlay'

local cfg = config.mapOverlay
local overlayCfg = config.overlay

local MapOverlay = {}

---@type number
local handle
---@type 'idle'|'loading'|'ready'|'missing'
local state = 'idle'
---@type string[] position in this list = overlay index + 1 (indexes shift down when one is removed)
local order = {}
---@type table<string, MapOverlayItem>
local items = {}
---@type boolean?
local visible
---@type fun()[]
local readyListeners = {}

-- The game only tells us which world position is under the mouse on the pause map,
-- so its zoom is measured by comparing two mouse positions.
local pauseMpp = cfg.pauseMetersPerPixel
---@type { cx: number, cy: number, wx: number, wy: number }?
local zoomAnchor
---@type number?
local lastEstimate
local wasPaused = false

---Forgets the last mouse position so measuring starts again
local function resetZoomSampling()
    zoomAnchor, lastEstimate = nil, nil
end

---Measures the pause map zoom from mouse movement and updates pauseMpp
local function samplePauseZoom()
    if type(GetPauseMapPointerWorldPosition) ~= 'function' then return end

    -- zooming or dragging moves the map, start measuring again
    if IsDisabledControlPressed(2, 237) or IsDisabledControlJustPressed(2, 241) or IsDisabledControlJustPressed(2, 242) then
        resetZoomSampling()
        return
    end

    local world = GetPauseMapPointerWorldPosition()
    if not world or (world.x == 0.0 and world.y == 0.0) then return end

    local resX, resY = GetActiveScreenResolution()
    local cx, cy = GetDisabledControlNormal(2, 239) * resX, GetDisabledControlNormal(2, 240) * resY

    if not zoomAnchor then
        zoomAnchor = { cx = cx, cy = cy, wx = world.x, wy = world.y }
        return
    end

    local dxp, dyp = cx - zoomAnchor.cx, cy - zoomAnchor.cy
    if math.abs(dxp) + math.abs(dyp) < 40 then return end

    local mpp

    if math.abs(dxp) >= math.abs(dyp) then
        mpp = (world.x - zoomAnchor.wx) / dxp
    else
        mpp = -(world.y - zoomAnchor.wy) / dyp -- screen y goes down, north goes up
    end

    zoomAnchor = { cx = cx, cy = cy, wx = world.x, wy = world.y }

    if mpp <= 0.02 or mpp > 100.0 then
        lastEstimate = nil
        return
    end

    -- only trust it when two measurements in a row agree (zoom has finished animating)
    local agrees = lastEstimate and math.abs(mpp / lastEstimate - 1.0) < 0.06
    local changed = math.abs(mpp / pauseMpp - 1.0) > 0.03

    if agrees and changed then
        pauseMpp = mpp
        lib.print.debug(('pause map scale %.2f m/px'):format(mpp))
    end

    lastEstimate = mpp
end

---@param method string
---@return boolean
local function call(method)
    return CallMinimapScaleformFunction(handle, method)
end

---@param id string
---@return integer?
local function indexOf(id)
    for i, v in ipairs(order) do
        if v == id then return i end
    end
end

---@param id string
local function unplace(id)
    local i = indexOf(id)
    if not i then return end

    if call('REM_OVERLAY') then
        ScaleformMovieMethodAddParamInt(i - 1)
        EndScaleformMovieMethod()
    end

    table.remove(order, i)

    if items[id] then
        items[id].placed = nil
    end
end

---@param icon BlipIcon
---@return number? width
---@return number? height
local function textureSize(icon)
    local res = GetTextureResolution(icon.txd, icon.txn)

    if res and res.x >= 8 and res.y >= 8 then
        return res.x, res.y
    end
end

---Overlay scale is a percentage of the texture size, where 100 = 1 metre per texture pixel
---@param it MapOverlayItem
---@param tw number texture width
---@param mpp number metres per screen pixel
---@return number
local function scaleFor(it, tw, mpp)
    local _, resY = GetActiveScreenResolution()
    local worldSize = it.fixed or (it.px * (resY / 1080.0) * cfg.iconScale * mpp)

    return worldSize / tw * 100.0
end

---@param it MapOverlayItem
---@param upright number rotation that keeps the icon upright on screen
---@return number
local function rotationFor(it, upright)
    if not it.rotate then return upright end

    local heading = it.heading or 0.0

    if it.entity and DoesEntityExist(it.entity) then
        heading = GetEntityHeading(it.entity)
    end

    return -heading
end

---@param y number
---@return number
local function mapY(y)
    return cfg.flipY and -y or y
end

---@param id string
---@param it MapOverlayItem
---@param mpp number
---@param upright number
local function place(id, it, mpp, upright)
    local icon = Icons.get(it.icon)
    if not icon or not icon.ready or not DoesBlipExist(it.handle) then return end

    local tw, th = textureSize(icon)
    if not tw or not th then return end -- texture still loading, tried again next tick

    local pos = GetBlipInfoIdCoord(it.handle)
    local rot = rotationFor(it, upright)
    local scale = scaleFor(it, tw, mpp)

    unplace(id)

    if not call('ADD_SCALED_OVERLAY') then return end

    ScaleformMovieMethodAddParamTextureNameString(icon.txd)
    ScaleformMovieMethodAddParamTextureNameString(icon.txn)
    ScaleformMovieMethodAddParamFloat(pos.x)
    ScaleformMovieMethodAddParamFloat(mapY(pos.y))
    ScaleformMovieMethodAddParamFloat(rot)
    ScaleformMovieMethodAddParamFloat(scale)
    ScaleformMovieMethodAddParamFloat(scale * tw / th)
    ScaleformMovieMethodAddParamInt(100)
    ScaleformMovieMethodAddParamBool(true) -- centre the icon on the position
    EndScaleformMovieMethod()

    order[#order + 1] = id
    it.placed = { x = pos.x, y = pos.y, rot = rot, scale = scale, txn = icon.txn, tw = tw, th = th }
end

---Moves, rotates and resizes a placed icon when needed
---@param id string
---@param it MapOverlayItem
---@param mpp number
---@param upright number
local function update(id, it, mpp, upright)
    local i = indexOf(id)
    local p = it.placed
    if not i or not p or not DoesBlipExist(it.handle) then return end

    local pos = GetBlipInfoIdCoord(it.handle)

    if math.abs(pos.x - p.x) + math.abs(pos.y - p.y) > cfg.moveThreshold and call('UPDATE_OVERLAY_POSITION') then
        ScaleformMovieMethodAddParamInt(i - 1)
        ScaleformMovieMethodAddParamFloat(pos.x)
        ScaleformMovieMethodAddParamFloat(mapY(pos.y))
        EndScaleformMovieMethod()
        p.x, p.y = pos.x, pos.y
    end

    local rot = rotationFor(it, upright)
    local turned = math.abs((rot - p.rot + 180.0) % 360.0 - 180.0) > 1.0

    if turned and call('UPDATE_OVERLAY_ROTATION') then
        ScaleformMovieMethodAddParamInt(i - 1)
        ScaleformMovieMethodAddParamFloat(rot)
        EndScaleformMovieMethod()
        p.rot = rot
    end

    local scale = scaleFor(it, p.tw, mpp)

    if math.abs(scale / p.scale - 1.0) > 0.05 and call('UPDATE_OVERLAY_SIZE_OR_SCALE') then
        ScaleformMovieMethodAddParamInt(i - 1)
        ScaleformMovieMethodAddParamFloat(scale)
        ScaleformMovieMethodAddParamFloat(scale * p.tw / p.th)
        EndScaleformMovieMethod()
        p.scale = scale
    end
end

---@param show boolean
local function setVisible(show)
    if visible == show then return end

    visible = show
    SetMinimapOverlayDisplay(handle, 0.0, 0.0, 100.0, 100.0, show and 100.0 or 0.0)
end

---@return integer wait ms until the next tick
local function tick()
    local paused = IsPauseMenuActive()

    if paused and not wasPaused then
        pauseMpp = cfg.pauseMetersPerPixel -- the map opens at its default zoom
        resetZoomSampling()
    end

    wasPaused = paused
    setVisible(paused or cfg.showOnMinimap)

    if not paused and not cfg.showOnMinimap then return 500 end

    if not paused and overlayCfg.lockZoom then
        SetRadarZoomPrecise(overlayCfg.lockZoom + 0.0)
    end

    local mpp, upright

    if paused then
        samplePauseZoom()
        mpp, upright = pauseMpp, 0.0
    else
        mpp = Overlay.minimapMetersPerPixel()
        -- the minimap turns with the camera, turn icons back so they stay upright
        upright = overlayCfg.northUp and 0.0 or -GetGameplayCamRot(2).z
    end

    for id, it in pairs(items) do
        local icon = Icons.get(it.icon)

        if not it.placed or not icon or it.placed.txn ~= icon.txn then
            place(id, it, mpp, upright)
        else
            update(id, it, mpp, upright)
        end
    end

    return 0
end

---Loads the gfx and starts the update loop
local function init()
    if not cfg.enabled then
        state = 'missing'
        return
    end

    if not LoadResourceFile(cache.resource, cfg.gfx) then
        state = 'missing'
        lib.print.warn(('%s not found, custom icons fall back to the screen overlay / GTA sprite (see README)'):format(cfg.gfx))
        return
    end

    state = 'loading'
    handle = AddMinimapOverlay(cfg.gfx)

    local timeout = GetGameTimer() + 10000

    while not HasMinimapOverlayLoaded(handle) do
        if GetGameTimer() > timeout then
            state = 'missing'
            lib.print.error(('%s failed to load'):format(cfg.gfx))
            return
        end

        Wait(50)
    end

    state = 'ready'

    for _, cb in ipairs(readyListeners) do
        cb()
    end

    while true do
        Wait(next(items) and tick() or 500)
    end
end

---@return boolean
function MapOverlay.available()
    return state == 'ready'
end

---@param cb fun() called once the gfx has loaded
function MapOverlay.onReady(cb)
    readyListeners[#readyListeners + 1] = cb
end

---@param id string
---@param item MapOverlayItem
function MapOverlay.set(id, item)
    local old = items[id]

    items[id] = item

    if state ~= 'ready' or not old or not old.placed then return end

    if old.icon ~= item.icon or old.handle ~= item.handle or old.fixed ~= item.fixed or old.px ~= item.px then
        unplace(id) -- added again on the next tick
    else
        item.placed = old.placed
    end
end

---@param id string
function MapOverlay.remove(id)
    if not items[id] then return end

    if state == 'ready' then
        unplace(id)
    end

    items[id] = nil
end

CreateThread(init)

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource or state ~= 'ready' then return end

    for i = #order, 1, -1 do
        unplace(order[i])
    end
end)

return MapOverlay
