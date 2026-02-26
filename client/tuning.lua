local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- FUNKCJE INSTALACYJNE
-- ==========================================

local function PrepareVehicle(vehicle)
    SetVehicleModKit(vehicle, 0)
end

--- Główna funkcja wykonawcza
local function InstallMod(vehicle, modType, modIndex, itemRequired, customAction, customDataKey, customDataValue)
    ESX.TriggerServerCallback('awrp_tuning:checkItem', function(hasItem)
        if not hasItem then
            lib.notify({ title = _L('error_title') or 'Błąd', description = (_L('part_missing') or 'Brak przedmiotu: '):format(itemRequired), type = 'error' })
            return
        end

        TriggerEvent('awrp_tuning:startInstallAnimation')

        if lib.progressBar({
            duration = 7500,
            label = (_L('busy') or 'Montowanie') .. ': ' .. itemRequired .. '...',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true }
        }) then
            ESX.TriggerServerCallback('awrp_tuning:consumeItem', function(consumed)
                if consumed then
                    local plate = AWRPUtils.Trim(GetVehicleNumberPlateText(vehicle))

                    -- 1. Standardowe modyfikacje GTA (Zderzaki, Spoilery, Silnik)
                    if modType ~= nil and modIndex ~= nil then
                        SetVehicleMod(vehicle, modType, modIndex, false)
                    end

                    -- 2. Customowe akcje (Turbo, Szyby, Neony)
                    if customAction then
                        customAction(vehicle)
                    end

                    -- 3. Zapis customowych danych do bazy i efekty natychmiastowe (Swapy, Drift)
                    if customDataKey then
                        TriggerServerEvent('awrp_tuning:saveTuningData', plate, customDataKey, customDataValue)
                        
                        if customDataKey == 'engine' then
                            Entity(vehicle).state:set('engineSound', Config.EngineSwaps[customDataValue].soundName, true)
                        elseif customDataKey == 'drift_tires' then
                            SetVehicleReduceGrip(vehicle, customDataValue)
                        elseif customDataKey == 'bulletproof_tires' then
                            SetVehicleTyresCanBurst(vehicle, not customDataValue)
                        end
                    end

                    TriggerEvent('awrp_tuning:stopInstallAnimation')
                    lib.notify({ title = _L('done') or 'Sukces', description = _L('install_success') or 'Zamontowano część pomyślnie!', type = 'success' })
                else
                    TriggerEvent('awrp_tuning:stopInstallAnimation')
                end
            end, itemRequired)
        else
            TriggerEvent('awrp_tuning:stopInstallAnimation')
            lib.notify({ title = _L('cancel') or 'Anulowano', description = _L('install_cancel') or 'Przerwano montaż.', type = 'warning' })
        end
    end, itemRequired)
end

-- ==========================================
-- GENERATORY DYNAMICZNYCH MENU
-- ==========================================

--- Tworzy podmenu dla części, które mają wiele wariantów (np. spoilery, zderzaki)
local function OpenDynamicModMenu(vehicle, title, modType, requiredItem)
    local numMods = GetNumVehicleMods(vehicle, modType)
    local options = {}

    if numMods == 0 then
        lib.notify({ title = _L('no_options_title') or 'Brak opcji', description = _L('no_options_desc') or 'Ten pojazd nie posiada modyfikacji tego typu.', type = 'info' })
        return
    end

    -- Opcja zdjęcia modyfikacji (Stock)
    table.insert(options, {
        title = (_L('remove_part') or 'Zdemontuj część'):format('Stock'),
        icon = 'xmark',
        onSelect = function()
            InstallMod(vehicle, modType, -1, requiredItem, nil, nil, nil)
        end
    })

    -- Generowanie listy dostępnych części
    for i = 0, numMods - 1 do
        table.insert(options, {
            title = title .. ' - ' .. (_L('variant') or 'Wariant') .. ' ' .. (i + 1),
            description = (_L('install_part') or 'Wymaga: '):format(requiredItem),
            icon = 'wrench',
            onSelect = function()
                InstallMod(vehicle, modType, i, requiredItem, nil, nil, nil)
            end
        })
    end

    local menuId = 'mod_menu_' .. modType
    lib.registerContext({ id = menuId, title = title, options = options })
    lib.showContext(menuId)
end

-- ==========================================
-- GŁÓWNE MENU STREFOWE (ox_lib)
-- ==========================================

