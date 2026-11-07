fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'kora_emotemenu'
-- Keep the legacy resource name resolvable for exports['qbemotemenu'] callers.
provide 'qbemotemenu'
author 'qbcore2'
version '1.0.0'
description 'A configurable FiveM emote menu with a live React emote creator.'

ui_page 'ui/dist/index.html'

-- `dependency` singular, called once per dependency: this codebase's convention.
-- The plural `dependencies { ... }` form does not enforce FXServer load order.
dependency 'kora_lib'
dependency 'kora_theme'

shared_script '@kora_lib/init.lua'

shared_scripts {
    'config.lua',
    'shared/emotes.lua'
}

client_scripts {
    '@kora_theme/client/bridge.lua',
    'client/main.lua',
    'client/emote_creator.lua',
}
server_script {
    'server/**.lua'
}

files {
    'ui/dist/index.html',
    'ui/dist/assets/**/*'
}
