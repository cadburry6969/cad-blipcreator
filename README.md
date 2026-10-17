# cad-blipcreator

An in-game blip editor for FiveM. Create, edit and delete map blips without restarting the server, give them your own PNG or SVG icons, and limit them to jobs or gangs. Other resources can add their own blips through exports, including blips that follow players or vehicles.

[![Preview video](https://img.youtube.com/vi/NK1RT8KVt5U/0.jpg)](https://www.youtube.com/watch?v=NK1RT8KVt5U)

## Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Using the editor](#using-the-editor)
- [Configuration](#configuration)
- [Custom icons](#custom-icons)
- [Exports](#exports)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)
- [Building the UI](#building-the-ui)
- [Credits and license](#credits-and-license)

## Features
- **In-game editor** with a live preview: every change shows on your map before you save it.
- **Visual pickers** for all GTA blip sprites and colours, with search.
- **Custom icons** from PNG / SVG files or straight from a link, shown on the minimap and the pause map.
- **Pick on map**: click a point on the pause map to place a blip.
- **Job and gang permissions** for qbx_core, qb-core, es_extended and ox_core.
- **Area circles**, flashing, map legend groups and "only show when nearby".
- **Saved blips** survive restarts. Changes show for every player straight away.
- **Exports** for other resources: blips for everyone, one player, a list of players or an ace group, including blips that follow a player or vehicle.
- **Server checked**: only allowed players can edit, and the server validates everything the editor sends.

## Requirements
- [ox_lib](https://github.com/overextended/ox_lib)
- Optional: qbx_core, qb-core, es_extended or ox_core, for job / gang limited blips
- Optional: OneSync, so blips that follow far away players or vehicles keep moving

## Installation
1. Download `cad-blipcreator.zip` from the [latest release](https://github.com/cadburry6969/cad-blipcreator/releases/latest) and extract it into your `resources` folder.
2. Add it to `server.cfg` after ox_lib and your framework:
   ```cfg
   ensure ox_lib
   ensure cad-blipcreator
   ```
3. By default only `group.admin` can open the editor. To let other groups use it:
   ```cfg
   add_ace group.mod command.blipcreator allow
   ```
   Or set `editor.adminOnly = false` in `config.lua` to let everyone use it.
4. Join the server and type `/blipcreator`.

## Using the editor
Type `/blipcreator` to open the editor on the right side of the screen. The minimap stays visible, so you can watch your changes.

### The blip list
- **Search** by name, id, icon or the resource that made the blip.
- **Filter** by *Saved* (made in the editor), *From scripts* (made by other resources) or by permission.
- Click a blip to edit it, or **New blip** to create one at your position.

### Editing a blip
| Section | What you can set |
| --- | --- |
| General | Name, and who can see it (everyone, or a job / gang from `config.lua`) |
| Position | **Pick on map**, **My position**, **Waypoint**, or type the coordinates. **Copy coords** copies `vector3(x, y, z)`, **Teleport there** takes you to it |
| Appearance | Sprite, colour, size, opacity, where it shows (map and / or minimap), "only show when nearby", flashing |
| Custom icon | A PNG / SVG icon instead of the GTA sprite, and its size |
| Area circle | A coloured circle around the blip, with its radius and opacity |
| Map legend group | Groups blips under a name in the pause map legend |

**Pick on map** hides the editor and opens the pause map. Place a waypoint where the blip should go: the map closes, the editor comes back and the coordinates are filled in. Close the map instead to cancel.

**View on map** opens the pause map so you can check the blip, and brings the editor back when you close it.

**Save** stores the blip for everyone. Nothing changes for other players until you save. **Delete** asks you to click twice.

Blips made by other resources can be viewed and teleported to, but not edited. Change them in the resource that made them.

`Escape` closes a picker, then goes back to the list, then closes the editor.

## Configuration
Everything is in `config.lua`.

| Setting | Default | What it does |
| --- | --- | --- |
| `editor.command` | `'blipcreator'` | The command that opens the editor |
| `editor.adminOnly` | `true` | Only players with the command's ace can use the editor |
| `permissions` | Everyone | The jobs / gangs offered in the editor. A blip can only be saved with a permission listed here |
| `icons` | two examples | Custom icons loaded for every player, see [Custom icons](#custom-icons) |
| `maxDuiIcons` | `24` | Max SVG / website icons. Each uses a small hidden browser |
| `tracking` | | How often blips on players / vehicles update |
| `mapOverlay` | enabled | Icons on the pause map and minimap using `data/MINIMAP_LOADER.gfx` |
| `overlay` | enabled | Backup minimap icons, used only when `MINIMAP_LOADER.gfx` is missing |
| `debug` | `false` | Adds the `/dynblipcal` and `/dynblipstatus` commands |

Example permissions for police and EMS:
```lua
permissions = {
    { label = 'Everyone', value = 'none' },
    { label = 'Police', value = 'police' },
    { label = 'EMS', value = 'ambulance' },
},
```

## Custom icons
There are two ways to add icons.

### From a link, in game
Open the icon picker in the editor, paste an `https://` link ending in `.png`, `.svg`, `.jpg` or `.webp`, and press **Add**. The name comes from the file name unless you type one.
- The icon is sent to every player and saved, so it is still there after a restart.
- Hover an icon added this way to remove it. Icons used by a saved blip can't be removed until that blip uses another icon.

### From files, in the config
Put the file in `data/icons/` and add it to `icons` in `config.lua`:
```lua
icons = {
    police = 'data/icons/police.svg',
    shop = { src = 'data/icons/shop.png', size = 128 },        -- size of the loaded image in pixels
    remote = 'https://example.com/icon.png',
    shared = '@other-resource/images/icon.svg',               -- must be in that resource's files {}
},
```

PNG and JPG files in this resource load directly. SVGs, website images and files from other resources are drawn by a small hidden browser (see `maxDuiIcons`).

### Where icons show
| Map | With `MINIMAP_LOADER.gfx` (included) | Without it |
| --- | --- | --- |
| Minimap | The icon, exactly on the blip | The icon, drawn over the minimap at an estimated position |
| Pause map | The icon, exactly on the blip | The blip's GTA sprite |

Pick a GTA sprite and colour that look like your icon: they are used wherever the icon can't be shown.

## Exports
Blips made with exports are **not saved**. They are removed when the resource that made them stops. Blips saved in the editor can't be changed through exports.

Every function that can fail returns `nil` / `false` plus an error message:
```lua
local id, err = exports['cad-blipcreator']:AddDynamicBlip({ label = 'No position' })
print(id, err) -- nil  one of coords / entity / player / localEntity is required
```

### Server exports
Server blips are seen by the players you choose and stay in sync for players who join later.

| Export | Returns | Description |
| --- | --- | --- |
| `AddDynamicBlip(data, targets?)` | `id?, err?` | Creates a blip. Pass `data.id` to choose the id |
| `UpdateDynamicBlip(id, changes)` | `ok, err?` | Changes some fields. Set a field to `false` to remove it |
| `RemoveDynamicBlip(id)` | `removed` | Removes a blip |
| `SetDynamicBlipTargets(id, targets)` | `ok` | Changes who can see a blip |
| `GetDynamicBlip(id)` | `{ id, data, targets, owner, saved }?` | Reads a blip, including saved ones |
| `GetDynamicBlips()` | `table[]` | Reads every blip |
| `ClearDynamicBlips()` | | Removes every blip your resource made |
| `RegisterBlipIcon(name, source)` | `ok` | Adds an icon for every player, including players who join later. Pass `false` as the source to remove it |
| `ResyncDynamicBlips(playerId)` | | Sends a player all blips they can see again, for example after their aces change |

**Targets** decide who sees a server blip:
| Value | Who sees it |
| --- | --- |
| `nil` or `-1` | Everyone |
| `5` | Player 5 only. The blip is removed when they leave |
| `{ 1, 2, 3 }` | Those players |
| `{ ace = 'group.police' }` | Players with that ace, checked when the blip is sent |

### Client exports
Client blips are only seen by that player.

| Export | Returns | Description |
| --- | --- | --- |
| `AddDynamicBlip(data)` | `id?, err?` | Creates a blip for this player |
| `UpdateDynamicBlip(id, changes)` | `ok, err?` | Changes some fields of a blip made on this client |
| `RemoveDynamicBlip(id)` | `removed` | Removes a blip made on this client |
| `GetDynamicBlip(id)` | `{ id, source, handle, visible, data }?` | Reads any blip this player has, from the server or this client |
| `GetDynamicBlips()` | `table[]` | Reads every blip this player has |
| `GetDynamicBlipHandle(id)` | `number?` | The GTA blip handle, for any blip native you need |
| `ClearDynamicBlips()` | | Removes the blips your resource made on this client |
| `RegisterBlipIcon(name, source)` | `ok` | Adds an icon for this player only |
| `RemoveBlipIcon(name)` | | Removes an icon for this player |
| `IsBlipIconReady(name)` | `boolean` | True once the icon has loaded |

### Blip fields
Every field is optional except the position.

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `coords` | `vector3` | | Position. One of `coords`, `entity`, `player` or `localEntity` is required |
| `entity` | `number` | | Follows a networked entity (network id) |
| `player` | `number` | | Follows a player (server id) |
| `localEntity` | `number` | | Client only. Follows a local entity handle |
| `label` | `string` | `'Blip'` | Name shown on the map |
| `sprite` | `number` | `1` | [GTA blip sprite](https://docs.fivem.net/docs/game-references/blips/) |
| `colour` | `number` | `0` | [GTA blip colour](https://docs.fivem.net/docs/game-references/blips/#blip-colors) |
| `scale` | `number` | `1.0` | Size, `1.0` is normal |
| `alpha` | `number` | `255` | Opacity, 0 to 255 |
| `display` | `number` | `2` | `2` map and minimap, `3` pause map only, `5` minimap only, `8` map and minimap but not clickable |
| `shortRange` | `boolean` | `true` | Only shows on the minimap when nearby |
| `priority` | `number` | | Which blip is drawn on top |
| `flash`, `flashInterval` | `boolean`, `number` | | Flashing blip, interval in ms |
| `route`, `routeColour` | `boolean`, `number` | | GPS route to the blip |
| `heading`, `headingIndicator` | `number`, `boolean` | | Rotates the sprite / shows a heading cone |
| `radius` | `number` | | Adds an area circle, in metres |
| `radiusColour`, `radiusAlpha` | `number` | blip colour, `128` | Area circle colour and opacity |
| `category`, `categoryLabel` | `number`, `string` | | Legend group. Use 12 or higher for your own |
| `permissions` | `string` / `string[]` | `'none'` | Job / gang names that can see it. `'none'` means everyone |
| `icon` | `string` | | Name of a registered custom icon |
| `iconSize` | `number` | `24` | Icon size in pixels (at 1080p) |
| `iconRotate` | `boolean` | | Turns the icon with the entity's heading, or with `heading` |
| `iconTint` | `{ r, g, b, a }` | | Tints the icon (minimap backup overlay only) |
| `mapIconSize` | `number` | | Fixed icon size on the ground in metres, instead of a fixed size on screen |
| `iconFallback` | `boolean` | `true` | Shows the GTA sprite on the pause map when the icon can't be drawn there |
| `removeOnDrop` | `boolean` | `true` | Server only. Removes a `player` blip when that player leaves |

## Examples

### A police unit that follows the officer, only seen by police
```lua
-- server
local blips = exports['cad-blipcreator']

blips:RegisterBlipIcon('patrol_car', 'https://example.com/icons/patrol-car.svg')

local function addUnitBlip(playerId, callsign)
    return blips:AddDynamicBlip({
        id = ('unit_%d'):format(playerId),
        player = playerId,
        label = ('Unit %s'):format(callsign),
        sprite = 56, -- cop patrol
        colour = 3,
        icon = 'patrol_car',
        iconRotate = true,
        shortRange = false,
    }, { ace = 'group.police' })
end

-- switch it to flashing when they press panic
local function panic(playerId)
    blips:UpdateDynamicBlip(('unit_%d'):format(playerId), { flash = true, colour = 1 })
end
```

### A delivery stop for one player
```lua
-- client
local stop = exports['cad-blipcreator']:AddDynamicBlip({
    coords = vec3(-1037.4, -2737.8, 20.2),
    label = 'Delivery',
    sprite = 501, -- package
    colour = 5,
    route = true,
    routeColour = 5,
})

-- when the delivery is done
exports['cad-blipcreator']:RemoveDynamicBlip(stop)
```

### A temporary event area for everyone
```lua
-- server
local eventBlip = exports['cad-blipcreator']:AddDynamicBlip({
    coords = vec3(197.2, -935.7, 30.7),
    label = 'Car meet',
    sprite = 777, -- car meet
    colour = 27,
    radius = 150.0,
    radiusAlpha = 90,
    shortRange = false,
})

SetTimeout(30 * 60 * 1000, function()
    exports['cad-blipcreator']:RemoveDynamicBlip(eventBlip)
end)
```

## Troubleshooting
| Problem | What to check |
| --- | --- |
| `/blipcreator` does nothing | You need the command's ace (`group.admin` by default), or set `editor.adminOnly = false` |
| Saving says "unknown permission" | Add that job / gang to `permissions` in `config.lua` |
| A job blip doesn't show | The player needs that job or gang, and your framework must be one of the supported ones |
| An icon doesn't show | Set `debug = true`, restart, and run `/dynblipstatus` in the F8 console. It lists every icon and blip and why it is or isn't drawn |
| Minimap icons are off position without the gfx | Run `/dynblipcal` (debug mode) and adjust `overlay.range`, or set `overlay.anchor` if your HUD moves the minimap |

## Limitations
- GTA can't use images as blip sprites, so custom icons are drawn separately from the blip. The included `MINIMAP_LOADER.gfx` places them exactly on both maps.
- The pause map zoom can't be read by scripts, so icon size there is measured from mouse movement. After opening or zooming the map, icons resize once you move the mouse. With a controller the size doesn't adjust.
- Sprite pictures in the editor load from docs.fivem.net, and link icons load from their website, so players need an internet connection to see them.
- Permission checks run on each player's game, so every targeted player receives the blip data. Use server `targets` for anything that must stay secret.
- Blips on players or vehicles out of range need OneSync to keep moving.

## Building the UI
The editor is a React + TypeScript app in `web/`. Releases already include the built files in `web/build`. Rebuild only if you change `web/src`:
```bash
cd web
npm install
npm run build
```
`npm run dev` opens the editor in a normal browser with sample data.

## Credits and license
- cad-blipcreator by Cadburry, licensed under the [GNU GPL v3](LICENSE).
- `data/MINIMAP_LOADER.gfx` comes unmodified from the [ScaleformUI 5.8.1 release](https://github.com/manups4e/ScaleformUI/releases/tag/5.8.1) by manups4e, PhilippRendell and Lacol9, under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). It may not be used commercially. Delete it to go back to GTA sprites on the pause map.
- Sprite and colour data from the [FiveM blip reference](https://docs.fivem.net/docs/game-references/blips/).

## Support
- Questions or bugs: open an issue in this repository.
- Discord: https://discord.gg/qxGPARNwNP
