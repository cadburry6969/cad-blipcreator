fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Cadburry (ByteCode Studios)'
description 'Create blips on the go (standalone)'
version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

dependencies {
    'ox_lib',
}