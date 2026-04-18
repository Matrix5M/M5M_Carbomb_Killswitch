local function buildEffectState(plate, mode, opts)
    opts = opts or {}
    return {
        plate = plate,
        mode = mode,
        stage = tonumber(opts.stage) or nil,
        forceEngineOff = opts.forceEngineOff == true,
        blockRestart = opts.blockRestart == true,
        hazards = opts.hazards == true,
        torqueMultiplier = tonumber(opts.torqueMultiplier) or nil,
        smokeStage = tonumber(opts.smokeStage) or 0,
        hornWeirdness = opts.hornWeirdness == true,
        flickerLights = opts.flickerLights == true,
        engineHealthTarget = tonumber(opts.engineHealthTarget) or nil,
        petrolTankHealthTarget = tonumber(opts.petrolTankHealthTarget) or nil,
        igniteFire = opts.igniteFire == true,
        extinguishFireAt = tonumber(opts.extinguishFireAt) or nil,
        startedAt = tonumber(opts.startedAt) or os.time(),
        armedAt = tonumber(opts.armedAt) or nil,
        expiresAt = tonumber(opts.expiresAt) or nil,
        nextStageAt = tonumber(opts.nextStageAt) or nil
    }
end

local function pushStateToTarget(target, plate)
    local state = MKRuntime.ByPlate[plate]
    if state then
        TriggerClientEvent('matrix-killswitch:client:applyState', target or -1, state)
    else
        TriggerClientEvent('matrix-killswitch:client:clearState', target or -1, plate)
    end
end

