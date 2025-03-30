fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Cadburry (Bytecode Studios)'
description 'Sanition Job with Snappy Phone Party System'
version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*'
}

client_scripts {
    'bridge/client.lua',
    'module/client.lua'
}

server_scripts {
    'bridge/server.lua',
    'module/server.lua'
}
