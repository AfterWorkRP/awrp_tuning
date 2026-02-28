local ESX = exports["es_extended"]:getSharedObject()
local initializedVehicles = {}

local function ApplyCustomTuning(vehicle, plate)
    if initializedVehicles[plate] then return end

    ESX.TriggerServerCallback('awrp_tuning:getTuningData', function(tuningData)
        if not tuningData then return end

        if tuningData.rgb_primary then
            SetVehicleCustomPrimaryColour(vehicle, tuningData.rgb_primary.r, tuningData.rgb_primary.g, tuningData.rgb_primary.b)
        end

        if tuningData.drift_tires then
            SetVehicleReduceGrip(vehicle, true)
        end

        if tuningData.bulletproof_tires then
            SetVehicleTyresCanBurst(vehicle, false)
        end

        if tuningData.engine and Config.EngineSwaps[tuningData.engine] then
            local soundName = Config.EngineSwaps[tuningData.engine].soundName
            Entity(vehicle).state:set('engineSound', soundName, true)
        end

        initializedVehicles[plate] = true
    end, plate)
end

-- Zoptymalizowane wykrywanie wejścia do pojazdu przez ox_lib
lib.onCache('vehicle', function(vehicle)
    if vehicle then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then
            plate = AWRPUtils.Trim(plate)
            ApplyCustomTuning(vehicle, plate)
        end
    end
end)

-- Czyszczenie starych pojazdów, aby nie rosła pamięć
lib.onCache('seat', function(seat)
    if not seat then
        initializedVehicles = {}
    end
end)

exports('LoadVehicleTuning', function(vehicle, plate)
    ApplyCustomTuning(vehicle, plate)
end)

AddStateBagChangeHandler('engineSound', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end
    ForceVehicleEngineAudio(entity, value)
end)

AddStateBagChangeHandler('colorRGB', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end
    SetVehicleCustomPrimaryColour(entity, value.r, value.g, value.b)
end)