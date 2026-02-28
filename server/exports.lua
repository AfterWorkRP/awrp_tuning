exports('GetEngineRepairMultiplier', function(plate)
    if not plate then return 1.0 end

    -- Użycie zoptymalizowanej logiki bazy danych
    local tuningData = AWRPUtils.GetVehicleCustomTuning(plate)

    if tuningData and tuningData.engine then
        local engineId = tuningData.engine
        if Config.EngineSwaps[engineId] and Config.EngineSwaps[engineId].repairMultiplier then
            return Config.EngineSwaps[engineId].repairMultiplier
        end
    end

    return 1.0
end)