local SERVICE_CLASSES = {
    [17] = true,
    [18] = true,
}

local EMERGENCY_CLASSES = {
    [18] = true,
}

function MKIsAdmin(src)
    if Config.UseAceForAdmin and IsPlayerAceAllowed(src, Config.AdminAcePermission) then
        return true
    end

    local citizenId = MKGetCitizenId(src)
    if citizenId and MKUtils.InSet(citizenId, Config.AdminCitizenIds or {}) then
        return true
    end

    local player = MKGetPlayer(src)
    local groups = Config.AdminGroups or {}
    local permissions = player and player.PlayerData and player.PlayerData.permissions
    if type(permissions) == 'table' then
        for _, group in ipairs(groups) do
            if permissions[group] then return true end
        end
    end

    return false
end

function MKCheckPermissionBlock(src, block, missingItemMessage, requiredItemOverride)
    block = block or {}
    local hasAccess = false

    if block.allowEveryone then
        hasAccess = true
    else
        local citizenId = MKGetCitizenId(src)
        local job = MKGetJobName(src)
        local gang = MKGetGangName(src)

        if citizenId and MKUtils.InSet(citizenId, block.citizenids or {}) then hasAccess = true end
        if (not hasAccess) and job and MKUtils.InSet(job, block.jobs or {}) then hasAccess = true end
        if (not hasAccess) and gang and MKUtils.InSet(gang, block.gangs or {}) then hasAccess = true end
    end

    if not hasAccess then return false, Config.Strings.actionDenied end

    local requiredItem = tostring(requiredItemOverride or block.requiredItem or '')
    if requiredItem ~= '' and MKGetItemCount(src, requiredItem) <= 0 then
        return false, missingItemMessage or Config.Strings.actionDenied
    end

    return true, nil
end

function MKCanUsePermissionBlock(src, block)
    local ok = MKCheckPermissionBlock(src, block)
    return ok == true
end

function MKCanManageDevice(src, device)
    if not device or device.is_removed then return false end
    if MKIsAdmin(src) then return true end
    local citizenId = MKGetCitizenId(src)
    return citizenId and device.owner_citizenid == citizenId
end

function MKVehicleModelIsListed(model, list)
    local normalized = MKUtils.NormalizeModelValue(model)
    for _, entry in ipairs(list or {}) do
        local e = MKUtils.NormalizeModelValue(entry)
        if e == normalized then return true end
    end
    return false
end

function MKIsVehicleBlacklisted(model, class)
    if Config.Blacklist.modelAllowlistOverrides and MKVehicleModelIsListed(model, Config.Blacklist.modelAllowlistOverrides) then
        return false
    end

    if Config.Blacklist.blockEmergencyVehicles and EMERGENCY_CLASSES[tonumber(class) or -1] then
        return true
    end

    if Config.Blacklist.blockServiceVehicles and SERVICE_CLASSES[tonumber(class) or -1] then
        return true
    end

    if MKUtils.InSet(tostring(class or ''), Config.Blacklist.vehicleClasses or {}) then
        return true
    end

    if MKVehicleModelIsListed(model, Config.Blacklist.vehicleModels or {}) then
        return true
    end

    return false
end

function MKRememberDetection(src, plate)
    MKRuntime.DetectionBySource[src] = MKRuntime.DetectionBySource[src] or {}
    MKRuntime.DetectionBySource[src][plate] = os.time()
end

function MKWasDetectedBySource(src, plate)
    local stamp = MKRuntime.DetectionBySource[src] and MKRuntime.DetectionBySource[src][plate]
    if not stamp then return false end
    return (os.time() - stamp) <= 600
end

function MKClearDetection(src, plate)
    if MKRuntime.DetectionBySource[src] then
        MKRuntime.DetectionBySource[src][plate] = nil
    end
end

function MKSetCooldown(bucket, key, seconds)
    MKRuntime.Cooldowns[bucket] = MKRuntime.Cooldowns[bucket] or {}
    MKRuntime.Cooldowns[bucket][key] = os.time() + math.floor(tonumber(seconds) or 0)
end

function MKIsCooldownActive(bucket, key)
    local expires = MKRuntime.Cooldowns[bucket] and MKRuntime.Cooldowns[bucket][key]
    return expires and expires > os.time() or false
end
