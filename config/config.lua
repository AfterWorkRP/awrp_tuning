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
        Job = 'mechanic', -- Wymagana praca (frakcja) do obsługi
        
        -- Strefa służby (Duty)
        DutyMarker = vec3(-203.2, -1328.0, 31.3),
        
        -- Strefa craftingu/magazynu części
        CraftingStash = vec3(-198.5, -1332.1, 31.3),
        
        -- Punkt odbioru zamówień (Mod orders z tabletu)
        DeliveryPoint = vec3(-208.5, -1338.1, 31.3),
        
        -- Stanowisko modyfikacji
        TuningZones = {
            vec3(-211.5, -1324.5, 30.8),
            vec3(-206.5, -1324.5, 30.8)
        },

        -- Hamownia (Dyno)
        DynoZone = {
            Coords = vec3(-215.5, -1327.5, 30.8),
            Heading = 90.0
        }
    },
}