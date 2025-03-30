--- FRAMEWORK SECTION

--- INVENTORY SECTION
if Config.Inventory == 'ox_inventory' then
    function HasItem(item, amount)
        local count = exports.ox_inventory:GetItemCount(item)
        amount = amount or 0
        return count and count > 0
    end

    function GetCount(item)
        local count = exports.ox_inventory:GetItemCount(item)
        return count and count
    end
elseif Config.Inventory == 'qb-inventory' or Config.Inventory == 'ps-inventory' or Config.Inventory == 'lj-inventory' then
    local QBCore = exports['qb-core']:GetCoreObject()

    function HasItem(item, amount)
        return exports[Config.Inventory]:HasItem(item, amount)
    end

    function GetCount(item)
        local playerData = QBCore.Functions.GetPlayerData()
        local count = 0
        if not playerData.items then return 0 end
        for _, data in pairs(playerData.items) do
            if data.name:lower() == item:lower() then
                count = count + 1
            end
        end
        return count
    end
end

--- TARGET SECTION
function AddVehicleTarget(option)
    if Config.Target == 'ox_target' then
        return exports.ox_target:addGlobalVehicle({option})
    elseif Config.Target == 'qb-target' then
        option.action = function(entity)
            option.onSelect({ entity = entity })
        end
        return exports['qb-target']:AddTargetBone({ 'seat_dside_r1', 'seat_pside_r1', 'platelight' }, {
            options = {option},
            distance = 1.6,
        })
    elseif Config.Target == 'sleepless_interact' then
        return exports.sleepless_interact:addGlobalVehicle({
            label = option.label,
            name = option.name,
            icon = option.icon,
            onSelect = function(data)
                option.onSelect(data)
            end
        })
    end
end

function AddTrashTargets(models, option)
    if Config.Target == 'ox_target' then
        return exports.ox_target:addModel(models, {option})
    elseif Config.Target == 'qb-target' then
        option.action = function(entity)
            option.onSelect({ entity = entity })
        end
        return exports['qb-target']:AddTargetModel(models, {
            options = {option},
            distance = 1.6,
        })
    elseif Config.Target == 'sleepless_interact' then
        return exports.sleepless_interact:addModel(models, {
            label = option.label,
            name = option.name,
            icon = option.icon,
            onSelect = function(data)
               option.onSelect(data)
            end
        })
    end
end

RegisterNetEvent('sanitation:client:setFuel', function(netId, plate)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if GetResourceState('LegacyFuel') == 'started' then
        exports.LegacyFuel:SetFuel(entity, 100.0)
    elseif GetResourceState('cdn-fuel') == 'started' then
        exports['cdn-fuel']:SetFuel(entity, 100.0)
    elseif GetResourceState('qb-fuel') == 'started' then
        exports['qb-fuel']:SetFuel(entity, 100.0)
    elseif GetResourceState('ps-fuel') == 'started' then
        exports['ps-fuel']:SetFuel(entity, 100.0)
    end
end)
