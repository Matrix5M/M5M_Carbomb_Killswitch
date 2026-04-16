MKInstall = MKInstall or {}

function MKInstall.GetNearestVehicle(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, radius or 4.0, false)
    if not vehicle or vehicle == 0 then return nil end
    return vehicle
end

function MKInstall.Start(vehicle, itemName)
    itemName = tostring(itemName or '')
    local installDef = MKUtils.GetInstallDefinitionByItem(itemName)
    if not installDef then
        return MKNotify(Config.Strings.invalidInstallDevice, 'error')
    end

    if not MKHasItem(itemName) then
        return MKNotify(Config.Strings.needInstallItem, 'error')
    end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return MKNotify('Exit the vehicle before installing a device.', 'error')
    end

    vehicle = vehicle or MKInstall.GetNearestVehicle(4.0)
    if not vehicle then
        return MKNotify(Config.Strings.noVehicleNearby, 'error')
    end

    local plate = MKUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
    local coords = GetEntityCoords(vehicle)
    local typeConfig = MKUtils.GetDeviceTypeConfig(installDef.deviceType) or {}

    local ok, reason = lib.callback.await('matrix-killswitch:validateInstall', false, {
        plate = plate,
        model = GetEntityModel(vehicle),
        class = GetVehicleClass(vehicle),
        coords = MKUtils.VectorToTable(coords),
        itemName = itemName,
        deviceType = installDef.deviceType,
        deviceName = installDef.label or typeConfig.label or 'Killswitch Device'
    })

    if not ok then
        return MKNotify(reason or Config.Strings.installFailed, 'error')
    end

    MKNotify(Config.Strings.installStarted, 'inform')
    MKAnimations.Play(MKAnimations.Install, Config.Devices.installDurationMs)
    local finished = MKProgress({
        duration = Config.Devices.installDurationMs,
        label = Config.Strings.installStarted,
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })
    MKAnimations.Stop()
    if not finished then return end

    if Config.Devices.installSkillCheck and not MKSkillCheck(Config.Devices.installSkillCheck) then
        return MKNotify(Config.Strings.installFailed, 'error')
    end

    TriggerServerEvent('matrix-killswitch:server:commitInstall', {
        plate = plate,
        model = GetEntityModel(vehicle),
        class = GetVehicleClass(vehicle),
        coords = MKUtils.VectorToTable(coords),
        heading = GetEntityHeading(vehicle),
        itemName = itemName,
        deviceType = installDef.deviceType,
        deviceName = installDef.label or typeConfig.label or 'Killswitch Device'
    })
end
