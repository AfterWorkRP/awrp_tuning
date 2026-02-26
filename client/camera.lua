-- ==========================================
-- SYSTEM KAMERY WARSZTATOWEJ
-- ==========================================

local cam = nil

--- Tworzy i ustawia kamerę na konkretnej strefie pojazdu
--- @param vehicle number Entity pojazdu
--- @param zone string Nazwa strefy (engine, rear, wheels, body)
local function CreateTuningCamera(vehicle, zone)
    -- Jeśli kamera już istnieje, usuwamy ją przed stworzeniem nowej
    if cam and DoesCamExist(cam) then
        DestroyCam(cam, false)
    end

    -- Tworzymy nową kamerę
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local offset = vector3(0.0, 0.0, 0.0)

    -- Ustawiamy pozycję kamery w zależności od edytowanej strefy
    if zone == 'engine' then
        -- Kamera z przodu, lekko z góry, patrząca na maskę
        offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 3.5, 1.0)
    elseif zone == 'rear' then
        -- Kamera z tyłu, patrząca na wydech/spoiler
        offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.5, 0.8)
    elseif zone == 'wheels' then
        -- Kamera z boku, skupiona na przednim kole
        offset = GetOffsetFromEntityInWorldCoords(vehicle, -2.5, 1.0, 0.3)
    elseif zone == 'body' then
        -- Kamera szeroka z boku auta (do lakieru, progów)
        offset = GetOffsetFromEntityInWorldCoords(vehicle, -3.5, 0.0, 1.0)
    else
        -- Domyślna kamera z boku
        offset = GetOffsetFromEntityInWorldCoords(vehicle, -3.5, 0.0, 1.0)
    end

    -- Ustawiamy pozycję kamery
    SetCamCoord(cam, offset.x, offset.y, offset.z)
    
    -- Kamera zawsze patrzy prosto na pojazd
    PointCamAtEntity(cam, vehicle, 0.0, 0.0, 0.0, true)
    
    -- Płynne przejście kamery (RenderScriptCams(render, ease, easeTime, p3, p4))
    RenderScriptCams(true, true, 1000, true, true)
end

--- Resetuje kamerę do standardowego widoku zza pleców gracza
local function DestroyTuningCamera()
    if cam and DoesCamExist(cam) then
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
end

-- ==========================================
-- EVENTY DO OBSŁUGI Z ZEWNĄTRZ
-- ==========================================

RegisterNetEvent('awrp_tuning:setCamera', function(vehicle, zone)
    CreateTuningCamera(vehicle, zone)
end)

RegisterNetEvent('awrp_tuning:clearCamera', function()
    DestroyTuningCamera()
end)

-- Podpięcie pod zamykanie menu ox_lib (gdy gracz wciśnie ESC)
AddEventHandler('ox_lib:menuClosed', function()
    -- Upewniamy się, że po wyjściu z jakiegokolwiek menu tuningu kamera wraca do normy
    DestroyTuningCamera()
end)