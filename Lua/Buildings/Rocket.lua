RocketTypeNames = {
	Passenger = T{1116, "Passenger Rocket"},
	Cargo = T{1115, "Cargo Rocket"},
	Trade = T{8029, "Trade Rocket"},
	Refugee = T{8123, "Refugee Rocket"},
	Fallback = T{1685, "Rocket"},
}

DefineClass.FXRocket = {
	__parents = { "SpawnFXObject" },
	entity = "Rocket",
}

DefineClass.SupplyRocket = {
	__parents = { "PinnableObject", "UniversalStorageDepot", "DroneControl", "WaypointsObj", "Renamable", "RechargeStationBase", "CommandObject"},
		
	properties = {
		{ category = "Rocket", id = "name", name = T{1000037, "Name"}, editor = "text", default = ""},
		{ template = true, category = "Rocket", name = T{702, "Launch Fuel"},      	id = "launch_fuel",      	editor = "number", default = 10*const.ResourceScale, min = 1*const.ResourceScale, max = 1000*const.ResourceScale, scale = const.ResourceScale, modifiable = true, help = "The amount of fuel it takes to launch the rocket.",},	
		{ template = true, category = "Rocket", name = T{758, "Max Export Storage"}, id = "max_export_storage", editor = "number", scale = const.ResourceScale, default = 100*const.ResourceScale, min = 0, modifiable = true },
		{ template = true, category = "Rocket", name = T{8457, "Passenger Orbit Lifetime"}, id = "passenger_orbit_life",      	editor = "number", default = 120*const.HourDuration, min = 1*const.HourDuration, scale = const.HourDuration, modifiable = true, help = "Passengers on board will die if the rocket doesn't land this many hours after arriving in orbit.",},
		
		{ id = "landed",	editor = "bool", default = false, no_edit = true }, -- true if working on Mars (controlling drones)
		{ id = "auto_export",	editor = "bool", default = false, no_edit = true },
		{ id = "allow_export",	editor = "bool", default = true, no_edit = true },
		{ id = "reserved_site", editor = "bool", default = false, no_edit = true },
		{ id = "landing_site", editor = "object", default = false, no_edit = true },
		{ id = "site_particle", editor = "object", default = false, no_edit = true },
	},
		
	display_icon = "UI/Icons/Buildings/orbital_probe.tga",
	pin_rollover = T{8030, "Carries supplies or passengers  from Earth. Can travel back to Earth when refueled."},
	pin_rollover_hint = T{7351, "<left_click> Place Rocket"},
	pin_rollover_hint_xbox = T{7352, "<ButtonA> Place Rocket"},
	pin_progress_value = "",
	pin_progress_max = "",
	pin_obvious_blink = true,
	
	pin_rollover_arriving = T{707, "<RocketType><newline>Travelling to Mars.<newline>Flight progress: <em><ArrivalTimePercent></em>%.<newline>Payload:<newline><CargoManifest>"},
	pin_rollover_in_orbit = T{710, "Ready to land.<newline>Payload:<newline><CargoManifest>"},

	-- landing/takeoff parameters
	orbital_altitude = 2500*guim,
	orbital_velocity = 100*guim,
	-- second set for the first rocket
	orbital_altitude_first = 400*guim,
	orbital_velocity_first = 43*guim,	
	warm_up = 10000,
	
	-- pre-hit ground moments, all are relative to hit-ground
	pre_hit_ground = 10000,
	pre_hit_ground2 = 13000,
	pre_hit_groud_decal = 0,
	
	warm_down = 1000,
	fx_actor_base_class = "FXRocket",
	fx_actor_class = "SupplyRocket",
	show_logo = true,
	rocket_palette = "RocketStandard",
	
	show_service_area = true,
	
	accumulate_dust = false,
	maintenance_resource_type = "no_maintenance", --doesnt require maintenance.
	accumulate_maintenance_points = false,
	use_shape_selection = false,
	default_label = false,

	cargo = false,
	placement = false,
	rovers = false,
	departures = false,
	boarding = false,
	disembarking = false,
	disembarking_confused = false,
	residence_search_radius = 1500*guim, -- radius around which to search for domes with free residences upon ordering	
	arrival_time = false,
	arrival_time_earth = false,
	first_arrival = false,
	is_pinned = false, -- remembers the pin state while on mars, as the travel/landing/takeoff modifies the state
	status = false,
	orbit_arrive_time = false,
	
	pin_status_img = false,
	is_demolishable_state = false, -- updated as the status updates
	
	-- ui related
	launch_time = false,
	flight_time = false,
	
	--drone control
	starting_drones = 0,
	working = false,
	drone_entry_spot = "Roverout", --where the drone should be to start the embark visuals.
	drone_spawn_spot = "Roverdock2",
	distance_to_provoke_go_home_cmd = 80 * guim,	
	auto_connect = false,
	
	--storage
	max_storage_per_resource = 60 * const.ResourceScale, --how much the rocket can hold as storage
	storable_resources = {"Concrete", "Metals", "Polymers", "Food", "Electronics", "MachineParts",},
	--refuel/export
	refuel_request = false,
	export_requests = false,
	unload_request = false,
	unload_fuel_request = false,
	exported_amount = false,
	custom_id = false,
	custom_travel_time_mars = false,
	custom_travel_time_earth = false,
	launch_after_unload = false,
	
	exclude_from_lr_transportation = true,
	
	drones_entering = false,
	drones_exiting = false,
	
	--land/launch dust
	total_dust_time = 5000, --it will dust total_dust_time time before land and total_dust_time time after launch
	dust_tick = 100, --tick between dust application
	dust_radius = 8, --in hexes
	total_launch_dust_amount = 50000, --the total amount of dust applied during launch
	total_land_dust_amount = 50000, --the total amount of dust applied during landing
	
	decal_fade_time = 50*const.DayDuration,
	
	dust_thread = false,
	
	rocket_engine_decal_name = "DecRocketSplatter",
	accumulated_fuel = 0,
	prio_button = true,
	encyclopedia_id = "Rocket",
	
	can_pulse_recharge = false,
	can_change_skin = true,
	can_fly_colonists = true,
	
	compatibility_thread = false,
}

-- commands

function SupplyRocket:Idle()
	-- fallback if a command breaks for some reason
	self:SetCommand("OnEarth")
end

function SupplyRocket:OnEarth()
	self:OffPlanet()
	self:UpdateStatus("on earth")
	WaitWakeup()
end

function SupplyRocket:FlyToMars(cargo, cost, flight_time, initial, launch_time)
	self:OffPlanet()
	flight_time = initial and 0 or (flight_time or self.custom_travel_time_mars or g_Consts.TravelTimeEarthMars)
	launch_time = launch_time or GameTime()
	
	-- mark arrival time for ui
	self.launch_time = launch_time
	self.flight_time = flight_time
	
	-- flight time correction for loading saves
	flight_time = Max(0, flight_time - GameTime() + launch_time)

	-- cargo/naming
	cargo = cargo or {}
	self.cargo = cargo
	if self.name == "" then
		self.name = cargo.rocket_name 
	end
	if not self.name or self.name=="" then
		self.name = g_CurrentMapParams.rocket_name 
		MarkNameAsUsed("Rocket",g_CurrentMapParams.rocket_name_base) 
	end
	if not self.name or self.name==""  then
		self.name = GenerateRocketName()
	end	
	
	if cost then
		self.city:ChangeFunding(-cost)
	end
	ResetCargo()
	--@@@msg RocketLaunchFromEarth,rocket - fired when a rocket is launched toward Mars
	Msg("RocketLaunchFromEarth", self)
	
	if g_ActiveHints["HintPassengerRockets"] and #cargo > 0 then
		for i = 1, #cargo do
			if cargo[i].class == "Passengers" then
				HintDisable("HintPassengerRockets")
				break
			end
		end
	end
	
	self:UpdateStatus("arriving")
		
	if initial then -- special case: first rocket is already in orbit and lands faster
		self.first_arrival = true
	else
		Sleep(flight_time)
	end
	self:SetCommand("WaitInOrbit")
end

function SupplyRocket:WaitInOrbit(arrive_time)
	self:OffPlanet()
	self.orbit_arrive_time = arrive_time
	self.cargo = self.cargo or {}
	local cargo = self.cargo
	-- release probes immediately, mark orbit arrival time if carrying passengers
	for i = #cargo, 1, -1 do
		local item = cargo[i]
		if IsKindOf(item, "OrbitalProbe") then
			for j = 1, item.amount do
				PlaceObject(item.class, {city = self.city})
			end
			table.remove(cargo, i)
		elseif item.class == "Passengers" then
			self.orbit_arrive_time = self.orbit_arrive_time or GameTime()
		end
	end

	self:UpdateStatus(self:IsFlightPermitted()  and "in orbit" or "suspended in orbit")
	
	if not self:IsLandAutomated() or not self:IsFlightPermitted() then
		if self.orbit_arrive_time then
			Sleep(Max(0, self.passenger_orbit_life + GameTime() - self.orbit_arrive_time))
			-- kill the passengers, call GameOver if there are no colonists on Mars
			local count
			for i = #cargo, 1, -1 do
				if cargo[i].class == "Passengers" then
					count = cargo[i].amount
					table.remove(cargo, i)
				end
			end
			if (count or 0) > 0 then
				if #(self.city.labels.Colonist or empty_table) == 0 then
					GameOver("last_colonist_died")
				else
					-- notification
					AddOnScreenNotification("DeadColonistsInSpace", nil, {count = count})
				end
				self:OnPassengersLost()
			end
			self.orbit_arrive_time = nil
			self:UpdateStatus(self.status) -- force update to get rid of the passenger-specific texts in rollover/summary
		end
		WaitWakeup()
	end
	self:SetCommand("LandOnMars", self.landing_site)
end

