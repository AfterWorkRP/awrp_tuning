local ESX = exports["es_extended"]:getSharedObject()

local blacklistedHashes = {}
for _, name in pairs(Config.BlacklistedVehicles) do
    blacklistedHashes[GetHashKey(name)] = true
end

local function IsVehicleBlacklisted(vehicle)
    return blacklistedHashes[GetEntityModel(vehicle)] == true
end

local function HasMechanicJob()
    local playerData = ESX.GetPlayerData()
    return playerData.job and AWRPUtils.IsMechanicJob(playerData.job.name)
end

local function IsNearTuningZone(entity, jobName)
    local coords = GetEntityCoords(entity)
    for _, shop in pairs(Config.TunerShops) do
        -- Sprawdzanie konkretnego Joba
        if shop.Job == jobName then
            for _, zonePos in ipairs(shop.TuningZones) do
                if #(coords - zonePos) < 10.0 then
                    return true
                end
            end
        end
    end
    return false
end

CreateThread(function()
    local targetOptions = {
        {
            name = 'tuning_engine',
            icon = 'fas fa-wrench',
            label = 'Modyfikacje pod maską',
            bones = { 'engine', 'bonnet' },
            canInteract = function(entity)
                local jobName = ESX.GetPlayerData().job.name
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity, jobName)
            end,
            onSelect = function(data) TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'engine') end
        },
        {
            name = 'tuning_wheels',
            icon = 'fas fa-dharmachakra',
            label = 'Modyfikacje kół',
            bones = { 'wheel_lf', 'wheel_rf', 'wheel_lr', 'wheel_rr' },
            canInteract = function(entity)
                local jobName = ESX.GetPlayerData().job.name
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity, jobName)
            end,
            onSelect = function(data) TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'wheels') end
        },
        {
            name = 'tuning_rear',
            icon = 'fas fa-cogs',
            label = 'Modyfikacje tyłu',
            bones = { 'boot', 'exhaust' },
            canInteract = function(entity)
                local jobName = ESX.GetPlayerData().job.name
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity, jobName)
            end,
            onSelect = function(data) TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'rear') end
        },
        {
            name = 'tuning_body',
            icon = 'fas fa-car-side',
            label = 'Modyfikacje karoserii',
            bones = { 'door_dside_f', 'door_pside_f' },
            canInteract = function(entity)
                local jobName = ESX.GetPlayerData().job.name
                return HasMechanicJob() and not IsVehicleBlacklisted(entity) and IsNearTuningZone(entity, jobName)
            end,
            onSelect = function(data) TriggerEvent('awrp_tuning:openZoneMenu', data.entity, 'body') end
        }
    }

    exports.ox_target:addGlobalVehicle(targetOptions)
end)