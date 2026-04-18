-- Add these items to your qb-core/shared/items.lua
-- This file is formatted for QBCore / qb-inventory installs.
-- Copy the entries you want into QBShared.Items.

return {
    ['killswitch_instant'] = {
        name = 'killswitch_instant',
        label = 'Instant Killswitch Device',
        weight = 250,
        type = 'item',
        image = '',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Installs a hidden device that instantly disables the engine when activated.'
    },
    ['killswitch_delayed'] = {
        name = 'killswitch_delayed',
        label = 'Delayed Killswitch Device',
        weight = 250,
        type = 'item',
        image = '',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Installs a hidden device that shuts the vehicle down after a short delay.'
    },
    ['car_bomb'] = {
        name = 'car_bomb',
        label = 'Car Bomb',
        weight = 250,
        type = 'item',
        image = 'car_bomb.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Installs a hidden device that immediately pushes the vehicle into catastrophic fire damage when activated.'
    },
    ['killswitch_emp'] = {
        name = 'killswitch_emp',
        label = 'EMP Killswitch Device',
        weight = 250,
        type = 'item',
        image = '',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Installs a hidden device that triggers a temporary EMP-style disruption.'
    },
    ['killswitch_remote'] = {
        name = 'killswitch_remote',
        label = 'Matrix Remote',
        weight = 100,
        type = 'item',
        image = '',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'A remote used to track linked vehicles and activate or deactivate installed killswitches.'
    },
    ['device_scanner'] = {
        name = 'device_scanner',
        label = 'Signal Scanner',
        weight = 200,
        type = 'item',
        image = '',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Used to scan vehicles for hidden sabotage devices.'
    },
    ['device_removal_kit'] = {
        name = 'device_removal_kit',
        label = 'Removal Kit',
        weight = 200,
        type = 'item',
        image = '',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Tools used to remove a detected sabotage device.'
    }
}
