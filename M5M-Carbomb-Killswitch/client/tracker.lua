RegisterNetEvent('matrix-killswitch:client:showTrackerPing', function(data)
    data = data or {}
    local coords = data.coords or {}
    local x, y, z = tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, 225)
    SetBlipScale(blip, 0.85)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Tracker Ping')
    EndTextCommandSetBlipName(blip)
    MKState.TrackerBlips[#MKState.TrackerBlips + 1] = blip

    local parts = {}
    if data.street and data.street ~= '' then parts[#parts + 1] = data.street end
    if data.zone and data.zone ~= '' then parts[#parts + 1] = data.zone end
    MKNotify(#parts > 0 and table.concat(parts, ' | ') or 'Tracker ping received.', 'inform')

    CreateThread(function()
        Wait((Config.Tracker.blipDurationSeconds or 15) * 1000)
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

CreateThread(function()
    while true do
        Wait(3000)
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then goto continue end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 then goto continue end

        local coords = GetEntityCoords(vehicle)
        local plate = MKUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
        if plate == '' then goto continue end

        local streetHash, crossing = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = streetHash ~= 0 and GetStreetNameFromHashKey(streetHash) or ''
        local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

        TriggerServerEvent('matrix-killswitch:server:updateTracker', {
            plate = plate,
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = GetEntityHeading(vehicle),
            street = street,
            zone = zone
        })

        ::continue::
    end
end)
