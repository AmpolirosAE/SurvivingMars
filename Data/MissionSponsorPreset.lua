-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('MissionSponsorPreset', {
	Drone = 6,
	DroneHub = 1,
	Electronics = 10,
	ExplorerRover = 1,
	MachineParts = 15,
	MoistureVaporator = 1,
	OrbitalProbe = 4,
	Polymers = 15,
	RCRover = 1,
	RCTransport = 1,
	SortKey = 1000,
	StirlingGenerator = 2,
	additional_research_points = 200,
	cargo = 70000,
	display_name = T{7021, --[[MissionSponsorPreset Default IMM display_name]] "International Mars Mission"},
	effect = T{7022, --[[MissionSponsorPreset Default IMM effect]] "Difficulty: <em>Very Easy</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Large Rocket payload (<cargo> kg)\n- Colonists never get Earthsick\n- Food supply from Passenger Rockets increased (x10)\n- Rockets synthesize Fuel\n\n<em><flavor></em>"},
	flavor = T{7023, --[[MissionSponsorPreset Default IMM flavor]] "Recommended for first-time players"},
	funding = 30000,
	goal = "MG_TechResearch",
	goal_target = 40,
	id = "IMM",
	initial_rockets = 4,
	initial_techs_unlocked = 1,
	sponsor_nation_name1 = "American",
	sponsor_nation_name2 = "German",
	sponsor_nation_name3 = "Russian",
	sponsor_nation_name4 = "Chinese",
	sponsor_nation_name5 = "Indian",
	sponsor_nation_name6 = "Bulgarian",
	sponsor_nation_name7 = "Swedish",
	sponsor_nation_name8 = "French",
	sponsor_nation_percent1 = 20,
	sponsor_nation_percent2 = 5,
	sponsor_nation_percent3 = 5,
	sponsor_nation_percent4 = 20,
	sponsor_nation_percent5 = 20,
	sponsor_nation_percent6 = 5,
	sponsor_nation_percent7 = 5,
	sponsor_nation_percent8 = 5,
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = 100,
		Prop = "ApplicantsPoolStartingSize",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = 9000,
		Label = "Consts",
		Prop = "FoodPerRocketPassenger",
	}),
})

PlaceObj('MissionSponsorPreset', {
	DroneHub = 1,
	Electronics = 15,
	ExplorerRover = 1,
	FuelFactory = 1,
	MachineParts = 25,
	OrbitalProbe = 2,
	Polymers = 20,
	RCRover = 1,
	RCTransport = 1,
	SortKey = 2000,
	StirlingGenerator = 2,
	additional_research_points = 200,
	cargo = 70000,
	challenge_mod = 40,
	display_name = T{1223, --[[MissionSponsorPreset Default NASA display_name]] "USA"},
	effect = T{5483, --[[MissionSponsorPreset Default NASA effect]] "Difficulty: <em>Easy</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Large Rocket payload (<cargo> kg)\n- Periodic additional funding<flavor>"},
	funding = 8000,
	goal = "MG_Anomalies",
	goal_target = 30,
	group = "Default",
	id = "NASA",
	initial_rockets = 3,
	initial_techs_unlocked = 1,
	sponsor_nation_name1 = "American",
	sponsor_nation_name2 = "German",
	sponsor_nation_name3 = "English",
	sponsor_nation_percent1 = 90,
	sponsor_nation_percent2 = 5,
	sponsor_nation_percent3 = 5,
	PlaceObj('Effect_ModifyLabel', {
		Amount = 500,
		Label = "Consts",
		Prop = "SponsorFundingPerInterval",
	}),
})

