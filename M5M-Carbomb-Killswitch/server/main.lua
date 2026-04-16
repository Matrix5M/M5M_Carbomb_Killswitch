local function registerUsableItems()
    if not MKCreateUsableItem then return end
    if MK.ResolveInventory() == 'ox_inventory' then return end

    local installItems = Config.Devices.installItems or {}
    for itemName, _ in pairs(installItems) do
        MKCreateUsableItem(itemName, function(source, item)
            TriggerClientEvent('matrix-killswitch:client:useItem', source, itemName)
        end)
    end

    MKCreateUsableItem('killswitch_remote', function(source, item)
        TriggerClientEvent('matrix-killswitch:client:useItem', source, 'killswitch_remote')
    end)

    MKCreateUsableItem('device_scanner', function(source, item)
        TriggerClientEvent('matrix-killswitch:client:useItem', source, 'device_scanner')
    end)

    MKCreateUsableItem('device_removal_kit', function(source, item)
        TriggerClientEvent('matrix-killswitch:client:useItem', source, 'device_removal_kit')
    end)
end

CreateThread(function()
    Database.Init()
    registerUsableItems()
    MKLog('Initialized database and Matrix Killswitch modules.')
end)