function SupplyRocket:LandOnMars(site, from_ui)
	self.reserved_site = nil
	self.landing_site = site
	self.cargo = self.cargo or {}
	if from_ui then
		CloseModeDialog()
	end
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Land")
		self:SetCommand("OnEarth")
	end
	local spot = site:GetSpotBeginIndex("Rocket")
	local dest = site:GetSpotPos(spot)
	local angle = site:GetSpotRotation(spot)

	self:UpdateStatus("landing")

	assert(terrain.IsPointInBounds(dest))
	
	local altitude = self.orbital_altitude
	local velocity = self.orbital_velocity

	local first_arrival = self.first_arrival
	if first_arrival then	
		altitude = self.orbital_altitude_first
		velocity = self.orbital_velocity_first	
		self.first_arrival = nil
		
		HintDisable("HintRocket")
	end
	
	self.orbit_arrive_time = nil
	
	local pt = dest + point(0, 0, altitude)
	self:ClearEnumFlags(const.efVisible)
	self:SetPos(pt)
	self:SetAngle(angle)
	
	PlayFX("RocketLand", "start", self)	
	if not IsValid(self.site_particle) then
		self.site_particle = PlaceParticles("Rocket_Pos")
		self.site_particle:SetPos(dest)
		self.site_particle:SetScale(200)
	end
	
	self:SetEnumFlags(const.efVisible + const.efSelectable)

	local a, t = self:GetAccelerationAndTime(dest, 0, velocity)
		
	if not IsValid(site.landing_pad) then
		self:StartDustThread(self.total_land_dust_amount, Max(0, t - self.total_dust_time))
	end
	
	self:SetAcceleration(a)
	self:SetPos(dest, t)
	
	assert(self.pre_hit_ground2 >  self.pre_hit_ground)
	assert(self.pre_hit_ground2 < t)
	assert(self.pre_hit_groud_decal < t)
	
	--spawn decal (delayed)
	if not IsValid(site.landing_pad) then
		self:PlaceEngineDecal(dest, Max(t - self.pre_hit_groud_decal, 0))
	end

	Sleep(Max(0, t - self.pre_hit_ground2)) -- t = T - pre_hit_ground2
	PlayFX("RocketLand", "pre-hit-ground2", self, false, dest)
	
	Sleep(Max(0, self.pre_hit_ground2 - self.pre_hit_ground)) -- t = T - pre_hit_ground
	PlayFX("RocketLand", "pre-hit-ground", self, false, dest)

	Sleep(Min(t, self.pre_hit_ground))
	PlayFX("RocketLand", "hit-ground", self, false, dest)
	StopParticles(self.site_particle)
	self.site_particle = nil
	Sleep(self.warm_down)
	PlayFX("RocketLand", "end", self)
	self:UpdateStatus("landed")
	
	if HintsEnabled then
		if first_arrival then
			HintTrigger("HintBuildingConstruction")
			HintTrigger("HintCameraControls")
			HintTrigger("HintStorageDepot")
			HintTrigger("HintSuggestSensorTower")
			HintTrigger("HintResupply")
			HintTrigger("HintPriority")
			HintTrigger("HintGameSpeed")
			if g_Consts.SponsorResearch > 0 then
				HintTrigger("HintResearchAvailable")
			end
		end
		
		if not g_ActiveHints["HintRefuelingTheRocket"] then
			local rockets = UICity and UICity.labels.SupplyRocket or ""
			local has_available = false
			for i = 1, #rockets do
				if rockets[i] ~= self and rockets[i]:IsAvailable() then
					has_available = true
					break
				end
			end
			if not has_available then
				HintRefuelingTheRocket:TriggerLater()
			end
		end
	end

	--@@@msg RocketLanded,rocket- fired when a rocket has landed on Mars.
	Msg("RocketLanded", self)
	self:SetCommand("Unload")
end