PlaceObj('MissionSponsorPreset', {
	Drone = 6,
	DroneHub = 1,
	Electronics = 10,
	FuelFactory = 1,
	MachineParts = 20,
	OrbitalProbe = 8,
	Polymers = 10,
	RCTransport = 1,
	SortKey = 3000,
	applicants_price = 500000000,
	cargo = 50000,
	challenge_mod = 50,
	default_skin = "Facet",
	display_name = T{5484, --[[MissionSponsorPreset Default BlueSun display_name]] "Blue Sun Corporation"},
	effect = T{5485, --[[MissionSponsorPreset Default BlueSun effect]] "Difficulty: <em>Easy</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Can buy Applicants with funding\n- Additional Rockets are significantly cheaper\n- Probes can discover deep Rare Metal deposits\n- Bonus Tech: <em>Deep Metal Extraction</em> (can extract deep metals and deep rare metals deposits)"},
	funding = 10000,
	goal = "MG_RareExport",
	goal_target = 100,
	group = "Default",
	id = "BlueSun",
	initial_techs_unlocked = 1,
	rocket_price = 500000000,
	sponsor_nation_name1 = "American",
	sponsor_nation_name2 = "German",
	sponsor_nation_name3 = "Chinese",
	sponsor_nation_name4 = "French",
	sponsor_nation_percent1 = 40,
	sponsor_nation_percent2 = 20,
	sponsor_nation_percent3 = 20,
	sponsor_nation_percent4 = 20,
	PlaceObj('Effect_GrantTech', {
		Field = "Physics",
		Research = "DeepMetalExtraction",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = 5,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
})

PlaceObj('MissionSponsorPreset', {
	DroneHub = 1,
	Electronics = 10,
	MachineParts = 15,
	Metals = 5,
	OrbitalProbe = 2,
	Polymers = 15,
	RCRover = 1,
	RCTransport = 1,
	SortKey = 4000,
	StirlingGenerator = 1,
	additional_research_points = 100,
	cargo = 50000,
	challenge_mod = 60,
	default_skin = "Star",
	display_name = T{1227, --[[MissionSponsorPreset Default CNSA display_name]] "China"},
	effect = T{5486, --[[MissionSponsorPreset Default CNSA effect]] "Difficulty: <em>Easy</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Passenger Rockets carry 10 additional Colonists\n- Applicants are generated twice as fast"},
	funding = 8000,
	goal = "MG_Martianborn",
	goal_target = 80,
	group = "Default",
	id = "CNSA",
	initial_rockets = 3,
	initial_techs_unlocked = 1,
	sponsor_nation_name1 = "Chinese",
	sponsor_nation_percent1 = 100,
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -50,
		Prop = "ApplicantGenerationInterval",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = 100,
		Prop = "ApplicantsPoolStartingSize",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = 10,
		Label = "Consts",
		Prop = "MaxColonistsPerRocket",
	}),
})

PlaceObj('MissionSponsorPreset', {
	DroneHub = 2,
	Electronics = 10,
	MachineParts = 15,
	MoistureVaporator = 2,
	OrbitalProbe = 2,
	Polymers = 20,
	RCRover = 1,
	SortKey = 5000,
	cargo = 50000,
	challenge_mod = 90,
	default_skin = "Star",
	display_name = T{1231, --[[MissionSponsorPreset Default ISRO display_name]] "India"},
	effect = T{5487, --[[MissionSponsorPreset Default ISRO effect]] "Difficulty: <em>Normal</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- All building costs reduced by 20%\n- Bonus Tech: <em>Low-G Engineering</em> (unlocks Medium Dome)"},
	funding = 7000,
	goal = "MG_Colonists",
	goal_target = 200,
	group = "Default",
	id = "ISRO",
	initial_rockets = 3,
	initial_techs_unlocked = 1,
	sponsor_nation_name1 = "Indian",
	sponsor_nation_name2 = "Chinese",
	sponsor_nation_name3 = "English",
	sponsor_nation_percent1 = 90,
	sponsor_nation_percent2 = 5,
	sponsor_nation_percent3 = 5,
	PlaceObj('Effect_GrantTech', {
		Field = "Engineering",
		Research = "LowGEngineering",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = -1,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -20,
		Prop = "Concrete_cost_modifier",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -20,
		Prop = "Electronics_cost_modifier",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -20,
		Prop = "MachineParts_cost_modifier",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = 50,
		Prop = "ApplicantsPoolStartingSize",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -20,
		Prop = "Metals_cost_modifier",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -20,
		Prop = "Polymers_cost_modifier",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -20,
		Prop = "PreciousMetals_cost_modifier",
	}),
})

