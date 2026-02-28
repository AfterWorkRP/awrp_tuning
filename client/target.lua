local ESX = exports["es_extended"]:getSharedObject()

-- ==========================================
-- FUNKCJE POMOCNICZE
-- ==========================================

--- Sprawdza czy pojazd znajduje się na czarnej liście (np. radiowozy)
--- @param vehicle number Entity pojazdu
--- @return boolean
local function IsVehicleBlacklisted(vehicle)
    local model = GetEntityModel(vehicle)
    for _, blacklistedName in pairs(Config.BlacklistedVehicles) do
        if model == GetHashKey(blacklistedName) then
            return true
        end
    end
    return false
end

--- Sprawdza czy gracz ma odpowiednią pracę do tuningu
--- @return boolean
local function HasMechanicJob()
    local playerData = ESX.GetPlayerData()
    -- Zakładamy, że praca to 'mechanic' lub 'tuner' (możesz dostosować)
    if playerData.job and (playerData.job.name == 'mechanic' or playerData.job.name == 'tuner') then
        return true
    end
    return false
end

local function IsNearTuningZone(entity)
    local coords = GetEntityCoords(entity)
    for _, shop in pairs(Config.TunerShops) do
        for _, zonePos in ipairs(shop.TuningZones) do
            if #(coords - zonePos) < 10.0 then -- Sprawdza promień 10 metrów od punktu
                return true
            end
        end
    end
    return false
end

-- ==========================================
-- INICJALIZACJA OX_TARGET DLA POJAZDÓW
-- ==========================================

CreateThread(function()
    local targetOptions = {
        -- 1. STREFA SILNIKA (Maska / Przód)
        {
            name = 'tuning_engine',
            icon = 'fas fa-wrench',
            label = 'Modyfikacje pod maską',
            bones = { 'engine', 'bonnet' },
            canInteract = function(entity, distance, coords, name, bone)
                -- DODANO: Sprawdzenie strefy IsNearTuningZone(entity)
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity)
            end,
            onSelect = function(data)
                TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'engine')
            end
        },

        -- 2. STREFA KÓŁ I ZAWIESZENIA
        {
            name = 'tuning_wheels',
            icon = 'fas fa-dharmachakra',
            label = 'Modyfikacje kół i zawieszenia',
            bones = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr' },
            canInteract = function(entity, distance, coords, name, bone)
                -- DODANO: Sprawdzenie strefy IsNearTuningZone(entity)
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity)
            end,
            onSelect = function(data)
                TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'wheels')
            end
        },

        -- 3. STREFA TYŁU (Bagażnik / Wydech / Spoiler)
        {
            name = 'tuning_rear',
            icon = 'fas fa-cogs',
            label = 'Modyfikacje tyłu',
            bones = { 'boot', 'exhaust' },
            canInteract = function(entity, distance, coords, name, bone)
                -- DODANO: Sprawdzenie strefy IsNearTuningZone(entity)
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity)
            end,
            onSelect = function(data)
                TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'rear')
            end
        },

        -- 4. STREFA KAROSERII I WNĘTRZA (Drzwi)
        {
            name = 'tuning_body',
            icon = 'fas fa-car-side',
            label = 'Modyfikacje karoserii i wnętrza',
            bones = { 'door_dside_f', 'door_pside_f' },
            canInteract = function(entity, distance, coords, name, bone)
                -- DODANO: Sprawdzenie strefy IsNearTuningZone(entity)
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity)
            end,
            onSelect = function(data)
                TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'body')
            end
        }
    }

    exports.ox_target:addGlobalVehicle(targetOptions)
end)