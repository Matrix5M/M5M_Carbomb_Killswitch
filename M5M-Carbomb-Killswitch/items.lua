return {
    killswitch_instant = {
        name = 'killswitch_instant',
        label = 'Instant Killswitch Device',
        weight = 250,
        type = 'item',
        image = 'killswitch_instant.png',
        unique = false,
        stack = true,
        close = true,
        useable = true,
        description = 'Installs a hidden device that instantly disables the engine when activated.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useInstantKillswitch'
        }
    },
    killswitch_delayed = {
        name = 'killswitch_delayed',
        label = 'Delayed Killswitch Device',
        weight = 250,
        type = 'item',
        image = 'killswitch_delayed.png',
        unique = false,
        stack = true,
        close = true,
        useable = true,
        description = 'Installs a hidden device that shuts the vehicle down after a short delay.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useDelayedKillswitch'
        }
    },
    car_bomb = {
        name = 'car_bomb',
        label = 'Car Bomb',
        weight = 250,
        type = 'item',
        image = 'car_bomb.png',
        unique = false,
        stack = true,
        close = true,
        useable = true,
        description = 'Installs a hidden device that immediately pushes the vehicle into catastrophic fire damage when activated.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useStagedKillswitch'
        }
    },
    killswitch_emp = {
        name = 'killswitch_emp',
        label = 'EMP Killswitch Device',
        weight = 250,
        type = 'item',
        image = 'killswitch_emp.png',
        unique = false,
        stack = true,
        close = true,
        useable = true,
        description = 'Installs a hidden device that triggers a temporary EMP-style disruption.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useEmpKillswitch'
        }
    },
    killswitch_remote = {
        name = 'killswitch_remote',
        label = 'Matrix Remote',
        weight = 100,
        type = 'item',
        image = 'killswitch_remote.png',
        unique = false,
        stack = false,
        close = true,
        useable = true,
        description = 'A remote used to track linked vehicles and activate or deactivate installed killswitches.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useKillswitchRemote'
        }
    },
    device_scanner = {
        name = 'device_scanner',
        label = 'Signal Scanner',
        weight = 200,
        type = 'item',
        image = 'device_scanner.png',
        unique = false,
        stack = false,
        close = true,
        useable = true,
        description = 'Used to scan vehicles for hidden sabotage devices.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useDeviceScanner'
        }
    },
    device_removal_kit = {
        name = 'device_removal_kit',
        label = 'Removal Kit',
        weight = 200,
        type = 'item',
        image = 'device_removal_kit.png',
        unique = false,
        stack = false,
        close = true,
        useable = true,
        description = 'Tools used to remove a detected sabotage device.',
        client = {
            export = 'M5M-Carbomb-Killswitch.useDeviceRemovalKit'
        }
    }
}