function SupplyRocket:Unload()
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Unload")
		self:SetCommand("OnEarth")
	end
	self.cargo = self.cargo or {}
	self:SpawnRovers()
	self:SpawnDronesFromEarth()
	self:OpenDoor()
	--needs to happen after rover's game init (so default desires have booted)
	--so we use opendoor's sleep to make sure all rovers are initialized.
	self:FillTransports() 
	Flight_Remark(self)

	local rovers = self.rovers
	self.rovers = nil
	self.placement = {}
	
	local rc_rovers = {}

	local out = self:GetSpotPos(self:GetSpotBeginIndex("Roverout"))
	local angle = self:GetAngle()
	-- disembark rovers
	if #rovers > 0 then
		if IsKindOf(rovers[1], "RCRover") then
			rc_rovers[1] = rovers[1]
		end
		local dir = (out - self:GetPos()):SetZ(0)
		local out_1 = self:PlaceAdjacent(rovers[1], GetPassablePointNearby(out + SetLen(dir, 25*guim)))	
		out = GetPassablePointNearby(out, rovers[1].pfclass)
		self:PlaceAdjacent(rovers[1], out) --block out so they don't park right @ the ramp exit.
	
		rovers[1]:Detach()
		rovers[1]:SetGameFlags(const.gofSpecialOrientMode)
		rovers[1]:SetAngle(angle)
		rovers[1]:SetPos(out)
		rovers[1]:SetAnim(1, "disembarkUnload", const.eDontCrossfade)
		Sleep(rovers[1]:TimeToAnimEnd())
		rovers[1].override_ui_status = nil
		rovers[1]:SetCommand("Goto", out_1)
		Sleep(1000) --disembark 2 anim is kinda quick so give it a sec
		if #rovers > 1 then
			--generate positions
			local positions = {}
			for i = #rovers, 2, -1 do
				if IsKindOf(rovers[i], "RCRover") then
					rc_rovers[#rc_rovers + 1] = rovers[i]
				end
				positions[i] = self:PlaceAdjacent(rovers[i], out_1)
			end
		
			for i = 2, #rovers do
				rovers[i]:Detach()
				rovers[i]:SetAngle(angle)
				rovers[i]:SetPos(out)
				rovers[i]:SetAnim(1, "disembarkUnload2", const.eDontCrossfade)
				Sleep(rovers[i]:TimeToAnimEnd())
				rovers[i].override_ui_status = nil
				rovers[i]:SetCommand("Goto", positions[i])
				Sleep(1000) --disembark 2 anim is kinda quick so give it a sec
			end
		end
	end
	
	--re enable auto siege mode on rc rovers
	for i = 1, #rc_rovers do
		rc_rovers[i].sieged_state = true
		if rc_rovers[i].command == "Idle" then --otherwise player is touching it.
			rc_rovers[i]:SetCommand("Idle")
		end
	end
	
	for i = 1, #self.drones do
		CreateGameTimeThread(function()
			local drone = self.drones[i]
			Sleep( (i - 1) * 1000 )
			if IsValid(drone) then
				self:LeadOut(drone)
				if not IsValid(drone) then return end
				local pt
				if IsValid(self) then
					pt = self:PickArrivalPos(false, false, 30*guim, 10*guim, 90*60, -90*60)
				else
					pt = self:PickArrivalPos(drone:GetPos(), point(guim, 0, 0), 30*guim, 10*guim, 180*60, -180*60)
				end
				Movable.Goto(drone, pt) -- Unit.Goto is a command, use this instead for direct control
				drone:SetCommand(IsValid(self) and "GoHome" or "Idle")
			end
		end, self, i)
	end

	for i = 1, #self.cargo do
		local item = self.cargo[i]
		local classdef = g_Classes[item.class]
		if Resources[item.class] then
			if item.amount > 0 then
				self:AddResource(item.amount*const.ResourceScale, item.class)
			end
		elseif item.class == "Passengers" then
			self:GenerateArrivals(item.amount, item.applicants_data)
		elseif IsKindOf(classdef, "Vehicle") then
			for j = 1, item.amount do
				local obj = PlaceObject(item.class, {city = self.city})
				self:PlaceAdjacent(obj, out, true)
			end
		elseif DataInstances.BuildingTemplate[item.class] then
			self.city:AddPrefabs(item.class, item.amount)
		else
			printf("unexpected cargo type %s, ignored", item.class)
		end
	end
		
	self.cargo = nil
	self.placement = nil
	
	self:SetCommand(self.launch_after_unload and "Takeoff" or "Refuel")
end

function SupplyRocket:Refuel()
	if not IsValid(self.landing_site) then
		assert(false, "Missing landing site for Refuel")
		self:SetCommand("OnEarth")
	end

	table.insert(g_LandedRocketsInNeedOfFuel, self)
	self:ResetDemandRequests()
	self:StartDroneControl()
	self:GenerateDepartures()	
	self:UpdateStatus("refueling")
	while not self:HasEnoughFuelToLaunch() do
		WaitMsg("RocketRefueled")
	end
	
	self:SetCommand("WaitLaunchOrder")
end

function SupplyRocket:WaitLaunchOrder()
	while true do -- looped so UpdateFlightPermissions can just wakeup the thread instead of duplicating the checks
		local issue = self:GetLaunchIssue()
		local can_take_off = not issue or issue == "cargo"

		self:UpdateStatus(can_take_off and "ready for launch" or "launch suspended")
		
		if self:IsLaunchAutomated() and not self:HasCargoSpaceLeft() and can_take_off then
			self:SetCommand("Countdown")
		end
		WaitWakeup()
	end
end

function SupplyRocket:DropBrokenDrones(t)
	for i=#t, 1, -1 do
		local drone = t[i]
		if drone:IsBroken() then
			if self:IsValidPos() then
				drone:SetPos(self:GetVisualPos2D())
			else
				drone:delete()
			end
			table.remove(t, i)
		end
	end
end

function SavegameFixups.DropBrokenDrones()
	ForEach { class = "SupplyRocket", exec = function(obj)
		obj:DropBrokenDrones(obj.drones_exiting)
		obj:DropBrokenDrones(obj.drones_entering)
	end }
end

function SupplyRocket:InterruptIncomingDronesAndDisconnect()
	self:InterruptDrones(nil, function(drone)
										if (drone.target == self) or 
											(drone.d_request and drone.d_request:GetBuilding() == self) or
											(drone.s_request and drone.s_request:GetBuilding() == self) then
											if not table.find(self.drones_exiting, drone) and not table.find(self.drones_entering, drone) then
												--we'll wait up for those drones currently on the ramp, no further drones should enter the rocket though
												return drone
											end
										end
									end)
									
	self:DisconnectFromCommandCenters() --so no more drones climb the ramp.
	table.remove_entry(g_LandedRocketsInNeedOfFuel, self) -- needs to be after DisconnectFromCommandCenters
	self.working = false --so recharging drones exit.
	self.auto_connect = false --so ccs don't reconect us automatically anymore
	-- should be after disconnect so no further drones enter
	while self:IsCargoRampInUse() do
		self:DropBrokenDrones(self.drones_exiting)
		self:DropBrokenDrones(self.drones_entering)
		--wait for drones to exit and passengers to enter
		Sleep(1000)
	end
	self:StopDroneControl() --this removes waypoint splines so it should be after drones exit.	
end

function SupplyRocket:Countdown()
	self:UpdateStatus("countdown")
	self:InterruptIncomingDronesAndDisconnect()
	self:CloseDoor()
	local export_amount = self:GetStoredExportResourceAmount()
	self.city:MarkPreciousMetalsExport(export_amount)
	self.exported_amount = export_amount	
	self:SetCommand("Takeoff")
end

function SupplyRocket:Takeoff()
	self:UpdateStatus("takeoff")
	if SelectedObj == self then
		SelectObj(false)
	end
	if not self.auto_export then
		self:ClearEnumFlags(const.efSelectable)
	end
	self:AbandonAllDrones()
	self:ClearAllResources()
	self:ResetDemandRequests()
	self.departures = nil
	self.boarding = nil
	
	--@@@msg RocketLaunched,rocket - fired when a rocket takes off from Mars
	Msg("RocketLaunched", self)
	
	self.cargo = nil
	local pt = self:GetPos()
	local dest = pt + point(0, 0, self.orbital_altitude)
	
	PlayFX("RocketEngine", "start", self)
	Sleep(self.warm_up)
	
	local has_pad = IsValid(self.landing_site) and IsValid(self.landing_site.landing_pad)
	if not has_pad then
		self:PlaceEngineDecal(pt, 0)
	end
	
	PlayFX("RocketEngine", "end", self)
	PlayFX("RocketLaunch", "start", self)
	local a, t = self:GetAccelerationAndTime(dest, self.orbital_velocity, 0)
	
	if not has_pad then
		self:StartDustThread(self.total_launch_dust_amount)
	end
	self:SetAcceleration(a)
	self:SetPos(dest, t)

	Sleep(t)
	if IsValid(self.landing_site) and not self.auto_export then
		DoneObject(self.landing_site)
		self.landing_site = nil
	else
		self.reserved_site = true
		if not IsValid(self.site_particle) then
			self.site_particle = PlaceParticles("Rocket_Pos")
			self.site_particle:SetPos(pt)
			self.site_particle:SetScale(200)
		end
	end
	if not IsValid(self) then return end
	PlayFX("RocketLaunch", "end", self)
	
	self:ClearEnumFlags(const.efVisible)
	
	self:SetCommand("FlyToEarth")
end

GlobalVar("g_ExportsFunding", 0)

function SupplyRocket:FlyToEarth(flight_time, launch_time)
	flight_time = flight_time or self.custom_travel_time_earth or g_Consts.TravelTimeMarsEarth
	self.launch_time = launch_time or GameTime()
	self.flight_time = flight_time

	-- flight time correction for loading saves
	flight_time = Max(0, flight_time - GameTime() + self.launch_time)

	self:UpdateStatus("departing")
	self:OffPlanet()
	
	Flight_Unmark(self)
		
	Sleep(flight_time)

	self:UpdateStatus("on earth")
	--@@@msg RocketReachedEarth,rocket - fired when a rocket finishes its travel from Mars to Earth
	Msg("RocketReachedEarth", self)

	if (self.exported_amount or 0) > 0 then
		local export_funding = MulDivRound(self.exported_amount, g_Consts.ExportPricePreciousMetals*1000000, const.ResourceScale)
		export_funding = self.city:ChangeFunding(export_funding)
		if not g_ExportsFunding or not IsOnScreenNotificationShown("RareMetalsExport") then
			g_ExportsFunding = 0
		end
		g_ExportsFunding = g_ExportsFunding + export_funding
		AddOnScreenNotification("RareMetalsExport", nil, { funding = g_ExportsFunding })
	end
	self.exported_amount = nil
	
	if self.auto_export then
		self:SetCommand("FlyToMars")
	else
		self:SetCommand("OnEarth")
	end
end

-- end commands

-- msg / status updates

local function UpdateFlightPermissions()
	local rockets = UICity.labels.AllRockets or empty_table
	for _, rocket in ipairs(rockets) do		
		if rocket.command == "WaitInOrbit" then -- update status/trigger land for rockets in orbit
			rocket:UpdateStatus(rocket:IsFlightPermitted() and "in orbit" or "suspended in orbit")
			if rocket:IsLandAutomated() then
				rocket:SetCommand("LandOnMars", rocket.landing_site)
			end
		elseif rocket.command == "WaitLaunchOrder" then -- update status/trigger launch for rockets on ground
			Wakeup(rocket.command_thread)
		end
	end
end

OnMsg.DustStorm = UpdateFlightPermissions
OnMsg.DustStormEnded = UpdateFlightPermissions

function OnMsg.ConstValueChanged(prop, old_value, new_value)
	if prop == "SupplyMissionsEnabled" then
		UpdateFlightPermissions()
	end		
end

function SupplyRocket:OnModifiableValueChanged(prop, old_val, new_val)
	if prop == "launch_fuel" then
		if self.command == "Refuel" then
			local delta = new_val - old_val
			local stored = old_val - self.refuel_request:GetActualAmount()
			self.refuel_request:AddAmount(delta)
			self:InterruptDrones(nil, function(drone) return drone.d_request == self.refuel_request and drone end)
			
			if self:HasEnoughFuelToLaunch() then
				local extra = stored - new_val
				if extra > 0 then
					self:DisconnectFromCommandCenters()
					local unit_count = 1 + (new_val / (const.ResourceScale * 10)) --1 per 10
					self.unload_fuel_request = self:AddSupplyRequest("Fuel", extra, 0, unit_count)
					self.refuel_request:SetAmount(0)
					self:ConnectToCommandCenters()
				end
				self:SetCommand("WaitLaunchOrder")
			end
		end
	elseif prop == "max_export_storage" then
		if self.command == "Refuel" or self.command == "WaitLaunchOrder" and self.export_requests then
			local delta = new_val - old_val
			self.export_requests[1]:AddAmount(delta)
			self:InterruptDrones(nil, function(drone) return drone.d_request == self.export_requests[1] and drone end)
			if self.command == "WaitLaunchOrder" then
				Wakeup(self.command_thread)
			end
		end
	end
end

-- end msg / status updates

-- backward compatibility
--[[
	Some rocket states used to happen in game-time threads which aren't saved anywhere and can be potentially saved.
	The following functions are used to hook onto these running threads and phase the rocket to a proper command.
--]]

-- potentially called from a created GameTime thread within LandOnSite
function SupplyRocket:UnloadCargo()
	self:SetCommand("Unload")
	Halt()
end

-- potentially called from a created GameTime thread within LandOnSite or BuildingUpdate
function SupplyRocket:Launch()
	self:SetCommand("Takeoff")
	Halt()
end

-- potentially called from within Launch (see above), in that case it's an automated return to Mars
function SupplyRocket:OrderLanding()
	self:SetCommand("FlyToMars")
	Halt()
end

-- potentially called at the very start of the created GameTime thread within LandOnSite
function SupplyRocket:Land()
	if IsValid(self.landing_site) then
		self:SetCommand("LandOnMars", self.landing_site)
	else
		self:SetCommand("WaitInOrbit")
	end
	Halt()
end

function SupplyRocket:CompatConvertToCommand()
	if self.command then
		return
	end
	if self.status == "on earth" then
		self:SetCommand("OnEarth")
	elseif self.status == "refueling" then
		self:SetCommand("Refuel")
	elseif self.status == "landed" then
		self:SetCommand("Unload")
	elseif self.status == "departing" then
		self:SetCommand("FlyToEarth")
	end
end

-- end backward compatibility

function SupplyRocket:BuildingUpdate(dt, day, hour)	
	if GetMissionSponsor().id == "IMM" and self.command == "Refuel" then
		self.accumulated_fuel = self.accumulated_fuel + MulDivRound(dt, self.launch_fuel/10, const.DayDuration)
		local amount = self.accumulated_fuel - self.accumulated_fuel % const.ResourceScale
		self.accumulated_fuel = self.accumulated_fuel - amount
		self.refuel_request:AddAmount( -Min(amount, self.refuel_request:GetTargetAmount() ) )
		if self:HasEnoughFuelToLaunch() then
			--@@@msg RocketRefueled,rocket - fired when a rocket is completely refueled for its trip back to Earth
			Msg("RocketRefueled", self)
		end
	end
end

function SupplyRocket:OffPlanet()
	if self:IsValidPos() then
		self:DetachFromMap()
	end
	if IsValid(self.landing_site) and not self.auto_export then
		DoneObject(self.landing_site)
		self.landing_site = nil
	end
	if SelectedObj == self then
		SelectObj(false)
	end
end

function SupplyRocket:GetSelectionRadiusScale()
	return self.work_radius
end

function SupplyRocket:GetLogicalPos()
	if IsValid(self.landing_site) then
		return self.landing_site:GetVisualPos()
	end
	return self:GetVisualPos()
end

local dust_query =
{
	classes = { "Building", "DustGridElement", "DroneBase" },
	area = false,
	hexradius = false,
	exec = function(o, amount)
		o:AddDust(amount)
	end,
}

function SupplyRocket:UpdateNotWorkingBuildingsNotification()
end

function SupplyRocket:StartDustThread(total_dust_to_apply, delay)
	if IsValidThread(self.dust_thread) then
		DeleteThread(self.dust_thread)
	end
	
	self.dust_thread = CreateGameTimeThread(function(self, total_dust_to_apply, delay)
		if delay and delay > 0 then
			Sleep(delay)
		end
				
		local total_dust_time = self.total_dust_time
		local dust_tick = self.dust_tick
		local total_dust_applied = 0
		local dust_to_apply_per_tick = (total_dust_to_apply / total_dust_time) * dust_tick
		assert(dust_to_apply_per_tick > 0 and dust_to_apply_per_tick * (total_dust_time / dust_tick) == total_dust_to_apply, "Rounding error in rocket dust application")
		while IsValid(self) and total_dust_applied < total_dust_to_apply do
			dust_query.area = self
			dust_query.hexradius = self.dust_radius
			ForEach(dust_query, dust_to_apply_per_tick)
			dust_query.area = false
			total_dust_applied = total_dust_applied + dust_to_apply_per_tick
			Sleep(self.dust_tick)
		end
	end, self, total_dust_to_apply, delay)
end

function SupplyRocket:Done()
	if IsValidThread(self.dust_thread) then
		DeleteThread(self.dust_thread)
	end
	self.dust_thread = false
	self.city:RemoveFromLabel("AllRockets", self)
end

function OnMsg.GatherLabels(labels)
	labels.AllRockets = true
end

function SupplyRocket:GameInit()
	if self.landed then --pre saved rocket on map
		self:SetCommand("Refuel")
	elseif not self.command then
		self:SetCommand("OnEarth")		
	end
	
	if not self.show_logo then
		self:DestroyAttaches("Logo")
	end
	self:SetPalette(self.rocket_palette)
	
	self.city:AddToLabel("AllRockets", self)
end

function SupplyRocket:GetWorkNotPossibleReason()
	if not self.landed then
		return "NotLanded"
	end
	return BaseBuilding.GetWorkNotPossibleReason(self)
end

function SupplyRocket:IsAvailable()
	return self.command == "OnEarth" and not self.auto_export
end

function SupplyRocket:BuildWaypointChains()
	--intentionally empty
end

function SupplyRocket:CanDemolish()
	return self.can_demolish and self.is_demolishable_state
end

function SupplyRocket:OnDemolish()
	if IsValid(self.landing_site) then
		DoneObject(self.landing_site)
		self.landing_site = nil
	end
	
	self:ReturnStockpiledResources()
	Building.OnDemolish(self)
end

function SupplyRocket:TogglePin(transparent)
	PinnableObject.TogglePin(self)
	if not transparent then
		self.is_pinned = not not self:IsPinned()
	end
end

function SupplyRocket:GetRocketType()
	if #self.cargo > 0 then
		for i,cargo in ipairs(self.cargo) do
			if cargo.class == "Passengers" then
				return RocketTypeNames.Passenger
			end
		end
		
		return RocketTypeNames.Cargo
	end
	
	return RocketTypeNames.Fallback
end

function SupplyRocket:UpdateStatus(status)
	if self:IsPinned() then
		self:TogglePin(true)
	end
	
	local could_change_skin = self.can_change_skin
	
	local template = DataInstances.BuildingTemplate[self.template_name]		
	self.status = status
	self:CompatConvertToCommand()
	if status == "arriving" then
		self.pin_blink = false
		self.pin_rollover = self.pin_rollover_arriving
		self.pin_summary1 = T{708, "<ArrivalTimePercent>%"}
		self.pin_rollover_hint = T{709, "In transit"}
		self.pin_rollover_hint_xbox = T{709, "In transit"}
		self.pin_status_img = "UI/Icons/pin_rocket_incoming.tga"
		self:TogglePin(true)
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "in orbit" then
		self.pin_blink = true
		self.pin_rollover = self.pin_rollover_in_orbit
		if template then
			self.pin_rollover_hint = template.pin_rollover_hint
			self.pin_rollover_hint_xbox = template.pin_rollover_hint_xbox
		end
		if self.orbit_arrive_time then
			self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T{8052, "Passengers on board will die if the rocket doesn't land in <em><UIOrbitTimeLeft> h</em>."}
		end
		self.pin_summary1 = nil
		self.pin_status_img = "UI/Icons/pin_rocket_orbiting.tga"
		self:TogglePin(true)
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "suspended in orbit" then
		self.pin_blink = false
		self.pin_rollover = self.pin_rollover_in_orbit
		if template then
			self.pin_rollover_hint = template.pin_rollover_hint
			self.pin_rollover_hint_xbox = template.pin_rollover_hint_xbox
		end
		if self.orbit_arrive_time then
			self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T{8052, "Passengers on board will die if the rocket doesn't land in <em><UIOrbitTimeLeft> h</em>."}
		end
		self.pin_rollover = self.pin_rollover .. "<newline><newline>" .. T{8523, "<red>Rockets can't land during dust storms.</red>"}
		self.pin_summary1 = nil
		self.pin_status_img = "UI/Icons/pin_rocket_orbiting.tga"
		self:TogglePin(true)
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "landing" then
		self.pin_blink = false
		self.pin_rollover = T{711, "Landing in progress."}
		if template then
			self.pin_rollover_hint = T{712, "Landing..."}
			self.pin_rollover_hint_xbox = T{712, "Landing..."}
		end
		self.pin_summary1 = nil
		self.pin_status_img = nil
		if self.is_pinned then
			self:TogglePin(true)
		end
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "landed" then
		self.pin_blink = false
		if template then
			self.pin_rollover = template.pin_rollover
			self.pin_rollover_hint = PinnableObject.pin_rollover_hint
			self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
		end
		self.pin_summary1 = nil
		self.pin_status_img = nil
		if self.is_pinned then
			self:TogglePin(true)
		end
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "refueling" then
		self.pin_blink = false
		if template then
			self.pin_rollover = template.pin_rollover
			self.pin_rollover_hint = PinnableObject.pin_rollover_hint
			self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
		end
		self.pin_summary1 = nil
		self.pin_status_img = nil
		if self.is_pinned then
			self:TogglePin(true)
		end
		self.is_demolishable_state = true
		self.can_change_skin = true
	elseif status == "ready for launch" or status == "launch suspended" then
		self.pin_blink = status == "ready for launch"
		if template then
			self.pin_rollover = template.pin_rollover
			self.pin_rollover_hint = PinnableObject.pin_rollover_hint
			self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
		end
		self.pin_summary1 = nil
		self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
		self:TogglePin(true)
		self.is_demolishable_state = true
		self.can_change_skin = true
	elseif status == "countdown" then
		self.pin_blink = false
		if template then
			self.pin_rollover = template.pin_rollover
			self.pin_rollover_hint = PinnableObject.pin_rollover_hint
			self.pin_rollover_hint_xbox = PinnableObject.pin_rollover_hint_xbox
		end
		self.pin_summary1 = nil
		self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
		self:TogglePin(true)
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "takeoff" then
		self.pin_blink = false
		self.pin_rollover = T{713, "Take-off in progress."}
		if template then
			self.pin_rollover_hint = T{714, "Taking off..."}
			self.pin_rollover_hint_xbox = T{714, "Taking off..."}
		end
		self.pin_summary1 = nil
		self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
		if self.is_pinned then
			self:TogglePin(true)
		end
		self.is_demolishable_state = false
		self.can_change_skin = false
	elseif status == "departing" then
		self.pin_blink = false
		self.pin_rollover = T{715, "Travelling to Earth.<newline>Flight progress: <em><ArrivalTimePercent></em>%."}
		if (self.exported_amount or 0) > 0 then
			self.pin_rollover = self.pin_rollover .. "<newline>" .. T{7674, "Exporting <resource(amount,res)>", amount = self.exported_amount, res = "PreciousMetals"}
		end
		self.pin_summary1 = T{708, "<ArrivalTimePercent>%"}
		self.pin_rollover_hint = T{709, "In transit"}
		self.pin_rollover_hint_xbox = T{709, "In transit"}
		self.pin_status_img = "UI/Icons/pin_rocket_outgoing.tga"
		self:TogglePin(true)
		self.is_demolishable_state = false
		self.can_change_skin = false
	end
	
	if self == SelectedObj then
		if self.can_change_skin == could_change_skin then
			RebuildInfopanel(self)
		else
			ReopenSelectionXInfopanel()
		end
	end
	
	--@@@msg RocketStatusUpdate,rocket,status - fired when rocket's status is updated. 'status' can be one of "on earth", "arriving", "in orbit", "suspended in orbit", "landing", "landed", "refueling", "ready for launch", "launch suspended", "countdown", "takeoff" or "departing"
	Msg("RocketStatusUpdate", self, status)
end

function PrepareApplicantsForTravel(city, host)
	local free = GetAvailableResidences(city)
	
	local applicants = {}
	local approved = host.context.approved_applicants 
	if approved then
		for applicant, approved in pairs(approved) do
			applicants[#applicants + 1] = applicant
		end
	else
		local eval_t = {}
		for i = #g_ApplicantPool, 1, -1 do
			local applicant = g_ApplicantPool[i]
			local eval = TraitFilterColonist(g_ApplicantPoolFilter, applicant[1].traits)
			if eval >= 0 then
				eval_t[applicant] = - eval
				applicants[#applicants + 1] = applicant
			end
		end
		table.sortby(applicants, eval_t)
	end
	
	local filtered_applicants_count= Min(g_Consts.MaxColonistsPerRocket, #applicants)
	local passengers_count = filtered_applicants_count
	if free < filtered_applicants_count then
		local params = {
			number1 = filtered_applicants_count,
			number2 = free,
			choice1 = T{717, "Launch anyway"}, 
			choice2 = (free > 0) and T{719, "Launch with <em><number></em> passengers", number = free} or T{718, "Abort"},
		}
		if free > 0 then
			params.choice3 = T{718, "Abort"}
		end
		local res = WaitPopupNotification("LaunchIssue_Housing", params, false, host)
			
		if not res or (free <= 0 and res == 2) or res == 3 then
			return false
		elseif res == 2 then
			passengers_count = free
		end			
	end
	
--		cargo[1].amount = passengers_count
		--cargo[2].amount = MulDivRound(passengers_count, g_Consts.FoodPerRocketPassenger, const.ResourceScale)
		-- remove applicants from the pool
	local applicants_data = {}
	for i = 1, passengers_count do
		local idx = table.remove_entry(g_ApplicantPool,applicants[i])
		assert(idx)-- can not find applicant in applicants pool
		applicants_data[i] = applicants[i][1]
	end
	--cargo[1].applicants_data = applicants_data	
	return passengers_count, applicants_data
end

function SupplyRocket:OnPinClicked(gamepad)
	HintDisable("HintGameStart")
	if HintsEnabled then
		HintTrigger("HintRocket")
	end
	if self.command == "OnEarth" or 
		self.command == "FlyToMars" or 
		self.command == "FlyToEarth" or 		
		self.command == "Takeoff" then
		
		return true
	end
	if self:IsValidPos() then
		return false -- use default logic (select/view)
	end
	local cargo = self.cargo or empty_table
	local passengers, drones
	for i = 1, #cargo do
		local cls = cargo[i].class
		if cls == "Passengers" then
			passengers = true
		elseif IsKindOf(g_Classes[cls], "Drone") and cargo[i].amount > 0 then
			drones = true
		end
	end
	
	local igi = GetInGameInterface()
	if gamepad and (igi.mode == "overview" or IsKindOf(igi.mode_dialog, "OverviewModeDialog")) then
		local mode_dlg = igi.mode_dialog
		local sector = mode_dlg.target_obj or mode_dlg.sector_obj
		--mode_dlg.exit_to = sector and sector:GetPos()
	end
	igi:SetMode("construction", { 
		template = "RocketLandingSite",
		instant_build = true,
		params = {
			amount = 0,
			passengers = passengers,
			drones = drones,
			stockpiles_obstruct = true,
			override_palette = self.rocket_palette,
			rocket = self,
			ui_callback = function(site)
				self:SetCommand("LandOnMars", site, "from ui")
			end,
		}
	})
	return true
end

function SupplyRocket:PlaceEngineDecal(pos, delay)
	CreateGameTimeThread(function()
		Sleep(delay)
		if not IsValid(self) then
			return
		end
		
		ForEach{
			class = self.rocket_engine_decal_name,
			area = pos,
			arearadius = 20*guim,
			action = "delete",
		}
		
		local engine_decal = PlaceObject(self.rocket_engine_decal_name)
		engine_decal:SetPos(pos)			
		engine_decal:SetOpacity(100)
		local fade_time = self.decal_fade_time	
				
		for opacity = 100, 0, -5 do
			Sleep(fade_time / 20)
			if not IsValid(engine_decal) then return end
			engine_decal:SetOpacity(opacity)
		end
		DoneObject(engine_decal)
	end)
end

GlobalVar("g_LandedRocketsInNeedOfFuel", {})

function SupplyRocket:SetPriority(priority)
	if self.priority == priority then return end
	for _, center in ipairs(self.command_centers) do
		center:RemoveRocket(self)
	end
	Building.SetPriority(self, priority)
	for _, center in ipairs(self.command_centers) do
		center:AddRocket(self)
	end
end

function SupplyRocket:AddCommandCenter(center)
	if TaskRequester.AddCommandCenter(self, center) then
		center:AddRocket(self)
	end
end

function SupplyRocket:RemoveCommandCenter(center)
	if TaskRequester.RemoveCommandCenter(self, center) then
		center:RemoveRocket(self)
	end
end

function SupplyRocket:Debug_InterruptTest()
	self:InterruptDrones(nil, function(drone)
										if (drone.target == self) or 
											(drone.d_request and drone.d_request:GetBuilding() == self) or
											(drone.s_request and drone.s_request:GetBuilding() == self) then
											return drone
										end
									end)
end

--drones
function SupplyRocket:StartDroneControl()
	WaypointsObj.BuildWaypointChains(self)
	self.landed = true
	self.working = true
	self.auto_connect = true
	self.accept_requester_connects = true
	self:ConnectTaskRequesters()
	self:GatherOrphanedDrones()
	self:ConnectToCommandCenters()
end

function SupplyRocket:StopDroneControl()
	self:DisconnectTaskRequesters()
	self.landed = false
	self.under_construction = false
	self.working = false
	self.auto_connect = false
	self.accept_requester_connects = false
	self.waypoint_chains = false
end

const.RocketMaxDrones = 999 --needs to be accounted for in resupply menu
function SupplyRocket:GetMaxDrones()
	return const.RocketMaxDrones
end

function SupplyRocket:OnWaypointStartGoto(drone, pos, next_pos)
	local z = pos:z()
	local a = z and (z - (next_pos:z() or z)) or 0
	if a ~= 0 then
		local b = pos:Dist2D(next_pos)
		local axis, angle = ComposeRotation(axis_y, atan(a, b), drone:GetAxis(), drone:GetAngle())
		drone:SetAxisAngle(axis, angle)
	else
		drone:SetAxis(axis_z)
	end
end

--override of leadin and leadout that don't use goto, so that Step(cpp) doesn't switch our axis
--mostly cpy paste from WaypointsObj
function SupplyRocket:LeadIn(unit)
	if unit.holder == self then return end
	unit:PushDestructor(function(unit)
		self:LeadOut(unit)
	end)		
	if IsKindOf(unit, "Drone") then
		table.insert(self.drones_entering, unit)
		unit:ClearGameFlags(const.gofSpecialOrientMode)
	end
	unit:PushDestructor(function(unit)
		-- uninterruptible code:
		if not IsValid(unit) then return end
		local entrance = self.waypoint_chains and self.waypoint_chains.rocket_entrance[1]
		if entrance then
			local open = entrance.openOutside
			local speed = unit:GetSpeed()
			local count = #entrance
			if unit:IsValidPos() then
				if unit:GetPos() ~= entrance[count] then
					unit:Goto(entrance[count]) --use goto to reach first pt
					if IsValid(self) and IsValid(unit) and unit:IsValidPos() then
						unit:Goto(entrance[count])
					end
				end
				if IsValid(self) and IsValid(unit) and unit:IsValidPos() then
					if IsKindOf(unit, "Drone") then
						for i = count - 1, 1, -1 do
							local p1 = entrance[i + 1]
							local p2 = entrance[i]
							unit:Face(p2)
							self:OnWaypointStartGoto(unit, p1, p2)
							local t = p1:Dist(p2) * 1000 / speed
							unit:SetPos(p2, t)
							Sleep(t)
							if not IsValid(self) or not unit:IsValidPos() then
								break
							end
						end
					else
						WaypointsObj.LeadIn(self, unit, entrance)
					end
				end
			end
		end
		if not IsValid(unit) then return end
		if IsValid(self) then
			unit:DetachFromMap()
			unit:SetHolder(self)
		end
		if IsKindOf(unit, "Drone") then
			table.remove_entry(self.drones_entering, unit)
			table.insert_unique(self.drones_exiting, unit)
			if IsValid(unit) then
				unit:SetGameFlags(const.gofSpecialOrientMode)
				unit:SetAxis(axis_z)
			end
			if self == SelectedObj and table.find(self.drones, unit) then
				SelectionArrowRemove(unit)
			end
		end
	end)
	unit:PopAndCallDestructor()
	unit:PopDestructor()
end

function SupplyRocket:DroneExitQueue(drone)
	RechargeStationBase.DroneExitQueue(self, drone)
	if not self.working and drone.holder == self then --since approach is hacked to lead in we have to leadout hackily as well
		self:LeadOut(drone)
	end
end

function SupplyRocket:LeadOut(unit)
	if IsKindOf(unit, "Drone") then
		if self.drone_charged == unit then
			self.drone_charged = false
			unit.force_go_home = true
		end
		if unit.command == "Embark" then --cant move in embark
			unit:SetCommand(false)
			while unit.command_destructors and unit.command_destructors[1] > 0 do --wait while unit's destructor cleans up
				Sleep(1)
			end
			
			unit.command_thread = CurrentThread() --hack, so that PopAndCallDestructor in Goto doesn't halt this thread.
		end
		table.insert_unique(self.drones_exiting, unit)
		unit:ClearGameFlags(const.gofSpecialOrientMode)
	end
	unit:PushDestructor(function(unit)
		-- uninterruptible code:
		if not IsValid(unit) then return end
		unit:SetState(unit:GetMoveAnim()) --fix for drones sometimes exiting in weird animation
		local entrance = self.waypoint_chains and self.waypoint_chains.rocket_exit[1]
		if entrance then
			local open = entrance.openInside
			unit:SetPos(entrance[1])
			local speed = unit:GetSpeed()
			for i = 2, #entrance do
				if not IsValid(self) or not IsValid(unit) then
					return
				end
				local p1 = entrance[i - 1]
				local p2 = entrance[i]
				unit:Face(p2)
				self:OnWaypointStartGoto(unit, p1, p2)
				local t = p1:Dist(p2) * 1000 / speed
				unit:SetPos(p2, t)
				Sleep(t)
			end
		end
		if IsValid(unit) then
			unit:SetHolder(false)
			self:OnExitUnit(unit)
		end
		if IsKindOf(unit, "Drone") then
			table.remove_entry(self.drones_exiting, unit)
			if IsValid(unit) then
				unit:SetGameFlags(const.gofSpecialOrientMode)
				unit:SetAxis(axis_z)
			end
			if self == SelectedObj and table.find(self.drones, unit) then
				SelectionArrowAdd(unit)
			end
		end
	end)
	unit:PopAndCallDestructor()
end

function SupplyRocket:PickArrivalPos(center, dir, max_radius, min_radius, max_angle, min_angle)
	min_radius = min_radius or 0
	
	if not dir or not center then
		local spot = self:GetSpotBeginIndex("Colonistout")
		local pos, angle = self:GetSpotLoc(spot)
		
		center = center or pos
		dir = dir or (pos - self:GetPos()):SetZ(0)
	end
	
	local mw, mh = terrain.GetMapSize()
	if center == InvalidPos() then
		center = point(mw / 2, mh / 2)
	end
	
	--DbgClearVectors()
	--DbgAddVector(center, dir, const.clrWhite)
	
	for j = 1, 25 do
		local r = SetLen(dir, Random(min_radius, max_radius))
		local v = Rotate(r, Random(min_angle, max_angle))
		local pt = v + center
		local x, y = pt:x(), pt:y()
		x = Clamp(x, guim, mw - guim)
		y = Clamp(y, guim, mh - guim)
		if terrain.IsPassable(x, y) then
			--DbgAddVector(center, v, const.clrGreen)
			local pos = point(x, y)
			return pos
		end
		--DbgAddVector(center, v, const.clrYellow)
	end
	return center
end

function SupplyRocket:SetCount()
	--intentionally empty.
end

function SupplyRocket:CreateResourceRequests()
	UniversalStorageDepot.CreateResourceRequests(self)
	
	--remove demand reqs (keep actual reqs so that everything works in unistorage)
	for k, v in pairs(self.demand) do
		table.remove_entry(self.task_requests, v)
	end
	--remove storage flags
	for k, v in pairs(self.supply) do
		v:ClearFlags(const.rfStorageDepot + const.rfPairWithHigher)
		v:AddFlags(const.rfPostInQueue)
	end
	
	local unit_count = 3 + (self.launch_fuel / (const.ResourceScale * 5)) --1 per 10
	self.refuel_request = self:AddDemandRequest("Fuel", self.launch_fuel, const.rfRestrictorRocket, unit_count)
	
	self:CreateExportRequests()
	
	--piggieback on this mehtod and init here
	self.drones_entering = {}
	self.drones_exiting = {}
end

function SupplyRocket:CreateExportRequests()
	if self.allow_export then
		local unit_count = 1 + (self.max_export_storage / (const.ResourceScale * 10)) --1 per 10
		self.export_requests = { self:AddDemandRequest("PreciousMetals", self.max_export_storage, 0, unit_count) }
	else
		self.export_requests = nil
	end	
end

function SupplyRocket:ResetDemandRequests()			
	if #self.command_centers > 0 then
		--reseting reqs with drones working on them may leave them in a broken state,
		--as far as i can tell this can be called from an old thread without passing countdown
		self:InterruptIncomingDronesAndDisconnect()
	end
	
	self.refuel_request:ResetAmount(self.launch_fuel)
	if self.unload_request then
		table.remove_entry(self.task_requests, self.unload_request)
		self.unload_request = nil
	end
	if self.unload_fuel_request then
		table.remove_entry(self.task_requests, self.unload_fuel_request)
		self.unload_fuel_request = nil
	end
	if self.allow_export then
		if self.export_requests then
			self.export_requests[1]:ResetAmount(self.max_export_storage)
		else
			local unit_count = 1 + (self.max_export_storage / (const.ResourceScale * 10)) --1 per 10
			self.export_requests = { self:AddDemandRequest("PreciousMetals", self.max_export_storage, 0, unit_count) }
		end
	else
		if self.export_requests then
			table.remove_entry(self.task_requests, self.export_requests[1])
		end
		self.export_requests = nil
	end
end

function SupplyRocket:GetStoredExportResourceAmount()
	if self.unload_request then
		return self.unload_request:GetActualAmount()
	end
	if not self.export_requests then
		return 0
	end
	return self.max_export_storage - self.export_requests[1]:GetActualAmount()
end

local special_cmd = {
	PickUp = true,
	Deliver = true,
	TransferResources = true,
	TransferAllResources = true,
	EmergencyPower = true,
}

function SupplyRocket:DroneApproach(drone, r)
	drone:ExitHolder(self)
	if not IsValid(self) then return end
	if special_cmd[drone.command] then
		if IsKindOf(drone, "Drone") then
			if drone:GotoBuildingSpot(self, self.drone_entry_spot) then
				if self.working then --lead in only if working, no need for drones to climb up to figure out that they have to climb down
					self:LeadIn(drone)
				end
				return true
			end
			return false
		else
			--cpy paste from wasterock droneapproach
			if not self:HasSpot("idle", drone.work_spot_task) then
				--some hacks so drones don't go into the rocks
				local r = 40 * guim --actual rocket rad is huge, so just use this for now
				local d_r = drone:GetRadius()
				local v = self:GetPos() - drone:GetPos()
				v = SetLen(Rotate(v, InteractionRand(360*60, "drone goto pos")), r + d_r)
				v = v + self:GetPos()
				return drone:Goto(v)
			else
				return drone:GotoBuildingSpot(self, drone.work_spot_task)
			end
		end
	else
		return drone:GotoBuildingSpot(self, drone.work_spot_task)
	end
end

function SupplyRocket:PlaceAdjacent(obj, def_pt, set_pos, move)
	local placement = self.placement	
	local radius = obj:HasMember("GetDestlockRadius") and obj:GetDestlockRadius() or obj:GetRadius()
	local target_pt
	local adjacent
	local my_rad = self:GetRadius()
	my_rad = my_rad * my_rad
	
	-- artificially increase the radius for a sparser placement
	radius = MulDivRound(radius, 150, 100)
	
	if #placement == 0 then
		-- no objects placed, pick the default pt
		target_pt = def_pt
		adjacent = {}
	elseif #placement == 1 then
		-- only one object placed, pick a point in the direction of default
		local dir = (def_pt - placement[1].center):SetZ(0)
		target_pt = placement[1].center + SetLen(dir, placement[1].radius + radius)
		adjacent = { 1 }
	else
		-- two or more objects: pick an object at random and one adjacent to it, then
		-- try the centers of the two circles touching the two picked ones (one on each side)
		
		local objs = table.copy(placement, "deep") -- code below modifies adjacency structures, using a copy
		local valid = {}
		
		-- build a list of indices of valid starting objecets
		for i = 1, #objs do 
			valid[i] = i
		end
		
		while not target_pt and #valid > 0 do
			local obj_idx, idx = table.rand(valid, InteractionRand("RocketUnload"))
			local obj = objs[obj_idx]
			if #obj.adjacent == 0 then
				-- obj is no longer a valid pick, remove from valid (not from objs, as it would invalidate adjacencies)
				table.remove(valid, idx)
			else
				local obj_idx2, idx2 = table.rand(obj.adjacent, InteractionRand("RocketUnload"))
				local obj2 = objs[obj_idx2]
				
				local d1 = obj.radius + obj2.radius
				local d2 = obj.radius + radius
				local d3 = obj2.radius + radius
				
				assert(d1 > 0 and d2 > 0 and d3 > 0)
				
				-- the centers of the 3 circles form a triangle with sides of length d1, d2 and d3
				-- calculate the angle at 'obj' using cosine theorem
				local cos_alpha = MulDivRound(4096, (-d3 * d3 + d1 * d1 + d2 * d2), (2 * d1 * d2)) -- scale 4096
				local angle = acos(cos_alpha)
				
				-- align a vector to the known side of the triangle, resize it to match the desired length
				local v = SetLen((obj2.center - obj.center):SetZ(0), d2)
				
				for i = 1, 2 do
					if not target_pt then
						-- rotate the vector using the calculated angle to get the 3rd point of the triangle
						target_pt = obj.center + Rotate(v, angle)
						-- check if valid
						if not terrain.IsPassable(target_pt) or target_pt:Dist2(self:GetPos()) < my_rad then --2 close 2 rocket or not passable.
							target_pt = false
						else							
							for j = 1, #placement do
								if j ~= obj_idx2 and j ~= obj_idx and placement[j].center:Dist2D(target_pt) < placement[j].radius + radius then
									--DbgAddCircle(target_pt, radius, const.clrRed)
									target_pt = false
									break
								end
							end
						end
					end
					
					if target_pt then
						assert(target_pt:Dist2D(obj.center) < d2 + 10*guic and target_pt:Dist2D(obj2.center) < d3 + 10*guic)
						break
					end
					
					-- invert angle and try placing on the opposite side
					angle = -angle
				end
						
				-- if both points aren't valid remove adjacency between obj and obj2 for this placement
				if not target_pt then
					table.remove_entry(obj.adjacent, obj_idx2)
					table.remove_entry(obj2.adjacent, obj_idx)
				else
					adjacent = { obj_idx, obj_idx2 }
				end
			end
		end
		
	end
	
	target_pt = (target_pt or def_pt):SetTerrainZ()
	adjacent = adjacent or ""
	
	placement[#placement + 1] = {
		--obj = obj,
		center = target_pt,
		x = target_pt:x(),
		y = target_pt:y(),
		radius = radius,
		adjacent = adjacent,
	}
	
	if move then
		Movable.Goto(obj, target_pt) -- Unit.Goto is a command, use this instead for direct control
	end
	if set_pos then
		obj:SetPos(target_pt)
	end
	
	--DbgAddCircle(target_pt, radius, const.clrGreen)
	
	for i = 1, #adjacent do
		local idx = adjacent[i]
		local tbl = placement[idx].adjacent
		tbl[#tbl + 1] = #placement
		
		--DbgAddVector(placement[idx].center, target_pt - placement[idx].center, const.clrBlue)
	end
	
	return target_pt
end

function SupplyRocket:OpenDoor()
	-- open bay door
	self:SetAnim(1, "disembarkStart")
	PlayFX("RocketDoorOpen", "start", self)
	Sleep(self:TimeToAnimEnd())
	self:SetAnim(1, "disembarkIdle")
	PlayFX("RocketDoorOpen", "end", self)
end

function SupplyRocket:CloseDoor()
	-- close bay door
	self:SetAnim(1, "disembarkEnd")
	PlayFX("RocketDoorClose", "start", self)
	Sleep(self:TimeToAnimEnd())
	self:SetAnim(1, "idle")
	PlayFX("RocketDoorClose", "end", self)
end

function SupplyRocket:SpawnDronesFromEarth()
	local idx = table.find(self.cargo, "class", "Drone")
	
	if idx then
		local number_of_carried_drones = self.cargo[idx].amount
		
		for i = 1, number_of_carried_drones do
			self:SpawnDrone()
		end
		
		self.cargo[idx].amount = 0
	end
end

function SupplyRocket:SpawnDrone()
	if #self.drones >= self:GetMaxDrones() then
		return
	end
	
	local drone = Drone:new{ city = self.city }
	drone:SetCommandCenter(self)
	
	local spawn_pos = self:GetSpotLoc(self:GetSpotBeginIndex(self.drone_spawn_spot))
	drone:SetPos(spawn_pos)
	CreateGameTimeThread(Drone.SetCommand, drone, "Embark")
end

--rovers attach to the door, so spawn and attach them before oppening it.
function SupplyRocket:SpawnRovers()
	local rovers = { transports = {} }
	local idx, n = 1, 1
	while n <= 2 and idx <= #(self.cargo or empty_table) do
		local item = self.cargo[idx]
		if n <= 2 and IsKindOf(g_Classes[item.class], "BaseRover") and item.amount > 0 then
			while item.amount > 0 do
				local rover = PlaceObject(item.class, {city = self.city, override_ui_status = "Disembarking"})
				rovers[#rovers + 1] = rover
				if item.class == "RCDesireTransport" then
					rovers.transports[#rovers.transports + 1] = rover
				end
				self:Attach(rover, self:GetSpotBeginIndex("Roverdock"..n))
				
				if n == 1 then
					rover:ClearGameFlags(const.gofSpecialOrientMode)
					n = n + 1
				end
				item.amount = item.amount - 1
			end
		else
			idx = idx + 1
		end
	end
	
	self.rovers = rovers
end

function SupplyRocket:FillTransports() --needs to happen after rover's game init (so default desires have booted)
	local transports = self.rovers.transports
	self.rovers.transports = nil
	
	--get only resources so we don't have to iterate for every rover
	local resources_cargo = {}
	for i = 1, #self.cargo do
		local item = self.cargo[i]
		if Resources[item.class] then
			resources_cargo[item.class] = item
		end
	end
	
	for i = 1, #transports do
		self:FillRCTransportFromCargo(transports[i], resources_cargo)
	end
end

function SupplyRocket:FillRCTransportFromCargo(rover, resources_cargo)
	for resource, amount in pairs(rover.desired_resource_levels) do
		if amount > 0 and resources_cargo[resource] and resources_cargo[resource].amount > 0 then
			local amount_to_add = Min(amount, resources_cargo[resource].amount * const.ResourceScale)
			rover:AddResource(amount_to_add, resource)
			resources_cargo[resource].amount = resources_cargo[resource].amount - (amount_to_add / const.ResourceScale)
		end
	end
end

function SupplyRocket:DroneUnloadResource(drone, request, resource, amount)
	drone:PushDestructor(function(drone)
		self:LeadOut(drone)
	end)
	drone:SetCarriedResource(false)
	UniversalStorageDepot.DroneUnloadResource(self, drone, request, resource, amount)
	if request == self.refuel_request then
		UICity:FuelForRocketRefuelingDelivered(amount)
		if self:HasEnoughFuelToLaunch() then
			Msg("RocketRefueled", self)
		end
	elseif self.command == "WaitLaunchOrder" and self:IsLaunchAutomated() and not self:HasCargoSpaceLeft() then
		self:SetCommand("Countdown")
	end
	RebuildInfopanel(self)
	drone:PopAndCallDestructor()
end

function SupplyRocket:DroneLoadResource(drone, request, resource, amount)
	if not drone then
		return UniversalStorageDepot.DroneLoadResource(self, drone, request, resource, amount, true)
	end
	drone:PushDestructor(function(drone)
		self:LeadOut(drone)
	end)
	UniversalStorageDepot.DroneLoadResource(self, drone, request, resource, amount, true)
	drone:SetCarriedResource(resource, amount) --hack
	RebuildInfopanel(self)
	drone:PopAndCallDestructor()
end

function SupplyRocket:GenerateArrivals(amount, applicants)
	if (amount or 0) <= 0 then
		return
	end
	
	self.disembarking = {}
	self.disembarking_confused = false
	
	local city = self.city
	local domes, safety_dome = GetDomesInWalkableDistance(city, self:GetPos())
	local free_space = {}
	for i = 1, amount do
		local applicant = table.remove(applicants)
		if not applicant then
			break
		end
		
		if city:IsTechResearched("SpaceRehabilitation") and city:Random(100) < TechDef.SpaceRehabilitation.param1 then
			for trait in pairs(applicant.traits) do
				local trait_def = DataInstances.Trait[trait]
				-- check trait_def: traits include nationality which doesn't have corresponding data instance
				if trait_def and trait_def.category == "Negative" then
					applicant.traits[trait] = nil
					break
				end
			end
		end
		
		local dome = ChooseDome(applicant.traits, domes, safety_dome, free_space)
		
		local space = free_space[dome] or 0
		if space > 0 then
			free_space[dome] = space - 1
		end
		
		applicant.dome = dome
		applicant.city = dome and dome.city or city
		
		local colonist = Colonist:new(applicant)
		self.disembarking[#self.disembarking + 1] = colonist
		colonist.arriving = self
		colonist:SetOutside(true)
		-- sleep to avoid all colonists disembarking at once
		Sleep(1000 + Random(0, 500))
	end
	
	while #self.disembarking > 0 do
		Sleep(100)
	end
	self.disembarking = nil
	
	AddOnScreenNotification("NewColonists", nil, {count = amount}, {self})
	if self.disembarking_confused then
		AddOnScreenNotification("ConfusedColonists", nil, {}, {self:GetPos()})
	end
end

function SupplyRocket:GenerateDepartures()
	if not self.can_fly_colonists or self.departures then -- for compatibility
		return
	end
	assert(self:IsValidPos())
	local domes = self.city.labels.Dome or ""
	self.departures = {}
	self.boarding = {}
	local list = {}
	for i = 1, #domes do
		local dome = domes[i]
		local tested, suitable
		for _, c in ipairs(IsValid(dome) and dome.labels.Colonist or empty_table) do
			if c:CanChangeCommand() and (c.status_effects.StatusEffect_Earthsick or (c.traits.Tourist and c.sols > 10)) then
				if not tested then
					suitable = IsInWalkingDist(self, dome, const.ColonistMaxDepartureRocketDist)
				end
				if suitable then
					list[#list + 1] = c
					c:SetCommand("LeavingMars", self)
				end
			end
		end
	end
	if #list > 0 then
		AddOnScreenNotification("LeavingMars", false, {colonists_count = #list}, list)
	end
end

function SupplyRocket:HasEnoughFuelToLaunch()
	return self.refuel_request:GetActualAmount() <= 0
end

function SupplyRocket:HasCargoSpaceLeft()
	for i = 1, #(self.export_requests or empty_table) do
		if self.export_requests[i]:GetActualAmount() > 0 then
			return true
		end
	end
end

function SupplyRocket:GetLaunchIssue()
	if g_Consts.SupplyMissionsEnabled ~= 1 then
		return "missions suspended"
	end

	if g_DustStorm then
		return "dust storm"
	end
	
	if self.command ~= "WaitLaunchOrder" and self.command ~= "Refuel" and self.command ~= "Unload" and self.command ~= "Countdown" then
		return "not landed"
	end
	
	if not self:HasEnoughFuelToLaunch() then
		return "fuel"
	end
	
	if self:GetStoredAmount() > 0 then
		return "cargo"
	end	
end

function SupplyRocket:UILaunch() -- blizzard promised no broadcast	
	if self:IsDemolishing() then
		self:ToggleDemolish()
	end
	
	local host = GetInGameInterface()
	local issue = self:GetLaunchIssue()
	
	if issue then
		if issue == "missions suspended" then
			ShowPopupNotification("LaunchIssue_MissionSuspended", false, false, host)
			return
		elseif issue == "dust storm" then
			ShowPopupNotification("LaunchIssue_DustStorm", false, false, host)
			return
		elseif issue == "not landed" then
			ShowPopupNotification("LaunchIssue_NotLanded", false, false, host)
			return
		elseif issue == "fuel" then
			ShowPopupNotification("LaunchIssue_Fuel", false, false, host)
			return
		elseif issue == "cargo" then	
			CreateRealTimeThread(function(rocket)
				local res = WaitPopupNotification("LaunchIssue_Cargo", {
						choice1 = T{8013, "Launch anyway (resources will be lost)."}, 
						choice2 = T{8014, "Abort the launch sequence."},
					}, false, host)
					
				if res and res == 1 then
					self:SetCommand("Countdown")
				end			
			end, self)
			return
		end
	end
	
	-- all ok
	self:SetCommand("Countdown")
end


function SupplyRocket:IsLaunchAutomated()
	return self.auto_export
end

function SupplyRocket:IsLandAutomated()
	return self.auto_export and IsValid(self.landing_site)
end

function SupplyRocket:IsBoardingAllowed()
	return self.command == "Refuel" or self.command == "WaitLaunchOrder" or (command == "Countdown" and self:IsCargoRampInUse())
end

function SupplyRocket:IsCargoRampInUse()
	return #(self.drones_exiting or empty_table) > 0 or 
			#(self.drones_entering or empty_table) > 0 or 
			#(self.boarding or empty_table) > 0
end

function SupplyRocket:IsFlightPermitted()
	return not g_DustStorm and g_Consts.SupplyMissionsEnabled == 1
end

function SupplyRocket:NeedsRefuel()
	return self.command == "Refuel"
end

function SupplyRocket:OnPassengersLost()
end

function SupplyRocket:GetSkins()
	if not self.can_change_skin then
		return empty_table
	end
	local trailblazer_entity = g_TrailblazerSkins[self.class]
	local entity = DataInstances.BuildingTemplate[self.template_name].entity
	if entity and trailblazer_entity then
		return { entity, trailblazer_entity }
	end
	return empty_table
end

-- ui getters
function SupplyRocket:GetRefuelProgress()
	return MulDivRound(self.launch_fuel - self.refuel_request:GetActualAmount(), 100, Max(1, self.launch_fuel))
end

function SupplyRocket:GetArrivalTimePercent()
	if not self.launch_time or (self.flight_time or 0) <= 0 then
		return 100
	end
	local t = GameTime() - self.launch_time
	return Min(100, MulDivRound(t, 100, self.flight_time))
end

function SupplyRocket:GetCargoManifest()
	if not self.cargo or #self.cargo == 0 then
		return T{720, "Nothing"}
	end
	
	local texts, resources = {}, {}
	
	for i = 1, #self.cargo do
		local item = self.cargo[i]
		if item.amount > 0 then
			if item.class == "Passengers" then
				texts[#texts + 1] = T{721, "<number> Passengers", number = item.amount}
			elseif Resources[item.class] then
				resources[#resources + 1] = T{722, "<resource(amount,res)>", amount = item.amount*const.ResourceScale, res = item.class}
			elseif DataInstances.BuildingTemplate[item.class] then
				local def = DataInstances.BuildingTemplate[item.class]
				local name = item.amount > 1 and def.display_name_pl or def.display_name
				texts[#texts + 1] = T{723, "<number> <name>", number = item.amount, name = name}
			else
				local def = g_Classes[item.class]
				texts[#texts + 1] = T{723, "<number> <name>", number = item.amount, name = def.display_name}
			end
		end
	end
	
	if #resources > 0 then
		texts[#texts + 1] = table.concat(resources, " ")
	end
	return table.concat(texts, "<newline>")	
end

function SupplyRocket:GetDisplayName()
	return Untranslated(self.name)
end

function SupplyRocket:GetUIOrbitTimeLeft()
	if not self.orbit_arrive_time then
		return ""
	end
	
	local ttd = (self.orbit_arrive_time + self.passenger_orbit_life - GameTime()) / const.HourDuration
	if ttd <= 0 then
		return T{8053, "< 1"}
	end	
	return ttd
end

function SupplyRocket:ApplyToGrids()
	--intentionally empty, rocket landing site applies/removes buildability for us
end

function SupplyRocket:RemoveFromGrids()
	--intentionally empty, rocket landing site applies/removes buildability for us
end

function SupplyRocket:CheatLaunch()
	self:SetCommand("Countdown")
end

function SupplyRocket:ToggleAutoExport()
	self.auto_export = not self.auto_export
	if not self.auto_export then -- can be disabled at any time
		if self.reserved_site then
			assert(IsValid(self.landing_site))
			DoneObject(self.landing_site)
			self.landing_site = nil
		end
		self.reserved_site = nil
	else -- can only be enabled when rocket is landed and has valid landing site
		assert(IsValid(self.landing_site))
		if self.command == "WaitLaunchOrder" then
			Wakeup(self.command_thread)
		end
	end
	if not self.auto_export and IsValid(self.site_particle) and self.status ~= "landing" then
		StopParticles(self.site_particle)
		if SelectedObj == self then
			SelectObj(false)
		end
	end
	ObjModified(self)
end

function SupplyRocket:ToggleAllowExport(broadcast)
	local allow = not self.allow_export
	
	if broadcast then
		local list = self.city.labels.SupplyRocket or empty_table
		for _, rocket in ipairs(list) do
			if rocket.allow_export ~= allow then
				rocket:ToggleAllowExport()
			end
		end
		return
	end
	
	self.allow_export = not self.allow_export
	
	if not self.allow_export and self.auto_export then
		self:ToggleAutoExport()
	end
	
	if self.command == "Refuel" or self.command == "WaitLaunchOrder" then
		if self.allow_export then
			-- cancel any remaining supply requests, interrupt drones, carry remaining supply to the new demand request
			self:InterruptDrones(nil, function(drone)
												if (drone.target == self) or 
													(drone.d_request and drone.d_request:GetBuilding() == self) or
													(drone.s_request and drone.s_request:GetBuilding() == self) then
													return drone
												end
											end)
			self:DisconnectFromCommandCenters()		
			
			-- create export request, transfer the remaining unload amount, close the unload request
			local stored = self.unload_request and self.unload_request:GetActualAmount() or 0
			
			local unit_count = 1 + (self.max_export_storage / (const.ResourceScale * 10)) --1 per 10
			self.export_requests = { self:AddDemandRequest("PreciousMetals", self.max_export_storage - stored, 0, unit_count) }
			if self.unload_request then
				table.remove_entry(self.task_requests, self.unload_request)
				self.unload_request = nil
			end
			
			self:ConnectToCommandCenters()
		else
			-- cancel demand request, interrupt drones, create supply request for the already stocked amount
			if self.export_requests and #self.export_requests > 0 then
				assert(#self.export_requests == 1)
				self:InterruptDrones(nil, function(drone)
													if (drone.target == self) or 
														(drone.d_request and drone.d_request:GetBuilding() == self) or
														(drone.s_request and drone.s_request:GetBuilding() == self) then
														return drone
													end
												end)
				
				self:DisconnectFromCommandCenters()
				-- create unload request, transfer the amount delivered, close the export request
				local amount = self:GetStoredExportResourceAmount()
				local unit_count = 1 + (self.max_export_storage / (const.ResourceScale * 10)) --1 per 10
				self.unload_request = self:AddSupplyRequest("PreciousMetals", amount, 0, unit_count)
				table.remove_entry(self.task_requests, self.export_requests[1])
				self.export_requests = nil
							
				self:ConnectToCommandCenters()
			end
		end
	end
	
	ObjModified(self)
end

function SupplyRocket:GetStoredAmount(resource)
	local stored = UniversalStorageDepot.GetStoredAmount(self, resource)
	if self.unload_request and (not resource or self.unload_request:GetResource() == resource) then
		stored = stored + self.unload_request:GetActualAmount()
	end
	return stored
end

function SupplyRocket:GetUIExportStatus()
	return T{286, "Gathering exports<right><preciousmetals(StoredExportResourceAmount, max_export_storage)>"}
end

function SupplyRocket:GetUIRocketStatus()
	if self.command == "FlyToMars" or self.command == "FlyToEarth" then
		return T{709, "In transit"}
	end
	if self.command == "LandOnMars" then
		return T{7897, "<green>Landing</green>"}
	end
	if self.command == "Unload" then
		return T{7898, "<green>Unloading cargo</green>"}
	end
	if self.exported_amount and self.command == "FlyToEarth" then
		return T{284, "<green>Exporting</green><right><preciousmetals(exported_amount, max_export_storage)>"}
	end
	local extra = self.unload_fuel_request and self.unload_fuel_request:GetActualAmount() or 0	
	local items = { 
		T{285, "Refueling<right><current>/<fuel(launch_fuel)>", current = (self.launch_fuel - self.refuel_request:GetActualAmount() + extra) / const.ResourceScale},
		self:GetUIExportStatus(),
	}
	
	if self.command == "Refuel" then
		items[#items+1] = T{7901, "<green>Waiting to refuel</green>"}
	elseif self.command == "WaitLaunchOrder" then	
		if self:GetStoredAmount() > 0 then
			items[#items+1] = T{7899, "<green>Waiting for resource unload</green>"}
		elseif self:IsLaunchAutomated() and self:HasCargoSpaceLeft() then
			items[#items+1] = T{8493, "Waiting cargo"}
		elseif self.departures and #self.departures > 0 then
			items[#items+1] = T{288, "<green>Waiting departures</green>"}
		else
			items[#items+1] = T{8033, "<green>Ready for take-off</green>"}
		end
	elseif self.command == "Countdown" then
		items[#items+1] = T{7900, "<green>Take-off in progress</green>"}
	elseif self.command == "Takeoff" then
		items[#items+1] = T{7900, "<green>Take-off in progress</green>"}
	end
	return table.concat(items, "<newline><left>")
end

function SupplyRocket:GetUILaunchStatus()
	if self.command == "FlyToMars" or self.command == "FlyToEarth" then
		return T{709, "In transit"}
	end
	if self.command == "LandOnMars" then
		return T{282, "Landing"}
	end
	if self.command == "Unload" then
		return T{283, "Unloading cargo"}
	end
	if self.command == "Countdown" or self.command == "Takeoff" then
		return T{289, "Take-off in progress"}
	end
	if self.command == "Refuel" then
		return T{7353, "Waiting to refuel"}
	end
	if self.command == "WaitLaunchOrder" and self:GetStoredAmount() > 0 then
		return T{287, "Waiting for resource unload"}
	end
	if self:IsLaunchAutomated() and self:HasCargoSpaceLeft() then
		return T{8493, "Waiting cargo"}
	end
	return T{8015, "Ready for take-off"}
end

function SupplyRocket:GetDronesCount()
	return #(self.drones or "")
end

local rocket_on_gnd_cmd = {
	LandOnMars = true,
	Unload = true,
	Refuel = true,
	WaitLaunchOrder = true,
	Countdown = true,
	Takeoff = true,
}

DefineClass.RocketLandingSite = {
	__parents = { "Building" },
	
	disable_selection = true,
	default_label = false,
	landing_pad = false,
}

function RocketLandingSite:GameInit()
	local attaches = self:GetAttaches() or ""
	for i = 1, #attaches do
		attaches[i]:ClearEnumFlags(const.efVisible)
	end
	
	local pads = UICity.labels.LandingPad or empty_table
	local on_pad = false
	local site_pos = self:GetPos()
	for _, pad in ipairs(pads) do
		if site_pos:Dist2D(pad:GetPos()) == 0 then
			self.landing_pad = pad
			break
		end
	end	
end

function RocketLandingSite:SelectionPropagate()
	local rocket = GetLandingRocket(self)
	assert(rocket)

	if rocket_on_gnd_cmd[rocket.command] then
		if IsValid(self.landing_pad) then
			return self.landing_pad
		end
		return rocket
	else
		if rocket.auto_export or not IsValid(self.landing_pad) then
			return rocket
		end
		return self.landing_pad
	end
end

DefineClass.LandingPad = {
	__parents = { "Building" },
}

function LandingPad:GameInit()
	self:DestroyAttaches("DecRocketLandingPlatformBuild")
	local obj = AttachToObject(self, "DecRocketLandingPlatform", "Pad")
	obj:SetAttachOffset(point(0, 0, 1000))
end

function LandingPad:InitConstruction(site)
	site:DestroyAttaches("DecRocketLandingPlatform")
	AttachToObject(site, "DecRocketLandingPlatformBuild", "Pad")
end

function LandingPad:OnDemolish()
	Building.OnDemolish(self)
	
	local rockets = UICity.labels.AllRockets or empty_table
	for _, rocket in ipairs(rockets) do
		if rocket.landing_site and rocket.landing_site.landing_pad == self then
			rocket.landing_site.landing_pad = nil
		end
	end
end

function LandingPad:CanDemolish()
	local rockets = UICity.labels.AllRockets or empty_table
	for _, rocket in ipairs(rockets) do
		if rocket.landing_site and rocket.landing_site.landing_pad == self and rocket_on_gnd_cmd[rocket.command] then
			return false
		end
	end
	
	return Building.CanDemolish(self)
end