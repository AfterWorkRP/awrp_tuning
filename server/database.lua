local ESX = exports["es_extended"]:getSharedObject()

local allowedKeys = {
    ['engine'] = true, ['stance'] = true, ['drift_tires'] = true, 
    ['bulletproof_tires'] = true, ['rgb_primary'] = true, 
    ['xenon_enabled'] = true, ['xenon_color'] = true, ['xenon_custom'] = true, 
    ['neon_enabled'] = true, ['neon_color'] = true
}

-- Funkcja globalna dla utils/exports
function AWRPUtils.GetVehicleCustomTuning(plate)
    local formattedPlate = AWRPUtils.Trim(plate)
    local result = MySQL.query.await('SELECT awrp_tuning FROM `owned_vehicles` WHERE `plate` = ?', {
        formattedPlate
    })

    if result and result[1] and result[1].awrp_tuning then
        return json.decode(result[1].awrp_tuning)
    end
    return {}
end

local function SaveVehicleCustomTuning(plate, key, value)
    local formattedPlate = AWRPUtils.Trim(plate)
    local jsonPath = '$."' .. key .. '"'
    local jsonValue = type(value) == 'table' and json.encode(value) or json.encode(value)

    MySQL.query.await('UPDATE `owned_vehicles` SET `awrp_tuning` = JSON_SET(COALESCE(`awrp_tuning`, "{}"), ?, CAST(? AS JSON)) WHERE `plate` = ?', {
        jsonPath, jsonValue, formattedPlate
    })
end

ESX.RegisterServerCallback('awrp_tuning:getTuningData', function(source, cb, plate)
    cb(AWRPUtils.GetVehicleCustomTuning(plate))
end)

RegisterNetEvent('awrp_tuning:saveTuningData', function(plate, key, value)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    if not AWRPUtils.IsMechanicJob(xPlayer.job.name) then
        AWRPUtils.Log('Odrzucono zapis! ID ' .. src .. ' próbował wywołać modyfikację bez uprawnień!', 'error')
        return
    end
    
    if not allowedKeys[key] and not string.match(tostring(key), "^neon_side_%d+$") then
        AWRPUtils.Log('Odrzucono zapis! ID ' .. src .. ' nieprawidłowy klucz: ' .. tostring(key), 'error')
        return
    end
    
    SaveVehicleCustomTuning(plate, key, value)
end)