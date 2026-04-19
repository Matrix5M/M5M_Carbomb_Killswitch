local function getVehicleByPlate(plate)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            if MKUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle)) == plate then
                return vehicle
            end
        end
    end
    return nil
end

local function stopVehicleFire(vehicle, plate)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        StopEntityFire(vehicle)
    end
    if plate then
        MKState.BurningVehicles[plate] = nil
        MKState.FireExtinguished[plate] = nil
        MKState.FireStopAt[plate] = nil
        MKState.LastFireDamageAt[plate] = nil
    end
end

local function restoreVehicleState(vehicle, plate)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    stopVehicleFire(vehicle, plate)

    SetVehicleUndriveable(vehicle, false)
    SetVehicleIndicatorLights(vehicle, 0, false)
    SetVehicleIndicatorLights(vehicle, 1, false)
    SetVehicleLights(vehicle, 0)
    SetVehicleCheatPowerIncrease(vehicle, 1.0)

    if GetVehicleEngineHealth(vehicle) > 0.0 then
        SetVehicleEngineOn(vehicle, true, true, false)
    end
end

local function maybeSputter(vehicle, state, plate)
    if not state.stage or state.stage <= 0 or state.forceEngineOff then return end
    local now = GetGameTimer()
    local last = MKState.LastSputterAt[plate] or 0
    local interval = 4000
    if state.stage == 2 then interval = 2500 end
    if state.stage >= 3 then interval = 1300 end
    if (now - last) < interval then return end

    MKState.LastSputterAt[plate] = now
    SetVehicleEngineOn(vehicle, false, true, true)
    CreateThread(function()
        Wait(math.min(700, math.max(250, 180 * (state.stage or 1))))
        if DoesEntityExist(vehicle) and MKState.ActiveEffects[plate] and not (MKState.ActiveEffects[plate].forceEngineOff) then
            SetVehicleEngineOn(vehicle, true, true, false)
        end
    end)
end

local function maybeHorn(vehicle, state, plate)
    if not state.hornWeirdness then return end
    local now = GetGameTimer()
    if (now - (MKState.LastHornAt[plate] or 0)) < 3500 then return end
    MKState.LastHornAt[plate] = now
    StartVehicleHorn(vehicle, 150, GetHashKey('HELDDOWN'), false)
end

local function maybeFlickerLights(vehicle, state, plate)
    if not state.flickerLights then return end
    local now = GetGameTimer()
    if (now - (MKState.LastLightFlickerAt[plate] or 0)) < 300 then return end
    MKState.LastLightFlickerAt[plate] = now
    SetVehicleLights(vehicle, math.random(0, 1) == 1 and 2 or 0)
end

local function getCatastrophicFireConfig()
    local staged = (Config.Effects and Config.Effects.staged) or {}
    return staged.catastrophicDamage or {}
end

local function keepDamagingBurningVehicle(vehicle, state, plate)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if not state.igniteFire then return end
    if IsEntityDead(vehicle) then return end

    local cfg = getCatastrophicFireConfig()
    if cfg.continueDamagingUntilDestroyed == false then return end

    local now = GetGameTimer()
    local tickMs = math.max(100, math.floor(tonumber(cfg.damageTickMs) or 1000))
    if (now - (MKState.LastFireDamageAt[plate] or 0)) < tickMs then return end
    MKState.LastFireDamageAt[plate] = now

    local engineStep = tonumber(cfg.fireEngineHealthStep) or 150.0
    local tankStep = tonumber(cfg.firePetrolTankHealthStep) or 80.0
    local minEngine = tonumber(cfg.minimumEngineHealth) or -4000.0
    local minTank = tonumber(cfg.minimumPetrolTankHealth) or -1000.0

    local currentEngine = GetVehicleEngineHealth(vehicle)
    local nextEngine = math.max(minEngine, currentEngine - engineStep)
    if nextEngine < currentEngine then
        SetVehicleEngineHealth(vehicle, nextEngine)
    end

    local currentTank = GetVehiclePetrolTankHealth(vehicle)
    local nextTank = math.max(minTank, currentTank - tankStep)
    if nextTank < currentTank then
        SetVehiclePetrolTankHealth(vehicle, nextTank)
    end

    SetVehicleUndriveable(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)

    if not IsEntityOnFire(vehicle) then
        StartEntityFire(vehicle)
        MKState.BurningVehicles[plate] = true
    end
end

local function getComparableUnixTime(state)
    if type(GetCloudTimeAsInt) == 'function' then
        local cloudTime = GetCloudTimeAsInt()
        if type(cloudTime) == 'number' and cloudTime > 0 then
            return cloudTime
        end
    end

    local startedAt = tonumber(state and state.startedAt)
    local receivedAt = tonumber(state and state._receivedAtTimer)
    if startedAt and receivedAt then
        return startedAt + math.floor((GetGameTimer() - receivedAt) / 1000)
    end

    return math.floor(GetGameTimer() / 1000)
