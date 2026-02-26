local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- OBSŁUGA PRZEDMIOTÓW UŻYWALNYCH (USABLE ITEMS)
-- ==========================================

-- Rejestrujemy Tablet Tunera, aby można było go kliknąć w ekwipunku
ESX.RegisterUsableItem(Config.Items.Tools.Tablet, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Weryfikacja, czy gracz pracujący w warsztacie (frakcja mechanika) może go użyć.
    -- Zakładamy, że główna frakcja to 'mechanic' (zdefiniowane w configu, możesz to rozbudować).
    if xPlayer.job.name == 'mechanic' or xPlayer.job.name == 'tuner' then
        -- Wysyłamy sygnał do klienta, aby otworzył interfejs ox_lib
        TriggerClientEvent('awrp_tuning:openTablet', source)
    else
        -- Zwykły gracz nie wie, jak tego użyć lub nie ma dostępu do bazy
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Błąd dostępu',
            description = 'Nie masz uprawnień do logowania w systemie diagnostycznym.',
            type = 'error'
        })
    end
end)


-- ==========================================
-- BEZPIECZNA KONSUMPCJA CZĘŚCI (ANTI-EXPLOIT)
-- ==========================================

--- Callback sprawdzający, czy gracz w ogóle posiada dany przedmiot.
--- Używany przez klienta np. zanim wyświetli opcję w ox_target.
ESX.RegisterServerCallback('awrp_tuning:checkItem', function(source, cb, itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    local item = xPlayer.getInventoryItem(itemName)
    
    -- Zwracamy true, jeśli przedmiot istnieje i gracz ma chociaż 1 sztukę
    if item and item.count > 0 then
        cb(true)
    else
        cb(false)
    end
end)

--- Callback do faktycznego zabrania przedmiotu z ekwipunku.
--- Wywoływany przez klienta DOPIERO PO ZAKOŃCZENIU animacji/mini-gry.
ESX.RegisterServerCallback('awrp_tuning:consumeItem', function(source, cb, itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    local item = xPlayer.getInventoryItem(itemName)
    
    -- Ponownie sprawdzamy, czy gracz nadal ma ten przedmiot (bo mógł go wyrzucić w trakcie animacji!)
    if item and item.count > 0 then
        xPlayer.removeInventoryItem(itemName, 1)
        cb(true) -- Sukces, zabrano przedmiot, klient może nałożyć modyfikację
    else
        -- Gracz próbował oszukać
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Błąd montażu',
            description = 'Część zniknęła z twoich rąk! Montaż przerwany.',
            type = 'error'
        })
        cb(false) -- Zwracamy fałsz, klient przerwie nakładanie modyfikacji na auto
    end
end)