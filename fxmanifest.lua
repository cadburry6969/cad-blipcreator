fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'cad-blipcreator'
author 'Cadburry'
description 'Blip editor and dynamic blips with custom icons'
version '2.0.0'

shared_script '@ox_lib/init.lua'

client_script 'client/init.lua'
server_script 'server/init.lua'

ui_page 'web/build/index.html'

files {
    'config.lua',
    'shared/*.lua',
    'client/*.lua',
    'client/**/*.lua',
    'web/build/index.html',
    'web/build/assets/*',
    'data/dui.html',
    'data/*.gfx',
    'data/icons/*.png',
    'data/icons/*.svg',
}

dependencies {
    'ox_lib',
}
