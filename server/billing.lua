local ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('awrp_tuning:sendBill', function(targetId, amount, reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xPlayer or not xTarget then return end

    if not AWRPUtils.IsMechanicJob(xPlayer.job.name) then return end

    -- Zabezpieczenie przed lewymi kwotami
    if type(amount) ~= 'number' or amount <= 0 or amount > 1000000 then
        AWRPUtils.Log('Wykryto próbę oszustwa przy fakturze od gracza ID: ' .. src, 'error')
        return
    end

    local societyName = 'society_' .. xPlayer.job.name
    
    -- Przykład 1: Standardowy esx_billing
    -- TriggerEvent('esx_billing:sendBill', xTarget.source, societyName, tostring(reason), amount)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Faktura wysłana',
        description = 'Wysłano rachunek na kwotę $' .. amount .. ' do obywatela.',
        type = 'success'
    })
end)