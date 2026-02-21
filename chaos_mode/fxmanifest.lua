fx_version 'cerulean'
game 'gta5'

name 'chaos_mode'
author 'codex'
description 'Random chaos events for sandbox FiveM servers'
version '1.0.0'

shared_script 'config.lua'
client_scripts {
    'client.lua',
    'sandbox_client.lua'
}

server_scripts {
    'server.lua',
    'sandbox_server.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}
