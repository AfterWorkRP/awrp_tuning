-- Pobranie obiektu ESX (standard dla ESX Legacy)
local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- FUNKCJE WEWNĘTRZNE BAZY DANYCH
-- ==========================================

--- Pobiera customowe dane tuningu dla podanej rejestracji
--- @param plate string Rejestracja pojazdu
--- @return table Tabela z danymi (lub pusta tabela, jeśli brak)
local function GetVehicleCustomTuning(plate)
    local formattedPlate = AWRPUtils.Trim(plate)
    
    local result = MySQL.query.await('SELECT awrp_tuning FROM `owned_vehicles` WHERE `plate` = ?', {
        formattedPlate
    })

    if result and result[1] and result[1].awrp_tuning then
        return json.decode(result[1].awrp_tuning)
    end
    
    return {} -- Zwracamy pustą tabelę, jeśli auto nie ma naszych modyfikacji
end

--- Zapisuje lub aktualizuje konkretną modyfikację w bazie
--- @param plate string Rejestracja
--- @param key string Klucz modyfikacji (np. 'engine', 'stance', 'drift_tires')
--- @param value any Wartość (np. 'engine_v8', true, albo tabela z ustawieniami stance)
local function SaveVehicleCustomTuning(plate, key, value)
    local formattedPlate = AWRPUtils.Trim(plate)
    
    -- 1. Najpierw pobieramy aktualne dane, żeby ich nie nadpisać!
    local currentData = GetVehicleCustomTuning(formattedPlate)
    
    -- 2. Aktualizujemy tylko ten jeden klucz, który mechanik właśnie zamontował
    currentData[key] = value
    
    -- 3. Zapisujemy zaktualizowanego JSONa z powrotem do bazy
    MySQL.update.await('UPDATE `owned_vehicles` SET `awrp_tuning` = ? WHERE `plate` = ?', {
        json.encode(currentData),
        formattedPlate
    })
end

-- ==========================================
-- CALLBACKI I EVENTY (KOMUNIKACJA Z KLIENTEM)
-- ==========================================

-- Callback używany, gdy gracz wyciąga auto z jg-garages.
-- Klient prosi serwer o customowe dane tuningu (stance, swap silnika, rgb), aby je nałożyć na zrespawnowane auto.
ESX.RegisterServerCallback('awrp_tuning:getTuningData', function(source, cb, plate)
    local data = GetVehicleCustomTuning(plate)
    cb(data)
end)

-- Event wywoływany przez klienta, gdy mechanik pomyślnie zamontuje nową część.
RegisterNetEvent('awrp_tuning:saveTuningData', function(plate, key, value)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    -- Tutaj w przyszłości możemy dodać zabezpieczenie: sprawdzić, czy gracz ma job mechanika
    -- i czy faktycznie stoi blisko tego pojazdu (tzw. ochrona przed cheaterami wywołującymi eventy z Lua executora).
    
    SaveVehicleCustomTuning(plate, key, value)
end)