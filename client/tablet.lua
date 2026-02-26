local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- FUNKCJE POMOCNICZE TABLETU
-- ==========================================

--- Sprawdza, czy gracz ma odpowiednią rangę do zamawiania części
--- @return boolean
local function CanOrderParts()
    local playerData = ESX.GetPlayerData()
    if not playerData.job then return false end

    local playerGrade = playerData.job.grade_name
    
    -- Sprawdzamy, czy ranga gracza znajduje się na liście dozwolonych w Configu
    for _, allowedGrade in ipairs(Config.Tablet.AllowedGrades) do
        if playerGrade == allowedGrade then
            return true
        end
    end
    return false
end

-- ==========================================
-- GŁÓWNE MENU TABLETU (ox_lib)
-- ==========================================

RegisterNetEvent('awrp_tuning:openTablet', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local options = {}

    -- 1. HAMOWNIA (DYNO / OBD)
    table.insert(options, {
        title = _L('tablet_dyno') or 'Diagnostyka i Hamownia (OBD)',
        description = _L('tablet_dyno_desc') or 'Podłącz tablet do komputera najbliższego pojazdu, aby zbadać jego osiągi.',
        icon = 'laptop-medical',
        onSelect = function()
            -- Znajdujemy najbliższy pojazd w promieniu 5 metrów
            local closestVehicle, closestDistance = ESX.Game.GetClosestVehicle(coords)
            
            if closestVehicle ~= -1 and closestDistance <= 5.0 then
                -- Wywołujemy event z pliku dyno.lua
                TriggerEvent('awrp_tuning:runDynoTest', closestVehicle)
            else
                lib.notify({ title = _L('error_title') or 'Błąd', description = _L('no_veh_nearby') or 'Brak pojazdu w zasięgu Bluetooth/Kabla.', type = 'error' })
            end
        end
    })

    -- 2. DYNAMICZNY KALKULATOR ROBOCIZNY I FAKTUROWANIE
    table.insert(options, {
        title = _L('tablet_calc') or 'Kalkulator Kosztorysów',
        description = _L('tablet_calc_desc') or 'Oblicz sugerowaną cenę dla klienta na podstawie trudności modyfikacji.',
        icon = 'calculator',
        onSelect = function()
            local input = lib.inputDialog(_L('tablet_calc') or 'Kalkulator Tuningowy', {
                { type = 'number', label = _L('calc_parts_cost') or 'Łączny koszt części hurtowych ($)', required = true, min = 1 },
                { type = 'select', label = _L('calc_difficulty') or 'Poziom skomplikowania montażu', required = true, options = {
                    { value = 1.0, label = (_L('calc_easy') or 'Łatwy (np. Zmiana felg, lakier) - ') .. Config.Tablet.LaborMargin.Min .. '$ bazowo' },
                    { value = 1.5, label = _L('calc_medium') or 'Średni (np. Hamulce, zderzaki)' },
                    { value = 2.5, label = _L('calc_hard') or 'Trudny (np. Turbo, zawieszenie)' },
                    { value = 4.0, label = (_L('calc_expert') or 'Ekspert (np. Engine Swap) - Max ') .. Config.Tablet.LaborMargin.Max .. '$ bazowo' }
                }},
                { type = 'number', label = _L('calc_amount') or 'Ilość montowanych części', required = true, min = 1, default = 1 }
            })

            if input then
                local partsCost = input[1]
                local difficultyMultiplier = input[2]
                local partsCount = input[3]

                -- Obliczamy sugerowaną marżę
                local baseLabor = Config.Tablet.LaborMargin.Min * difficultyMultiplier * partsCount
                
                -- Ograniczenie maksymalnej marży
                if baseLabor > Config.Tablet.LaborMargin.Max then
                    baseLabor = Config.Tablet.LaborMargin.Max
                end

                local finalPrice = partsCost + baseLabor

                local contentStr = _L('calc_summary') or '**Koszt samych części:** $%d\n**Sugerowana robocizna:** $%d\n\n**RAZEM DO ZAPŁATY:** $%d'

                lib.alertDialog({
                    header = _L('calc_result') or 'Kosztorys dla Klienta',
                    content = string.format(
                        contentStr,
                        partsCost, math.floor(baseLabor), math.floor(finalPrice)
                    ),
                    centered = true,
                    cancel = false
                })
                
                -- Tutaj w przyszłości podepniesz swój skrypt od faktur (Billing System)
                -- np. TriggerServerEvent('esx_billing:sendBill', target, 'society_mechanic', 'Tuning Pojazdu', finalPrice)
            end
        end
    })

    -- 3. ZAMAWIANIE CZĘŚCI Z HURTOWNI (Tylko dla Szefa/Managera)
    if CanOrderParts() then
        table.insert(options, {
            title = _L('tablet_orders') or 'Panel Zamówień Hurtowych',
            description = _L('tablet_orders_desc') or 'Złóż zamówienie na części. System wyśle zlecenie do kurierów/mechaników.',
            icon = 'boxes-stacked',
            onSelect = function()
                local input = lib.inputDialog(_L('order_title') or 'Zamówienie Części', {
                    { type = 'input', label = _L('order_name') or 'Nazwa lub Kod Części (np. engine_v8)', required = true },
                    { type = 'number', label = _L('order_amount') or 'Ilość sztuk', required = true, min = 1, max = 50 }
                })

                if input then
                    local partName = input[1]
                    local amount = input[2]

                    -- Wywołujemy server event (który w przyszłości połączysz ze swoim skryptem kurierskim mechanika)
                    TriggerServerEvent('awrp_tuning:placeWholesaleOrder', partName, amount)
                    
                    local descStr = _L('order_sent_desc') or 'Zlecenie na %dx %s zostało przekazane do realizacji.'

                    lib.notify({
                        title = _L('order_sent') or 'Zamówienie wysłane',
                        description = descStr:format(amount, partName),
                        type = 'success'
                    })
                end
            end
        })
    end

    -- Wyświetlamy menu Tabletu
    lib.registerContext({
        id = 'tuner_tablet_menu',
        title = _L('tablet_title') or 'TunerOS - System Zarządzania',
        options = options
    })

    -- Animacja wyciągania telefonu/tabletu (opcjonalnie)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    lib.showContext('tuner_tablet_menu')
    
    -- Kiedy menu zostanie zamknięte, czyścimy animację
    -- ox_lib nie ma wbudowanego callbacku na zamknięcie kontekstu w tak prosty sposób, 
    -- więc dla bezpieczeństwa animacja zniknie po ruchu gracza.
end)