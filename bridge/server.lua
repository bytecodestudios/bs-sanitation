--- FRAMEWORK SECTION
if Config.Framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()

    function GetSource(citizenid)
        local xPlayer = ESX.GetPlayerFromIdentifier(citizenid)
        return xPlayer.source
    end

    function GetIdentifer(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.identifier
    end

    function AddMoney(source, amount, reason)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.addAccountMoney('bank', amount, reason)
            return true
        end
        return false
    end

    function RemoveMoney(source, amount, reason)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.removeAccountMoney('bank', amount, reason)
            return true
        end
        return false
    end
elseif Config.Framework == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()

    function GetSource(citizenid)
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        return Player.PlayerData.source
    end

    function GetIdentifer(source)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.PlayerData.citizenid
    end

    function AddMoney(source, amount, reason)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.Functions.AddMoney('cash', amount, reason)
    end

    function RemoveMoney(source, amount, reason)
        local Player = QBCore.Functions.GetPlayer(source)
        return Player.Functions.RemoveMoney('bank', amount, reason)
    end
elseif Config.Framework == 'qbox' then
    function GetSource(citizenid)
        local Player = exports.qbx_core:GetPlayerByCitizenId(citizenid)
        return Player.PlayerData.source
    end

    function GetIdentifer(source)
        local Player = exports.qbx_core:GetPlayer(source)
        return Player.PlayerData.citizenid
    end

    function AddMoney(source, amount, reason)
        local Player = exports.qbx_core:GetPlayer(source)
        return Player.Functions.AddMoney('cash', amount, reason)
    end

    function RemoveMoney(source, amount, reason)
        local Player = exports.qbx_core:GetPlayer(source)
        return Player.Functions.RemoveMoney('bank', amount, reason)
    end
end

--- INVENTORY SECTION
if Config.Inventory == 'ox_inventory' then
    function GetCount(src, item)
        local count = exports.ox_inventory:GetItemCount(src, item)
        return count and count
    end

    function AddItem(src, item, amount, metadata)
        return exports.ox_inventory:AddItem(src, item, amount, metadata)
    end

    function RemoveItem(src, item, amount)
        return exports.ox_inventory:RemoveItem(src, item, amount)
    end
elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' or Config.Inventory == 'lj-inventory' then
    function GetCount(src, item)
        local items = exports[Config.Inventory]:GetItemsByName(src, item)
        return items and #items
    end

    function AddItem(src, item, amount, metadata)
        return exports[Config.Inventory]:AddItem(src, item, amount, false, metadata)
    end

    function RemoveItem(src, item, amount)
        return exports[Config.Inventory]:RemoveItem(src, item, amount)
    end
end

--- XP SECTION
function GetSanitationXP(citizenid)
    if GetResourceState('bc_jobxpmanager') == 'started' then
        local data = exports.bc_jobxpmanager:GetJobData(citizenid, 'sanitation')
        return data and (data.level or 1)
    end
    return 1
end

function AddSanitationXP(citizenid, amount)
    if GetResourceState('bc_jobxpmanager') == 'started' then
        return exports.bc_jobxpmanager:AddJobXP(citizenid, 'sanitation', amount)
    end
    return true
end

function RemoveSanitationXP(citizenid, amount)
    if GetResourceState('bc_jobxpmanager') == 'started' then
        return exports.bc_jobxpmanager:RemoveJobXP(citizenid, 'sanitation', amount)
    end
    return true
end

--- UTILS SECTION
function SetVehicleFuel(playerId, vehNetId, plate)
    TriggerClientEvent('sanitation:client:setFuel', playerId, vehNetId, plate)
end

function AddVehicleKeys(playerId, vehNetId, plate)
    if GetResourceState('Renewed-Vehiclekeys') == 'started' then
        exports['Renewed-Vehiclekeys']:addKey(playerId, plate)
    elseif GetResourceState('qb-vehiclekeys') == 'started' then
        exports['qb-vehiclekeys']:GiveKeys(playerId, plate)
    elseif GetResourceState('qbx_vehiclekeys') == 'started' then
        exports.qbx_vehiclekeys:GiveKeys(playerId, plate)
    elseif GetResourceState('qs-vehiclekeys') == 'started' then
        local model = GetEntityModel(NetworkGetEntityFromNetworkId(vehNetId))
        exports['qs-vehiclekeys']:GiveServerKeys(playerId, plate, model, false)
    end
end

function Logger(player, category, message)
    lib.logger(player, category, type(message) == 'table' and json.encode(message) or message)
end
