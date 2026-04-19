RegisterNetEvent('matrix-killswitch:server:updateTracker', function(data)
    data = data or {}
    local plate = MKUtils.NormalizePlate(data.plate)
    if plate == '' then return end

    local device = Database.GetDeviceByPlate(plate)
    if not device or device.is_removed then return end
    if not device.paired_remote_id or tostring(device.paired_remote_id) == '' then return end

    Database.UpsertTracker({
        plate = plate,
        x = data.x,
        y = data.y,
        z = data.z,
        heading = data.heading,
        street = data.street,
        zone = data.zone
    })
end)
