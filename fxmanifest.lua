fx_version 'cerulean'
game 'gta5'

author 'Afterwork Tuning'
description 'Zaawansowany system tuningu dla AWRP'
version '1.0.0'

-- Wymagane zasoby, bez nich skrypt się nie uruchomi
dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql',
    'ox_target',
    'tgiann-inventory'
}

-- Pliki ładowane po obu stronach (Client + Server)
shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config/locales/pl.lua',  -- DODANA LINIJA
    'config/config.lua',
    'config/config-mods.lua',
    'shared/utils.lua'
}

-- Pliki klienta
client_scripts {
    'client/main.lua',
    'client/target.lua',
    'client/tuning.lua',
    'client/tablet.lua',
    'client/dyno.lua',
    'client/animations.lua',
    'client/camera.lua'
}

-- Pliki serwera
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
    'server/items.lua',
    'server/billing.lua',
    'server/exports.lua'
}

-- Jeśli dodamy w przyszłości wykres hamowni w HTML/JS
ui_page 'web/index.html'
files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}