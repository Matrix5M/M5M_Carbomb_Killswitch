MKRemove = MKRemove or {}

function MKRemove.Start(vehicle)
    if not MKHasItem(Config.Permissions.Remove.requiredItem or 'device_removal_kit') then
        return MKNotify(Config.Strings.needRemovalKit, 'error')
    end

    vehicle = vehicle or MKInstall.GetNearestVehicle(4.0)
    if not vehicle then
        return MKNotify(Config.Strings.noVehicleNearby, 'error')
    end

    local plate = MKUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
    MKNotify(Config.Strings.removeStarted, 'inform')
    MKAnimations.Play(MKAnimations.Remove, 8000)
    local finished = MKProgress({
        duration = 8000,
        label = Config.Strings.removeStarted,
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })
    MKAnimations.Stop()
    if not finished then return end

    if not MKSkillCheck({'easy', 'medium'}) then
        return MKNotify('Removal attempt failed.', 'error')
    end

    TriggerServerEvent('matrix-killswitch:server:requestRemoval', { plate = plate })
end
