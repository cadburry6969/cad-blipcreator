fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Cadburry (ByteCode Studios)'
description 'Create blips on the go (standalone)'
version '1.2'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'bridge/client/*.lua',
    'modules/**/client.lua',
}

server_scripts {
    -- 'bridge/server/*.lua',
    'modules/**/server.lua',
}

dependencies {
    'ox_lib',
}
