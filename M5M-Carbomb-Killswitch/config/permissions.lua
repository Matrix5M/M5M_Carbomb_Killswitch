return {
    Permissions = {
        Install = {
            allowEveryone = true,
            jobs = {},
            gangs = {},
            citizenids = {},
            requiredItem = 'killswitch_device'
        },
        Trigger = {
            allowEveryone = true,
            jobs = {},
            gangs = {},
            citizenids = {},
            requiredItem = 'killswitch_remote'
        },
        Detect = {
            allowEveryone = true,
            jobs = {},
            gangs = {},
            citizenids = {},
            requiredItem = 'device_scanner'
        },
        Remove = {
            allowEveryone = true,
            jobs = {},
            gangs = {},
            citizenids = {},
            requiredItem = 'device_removal_kit'
        },
        Admin = {
            citizenids = {},
            groups = { 'god', 'admin', 'superadmin' }
        }
    }
}
