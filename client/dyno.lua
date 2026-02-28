local function CalculateVehiclePerformance(vehicle)
    local mass = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass')
    local driveForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
    local maxVelocity = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')

    if mass < 100.0 then mass = 1500.0 end
    if driveForce < 0.01 then driveForce = 0.1 end
    if maxVelocity < 10.0 then maxVelocity = 120.0 end

    local baseHp = (mass * driveForce * maxVelocity) / 100.0
    local baseTorque = (mass * driveForce) * 1.6

    local bonusHp = 0
    local bonusTorque = 0

    local engineMod = GetVehicleMod(vehicle, 11)
    if engineMod ~= -1 then
        bonusHp = bonusHp + ((engineMod + 1) * 25.0)
        bonusTorque = bonusTorque + ((engineMod + 1) * 30.0)
    end

    if IsToggleModOn(vehicle, 18) then
        bonusHp = bonusHp + 65.0
        bonusTorque = bonusTorque + 80.0
    end

    return math.floor(baseHp + bonusHp), math.floor(baseTorque + bonusTorque)
end

-- Zmiana na standardowy event zamiast NetEvent, aby nie dało się go wywołać z zewnątrz
AddEventHandler('awrp_tuning:runDynoTest', function(vehicle)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)

    if lib.progressBar({
        duration = 5000,
        label = _L('loading'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true }
    }) then
        ClearPedTasks(ped)
        local hp, torque = CalculateVehiclePerformance(vehicle)

        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'showDyno', hp = hp, torque = torque })
        
        -- Fallback loop dla ESC, aby gracz nie zablokował sobie gry
        CreateThread(function()
            local isFocused = true
            while isFocused do
                if IsControlJustPressed(0, 200) then -- ESC
                    SetNuiFocus(false, false)
                    SendNUIMessage({ type = 'hideDyno' })
                    isFocused = false
                end
                Wait(0)
            end
        end)
    else
        ClearPedTasks(ped)
        lib.notify({ title = _L('cancel'), description = _L('error'), type = 'warning' })
    end
end)

RegisterNUICallback('closeDyno', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)