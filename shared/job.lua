Config = Config or {}

Config.Job = {
    Vehicles = { -- what all vehicles are considered for trash pickup
        `trash`
    },
    VehicleRentingCost = 500, -- what would be the cost to rent a trash vehicle
    TrashModels = {           -- what all trash models are allowed to pick trash from
        `prop_dumpster_01a`, `prop_dumpster_02a`, `prop_dumpster_02b`, `prop_dumpster_3a`,
        `hw1_13_props_dump01alod`, `hw1_13_props_dump01alod1`, `hw1_13_props_dump01alod2`,
        `m23_2_prop_m32_dumpster_01a`, `prop_dumpster_4b`, `prop_bin_07c`, `prop_bin_08a`, `prop_bin_01b`
    },
    TrashPerJob = { min = 4, max = 15 },       -- how many trash bags to be given per assigned zone
    AddXPOnComplete = { min = 1, max = 3 },    -- how much xp to be given on job complete
    LoseXPOnDamage = { min = 1, max = 3 },     -- how much xp to be lost if damaged vehicle is returned
    PayPerTrashBag = { min = 100, max = 150 }, -- payment per trash bag collected
    PayPerMember = { min = 100, max = 150 },   -- this will be added per member incresed [ total = payment + (member x PayPerMember) ]
    PayPerXPLevel = {
        [1] = { min = 10, max = 15 },
        [2] = { min = 15, max = 20 },
        [3] = { min = 20, max = 25 }
    },
    RandomRewards = {
        { name = 'sandwich', amount = { min = 1, max = 2 }, metadata = false, chance = 10 }
    },
    Zones = { -- the trash zones where people will be assigned to pick up trash
        { coords = vec3(120.646, -1697.498, 29.139), color = 2, alpha = 155, radius = 250.0 }
    }
}
