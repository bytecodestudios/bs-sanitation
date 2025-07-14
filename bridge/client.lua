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

local blips = {}

local function removeBlip(self)
	if not self or not self.blipId then return end
	if DoesBlipExist(self.blipId) then RemoveBlip(self.blipId) end
	blips[self.id] = nil
end

function CreateCoordBlip(props)
    local _type = type(props)
    if _type ~= "table" then error(("expected type 'table' for the first argument, received (%s)"):format(_type)) end
    local id = #blips + 1
    local self = {} 
    local blip = AddBlipForCoord(props.coords.x + 0.0, props.coords.y + 0.0, props.coords.z + 0.0)
    if props.sprite then
        SetBlipSprite(blip, props.sprite or 1)
    end
    SetBlipScale(blip, props.scale or 0.6)
    SetBlipColour(blip, props.color or 0)
    SetBlipDisplay(blip, 2)
    SetBlipAsShortRange(blip, true)
    if props.name then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(props.name)
        EndTextCommandSetBlipName(blip)
    end
    if props.distance then
        self.distance = props.distance
    end
    self.id = id
    self.blipId = blip
    self.remove = function()
		removeBlip(self)
	end
    blips[id] = self
    return self
end

function CreateRadiusBlip(props)
    local _type = type(props)
    if _type ~= "table" then error(("expected type 'table' for the first argument, received (%s)"):format(_type)) end
    local id = #blips + 1
    local self = {} 
    local blip = AddBlipForRadius(props.coords.x + 0.0, props.coords.y + 0.0, props.coords.z + 0.0, props.radius)
    SetBlipColour(blip, props.color or 0)
    SetBlipAlpha(blip, props.alpha or 250)
    self.id = id
    self.blipId = blip
    self.remove = function()
		removeBlip(self)
	end
    blips[id] = self
    return self
end