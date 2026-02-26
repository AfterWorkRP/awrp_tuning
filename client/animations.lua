-- ==========================================
-- ZMIENNE LOKALNE
-- ==========================================
local isAnimating = false
local currentProp = nil

-- ==========================================
-- FUNKCJE POMOCNICZE
-- ==========================================

--- Bezpieczne ładowanie słownika animacji
--- @param dict string Nazwa słownika
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

--- Bezpieczne ładowanie modelu (propa)
--- @param modelHash number Hash modelu
local function LoadPropModel(modelHash)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end
end

-- ==========================================
-- GŁÓWNE EVENTY ANIMACJI
-- ==========================================

RegisterNetEvent('awrp_tuning:startInstallAnimation', function()
    local ped = PlayerPedId()
    
    -- Zabezpieczenie przed nałożeniem się animacji
    if isAnimating then return end
    isAnimating = true

    -- Słownik i nazwa animacji (Klasyczne schylanie się i grzebanie mechanika)
    local animDict = "mini@repair"
    local animName = "fixing_a_ped"
    
    -- Hash modelu klucza francuskiego
    local propModel = `prop_tool_wrench`

    -- Ładujemy zasoby do pamięci gry
    LoadAnimDict(animDict)
    LoadPropModel(propModel)

    -- Tworzymy fizyczny obiekt klucza obok gracza
    local coords = GetEntityCoords(ped)
    currentProp = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)
    
    -- Znajdujemy kość prawej dłoni gracza (ID: 28422)
    local boneIndex = GetPedBoneIndex(ped, 28422)
    
    -- Przypinamy klucz do dłoni z odpowiednimi przesunięciami
    -- AttachEntityToEntity(obiekt, cel, kosc, xPos, yPos, zPos, xRot, yRot, zRot, ...)
    AttachEntityToEntity(currentProp, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Odpalamy zapętloną animację z flagą 1 (Loop)
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Zwalniamy zasoby z pamięci (GTA samo usunie je po zakończeniu)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(propModel)
end)

RegisterNetEvent('awrp_tuning:stopInstallAnimation', function()
    local ped = PlayerPedId()
    
    -- Zatrzymujemy animację
    ClearPedTasks(ped)
    
    -- Usuwamy fizyczny klucz, jeśli istnieje
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
    end
    
    -- Resetujemy zmienne
    currentProp = nil
    isAnimating = false
end)