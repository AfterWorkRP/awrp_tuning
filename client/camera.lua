local cam = nil
local isTuningCameraActive = false

local function CreateTuningCamera(vehicle, zone)
    if cam and DoesCamExist(cam) then DestroyCam(cam, false) end

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local offset = vector3(0.0, 0.0, 0.0)

    if zone == 'engine' then
        offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 3.5, 1.0)
    elseif zone == 'rear' then
        offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.5, 0.8)
    elseif zone == 'wheels' then
        offset = GetOffsetFromEntityInWorldCoords(vehicle, -2.5, 1.0, 0.3)
    else
        offset = GetOffsetFromEntityInWorldCoords(vehicle, -3.5, 0.0, 1.0)
    end

    SetCamCoord(cam, offset.x, offset.y, offset.z)
    PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    isTuningCameraActive = true
end

local function DestroyTuningCamera()
    if cam and DoesCamExist(cam) then
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(cam, false)
        cam = nil
        isTuningCameraActive = false
    end
end

RegisterNetEvent('awrp_tuning:setCamera', function(vehicle, zone)
    CreateTuningCamera(vehicle, zone)
end)

RegisterNetEvent('awrp_tuning:clearCamera', function()
    DestroyTuningCamera()
end)

AddEventHandler('ox_lib:menuClosed', function()
    -- Weryfikujemy flagę tak, by nie zepsuć innych interfejsów ox_lib
    if isTuningCameraActive then
        DestroyTuningCamera()
    end
end)