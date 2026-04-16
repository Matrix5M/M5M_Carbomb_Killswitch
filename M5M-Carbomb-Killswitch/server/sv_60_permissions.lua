RegisterCommand(Config.AdminCommand, function(source, args)
    if source == 0 then
        print('[Matrix Killswitch] Console command usage: killswitchadmin list | clear <plate> | remove <plate>')
        return
    end

    if not MKIsAdmin(source) then
        return TriggerClientEvent('matrix-killswitch:client:notify', source, Config.Strings.actionDenied, 'error')
    end

    local sub = tostring(args[1] or ''):lower()
    local plate = MKUtils.NormalizePlate(args[2])

    if sub == 'list' then
        local devices = Database.GetAllDevices() or {}
        return TriggerClientEvent('matrix-killswitch:client:notify', source, ('Tracked devices: %s'):format(#devices), 'inform')
    end

    if plate == '' then
        return TriggerClientEvent('matrix-killswitch:client:notify', source, 'Usage: /killswitchadmin clear <plate> or /killswitchadmin remove <plate>', 'inform')
    end

    local device = Database.GetDeviceByPlate(plate)
    if not device then
        return TriggerClientEvent('matrix-killswitch:client:notify', source, 'No device found for that plate.', 'error')
    end

    if sub == 'clear' then
        MKRuntime.ByPlate[plate] = nil
        Database.UpdateDeviceStatus(plate, 'active')
        TriggerClientEvent('matrix-killswitch:client:clearState', -1, plate)
        return TriggerClientEvent('matrix-killswitch:client:notify', source, ('Cleared active state for %s'):format(plate), 'success')
    elseif sub == 'remove' then
        Database.MarkRemoved(plate, ('admin:%s'):format(MKGetCitizenId(source) or source))
        MKRuntime.ByPlate[plate] = nil
        TriggerClientEvent('matrix-killswitch:client:clearState', -1, plate)
        return TriggerClientEvent('matrix-killswitch:client:notify', source, ('Removed device from %s'):format(plate), 'success')
    end

    TriggerClientEvent('matrix-killswitch:client:notify', source, 'Unknown subcommand.', 'error')
end, false)
