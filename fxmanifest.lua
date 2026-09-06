fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'qbemotemenu'
author 'qbcore2'
version '1.0.0'
description 'A qblib-native, configurable FiveM emote menu.'

dependencies {
    'qblib'
}

shared_script '@qblib/init.lua'

shared_scripts {
    'config.lua',
    'shared/emotes.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'
