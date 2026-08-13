local QBCore = exports['qb-core']:GetCoreObject()

local isOpen = false
local propOne, propTwo = nil, nil

local animDict = "missheistdockssetup1clipboard@base"
local animName = "base"

local modelOne = `prop_notepad_01`
local boneOne = 18905
local placementOne = vector3(0.1, 0.02, 0.05)
local rotationOne = vector3(10.0, 0.0, 0.0)

local modelTwo = `prop_pencil_01`
local boneTwo = 58866
local placementTwo = vector3(0.11, -0.02, 0.001)
local rotationTwo = vector3(-120.0, 0.0, 0.0)

-- ---------------------------------------------------------------------------
-- Prop / animation handling (unchanged behaviour from the original script)
-- ---------------------------------------------------------------------------

local function attachProps()
    if not Config.UseProp then return end

    local playerPed = PlayerPedId()

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end

    RequestModel(modelOne)
    while not HasModelLoaded(modelOne) do Wait(0) end

    RequestModel(modelTwo)
    while not HasModelLoaded(modelTwo) do Wait(0) end

    propOne = CreateObject(modelOne, 0.0, 0.0, 0.0, true, true, false)
    propTwo = CreateObject(modelTwo, 0.0, 0.0, 0.0, true, true, false)

    local boneIndexOne = GetPedBoneIndex(playerPed, boneOne)
    local boneIndexTwo = GetPedBoneIndex(playerPed, boneTwo)

    SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)

    AttachEntityToEntity(propOne, playerPed, boneIndexOne, placementOne.x, placementOne.y, placementOne.z, rotationOne.x, rotationOne.y, rotationOne.z, true, false, false, false, 2, true)
    AttachEntityToEntity(propTwo, playerPed, boneIndexTwo, placementTwo.x, placementTwo.y, placementTwo.z, rotationTwo.x, rotationTwo.y, rotationTwo.z, true, false, false, false, 2, true)

    SetModelAsNoLongerNeeded(modelOne)
    SetModelAsNoLongerNeeded(modelTwo)

    TaskPlayAnim(playerPed, animDict, animName, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
end

local function detachProps()
    if not Config.UseProp then return end

    local playerPed = PlayerPedId()
    StopAnimTask(playerPed, animDict, animName, 1.0)

    if propOne then DeleteEntity(propOne) propOne = nil end
    if propTwo then DeleteEntity(propTwo) propTwo = nil end
end

-- ---------------------------------------------------------------------------
-- Server bridge helpers
-- ---------------------------------------------------------------------------

local function fetchNotes(cb)
    QBCore.Functions.TriggerCallback('ab_note:server:getNotesList', function(notes)
        cb(notes or {})
    end)
end

-- ---------------------------------------------------------------------------
-- Open / close
-- ---------------------------------------------------------------------------

function OpenNotebook()
    if isOpen then return end

    if Config.BlockInVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
        QBCore.Functions.Notify('You cannot do that in a vehicle', 'error')
        return
    end

    isOpen = true
    attachProps()

    fetchNotes(function(notes)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            notes = notes,
            config = {
                maxTitle = Config.MaxTitleLength,
                maxContent = Config.MaxContentLength,
                maxNotes = Config.MaxNotes
            }
        })
    end)
end

function CloseNotebook()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    detachProps()
end

-- ---------------------------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------------------------

RegisterNUICallback('close', function(_, cb)
    CloseNotebook()
    cb('ok')
end)

RegisterNUICallback('getNotes', function(_, cb)
    fetchNotes(function(notes) cb(notes) end)
end)

RegisterNUICallback('saveNote', function(data, cb)
    local noteId = data.id
    local title = tostring(data.title or '')
    local content = tostring(data.content or '')

    if title == '' or content == '' then
        cb({ success = false, message = 'Title and content are required' })
        return
    end

    QBCore.Functions.TriggerCallback('ab_note:server:saveNote', function(result)
        cb(result)
    end, noteId, title, content)
end)

RegisterNUICallback('deleteNote', function(data, cb)
    QBCore.Functions.TriggerCallback('ab_note:server:deleteNote', function(result)
        cb(result)
    end, data.id)
end)

-- ---------------------------------------------------------------------------
-- Commands / keybinds
-- ---------------------------------------------------------------------------

RegisterCommand(Config.Command, function()
    OpenNotebook()
end, false)

CreateThread(function()
    Wait(1000)
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, Config.CommandDescription)
end)

if Config.Keybind.enabled then
    RegisterKeyMapping(Config.Command, Config.Keybind.description, 'keyboard', Config.Keybind.key)
end

-- Kept for compatibility: server can still ask an open notebook to refresh
-- (e.g. if a note was deleted through another means).
RegisterNetEvent('ab_note:client:refreshMenu', function()
    if isOpen then
        fetchNotes(function(notes)
            SendNUIMessage({ action = 'refresh', notes = notes })
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if isOpen then CloseNotebook() end
end)
