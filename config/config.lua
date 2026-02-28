Config = Config or {}

Config.Framework = 'esx'
Config.UseTarget = 'ox_target'
Config.Inventory = 'tgiann-inventory'
Config.Locale = 'pl'

function _L(str, ...)
    if Locales[Config.Locale] and Locales[Config.Locale][str] then
        local text = Locales[Config.Locale][str]
        if select('#', ...) > 0 then
            return string.format(text, ...)
        end
        return text
    end
    return 'Locale ['..str..'] missing'
end

Config.Tablet = {
    LaborMargin = {
        Min = 50,
        Max = 5000
    },
    AllowedGrades = { 'boss', 'manager', 'tuner' }
}

Config.BlacklistedVehicles = {
    'police', 'police2', 'police3', 'ambulance', 'firetruk', 'fbi', 'fbi2', 'riot', 'pbus', 'bmx', 'scorcher'
}

Config.TunerShops = {
    ['LosSantosCustoms'] = {
        Job = 'tuner',
        DutyMarker = vec3(762.14691162109,-1226.0695800781,24.930212020874),
        CraftingStash = vec3(759.29162597656,-1232.2034912109,24.988891601562),
        DeliveryPoint = vec3(746.94805908203,-1215.1169433594,24.661222457886),
        TuningZones = {
            vec3(765.04656982422,-1222.7725830078,24.204795837402)
        },
        DynoZone = {
            Coords = vec3(761.43615722656,-1209.9077148438,23.530738830566),
            Heading = 3.0
        }
    },
}