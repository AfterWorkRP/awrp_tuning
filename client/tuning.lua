local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- ZMIENNE POMOCNICZE (STATE MANAGEMENT)
-- ==========================================
local originalMods = {}
local currentVehicle = nil

-- Koła i specjalne flagi
local savedWheelType = -1
local currentWheelType = -1
local originalDrift = false
local originalBulletproof = false

-- Zapis oryginalnych kolorów, by ESC poprawnie je cofało
local originalColors = {
    primary = {r = 0, g = 0, b = 0},
    secondary = {r = 0, g = 0, b = 0},
    pearl = 0,
    wheel = 0,
    dash = 0,
    interior = 0,
    windowTint = -1,
    plateIndex = 0,
    livery = -1
}

local originalLighting = {
    xenon = { enabled = false, color = 0, custom = { enabled = false, r = 255, g = 255, b = 255 } },
    neon  = { enabled = { false, false, false, false }, color = { r = 255, g = 255, b = 255 } }
}

-- ==========================================
-- FALLBACKI (Tłumaczenia i Narzędzia)
-- ==========================================
local function _L(key)
    if _G._L then return _G._L(key) end
    return tostring(key)
end

local function _trim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

AWRPUtils = AWRPUtils or {}
AWRPUtils.Trim = AWRPUtils.Trim or _trim

-- ==========================================
-- WRAPPERY OŚWIETLENIA (Skrócone dla czytelności)
-- ==========================================
local function SetXenonEnabled(vehicle, enabled) SetVehicleModKit(vehicle, 0) ToggleVehicleMod(vehicle, 22, enabled == true) end
local function GetXenonEnabled(vehicle) local ok, state = pcall(function() return IsToggleModOn(vehicle, 22) end) return ok and state == true or false end
local function SetXenonColorIndex(vehicle, colorIndex) colorIndex = tonumber(colorIndex) or 0 SetXenonEnabled(vehicle, true) if SetVehicleXenonLightsColor then SetVehicleXenonLightsColor(vehicle, colorIndex) else Citizen.InvokeNative(0xE41033B25D003A07, vehicle, colorIndex) end end
local function GetXenonColorIndex(vehicle) local ok, val = pcall(function() if GetVehicleXenonLightsColour then return GetVehicleXenonLightsColour(vehicle) end return Citizen.InvokeNative(0x3DFF319A831E0CDB, vehicle) end) val = ok and tonumber(val) or 0 return (val < 0 and 0 or (val > 12 and 12 or val)) end
local function SetXenonCustomRGB(vehicle, r, g, b) r, g, b = tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255 SetXenonEnabled(vehicle, true) if SetVehicleXenonLightsCustomColor then SetVehicleXenonLightsCustomColor(vehicle, r, g, b) else Citizen.InvokeNative(0x1683E7F0, vehicle, r, g, b) end end
local function ClearXenonCustomRGB(vehicle) if ClearVehicleXenonLightsCustomColor then ClearVehicleXenonLightsCustomColor(vehicle) else Citizen.InvokeNative(0x2867ED8C, vehicle) end end
local function TryGetXenonCustomRGB(vehicle) local ok, a, b, c, d = pcall(function() return GetVehicleXenonLightsCustomColor(vehicle) end) if ok then if type(a) == 'boolean' then return a == true, tonumber(b) or 255, tonumber(c) or 255, tonumber(d) or 255 elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'number' then return true, tonumber(a) or 255, tonumber(b) or 255, tonumber(c) or 255 end end return false, 255, 255, 255 end
local function SetNeonEnabled(vehicle, index, enabled) SetVehicleNeonLightEnabled(vehicle, index, enabled == true) end
local function GetNeonEnabled(vehicle, index) local ok, state = pcall(function() return IsVehicleNeonLightEnabled(vehicle, index) end) return ok and state == true or false end
local function SetNeonRGB(vehicle, r, g, b) r, g, b = tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255 SetVehicleNeonLightsColour(vehicle, r, g, b) end
local function GetNeonRGB(vehicle) local ok, r, g, b = pcall(function() return GetVehicleNeonLightsColour(vehicle) end) if ok then return tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255 end return 255,255,255 end

