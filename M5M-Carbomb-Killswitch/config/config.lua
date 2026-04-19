Config = {}

Config.Framework = 'auto'      -- auto, qbcore, qbox
Config.Inventory = 'auto'      -- auto, ox_inventory, qb-inventory
Config.Target = 'auto'         -- auto, ox_target, qb-target

Config.Debug = false
Config.AdminCommand = 'killswitchadmin'
Config.AdminAcePermission = 'matrixkillswitch.admin'
Config.UseAceForAdmin = true
Config.AdminCitizenIds = {}
Config.AdminGroups = { 'god', 'admin', 'superadmin' }

Config.RemoteMenuTitle = 'Matrix Killswitch'
Config.MaxLinkedVehiclesPerPlayer = 10
Config.DefaultTargetDistance = 2.0
Config.MaxTargetUseDistance = 5.0
Config.UsePlateAsPrimaryKey = true

local function merge(section)
    for k, v in pairs(section or {}) do
        Config[k] = v
    end
end

merge(lib.require('config.shared'))
merge(lib.require('config.permissions'))
merge(lib.require('config.devices'))
merge(lib.require('config.effects'))
merge(lib.require('config.tracker'))
merge(lib.require('config.blacklist'))
merge(lib.require('config.police'))
merge(lib.require('config.strings'))
