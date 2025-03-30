Config = Config or {}

Config.Party = {
	minSize = 1,                       -- min members required to start the job
	maxSize = 4,                       -- max members you can have to start the job
	jobName = 'Sanitation',            -- job name
	jobIcon = 'fas fa-trash',          -- icon to show when this job is assigned
	jobType = 'legal',                 -- Job type: 'legal' , 'illegal'
	jobSize = 5,                       -- Max parties for this job
	jobAssignTime = { min = 1, max = 5 }, -- (secs) Time that takes to assign a job
	jobBlips = {
		{ name = 'Sanitation', coords = vector3(873.542, -2197.565, 30.519), sprite = 318, color = 25, scale = 0.8 }
	},
	jobZones = {
		['employeer'] = {
			model = `s_m_y_garbage`,
			coords = vector4(873.453, -2200.309, 30.519, 358.208),
			type = 'male',
			distance = 30.0,
			animation = { scenario = 'WORLD_HUMAN_CLIPBOARD' },
			states = { freeze = true, blockevents = true, invincible = true },
		},
	},
	jobSpawns = {
		vector4(879.578, -2191.921, 30.236, 355.881),
		vector4(878.874, -2177.128, 30.232, 176.077),
		vector4(869.979, -2188.148, 30.211, 85.393)
	}
}
