Config = Config or {}

-- ==========================================
-- GŁÓWNE USTAWIENIA (CORE)
-- ==========================================
Config.Framework = 'esx'
Config.UseTarget = 'ox_target'
Config.Inventory = 'tgiann-inventory'

-- Wybór języka (musi odpowiadać nazwie w Locales['nazwa'] w plikach locales)
Config.Locale = 'pl'

-- ==========================================
-- FUNKCJA TŁUMACZEŃ (LOCALES)
-- ==========================================
-- Funkcja pomocnicza do pobierania tekstów z plików językowych
function _L(str)
    if Locales[Config.Locale] and Locales[Config.Locale][str] then
        return Locales[Config.Locale][str]
    end
    return 'Locale ['..str..'] missing'
end

-- ==========================================
-- USTAWIENIA TUNER TABLETU
-- ==========================================
Config.Tablet = {
    -- Nazwa przedmiotu wyzwalającego tablet
    ItemName = 'tuner_tablet',
    
    LaborMargin = {
        Min = 50,  -- Minimalna marża za robociznę (w $)
        Max = 5000 -- Maksymalna marża (do ustawienia w tablecie)
    },
    -- Rangi uprawnione do zarządzania i zamawiania części
    AllowedGrades = { 'boss', 'manager', 'tuner' }
}

-- ==========================================
-- ZABEZPIECZENIA
-- ==========================================
Config.BlacklistedVehicles = {
    'police', 'police2', 'police3', 'ambulance', 'firetruk', 'bmx', 'scorcher'
}

-- ==========================================
-- LOKACJE WARSZTATÓW (TUNER SHOPS)
-- ==========================================
Config.TunerShops = {
    ['LosSantosCustoms'] = {
        Job = 'tuner', -- Wymagana praca (frakcja) do obsługi
        
        -- Strefa służby (Duty)
        DutyMarker = vec3(762.14691162109,-1226.0695800781,24.930212020874),
        
        -- Strefa craftingu/magazynu części
        CraftingStash = vec3(759.29162597656,-1232.2034912109,24.988891601562),
        
        -- Punkt odbioru zamówień (Mod orders z tabletu)
        DeliveryPoint = vec3(746.94805908203,-1215.1169433594,24.661222457886),
        
        -- Stanowisko modyfikacji
        TuningZones = {
            vec3(765.04656982422,-1222.7725830078,24.204795837402)

        },

        -- Hamownia (Dyno)
        DynoZone = {
            Coords = vec3(761.43615722656,-1209.9077148438,23.530738830566),
            Heading = 3.0
        }
    },
}