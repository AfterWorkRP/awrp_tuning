local isAnimating = false
local currentProp = nil

RegisterNetEvent('awrp_tuning:startInstallAnimation', function()
    local ped = PlayerPedId()
    if isAnimating then return end
    isAnimating = true

    local animDict = "mini@repair"
    local animName = "fixing_a_ped"
    local propModel = `prop_tool_wrench`

    -- ox_lib ma zabezpieczenie przed zacięciem
    lib.requestAnimDict(animDict, 1500)
    lib.requestModel(propModel, 1500)

    local coords = GetEntityCoords(ped)
    currentProp = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 28422)
    
    AttachEntityToEntity(currentProp, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(propModel)
end)

RegisterNetEvent('awrp_tuning:stopInstallAnimation', function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
    end
    
    currentProp = nil
    isAnimating = false
end)