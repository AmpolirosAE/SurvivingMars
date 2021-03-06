local stat_scale = const.Scale.Stat

DefineClass.Residence = {
	__parents = { "StatsChange", "Holder"},
	
	properties = {		
		{  template = true, modifiable = true, id = "capacity",        name = T{687, "Number of Residents"}, default = 5,  category = "Residence", editor = "number", min = 1 },
		{  template = true, modifiable = true, id = "rest_duration",   name = T{688, "Rest Duration"},         default = 7*const.HourDuration, category = "Residence", editor = "number", scale = "hours", },
		{  template = true, modifiable = true, id = "children_only",   name = T{689, "Children only"},         default = false, category = "Residence", editor = "bool", },
		{  template = true, modifiable = true, id = "sanity_increase", name = T{691, "Sanity recover per rest"}, default = 0, editor = "number", scale = "Stat", },			
	},
	colonists = false,  -- colonists arrays in this home
	reserved = false,  -- from emigrating colonsit waiting for the shuttle
	closed = 0,
}

function Residence:Init()
	self.colonists = {}
	self.reserved = {}
end
	
function Residence:GameInit()
	self.city:AddToLabel("Residence", self)
	self:CheckHomeForHomeless()
	
	if HintsEnabled then
		HintTrigger("HintPassengerRockets")
	end
	
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:Done()
	self.city:RemoveFromLabel("Residence", self)
	self:OnDestroyed()
end

