lib.callback.register('matrix-killswitch:getLinkedDevices', function(source)
    return MKDevices.GetLinkedDevicesForSource(source)
end)

lib.callback.register('matrix-killswitch:validateInstall', function(source, payload)
    return MKDevices.ValidateInstall(source, payload)
end)

lib.callback.register('matrix-killswitch:getTrackerData', function(source, plate)
    local device = Database.GetDeviceByPlate(plate)
    if not device or not MKCanManageDevice(source, device) then return nil end
    return Database.GetTracker(plate)
end)

lib.callback.register('matrix-killswitch:getVehicleDeviceState', function(source, plate)
    local normalized = MKUtils.NormalizePlate(plate)
    local device = Database.GetDeviceByPlate(normalized)
    return device and not device.is_removed or false
end)

lib.callback.register('matrix-killswitch:detectVehicleDevice', function(source, payload)
    payload = payload or {}
    local plate = MKUtils.NormalizePlate(payload.plate)

    local ok, reason = MKCheckPermissionBlock(source, Config.Permissions.Detect, Config.Strings.needScanner)
    if not ok then
        return { ok = false, detected = false, message = reason }
    end

    local device = Database.GetDeviceByPlate(plate)
    if not device or device.is_removed then
        return { ok = true, detected = false, message = Config.Strings.noDeviceFound }
    end

    MKRememberDetection(source, plate)
    return {
        ok = true,
        detected = true,
        plate = plate,
        nickname = device.nickname,
        ownerCitizenId = MKCanManageDevice(source, device) and device.owner_citizenid or nil,
        message = Config.Strings.deviceDetected
    }
end)

lib.callback.register('matrix-killswitch:getAllActiveStates', function(source)
    local out = {}
    for plate, state in pairs(MKRuntime.ByPlate or {}) do
        out[#out + 1] = state
    end
    return out
end)
