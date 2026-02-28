local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- OBSŁUGA PRZEDMIOTÓW UŻYWALNYCH (USABLE ITEMS)
-- ==========================================

ESX.RegisterUsableItem(Config.Items.Tools.Tablet, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    if xPlayer.job.name == 'mechanic' or xPlayer.job.name == 'tuner' then
        -- Serwer sprawdza, czy gracz siedzi w aucie (opcjonalnie, lepiej w kliencie)
        TriggerClientEvent('awrp_tuning:checkAndOpenTablet', source)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Błąd', description = 'Nie masz uprawnień.', type = 'error' })
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