local ConfigJob = lib.table.deepclone(Config.Job)
local ConfigParty = lib.table.deepclone(Config.Party)

local jobData = {}
local pickedTrash = nil

local function notify(msg, type)
    lib.notify({ description = msg, type = type })
end

local function getTrashesInArea(coords, radius)
    local objects = GetGamePool('CObject')
    local count = 0

    for i = 1, #objects do
        local object = objects[i]
        local objectCoords = GetEntityCoords(object)
        local distance = #(coords - objectCoords)

        if distance < radius then
            if lib.table.contains(ConfigJob.TrashModels, GetEntityModel(object)) then
                count += 1
            end
        end
    end

    return count
end

local function jobhandler()
    local self = {}
    self.party = function()
        return LocalPlayer.state.partyData
    end
    self.inparty = function()
        if self.party() then
            return self.party()?.inParty
        end
        return false
    end
    self.hasjob = function()
        return (self.party()?.currentJob == ConfigParty.jobName) and jobData?.status
    end
    self.inzone = function()
        return jobData?.inzone or false
    end
    self.istrashveh = function(entity)
        return lib.table.contains(ConfigJob.Vehicles, GetEntityModel(entity))
    end
    self.istrashpicked = function(entity)
        local coords = GetEntityCoords(entity)
        if jobData.trashes then
            for _, _coords in pairs(jobData.trashes) do
                if _coords and (#(_coords - coords) < 2.0) then
                    return true
                end
            end
        end
        return false
    end
    self.reachedmaxlimit = function()
        return jobData.trashescollected >= jobData.maxtrashes
    end
    self.checkinzone = function()
        local coords = GetEntityCoords(cache.ped)
        return jobData.zone and (#(jobData.zone.coords - coords) < jobData.zone.radius)
    end
    self.allpickedinzone = function()
        if not jobData.zone then return false end
        local trashes = getTrashesInArea(jobData.zone.coords, jobData.zone.radius)
        return (jobData.trashes and (#jobData.trashes >= trashes)) or false
    end
    return self
end

lib.onCache('vehicle', function(entity)
    if not entity then return end

    local handler = jobhandler()
    if handler.inparty() and handler.hasjob() and not handler.inzone() and handler.istrashveh(entity) then
        TriggerServerEvent('sanitation:server:reportStatus', { status = 'takenvehicle' })
    end
end)

RegisterNetEvent('sanitation:client:reportStatus', function(data)
    if data?.status == 'updatetrashes' then
        jobData.trashes = data.trashes
        jobData.trashescollected = data.trashescollected
    end
    if data?.status == 'completed' and jobData?.blip then
        jobData.blip.remove()
    end
end)

RegisterNetEvent('sanitation:client:toggleJob', function(job)
    if job?.status then
        local repeating = jobData.inzone
        jobData.status = job.status
        jobData.blip = CreateRadiusBlip(job.zone)
        jobData.zone = job.zone
        jobData.inzone = job.inZone
        jobData.trashes = job.trashes
        jobData.trashescollected = job.trashescollected
        jobData.maxtrashes = job.maxtrashes
        if repeating then return end
        local handler = jobhandler()
        CreateThread(function()
            while handler.hasjob() and not handler.checkinzone() do Wait(2000) end
            jobData.inzone = true
            TriggerServerEvent('sanitation:server:reportStatus', { status = 'inzone' })
            while handler.hasjob() do
                Wait(20000)
                if handler.inzone() and handler.allpickedinzone() and not handler.reachedmaxlimit() then
                    SetTimeout(math.random(500, 2000), function()
                        TriggerServerEvent('sanitaion:server:assignNewZone')
                    end)
                end
            end
        end)
    else
        if jobData.blip then jobData.blip:remove() end
        jobData = {}
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for name in pairs(ConfigParty.jobZones) do
       exports['cad-pedspawner']:DeletePed('sanitation_' .. name)
    end
    if pickedTrash and DoesEntityExist(pickedTrash) then
        DeleteEntity(pickedTrash)
        pickedTrash = nil
    end
    if jobData?.blip then
        TriggerServerEvent('sanitation:server:terminateJob')
        jobData.blip:remove()
        jobData = {}
    end
end)

CreateThread(function()
    for name, data in pairs(ConfigParty.jobZones) do
        exports['cad-pedspawner']:AddPed('sanitation_' .. name, {
            model = data.model,
            coords = data.coords,
            type = data.type,
            distance = data.distance or 20.0,
            animation = data.animation,
            states = data.states,
            target = {
                {
                    label = 'Request Work',
                    icon = 'fa-solid fa-briefcase',
                    distance = 1.6,
                    canInteract = function()
                        local handler = jobhandler()
                        return not handler.hasjob()
                    end,
                    onSelect = function()
                        TriggerServerEvent('sanitation:server:requestJob')
                    end
                },
                {
                    label = 'Rent Vehicle',
                    icon = 'fa-solid fa-truck-moving',
                    distance = 1.6,
                    canInteract = function()
                        local handler = jobhandler()
                        return handler.hasjob()
                    end,
                    onSelect = function()
                        TriggerServerEvent('sanitation:server:rentVehicle')
                    end
                },
                {
                    label = 'Return Vehicle',
                    icon = 'fa-solid fa-rotate-right',
                    distance = 1.6,
                    canInteract = function()
                        local handler = jobhandler()
                        return handler.hasjob()
                    end,
                    onSelect = function()
                        TriggerServerEvent('sanitation:server:returnVehicle')
                    end
                },
                {
                    label = 'Collect Payment & End Work',
                    icon = 'fa-solid fa-file-invoice',
                    distance = 1.6,
                    canInteract = function()
                        local handler = jobhandler()
                        return handler.hasjob()
                    end,
                    onSelect = function()
                        TriggerServerEvent('sanitation:server:collectPayment')
                    end
                }
            }
        })
    end
    for _, data in pairs(ConfigParty.jobBlips) do
        CreateCoordBlip({
            name = data.name,
            coords = data.coords,
            sprite = data.sprite,
            scale = data.scale,
            color = data.color
        })
    end

    local function collectTrash(self)
        Wait(math.random(100, 800))
        if lib.progressBar({
                duration = math.random(7000, 9000),
                label = 'Throwing the trash into the truck',
                useWhileDead = false,
                canCancel = true,
                anim = { dict = 'creatures@rottweiler@tricks@', clip = 'petting_franklin' },
                disable = { move = true, car = true }
            }) then
            if pickedTrash and DoesEntityExist(pickedTrash) then
                DeleteEntity(pickedTrash)
                pickedTrash = nil
                TriggerServerEvent('sanitation:server:collectTrash')
            end
        end
    end
    AddVehicleTarget({
        name = 'sanitation:trashtruck',
        label = 'Throw trash',
        icon = 'fas fa-trash-arrow-up',
        bones = { 'seat_dside_r1', 'seat_pside_r1', 'platelight' },
        distance = 1.6,
        canInteract = function(entity)
            local handler = jobhandler()
            return handler.hasjob() and handler.inzone() and handler.istrashveh(entity) and
            (GetVehicleDoorAngleRatio(entity, 5) > 0.0) and (pickedTrash ~= nil) and not lib.progressActive()
        end,
        onSelect = collectTrash
    })

    local function pickupTrash(self)
        if lib.progressBar({
                duration = math.random(9000, 10000),
                label = 'Collecting trash from bin...',
                useWhileDead = false,
                canCancel = true,
                anim = { scenario = 'PROP_HUMAN_BUM_BIN' },
                disable = { move = true, car = true }
            }) then
            if pickedTrash and DoesEntityExist(pickedTrash) then
                notify('You are already carrying trash', 'error')
                return
            end
            local handler = jobhandler()
            if handler.reachedmaxlimit() or handler.istrashpicked(self.entity) then
                notify('Trash bin is empty', 'success')
                return
            end
            pickedTrash = CreateObject(`hei_prop_heist_binbag`, 0, 0, 0, true, true, true)
            AttachEntityToEntity(pickedTrash, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.15, 0, 0, 0, 270.0, 60.0,
                true, true, false, true, 1, true)
            TriggerServerEvent('sanitation:server:pickupTrash', {
                coords = GetEntityCoords(self.entity)
            })
        end
    end
    AddTrashTargets(ConfigJob.TrashModels, {
        name = 'sanitation:trashmodels',
        label = 'Pickup Trash',
        icon = 'fa-solid fa-trash',
        distance = 1.6,
        canInteract = function(entity)
            local handler = jobhandler()
            return handler.hasjob() and handler.inzone() and not handler.istrashpicked(entity) and
            not lib.progressActive()
        end,
        onSelect = pickupTrash
    })
end)
