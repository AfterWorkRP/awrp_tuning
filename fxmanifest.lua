fx_version 'cerulean'
game 'gta5'

lua54 'yes'
provide 'awrp_tuning'

author 'Afterwork Tuning'
description 'Zaawansowany system tuningu dla AWRP'
version '1.0.1'

dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql',
    'ox_target',
    'tgiann-inventory'
}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'config/locales/pl.lua',
    'config/config.lua',
    'config/config-mods.lua'
}

client_scripts {
    'client/main.lua',
    'client/target.lua',
    'client/tuning.lua',
    'client/tablet.lua',
    'client/dyno.lua',
    'client/animations.lua',
    'client/camera.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/items.lua',
    'server/billing.lua',
    'server/exports.lua'
}

ui_page 'web/index.html'
files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}