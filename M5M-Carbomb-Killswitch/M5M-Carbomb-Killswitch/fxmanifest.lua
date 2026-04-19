fx_version 'cerulean'
game 'gta5'

author 'Matrix5M'
description 'M5M-Carbomb-Killswitch - premium vehicle immobilizer, tracker, and staged sabotage scaffold'
version '0.1.8'

lua54 'yes'

escrow_ignore {
    'config/*.lua',
    'items.lua',
    'qb-items.lua',
    'database.sql',
    'install.md'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'bridge/shared.lua',
    'shared/logger.lua',
    'shared/utils.lua'
}

server_scripts {
    'bridge/server.lua',
    'server/database.lua',
    'server/sv_00_prelude.lua',
    'server/sv_10_corehelpers.lua',
    'server/sv_20_devices.lua',
    'server/sv_30_oxcallbacks.lua',
    'server/sv_40_actions.lua',
    'server/sv_50_tracker.lua',
    'server/sv_60_permissions.lua',
    'server/sv_70_logs.lua',
    'server/sv_80_cleanup.lua',
    'server/main.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/animations.lua',
    'client/state.lua',
    'client/install.lua',
    'client/remote.lua',
    'client/tracker.lua',
    'client/effects.lua',
    'client/detect.lua',
    'client/remove.lua',
    'client/targets.lua',
    'client/main.lua'
}


files {
    'config/*.lua',
    'database.sql',
    'items.lua',
    'qb-items.lua',
    'install.md'
}

dependencies {
    'oxmysql',
    'ox_lib'
}
