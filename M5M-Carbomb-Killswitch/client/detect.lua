MKDetect = MKDetect or {}

function MKDetect.Start(vehicle)
    if not MKHasItem(Config.Permissions.Detect.requiredItem or 'device_scanner') then
        return MKNotify(Config.Strings.needScanner, 'error')
    end

    vehicle = vehicle or MKInstall.GetNearestVehicle(4.0)
    if not vehicle then
        return MKNotify(Config.Strings.noVehicleNearby, 'error')
    end

    local plate = MKUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
    MKNotify(Config.Strings.scanStarted, 'inform')
    MKAnimations.Play(MKAnimations.Scan, Config.Police.fasterAuthorizedScanMs or 6000)
    local finished = MKProgress({
        duration = Config.Police.fasterAuthorizedScanMs or 6000,
        label = Config.Strings.scanStarted,
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })
    MKAnimations.Stop()
    if not finished then return end

    local result = lib.callback.await('matrix-killswitch:detectVehicleDevice', false, { plate = plate })
    if result and result.detected then
        MKNotify(result.message or Config.Strings.deviceDetected, 'success')
    else
        MKNotify((result and result.message) or Config.Strings.noDeviceFound, (result and result.ok == false) and 'error' or 'inform')
    end
end
