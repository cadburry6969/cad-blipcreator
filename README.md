# Blipcreator

Create, edit and delete map blips in game with an editor, and give them custom PNG / SVG icons. Saved blips survive restarts. Other resources can add their own blips through exports.

## Preview (Old)
[![Click Here](https://img.youtube.com/vi/NK1RT8KVt5U/0.jpg)](https://www.youtube.com/watch?v=NK1RT8KVt5U)

## Features
- In-game editor with live preview on the map while you edit
- Sprite and colour pickers with pictures of every GTA blip and colour
- Custom PNG / SVG icons on the minimap and the pause map, from files or from a link
- Pick a blip's position by clicking on the pause map
- Search the blip list and filter by saved, from scripts, or permission
- Limit blips to jobs or gangs (qbx_core, qb-core, es_extended, ox_core)
- Area circles, flashing, map legend groups, "only show when nearby"
- Exports for other resources, including blips that follow players or vehicles

## Install
1. Requires [ox_lib](https://github.com/overextended/ox_lib).
2. Add `ensure cad-blipcreator` to `server.cfg` after `ox_lib` and your framework.
3. By default only `group.admin` can open the editor. Give it to others with `add_ace group.mod command.blipcreator allow`, or set `editor.adminOnly = false` in `config.lua`.
4. In game, type `/blipcreator`.

## Using the editor
- **New blip** starts at your position. To move it:
  - **Pick on map** hides the editor and opens the pause map. Place a waypoint where the blip should go: the map closes, the editor comes back, and the coordinates are filled in. Close the map instead to cancel. A waypoint you already had is kept; otherwise the one you placed is removed.
  - **My position** or **Waypoint** use where you stand or your current waypoint.
- **Copy coords** copies `vector3(x, y, z)` to the clipboard, and **Teleport there** takes you to the blip.
- The height comes from the ground at that point. Far away from you the ground isn't loaded, so the previous height is kept. Blips only use x and y, so this only matters for teleporting.
- Every change shows on your map straight away. **View on map** opens the pause map and brings the editor back when you close it.
- **Save** stores the blip for everyone. Nothing changes for other players until you save.
- Blips made by other resources are listed under **From scripts**. You can view and teleport to them, but not edit them.
- `Escape` closes a picker, then goes back to the list, then closes the editor.

## Config (`config.lua`)
| Setting | What it does |
| --- | --- |
| `editor.command` / `editor.adminOnly` | The command name, and whether it needs the command ace |
| `permissions` | The jobs / gangs offered in the editor. A blip can only be saved with a permission listed here |
| `icons` | Custom icons, by name. Put files in `data/icons/` |
| `overlay` | Fallback minimap icons, used when `MINIMAP_LOADER.gfx` is missing |
| `mapOverlay` | Icons on the pause map and minimap through `data/MINIMAP_LOADER.gfx` |
| `debug` | Adds `/dynblipcal` and `/dynblipstatus` for checking icons |

## Custom icons
**From a link (in game):** open the icon picker in the editor, paste an `https://` link ending in `.png`, `.svg`, `.jpg` or `.webp`, and press **Add**. The name is taken from the file name unless you type one. The icon is sent to every player, saved in `store/blips.json`, and loaded again after a restart. Hover an icon added this way to remove it. An icon used by a saved blip can't be removed until that blip uses another icon.

**From files (config):** add an entry to `icons` in `config.lua`:

```lua
icons = {
    police = 'data/icons/police.svg',
    shop = { src = 'data/icons/shop.png', size = 128 },
    remote = 'https://example.com/icon.png',
    shared = '@other-resource/images/icon.svg', -- must be in that resource's files {}
},
```

PNG and JPG files in this resource load directly. SVGs, website images and files from other resources are drawn by a hidden browser, one per icon (`maxDuiIcons`, default 24).

Icons need `data/MINIMAP_LOADER.gfx` to show on the pause map. It comes unmodified from `ScaleformUI_Assets.zip` in the [ScaleformUI 5.8.1 release](https://github.com/manups4e/ScaleformUI/releases/tag/5.8.1), by manups4e, PhilippRendell and Lacol9, under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). That allows non-commercial use with credit, so check it fits before using it in a paid resource. Delete the file to go back to GTA sprites on the pause map.

## Exports
Blips made with exports are not saved, and are removed when the resource that made them stops.

### Server (seen by players you choose)
```lua
local blips = exports['cad-blipcreator']

blips:RegisterBlipIcon('unit', 'data/icons/unit.svg') -- every player, including ones who join later

-- targets: nil or -1 = everyone, 5 = one player, { 1, 2 } = a list, { ace = 'group.police' }
local id = blips:AddDynamicBlip({
    player = source,
    label = 'Unit 12',
    sprite = 56,
    colour = 3,
    icon = 'unit',
    iconRotate = true,
}, { ace = 'group.police' })

blips:UpdateDynamicBlip(id, { flash = true })
blips:SetDynamicBlipTargets(id, -1)
blips:RemoveDynamicBlip(id)
blips:GetDynamicBlip(id)
blips:GetDynamicBlips()
blips:ClearDynamicBlips()        -- everything your resource made
blips:ResyncDynamicBlips(source) -- after a player's aces change
```

### Client (seen only by that player)
```lua
local id = exports['cad-blipcreator']:AddDynamicBlip({
    coords = vec3(200.0, -930.0, 30.0),
    label = 'Drop off',
    route = true,
})

exports['cad-blipcreator']:UpdateDynamicBlip(id, { coords = vec3(210.0, -940.0, 30.0) })
exports['cad-blipcreator']:RemoveDynamicBlip(id)
exports['cad-blipcreator']:GetDynamicBlipHandle(id) -- the GTA blip handle
```

### Blip fields
| Field | Type | Notes |
| --- | --- | --- |
| `coords` / `entity` / `player` / `localEntity` | position | One is required. `entity` is a network id, `player` a server id, `localEntity` client only |
| `label`, `sprite`, `colour`, `scale`, `alpha` | | `scale` 1.0 is normal size |
| `display` | number | `2` map and minimap, `3` pause map only, `5` minimap only, `8` not clickable |
| `shortRange`, `flash`, `route`, `routeColour`, `priority` | | |
| `radius`, `radiusColour`, `radiusAlpha` | | Adds an area circle |
| `category`, `categoryLabel` | | Legend group, use 12 or higher |
| `permissions` | | `'none'`, a job / gang name, or a list of names |
| `icon`, `iconSize`, `iconRotate`, `iconTint`, `mapIconSize` | | Custom icon by name, size in pixels |

In `UpdateDynamicBlip`, set a field to `false` to remove it (`icon = false`). Saved blips can only be changed in the editor.

## Editing the UI
The editor is a React + TypeScript app in `web/`. The built files in `web/build` are what the game loads, so rebuild after changing anything in `web/src`:

```bash
cd web
npm install
npm run build
```

`npm run dev` opens it in a browser with sample data.

## Limitations
- GTA can't use images as blip sprites, so custom icons are drawn separately. Without `MINIMAP_LOADER.gfx`, the pause map shows the GTA sprite and minimap icon positions are estimated (tune with `/dynblipcal`).
- The pause map zoom can't be read, so icon size there is measured from mouse movement. Until you move the mouse after opening or zooming the map, `mapOverlay.pauseMetersPerPixel` is used. With a controller the size doesn't adjust.
- Sprite pictures in the editor load from docs.fivem.net, so they need an internet connection. Link icons need every player to be able to reach that website.
- Permission checks run on each player's game, so every targeted player receives the blip data. Use server `targets` for anything secret.
- Blips on players or vehicles out of range need OneSync to keep moving.

## Contact
- If you have any questions or need assistance, feel free to open an issue in this repository.
- Join Discord: https://discord.gg/qxGPARNwNP
