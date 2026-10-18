--[[
    ============================================================================
    Loki Medical Suite - Physical Rehabilitation Database Layer (oxmysql)
    Absorbed & Enhanced from Oxlyn Crutch System
    ============================================================================
]]

RehabDB = {
    ready = false,
    tableName = "loki_rehab_recoveries"
}

local RECOVERIES_SCHEMA = [[
    CREATE TABLE IF NOT EXISTS `%s` (
        `identifier`      VARCHAR(64)  NOT NULL,
        `mode`            VARCHAR(16)  NOT NULL,
        `duration`        INT          NOT NULL,
        `ends_at`         BIGINT       NOT NULL,
        `started_at`      BIGINT       NOT NULL,
        `next_stage`      VARCHAR(16)  DEFAULT NULL,
        `next_duration`   INT          DEFAULT NULL,
        `applied_by`      VARCHAR(64)  DEFAULT NULL,
        `applied_by_name` VARCHAR(128) DEFAULT NULL,
        `target_name`     VARCHAR(128) DEFAULT NULL,
        `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`identifier`),
        KEY `idx_ends_at` (`ends_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

local function initDatabase()
    local sql = RECOVERIES_SCHEMA:format(RehabDB.tableName)
    MySQL.query.await(sql)
    RehabDB.ready = true
    print("^2[Loki Medical]^7 Tabela de reabilitação física (`" .. RehabDB.tableName .. "`) inicializada com sucesso.")
    TriggerEvent("loki_prescriptions:rehab:databaseReady")
end

function RehabDB.Upsert(identifier, data)
    if not RehabDB.ready then return end

    MySQL.prepare(
        "INSERT INTO `" .. RehabDB.tableName .. [[`
            (`identifier`, `mode`, `duration`, `ends_at`, `started_at`,
             `next_stage`, `next_duration`,
             `applied_by`, `applied_by_name`, `target_name`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `mode`            = VALUES(`mode`),
            `duration`        = VALUES(`duration`),
            `ends_at`         = VALUES(`ends_at`),
            `started_at`      = VALUES(`started_at`),
            `next_stage`      = VALUES(`next_stage`),
            `next_duration`   = VALUES(`next_duration`),
            `applied_by`      = VALUES(`applied_by`),
            `applied_by_name` = VALUES(`applied_by_name`),
            `target_name`     = VALUES(`target_name`)
        ]],
        {
            identifier,
            data.mode,
            data.duration,
            data.endsAt,
            data.startedAt or os.time(),
            data.nextStage,
            data.nextDuration,
            data.appliedBy,
            data.appliedByName,
            data.targetName
        }
    )
end

function RehabDB.UpdateEnd(identifier, endsAt, duration)
    if not RehabDB.ready then return end

    MySQL.prepare(
        "UPDATE `" .. RehabDB.tableName .. [[`
        SET `ends_at` = ?, `duration` = ?
        WHERE `identifier` = ?
        ]],
        { endsAt, duration, identifier }
    )
end

function RehabDB.Delete(identifier)
    if not RehabDB.ready then return end

    MySQL.prepare(
        "DELETE FROM `" .. RehabDB.tableName .. "` WHERE `identifier` = ?",
        { identifier }
    )
end

function RehabDB.FetchByIdentifier(identifier)
    if not RehabDB.ready then return nil end

    return MySQL.single.await(
        "SELECT * FROM `" .. RehabDB.tableName .. "` WHERE `identifier` = ? LIMIT 1",
        { identifier }
    )
end

function RehabDB.FetchAllActive()
    if not RehabDB.ready then return {} end

    local rows = MySQL.query.await(
        "SELECT * FROM `" .. RehabDB.tableName .. "` WHERE `ends_at` > ?",
        { os.time() }
    )
    return rows or {}
end

function RehabDB.PruneExpired()
    if not RehabDB.ready then return end

    MySQL.prepare(
        "DELETE FROM `" .. RehabDB.tableName .. "` WHERE `ends_at` <= ?",
        { os.time() }
    )
end

CreateThread(function()
    local tries = 0
    while GetResourceState("oxmysql") ~= "started" and tries < 200 do
        Wait(50)
        tries = tries + 1
    end

    local ok, err = pcall(initDatabase)
    if not ok then
        print("^1[Loki Medical]^7 Erro ao instalar tabela de reabilitação: " .. tostring(err))
        return
    end

    RehabDB.PruneExpired()
end)
