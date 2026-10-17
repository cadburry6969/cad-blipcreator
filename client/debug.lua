local config = require 'config'
local Schema = require 'shared.schema'
local Blips = require 'client.blips'
local Icons = require 'client.icons'
local MapOverlay = require 'client.render.mapoverlay'

local CALIBRATION_ID = '__calibration'

-- places a test blip 120 m north showing the GTA sprite and the icon together
RegisterCommand('dynblipcal', function(_, args)
    local mode = args[1]

    if mode == 'off' then
        Blips.remove(CALIBRATION_ID)
        return
    end

    if mode and tonumber(args[2]) and config.overlay.range[mode] then
        config.overlay.range[mode] = tonumber(args[2]) + 0.0
        print(('range.%s = %.1f'):format(mode, config.overlay.range[mode]))
    end

    local p = GetEntityCoords(cache.ped)
    local data = assert(Schema.merge(nil, {
        coords = vec3(p.x, p.y + 120.0, p.z),
        label = 'Overlay calibration',
        colour = 1,
        shortRange = false,
        icon = 'example_svg',
    }))

    Blips.remove(CALIBRATION_ID)

    local e = Blips.upsert(CALIBRATION_ID, data, 'local', cache.resource)
    e.debugBoth = true
    Blips.restyle(e)

    print('usage: /dynblipcal [foot|vehicle|vehicleFast|bigmap|locked] [metres] | /dynblipcal off')
end, false)

-- prints why an icon is or isn't showing (F8 console)
RegisterCommand('dynblipstatus', function()
    print('^5-- icons --^7')

    for name, icon in pairs(Icons.all()) do
        print(('%s  ready=%s  src=%s  dui=%s'):format(name, icon.ready, icon.src, icon.dui ~= nil))
    end

    print('^5-- blips --^7')

    for id, e in pairs(Blips.all()) do
        local d = e.data
        local plan = Blips.iconPlan(d)

        print(('%s [%s]  visible=%s  handle=%s  icon=%s  minimapIcon=%s  pauseIcon=%s  display=%s'):format(
            id, e.source, e.visible, e.handle, d.icon, plan.screen, plan.map, d.display
        ))
    end

    print(('pause map overlay (%s) available=%s'):format(config.mapOverlay.gfx, MapOverlay.available()))
    print(('minimapRendering=%s  pause=%s  bigmap=%s  interior=%s'):format(
        IsMinimapRendering(), IsPauseMenuActive(), IsBigmapActive(), GetInteriorFromEntity(cache.ped) ~= 0
    ))
end, false)