function Residence:OnDestroyed()
	for i = #self.colonists, 1, -1 do
		local colonist = self.colonists[i]
		if IsValid(colonist) then
			colonist:SetResidence(false)
			colonist:UpdateResidence()
		end
	end
	self.colonists = {}
	for i = #self.reserved, 1, -1 do
		local colonist = self.reserved[i]
		if IsValid(colonist) then
			colonist.reserved_residence = false
		end
	end
	self.reserved = {}
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:AddResident(unit)
	if table.find(self.colonists, unit) then
		assert(false, "Already a resident!")
		return
	end
	unit:CancelResidenceReservation()
	assert(self:GetFreeSpace() > 0)
	self.colonists[#self.colonists+1] = unit
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:RemoveResident(unit)
	assert(not self.reserved[unit])
	table.remove_entry(self.colonists, unit)
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:ClosePositions(idx)
	local empty = self.capacity - #self.colonists	
	self.closed = Clamp(self.capacity - idx + 1, 0, empty)
	-- cancel reserved
	local reserved = #self.reserved
	local to_cancel = self.closed - (empty - reserved)
	if to_cancel>0 then
		for i = reserved, reserved-to_cancel+1, -1 do
			local unit = self.reserved[i]
			unit:CancelResidenceReservation()
			to_cancel = to_cancel - 1
			if to_cancel==0 then 
				break
			end	
		end
	end
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:OpenPositions(idx)
	self.closed = Clamp(self.capacity - idx, 0, self.capacity - #self.colonists)
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:KickResident(colonist, idx)
	colonist:SetResidence(false)
end

function Residence:CheckHomeForHomeless()
	local homeless = self.parent_dome and self.parent_dome.labels.Homeless or empty_table
	for i=#homeless,1,-1 do
		local colonist = homeless[i]
		if IsValid(colonist) then
			colonist:UpdateResidence()
		end	
	end
end

function Residence:SetUIWorking(working)
	Building.SetUIWorking(self, working)
	if working then
		if self.working then 
			self:CheckHomeForHomeless()
		end	
	else
		for i = #self.colonists, 1, -1 do
			local colonist = self.colonists[i]
			if IsValid(colonist) then			
				colonist:UpdateResidence()
				if colonist.residence ~= self and colonist.holder == self then					
					colonist:SetCommand("ExitBuilding", self)					
				end
			end
		end	
	end
	RebuildInfopanel()
end

function Residence:IsSuitable(colonist)
	return not self.children_only or colonist.traits.Child
end

Residence.CheckHomeForHomless = Residence.CheckHomeForHomeless

function Residence:SetDome(dome)
	if self.parent_dome then
		self.parent_dome:RemoveFromLabel("Residence", self)
	end
	
	Building.SetDome(self, dome)
	
	if dome then
		self.parent_dome:AddToLabel("Residence", self)
		self:CheckHomeForHomeless()
	end	
end

function Residence:OnSelected()
	SelectionArrowAdd(self.colonists)
end

function Residence:GetFreeSpace()
	return self.capacity - self.closed - (#self.reserved + #self.colonists)
end

function Residence:OnModifiableValueChanged(prop)
	if prop == "capacity" and self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end


function Residence:CanReserveResidence(unit)
	if self.children_only and not unit.traits.Child then
		return false
	end
	return self.reserved[unit] or self:GetFreeSpace() > 0
end

function Residence:ReserveResidence(unit)
	if self.reserved[unit] then
		return true
	end
	if self:CanReserveResidence(unit) then
		unit:CancelResidenceReservation()
		assert(self:GetFreeSpace() > 0)
		table.insert(self.reserved, unit)
		self.reserved[unit] = true
		unit.reserved_residence = self
		if self.parent_dome then
			self.parent_dome:RecalcFreeSpace()
		end
		return true
	end
	return false
end

function Residence:ColonistCanInteract(col)
	if self.children_only and not col.traits.Child then
		return false, T{4306, "<red>Building accepts only children</red>"}
	end
	if self == col.residence then
		return false, T{4307, "Current Residence"}
	end
	if not col:CanReachBuilding(self) then
		return false, T{4308, "<red>Out of reach</red>"}
	end
	return true, T{4309, "<em><left_click></em>: Set Residence"}
end

function Residence:ColonistInteract(col)
	if col.residence == self then return end
	if self.children_only and not col.traits.Child then return end
	if col.user_forced_residence and col.user_forced_residence[1] == self then return end --setting same residence
	if col.user_forced_residence and IsValid(col.user_forced_residence[1]) then
		--cancel reservation
		col.user_forced_residence[1]:CancelResidenceReservation(col)
	end
	
	col.user_forced_residence = {self, GameTime()}

	if not self:CanReserveResidence(col) then
		--design - kick oldest resident.
		self:KickOldestResident()
	end
	if self.parent_dome == col.dome then
		col:SetResidence(self)
	else
		assert(self.parent_dome, "Residence outside of a dome")
		self:ReserveResidence(col)
		col:SetForcedDome(self.parent_dome)
	end
	return true
end

function Residence:KickOldestResident()
	--local greatest_age = 0
	local oldest_resident = false
	
	for i = 1, #self.colonists do
		local colo = self.colonists[i]
		if not oldest_resident or oldest_resident.age < colo.age then
			oldest_resident = colo
		end
	end
	
	if oldest_resident then
		self:KickResident(oldest_resident)
	else
		--we found nooone to kick out!
		--check reservations
		for _, colo in ipairs(self.reserved) do
			if not oldest_resident or oldest_resident.age < colo.age then
				oldest_resident = colo
			end
		end
		
		if oldest_resident then
			self:CancelResidenceReservation(oldest_resident)
		end
	end
end

function Residence:CancelResidenceReservation(unit)
	if not self.reserved[unit] then
		return
	end
	table.remove_entry(self.reserved, unit)
	self.reserved[unit] = nil
	if self.parent_dome then
		self.parent_dome:RecalcFreeSpace()
	end
end

function Residence:Service(unit, duration)
  if unit.traits.Introvert and  unit.dome and #unit.dome.labels.Colonist>30 then -- Loner
		unit:ChangeComfort(-4*stat_scale, "Loner")
	end
	StatsChange.Service(self, unit, duration, "rest")
end

function Residence:GetUICapacity()
	return self.capacity - self.closed
end

function Residence:GetUIResidentsCount()
	return #self.colonists
end

local function GetResidenceComfort(residence, is_child)
	local valid = IsValid(residence) and not residence.destroyed and not residence.demolishing
	if not valid then
		return
	end
	local score = residence.service_comfort 
	if residence.children_only then
		return is_child and score * 2
	end
	return score
end

--Choose 'best' Residence for that unit
function ChooseResidence(unit)	
	local is_child = unit.traits["Child"]
	local current_home = unit.residence
	local max_score
	local dome = unit.dome
	local current_score = current_home and current_home.parent_dome == dome and GetResidenceComfort(current_home, is_child)
	local best_building = false
	local buildings = dome and dome.labels.Residence or unit.city.labels.Residence or empty_table
	for i = 1, #buildings do
		local home = buildings[i]
		local score = home:GetFreeSpace() > 0 and GetResidenceComfort(home, is_child)
		if score then
			if best_building then
				local best_working = best_building.ui_working
				local home_working = home.ui_working
				if not best_working and home_working then
					max_score = score
					best_building = home				
				elseif best_working and home_working then	
					if max_score < score or (max_score == score and Random(0, 100)<50 ) then
						max_score = score
						best_building = home
					end
				--elseif best_working and not home_working then
				-- does not change	
				end
			elseif (not max_score or max_score < score) or (max_score == score  and Random(0, 100)<50 ) then
				max_score = score
				best_building = home
			end
		end	
	end
	if not max_score or (current_score and current_score >= max_score) then
		if current_home and current_home.ui_working or (best_building and not best_building.ui_working) then
			return current_home
		end
	end
	return best_building
end

local l_TemplateSkinRadius = {}

DefineClass.TemplateSkinResidence =
{
	__parents = {"CObject"},
}

function TemplateSkinResidence:GetRadius()
	return l_TemplateSkinRadius[self:GetEntity()] or CObject.GetRadius(self)
end

local function CalcTemplateSkinRadiuses()
	local hex_size = point(const.HexSize, const.HexSize)
	local classes = ClassLeafDescendantsList("TemplateSkinResidence")
	for _, class in ipairs(classes) do
		local skins = GetBuildingSkins(class)
		for _, skin in ipairs(skins) do
			local outline_hexes = GetEntityOutlineShape(skin)			
			local bbox = box(0, 0, 0, 0)
			for _, outline_hex in ipairs(outline_hexes) do
				local center = point(HexToWorld(outline_hex:xy()))
				bbox = Extend(bbox, center + hex_size)
				bbox = Extend(bbox, center - hex_size)
			end
			l_TemplateSkinRadius[skin] = bbox:min():Dist(bbox:max()) / 2
		end
	end
end

OnMsg.HexShapesRebuilt = CalcTemplateSkinRadiuses

function OnMsg.ClassesBuilt()
	if DataInstances.BuildingTemplate then
		CalcTemplateSkinRadiuses()
	end
end

DefineClass.LivingBase =
{
	__parents = { "ElectricityConsumer", "Residence", "TemplateSkinResidence" },
	living_attaches = false,
}

DefineClass("LivingQuartersHouseBase", "WaypointsObj")
--DefineClass("LivingQuartersHouse_01", "LivingQuartersHouseBase")
--DefineClass("LivingQuartersHouse_02", "LivingQuartersHouseBase")
--DefineClass("SmartHomeHouse_01", "LivingQuartersHouseBase")
--DefineClass("SmartHomeHouse_02", "LivingQuartersHouseBase")

DefineClass.LivingQuarters = {
	__parents = { "LivingBase", "InteriorAmbientLife" },
	enum_flags = { efWalkable = true },
	interior = {"LivingQuartersInterior_01", "LivingQuartersInterior_02"},
	living_attaches = { "LivingQuartersHouse_01", "LivingQuartersHouse_02" },
}

DefineClass.Apartments = {
	__parents = { "LivingBase" , "WaypointsObj"},
	enum_flags = { efWalkable = true },
}

DefineClass.SmartHome = {
	__parents = { "LivingBase" },
	enum_flags = { efWalkable = true },
	living_attaches = { "SmartHomeHouse_01", "SmartHomeHouse_02" },
}


function SmartHome:GetBroadcastLabel()
	return self.class --so small and big smart homes get broadcasted to together.
end

DefineClass.Nursery = {
	__parents = { "LivingBase", "WaypointsObj" },
	enum_flags = { efWalkable = true },
}
