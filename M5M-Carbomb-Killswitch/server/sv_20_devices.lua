MKDevices = MKDevices or {}

function MKDevices.CountOwnedDevices(citizenid)
    local rows = Database.GetDevicesByOwner(citizenid) or {}
    return #rows
end

function MKDevices.ValidateInstall(src, payload)
    payload = payload or {}

    local installDef = MKUtils.GetInstallDefinitionByItem(payload.itemName)
    if not installDef then
        return false, Config.Strings.invalidInstallDevice
    end

    local allowed, reason = MKCheckPermissionBlock(src, Config.Permissions.Install, Config.Strings.needInstallItem, payload.itemName)
    if not allowed then
        return false, reason
    end

    local citizenid = MKGetCitizenId(src)
    if not citizenid then
        return false, 'Unable to identify player.'
    end

    if MKDevices.CountOwnedDevices(citizenid) >= (Config.MaxLinkedVehiclesPerPlayer or 10) then
        return false, 'Maximum linked vehicles reached.'
    end

    local plate = MKUtils.NormalizePlate(payload.plate)
    if plate == '' then
        return false, 'Invalid plate.'
    end

    local vehicleClass = tonumber(payload.class) or -1
    local model = payload.model
    if MKIsVehicleBlacklisted(model, vehicleClass) then
        return false, 'This vehicle cannot be targeted.'
    end

    local existing = Database.GetDeviceByPlate(plate)
    if existing and not existing.is_removed then
        return false, 'A device is already installed on this vehicle.'
    end

    return true
end

function MKDevices.CreateForPlayer(src, payload)
    local citizenid = MKGetCitizenId(src)
    local name = MKGetCharName(src)
    local coords = payload.coords or {}
    local installDef = MKUtils.GetInstallDefinitionByItem(payload.itemName) or {}
    local typeConfig = MKUtils.GetDeviceTypeConfig(payload.deviceType or installDef.deviceType) or {}

    return Database.InsertDevice({
        owner_citizenid = citizenid,
        installer_name = name,
        plate = payload.plate,
        vehicle_model = tostring(payload.model or ''),
        device_name = payload.deviceName or installDef.label or typeConfig.label or 'Matrix Killswitch Device',
        device_type = payload.deviceType or installDef.deviceType or 'instant',
        status = 'active',
        paired_remote_id = citizenid,
        nickname = payload.nickname or payload.plate,
        installed_x = coords.x,
        installed_y = coords.y,
        installed_z = coords.z,
        installed_heading = payload.heading,
        is_hidden = true,
        is_removed = false
    })
end

function MKDevices.GetLinkedDevicesForSource(src)
    local citizenid = MKGetCitizenId(src)
    if not citizenid then return {} end
    local devices = Database.GetDevicesByOwner(citizenid) or {}
    for i = 1, #devices do
        local tracker = Database.GetTracker(devices[i].plate)
        if tracker then
            devices[i].tracker = tracker
        end
        local runtime = MKRuntime.ByPlate[devices[i].plate]
        if runtime then
            devices[i].runtime = runtime
        end

        local typeConfig = MKUtils.GetDeviceTypeConfig(devices[i].device_type) or {}
        devices[i].typeLabel = typeConfig.label or devices[i].device_name or devices[i].device_type
        devices[i].activationDescription = typeConfig.activationDescription
    end
    return devices
end
