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

-- ==========================================
-- INICJALIZACJA OX_TARGET DLA POJAZDÓW
-- ==========================================

CreateThread(function()
    -- Definiujemy opcje, które pojawią się na KAŻDYM pojeździe, 
    -- ale tylko w określonych miejscach (bones) i tylko dla mechanika.
    
    local targetOptions = {
        -- 1. STREFA SILNIKA (Maska / Przód)
        {
            name = 'tuning_engine',
            icon = 'fas fa-wrench',
            label = 'Modyfikacje pod maską',
            bones = { 'engine', 'bonnet' }, -- 'bonnet' to maska w GTA
            canInteract = function(entity, distance, coords, name, bone)
                return HasMechanicJob() and not IsVehicleBlacklisted(entity)
            end,
            onSelect = function(data)
                -- Wysyłamy sygnał do otwarcia menu z częściami silnikowymi, turbo, itp.
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
                return HasMechanicJob() and not IsVehicleBlacklisted(entity)
            end,
            onSelect = function(data)
                -- Wysyłamy sygnał do menu obsługującego hamulce, opony (drift tires), stance, felgi
                TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'wheels')
            end
        },

        -- 3. STREFA TYŁU (Bagażnik / Wydech / Spoiler)
        {
            name = 'tuning_rear',
            icon = 'fas fa-cogs',
            label = 'Modyfikacje tyłu',
            bones = { 'boot', 'exhaust' }, -- 'boot' to bagażnik
            canInteract = function(entity, distance, coords, name, bone)
                return HasMechanicJob() and not IsVehicleBlacklisted(entity)
            end,
            onSelect = function(data)
                -- Menu dla spoilerów, wydechów, zderzaków tylnych
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
                return HasMechanicJob() and not IsVehicleBlacklisted(entity)
            end,
            onSelect = function(data)
                -- Menu dla lakieru (RGB/HEX), neonów, klatki bezpieczeństwa, foteli
                TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'body')
            end
        }
    }

    -- Rejestrujemy nasze opcje globalnie dla wszystkich pojazdów w grze
    exports.ox_target:addGlobalVehicle(targetOptions)
end)