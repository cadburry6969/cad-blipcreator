---@class BlipIcon
---@field name string
---@field src string
---@field size number texture size in pixels
---@field txd string texture dictionary
---@field txn string texture name
---@field ready boolean
---@field dui number? hidden browser used to render SVG / remote images

local config = require 'config'

local Icons = {}

local TXD_NAME = 'cad_blip_icons'

---@type number?
local txdHandle
---@type table<string, BlipIcon>
local icons = {}
---@type fun(name: string)[]
local listeners = {}
local duiCount = 0
local texSeq = 0

---@return number
local function getTxd()
    if not txdHandle then
        txdHandle = CreateRuntimeTxd(TXD_NAME)
    end

    return txdHandle
end

---@param str string
---@return string
local function urlEncode(str)
    return (str:gsub('[^%w%-_%.~]', function(c) return ('%%%02X'):format(c:byte()) end))
end

---@param name string
local function notify(name)
    for _, cb in ipairs(listeners) do
        cb(name)
    end
end

---Address a browser can load the file from
---@param src string
---@return string
local function webUrl(src)
    if src:find('^https?://') or src:find('^data:') then return src end

    local res, path = src:match('^@([^/]+)/(.+)$')

    return ('https://cfx-nui-%s/%s'):format(res or cache.resource, path or src)
end

---Picks how a source is loaded: 'image' (read directly) or 'dui' (rendered by a hidden browser)
---@param src string
---@return 'image'|'dui'|nil kind
---@return string? target
local function classify(src)
    if src:find('^data:image/png') or src:find('^data:image/jpe?g') then return 'image', src end
    if src:find('^data:image/svg') or src:find('^https?://') then return 'dui', src end

    local res = src:match('^@([^/]+)/')
    local ext = (src:match('%.(%w+)$') or ''):lower()
    local isImage = ext == 'png' or ext == 'jpg' or ext == 'jpeg'

    if not res and isImage then
        if not LoadResourceFile(cache.resource, src) then return end

        return 'image', src
    end

    if isImage or ext == 'svg' or ext == 'webp' then
        return 'dui', webUrl(src)
    end
end

---@param icon BlipIcon
---@param url string
---@return boolean ok
local function loadDui(icon, url)
    if duiCount >= config.maxDuiIcons then
        lib.print.warn(('icon "%s" skipped: maxDuiIcons (%d) reached'):format(icon.name, config.maxDuiIcons))
        return false
    end

    local page = ('https://cfx-nui-%s/data/dui.html?src=%s'):format(cache.resource, urlEncode(url))
    local dui = CreateDui(page, icon.size, icon.size)

    duiCount = duiCount + 1
    icon.dui = dui

    CreateThread(function()
        local timeout = GetGameTimer() + 10000

        while not IsDuiAvailable(dui) do
            if GetGameTimer() > timeout or icons[icon.name] ~= icon then return end

            Wait(50)
        end

        CreateRuntimeTextureFromDuiHandle(getTxd(), icon.txn, GetDuiHandle(dui))
        icon.ready = true
        notify(icon.name)
    end)

    return true
end

---Registers an icon, replacing any icon with the same name
---@param name string
---@param source BlipIconSource
---@return boolean ok
function Icons.register(name, source)
    local src, size = source, 128

    if type(source) == 'table' then
        src, size = source.src, source.size or 128
    end

    if type(name) ~= 'string' or type(src) ~= 'string' then return false end

    local existing = icons[name]
    if existing and existing.src == src and existing.size == math.floor(size) then return true end

    local kind, target = classify(src)

    if not kind or not target then
        lib.print.error(('icon "%s": unsupported or missing source "%s"'):format(name, src))
        return false
    end

    Icons.remove(name, true)

    -- textures can't be deleted, so each registration gets a new texture name
    texSeq = texSeq + 1

    ---@type BlipIcon
    local icon = {
        name = name,
        src = src,
        size = math.floor(size),
        txd = TXD_NAME,
        txn = ('%s_%d'):format(name, texSeq),
        ready = false,
    }

    icons[name] = icon

    if kind == 'image' then
        local tex = CreateRuntimeTextureFromImage(getTxd(), icon.txn, target)

        if tex and tex ~= 0 then
            icon.ready = true
            notify(name)
            return true
        end

        -- the game couldn't read the image, let the browser try
        target = webUrl(target)
    end

    return loadDui(icon, target)
end

---@param name string
---@param silent boolean? skip notifying listeners
function Icons.remove(name, silent)
    local icon = icons[name]
    if not icon then return end

    if icon.dui then
        DestroyDui(icon.dui)
        duiCount = duiCount - 1
    end

    icons[name] = nil

    if not silent then
        notify(name)
    end
end

---@param name string
---@return BlipIcon?
function Icons.get(name)
    return icons[name]
end

---@param name string
---@return boolean
function Icons.exists(name)
    return icons[name] ~= nil
end

---@param name string
---@return boolean
function Icons.isReady(name)
    return icons[name] ~= nil and icons[name].ready
end

---@return table<string, BlipIcon>
function Icons.all()
    return icons
end

---Icons with an address the editor can show them from
---@param linkIcons string[]? names of icons added from a link in the editor
---@return { name: string, url: string, link: boolean }[]
function Icons.list(linkIcons)
    local isLink = {}

    for _, name in ipairs(linkIcons or {}) do
        isLink[name] = true
    end

    local list = {}

    for name, icon in pairs(icons) do
        list[#list + 1] = { name = name, url = webUrl(icon.src), link = isLink[name] == true }
    end

    table.sort(list, function(a, b) return a.name < b.name end)

    return list
end

---@param cb fun(name: string) called when an icon is added, finishes loading or is removed
function Icons.onChange(cb)
    listeners[#listeners + 1] = cb
end

for name, source in pairs(config.icons) do
    Icons.register(name, source)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource then return end

    for _, icon in pairs(icons) do
        if icon.dui then
            DestroyDui(icon.dui)
        end
    end
end)

return Icons
