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
