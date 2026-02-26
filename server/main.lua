local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- INICJALIZACJA SERWERA
-- ==========================================
print('^2[awrp_tuning]^7 Zainicjalizowano zaawansowany system tuningu.')

-- ==========================================
-- OBSŁUGA ZAMÓWIEŃ HURTOWYCH (Z TABLETU)
-- ==========================================

RegisterNetEvent('awrp_tuning:placeWholesaleOrder', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Weryfikacja, czy gracz ma uprawnienia (podwójne sprawdzenie po stronie serwera dla bezpieczeństwa)
    local hasPermission = false
    for _, grade in ipairs(Config.Tablet.AllowedGrades) do
        if xPlayer.job.grade_name == grade then
            hasPermission = true
            break
        end
    end

    if not hasPermission then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Brak uprawnień', description = 'Nie możesz zamawiać części.', type = 'error' })
        return
    end

    -- Obliczanie kosztu zamówienia (Przykładowo: 100$ za każdą sztukę hurtową)
    -- W przyszłości możesz to rozbudować i przypisać ceny hurtowe do Config.Items
    local totalCost = amount * 100 

    -- Pobieranie pieniędzy z konta frakcji (warsztatu)
    -- Zakładamy, że konto warsztatu to 'society_mechanic' (dostosuj do nazwy joba)
    local societyAccount = 'society_' .. xPlayer.job.name

    TriggerEvent('esx_addonaccount:getSharedAccount', societyAccount, function(account)
        if account and account.money >= totalCost then
            -- Pobieramy pieniądze z konta firmy
            account.removeMoney(totalCost)

            -- Informujemy zamawiającego
            TriggerClientEvent('ox_lib:notify', src, { 
                title = 'Opłacono fakturę', 
                description = 'Pobrano $' .. totalCost .. ' z konta firmy. Oczekuj na dostawę.', 
                type = 'success' 
            })

            -- TUTAJ ŁĄCZYMY SIĘ Z TWOIM DRUGIM SKRYPTEM MECHANIKA
            -- Wysyłamy event (np. do skryptu kuriera części), żeby pracownicy mogli przywieźć te paczki.
            -- Zmień 'mechanic_job:addDeliveryTask' na taki event, jakiego używa Twój skrypt:
            TriggerEvent('mechanic_job:addDeliveryTask', societyAccount, itemName, amount)
            
        else
            -- Brak środków na koncie firmy
            TriggerClientEvent('ox_lib:notify', src, { 
                title = 'Odrzucono transakcję', 
                description = 'Brak wystarczających środków na koncie warsztatu (Brakuje $' .. (totalCost - (account and account.money or 0)) .. ').', 
                type = 'error' 
            })
        end
    end)
end)