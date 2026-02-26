--- Zwraca mnożnik kosztów naprawy silnika dla podanej rejestracji (plate)
--- @param plate string Rejestracja pojazdu
--- @return number Mnożnik (np. 1.0 dla seryjnego, 2.5 dla V8)
exports('GetEngineRepairMultiplier', function(plate)
    -- Zabezpieczenie: jeśli nie podano rejestracji, zwracamy standardowy mnożnik 1.0
    if not plate then 
        return 1.0 
    end

    -- Usuwamy białe znaki (spacje) z rejestracji na wszelki wypadek (częsty błąd w ESX)
    local formattedPlate = AWRPUtils.Trim(plate)

    -- Pobieramy dane z bazy. Używamy .await, aby funkcja poczekała na wynik 
    -- i mogła go poprawnie zwrócić (synchronicznie) do drugiego skryptu.
    local result = MySQL.query.await('SELECT awrp_tuning FROM `owned_vehicles` WHERE `plate` = ?', {
        formattedPlate
    })

    -- Sprawdzamy, czy auto istnieje w bazie i czy ma jakiekolwiek dane z naszego skryptu
    if result and result[1] and result[1].awrp_tuning then
        
        -- Dekodujemy JSON z naszej kolumny do tabeli LUA
        local tuningData = json.decode(result[1].awrp_tuning)

        -- Jeśli dane są poprawne i auto ma klucz 'engine' (zmieniony silnik)
        if tuningData and tuningData.engine then
            local engineId = tuningData.engine
            
            -- Sprawdzamy w naszym Config-mods.lua, czy taki silnik nadal tam istnieje
            if Config.EngineSwaps[engineId] and Config.EngineSwaps[engineId].repairMultiplier then
                -- Zwracamy mnożnik dla tego silnika
                return Config.EngineSwaps[engineId].repairMultiplier
            end
        end
    end

    -- -- PRZYKŁAD DODANIE SKRYPTU DO MECHANIKA:
    -- -- Mając już gdzieś w kodzie zmienną 'plate' i bazową cenę naprawy 'baseRepairCost':
    --     local repairMultiplier = exports['awrp_tuning']:GetEngineRepairMultiplier(plate)
    --     local finalRepairCost = baseRepairCost * repairMultiplier

    --     print('Całkowity koszt naprawy: $' .. finalRepairCost)

    
    -- Jeśli auto nie ma zmienionego silnika (lub w ogóle nie ma go w bazie), zwracamy domyślne 1.0
    return 1.0
end)