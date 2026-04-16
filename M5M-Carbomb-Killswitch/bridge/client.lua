local cachedCore = nil
local qbZoneNames = {}
local qbGlobalVehicleOptions = {}
local uniqueCounter = 0

local function nextUnique(prefix)
    uniqueCounter = uniqueCounter + 1
    return ('%s_%s_%d'):format(prefix or 'matrix_killswitch', GetGameTimer(), uniqueCounter)
end

local function getPlayerDataFallback()
    if type(QBX) == 'table' and type(QBX.PlayerData) == 'table' then
        return QBX.PlayerData
    end

    local state = LocalPlayer and LocalPlayer.state
    if state then
        if type(state.PlayerData) == 'table' then return state.PlayerData end
        if type(state.playerData) == 'table' then return state.playerData end
    end

    return {}
end

local function buildSyntheticCore()
    local core = { Shared = { Items = MK.GetSharedItems() }, Functions = {} }

    core.Functions.GetPlayerData = function()
        return getPlayerDataFallback()
    end

    core.Functions.Notify = function(message, nType)
        if GetResourceState('qbx_core') == 'started' then
            exports.qbx_core:Notify(tostring(message), tostring(nType or 'inform'))
            return
        end

        if lib and lib.notify then
            lib.notify({ description = tostring(message), type = tostring(nType or 'inform') })
        end
    end

    return core
end

function MKCore()
    if cachedCore then return cachedCore end
    local framework = MK.ResolveFramework()
    if framework == 'qbcore' and GetResourceState('qb-core') == 'started' then
        cachedCore = exports['qb-core']:GetCoreObject()
        _G.QBCore = cachedCore
        return cachedCore
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core then
            cachedCore = core
            _G.QBCore = cachedCore
            return cachedCore
        end
    end

    cachedCore = buildSyntheticCore()
    _G.QBCore = cachedCore
    return cachedCore
end

function MKNotify(message, nType)
    local core = MKCore()
    if core and core.Functions and core.Functions.Notify then
        core.Functions.Notify(message, nType or 'inform')
        return
    end
    if lib and lib.notify then
        lib.notify({ description = tostring(message), type = tostring(nType or 'inform') })
    end
end

function MKProgress(data)
    if lib and lib.progressBar then
        return lib.progressBar(data)
    end
    Wait(tonumber(data and data.duration) or 1000)
    return true
end

function MKSkillCheck(input)
    if lib and lib.skillCheck then
        return lib.skillCheck(input or {'easy'})
    end
    return true
end

function MKInputDialog(title, rows)
    if lib and lib.inputDialog then
        return lib.inputDialog(title, rows)
    end
    return nil
end


function MKHasItem(itemName, amount)
    amount = math.floor(tonumber(amount) or 1)
    local inventory = MK.ResolveInventory()

    if inventory == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', itemName) or 0
        return count >= amount
    end

    local core = MKCore()
    local pd = (core and core.Functions and core.Functions.GetPlayerData and core.Functions.GetPlayerData()) or {}
    local items = pd.items or {}
    for _, item in pairs(items) do
        if item and item.name == itemName then
            local count = tonumber(item.amount or item.count or 0) or 0
            if count >= amount then
                return true
            end
        end
    end

    return false
end

MKTarget = MKTarget or {}

local function qbOptionFromOx(opt)
    return {
        icon = opt.icon,
        label = tostring(opt.label or opt.name or nextUnique('label')),
        action = function(entity)
            if opt.onSelect then
                opt.onSelect({ entity = entity, coords = GetEntityCoords(entity) })
                return
            end
            if opt.action then return opt.action(entity) end
        end,
        canInteract = function(entity, distance, data)
            if opt.canInteract then
                return opt.canInteract(entity, distance, data and data.coords or nil, opt.name, nil)
            end
            return true
        end,
        distance = tonumber(opt.distance) or 2.0
    }
end

function MKTarget:addGlobalVehicle(options)
    local target = MK.ResolveTarget()
    if target == 'ox_target' and GetResourceState('ox_target') == 'started' then
        return exports.ox_target:addGlobalVehicle(options)
    end

    if target ~= 'qb-target' or GetResourceState('qb-target') ~= 'started' then
        return nil
    end

    local qbOptions = {}
    for _, opt in ipairs(options or {}) do
        qbOptions[#qbOptions + 1] = qbOptionFromOx(opt)
    end

    exports['qb-target']:AddGlobalVehicle({
        options = qbOptions,
        distance = tonumber(Config.DefaultTargetDistance) or 2.0
    })

    local id = nextUnique('qb_global_vehicle')
    qbGlobalVehicleOptions[id] = true
    return id
end

function MKTarget:addSphereZone(data)
    if MK.ResolveTarget() == 'ox_target' and GetResourceState('ox_target') == 'started' then
        return exports.ox_target:addSphereZone(data)
    end

    if MK.ResolveTarget() ~= 'qb-target' or GetResourceState('qb-target') ~= 'started' then
        return nil
    end

    local name = tostring(data.name or nextUnique('killswitch_zone'))
    local options = {}
    for _, opt in ipairs(data.options or {}) do
        options[#options + 1] = qbOptionFromOx(opt)
    end

    exports['qb-target']:AddCircleZone(name, data.coords, tonumber(data.radius or 1.25), {
        name = name,
        debugPoly = data.debug == true,
        useZ = true
    }, {
        options = options,
        distance = tonumber(data.distance) or 2.0
    })

    qbZoneNames[name] = true
    return name
end

function MKTarget:removeZone(zoneId)
    if not zoneId then return end
    if MK.ResolveTarget() == 'ox_target' and GetResourceState('ox_target') == 'started' then
        return exports.ox_target:removeZone(zoneId)
    end

    if MK.ResolveTarget() == 'qb-target' and GetResourceState('qb-target') == 'started' then
        exports['qb-target']:RemoveZone(tostring(zoneId))
        qbZoneNames[tostring(zoneId)] = nil
    end
end

exports('useInstantKillswitch', function(data, slot)
    if MKInstall and MKInstall.Start then MKInstall.Start(nil, 'killswitch_instant') end
    return true
end)

exports('useDelayedKillswitch', function(data, slot)
    if MKInstall and MKInstall.Start then MKInstall.Start(nil, 'killswitch_delayed') end
    return true
end)

exports('useStagedKillswitch', function(data, slot)
    if MKInstall and MKInstall.Start then MKInstall.Start(nil, 'car_bomb') end
    return true
end)

exports('useEmpKillswitch', function(data, slot)
    if MKInstall and MKInstall.Start then MKInstall.Start(nil, 'killswitch_emp') end
    return true
end)

exports('useKillswitchDevice', function(data, slot)
    if MKInstall and MKInstall.Start then MKInstall.Start(nil, 'killswitch_device') end
    return true
end)

exports('useKillswitchRemote', function(data, slot)
    if MKRemote and MKRemote.OpenMenu then MKRemote.OpenMenu() end
    return true
end)

exports('useDeviceScanner', function(data, slot)
    if MKDetect and MKDetect.Start then MKDetect.Start() end
    return true
end)

exports('useDeviceRemovalKit', function(data, slot)
    if MKRemove and MKRemove.Start then MKRemove.Start() end
    return true
end)
