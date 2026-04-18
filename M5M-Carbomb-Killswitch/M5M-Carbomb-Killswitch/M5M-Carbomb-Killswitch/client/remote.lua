MKRemote = MKRemote or {}

local function trackerDescription(device)
    local tracker = device.tracker or {}
    local parts = {}
    if tracker.last_street and tracker.last_street ~= '' then parts[#parts + 1] = tracker.last_street end
    if tracker.last_zone and tracker.last_zone ~= '' then parts[#parts + 1] = tracker.last_zone end
    return #parts > 0 and table.concat(parts, ' | ') or 'No last known location'
end

local function openRenameDialog(device)
    local result = MKInputDialog('Rename Linked Vehicle', {
        { type = 'input', label = 'Nickname', default = device.nickname or device.plate, required = true, max = Config.Devices.nicknameMaxLength or 24 }
    })
    if not result or not result[1] then return end
    TriggerServerEvent('matrix-killswitch:server:updateNickname', { deviceId = device.id, plate = device.plate, nickname = result[1] })
end

local function confirmUnlinkDevice(device)
    local confirmed = lib.alertDialog({
        header = Config.Strings.unlinkConfirmTitle or 'Remove Linked Vehicle',
        content = Config.Strings.unlinkConfirmMessage or 'This will remove the vehicle from your remote tracker list.',
        centered = true,
        cancel = true
    })

    if confirmed ~= 'confirm' then return end
    TriggerServerEvent('matrix-killswitch:server:unlinkDevice', { deviceId = device.id, plate = device.plate })
end

local function buildDeviceOptions(device)
    local title = (device.nickname and device.nickname ~= '' and device.nickname) or device.plate
    local status = (device.runtime and device.runtime.mode) or device.status or 'active'
    local typeLabel = device.typeLabel or device.device_name or 'Killswitch'
    return {
        title = title,
        description = ('Type: %s\nPlate: %s | Status: %s\n%s'):format(typeLabel, device.plate or 'Unknown', status, trackerDescription(device)),
        arrow = true,
        onSelect = function()
            lib.registerContext({
                id = 'mk_device_actions_' .. tostring(device.id),
                title = title,
                menu = 'mk_remote_main',
                options = {
                    { title = 'Tracker Ping', description = 'Show the vehicle\'s last known location.', onSelect = function() TriggerServerEvent('matrix-killswitch:server:triggerAction', { deviceId = device.id, plate = device.plate, mode = 'tracker_ping' }) end },
                    { title = Config.Strings.activateDevice, description = device.activationDescription or 'Trigger the installed killswitch behavior.', onSelect = function() TriggerServerEvent('matrix-killswitch:server:triggerAction', { deviceId = device.id, plate = device.plate, mode = 'activate_device' }) end },
                    { title = Config.Strings.deactivateDevice, description = 'Re-enable the vehicle if it is currently affected.', onSelect = function() TriggerServerEvent('matrix-killswitch:server:triggerAction', { deviceId = device.id, plate = device.plate, mode = 'clear_state' }) end },
                    { title = 'Rename Vehicle', description = 'Change how this linked vehicle is displayed.', onSelect = function() openRenameDialog(device) end },
                    { title = Config.Strings.unlinkDevice or 'Remove From Tracker List', description = Config.Strings.unlinkDeviceDescription or 'Unlink this vehicle from your remote tracker list.', onSelect = function() confirmUnlinkDevice(device) end },
                }
            })
            lib.showContext('mk_device_actions_' .. tostring(device.id))
        end
    }
end

function MKRemote.OpenMenu()
    local devices = lib.callback.await('matrix-killswitch:getLinkedDevices', false) or {}
    if #devices == 0 then
        return MKNotify(Config.Strings.noLinkedVehicles, 'error')
    end

    local options = {}
    for i = 1, #devices do
        options[#options + 1] = buildDeviceOptions(devices[i])
    end

    lib.registerContext({
        id = 'mk_remote_main',
        title = Config.RemoteMenuTitle,
        options = options
    })

    lib.showContext('mk_remote_main')
end
