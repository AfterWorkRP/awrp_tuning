local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- SYSTEM FAKTUR (BILLING PLACEHOLDER)
-- ==========================================

--- Event do wystawiania faktur za tuning
--- Możesz go wywołać z dowolnego miejsca w kliencie (np. z Tuner Tabletu po zaakceptowaniu kosztorysu)
--- @param targetId number ID gracza, który ma zapłacić
--- @param amount number Kwota do zapłaty
--- @param reason string Tytuł faktury (np. "Tuning Pojazdu - Wymiana Silnika")
RegisterNetEvent('awrp_tuning:sendBill', function(targetId, amount, reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xPlayer or not xTarget then return end

    -- Zabezpieczenie: Czy wystawiający to faktycznie mechanik?
    if xPlayer.job.name ~= 'mechanic' and xPlayer.job.name ~= 'tuner' then
        -- Ktoś próbuje oszukać system i wystawić lewą fakturę
        return
    end

    local societyName = 'society_' .. xPlayer.job.name

    -- ==========================================
    -- MIEJSCE NA TWÓJ SKRYPT FAKTUR
    -- ==========================================
    
    -- Przykład 1: Standardowy esx_billing
    -- TriggerEvent('esx_billing:sendBill', xTarget.source, societyName, reason, amount)

    -- Przykład 2: okokBilling
    -- TriggerEvent('okokBilling:CreateCustomInvoice', xTarget.source, amount, reason, reason, societyName, xPlayer.source)

    -- ==========================================

    -- Opcjonalne powiadomienie dla mechanika, że faktura poszła do klienta
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Faktura wysłana',
        description = 'Wysłano rachunek na kwotę $' .. amount .. ' do obywatela.',
        type = 'success'
    })
end)