PlaceObj('MissionSponsorPreset', {
	Drone = 6,
	DroneHub = 1,
	Electronics = 10,
	ExplorerRover = 1,
	FuelFactory = 1,
	MachineParts = 15,
	MoistureVaporator = 1,
	OrbitalProbe = 3,
	Polymers = 15,
	SortKey = 6000,
	additional_research_points = 300,
	cargo = 50000,
	challenge_mod = 110,
	display_name = T{5488, --[[MissionSponsorPreset Default ESA display_name]] "Europe"},
	effect = T{5489, --[[MissionSponsorPreset Default ESA effect]] "Difficulty: <em>Normal</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- 5 extra starting technologies\n- Gain Funding every time a tech is researched. Gain double if it's a Breakthrough tech"},
	funding = 6000,
	funding_per_breakthrough = 300,
	funding_per_tech = 150,
	goal = "MG_TechResearch",
	goal_target = 40,
	group = "Default",
	id = "ESA",
	initial_techs_unlocked = 2,
	sponsor_nation_name1 = "German",
	sponsor_nation_name2 = "French",
	sponsor_nation_name3 = "Swedish",
	sponsor_nation_name4 = "Bulgarian",
	sponsor_nation_percent1 = 40,
	sponsor_nation_percent2 = 30,
	sponsor_nation_percent3 = 20,
	sponsor_nation_percent4 = 10,
	PlaceObj('Effect_ModifyLabel', {
		Amount = -3,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
})

PlaceObj('MissionSponsorPreset', {
	Drone = 4,
	DroneHub = 3,
	Electronics = 15,
	MachineParts = 15,
	OrbitalProbe = 3,
	Polymers = 15,
	RCTransport = 1,
	SortKey = 7000,
	additional_research_points = 100,
	cargo = 50000,
	challenge_mod = 130,
	default_skin = "Facet",
	display_name = T{5490, --[[MissionSponsorPreset Default SpaceY display_name]] "SpaceY"},
	effect = T{5491, --[[MissionSponsorPreset Default SpaceY effect]] "Difficulty: <em>Normal</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Drone Hubs start with additional Drones\n- 50% cheaper advanced resources"},
	funding = 6000,
	goal = "MG_Colonists",
	goal_target = 200,
	group = "Default",
	id = "SpaceY",
	initial_rockets = 5,
	initial_techs_unlocked = 1,
	modifier_name1 = "Polymers",
	modifier_name2 = "Electronics",
	modifier_name3 = "MachineParts",
	modifier_value1 = -50,
	modifier_value2 = -50,
	modifier_value3 = -50,
	sponsor_nation_name1 = "American",
	sponsor_nation_name2 = "Chinese",
	sponsor_nation_name3 = "Russian",
	sponsor_nation_name4 = "French",
	sponsor_nation_percent1 = 80,
	sponsor_nation_percent2 = 10,
	sponsor_nation_percent3 = 5,
	sponsor_nation_percent4 = 5,
	PlaceObj('Effect_ModifyLabel', {
		Amount = 20,
		Label = "Consts",
		Prop = "CommandCenterMaxDrones",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = 4,
		Label = "DroneHub",
		Prop = "starting_drones",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = -5,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -25,
		Prop = "ApplicantsPoolStartingSize",
	}),
})

PlaceObj('MissionSponsorPreset', {
	Drone = 8,
	DroneHub = 1,
	Electronics = 10,
	FuelFactory = 1,
	MachineParts = 15,
	MoistureVaporator = 1,
	OrbitalProbe = 1,
	Polymers = 15,
	RCTransport = 1,
	SortKey = 8000,
	additional_research_points = -100,
	cargo = 50000,
	challenge_mod = 170,
	display_name = T{5493, --[[MissionSponsorPreset Default NewArk display_name]] "Church of the New Ark"},
	effect = T{5494, --[[MissionSponsorPreset Default NewArk effect]] "Difficulty: <em>Hard</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- All Colonists have the Religious trait\n- Birthrate is doubled\n- Hydroponic Farms performance reduced by 50 <em>(drawback)</em>"},
	goal = "MG_Martianborn",
	goal_target = 80,
	group = "Default",
	id = "NewArk",
	initial_rockets = 1,
	initial_techs_unlocked = 1,
	sponsor_nation_name1 = "American",
	sponsor_nation_name2 = "English",
	sponsor_nation_percent1 = 95,
	sponsor_nation_percent2 = 5,
	trait = "Religious",
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -50,
		Prop = "BirthThreshold",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = -5,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = 20,
		Prop = "ApplicantsPoolStartingSize",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "HydroponicFarm",
		Percent = -50,
		Prop = "performance",
	}),
})