local function pushAllStatesToTarget(target)
    local all = {}
    for _, state in pairs(MKRuntime.ByPlate or {}) do
        all[#all + 1] = state
    end
    TriggerClientEvent('matrix-killswitch:client:syncStates', target or -1, all)
end

local function setRuntimeState(plate, state, status)
    MKRuntime.ByPlate[plate] = state
    Database.UpdateDeviceStatus(plate, status or state.mode or 'triggered')
    pushStateToTarget(-1, plate)
end

local function clearRuntimeState(plate, status)
    MKRuntime.ByPlate[plate] = nil
    Database.UpdateDeviceStatus(plate, status or 'active')
    pushStateToTarget(-1, plate)
end

local function startStagedMalfunction(plate, device, sourceCitizenId)
    local stagedConfig = Config.Effects.staged or {}
    local durations = stagedConfig.stageDurations or { 6, 8, 8, 6 }
    local torques = stagedConfig.torqueMultipliers or { 0.9, 0.65, 0.35, 0.0 }
    local failureMode = tostring(stagedConfig.failureMode or 'shutdown'):lower()
    local immediateFinalStage = stagedConfig.immediateFinalStageOnActivation == true
    local catastrophicConfig = stagedConfig.catastrophicDamage or {}
    local shutdownConfig = stagedConfig.shutdownDamage or {}

    local function getStageDamage(stage, isFinal)
        if failureMode == 'catastrophic' then
            if isFinal then
                local extinguishAfter = math.max(0, math.floor(tonumber(catastrophicConfig.autoExtinguishAfterSeconds) or 0))
                return {
                    engineHealthTarget = tonumber(catastrophicConfig.finalEngineHealth) or -150.0,
                    petrolTankHealthTarget = tonumber(catastrophicConfig.finalPetrolTankHealth) or 300.0,
                    igniteFire = catastrophicConfig.igniteOnFinalStage == true,
                    extinguishFireAt = extinguishAfter > 0 and (os.time() + extinguishAfter) or nil
                }
            elseif stage >= 3 then
                return {
                    engineHealthTarget = tonumber(catastrophicConfig.severeEngineHealth) or 120.0
                }
            elseif stage >= 2 then
                return {
                    engineHealthTarget = tonumber(catastrophicConfig.smokeEngineHealth) or 325.0
                }
            end
        else
            if stage >= 3 then
                return {
                    engineHealthTarget = tonumber(shutdownConfig.severeEngineHealth) or 180.0
                }
            elseif stage >= 2 then
                return {
                    engineHealthTarget = tonumber(shutdownConfig.smokeEngineHealth) or 350.0
                }
            end
        end

        return {}
    end

    local function applyStage(stage)
        local isFinal = stage >= #durations
        local damage = getStageDamage(stage, isFinal)
        local state = buildEffectState(plate, 'staged_malfunction', {
            stage = stage,
            startedAt = os.time(),
            nextStageAt = isFinal and nil or (os.time() + (tonumber(durations[stage]) or 5)),
            torqueMultiplier = torques[stage] or torques[#torques] or 0.0,
            hazards = stage >= (stagedConfig.hazardsFromStage or 2),
            smokeStage = stage >= (stagedConfig.smokeFromStage or 2) and stage or 0,
            hornWeirdness = stage >= (stagedConfig.hornWeirdnessFromStage or 3),
            forceEngineOff = isFinal,
            blockRestart = isFinal,
            engineHealthTarget = damage.engineHealthTarget,
            petrolTankHealthTarget = damage.petrolTankHealthTarget,
            igniteFire = damage.igniteFire,
            extinguishFireAt = damage.extinguishFireAt
        })

        setRuntimeState(plate, state, isFinal and 'disabled' or 'triggered')

        if isFinal then
            Database.LogAction(device.id, sourceCitizenId, 'trigger', 'staged_malfunction_complete', 'success', plate, {
                stage = stage,
                failure_mode = failureMode,
                ignite_fire = state.igniteFire == true,
                final_engine_health = state.engineHealthTarget,
                final_petrol_tank_health = state.petrolTankHealthTarget
            })
            return
        end

        SetTimeout((tonumber(durations[stage]) or 5) * 1000, function()
            local current = MKRuntime.ByPlate[plate]
            if not current or current.mode ~= 'staged_malfunction' or tonumber(current.stage) ~= stage then return end
            applyStage(stage + 1)
        end)
    end

    local initialStage = immediateFinalStage and math.max(#durations, 1) or 1
    applyStage(initialStage)
end

local function applyInstantDisable(plate)
    setRuntimeState(plate, buildEffectState(plate, 'instant_disable', {
        forceEngineOff = true,
        blockRestart = true,
        torqueMultiplier = 0.0,
        hazards = true
    }), 'disabled')
end

local function applyEmp(plate)
    local duration = tonumber(Config.Effects.emp.durationSeconds) or 15
    setRuntimeState(plate, buildEffectState(plate, 'emp', {
        forceEngineOff = true,
        blockRestart = Config.Effects.emp.lockIgnition == true,
        torqueMultiplier = 0.0,
        hazards = Config.Effects.emp.flickerLights == true,
        flickerLights = Config.Effects.emp.flickerLights == true,
        hornWeirdness = Config.Effects.emp.messWithHorn == true,
        expiresAt = os.time() + duration
    }), 'emp_active')

    SetTimeout(duration * 1000, function()
        local current = MKRuntime.ByPlate[plate]
        if current and current.mode == 'emp' and (Config.Effects.emp.autoRecover ~= false) then
            clearRuntimeState(plate, 'active')
        end
    end)
end

local function armDelayedShutdown(plate, delaySeconds)
    local delay = math.floor(tonumber(delaySeconds) or 0)
    setRuntimeState(plate, buildEffectState(plate, 'delayed_shutdown', {
        torqueMultiplier = 1.0,
        armedAt = os.time(),
        expiresAt = os.time() + delay
    }), 'triggered')

    SetTimeout(delay * 1000, function()
        local current = MKRuntime.ByPlate[plate]
        if not current or current.mode ~= 'delayed_shutdown' then return end
        applyInstantDisable(plate)
    end)
end


local function resolveDeviceActivation(device)
    local typeConfig = MKUtils.GetDeviceTypeConfig(device and device.device_type) or {}
    local mode = tostring(typeConfig.activationMode or 'instant_disable')

    if mode == 'delayed_shutdown' then
        local delay = math.floor(tonumber(typeConfig.activationDelaySeconds) or 0)
        if delay <= 0 then
            local presets = Config.Devices.allowedDelayPresets or {}
            delay = math.floor(tonumber(presets[1]) or 30)
        end
        return mode, delay
    end

    return mode, nil
end

local function validateDeviceAction(src, payloadOrPlate)
    local payload = type(payloadOrPlate) == 'table' and payloadOrPlate or { plate = payloadOrPlate }
    local plate = MKUtils.NormalizePlate(payload.plate)

    local allowed, reason = MKCheckPermissionBlock(src, Config.Permissions.Trigger, Config.Strings.needRemote)
    if not allowed then
        return nil, reason
    end

    local device = nil
    if payload.deviceId then
        device = Database.GetDeviceById(payload.deviceId)
    end
    if not device and plate ~= '' then
        device = Database.GetDeviceByPlate(plate)
    end
    if not device or device.is_removed then
        return nil, Config.Strings.noLinkedDevice
    end

    if not MKCanManageDevice(src, device) then
        return nil, 'You do not control this device.'
    end

    return device, nil
end

RegisterNetEvent('matrix-killswitch:server:commitInstall', function(payload)
    local src = source
    local ok, reason = MKDevices.ValidateInstall(src, payload)
    if not ok then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, reason or Config.Strings.installFailed, 'error')
    end

    local installDef = MKUtils.GetInstallDefinitionByItem(payload.itemName)
    if not installDef then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, Config.Strings.invalidInstallDevice, 'error')
    end

    if Config.Devices.consumeInstallItem and not MKRemoveItem(src, payload.itemName, 1) then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, Config.Strings.needInstallItem, 'error')
    end

    local device = MKDevices.CreateForPlayer(src, payload)
    if not device then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, Config.Strings.installFailed, 'error')
    end

    if MKGetItemCount(src, Config.Permissions.Trigger.requiredItem) <= 0 then
        MKAddItem(src, Config.Permissions.Trigger.requiredItem, 1, { linked_plate = device.plate })
    end

    Database.LogAction(device.id, MKGetCitizenId(src), 'install', 'install', 'success', device.plate, payload)
    TriggerClientEvent('matrix-killswitch:client:installSuccess', src, device)
