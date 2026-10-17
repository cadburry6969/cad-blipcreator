---@class OverlayItem
---@field handle number blip handle
---@field icon string
---@field size number pixels at 1080p
---@field tint number[]?
---@field rotate boolean?
---@field heading number?
---@field entity number?
---@field shortRange boolean
---@field alpha number

---@class MinimapRect
---@field x number left (0 to 1 of screen width)
---@field y number top (0 to 1 of screen height)
---@field w number
---@field h number

---@class OverlayFrame
---@field anchor MinimapRect
---@field aspect number
---@field camHeading number
---@field sin number
---@field cos number
---@field origin vector3
---@field cx number screen x of the player on the minimap
---@field cy number screen y of the player on the minimap
---@field ppmX number screen units per metre, horizontal
---@field ppmY number screen units per metre, vertical

local config = require 'config'
local Icons = require 'client.icons'

local cfg = config.overlay

local Overlay = {}

---@type table<string, OverlayItem>
local items = {}
local count = 0
local running = false

---@type { x: number, bottom: number, w: number, h: number }?
local anchorCache
local anchorExpires = 0

---Estimates where the minimap is on screen from the default GTA layout
---@param big boolean expanded minimap
---@return MinimapRect
local function computeAnchor(big)
    if cfg.anchor then return cfg.anchor end

    local now = GetGameTimer()

    if not anchorCache or now > anchorExpires then
        local aspect = GetAspectRatio(false)
        local inset = (1.0 - GetSafeZoneSize()) * 0.5
        local w = 1.0 / (4.0 * aspect)
        local h = 1.0 / 5.674
        local x = inset

        if aspect > 2.0 then
            x = x + w * 0.845
            w = w * 0.76
        elseif aspect > 1.8 then
            x = x + w * 0.2225
            w = w * 0.995
        end

        anchorCache = { x = x, bottom = 1.0 - inset, w = w, h = h }
        anchorExpires = now + 1000
    end

    local a = anchorCache --[[@as { x: number, bottom: number, w: number, h: number }]]
    local w, h = a.w, a.h

    if big then
        w, h = w * cfg.bigmapScale.x, h * cfg.bigmapScale.y
    end

    return { x = a.x, y = a.bottom - h, w = w, h = h }
end

---Estimated metres shown across the minimap width
---@param vehicle number|false
---@param big boolean expanded minimap
---@return number
local function currentRange(vehicle, big)
    if cfg.lockZoom then return cfg.range.locked end
    if big then return cfg.range.bigmap end
    if not vehicle then return cfg.range.foot end

    local t = math.min(GetEntitySpeed(vehicle) / cfg.fastSpeed, 1.0)

    return cfg.range.vehicle + (cfg.range.vehicleFast - cfg.range.vehicle) * t
end

---@return boolean
local function shouldDraw()
    -- IsHudHidden() is not checked because custom HUDs often hide the HUD but keep the minimap
    if IsPauseMenuActive() or not IsMinimapRendering() then return false end
    if IsBigmapActive() and not cfg.showOnBigmap then return false end
    if cfg.hideInInteriors and GetInteriorFromEntity(cache.ped) ~= 0 then return false end

    return true
end

---Debug outline of the estimated minimap area
---@param a MinimapRect
local function drawOutline(a)
    local t = 0.0015

    DrawRect(a.x + a.w * 0.5, a.y, a.w, t, 255, 0, 255, 200)
    DrawRect(a.x + a.w * 0.5, a.y + a.h, a.w, t, 255, 0, 255, 200)
    DrawRect(a.x, a.y + a.h * 0.5, t, a.h, 255, 0, 255, 200)
    DrawRect(a.x + a.w, a.y + a.h * 0.5, t, a.h, 255, 0, 255, 200)
    DrawRect(a.x + a.w * cfg.center.x, a.y + a.h * cfg.center.y, 0.003, 0.005, 255, 0, 255, 255)
end

