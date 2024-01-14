-- input menu to create new blip
---@param uniqueId any
---@param data table
---@param teleport boolean
local function AddBlip(uniqueId, data, teleport)
    local coords = GetCoords(teleport)
    local input = lib.inputDialog(uniqueId and 'Edit Blip' or 'Add Blip', {
        {type = 'input', label = 'Name', description = 'Enter the name of blip', icon = 'fa-solid fa-tags', required = true, default = data?.name, min = 1},
        {type = 'number', label = 'Sprite', description = 'Enter blip sprite', icon = 'fa-solid fa-icons', required = true, default = data?.sprite, min = 1, step = 1},
        {type = 'number', label = 'Scale', description = 'Enter blip scale', icon = 'fa-solid fa-text-width', required = true, default = data?.scale or 100, min = 0},
        {type = 'number', label = 'Colour', description = 'Enter blip colour', icon = 'fa-solid fa-droplet', required = true, default = data?.colour, min = 1},
        {type = 'select', label = 'Show', description = 'Select blip display type', icon = 'fa-solid fa-eye', required = true, default = data?.display or 8, options = {
            { label = "Doesn't show up, ever, anywhere.", value = 0 },
            { label = "Shows on both main map and minimap. (Selectable)", value = 2 },
            { label = "Shows on main map only. (Selectable)", value = 3 },
            { label = "Shows on main map only. (Selectable)", value = 4 },
            { label = "Shows on minimap only.", value = 5 },
            { label = "Shows on both main map and minimap. (Not selectable)", value = 8 },
        }},
        {type = 'checkbox', label = 'Short Range', checked = data?.srange or true},
        {type = 'select', label = 'Permissions', description = 'Permission to view this blip', icon = 'fa-solid fa-lock', required = false, default = data?.permissions or 'none', options = Config.Permissions},
    })
    if not input or not input[1] or not input[2] or not input[3] or not input[4] or not input[5] or not input[6] then return end
    local _data = {
        coords = coords,
        name = input[1],
        sprite = input[2],
        scale = input[3],
        colour = input[4],
        display = input[5],
        srange = input[6],
        permissions = input[7],
    }
    TriggerServerEvent('cad-blipcreator:saveBlip', uniqueId, _data)
end

-- edit selected blip
---@param uniqueId any
---@param data table
local function BlipOptions(uniqueId, data)
    lib.registerContext({
        id = 'cad_blipoptions',
        title = 'Manage - '..data.name,
        menu = 'cad_manage_blips',
        options = {
            {
                title = 'Edit Blip',
                icon = 'fa-solid fa-pen',
                onSelect = function()
                    AddBlip(uniqueId, data, Config.TeleportAtCoords)
                end
            },
            {
                title = 'Teleport To Blip',
                icon = 'fa-solid fa-map-pin',
                onSelect = function()
                    local _coords = data.coords
                    SetEntityCoords(PlayerPedId(), _coords.x, _coords.y, _coords.z, false, false, false, false)
                end
            },
            {
                title = 'Remove Blip',
                icon = 'fa-solid fa-trash',
                onSelect = function()
                    TriggerServerEvent('cad-blipcreator:removeBlip', uniqueId)
                end
            }
        }
    })
    lib.showContext('cad_blipoptions')
end

-- show all existing blips
local function ManageBlips()
    local options = {}
    local blips = GlobalState.blips
    for uniqueId, data in pairs(blips) do
        options[#options+1] = {
            title = data.name,
            description = ('vector3(%s, %s, %s)'):format(tostring(data.coords.x), tostring(data.coords.y), tostring(data.coords.z)),
            icon = 'fa-solid fa-map-pin',
            onSelect = function()
                BlipOptions(uniqueId, data)
            end
        }
    end
    if #options < 1 then return lib.notify({ description = 'No blips created', type = 'error' }) end
    lib.registerContext({
        id = 'cad_manage_blips',
        title = 'Manage Blips',
        menu = 'cad_mainmenu_blips',
        options = options
    })
    lib.showContext('cad_manage_blips')
end

-- event to open blip manager
RegisterNetEvent('cad-blipcreator:openMenu', function()
    lib.registerContext({
        id = 'cad_mainmenu_blips',
        title = 'Blips Menu',
        options = {
            {
                title = 'Create Blip',
                icon = 'fa-solid fa-plus',
                onSelect = function()
                    AddBlip(nil, {}, Config.TeleportAtCoords)
                end
            },
            {
                title = 'Manage Blips',
                icon = 'fa-solid fa-list',
                onSelect = function()
                    ManageBlips()
                end
            }
        }
    })
    lib.showContext('cad_mainmenu_blips')
end)

AddEventHandler('playerSpawned', function ()
    RefreshBlips()
end)

AddEventHandler('onResourceStart', function (resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    RefreshBlips()
end)
