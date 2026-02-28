local ESX = exports["es_extended"]:getSharedObject()

local function CanOrderParts()
    local playerData = ESX.GetPlayerData()
    if not playerData.job then return false end

    for _, allowedGrade in ipairs(Config.Tablet.AllowedGrades) do
        if playerData.job.grade_name == allowedGrade then
            return true
        end
    end
    return false
end

RegisterNetEvent('awrp_tuning:openTablet', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local options = {}

    table.insert(options, {
        title = _L('tablet_dyno'),
        description = _L('tablet_dyno_desc'),
        icon = 'laptop-medical',
        onSelect = function()
            local closestVehicle, closestDistance = ESX.Game.GetClosestVehicle(coords)
            if closestVehicle ~= -1 and closestDistance <= 5.0 then
                TriggerEvent('awrp_tuning:runDynoTest', closestVehicle)
            else
                lib.notify({ title = _L('error_title'), description = _L('no_veh_nearby'), type = 'error' })
            end
        end
    })

    table.insert(options, {
        title = _L('tablet_calc'),
        description = _L('tablet_calc_desc'),
        icon = 'calculator',
        onSelect = function()
            local input = lib.inputDialog(_L('tablet_calc'), {
                { type = 'number', label = _L('calc_parts_cost'), required = true, min = 1 },
                { type = 'select', label = _L('calc_difficulty'), required = true, options = {
                    { value = 1.0, label = _L('calc_easy', Config.Tablet.LaborMargin.Min) },
                    { value = 1.5, label = _L('calc_medium') },
                    { value = 2.5, label = _L('calc_hard') },
                    { value = 4.0, label = _L('calc_expert', Config.Tablet.LaborMargin.Max) }
                }},
                { type = 'number', label = _L('calc_amount'), required = true, min = 1, default = 1 }
            })

            if input then
                local partsCost = input[1]
                local diffMultiplier = input[2]
                local partsCount = input[3]

                local baseLabor = Config.Tablet.LaborMargin.Min * diffMultiplier * partsCount
                if baseLabor > Config.Tablet.LaborMargin.Max then baseLabor = Config.Tablet.LaborMargin.Max end

                local finalPrice = partsCost + baseLabor

                lib.alertDialog({
                    header = _L('calc_result'),
                    content = _L('calc_summary', partsCost, math.floor(baseLabor), math.floor(finalPrice)),
                    centered = true,
                    cancel = false
                })
            end
        end
    })

    if CanOrderParts() then
        table.insert(options, {
            title = _L('tablet_orders'),
            description = _L('tablet_orders_desc'),
            icon = 'boxes-stacked',
            onSelect = function()
                local input = lib.inputDialog(_L('order_title'), {
                    { type = 'input', label = _L('order_name'), required = true },
                    { type = 'number', label = _L('order_amount'), required = true, min = 1, max = 50 }
                })

                if input then
                    TriggerServerEvent('awrp_tuning:placeWholesaleOrder', input[1], input[2])
                    lib.notify({
                        title = _L('order_sent'),
                        description = _L('order_sent_desc', input[2], input[1]),
                        type = 'success'
                    })
                end
            end
        })
    end

    lib.registerContext({
        id = 'tuner_tablet_menu',
        title = _L('tablet_title'),
        options = options,
        onExit = function() ClearPedTasks(PlayerPedId()) end
    })

    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
    lib.showContext('tuner_tablet_menu')
end)

RegisterNetEvent('awrp_tuning:checkAndOpenTablet', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TriggerEvent('awrp_tuning:openTabletMenu')
    else
        TriggerEvent('awrp_tuning:openTablet')
    end
end)