PlaceObj('MissionSponsorPreset', {
	Drone = 4,
	DroneHub = 1,
	Electronics = 15,
	FuelFactory = 1,
	MachineParts = 20,
	MoistureVaporator = 1,
	OrbitalProbe = 1,
	Polymers = 15,
	RCRover = 1,
	SortKey = 9000,
	additional_research_points = 100,
	cargo = 50000,
	challenge_mod = 180,
	default_skin = "Facet",
	display_name = T{1226, --[[MissionSponsorPreset Default Roscosmos display_name]] "Russia"},
	effect = T{5492, --[[MissionSponsorPreset Default Roscosmos effect]] "Difficulty: <em>Hard</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Bonus Tech: <em>Fueled Extractors</em> (extractor upgrade that boosts production but consumes Fuel)\n- Fueled Extractors upgrade is free\n- Fuel Refinery prefab costs <percent(50)> less\n- Rockets have extended travel time <em>(drawback)</em>"},
	funding = 5000,
	goal = "MG_RareExport",
	goal_target = 100,
	group = "Default",
	id = "Roscosmos",
	initial_techs_unlocked = 1,
	modifier_name1 = "FuelFactory",
	modifier_value1 = -50,
	sponsor_nation_name1 = "Russian",
	sponsor_nation_name2 = "Bulgarian",
	sponsor_nation_percent1 = 95,
	sponsor_nation_percent2 = 5,
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = 100,
		Prop = "TravelTimeEarthMars",
	}),
	PlaceObj('Effect_GrantTech', {
		Field = "Robotics",
		Research = "FueledExtractors",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = 100,
		Prop = "TravelTimeMarsEarth",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = -3,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
})

PlaceObj('MissionSponsorPreset', {
	Drone = 6,
	Electronics = 5,
	ExplorerRover = 1,
	FuelFactory = 1,
	MachineParts = 15,
	MoistureVaporator = 1,
	OrbitalProbe = 2,
	Polymers = 10,
	RCRover = 1,
	SortKey = 10000,
	anomaly_bonus_breakthrough = range(2, 4),
	applicants_per_breakthrough = 30,
	cargo = 50000,
	challenge_mod = 200,
	default_skin = "Star",
	display_name = T{5495, --[[MissionSponsorPreset Default paradox display_name]] "Paradox Interactive"},
	effect = T{5496, --[[MissionSponsorPreset Default paradox effect]] "Difficulty: <em>Hard</em>\n\nFunding: $<funding> M\nResearch per Sol: <research(SponsorResearch)>\nRare Metals price: $<ExportPricePreciousMetals> M\nStarting Applicants: <ApplicantsPoolStartingSize>\n\n- Discover more Breakthrough Anomalies\n- Researching a Breakthrough Tech grants Applicants\n- Rockets require more fuel to launch <em>(drawback)</em>"},
	filter = function (self) return HasParadoxSponsor() end,
	goal = "MG_Anomalies",
	goal_target = 30,
	group = "Default",
	id = "paradox",
	initial_rockets = 1,
	initial_techs_unlocked = 1,
	sponsor_nation_name1 = "Swedish",
	sponsor_nation_name2 = "German",
	sponsor_nation_name3 = "English",
	sponsor_nation_name4 = "French",
	sponsor_nation_percent1 = 60,
	sponsor_nation_percent2 = 10,
	sponsor_nation_percent3 = 20,
	sponsor_nation_percent4 = 10,
	PlaceObj('Effect_ModifyLabel', {
		Amount = 40,
		Label = "AllRockets",
		Prop = "launch_fuel",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Amount = -1,
		Label = "Consts",
		Prop = "ExportPricePreciousMetals",
	}),
	PlaceObj('Effect_ModifyLabel', {
		Label = "Consts",
		Percent = -25,
		Prop = "ApplicantsPoolStartingSize",
	}),
})

PlaceObj('MissionSponsorPreset', {
	SortKey = 11000,
	display_name = T{3490, --[[MissionSponsorPreset Default random display_name]] "Random"},
	group = "Default",
	id = "random",
})

