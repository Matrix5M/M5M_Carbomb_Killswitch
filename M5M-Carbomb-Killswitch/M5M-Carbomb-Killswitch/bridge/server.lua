local cachedCore = nil

local function buildSyntheticCore()
    local core = { Shared = { Items = MK.GetSharedItems() }, Functions = {} }

    core.Functions.GetPlayer = function(src)
        if GetResourceState('qbx_core') == 'started' then
            return exports.qbx_core:GetPlayer(src)
        end
        return nil
    end

    core.Functions.GetPlayerByCitizenId = function(citizenId)
        if GetResourceState('qbx_core') == 'started' then
            return exports.qbx_core:GetPlayerByCitizenId(citizenId)
        end
        return nil
    end

    core.Functions.GetPlayers = function()
        if GetResourceState('qbx_core') == 'started' then
            local map = exports.qbx_core:GetQBPlayers() or {}
            local out = {}
            for src, _ in pairs(map) do
                out[#out + 1] = tonumber(src)
            end
            table.sort(out)
            return out
        end
        return GetPlayers()
    end

    core.Functions.CreateUseableItem = function(item, cb)
        if GetResourceState('qbx_core') == 'started' then
            return exports.qbx_core:CreateUseableItem(item, cb)
        end
        return nil
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

function MKGetPlayers()
    local core = MKCore()
    if core and core.Functions and core.Functions.GetPlayers then
        return core.Functions.GetPlayers()
    end
    return GetPlayers()
end

function MKCreateUsableItem(itemName, cb)
    local core = MKCore()
    if core and core.Functions and core.Functions.CreateUseableItem then
        return core.Functions.CreateUseableItem(itemName, cb)
    end
    return nil
end

function MKGetPlayer(src)
    local core = MKCore()
    if core and core.Functions and core.Functions.GetPlayer then
        return core.Functions.GetPlayer(src)
    end
    return nil
end

function MKGetCitizenId(src)
    local player = MKGetPlayer(src)
    if not player then return nil end
    local pd = player.PlayerData or {}
    return pd.citizenid or pd.citizenId or pd.charid
end

function MKGetCharName(src)
    local player = MKGetPlayer(src)
    if not player then return ('Player %s'):format(src) end
    local pd = player.PlayerData or {}
    local charinfo = pd.charinfo or {}
    local first = charinfo.firstname or charinfo.firstName or ''
    local last = charinfo.lastname or charinfo.lastName or ''
    local name = (tostring(first) .. ' ' .. tostring(last)):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then name = pd.name or ('Player %s'):format(src) end
    return name
end

function MKGetJobName(src)
    local player = MKGetPlayer(src)
    local pd = player and player.PlayerData or {}
    local job = pd.job or {}
    return job.name
end

function MKGetGangName(src)
    local player = MKGetPlayer(src)
    local pd = player and player.PlayerData or {}
    local gang = pd.gang or {}
    return gang.name
end

function MKRemoveItem(src, itemName, amount, metadata)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local inventory = MK.ResolveInventory()
    if inventory == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(src, itemName, amount, metadata)
    end

    local player = MKGetPlayer(src)
    if player and player.Functions and player.Functions.RemoveItem then
        return player.Functions.RemoveItem(itemName, amount, false, metadata)
    end

    return false
end

function MKAddItem(src, itemName, amount, metadata)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local inventory = MK.ResolveInventory()
    if inventory == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(src, itemName, amount, metadata)
    end

    local player = MKGetPlayer(src)
    if player and player.Functions and player.Functions.AddItem then
        return player.Functions.AddItem(itemName, amount, false, metadata)
    end

    return false
end

function MKGetItemCount(src, itemName)
    local inventory = MK.ResolveInventory()
    if inventory == 'ox_inventory' and GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:Search(src, 'count', itemName) or 0
    end

    local player = MKGetPlayer(src)
    if player and player.Functions and player.Functions.GetItemByName then
        local item = player.Functions.GetItemByName(itemName)
        return item and (item.amount or item.count or 0) or 0
    end

    return 0
end