end)

RegisterNetEvent('matrix-killswitch:server:triggerAction', function(payload)
    local src = source
    payload = payload or {}
    local plate = MKUtils.NormalizePlate(payload.plate)
    local mode = tostring(payload.mode or '')
    local device, err = validateDeviceAction(src, payload)
    if device and (plate == '' or plate ~= device.plate) then plate = device.plate end
    if not device then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, err or 'Action failed.', 'error')
    end

    if mode == 'tracker_ping' then
        if MKIsCooldownActive('tracker', plate) then
            return TriggerClientEvent('matrix-killswitch:client:notify', src, 'Tracker cooldown active.', 'error')
        end
        MKSetCooldown('tracker', plate, Config.Devices.trackerCooldownSeconds)
        local tracker = Database.GetTracker(plate)
        if tracker then
            TriggerClientEvent('matrix-killswitch:client:showTrackerPing', src, {
                plate = plate,
                coords = { x = tracker.last_x, y = tracker.last_y, z = tracker.last_z },
                street = tracker.last_street,
                zone = tracker.last_zone,
                lastSeenAt = tracker.last_seen_at
            })
        else
            TriggerClientEvent('matrix-killswitch:client:notify', src, 'No tracker data available yet.', 'error')
        end
        Database.LogAction(device.id, MKGetCitizenId(src), 'trigger', mode, 'success', plate)
        return
    end

    if mode == 'clear_state' then
        clearRuntimeState(plate, 'active')
        Database.LogAction(device.id, MKGetCitizenId(src), 'trigger', mode, 'success', plate)
        return TriggerClientEvent('matrix-killswitch:client:notify', src, Config.Strings.stateCleared, 'success')
    end

    if mode ~= 'activate_device' then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, 'Unknown action mode.', 'error')
    end

    if MKIsCooldownActive('action', plate) then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, 'Action cooldown active.', 'error')
    end
    MKSetCooldown('action', plate, Config.Devices.triggerCooldownSeconds)

    local activationMode, activationDelay = resolveDeviceActivation(device)

    if activationMode == 'instant_disable' then
        applyInstantDisable(plate)
    elseif activationMode == 'delayed_shutdown' then
        armDelayedShutdown(plate, activationDelay)
    elseif activationMode == 'staged_malfunction' then
        startStagedMalfunction(plate, device, MKGetCitizenId(src))
    elseif activationMode == 'emp' then
        if MKIsCooldownActive('emp', plate) then
            return TriggerClientEvent('matrix-killswitch:client:notify', src, 'EMP cooldown active.', 'error')
        end
        MKSetCooldown('emp', plate, Config.Devices.empCooldownSeconds)
        applyEmp(plate)
    else
        return TriggerClientEvent('matrix-killswitch:client:notify', src, 'Unknown device activation type.', 'error')
    end

    Database.LogAction(device.id, MKGetCitizenId(src), 'trigger', activationMode, 'success', plate, {
        requested_mode = mode,
        resolved_mode = activationMode,
        resolved_delay = activationDelay,
        device_type = device.device_type
    })
    TriggerClientEvent('matrix-killswitch:client:notify', src, 'Killswitch activated.', 'success')