local function CaptureStateOriginal(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    -- Kolory RGB
    local pr, pg, pb = GetVehicleCustomPrimaryColour(vehicle)
    local sr, sg, sb = GetVehicleCustomSecondaryColour(vehicle)
    originalColors.primary = {r = pr, g = pg, b = pb}
    originalColors.secondary = {r = sr, g = sg, b = sb}
    
    -- Inne kolory i warianty
    originalColors.pearl, originalColors.wheel = GetVehicleExtraColours(vehicle)
    originalColors.dash = GetVehicleDashboardColour(vehicle)
    originalColors.interior = GetVehicleInteriorColour(vehicle)
    originalColors.windowTint = GetVehicleWindowTint(vehicle)
    originalColors.plateIndex = GetVehicleNumberPlateTextIndex(vehicle)
    originalColors.livery = GetVehicleLivery(vehicle)
    
    -- Opony
    originalDrift = GetVehicleReduceGrip(vehicle)
    originalBulletproof = not GetVehicleTyresCanBurst(vehicle)
    savedWheelType = GetVehicleWheelType(vehicle)
    currentWheelType = savedWheelType

    -- Światła
    originalLighting.xenon.enabled = GetXenonEnabled(vehicle)
    originalLighting.xenon.color = GetXenonColorIndex(vehicle)
    local hasCustom, cr, cg, cb = TryGetXenonCustomRGB(vehicle)
    originalLighting.xenon.custom.enabled = hasCustom
    originalLighting.xenon.custom.r, originalLighting.xenon.custom.g, originalLighting.xenon.custom.b = cr, cg, cb

    for i = 0, 3 do originalLighting.neon.enabled[i+1] = GetNeonEnabled(vehicle, i) end
    local nr, ng, nb = GetNeonRGB(vehicle)
    originalLighting.neon.color.r, originalLighting.neon.color.g, originalLighting.neon.color.b = nr, ng, nb
end

local function RestoreStateOriginal(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    SetVehicleModKit(vehicle, 0)
    
    -- Mody
    for modType, modIndex in pairs(originalMods) do
        if type(modType) == 'number' then SetVehicleMod(vehicle, modType, modIndex, false) end
    end
    
    -- Koła
    if savedWheelType ~= -1 then SetVehicleWheelType(vehicle, savedWheelType) end
    SetVehicleReduceGrip(vehicle, originalDrift)
    SetVehicleTyresCanBurst(vehicle, not originalBulletproof)

    -- Kolory
    SetVehicleCustomPrimaryColour(vehicle, originalColors.primary.r, originalColors.primary.g, originalColors.primary.b)
    SetVehicleCustomSecondaryColour(vehicle, originalColors.secondary.r, originalColors.secondary.g, originalColors.secondary.b)
    SetVehicleExtraColours(vehicle, originalColors.pearl, originalColors.wheel)
    SetVehicleDashboardColour(vehicle, originalColors.dash)
    SetVehicleInteriorColour(vehicle, originalColors.interior)
    SetVehicleWindowTint(vehicle, originalColors.windowTint)
    SetVehicleNumberPlateTextIndex(vehicle, originalColors.plateIndex)
    SetVehicleLivery(vehicle, originalColors.livery)

    -- Światła
    SetXenonEnabled(vehicle, originalLighting.xenon.enabled)
    if originalLighting.xenon.custom.enabled then
        SetXenonCustomRGB(vehicle, originalLighting.xenon.custom.r, originalLighting.xenon.custom.g, originalLighting.xenon.custom.b)
    else
        ClearXenonCustomRGB(vehicle)
        SetXenonColorIndex(vehicle, originalLighting.xenon.color or 0)
        SetXenonEnabled(vehicle, originalLighting.xenon.enabled)
    end
    SetNeonRGB(vehicle, originalLighting.neon.color.r, originalLighting.neon.color.g, originalLighting.neon.color.b)
    for i = 0, 3 do SetNeonEnabled(vehicle, i, originalLighting.neon.enabled[i+1] == true) end
end

-- ==========================================
-- LIVE PREVIEW / RESET
-- ==========================================
local function ApplyPreview(vehicle, modType, modIndex, customData)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetVehicleModKit(vehicle, 0)

    if modType == 23 then
        SetVehicleWheelType(vehicle, currentWheelType ~= -1 and currentWheelType or 0)
        SetVehicleMod(vehicle, 23, modIndex, false)
    elseif modType == 'rgb_primary' then
        if customData then SetVehicleCustomPrimaryColour(vehicle, customData.r, customData.g, customData.b) end
    elseif modType == 'rgb_secondary' then
        if customData then SetVehicleCustomSecondaryColour(vehicle, customData.r, customData.g, customData.b) end
    elseif modType == 'pearl' then
        local _, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, modIndex, wheelColor)
    elseif modType == 'wheel_color' then
        local pearlColor, _ = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, pearlColor, modIndex)
    elseif modType == 'dash_color' then
        SetVehicleDashboardColour(vehicle, modIndex)
    elseif modType == 'int_color' then
        SetVehicleInteriorColour(vehicle, modIndex)
    elseif modType == 'window_tint' then
        SetVehicleWindowTint(vehicle, modIndex)
    elseif modType == 'plate_index' then
        SetVehicleNumberPlateTextIndex(vehicle, modIndex)
    elseif modType == 'livery' then
        SetVehicleMod(vehicle, 48, modIndex, false)
        SetVehicleLivery(vehicle, modIndex)
    elseif modType == 'xenon_color' then
        ClearXenonCustomRGB(vehicle)
        SetXenonColorIndex(vehicle, modIndex)
    elseif modType == 'xenon_toggle' then
        SetXenonEnabled(vehicle, modIndex == 1)
    elseif modType == 'neon_toggle' then
        if customData and customData.idx ~= nil then SetNeonEnabled(vehicle, customData.idx, customData.enabled == true) end
    elseif modType == 'neon_rgb' then
        if customData then SetNeonRGB(vehicle, customData.r, customData.g, customData.b) end
    elseif type(modType) == 'number' then
        SetVehicleMod(vehicle, modType, modIndex, false)
    end
