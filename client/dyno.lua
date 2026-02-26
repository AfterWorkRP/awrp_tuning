-- ==========================================
-- ALGORYTM HAMOWNI (DYNO)
-- ==========================================

--- Oblicza szacunkową moc (HP) i moment obrotowy (Nm) na podstawie handlingu i modyfikacji
--- @param vehicle number Entity pojazdu
--- @return number hp, number torque
local function CalculateVehiclePerformance(vehicle)
    -- Pobieramy bazowe wartości z pliku handling.meta danego pojazdu
    local mass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass')
    local driveForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
    local maxVelocity = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')

    -- Zabezpieczenie przed dziwnymi wartościami z modowanych aut
    if mass < 100.0 then mass = 1500.0 end
    if driveForce < 0.01 then driveForce = 0.1 end
    if maxVelocity < 10.0 then maxVelocity = 120.0 end

    -- Wzór matematyczny symulujący konie mechaniczne (HP)
    -- Masa * Przyspieszenie * Prędkość Max / stała wartość balansująca
    local baseHp = (mass * driveForce * maxVelocity) / 100.0
    
    -- Wzór na moment obrotowy (Nm)
    local baseTorque = (mass * driveForce) * 1.6

    -- ==========================================
    -- UWZGLĘDNIENIE AKTUALNYCH MODYFIKACJI
    -- ==========================================
    local bonusHp = 0
    local bonusTorque = 0

    -- Sprawdzamy ulepszenie silnika (ID 11)
    local engineMod = GetVehicleMod(vehicle, 11)
    if engineMod ~= -1 then
        bonusHp = bonusHp + ((engineMod + 1) * 25.0) -- Każdy poziom daje ok. 25 KM
        bonusTorque = bonusTorque + ((engineMod + 1) * 30.0)
    end

    -- Sprawdzamy turbosprężarkę (ID 18)
    local hasTurbo = IsToggleModOn(vehicle, 18)
    if hasTurbo then
        bonusHp = bonusHp + 65.0 -- Turbo dodaje 65 KM
        bonusTorque = bonusTorque + 80.0
    end

    -- W przyszłości możemy tu dodać mnożniki z Config.EngineSwaps (np. swap V8)

    local finalHp = math.floor(baseHp + bonusHp)
    local finalTorque = math.floor(baseTorque + bonusTorque)

    return finalHp, finalTorque
end

-- ==========================================
-- EVENTY DLA TABLETU
-- ==========================================

RegisterNetEvent('awrp_tuning:runDynoTest', function(vehicle)
    local ped = PlayerPedId()

    -- 1. Animacja patrzenia w tablet / podpinania kabla
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)

    -- 2. Pasek postępu symulujący badanie diagnostyczne
    if lib.progressBar({
        duration = 5000, -- 5 sekund diagnozy
        label = _L('loading') or 'Pobieranie danych z komputera pokładowego (OBD)...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    }) then
        ClearPedTasks(ped)

        -- 3. Obliczanie wyników
        local hp, torque = CalculateVehiclePerformance(vehicle)

        -- 4. WYŚWIETLENIE NUI (Twój interfejs HTML/JS)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showDyno',
            hp = hp,
            torque = torque
        })
    else
        -- Anulowano
        ClearPedTasks(ped)
        lib.notify({ title = _L('cancel') or 'Przerwano', description = _L('error') or 'Odłączono interfejs diagnostyczny.', type = 'warning' })
    end
end)

-- ==========================================
-- CALLBACKI NUI
-- ==========================================

-- Callback zamykający NUI (odpalany przez skrypt JS pod klawiszem ESC)
RegisterNUICallback('closeDyno', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)