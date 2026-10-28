fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'kora_emotemenu'
-- Keep the legacy resource name resolvable for exports['qbemotemenu'] callers.
provide 'qbemotemenu'
author 'qbcore2'
version '1.0.0'
description 'A qblib-native, configurable FiveM emote menu.'

dependencies {
    'kora_lib'
}

shared_script '@kora_lib/init.lua'

shared_scripts {
    'config.lua',
    'shared/emotes.lua'
}

client_scripts {
    'client/main.lua',
    'client/emote_creator.lua',
}
server_script {
    'server/**.lua'
}
