local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- ZMIENNE POMOCNICZE (STATE MANAGEMENT)
-- ==========================================
local originalMods = {}
local currentVehicle = nil

-- wheel types:
local savedWheelType = -1     -- wheel type sprzed wejścia do tuningu
local currentWheelType = -1   -- wheel type aktualnie wybranej kategorii felg (Sport/Muscle/...)

-- lighting state snapshot (żeby ESC zawsze cofał do poprawnego stanu)
local originalLighting = {
    xenon = { enabled = false, color = 0, custom = { enabled = false, r = 255, g = 255, b = 255 } },
    neon  = { enabled = { false, false, false, false }, color = { r = 255, g = 255, b = 255 } } -- 0 L,1 R,2 F,3 B
}

local originalPrimaryRGB = {r = 0, g = 0, b = 0}

-- ==========================================
-- Fallbacki (jeśli w Twoim zasobie są zdefiniowane globalnie, te nie będą użyte)
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
-- WRAPPERY: Xenon/Neon
-- ==========================================

local function SetXenonEnabled(vehicle, enabled)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetVehicleModKit(vehicle, 0)
    ToggleVehicleMod(vehicle, 22, enabled == true)
end

local function GetXenonEnabled(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    local ok, state = pcall(function() return IsToggleModOn(vehicle, 22) end)
    return ok and state == true or false
end

local function SetXenonColorIndex(vehicle, colorIndex)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    colorIndex = tonumber(colorIndex) or 0
    SetXenonEnabled(vehicle, true)

    if SetVehicleXenonLightsColor then
        SetVehicleXenonLightsColor(vehicle, colorIndex)
    elseif SetVehicleXenonLightsColour then
        SetVehicleXenonLightsColour(vehicle, colorIndex)
    else
        Citizen.InvokeNative(0xE41033B25D003A07, vehicle, colorIndex)
    end
end

local function GetXenonColorIndex(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return 0 end
    local ok, val = pcall(function()
        if GetVehicleXenonLightsColour then
            return GetVehicleXenonLightsColour(vehicle)
        end
        return Citizen.InvokeNative(0x3DFF319A831E0CDB, vehicle)
    end)
    val = ok and tonumber(val) or 0
    if val < 0 then val = 0 end
    if val > 12 then val = 12 end
    return val
end

local function SetXenonCustomRGB(vehicle, r, g, b)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    r, g, b = tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255
    SetXenonEnabled(vehicle, true)
    if SetVehicleXenonLightsCustomColor then
        SetVehicleXenonLightsCustomColor(vehicle, r, g, b)
    else
        Citizen.InvokeNative(0x1683E7F0, vehicle, r, g, b)
    end
end

local function ClearXenonCustomRGB(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    if ClearVehicleXenonLightsCustomColor then
        ClearVehicleXenonLightsCustomColor(vehicle)
    else
        Citizen.InvokeNative(0x2867ED8C, vehicle)
    end
end

local function TryGetXenonCustomRGB(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false, 255,255,255 end

    local ok, a, b, c, d = pcall(function()
        return GetVehicleXenonLightsCustomColor(vehicle)
    end)

    if ok then
        if type(a) == 'boolean' then
            return a == true, tonumber(b) or 255, tonumber(c) or 255, tonumber(d) or 255
        elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'number' then
            return true, tonumber(a) or 255, tonumber(b) or 255, tonumber(c) or 255
        end
    end

    return false, 255, 255, 255
end

local function SetNeonEnabled(vehicle, index, enabled)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetVehicleNeonLightEnabled(vehicle, index, enabled == true)
end

local function GetNeonEnabled(vehicle, index)
    if not vehicle or not DoesEntityExist(vehicle) then return false end
    local ok, state = pcall(function() return IsVehicleNeonLightEnabled(vehicle, index) end)
    return ok and state == true or false
end

local function SetNeonRGB(vehicle, r, g, b)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    r, g, b = tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255
    SetVehicleNeonLightsColour(vehicle, r, g, b)
end

local function GetNeonRGB(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return 255,255,255 end
    local ok, r, g, b = pcall(function() return GetVehicleNeonLightsColour(vehicle) end)
    if ok then
        return tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255
    end
    return 255,255,255
end

local function CaptureLightingOriginal(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    originalLighting.xenon.enabled = GetXenonEnabled(vehicle)
    originalLighting.xenon.color = GetXenonColorIndex(vehicle)

    local hasCustom, cr, cg, cb = TryGetXenonCustomRGB(vehicle)
    originalLighting.xenon.custom.enabled = hasCustom
    originalLighting.xenon.custom.r, originalLighting.xenon.custom.g, originalLighting.xenon.custom.b = cr, cg, cb

    for i = 0, 3 do
        originalLighting.neon.enabled[i+1] = GetNeonEnabled(vehicle, i)
    end
    local nr, ng, nb = GetNeonRGB(vehicle)
    originalLighting.neon.color.r, originalLighting.neon.color.g, originalLighting.neon.color.b = nr, ng, nb
end

local function RestoreLightingOriginal(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    SetXenonEnabled(vehicle, originalLighting.xenon.enabled)

    if originalLighting.xenon.custom.enabled then
        SetXenonCustomRGB(vehicle, originalLighting.xenon.custom.r, originalLighting.xenon.custom.g, originalLighting.xenon.custom.b)
    else
        ClearXenonCustomRGB(vehicle)
        SetXenonColorIndex(vehicle, originalLighting.xenon.color or 0)
        SetXenonEnabled(vehicle, originalLighting.xenon.enabled) -- SetXenonColorIndex włącza xenon, więc cofamy
    end

    SetNeonRGB(vehicle, originalLighting.neon.color.r, originalLighting.neon.color.g, originalLighting.neon.color.b)
    for i = 0, 3 do
        SetNeonEnabled(vehicle, i, originalLighting.neon.enabled[i+1] == true)
    end
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

    elseif modType == 'rgb' then
        if customData and customData.r and customData.g and customData.b then
            SetVehicleCustomPrimaryColour(vehicle, customData.r, customData.g, customData.b)
        end

    elseif modType == 'xenon_color' then
        ClearXenonCustomRGB(vehicle)
        SetXenonColorIndex(vehicle, modIndex)

    elseif modType == 'xenon_toggle' then
        SetXenonEnabled(vehicle, modIndex == 1)

    elseif modType == 'neon_toggle' then
        if customData and customData.idx ~= nil then
            SetNeonEnabled(vehicle, customData.idx, customData.enabled == true)
        end

    elseif modType == 'neon_rgb' then
        if customData and customData.r and customData.g and customData.b then
            SetNeonRGB(vehicle, customData.r, customData.g, customData.b)
        end

    elseif type(modType) == 'number' then
        SetVehicleMod(vehicle, modType, modIndex, false)
    end
end

local function ResetVehicleToOriginal()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    SetVehicleModKit(currentVehicle, 0)

    for modType, modIndex in pairs(originalMods) do
        if type(modType) == 'number' then
            SetVehicleMod(currentVehicle, modType, modIndex, false)
        end
    end

    if savedWheelType ~= -1 then
        SetVehicleWheelType(currentVehicle, savedWheelType)
    end

    SetVehicleCustomPrimaryColour(currentVehicle, originalPrimaryRGB.r, originalPrimaryRGB.g, originalPrimaryRGB.b)

    RestoreLightingOriginal(currentVehicle)

    currentVehicle = nil
    originalMods = {}
    savedWheelType = -1
    currentWheelType = -1
end

-- ==========================================
-- INSTALL: część / akcja
-- ==========================================

local function InstallMod(vehicle, modType, modIndex, itemRequired, customAction, customDataKey, customDataValue)
    ESX.TriggerServerCallback('awrp_tuning:checkItem', function(hasItem)
        if not hasItem then
            lib.notify({ title = _L('error_title'), description = _L('part_missing'):format(itemRequired), type = 'error' })
            return
        end

        if lib.progressBar({
            duration = 5000,
            label = _L('busy') .. ': ' .. itemRequired,
            useWhileDead = false,
            canCancel = true,
            disable = { car = false, move = true, combat = true }
        }) then
            ESX.TriggerServerCallback('awrp_tuning:consumeItem', function(consumed)
                if consumed then
                    local plate = AWRPUtils.Trim(GetVehicleNumberPlateText(vehicle))

                    SetVehicleModKit(vehicle, 0)

                    if modType ~= nil and modIndex ~= nil and modType ~= 'rgb' then
                        if modType == 23 then
                            SetVehicleWheelType(vehicle, currentWheelType ~= -1 and currentWheelType or 0)
                        end
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

local function InstallAction(vehicle, itemRequired, applyFn, onCommit, customDataKey, customDataValue)
    if not itemRequired or itemRequired == '' then
        if applyFn then applyFn(vehicle) end
        if onCommit then onCommit() end
        lib.notify({ title = _L('done'), description = _L('install_success'), type = 'success' })
        return
    end

    ESX.TriggerServerCallback('awrp_tuning:checkItem', function(hasItem)
        if not hasItem then
            lib.notify({ title = _L('error_title'), description = _L('part_missing'):format(itemRequired), type = 'error' })
            return
        end

        if lib.progressBar({
            duration = 3500,
            label = _L('busy') .. ': ' .. itemRequired,
            useWhileDead = false,
            canCancel = true,
            disable = { car = false, move = true, combat = true }
        }) then
            ESX.TriggerServerCallback('awrp_tuning:consumeItem', function(consumed)
                if consumed then
                    local plate = AWRPUtils.Trim(GetVehicleNumberPlateText(vehicle))

                    if applyFn then applyFn(vehicle) end
                    if onCommit then onCommit() end

                    if customDataKey then
                        TriggerServerEvent('awrp_tuning:saveTuningData', plate, customDataKey, customDataValue)
                    end

                    lib.notify({ title = _L('done'), description = _L('install_success'), type = 'success' })
                end
            end, itemRequired)
        end
    end, itemRequired)
end

-- ==========================================
-- MENU: lista modów z live preview (onSelected)
-- returnMenuId = menu, do którego wracamy po ESC
-- ==========================================

local function OpenModCategory(title, modType, requiredItem, returnMenuId)
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    local veh = currentVehicle
    SetVehicleModKit(veh, 0)

    if originalMods[modType] == nil and type(modType) == 'number' then
        originalMods[modType] = GetVehicleMod(veh, modType)
    end

    local numMods = (type(modType) == 'number') and GetNumVehicleMods(veh, modType) or 0
    local options = {}

    options[#options + 1] = { label = "Fabryczne (Stock)", args = { modIndex = -1 }, close = false }

    for i = 0, numMods - 1 do
        local textLabel = GetModTextLabel(veh, modType, i)
        local label = textLabel and GetLabelText(textLabel) or "NULL"
        if not label or label == "NULL" then
            label = ("%s #%d"):format(title, i + 1)
        end
        options[#options + 1] = { label = label, args = { modIndex = i }, close = false }
    end

    local currentIdx = -1
    if type(modType) == 'number' then currentIdx = GetVehicleMod(veh, modType) end
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
            if not veh or not DoesEntityExist(veh) then return end
            SetVehicleModKit(veh, 0)

            if modType == 23 then
                SetVehicleWheelType(veh, currentWheelType ~= -1 and currentWheelType or 0)
            end

            if type(modType) == 'number' then
                SetVehicleMod(veh, modType, originalMods[modType] or -1, false)
            end

            if returnMenuId then lib.showMenu(returnMenuId) end
        end,
    }, function(_, _, args)
        if not args or args.modIndex == nil then return end
        InstallMod(veh, modType, args.modIndex, requiredItem)
    end)

    lib.showMenu(menuId)
end

-- ==========================================
-- MENU: Oświetlenie (xenon/neon) – wszystko jako lib.registerMenu
-- ==========================================

local function OpenXenonToggleMenu(requiredItem, returnMenuId)
    local veh = currentVehicle
    if not veh or not DoesEntityExist(veh) then return end

    local options = {
        { label = "⬅ Powrót", args = { back = true }, close = false },
        { label = "Wyłącz Xenony", args = { enabled = false }, close = false },
        { label = "Włącz Xenony",  args = { enabled = true },  close = false },
    }

    lib.registerMenu({
        id = "tuning_xenon_toggle",
        title = "Reflektory Xenon",
        position = 'top-right',
        disableInput = true,
        options = options,
        defaultIndex = GetXenonEnabled(veh) and 3 or 2,

        onSelected = function(_, _, args)
            if not args or args.back then return end
            ApplyPreview(veh, 'xenon_toggle', args.enabled and 1 or 0)
        end,

        onClose = function()
            RestoreLightingOriginal(veh)
            if returnMenuId then lib.showMenu(returnMenuId) end
        end
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu(returnMenuId)
            return
        end

        InstallAction(veh, requiredItem, function(v)
            SetXenonEnabled(v, args.enabled)
        end, function()
            originalLighting.xenon.enabled = args.enabled == true
        end, "xenon_enabled", args.enabled == true)
    end)

    lib.showMenu("tuning_xenon_toggle")
end

local function OpenXenonColorMenu(requiredItem, returnMenuId)
    local veh = currentVehicle
    if not veh or not DoesEntityExist(veh) then return end

    local options = { { label = "⬅ Powrót", args = { back = true }, close = false } }
    for i = 0, 12 do
        options[#options+1] = { label = ("Kolor #%d"):format(i), args = { idx = i }, close = false }
    end

    local currentIdx = GetXenonColorIndex(veh)

    lib.registerMenu({
        id = "tuning_xenon_color",
        title = "Kolor Xenon (0-12)",
        position = 'top-right',
        disableInput = true,
        options = options,
        defaultIndex = (currentIdx + 2), -- +1 bo back, +1 bo 1-based

        onSelected = function(_, _, args)
            if not args or args.back then return end
            ApplyPreview(veh, 'xenon_color', args.idx)
        end,

        onClose = function()
            RestoreLightingOriginal(veh)
            if returnMenuId then lib.showMenu(returnMenuId) end
        end
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu(returnMenuId)
            return
        end

        InstallAction(veh, requiredItem, function(v)
            ClearXenonCustomRGB(v)
            SetXenonColorIndex(v, args.idx)
        end, function()
            originalLighting.xenon.color = args.idx
            originalLighting.xenon.custom.enabled = false
        end, "xenon_color", args.idx)
    end)

    lib.showMenu("tuning_xenon_color")
end

local function OpenXenonCustomMenu(requiredItem, returnMenuId)
    local veh = currentVehicle
    if not veh or not DoesEntityExist(veh) then return end

    local options = {
        { label = "⬅ Powrót", args = { back = true }, close = false },
        { label = "Ustaw Custom RGB…", args = { set = true }, close = false },
        { label = "Wyczyść Custom RGB", args = { clear = true }, close = false },
    }

    lib.registerMenu({
        id = "tuning_xenon_custom",
        title = "Xenon: Custom RGB",
        position = 'top-right',
        disableInput = true,
        options = options,
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu(returnMenuId)
            return
        end

        if args.set then
            local input = lib.inputDialog("Xenon RGB", {{ type = 'color', label = "Kolor", format = 'rgb' }})
            if not input or not input[1] then
                lib.showMenu("tuning_xenon_custom")
                return
            end

            local r_c, g_c, b_c = input[1]:match("rgb%((%d+), (%d+), (%d+)%)")
            r_c, g_c, b_c = tonumber(r_c), tonumber(g_c), tonumber(b_c)

            ApplyPreview(veh, 'xenon_toggle', 1)
            SetXenonCustomRGB(veh, r_c, g_c, b_c)

            InstallAction(veh, requiredItem, function(v)
                SetXenonCustomRGB(v, r_c, g_c, b_c)
            end, function()
                originalLighting.xenon.custom.enabled = true
                originalLighting.xenon.custom.r, originalLighting.xenon.custom.g, originalLighting.xenon.custom.b = r_c, g_c, b_c
            end, "xenon_custom", { r = r_c, g = g_c, b = b_c })

            lib.showMenu("tuning_xenon_custom")
            return
        end

        if args.clear then
            InstallAction(veh, requiredItem, function(v)
                ClearXenonCustomRGB(v)
                SetXenonColorIndex(v, originalLighting.xenon.color or 0)
                SetXenonEnabled(v, originalLighting.xenon.enabled)
            end, function()
                originalLighting.xenon.custom.enabled = false
            end, "xenon_custom", false)

            lib.showMenu("tuning_xenon_custom")
        end
    end)

    lib.showMenu("tuning_xenon_custom")
end

local function OpenNeonToggleMenu(requiredItem, returnMenuId)
    local veh = currentVehicle
    if not veh or not DoesEntityExist(veh) then return end

    local options = {
        { label = "⬅ Powrót", args = { back = true }, close = false },
        { label = "Neony: Wszystkie OFF", args = { mode = "all", enabled = false }, close = false },
        { label = "Neony: Wszystkie ON",  args = { mode = "all", enabled = true },  close = false },
        { label = "Lewy (0) – przełącz",  args = { mode = "one", idx = 0 }, close = false },
        { label = "Prawy (1) – przełącz", args = { mode = "one", idx = 1 }, close = false },
        { label = "Przód (2) – przełącz", args = { mode = "one", idx = 2 }, close = false },
        { label = "Tył (3) – przełącz",   args = { mode = "one", idx = 3 }, close = false },
    }

    lib.registerMenu({
        id = "tuning_neon_toggle",
        title = "Neony: Włącz / Wyłącz",
        position = 'top-right',
        disableInput = true,
        options = options,

        onSelected = function(_, _, args)
            if not args or args.back then return end
            if args.mode == "all" then
                for i = 0, 3 do
                    ApplyPreview(veh, 'neon_toggle', nil, { idx = i, enabled = args.enabled })
                end
            else
                local current = GetNeonEnabled(veh, args.idx)
                ApplyPreview(veh, 'neon_toggle', nil, { idx = args.idx, enabled = not current })
            end
        end,

        onClose = function()
            RestoreLightingOriginal(veh)
            if returnMenuId then lib.showMenu(returnMenuId) end
        end
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu(returnMenuId)
            return
        end

        if args.mode == "all" then
            InstallAction(veh, requiredItem, function(v)
                for i = 0, 3 do SetNeonEnabled(v, i, args.enabled) end
            end, function()
                for i = 0, 3 do originalLighting.neon.enabled[i+1] = args.enabled end
            end, "neon_enabled", args.enabled)
        else
            local idx = args.idx
            local newState = not GetNeonEnabled(veh, idx)
            InstallAction(veh, requiredItem, function(v)
                SetNeonEnabled(v, idx, newState)
            end, function()
                originalLighting.neon.enabled[idx+1] = newState
            end, ("neon_side_%d"):format(idx), newState)
        end
    end)

    lib.showMenu("tuning_neon_toggle")
end

local function OpenNeonColorPicker(requiredItem, returnMenuId)
    local veh = currentVehicle
    if not veh or not DoesEntityExist(veh) then return end

    local input = lib.inputDialog("Neony RGB", {{ type = 'color', label = "Kolor", format = 'rgb' }})
    if not input or not input[1] then
        if returnMenuId then lib.showMenu(returnMenuId) end
        return
    end

    local r_c, g_c, b_c = input[1]:match("rgb%((%d+), (%d+), (%d+)%)")
    r_c, g_c, b_c = tonumber(r_c), tonumber(g_c), tonumber(b_c)

    ApplyPreview(veh, 'neon_rgb', nil, { r = r_c, g = g_c, b = b_c })

    InstallAction(veh, requiredItem, function(v)
        SetNeonRGB(v, r_c, g_c, b_c)
    end, function()
        originalLighting.neon.color.r, originalLighting.neon.color.g, originalLighting.neon.color.b = r_c, g_c, b_c
    end, "neon_color", { r = r_c, g = g_c, b = b_c })

    if returnMenuId then lib.showMenu(returnMenuId) end
end

-- ==========================================
-- ROOT MENUS (bez context menu) – tablet odpala to
-- ==========================================

local function OpenBodyMenu()
    lib.registerMenu({
        id = 'tuning_body_menu',
        title = 'Karoseria',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Zderzak Przód", args = { open = 'mod', title = "Zderzak Przód", modType = 1, item = Config.Items.Cosmetics.FrontBumper }, close = false },
            { label = "Zderzak Tył",  args = { open = 'mod', title = "Zderzak Tył",  modType = 2, item = Config.Items.Cosmetics.RearBumper }, close = false },
            { label = "Progi",        args = { open = 'mod', title = "Progi",        modType = 3, item = Config.Items.Cosmetics.SideSkirt }, close = false },
            { label = "Maska",        args = { open = 'mod', title = "Maska",        modType = 7, item = Config.Items.Cosmetics.Hood }, close = false },
            { label = "Spoiler",      args = { open = 'mod', title = "Spoiler",      modType = 0, item = Config.Items.Cosmetics.Spoiler }, close = false },
            { label = "Błotniki",     args = { open = 'mod', title = "Błotniki",     modType = 8, item = Config.Items.Cosmetics.Fender }, close = false },
            { label = "Dach / Bagażnik", args = { open = 'mod', title = "Dach",      modType = 10, item = Config.Items.Cosmetics.Roof }, close = false },
            { label = "Lakierowanie (Primary)", args = { open = 'paint' }, close = false },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu('tuning_root_menu')
            return
        end

        if args.open == 'paint' then
            local input = lib.inputDialog("Mieszalnia lakieru", {{ type = 'color', label = "Wybierz kolor", format = 'rgb' }})
            if input and input[1] then
                local r_c, g_c, b_c = input[1]:match("rgb%((%d+), (%d+), (%d+)%)")
                InstallMod(currentVehicle, 'rgb', nil, Config.Items.Cosmetics.Respray, function(v)
                    SetVehicleCustomPrimaryColour(v, tonumber(r_c), tonumber(g_c), tonumber(b_c))
                end, 'rgb_primary', {r = tonumber(r_c), g = tonumber(g_c), b = tonumber(b_c)})
            end
            lib.showMenu('tuning_body_menu')
            return
        end

        if args.open == 'mod' then
            OpenModCategory(args.title, args.modType, args.item, 'tuning_body_menu')
        end
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

            { label = "Felgi (Sportowe)", args = { wheelType = 0 }, close = false },
            { label = "Felgi (Muscle)",   args = { wheelType = 1 }, close = false },
            { label = "Felgi (Lowrider)", args = { wheelType = 2 }, close = false },
            { label = "Felgi (SUV)",      args = { wheelType = 3 }, close = false },
            { label = "Felgi (Off-Road)", args = { wheelType = 4 }, close = false },

            { label = "Zawieszenie", args = { open = 'mod', title = "Zawieszenie", modType = 15, item = Config.Items.Performance.Suspension }, close = false },
            { label = "Hamulce",     args = { open = 'mod', title = "Hamulce",     modType = 12, item = Config.Items.Performance.Brakes }, close = false },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu('tuning_root_menu')
            return
        end

        if args.wheelType ~= nil then
            currentWheelType = args.wheelType
            SetVehicleWheelType(currentVehicle, args.wheelType)
            OpenModCategory("Felgi", 23, Config.Items.Cosmetics.Rim, 'tuning_wheels_menu')
            return
        end

        if args.open == 'mod' then
            OpenModCategory(args.title, args.modType, args.item, 'tuning_wheels_menu')
        end
    end)

    lib.showMenu('tuning_wheels_menu')
end

local function OpenPerfMenu()
    lib.registerMenu({
        id = 'tuning_perf_menu',
        title = 'Osiągi (Performance)',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Ulepszenie Silnika", args = { open = 'mod', title = "Silnik", modType = 11, item = Config.Items.Performance.Engine }, close = false },
            { label = "Skrzynia Biegów",     args = { open = 'mod', title = "Skrzynia Biegów", modType = 13, item = Config.Items.Performance.Transmission }, close = false },
            { label = "Turbosprężarka",      args = { open = 'turbo' }, close = false },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu('tuning_root_menu')
            return
        end

        if args.open == 'mod' then
            OpenModCategory(args.title, args.modType, args.item, 'tuning_perf_menu')
            return
        end

        if args.open == 'turbo' then
            InstallMod(currentVehicle, nil, nil, Config.Items.Performance.Turbo, function(v)
                ToggleVehicleMod(v, 18, true)
            end)
            lib.showMenu('tuning_perf_menu')
        end
    end)

    lib.showMenu('tuning_perf_menu')
end

local function OpenInteriorMenu()
    lib.registerMenu({
        id = 'tuning_interior_menu',
        title = 'Wnętrze',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Klatka Bezpieczeństwa", args = { open = 'mod', title = "Klatka", modType = 5,  item = Config.Items.Cosmetics.Frame }, close = false },
            { label = "Wykończenie Kabiny",    args = { open = 'mod', title = "Wnętrze", modType = 27, item = Config.Items.Cosmetics.Interior }, close = false },
            { label = "Ozdoby (Dashboard)",    args = { open = 'mod', title = "Dashboard", modType = 29, item = Config.Items.Cosmetics.Interior }, close = false },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu('tuning_root_menu')
            return
        end
        if args.open == 'mod' then
            OpenModCategory(args.title, args.modType, args.item, 'tuning_interior_menu')
        end
    end)

    lib.showMenu('tuning_interior_menu')
end

local function OpenLightsMenu()
    local xenonItem = (Config.Items and Config.Items.Cosmetics and Config.Items.Cosmetics.Xenon) or nil
    local neonItem  = (Config.Items and Config.Items.Cosmetics and Config.Items.Cosmetics.Neon)  or nil

    lib.registerMenu({
        id = 'tuning_lights_menu',
        title = 'Oświetlenie',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "⬅ Powrót", args = { back = true }, close = false },
            { label = "Xenony: Włącz/Wyłącz", args = { open = 'xenon_toggle', item = xenonItem }, close = false },
            { label = "Xenony: Kolor (0-12)", args = { open = 'xenon_color',  item = xenonItem }, close = false },
            { label = "Xenony: Custom RGB",   args = { open = 'xenon_custom', item = xenonItem }, close = false },
            { label = "Neony: Włącz/Wyłącz",  args = { open = 'neon_toggle',  item = neonItem }, close = false },
            { label = "Neony: Kolor RGB",     args = { open = 'neon_color',   item = neonItem }, close = false },
        }
    }, function(_, _, args)
        if not args then return end
        if args.back then
            lib.showMenu('tuning_root_menu')
            return
        end

        if args.open == 'xenon_toggle' then OpenXenonToggleMenu(args.item, 'tuning_lights_menu') return end
        if args.open == 'xenon_color'  then OpenXenonColorMenu(args.item,  'tuning_lights_menu') return end
        if args.open == 'xenon_custom' then OpenXenonCustomMenu(args.item, 'tuning_lights_menu') return end
        if args.open == 'neon_toggle'  then OpenNeonToggleMenu(args.item,  'tuning_lights_menu') return end
        if args.open == 'neon_color'   then OpenNeonColorPicker(args.item, 'tuning_lights_menu') return end
    end)

    lib.showMenu('tuning_lights_menu')
end

local function OpenTuningRootMenu()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return end

    currentVehicle = veh
    SetVehicleModKit(veh, 0)

    -- snapshot bazowy
    local r, g, b = GetVehicleCustomPrimaryColour(veh)
    originalPrimaryRGB = {r = r, g = g, b = b}
    savedWheelType = GetVehicleWheelType(veh)
    currentWheelType = savedWheelType
    CaptureLightingOriginal(veh)

    lib.registerMenu({
        id = 'tuning_root_menu',
        title = 'TunerOS - Live Preview',
        position = 'top-right',
        disableInput = true,
        options = {
            { label = "Karoseria", args = { open = 'body' }, close = false },
            { label = "Koła i Zawieszenie", args = { open = 'wheels' }, close = false },
            { label = "Osiągi (Performance)", args = { open = 'perf' }, close = false },
            { label = "Wnętrze", args = { open = 'interior' }, close = false },
            { label = "Oświetlenie", args = { open = 'lights' }, close = false },
            { label = "Zamknij", args = { close = true }, close = true },
        },
        onClose = function()
            ResetVehicleToOriginal()
        end
    }, function(_, _, args)
        if not args then return end
        if args.close then
            ResetVehicleToOriginal()
            return
        end

        if args.open == 'body' then OpenBodyMenu() return end
        if args.open == 'wheels' then OpenWheelsMenu() return end
        if args.open == 'perf' then OpenPerfMenu() return end
        if args.open == 'interior' then OpenInteriorMenu() return end
        if args.open == 'lights' then OpenLightsMenu() return end
    end)

    lib.showMenu('tuning_root_menu')
end

-- ==========================================
-- PUBLIC: event + export (tablet może wywołać jedno i drugie)
-- ==========================================

RegisterNetEvent('awrp_tuning:openTabletMenu', function()
    OpenTuningRootMenu()
end)

exports('OpenTuning', function()
    OpenTuningRootMenu()
end)