end

-- ==========================================
-- INSTALL: część / akcja
-- ==========================================
local function InstallMod(vehicle, modType, modIndex, itemRequired, customAction, customDataKey, customDataValue)
    if not itemRequired or itemRequired == "" then itemRequired = "Brak ID w configu" end -- Fallback zabezpieczający

    ESX.TriggerServerCallback('awrp_tuning:checkItem', function(hasItem)
        if not hasItem then
            lib.notify({ title = _L('error_title'), description = _L('part_missing'):format(itemRequired), type = 'error' })
            return
        end

        if lib.progressBar({
            duration = 4000,
            label = _L('busy') .. ': ' .. itemRequired,
            useWhileDead = false,
            canCancel = true,
            disable = { car = false, move = true, combat = true }
        }) then
            ESX.TriggerServerCallback('awrp_tuning:consumeItem', function(consumed)
                if consumed then
                    local plate = AWRPUtils.Trim(GetVehicleNumberPlateText(vehicle))
                    SetVehicleModKit(vehicle, 0)

                    if type(modType) == 'number' then
                        if modType == 23 then SetVehicleWheelType(vehicle, currentWheelType ~= -1 and currentWheelType or 0) end
                        SetVehicleMod(vehicle, modType, modIndex, false)
                        originalMods[modType] = modIndex
                    end

                    if customAction then customAction(vehicle) end

                    if customDataKey then
                        TriggerServerEvent('awrp_tuning:saveTuningData', plate, customDataKey, customDataValue)
                    end

                    lib.notify({ title = _L('done'), description = _L('install_success'), type = 'success' })
                end
            end, itemRequired)
        end
    end, itemRequired)
end

-- Instaler bez modType (np do toggle drift/bulletproof)
local function InstallAction(vehicle, itemRequired, applyFn, onCommit, customDataKey, customDataValue)
    InstallMod(vehicle, nil, nil, itemRequired, applyFn, customDataKey, customDataValue)
    if onCommit then onCommit() end
end