end)

RegisterNetEvent('matrix-killswitch:server:updateNickname', function(payload)
    local src = source
    payload = payload or {}
    local plate = MKUtils.NormalizePlate(payload.plate)
    local nickname = MKUtils.Trim(payload.nickname)
    nickname = nickname:sub(1, Config.Devices.nicknameMaxLength or 24)

    local device, err = validateDeviceAction(src, payload)
    if not device then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, err or 'Unable to rename device.', 'error')
    end

    Database.UpdateNickname(plate, nickname)
    TriggerClientEvent('matrix-killswitch:client:notify', src, 'Vehicle nickname updated.', 'success')
end)

RegisterNetEvent('matrix-killswitch:server:unlinkDevice', function(payload)
    local src = source
    payload = payload or {}

    local device, err = validateDeviceAction(src, payload)
    if not device then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, err or 'Unable to unlink vehicle.', 'error')
    end

    local plate = device.plate
    Database.UpdateRemotePairing(plate, nil, 'inactive')
    Database.DeleteTracker(plate)
    clearRuntimeState(plate, 'inactive')
    MKClearDetection(src, plate)
    Database.LogAction(device.id, MKGetCitizenId(src), 'unlink', 'remote_unlink', 'success', plate)
    TriggerClientEvent('matrix-killswitch:client:notify', src, Config.Strings.unlinkSuccess or 'Vehicle removed from your remote tracker list.', 'success')
end)

RegisterNetEvent('matrix-killswitch:server:requestRemoval', function(payload)
    local src = source
    payload = payload or {}
    local plate = MKUtils.NormalizePlate(payload.plate)

    local allowed, reason = MKCheckPermissionBlock(src, Config.Permissions.Remove, Config.Strings.needRemovalKit)
    if not allowed then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, reason, 'error')
    end

    local device = Database.GetDeviceByPlate(plate)
    if not device or device.is_removed then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, Config.Strings.noDeviceFound, 'error')
    end

    if not Config.Devices.allowBlindRemovalAttempts and not MKWasDetectedBySource(src, plate) then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, 'You need to detect a device first.', 'error')
    end

    if Config.Devices.consumeRemovalKitOnSuccess and not MKRemoveItem(src, Config.Permissions.Remove.requiredItem, 1) then
        return TriggerClientEvent('matrix-killswitch:client:notify', src, 'Missing required removal kit.', 'error')
    end

    Database.MarkRemoved(plate, MKGetCitizenId(src) or ('src:%s'):format(src))
    Database.DeleteTracker(plate)
    clearRuntimeState(plate, 'removed')
    MKClearDetection(src, plate)
    Database.LogAction(device.id, MKGetCitizenId(src), 'remove', 'remove', 'success', plate)

    if Config.Devices.notifyInstallerOnRemoval and device.owner_citizenid and device.owner_citizenid ~= MKGetCitizenId(src) then
        for _, playerId in ipairs(MKGetPlayers()) do
            playerId = tonumber(playerId)
            if playerId and MKGetCitizenId(playerId) == device.owner_citizenid then
                TriggerClientEvent('matrix-killswitch:client:notify', playerId, ('A linked device on %s was removed.'):format(plate), 'inform')
            end
        end
    end

    TriggerClientEvent('matrix-killswitch:client:removeSuccess', src)
end)

RegisterNetEvent('matrix-killswitch:server:requestStateSync', function()
    local src = source
    pushAllStatesToTarget(src)
end)
