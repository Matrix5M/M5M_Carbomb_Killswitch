Database = Database or {}

local function tryExec(sql, params)
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync(sql, params or {})
    end)
    if not ok then
        print(('^1[Matrix Killswitch] Database error: %s^7'):format(tostring(result)))
        return nil
    end
    return result
end

local function tryInsert(sql, params)
    local ok, result = pcall(function()
        return exports.oxmysql:insertSync(sql, params or {})
    end)
    if not ok then
        print(('^1[Matrix Killswitch] Database insert error: %s^7'):format(tostring(result)))
        return nil
    end
    return result
end

local function tryExecQuiet(sql, params)
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync(sql, params or {})
    end)
    if not ok then return nil end
    return result
end

local function columnExists(tableName, columnName)
    local rows = tryExecQuiet([[
        SELECT COUNT(*) AS count
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, columnName }) or {}
    return tonumber(rows[1] and rows[1].count or 0) > 0
end

local function ensureColumn(tableName, columnName, definitionSql)
    if columnExists(tableName, columnName) then return end
    tryExec(('ALTER TABLE `%s` ADD COLUMN %s'):format(tableName, definitionSql))
end

local function decodeDevice(row)
    row = row or {}
    row.id = tonumber(row.id) or 0
    row.plate = MKUtils.NormalizePlate(row.plate)
    row.nickname = tostring(row.nickname or '')
    row.status = tostring(row.status or 'active')
    row.is_hidden = MKUtils.CoerceBool(row.is_hidden, true)
    row.is_removed = MKUtils.CoerceBool(row.is_removed, false)
    row.coords = {
        x = tonumber(row.installed_x) or 0.0,
        y = tonumber(row.installed_y) or 0.0,
        z = tonumber(row.installed_z) or 0.0,
        w = tonumber(row.installed_heading) or 0.0,
    }
    return row
end

function Database.Init()
    tryExec([[
        CREATE TABLE IF NOT EXISTS `vehicle_killswitch_devices` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `owner_citizenid` VARCHAR(100) NOT NULL,
            `installer_name` VARCHAR(100) NULL,
            `plate` VARCHAR(20) NOT NULL,
            `vehicle_model` VARCHAR(100) NULL,
            `device_name` VARCHAR(100) NULL,
            `device_type` VARCHAR(50) NOT NULL DEFAULT 'standard',
            `status` VARCHAR(32) NOT NULL DEFAULT 'active',
            `paired_remote_id` VARCHAR(100) NULL,
            `nickname` VARCHAR(100) NULL,
            `installed_x` DOUBLE NULL,
            `installed_y` DOUBLE NULL,
            `installed_z` DOUBLE NULL,
            `installed_heading` FLOAT NULL,
            `install_notes` VARCHAR(255) NULL,
            `is_hidden` TINYINT(1) NOT NULL DEFAULT 1,
            `is_removed` TINYINT(1) NOT NULL DEFAULT 0,
            `removed_by` VARCHAR(100) NULL,
            `removed_at` TIMESTAMP NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uniq_vehicle_killswitch_plate` (`plate`),
            KEY `idx_vehicle_killswitch_owner` (`owner_citizenid`),
            KEY `idx_vehicle_killswitch_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    tryExec([[
        CREATE TABLE IF NOT EXISTS `vehicle_killswitch_actions` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `device_id` INT NOT NULL,
            `source_citizenid` VARCHAR(100) NULL,
            `action_type` VARCHAR(50) NOT NULL,
            `action_mode` VARCHAR(50) NULL,
            `result` VARCHAR(50) NOT NULL DEFAULT 'success',
            `target_plate` VARCHAR(20) NOT NULL,
            `details_json` LONGTEXT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_vehicle_killswitch_actions_device` (`device_id`),
            KEY `idx_vehicle_killswitch_actions_plate` (`target_plate`),
            KEY `idx_vehicle_killswitch_actions_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    tryExec([[
        CREATE TABLE IF NOT EXISTS `vehicle_killswitch_tracker` (
            `plate` VARCHAR(20) NOT NULL,
            `last_x` DOUBLE NULL,
            `last_y` DOUBLE NULL,
            `last_z` DOUBLE NULL,
            `last_heading` FLOAT NULL,
            `last_seen_at` TIMESTAMP NULL DEFAULT NULL,
            `last_street` VARCHAR(100) NULL,
            `last_zone` VARCHAR(100) NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    ensureColumn('vehicle_killswitch_devices', 'nickname', '`nickname` VARCHAR(100) NULL')
    ensureColumn('vehicle_killswitch_devices', 'paired_remote_id', '`paired_remote_id` VARCHAR(100) NULL')
    ensureColumn('vehicle_killswitch_devices', 'removed_at', '`removed_at` TIMESTAMP NULL DEFAULT NULL')
    ensureColumn('vehicle_killswitch_tracker', 'last_street', '`last_street` VARCHAR(100) NULL')
    ensureColumn('vehicle_killswitch_tracker', 'last_zone', '`last_zone` VARCHAR(100) NULL')
end

function Database.GetDevicesByOwner(citizenid)
    local rows = tryExec('SELECT * FROM vehicle_killswitch_devices WHERE owner_citizenid = ? AND is_removed = 0 ORDER BY id ASC', { citizenid }) or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = decodeDevice(rows[i])
    end
    return out
end

function Database.GetDevicesByRemote(remoteId)
    local rows = tryExec('SELECT * FROM vehicle_killswitch_devices WHERE paired_remote_id = ? AND is_removed = 0 ORDER BY id ASC', { tostring(remoteId or '') }) or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = decodeDevice(rows[i])
    end
    return out
end

function Database.GetAllDevices()
    local rows = tryExec('SELECT * FROM vehicle_killswitch_devices ORDER BY id ASC') or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = decodeDevice(rows[i])
    end
    return out
end

function Database.GetDeviceByPlate(plate)
    local rows = tryExec('SELECT * FROM vehicle_killswitch_devices WHERE plate = ? LIMIT 1', { MKUtils.NormalizePlate(plate) }) or {}
    if rows[1] then return decodeDevice(rows[1]) end
    return nil
end

function Database.GetDeviceById(id)
    local rows = tryExec('SELECT * FROM vehicle_killswitch_devices WHERE id = ? LIMIT 1', { tonumber(id) or 0 }) or {}
    if rows[1] then return decodeDevice(rows[1]) end
    return nil
end

function Database.InsertDevice(data)
    local plate = MKUtils.NormalizePlate(data.plate)
    local existing = Database.GetDeviceByPlate(plate)

    if existing then
        tryExec([[
            UPDATE vehicle_killswitch_devices
            SET
                owner_citizenid = ?,
                installer_name = ?,
                vehicle_model = ?,
                device_name = ?,
                device_type = ?,
                status = ?,
                paired_remote_id = ?,
                nickname = ?,
                installed_x = ?,
                installed_y = ?,
                installed_z = ?,
                installed_heading = ?,
                is_hidden = ?,
                is_removed = 0,
                removed_by = NULL,
                removed_at = NULL
            WHERE plate = ?
        ]], {
            data.owner_citizenid,
            data.installer_name,
            tostring(data.vehicle_model or ''),
            data.device_name,
            data.device_type or 'standard',
            data.status or 'active',
            data.paired_remote_id,
            data.nickname,
            tonumber(data.installed_x) or 0.0,
            tonumber(data.installed_y) or 0.0,
            tonumber(data.installed_z) or 0.0,
            tonumber(data.installed_heading) or 0.0,
            data.is_hidden and 1 or 0,
            plate
        })
        return Database.GetDeviceByPlate(plate)
    end

    local id = tryInsert([[
        INSERT INTO vehicle_killswitch_devices
            (owner_citizenid, installer_name, plate, vehicle_model, device_name, device_type, status, paired_remote_id, nickname, installed_x, installed_y, installed_z, installed_heading, is_hidden, is_removed)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.owner_citizenid,
        data.installer_name,
        plate,
        tostring(data.vehicle_model or ''),
        data.device_name,
        data.device_type or 'standard',
        data.status or 'active',
        data.paired_remote_id,
        data.nickname,
        tonumber(data.installed_x) or 0.0,
        tonumber(data.installed_y) or 0.0,
        tonumber(data.installed_z) or 0.0,
        tonumber(data.installed_heading) or 0.0,
        data.is_hidden and 1 or 0,
        data.is_removed and 1 or 0
    })
    if not id then return nil end
    return Database.GetDeviceByPlate(plate)
end

function Database.UpdateDeviceStatus(plate, status)
    tryExec('UPDATE vehicle_killswitch_devices SET status = ? WHERE plate = ?', { tostring(status or 'active'), MKUtils.NormalizePlate(plate) })
end

function Database.UpdateNickname(plate, nickname)
    tryExec('UPDATE vehicle_killswitch_devices SET nickname = ? WHERE plate = ?', { tostring(nickname or ''), MKUtils.NormalizePlate(plate) })
end

function Database.UpdateRemotePairing(plate, remoteId, status)
    tryExec('UPDATE vehicle_killswitch_devices SET paired_remote_id = ?, status = ? WHERE plate = ?', {
        remoteId,
        tostring(status or 'active'),
        MKUtils.NormalizePlate(plate)
    })
end

function Database.MarkRemoved(plate, removedBy)
    tryExec('UPDATE vehicle_killswitch_devices SET is_removed = 1, status = ?, removed_by = ?, removed_at = NOW() WHERE plate = ?', {
        'removed', tostring(removedBy or ''), MKUtils.NormalizePlate(plate)
    })
end

function Database.DeleteTracker(plate)
    tryExec('DELETE FROM vehicle_killswitch_tracker WHERE plate = ?', { MKUtils.NormalizePlate(plate) })
end

function Database.UpsertTracker(data)
    tryExec([[
        INSERT INTO vehicle_killswitch_tracker (plate, last_x, last_y, last_z, last_heading, last_seen_at, last_street, last_zone)
        VALUES (?, ?, ?, ?, ?, NOW(), ?, ?)
        ON DUPLICATE KEY UPDATE
            last_x = VALUES(last_x),
            last_y = VALUES(last_y),
            last_z = VALUES(last_z),
            last_heading = VALUES(last_heading),
            last_seen_at = NOW(),
            last_street = VALUES(last_street),
            last_zone = VALUES(last_zone)
    ]], {
        MKUtils.NormalizePlate(data.plate),
        tonumber(data.x) or 0.0,
        tonumber(data.y) or 0.0,
        tonumber(data.z) or 0.0,
        tonumber(data.heading) or 0.0,
        tostring(data.street or ''),
        tostring(data.zone or '')
    })
end

function Database.GetTracker(plate)
    local rows = tryExec('SELECT * FROM vehicle_killswitch_tracker WHERE plate = ? LIMIT 1', { MKUtils.NormalizePlate(plate) }) or {}
    return rows[1]
end

function Database.LogAction(deviceId, sourceCitizenId, actionType, actionMode, result, targetPlate, detailsJson)
    tryInsert([[
        INSERT INTO vehicle_killswitch_actions
            (device_id, source_citizenid, action_type, action_mode, result, target_plate, details_json)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        tonumber(deviceId) or 0,
        sourceCitizenId,
        tostring(actionType or ''),
        tostring(actionMode or ''),
        tostring(result or 'success'),
        MKUtils.NormalizePlate(targetPlate),
        detailsJson and json.encode(detailsJson) or nil
    })
end
