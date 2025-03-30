local ConfigJob = lib.table.deepclone(Config.Job)
local ConfigParty = lib.table.deepclone(Config.Party)
local pgroup = exports['snappy-phone']

local partyData = {}
local partyTasks = {}

local rentedVehicles = {}
local isVehicleSpawning = {}
local tempTrash = {}

pgroup:registerJob({
    name = ConfigParty.jobName,
    icon = ConfigParty.jobIcon,
    size = ConfigParty.jobSize,
    type = ConfigParty.jobType
})

local function notify(source, message, type)
    lib.notify(source, { description = message, type = type })
end

local function sendToPartyMembers(partyId, callback)
    local members = pgroup:getPartyMembers(partyId)
    for _, member in pairs(members) do
        local source = GetSource(member.citizenid)
        if source then callback(source, member.citizenid) end
    end
end

local function isPointOccupied(x, y, z, radius)
    local coords = vector3(x, y, z)
    local vehicles = GetAllVehicles()
    local closeVeh = {}
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if distance <= radius then
            closeVeh[#closeVeh + 1] = vehicles[i]
        end
    end
    if #closeVeh > 0 then return true end
    return false
end

local function getEmptySpawnPoint()
    for _, v in pairs(ConfigParty.jobSpawns) do
        if not isPointOccupied(v.x, v.y, v.z, 3) then
            return true, v
        end
    end
    return false, nil
end

local function getReward()
    local function _shuffle(t)
        for i = #t, 2, -1 do
            local j = math.random(1, i)
            t[i], t[j] = t[j], t[i]
        end
        return t
    end
    local rewards = _shuffle(ConfigJob.RandomRewards)
    local chance = math.random(1, 100)
    local cumulativeChance = 0

    for _, reward in ipairs(rewards) do
        cumulativeChance = cumulativeChance + reward.chance
        if chance <= cumulativeChance then
            ---@diagnostic disable-next-line: undefined-field
            local amount = math.random(reward.amount.min, reward.amount.max)
            reward.amount = amount
            return reward
        end
    end

    return nil
end

local function returnVehicle(source)
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then
        notify(source, 'You are not party leader', 'error')
        return false
    end
    if rentedVehicles[partyId] then
        local veh = NetworkGetEntityFromNetworkId(rentedVehicles[partyId][2])
        if DoesEntityExist(veh) then
            local c1 = GetEntityCoords(GetPlayerPed(source))
            local c2 = GetEntityCoords(veh)
            if #(c1 - c2) > 100 then
                pgroup:sendPartyNotification(partyId, {
                    title = ConfigParty.jobName,
                    description = 'Vehicle is too far, please bring it close by.',
                    icon = ConfigParty.jobIcon,
                    duration = 10000
                })
                return false
            end
            local bodyDamage = 100 - (GetVehicleBodyHealth(veh) / 10)
            local engineDamage = 100 - (GetVehicleEngineHealth(veh) / 10)
            local damage = (bodyDamage + engineDamage) / 2
            local price = (rentedVehicles[partyId][1] * (1 - (damage / 100)))
            if damage > 80 then
                local xpToRemove = math.random(ConfigJob.LoseXPOnDamage.min, ConfigJob.LoseXPOnDamage.max)
                if RemoveMoney(math.abs(price), "Vehicle Damage Cost - Sanitation") then
                    sendToPartyMembers(partyId, function(playerId, citizenId)
                        if playerId then
                            RemoveSanitationXP(citizenId, xpToRemove)
                        end
                    end)
                    DeleteEntity(veh)
                    rentedVehicles[partyId] = nil
                    pgroup:sendPartyNotification(partyId, {
                        title = ConfigParty.jobName,
                        description = 'Vehicle has been returned.',
                        icon = ConfigParty.jobIcon,
                        duration = 10000
                    })
                    return true
                end
            else
                AddMoney(source, price, 'Return Rent - Sanitation')
                DeleteEntity(veh)
                rentedVehicles[partyId] = nil
                pgroup:sendPartyNotification(partyId, {
                    title = ConfigParty.jobName,
                    description = 'Vehicle has been returned.',
                    icon = ConfigParty.jobIcon,
                    duration = 10000
                })
                return true
            end
            return false
        else
            rentedVehicles[partyId] = nil
            return true
        end
    else
        notify(source, 'You have\'nt rented any vehicle', 'error')
        return true
    end
end

RegisterNetEvent('sanitation:server:returnVehicle', function()
    local source = source
    returnVehicle(source)
end)

RegisterNetEvent('sanitation:server:rentVehicle', function()
    local source = source
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then return end
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then
        notify(source, 'You are not party leader', 'error')
        return
    end
    if not partyData[partyId] then return end
    if isVehicleSpawning[source] then
        notify(source, 'Please stay close by to the truck spawn...', 'error')
        return
    end
    if rentedVehicles[partyId] then
        notify(source, 'You are not allowed to rent more vehicles', 'error')
        return
    end
    local clear, coords = getEmptySpawnPoint()
    if not clear or not coords then
        notify(source, 'Couldnot rent a vehicle, since there are vehicles on the way', 'error')
        return
    end
    local model = ConfigJob.Vehicles[math.random(1, #ConfigJob.Vehicles)]
    local price = ConfigJob.VehicleRentingCost
    local canPay = RemoveMoney(source, price, 'Vehicle Rent - Sanitation')
    if not canPay then
        notify(source, string.format('You need $%d to rent a vehicle', price), 'error')
        return
    end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, true)
    SetEntityHeading(veh, coords.w or 0.0)
    while not DoesEntityExist(veh) do Wait(0) end
    isVehicleSpawning[source] = true
    while NetworkGetEntityOwner(veh) ~= source do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local plate = GetVehicleNumberPlateText(veh)
    SetVehicleFuel(source, netId, plate)
    rentedVehicles[partyId] = { price, netId }
    sendToPartyMembers(partyId, function(playerId, citizenId)
        if playerId then
            AddVehicleKeys(playerId, netId, plate)
        end
    end)
    pgroup:sendPartyNotification(partyId, {
        title = ConfigParty.jobName,
        description = 'You rented a vehicle with plate: ' .. plate,
        icon = ConfigParty.jobIcon,
        duration = 15000
    })
    isVehicleSpawning[source] = nil
end)

RegisterNetEvent('sanitation:server:reportStatus', function(data)
    if not data.status then
        print(string.format('%s [%d] is possibly exploiting `reportStatus`', GetPlayerName(source), source))
        return
    end
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then return end
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then return end
    if data.status == 'takenvehicle' then
        partyTasks[partyId] = {
            { name = 'Rent a trash truck which can be used to dump trash',                                                       status = 'done' },
            { name = 'Go to the assigned zone to collect trash',                                                                 status = 'current' },
            { name = string.format('Collect trash %d/%d', partyData[partyId]?.trashescollected, partyData[partyId]?.maxtrashes), status = 'pending' },
            { name = 'Return to Sanitation HQ',                                                                                  status = 'pending' },
        }
        pgroup:updatePartyTasks(partyId, partyTasks[partyId])
    elseif data.status == 'inzone' then
        if partyData[partyId].inZone then return end
        partyTasks[partyId] = {
            { name = 'Rent a trash truck which can be used to dump trash',                                                       status = 'done' },
            { name = 'Go to the assigned zone to collect trash',                                                                 status = 'done' },
            { name = string.format('Collect trash %d/%d', partyData[partyId]?.trashescollected, partyData[partyId]?.maxtrashes), status = 'current' },
            { name = 'Return to Sanitation HQ',                                                                                  status = 'pending' },
        }
        partyData[partyId].inZone = true
        pgroup:updatePartyTasks(partyId, partyTasks[partyId])
    end
end)

RegisterNetEvent('sanitation:server:pickupTrash', function(trash)
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not trash.coords or not partyId then
        print(string.format('%s [%d] is possibly exploiting `collectTrash`', GetPlayerName(source), source))
        return
    end

    local coords = trash.coords
    local trashes = partyData[partyId]?.trashes or {}
    if #trashes > 0 then
        for _, _coords in pairs(trashes) do
            if _coords and (#(_coords - coords) < 2) then
                notify(source, 'This trash has already been picked', 'error')
                return
            end
        end
    end

    partyData[partyId].trashes[#trashes + 1] = coords
    if not tempTrash[partyId] then tempTrash[partyId] = 0 end
    tempTrash[partyId] += 1
    local reachedLimit = partyData[partyId].trashescollected >= partyData[partyId].maxtrashes
    sendToPartyMembers(partyId, function(playerId, citizenId)
        if playerId then
            if reachedLimit then
                TriggerClientEvent("sanitation:client:reportStatus", playerId, { status = 'completed' })
            else
                TriggerClientEvent("sanitation:client:reportStatus", playerId, {
                    status = 'updatetrashes',
                    trashes = partyData[partyId].trashes,
                    trashescollected = tempTrash[partyId]
                })
            end
        end
    end)
end)

RegisterNetEvent('sanitation:server:collectTrash', function()
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then
        print(string.format('%s [%d] is possibly exploiting `collectTrash`', GetPlayerName(source), source))
        return
    end
    partyData[partyId].trashescollected = tempTrash[partyId] or 0
    local reachedLimit = partyData[partyId].trashescollected >= partyData[partyId].maxtrashes
    if reachedLimit then
        sendToPartyMembers(partyId, function(playerId, citizenId)
            if playerId then
                TriggerClientEvent("sanitation:client:reportStatus", playerId, { status = 'completed' })
            end
        end)
    end
    partyTasks[partyId] = {
        { name = 'Rent a trash truck which can be used to dump trash',                                                       status = 'done' },
        { name = 'Go to the assigned zone to collect trash',                                                                 status = 'done' },
        { name = string.format('Collect trash %d/%d', partyData[partyId]?.trashescollected, partyData[partyId]?.maxtrashes), status = reachedLimit and 'done' or 'current' },
        { name = 'Return to Sanitation HQ',                                                                                  status = reachedLimit and 'current' or 'pending' },
    }
    pgroup:updatePartyTasks(partyId, partyTasks[partyId])
    local reward = getReward()
    if reward then AddItem(source, reward.name, reward.amount) end
end)

RegisterNetEvent('sanitaion:server:assignNewZone', function()
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then
        notify(source, 'You need to be in party to start work')
        return
    end
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then
        notify(source, 'You are not party leader')
        return
    end
    local zoneIndex = math.random(1, #ConfigJob.Zones)
    local zone = ConfigJob.Zones[zoneIndex]
    local maxtrashes = math.random(ConfigJob.TrashPerJob.min, ConfigJob.TrashPerJob.max)
    local min, max = ConfigParty.jobAssignTime.min * 1000, ConfigParty.jobAssignTime.max * 1000
    SetTimeout(math.random(min, max), function()
        partyData[partyId].status = true
        partyData[partyId].zoneIndex = zoneIndex
        partyData[partyId].zone = zone
        partyData[partyId].inZone = false
        partyData[partyId].trashes = {}

        partyTasks[partyId] = {
            { name = 'Rent a trash truck which can be used to dump trash', status = 'done' },
            { name = 'Go to the assigned zone to collect trash',           status = 'current' },
            { name = string.format('Collect trash %d/%d', 0, maxtrashes),  status = 'pending' },
            { name = 'Return to Sanitation HQ',                            status = 'pending' },
        }
        pgroup:updatePartyTasks(partyId, partyTasks[partyId])
        sendToPartyMembers(partyId, function(playerId, citizenId)
            if playerId and citizenId then
                TriggerClientEvent("sanitation:client:toggleJob", playerId, partyData[partyId])
            end
        end)
    end)
end)

RegisterNetEvent('sanitation:server:collectPayment', function()
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then
        notify(source, 'You need to be in party to start work', 'error')
        return
    end
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then
        notify(source, 'You are not party leader', 'error')
        return
    end
    if not partyData[partyId] then
        notify(source, 'You haven\'t worked to recieve payment', 'error')
        return
    end
    if partyData[partyId].collected then
        notify(source, 'You have already collected the payment', 'error')
        return
    end
    if partyData[partyId].trashescollected < ConfigJob.TrashPerJob.min then
        notify(source, 'You have\'nt worked enough to collect the payment', 'error')
        return
    end
    if not returnVehicle(source) then
        notify(source, 'You have\'nt worked enough to collect the payment', 'error')
        return
    end
    local partySize = pgroup:getPartySize(partyId)
    local payPerTrashBag = math.random(ConfigJob.PayPerTrashBag.min, ConfigJob.PayPerTrashBag.max)
    local payPerMember = partySize * math.random(ConfigJob.PayPerMember.min, ConfigJob.PayPerMember.max)
    local experiance = ConfigJob.PayPerXPLevel[GetSanitationXP(cid)]
    local payForXp = partySize * math.random(experiance.min, experiance.max)
    local payment = math.ceil(((payPerTrashBag * partyData[partyId].trashescollected) + payPerMember + payForXp) /
        partySize)
    local xpToAdd = math.random(ConfigJob.AddXPOnComplete.min, ConfigJob.AddXPOnComplete.max)
    sendToPartyMembers(partyId, function(playerId, citizenId)
        if playerId and citizenId then
            AddSanitationXP(citizenId, xpToAdd)
            AddMoney(playerId, payment, 'Payment - Sanitation')
        end
    end)
    partyData[partyId].collected = true
    pgroup:disbandParty(source, partyId, cid)
end)

RegisterNetEvent('sanitation:server:requestJob', function()
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then
        notify(source, 'You need a party in order to request work', 'error')
        return
    end
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then
        notify(source, 'Only party leaders can request for work', 'error')
        return
    end
    local partySize = pgroup:getPartySize(partyId)
    if partySize >= ConfigParty.minSize and partySize <= ConfigParty.maxSize then
        if pgroup:getPartyJob(partyId) == ConfigParty.jobName then
            notify(source, 'You have already signed up for work', 'error')
            return
        end
        local canSet = pgroup:setPartyJob(partyId, ConfigParty.jobName)
        if not canSet.status then
            notify(source, canSet.msg)
            return
        end
        partyTasks[partyId] = {
            { name = 'Wait for a job to be assigned', status = 'current' },
        }
        pgroup:updatePartyTasks(partyId, partyTasks[partyId])
        local zoneIndex = math.random(1, #ConfigJob.Zones)
        local zone = ConfigJob.Zones[zoneIndex]
        local maxtrashes = math.random(ConfigJob.TrashPerJob.min, ConfigJob.TrashPerJob.max)
        local min, max = ConfigParty.jobAssignTime.min * 1000, ConfigParty.jobAssignTime.max * 1000
        SetTimeout(math.random(min, max), function()
            partyData[partyId] = {
                status = true,
                zoneIndex = zoneIndex,
                zone = zone,
                inZone = false,
                trashes = {},
                trashescollected = 0,
                maxtrashes = maxtrashes
            }
            partyTasks[partyId] = {
                { name = 'Rent a trash truck which can be used to dump trash', status = 'current' },
                { name = 'Go to the assigned zone to collect trash',           status = 'pending' },
                { name = string.format('Collect trash %d/%d', 0, maxtrashes),  status = 'pending' },
                { name = 'Return to Sanitation HQ',                            status = 'pending' },
            }
            pgroup:updatePartyTasks(partyId, partyTasks[partyId])
            sendToPartyMembers(partyId, function(playerId, citizenId)
                if playerId and citizenId then
                    TriggerClientEvent("sanitation:client:toggleJob", playerId, partyData[partyId])
                    notify(playerId, 'You were assigned ' .. ConfigParty.jobName .. ' work.')
                end
            end)
        end)
    else
        notify(source, 'The employeer did not find the required no of members for work', 'error')
        return
    end
end)

RegisterNetEvent('sanitation:server:terminateJob', function()
    local cid = GetIdentifer(source)
    local partyId = pgroup:getPlayerPartyId(cid)
    if not partyId then return end
    local isLeader = pgroup:isPartyLeader(partyId, cid)
    if not isLeader then return end
    pgroup:disbandParty(source, partyId, cid)
end)

RegisterNetEvent('phone:server:disbandParty', function(source, partyId)
    if tempTrash[partyId] then tempTrash[partyId] = nil end
    if partyTasks[partyId] then partyTasks[partyId] = nil end
    if partyData[partyId] then partyData[partyId] = nil end
end)

RegisterNetEvent("phone:server:leftParty", function(source, data)
    if data.currentJob == ConfigParty.jobName then
        TriggerClientEvent("sanitation:client:toggleJob", source, { status = false })
        notify(source, 'You left ' .. ConfigParty.jobName .. ' work.')
    end
end)

RegisterNetEvent('phone:server:resumePendingJobs', function(source, data)
    if data.currentJob == ConfigParty.jobName then
        TriggerClientEvent("sanitation:client:toggleJob", source, partyData[data.partyId])
        notify(source, 'You continued ' .. ConfigParty.jobName .. ' work.')
    end
end)