RegisterNetEvent('awrp_tuning:openZoneMenu', function(vehicle, zone)
    TriggerEvent('awrp_tuning:setCamera', vehicle, zone)
    PrepareVehicle(vehicle)
    local options = {}

    -- ==========================================
    -- 1. STREFA SILNIKA I PRZODU
    -- ==========================================
    if zone == 'engine' then
        table.insert(options, {
            title = _L('menu_engine') or 'Silnik (Ulepszenie)', icon = 'gauge-high',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('menu_engine') or 'Ulepszenie Silnika', 11, Config.Items.Performance.Engine) end
        })
        table.insert(options, {
            title = _L('menu_transmission') or 'Skrzynia biegów', icon = 'gear',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('menu_transmission') or 'Skrzynia biegów', 13, Config.Items.Performance.Transmission) end
        })
        table.insert(options, {
            title = _L('menu_turbo') or 'Turbosprężarka', description = (_L('install_part') or 'Wymaga: '):format(Config.Items.Performance.Turbo), icon = 'fan',
            onSelect = function() 
                InstallMod(vehicle, nil, nil, Config.Items.Performance.Turbo, function(veh) ToggleVehicleMod(veh, 18, true) end, nil, nil) 
            end
        })
        table.insert(options, {
            title = _L('hood') or 'Maska', icon = 'car',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('hood') or 'Maska', 7, Config.Items.Cosmetics.Hood) end
        })
        table.insert(options, {
            title = _L('grille') or 'Kratka chłodnicy (Grille)', icon = 'bars',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('grille') or 'Kratka chłodnicy', 6, Config.Items.Cosmetics.Grille) end
        })
        table.insert(options, {
            title = _L('horn') or 'Klakson', icon = 'bullhorn',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('horn') or 'Klakson', 14, Config.Items.Cosmetics.Horn) end
        })
        
        -- ENGINE SWAPS
        for k, v in pairs(Config.EngineSwaps) do
            table.insert(options, {
                title = (_L('menu_swap') or 'Swap') .. ': ' .. v.label, 
                description = (_L('install_part') or 'Wymaga: '):format(k), 
                icon = 'fire',
                onSelect = function() InstallMod(vehicle, nil, nil, k, nil, 'engine', k) end
            })
        end

    -- ==========================================
    -- 2. STREFA KÓŁ I ZAWIESZENIA
    -- ==========================================
    elseif zone == 'wheels' then
        table.insert(options, {
            title = _L('menu_suspension') or 'Zawieszenie', icon = 'compress',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('menu_suspension') or 'Zawieszenie', 15, Config.Items.Performance.Suspension) end
        })
        table.insert(options, {
            title = _L('brakes') or 'Hamulce', icon = 'circle-stop',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('brakes') or 'Hamulce', 12, Config.Items.Performance.Brakes) end
        })
        table.insert(options, {
            title = _L('menu_wheels') or 'Felgi (Sportowe)', icon = 'dharmachakra',
            onSelect = function() 
                SetVehicleWheelType(vehicle, 0)
                OpenDynamicModMenu(vehicle, _L('menu_wheels') or 'Felgi', 23, Config.Items.Cosmetics.Rim) 
            end
        })
        table.insert(options, {
            title = _L('bulletproof_tires') or 'Załóż Opony Kuloodporne', description = (_L('install_part') or 'Wymaga: '):format(Config.Items.Wheels.Bulletproof), icon = 'shield',
            onSelect = function() InstallMod(vehicle, nil, nil, Config.Items.Wheels.Bulletproof, nil, 'bulletproof_tires', true) end
        })
        table.insert(options, {
            title = _L('menu_drift_tires') or 'Załóż Opony do Driftu', description = (_L('install_part') or 'Wymaga: '):format(Config.Items.Wheels.Drift), icon = 'rotate-right',
            onSelect = function() InstallMod(vehicle, nil, nil, Config.Items.Wheels.Drift, nil, 'drift_tires', true) end
        })
        table.insert(options, {
            title = _L('stock_tires') or 'Przywróć Opony Standardowe', description = (_L('install_part') or 'Wymaga: '):format(Config.Items.Wheels.Stock), icon = 'car',
            onSelect = function() 
                InstallMod(vehicle, nil, nil, Config.Items.Wheels.Stock, function(veh) 
                    SetVehicleReduceGrip(veh, false)
                    SetVehicleTyresCanBurst(veh, true)
                end, 'drift_tires', false) 
            end
        })

    -- ==========================================
    -- 3. STREFA TYŁU (Wydech/Spoiler)
    -- ==========================================
    elseif zone == 'rear' then
        table.insert(options, {
            title = _L('rear_bumper') or 'Zderzak tylny', icon = 'car-rear',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('rear_bumper') or 'Tylny Zderzak', 2, Config.Items.Cosmetics.RearBumper) end
        })
        table.insert(options, {
            title = _L('spoiler') or 'Spoiler', icon = 'wind',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('spoiler') or 'Spoiler', 0, Config.Items.Cosmetics.Spoiler) end
        })
        table.insert(options, {
            title = _L('exhaust') or 'Wydech', icon = 'smog',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('exhaust') or 'Wydech', 4, Config.Items.Cosmetics.Exhaust) end
        })
        table.insert(options, {
            title = _L('roof') or 'Dach / Bagażnik', icon = 'arrow-up',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('roof') or 'Dach', 10, Config.Items.Cosmetics.Roof) end
        })

    -- ==========================================
    -- 4. STREFA KAROSERII I WNĘTRZA
    -- ==========================================
    elseif zone == 'body' then
        table.insert(options, {
            title = _L('front_bumper') or 'Zderzak przedni', icon = 'car-side',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('front_bumper') or 'Przedni Zderzak', 1, Config.Items.Cosmetics.FrontBumper) end
        })
        table.insert(options, {
            title = _L('side_skirts') or 'Progi (Side Skirts)', icon = 'arrows-left-right',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('side_skirts') or 'Progi', 3, Config.Items.Cosmetics.SideSkirt) end
        })
        table.insert(options, {
            title = _L('fenders') or 'Błotniki (Fenders)', icon = 'car',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('fenders') or 'Błotniki', 8, Config.Items.Cosmetics.Fender) end
        })
        table.insert(options, {
            title = _L('frame') or 'Klatka / Podwozie', icon = 'border-all',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('frame') or 'Klatka bezpieczeństwa', 5, Config.Items.Cosmetics.Frame) end
        })
        table.insert(options, {
            title = _L('armor') or 'Opancerzenie', icon = 'shield-halved',
            onSelect = function() OpenDynamicModMenu(vehicle, _L('armor') or 'Opancerzenie', 16, Config.Items.Performance.Armor) end
        })
        table.insert(options, {
            title = _L('window_tint') or 'Przyciemnianie szyb', description = (_L('install_part') or 'Wymaga: '):format(Config.Items.Cosmetics.WindowTint), icon = 'eye-slash',
            onSelect = function()
                local input = lib.inputDialog(_L('window_tint') or 'Przyciemnianie szyb', {
                    { type = 'select', label = _L('tint_level') or 'Wybierz poziom folii', options = {
                        { value = 0, label = _L('tint_none') or 'Brak (Stock)' }, { value = 1, label = _L('tint_dark') or 'Ciemne (Dark Smoke)' },
                        { value = 2, label = _L('tint_medium') or 'Średnie (Light Smoke)' }, { value = 3, label = _L('tint_limo') or 'Limo (Najciemniejsze)' }
                    }}
                })
                if input and input[1] then
                    InstallMod(vehicle, nil, nil, Config.Items.Cosmetics.WindowTint, function(veh) SetVehicleWindowTint(veh, input[1]) end, nil, nil)
                end
            end
        })
        table.insert(options, {
            title = _L('respray') or 'Lakierowanie (RGB)', description = (_L('install_part') or 'Wymaga: '):format(Config.Items.Cosmetics.Respray), icon = 'palette',
            onSelect = function()
                local input = lib.inputDialog(_L('respray_menu') or 'Mieszalnia lakieru', {
                    { type = 'color', label = _L('respray_color') or 'Nowy kolor główny (Primary)', format = 'rgb' }
                })
                if input and input[1] then
                    local color = input[1] -- Format "rgb(r, g, b)"
                    local r, g, b = color:match("rgb%((%d+), (%d+), (%d+)%)")
                    InstallMod(vehicle, nil, nil, Config.Items.Cosmetics.Respray, function(veh) 
                        SetVehicleCustomPrimaryColour(veh, tonumber(r), tonumber(g), tonumber(b)) 
                    end, 'rgb_primary', { r = tonumber(r), g = tonumber(g), b = tonumber(b) })
                end
            end
        })
    end

    -- Wyświetlanie zbudowanego menu
    local contextId = 'tuning_menu_' .. zone
    lib.registerContext({ id = contextId, title = (_L('zone') or 'Strefa') .. ': ' .. string.upper(zone), options = options })
    lib.showContext(contextId)
end)