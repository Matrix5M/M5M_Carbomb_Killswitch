return {
    Effects = {
        instantDisable = {
            blockRestartUntilCleared = true
        },
        staged = {
            totalDurationSeconds = 28,
            stageDurations = { 6, 8, 8, 6 },
            torqueMultipliers = { 0.9, 0.65, 0.35, 0.0 },
            sputterIntervals = {
                { min = 4500, max = 7000 },
                { min = 2500, max = 4500 },
                { min = 1200, max = 2500 }
            },
            smokeFromStage = 2,
            hazardsFromStage = 2,
            hornWeirdnessFromStage = 3,
            immediateFinalStageOnActivation = true,

            -- shutdown: uses the original staged shutdown path with smoke and hard disable.
            -- catastrophic: pushes the staged device into heavier engine damage and optional fire on the final stage.
            failureMode = 'catastrophic',

            shutdownDamage = {
                smokeEngineHealth = 350.0,
                severeEngineHealth = 180.0
            },

            catastrophicDamage = {
                smokeEngineHealth = 325.0,
                severeEngineHealth = 120.0,
                finalEngineHealth = -150.0,
                finalPetrolTankHealth = 300.0,
                igniteOnFinalStage = true,
                autoExtinguishAfterSeconds = 0,
                continueDamagingUntilDestroyed = true,
                damageTickMs = 1000,
                fireEngineHealthStep = 150.0,
                firePetrolTankHealthStep = 80.0,
                minimumEngineHealth = -4000.0,
                minimumPetrolTankHealth = -1000.0
            }
        },
        emp = {
            durationSeconds = 15,
            lockIgnition = true,
            flickerLights = true,
            messWithHorn = true,
            autoRecover = true
        }
    }
}
