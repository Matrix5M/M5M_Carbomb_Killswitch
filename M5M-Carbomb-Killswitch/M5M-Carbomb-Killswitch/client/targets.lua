CreateThread(function()
    if not Config.Target then return end
    if not MKTarget or not MKTarget.addGlobalVehicle then return end

    MKTarget:addGlobalVehicle({
        {
            name = 'mk_scan_vehicle',
            icon = 'fas fa-wave-square',
            label = 'Scan for Device',
            distance = Config.DefaultTargetDistance or 2.0,
            canInteract = function(entity, distance, coords, name)
                return MKHasItem(Config.Permissions.Detect.requiredItem or 'device_scanner')
            end,
            onSelect = function(data)
                if MKDetect and MKDetect.Start then
                    MKDetect.Start(data and data.entity)
                end
            end
        },
        {
            name = 'mk_remove_device',
            icon = 'fas fa-screwdriver-wrench',
            label = 'Remove Device',
            distance = Config.DefaultTargetDistance or 2.0,
            canInteract = function(entity, distance, coords, name)
                return MKHasItem(Config.Permissions.Remove.requiredItem or 'device_removal_kit')
            end,
            onSelect = function(data)
                if MKRemove and MKRemove.Start then
                    MKRemove.Start(data and data.entity)
                end
            end
        }
    })
end)
