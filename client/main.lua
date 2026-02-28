local ESX = exports["es_extended"]:getSharedObject()
local initializedVehicles = {}

-- ==========================================
-- APLIKOWANIE CUSTOMOWYCH DANYCH (Z BAZY)
-- ==========================================

--- Funkcja pobierająca z serwera i nakładająca customowe modyfikacje na auto
--- @param vehicle number Entity pojazdu
--- @param plate string Rejestracja
local function ApplyCustomTuning(vehicle, plate)
    -- Zabezpieczenie, żeby nie pobierać danych dla tego samego auta 100 razy
    if initializedVehicles[plate] then return end

    ESX.TriggerServerCallback('awrp_tuning:getTuningData', function(tuningData)
        if not tuningData then return end

        -- 1. Aplikowanie Lakieru RGB
        if tuningData.rgb_primary then
            SetVehicleCustomPrimaryColour(vehicle, tuningData.rgb_primary.r, tuningData.rgb_primary.g, tuningData.rgb_primary.b)
        end

        -- 2. Aplikowanie Opon Driftowych
        if tuningData.drift_tires then
            SetVehicleReduceGrip(vehicle, true)
        end

        -- 3. Aplikowanie Opon Kuloodpornych
        if tuningData.bulletproof_tires then
            SetVehicleTyresCanBurst(vehicle, false)
        end

        -- 4. Aplikowanie Dźwięku Silnika (State Bag)
        if tuningData.engine and Config.EngineSwaps[tuningData.engine] then
            local soundName = Config.EngineSwaps[tuningData.engine].soundName
            -- Ustawiamy globalną flagę dla tego pojazdu
            Entity(vehicle).state:set('engineSound', soundName, true)
        end

        -- Oznaczamy auto jako załadowane
        initializedVehicles[plate] = true
    end, plate)
end

-- ==========================================
-- DETEKCJA NOWYCH POJAZDÓW (WSIADANIE)
-- ==========================================

-- Najbezpieczniejsza i uniwersalna metoda (kompatybilna z jg-garages).
-- Kiedy gracz wsiada do pojazdu, sprawdzamy, czy auto ma nałożone nasze modyfikacje.
AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName == 'CEventNetworkPlayerEnteredVehicle' then
        local playerId = args[1]
        local vehicle = args[2]

        -- Sprawdzamy czy to my wsiedliśmy do auta
        if playerId == PlayerId() then
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate then
                -- Usuwamy spacje z rejestracji (dla pewności)
                plate = AWRPUtils.Trim(plate)
                ApplyCustomTuning(vehicle, plate)
            end
        end
    end
end)

-- Eksport dla skryptów garażowych (opcjonalny)
-- Jeśli chcesz wywołać to bezpośrednio z kodu jg-garages zaraz po spawnie:
-- exports['awrp_tuning']:LoadVehicleTuning(vehicle, plate)
exports('LoadVehicleTuning', function(vehicle, plate)
    ApplyCustomTuning(vehicle, plate)
end)

-- ==========================================
-- ONESYNC INFINITY - SYNCHRONIZACJA DŹWIĘKÓW
-- ==========================================

-- Ten handler nasłuchuje zmian na całym serwerze.
-- Jeśli jakikolwiek mechanik zamontuje V8, albo z garażu wyjedzie auto z V8,
-- ten kod natychmiast podmieni dźwięk silnika dla KAŻDEGO gracza w okolicy.
AddStateBagChangeHandler('engineSound', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end

    -- Pobieramy entity pojazdu na podstawie nazwy baga
    local entity = GetEntityFromStateBagName(bagName)
    
    -- Zabezpieczenie: czy pojazd istnieje i czy to faktycznie pojazd
    if entity == 0 or not DoesEntityExist(entity) then return end

    -- Podmieniamy natywny dźwięk silnika na ten zdefiniowany w configu (np. 'DOMINATOR' dla V8)
    ForceVehicleEngineAudio(entity, value)
end)

AddStateBagChangeHandler('colorRGB', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end
    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end

    -- Synchronizacja koloru dla wszystkich graczy w pobliżu
    SetVehicleCustomPrimaryColour(entity, value.r, value.g, value.b)
end)