MKUtils = MKUtils or {}

function MKUtils.Clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function MKUtils.Trim(value)
    local trimmed = tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
    return trimmed
end

function MKUtils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = MKUtils.DeepCopy(v)
    end
    return out
end

function MKUtils.Round(num, places)
    local mult = 10 ^ (places or 0)
    return math.floor((tonumber(num) or 0) * mult + 0.5) / mult
end

function MKUtils.CoerceBool(value, default)
    if value == nil then return default end
    local t = type(value)
    if t == 'boolean' then return value end
    if t == 'number' then return value ~= 0 end
    if t == 'string' then
        local normalized = value:lower()
        if normalized == '1' or normalized == 'true' or normalized == 'yes' or normalized == 'on' then return true end
        if normalized == '0' or normalized == 'false' or normalized == 'no' or normalized == 'off' or normalized == '' then return false end
    end
    return default
end

function MKUtils.VectorToTable(coords)
    if type(coords) == 'vector3' or type(coords) == 'vector4' then
        return { x = coords.x, y = coords.y, z = coords.z, w = coords.w }
    end
    return {
        x = tonumber(coords and coords.x) or 0.0,
        y = tonumber(coords and coords.y) or 0.0,
        z = tonumber(coords and coords.z) or 0.0,
        w = tonumber(coords and coords.w) or 0.0
    }
end

function MKUtils.Distance(a, b)
    local ax, ay, az = tonumber(a and a.x) or 0.0, tonumber(a and a.y) or 0.0, tonumber(a and a.z) or 0.0
    local bx, by, bz = tonumber(b and b.x) or 0.0, tonumber(b and b.y) or 0.0, tonumber(b and b.z) or 0.0
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function MKUtils.NormalizePlate(plate)
    local normalized = tostring(plate or ''):upper():gsub('^%s+', ''):gsub('%s+$', '')
    return normalized
end

function MKUtils.NormalizeModelValue(value)
    if type(value) == 'number' then return tostring(value) end
    return tostring(value or ''):lower()
end

function MKUtils.InSet(value, list)
    value = tostring(value or '')
    for i = 1, #(list or {}) do
        if tostring(list[i]) == value then
            return true
        end
    end
    return false
end

function MKUtils.TableLength(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

function MKUtils.FormatSeconds(total)
    total = math.max(0, math.floor(tonumber(total) or 0))
    local minutes = math.floor(total / 60)
    local seconds = total % 60
    if minutes > 0 then
        return ('%dm %02ds'):format(minutes, seconds)
    end
    return ('%ds'):format(seconds)
end


function MKUtils.GetInstallDefinitionByItem(itemName)
    itemName = tostring(itemName or '')
    local defs = Config and Config.Devices and Config.Devices.installItems or {}
    return defs[itemName]
end

function MKUtils.GetDeviceTypeConfig(deviceType)
    deviceType = tostring(deviceType or '')
    local defs = Config and Config.Devices and Config.Devices.deviceTypes or {}
    return defs[deviceType]
end
