return {
    Devices = {
        installDurationMs = 10000,
        installSkillCheck = { 'easy', 'easy', 'medium' },
        maxDevicesPerVehicle = 1,
        nicknameMaxLength = 24,
        consumeInstallItem = true,
        consumeRemovalKitOnSuccess = false,
        requireVehicleEmpty = false,
        requireKeysToInstall = false,
        allowHostileInstalls = true,
        allowBlindRemovalAttempts = false,
        notifyInstallerOnRemoval = true,
        triggerCooldownSeconds = 15,
        trackerCooldownSeconds = 30,
        empCooldownSeconds = 45,
        allowedDelayPresets = { 30, 60, 120 },

        deviceTypes = {
            instant = {
                label = 'Instant Killswitch',
                activationMode = 'instant_disable',
                activationDescription = 'Immediately cuts the engine and blocks restart.'
            },
            delayed = {
                label = 'Delayed Killswitch',
                activationMode = 'delayed_shutdown',
                activationDelaySeconds = 60,
                activationDescription = 'Arms a delayed shutdown using the preset timer.'
            },
            staged = {
                label = 'Car Bomb',
                activationMode = 'staged_malfunction',
                activationDescription = 'Triggers the staged sabotage profile, currently configured to jump straight into catastrophic fire damage on activation.'
            },
            emp = {
                label = 'EMP Killswitch',
                activationMode = 'emp',
                activationDescription = 'Temporarily disrupts the vehicle electronics.'
            }
        },

        installItems = {
            killswitch_instant = {
                deviceType = 'instant',
                label = 'Instant Killswitch Device',
                description = 'Installs a hidden device that instantly disables the engine when activated.'
            },
            killswitch_delayed = {
                deviceType = 'delayed',
                label = 'Delayed Killswitch Device',
                description = 'Installs a hidden device that shuts the vehicle down after a short delay.'
            },
            car_bomb = {
                deviceType = 'staged',
                label = 'Car Bomb',
                description = 'Installs a hidden device that triggers catastrophic fire damage on activation.'
            },
            killswitch_emp = {
                deviceType = 'emp',
                label = 'EMP Killswitch Device',
                description = 'Installs a hidden device that triggers a temporary EMP-style disruption.'
            },

            -- Legacy fallback so older test items do not hard-fail if they still exist in inventory.
            killswitch_device = {
                deviceType = 'instant',
                label = 'Instant Killswitch Device',
                description = 'Legacy generic install item. Defaults to the instant killswitch behavior.'
            }
        }
    }
}
