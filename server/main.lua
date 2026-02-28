local ESX = exports["es_extended"]:getSharedObject()

print('^2[awrp_tuning]^7 Zainicjalizowano zaawansowany system tuningu.')

RegisterNetEvent('awrp_tuning:placeWholesaleOrder', function(itemName, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Zabezpieczenie danych
    if type(amount) ~= 'number' or amount < 1 or amount > 50 then 
        TriggerClientEvent('ox_lib:notify', src, { title = 'Błąd', description = 'Nieprawidłowa ilość.', type = 'error' })
        return 
    end

    if type(itemName) ~= 'string' or itemName == '' then return end

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

    local totalCost = amount * 100 
    local societyAccount = 'society_' .. xPlayer.job.name

    TriggerEvent('esx_addonaccount:getSharedAccount', societyAccount, function(account)
        if account and account.money >= totalCost then
            account.removeMoney(totalCost)

            TriggerClientEvent('ox_lib:notify', src, { 
                title = 'Opłacono fakturę', 
                description = 'Pobrano $' .. totalCost .. ' z konta firmy. Oczekuj na dostawę.', 
                type = 'success' 
            })

            -- TriggerEvent('mechanic_job:addDeliveryTask', societyAccount, itemName, amount)
        else
            TriggerClientEvent('ox_lib:notify', src, { 
                title = 'Odrzucono transakcję', 
                description = 'Brak wystarczających środków na koncie warsztatu (Brakuje $' .. (totalCost - (account and account.money or 0)) .. ').', 
                type = 'error' 
            })
        end
    end)
end)