-- ==========================================
-- MENU: KATEGORIE I LISTY
-- ==========================================
local function OpenModCategory(title, modType, requiredItem, returnMenuId)
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end
    local veh = currentVehicle
    SetVehicleModKit(veh, 0)

    if originalMods[modType] == nil and type(modType) == 'number' then
        originalMods[modType] = GetVehicleMod(veh, modType)
    end

    local numMods = 0
    if modType == 'livery' then
        numMods = GetNumVehicleMods(veh, 48) > 0 and GetNumVehicleMods(veh, 48) or GetVehicleLiveryCount(veh)
    elseif modType == 'window_tint' then numMods = 7
    elseif modType == 'plate_index' then numMods = 6
    elseif type(modType) == 'number' then numMods = GetNumVehicleMods(veh, modType) end

    local options = {}
    options[#options + 1] = { label = "Fabryczne (Stock / None)", args = { modIndex = -1 }, close = false }

    for i = 0, numMods - 1 do
        local label = ("%s Wariant #%d"):format(title, i + 1)
        if type(modType) == 'number' then
            local textLabel = GetModTextLabel(veh, modType, i)
            if textLabel and GetLabelText(textLabel) ~= "NULL" then label = GetLabelText(textLabel) end
        end
        options[#options + 1] = { label = label, args = { modIndex = i }, close = false }
    end

    local currentIdx = -1
    if modType == 'livery' then currentIdx = GetVehicleLivery(veh)
    elseif modType == 'window_tint' then currentIdx = GetVehicleWindowTint(veh)
    elseif modType == 'plate_index' then currentIdx = GetVehicleNumberPlateTextIndex(veh)
    elseif type(modType) == 'number' then currentIdx = GetVehicleMod(veh, modType) end
    
    local defaultIndex = (currentIdx == -1) and 1 or (currentIdx + 2)
    local menuId = ('tuning_mod_menu_%s'):format(tostring(modType))

    lib.registerMenu({
        id = menuId,
        title = title,
        position = 'top-right',
        disableInput = true,
        options = options,
        defaultIndex = defaultIndex,
        onSelected = function(_, _, args)
            if not args or args.modIndex == nil then return end
            ApplyPreview(veh, modType, args.modIndex)
        end,
        onClose = function()
            RestoreStateOriginal(veh)
            if returnMenuId then lib.showMenu(returnMenuId) end
        end,
    }, function(_, _, args)
        if not args or args.modIndex == nil then return end
        
        -- Customowe akcje dla specjalnych modType
        if modType == 'window_tint' then
            InstallMod(veh, nil, nil, requiredItem, function(v) SetVehicleWindowTint(v, args.modIndex) end, 'window_tint', args.modIndex)
            originalColors.windowTint = args.modIndex
        elseif modType == 'plate_index' then
            InstallMod(veh, nil, nil, requiredItem, function(v) SetVehicleNumberPlateTextIndex(v, args.modIndex) end, 'plate_index', args.modIndex)
            originalColors.plateIndex = args.modIndex
        elseif modType == 'livery' then
            InstallMod(veh, nil, nil, requiredItem, function(v) SetVehicleMod(v, 48, args.modIndex, false) SetVehicleLivery(v, args.modIndex) end, 'livery', args.modIndex)
            originalColors.livery = args.modIndex
        else
            InstallMod(veh, modType, args.modIndex, requiredItem)
        end
    end)

    lib.showMenu(menuId)
end

local function OpenColorPicker(title, modType, requiredItem, customDataKey, returnMenuId)
    local veh = currentVehicle
    local input = lib.inputDialog(title, {{ type = 'color', label = "Wybierz Kolor", format = 'rgb' }})
    if input and input[1] then
        local r, g, b = input[1]:match("rgb%((%d+), (%d+), (%d+)%)")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        
        ApplyPreview(veh, modType, nil, {r = r, g = g, b = b})
        
        InstallAction(veh, requiredItem, function(v)
            if modType == 'rgb_primary' then SetVehicleCustomPrimaryColour(v, r, g, b) originalColors.primary = {r=r,g=g,b=b}
            elseif modType == 'rgb_secondary' then SetVehicleCustomSecondaryColour(v, r, g, b) originalColors.secondary = {r=r,g=g,b=b} end
        end, nil, customDataKey, {r = r, g = g, b = b})
    end
    lib.showMenu(returnMenuId)
end

local function OpenColorIndexMenu(title, modType, maxIndex, requiredItem, customDataKey, returnMenuId)
    local veh = currentVehicle
    local options = { { label = "⬅ Powrót", args = { back = true }, close = false } }
    for i = 0, maxIndex do options[#options+1] = { label = ("Opcja koloru #%d"):format(i), args = { idx = i }, close = false } end

    lib.registerMenu({
        id = "tuning_color_index_" .. modType,
        title = title,
        position = 'top-right',
        disableInput = true,
        options = options,
        onSelected = function(_, _, args)
            if not args or args.back then return end
            ApplyPreview(veh, modType, args.idx)
        end,
        onClose = function() RestoreStateOriginal(veh) if returnMenuId then lib.showMenu(returnMenuId) end end
    }, function(_, _, args)
        if not args then return end
        if args.back then lib.showMenu(returnMenuId) return end

        InstallAction(veh, requiredItem, function(v)
            if modType == 'pearl' then local _,w = GetVehicleExtraColours(v) SetVehicleExtraColours(v, args.idx, w) originalColors.pearl = args.idx
            elseif modType == 'wheel_color' then local p,_ = GetVehicleExtraColours(v) SetVehicleExtraColours(v, p, args.idx) originalColors.wheel = args.idx
            elseif modType == 'dash_color' then SetVehicleDashboardColour(v, args.idx) originalColors.dash = args.idx
            elseif modType == 'int_color' then SetVehicleInteriorColour(v, args.idx) originalColors.interior = args.idx end
        end, nil, customDataKey, args.idx)
    end)
    lib.showMenu("tuning_color_index_" .. modType)
end

-- ==========================================
-- ROOT MENUS
-- ==========================================
local function OpenPaintMenu()
    lib.registerMenu({
        id = 'tuning_paint_menu',
        title = 'Mieszalnia Lakierów',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Kolor Główny (Primary RGB)", args = { open = 'picker', type = 'rgb_primary', key = 'rgb_primary' } },
            { label = "Kolor Dodatkowy (Secondary RGB)", args = { open = 'picker', type = 'rgb_secondary', key = 'rgb_secondary' } },
            { label = "Odcień Perłowy (Pearlescent)", args = { open = 'index', type = 'pearl', max = 158, key = 'pearl_color' } },
            { label = "Kolor Felg", args = { open = 'index', type = 'wheel_color', max = 158, key = 'wheel_color' } },
            { label = "Kolor Wnętrza (Tapicerka)", args = { open = 'index', type = 'int_color', max = 158, key = 'int_color' } },
            { label = "Kolor Deski Rozdzielczej", args = { open = 'index', type = 'dash_color', max = 158, key = 'dash_color' } },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then lib.showMenu('tuning_root_menu') return end
        local item = Config.Items.Cosmetics.Respray
        if args.open == 'picker' then OpenColorPicker(args.type, args.type, item, args.key, 'tuning_paint_menu')
        elseif args.open == 'index' then OpenColorIndexMenu(args.type, args.type, args.max, item, args.key, 'tuning_paint_menu') end
    end)
    lib.showMenu('tuning_paint_menu')
end

local function OpenBodyMenu()
    local item = Config.Items.Cosmetics
    lib.registerMenu({
        id = 'tuning_body_menu',
        title = 'Karoseria i Zewnętrzne',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Zderzak Przód", args = { mod = 1, item = item.FrontBumper } },
            { label = "Zderzak Tył",  args = { mod = 2, item = item.RearBumper } },
            { label = "Progi (Side Skirts)", args = { mod = 3, item = item.SideSkirt } },
            { label = "Maska",        args = { mod = 7, item = item.Hood } },
            { label = "Spoiler",      args = { mod = 0, item = item.Spoiler } },
            { label = "Błotniki",     args = { mod = 8, item = item.Fender } },
            { label = "Dach",         args = { mod = 10, item = item.Roof } },
            { label = "Kratka (Grille)", args = { mod = 6, item = item.Grille } },
            { label = "Wydech (Exhaust)", args = { mod = 4, item = item.Exhaust } },
            { label = "Klakson", args = { mod = 14, item = item.Horn } },
            { label = "Przyciemnianie Szyb", args = { mod = 'window_tint', item = item.WindowTint } },
            { label = "Rejestracja (Styl)", args = { mod = 'plate_index', item = item.Plate } },
            { label = "Oklejenie (Livery)", args = { mod = 'livery', item = item.Livery } },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then lib.showMenu('tuning_root_menu') return end
        OpenModCategory(args.label, args.mod, args.item, 'tuning_body_menu')
    end)
    lib.showMenu('tuning_body_menu')
end

local function OpenWheelsMenu()
    lib.registerMenu({
        id = 'tuning_wheels_menu',
        title = 'Koła i Zawieszenie',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Felgi (Sportowe)", args = { wheelType = 0 } },
            { label = "Felgi (Muscle)",   args = { wheelType = 1 } },
            { label = "Felgi (Lowrider)", args = { wheelType = 2 } },
            { label = "Felgi (SUV)",      args = { wheelType = 3 } },
            { label = "Felgi (Off-Road)", args = { wheelType = 4 } },
            { label = "Felgi (Tuner)",    args = { wheelType = 5 } },
            { label = "Felgi (High-End)", args = { wheelType = 7 } },
            { label = "Zawieszenie", args = { mod = 15, item = Config.Items.Performance.Suspension } },
            { label = "Hamulce",     args = { mod = 12, item = Config.Items.Performance.Brakes } },
            { label = "Opony: Załóż Driftowe", args = { action = 'drift', item = Config.Items.Wheels.Drift } },
            { label = "Opony: Załóż Kuloodporne", args = { action = 'bullet', item = Config.Items.Wheels.Bulletproof } },
            { label = "Opony: Przywróć Stock", args = { action = 'stock', item = Config.Items.Wheels.Stock } },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then lib.showMenu('tuning_root_menu') return end

        if args.wheelType ~= nil then
            currentWheelType = args.wheelType
            SetVehicleWheelType(currentVehicle, args.wheelType)
            OpenModCategory("Felgi", 23, Config.Items.Cosmetics.Rim, 'tuning_wheels_menu')
        elseif args.mod then
            OpenModCategory(args.label, args.mod, args.item, 'tuning_wheels_menu')
        elseif args.action then
            local veh = currentVehicle
            if args.action == 'drift' then
                InstallAction(veh, args.item, function(v) SetVehicleReduceGrip(v, true) end, function() originalDrift = true end, 'drift_tires', true)
            elseif args.action == 'bullet' then
                InstallAction(veh, args.item, function(v) SetVehicleTyresCanBurst(v, false) end, function() originalBulletproof = true end, 'bulletproof_tires', true)
            elseif args.action == 'stock' then
                InstallAction(veh, args.item, function(v) SetVehicleReduceGrip(v, false) SetVehicleTyresCanBurst(v, true) end, function() originalDrift = false originalBulletproof = false end, 'stock_tires', true)
            end
        end
    end)
    lib.showMenu('tuning_wheels_menu')
end

local function OpenPerfMenu()
    local item = Config.Items.Performance
    lib.registerMenu({
        id = 'tuning_perf_menu',
        title = 'Osiągi (Performance)',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true } },
            { label = "Ulepszenie Silnika", args = { mod = 11, item = item.Engine } },
            { label = "Skrzynia Biegów", args = { mod = 13, item = item.Transmission } },
            { label = "Turbosprężarka", args = { mod = 'turbo', item = item.Turbo } },
            { label = "Opancerzenie (Armor)", args = { mod = 16, item = item.Armor } },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then lib.showMenu('tuning_root_menu') return end
        if args.mod == 'turbo' then
            InstallAction(currentVehicle, args.item, function(v) ToggleVehicleMod(v, 18, true) end, nil, 'turbo', true)
        else
            OpenModCategory(args.label, args.mod, args.item, 'tuning_perf_menu')
        end
    end)
    lib.showMenu('tuning_perf_menu')
end

local function OpenBennysMenu()
    local item = Config.Items.Cosmetics
    lib.registerMenu({
        id = 'tuning_bennys_menu',
        title = 'Wnętrze & Customowe Dodatki',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Klatka Bezpieczeństwa", args = { mod = 5, item = item.Frame } },
            { label = "Ozdoby (Ornaments)", args = { mod = 25, item = item.Extras } },
            { label = "Deska Rozdzielcza", args = { mod = 26, item = item.Interior } },
            { label = "Zegary (Dials)", args = { mod = 27, item = item.Interior } },
            { label = "Fotele (Seats)", args = { mod = 29, item = item.Interior } },
            { label = "Kierownica (Steering Wheel)", args = { mod = 30, item = item.Interior } },
            { label = "Gałka zmiany biegów", args = { mod = 31, item = item.Interior } },
            { label = "Tabliczki (Plaques)", args = { mod = 32, item = item.Extras } },
            { label = "Głośniki (Speakers)", args = { mod = 33, item = item.Extras } },
            { label = "Bagażnik (Trunk)", args = { mod = 34, item = item.Extras } },
            { label = "Hydraulika", args = { mod = 35, item = item.Extras } },
            { label = "Blok Silnika (Custom)", args = { mod = 36, item = Config.Items.Performance.Engine } },
            { label = "Filtry Powietrza", args = { mod = 37, item = Config.Items.Performance.Engine } },
            { label = "Rozpórki (Struts)", args = { mod = 38, item = Config.Items.Performance.Suspension } },
            { label = "Pokrywa Błotnika (Arch Cover)", args = { mod = 39, item = item.Fender } },
            { label = "Anteny", args = { mod = 40, item = item.Extras } },
            { label = "Zbiornik paliwa (Tank)", args = { mod = 42, item = item.Extras } },
            { label = "Szyby Ozdobne (Windows)", args = { mod = 46, item = item.Extras } }
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then lib.showMenu('tuning_root_menu') return end
        OpenModCategory(args.label, args.mod, args.item, 'tuning_bennys_menu')
    end)
    lib.showMenu('tuning_bennys_menu')
end

-- ROOT MENU BUILDER
local function OpenTuningRootMenu()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return end

    currentVehicle = veh
    CaptureStateOriginal(veh)

    lib.registerMenu({
        id = 'tuning_root_menu',
        title = 'TunerOS - System Diagnostyki',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "Lakiernia", args = { open = 'paint' } },
            { label = "Karoseria i Zewnętrzne", args = { open = 'body' } },
            { label = "Koła i Zawieszenie", args = { open = 'wheels' } },
            { label = "Osiągi i Mechanika", args = { open = 'perf' } },
            { label = "Wnętrze i Custom (Benny's)", args = { open = 'bennys' } },
            -- UWAGA: Moduł świateł korzysta z wcześniej zdefiniowanych OpenLightsMenu z orginalnego kodu
            { label = "Zakończ Tuning", args = { close = true }, close = true },
        },
        onClose = function() ResetVehicleToOriginal() end
    }, function(_, _, args)
        if not args then return end
        if args.close then ResetVehicleToOriginal() return end

        if args.open == 'paint' then OpenPaintMenu()
        elseif args.open == 'body' then OpenBodyMenu()
        elseif args.open == 'wheels' then OpenWheelsMenu()
        elseif args.open == 'perf' then OpenPerfMenu()
        elseif args.open == 'bennys' then OpenBennysMenu()
        end
    end)

    lib.showMenu('tuning_root_menu')
end

function ResetVehicleToOriginal()
    if not currentVehicle then return end
    RestoreStateOriginal(currentVehicle)
    currentVehicle = nil
    originalMods = {}
    savedWheelType = -1
    currentWheelType = -1
end

RegisterNetEvent('awrp_tuning:openTabletMenu', function() OpenTuningRootMenu() end)
exports('OpenTuning', function() OpenTuningRootMenu() end)

-- Obsługa ox_target - otwieranie konkretnego działu w zależności od strefy
RegisterNetEvent('awrp_tuning:openZoneMenu', function(vehicle, zone)
    if not vehicle or vehicle == 0 then return end
    
    -- 1. Budujemy główne menu i zapisujemy snapshot auta
    -- (Dzięki temu przycisk "Powrót" w podmenu będzie działał prawidłowo)
    OpenTuningRootMenu()

    -- 2. Wymuszamy kamerę z pliku camera.lua na konkretną strefę
    TriggerEvent('awrp_tuning:setCamera', vehicle, zone)

    -- 3. Otwieramy od razu konkretny dział w zależności od klikniętej strefy auta
    if zone == 'engine' then
        OpenPerfMenu()
    elseif zone == 'wheels' then
        OpenWheelsMenu()
    elseif zone == 'rear' or zone == 'body' then
        OpenBodyMenu()
    end
end)