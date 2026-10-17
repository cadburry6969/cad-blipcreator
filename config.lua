return {
    debug = false, -- extra prints plus the /dynblipcal and /dynblipstatus commands

    editor = {
        command = 'blipcreator',
        adminOnly = true, -- only players allowed to use the command (group.admin by default) can edit blips
    },

    -- jobs or gangs a blip can be limited to, shown in the editor
    permissions = {
        { label = 'Everyone', value = 'none' },
        -- { label = 'Police', value = 'police' },
        -- { label = 'EMS', value = 'ambulance' },
    },

    -- Icons loaded for every player. Use a path, or { src = path, size = pixels }.
    --   'data/icons/x.png'            image in this resource
    --   'data/icons/x.svg'            SVG in this resource
    --   '@other-resource/path/x.svg'  file from another resource (must be in its files {})
    --   'https://...'                 image from a website
    icons = {
        example_png = 'data/icons/example.png',
        example_svg = { src = 'data/icons/example.svg', size = 128 },
    },

    maxDuiIcons = 24, -- max SVG / website icons, each one uses a hidden browser

    tracking = {
        serverInterval = 1000,    -- ms between position updates for blips on far away players / vehicles (needs OneSync)
        serverMinDistance = 2.0,  -- metres moved before an update is sent
        attachCheckInterval = 500, -- ms between checks for players / vehicles coming near
    },

    -- Icons drawn over the minimap. Only used when MINIMAP_LOADER.gfx is missing or
    -- mapOverlay.showOnMinimap is false. Positions are estimated, tune them with /dynblipcal.
    overlay = {
        enabled = true,
        northUp = false,          -- true if your minimap always points north
        hideInInteriors = false,  -- hide icons inside buildings, where the minimap zooms differently
        showOnBigmap = true,      -- show icons on the expanded minimap (Z)
        center = vec2(0.5, 0.5),  -- where the player is on the minimap (0 to 1)
        iconScale = 1.0,          -- makes every icon bigger or smaller
        -- metres shown across the minimap width (also sets icon size when mapOverlay is used)
        range = {
            foot = 320.0,
            vehicle = 420.0,
            vehicleFast = 700.0,
            bigmap = 1400.0,
            locked = 320.0, -- used when lockZoom is set
        },
        fastSpeed = 40.0,         -- speed (m/s) where range.vehicleFast is used
        lockZoom = false,         -- a number (e.g. 1100) keeps the minimap at one zoom so icons size exactly
        bigmapScale = vec2(1.0, 2.55), -- expanded minimap size compared to the normal one
        anchor = nil,             -- { x = , y = , w = , h = } minimap area on screen (0 to 1) if your HUD moves it
    },

    -- Icons on the pause map and minimap using MINIMAP_LOADER.gfx (from ScaleformUI, see README).
    -- Icons line up exactly with the map, whatever your HUD layout. Without the file the minimap
    -- uses the overlay settings above and the pause map shows the GTA sprite.
    mapOverlay = {
        enabled = true,
        gfx = 'data/MINIMAP_LOADER.gfx',
        showOnMinimap = true,      -- also use it for the minimap
        iconScale = 1.0,           -- makes every icon bigger or smaller
        -- The pause map zoom can't be read, so it is measured when you move the mouse over the map.
        -- This value is used when the map opens, until the mouse moves (debug prints measurements).
        pauseMetersPerPixel = 2.0,
        moveThreshold = 1.0,       -- metres a blip moves before its icon is moved
        flipY = false,             -- only if icons show up mirrored north / south
    },
}
