MK = MK or {}

local resourceName = GetCurrentResourceName()
local loadedItems = nil

local function loadItemsFile()
    if loadedItems ~= nil then return loadedItems end
    local raw = LoadResourceFile(resourceName, 'items.lua')
    if not raw or raw == '' then
        loadedItems = {}
        return loadedItems
    end

    local chunk, err = load(raw, ('@@%s/items.lua'):format(resourceName), 't', _ENV)
    if not chunk then
        print(('^1[Matrix Killswitch] Failed to load items.lua: %s^7'):format(tostring(err)))
        loadedItems = {}
        return loadedItems
    end

    local ok, result = pcall(chunk)
    loadedItems = ok and type(result) == 'table' and result or {}
    return loadedItems
end

local function normalizeFramework(value)
    value = tostring(value or 'auto'):lower()
    if value == 'qb-core' then value = 'qbcore' end
    if value == 'qbx' or value == 'qbx_core' then value = 'qbox' end
    if value ~= 'auto' and value ~= 'qbcore' and value ~= 'qbox' then value = 'auto' end
    return value
end

local function normalizeInventory(value)
    value = tostring(value or 'auto'):lower()
    if value == 'ox' then value = 'ox_inventory' end
    if value == 'qbinventory' then value = 'qb-inventory' end
    if value ~= 'auto' and value ~= 'ox_inventory' and value ~= 'qb-inventory' then value = 'auto' end
    return value
end

local function normalizeTarget(value)
    value = tostring(value or 'auto'):lower()
    if value == 'ox' then value = 'ox_target' end
    if value == 'qbtarget' then value = 'qb-target' end
    if value ~= 'auto' and value ~= 'ox_target' and value ~= 'qb-target' then value = 'auto' end
    return value
end

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

function MK.ResolveFramework()
    local configured = normalizeFramework(Config and Config.Framework or 'auto')
    if configured ~= 'auto' then return configured end
    if resourceStarted('qbx_core') or resourceStarted('qbx-core') then return 'qbox' end
    if resourceStarted('qb-core') then return 'qbcore' end
    return 'qbcore'
end

function MK.ResolveInventory()
    local configured = normalizeInventory(Config and Config.Inventory or 'auto')
    if configured ~= 'auto' then return configured end
    if resourceStarted('ox_inventory') then return 'ox_inventory' end
    if resourceStarted('qb-inventory') then return 'qb-inventory' end
    return 'ox_inventory'
end

function MK.ResolveTarget()
    local configured = normalizeTarget(Config and Config.Target or 'auto')
    if configured ~= 'auto' then return configured end
    if resourceStarted('ox_target') then return 'ox_target' end
    if resourceStarted('qb-target') then return 'qb-target' end
    return 'ox_target'
end

function MK.LoadItemsFile()
    return loadItemsFile()
end

function MK.GetSharedItems()
    local inventory = MK.ResolveInventory()
    if inventory == 'ox_inventory' and resourceStarted('ox_inventory') then
        local ok, items = pcall(function()
            return exports.ox_inventory:Items()
        end)
        if ok and type(items) == 'table' then return items end
    end

    if rawget(_G, 'QBCore') and QBCore.Shared and type(QBCore.Shared.Items) == 'table' then
        return QBCore.Shared.Items
    end

    return loadItemsFile()
end
