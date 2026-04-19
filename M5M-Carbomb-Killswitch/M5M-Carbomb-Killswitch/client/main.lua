RegisterNetEvent('matrix-killswitch:client:notify', function(message, nType)
    MKNotify(message, nType)
end)

RegisterNetEvent('matrix-killswitch:client:installSuccess', function(device)
    local label = device and (device.device_name or device.nickname or device.plate) or nil
    MKNotify(label and (label .. ' installed.') or Config.Strings.installSuccess, 'success')
end)

RegisterNetEvent('matrix-killswitch:client:removeSuccess', function()
    MKNotify(Config.Strings.removeSuccess, 'success')
end)

RegisterNetEvent('matrix-killswitch:client:useItem', function(itemName)
    itemName = tostring(itemName or '')
    if itemName == 'killswitch_instant' or itemName == 'killswitch_delayed' or itemName == 'car_bomb' or itemName == 'killswitch_emp' or itemName == 'killswitch_device' then
        return MKInstall.Start(nil, itemName)
    elseif itemName == 'killswitch_remote' then
        return MKRemote.OpenMenu()
    elseif itemName == 'device_scanner' then
        return MKDetect.Start()
    elseif itemName == 'device_removal_kit' then
        return MKRemove.Start()
    end
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('matrix-killswitch:server:requestStateSync')
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:displayMetadata({ linked_plate = 'Linked Plate' })
    end
end)