end

local function maybeHandleVehicleFire(vehicle, state, plate)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if IsEntityDead(vehicle) then
        stopVehicleFire(vehicle, plate)
        MKState.FireExtinguished[plate] = true
        return
    end

    local stopAt = tonumber(state.extinguishFireAt) or nil
    local now = getComparableUnixTime(state)

    if MKState.BurningVehicles[plate] and stopAt and stopAt > 0 and now >= stopAt then
        stopVehicleFire(vehicle, plate)
        MKState.FireExtinguished[plate] = true
        return
    end

    if not state.igniteFire or MKState.FireExtinguished[plate] then return end

    if not MKState.BurningVehicles[plate] then
        StartEntityFire(vehicle)
        MKState.BurningVehicles[plate] = true
        if stopAt and stopAt > 0 then
            MKState.FireStopAt[plate] = stopAt
        end
    end

    keepDamagingBurningVehicle(vehicle, state, plate)
end

local function applyStateToVehicle(vehicle, state, plate)
    if state.forceEngineOff then
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleUndriveable(vehicle, true)
    else
        SetVehicleUndriveable(vehicle, false)
    end

    if state.torqueMultiplier then
        SetVehicleCheatPowerIncrease(vehicle, tonumber(state.torqueMultiplier) or 1.0)
    end

    if state.hazards then
        SetVehicleIndicatorLights(vehicle, 0, true)
        SetVehicleIndicatorLights(vehicle, 1, true)
    else
        SetVehicleIndicatorLights(vehicle, 0, false)
        SetVehicleIndicatorLights(vehicle, 1, false)
    end

    if state.engineHealthTarget then
        local currentHealth = GetVehicleEngineHealth(vehicle)
        local targetHealth = tonumber(state.engineHealthTarget) or currentHealth
        if currentHealth > targetHealth then
            SetVehicleEngineHealth(vehicle, targetHealth)
        end
    elseif tonumber(state.smokeStage or 0) >= 2 then
        local currentHealth = GetVehicleEngineHealth(vehicle)
        local targetHealth = state.stage and (state.stage >= 3 and 180.0 or 350.0) or 350.0
        if currentHealth > targetHealth then
            SetVehicleEngineHealth(vehicle, targetHealth)
        end
    end

    if state.petrolTankHealthTarget then
        local currentTankHealth = GetVehiclePetrolTankHealth(vehicle)
        local targetTankHealth = tonumber(state.petrolTankHealthTarget) or currentTankHealth
        if currentTankHealth > targetTankHealth then
            SetVehiclePetrolTankHealth(vehicle, targetTankHealth)
        end
    end

    maybeHandleVehicleFire(vehicle, state, plate)
    maybeSputter(vehicle, state, plate)
    maybeHorn(vehicle, state, plate)
    maybeFlickerLights(vehicle, state, plate)
end

RegisterNetEvent('matrix-killswitch:client:applyState', function(data)
    data = data or {}
    local plate = MKUtils.NormalizePlate(data.plate)
    if plate == '' then return end
    data._receivedAtTimer = GetGameTimer()
    MKState.ActiveEffects[plate] = data
end)

RegisterNetEvent('matrix-killswitch:client:syncStates', function(states)
    MKState.ActiveEffects = {}
    for _, state in ipairs(states or {}) do
        local plate = MKUtils.NormalizePlate(state.plate)
        if plate ~= '' then
            state._receivedAtTimer = GetGameTimer()
            MKState.ActiveEffects[plate] = state
        end
    end
end)

RegisterNetEvent('matrix-killswitch:client:clearState', function(plate)
    plate = MKUtils.NormalizePlate(plate)
    MKState.ActiveEffects[plate] = nil
    local vehicle = getVehicleByPlate(plate)
    if vehicle then
        restoreVehicleState(vehicle, plate)
    else
        MKState.BurningVehicles[plate] = nil
        MKState.FireExtinguished[plate] = nil
        MKState.FireStopAt[plate] = nil
    end
end)

CreateThread(function()
    while true do
        Wait(400)
        for plate, state in pairs(MKState.ActiveEffects) do
            local vehicle = getVehicleByPlate(plate)
            if vehicle then
                applyStateToVehicle(vehicle, state, plate)
            end
        end

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local plate = MKUtils.NormalizePlate(GetVehicleNumberPlateText(vehicle))
            local state = MKState.ActiveEffects[plate]
            if state and state.blockRestart then
                DisableControlAction(0, 71, true)
                DisableControlAction(0, 72, true)
            end
        end
    end
end)