---@param it OverlayItem
---@param ctx OverlayFrame
local function drawItem(it, ctx)
    local icon = Icons.get(it.icon)
    if not icon or not icon.ready or not DoesBlipExist(it.handle) then return end

    local pos = GetBlipInfoIdCoord(it.handle)
    local dx, dy = pos.x - ctx.origin.x, pos.y - ctx.origin.y
    local right = dx * ctx.cos + dy * ctx.sin
    local up = -dx * ctx.sin + dy * ctx.cos
    local sx = ctx.cx + right * ctx.ppmX
    local sy = ctx.cy - up * ctx.ppmY

    local ih = (it.size / 1080.0) * cfg.iconScale
    local iw = ih / ctx.aspect
    local a = ctx.anchor
    local minX, maxX = a.x + iw * 0.5, a.x + a.w - iw * 0.5
    local minY, maxY = a.y + ih * 0.5, a.y + a.h - ih * 0.5

    if sx < minX or sx > maxX or sy < minY or sy > maxY then
        if it.shortRange then return end

        -- far away blips stay on the minimap edge, like GTA blips
        local vx, vy, t = sx - ctx.cx, sy - ctx.cy, 1.0

        if vx > 0 then
            t = math.min(t, (maxX - ctx.cx) / vx)
        elseif vx < 0 then
            t = math.min(t, (minX - ctx.cx) / vx)
        end

        if vy > 0 then
            t = math.min(t, (maxY - ctx.cy) / vy)
        elseif vy < 0 then
            t = math.min(t, (minY - ctx.cy) / vy)
        end

        sx, sy = ctx.cx + vx * t, ctx.cy + vy * t
    end

    local rot = 0.0

    if it.rotate then
        local heading = it.heading or 0.0

        if it.entity and DoesEntityExist(it.entity) then
            heading = GetEntityHeading(it.entity)
        end

        rot = ctx.camHeading - heading
    end

    local tint = it.tint or {}
    local alpha = math.floor((tint[4] or 255) * (it.alpha / 255))

    DrawSprite(icon.txd, icon.txn, sx, sy, iw, ih, rot, tint[1] or 255, tint[2] or 255, tint[3] or 255, alpha)
end

---Builds the per-frame values every icon needs
---@return OverlayFrame
local function buildFrame()
    local vehicle = cache.vehicle
    local anchor = computeAnchor(IsBigmapActive())
    local aspect = GetAspectRatio(false)
    local camHeading = cfg.northUp and 0.0 or GetGameplayCamRot(2).z
    local rad = math.rad(camHeading)
    local range = currentRange(vehicle, IsBigmapActive())

    return {
        anchor = anchor,
        aspect = aspect,
        camHeading = camHeading,
        sin = math.sin(rad),
        cos = math.cos(rad),
        origin = GetEntityCoords(vehicle or cache.ped),
        cx = anchor.x + anchor.w * cfg.center.x,
        cy = anchor.y + anchor.h * cfg.center.y,
        ppmX = anchor.w / range,
        ppmY = anchor.w * aspect / range,
    }
end

---Starts the draw loop if it isn't running
local function run()
    if running then return end

    running = true

    CreateThread(function()
        while count > 0 do
            local wait = 0

            if cfg.lockZoom then
                SetRadarZoomPrecise(cfg.lockZoom + 0.0)
            end

            if shouldDraw() then
                local frame = buildFrame()

                SetScriptGfxDrawOrder(7) -- draw on top of the minimap

                for _, it in pairs(items) do
                    drawItem(it, frame)
                end

                if config.debug then
                    drawOutline(frame.anchor)
                end
            elseif not cfg.lockZoom then
                wait = 200
            end

            Wait(wait)
        end

        running = false
    end)
end

---Estimated minimap scale, used to size map overlay icons on the minimap
---@return number metres per screen pixel
function Overlay.minimapMetersPerPixel()
    local big = IsBigmapActive()
    local anchor = computeAnchor(big)
    local resX = GetActiveScreenResolution()

    return currentRange(cache.vehicle, big) / (anchor.w * resX)
end

---@param id string
---@param item OverlayItem
function Overlay.set(id, item)
    if not items[id] then
        count = count + 1
    end

    items[id] = item
    run()
end

---@param id string
function Overlay.remove(id)
    if not items[id] then return end

    items[id] = nil
    count = count - 1
end

return Overlay
