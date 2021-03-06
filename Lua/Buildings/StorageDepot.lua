DefineClass.StorageDepot = {
	__parents = { "Building", "ResourceStockpileBase", "ShuttleLanding", "AutoTransportStateUIProps", },
	game_flags = { gofPermanent = true },

	properties = {
		-- add dont_save specifically for this class, as it has a Get function 
		{ template = true, name = T{765, "Pin Rollover"}, id = "pin_rollover", category = "Pin",  editor = "text", default = "", translate = true, dont_save = true},
		{ template = true, category = "Demolish", name = T{175, "Use demolished state?"}, id = "use_demolished_state", editor = "bool", default = false, object_update = true },
		{ template = true, category = "Storage Space", name = T{8054, "Ignored by shuttles"}, id = "exclude_from_lr_transportation", editor = "bool", default = false },
	},
	entity = false,

	description = false,
	display_name = false,
	GetDisplayName = Building.GetDisplayName,
	
	max_x = 12,
	max_y = 5,
	max_z = 5,
	
	spacing_x = 13*guic,
	spacing_y = 16*guic,
	spacing_z = 1*guic,
	
	demand = false,
	supply = false,

	has_demand_request = false,
	has_supply_request = false,
	
	GetShapePoints = GridObject.GetShapePoints,
	
	auto_transportation_state = "Auto",
	
	--Storage depots do not accumulate dust (bug:0118697)
	accumulate_dust = false,
	maintenance_resource_type = "no_maintenance", --doesnt require maintenance.
	accumulate_maintenance_points = false,
	
	landing_spot_name = "Workshuttle",
	prio_button = false,
	on_off_button = false,
	min_threshold_amount = 0,
	
	OnCommandCenterWorkingChanged = Building.OnCommandCenterWorkingChanged,
	OnAddedByControl = Building.OnAddedByControl,
	OnRemovedByControl = Building.OnRemovedByControl,
}

function StorageDepot:GameInit()
	if not self.exclude_from_lr_transportation then
		LRManagerInstance:AddBuilding(self)
	end
end

function StorageDepot:AddToCityLabels()
	Building.AddToCityLabels(self)
end

function StorageDepot:SetResourceAutoTransportationState(resource, state)
	self.auto_transportation_state = state
end

function StorageDepot:CreateResourceRequests()
	Building.CreateResourceRequests(self)
	self.demand = {}
	self.supply = {}
	for _, resource_name in ipairs(AllResourcesList) do
		local max_name = "max_amount_"..resource_name
		if self:HasMember(max_name) then
			local demand = self:AddDemandRequest(resource_name, self[max_name], const.rfStorageDepot)
			local supply = self:AddSupplyRequest(resource_name, 0, const.rfStorageDepot + const.rfPairWithHigher)
			self.demand[resource_name] = demand
			self.supply[resource_name] = supply
		
			self["GetStored_"..resource_name]=  function(self)
				return self.supply[resource_name]:GetActualAmount()
			end
			self["GetMaxAmount_"..resource_name]= function(self)
				return self[max_name]
			end
		end
	end
end

function StorageDepot:AddDepotResource(resource, amount)
	self.supply[resource]:AddAmount(amount)
	self.demand[resource]:AddAmount(-amount)
	self:SetCount(self.supply[resource]:GetActualAmount())
end

StorageDepot.AddResource = StorageDepot.AddDepotResource

function StorageDepot:DroneLoadResource(drone, request, resource, amount)
	if self.supply[resource] == request then
		self.demand[resource]:AddAmount(amount)
		self:SetCount(self.supply[resource]:GetActualAmount())
	end
end

function StorageDepot:DroneUnloadResource(drone, request, resource, amount)
	Building.DroneUnloadResource(self, drone, request, resource, amount)
	if self.demand[resource] == request then
		self.supply[resource]:AddAmount(amount)
		self:SetCount(self.supply[resource]:GetActualAmount())
	end
end

function StorageDepot:InitInside(dome)
	Building.InitInside(self, dome)
	ResourceStockpileBase.InitInside(self, dome)
end

function StorageDepot:InitOutside()
	Building.InitOutside(self)
	ResourceStockpileBase.InitOutside(self)
end

StorageDepot.MoveInside = Building.MoveInside

function StorageDepot:ReturnStockpiledResources()
	local pos = self:GetVisualPos()
	if pos ~= InvalidPos() then
		for resource_flag, request in pairs(self.supply) do
			local amount = request:GetActualAmount()
			if amount > 0 then
				PlaceResourceStockpile_Delayed(pos, resource_flag, amount, self:GetAngle(), true)
			end
		end
	end
	
	self:ClearAllResources()
end

function StorageDepot:Done() --should this be in building::returnresources?
	if not self.exclude_from_lr_transportation then
		LRManagerInstance:RemoveBuilding(self)
	end
	self:ReturnStockpiledResources()
end

function StorageDepot:RoverWork(rover, request, resource, amount, reciprocal_req, interaction_type, total_amount)
	Building.RoverWork(self, rover, request, resource, amount)
	if resource ~= "clean" and resource ~= "repair" then
		--temp presentation
		rover:ContinuousTask(request, amount, "gatherStart", "gatherIdle", "gatherEnd",
		interaction_type == "load" and "Load" or "Unload",	"step", g_Consts.RCRoverTransferResourceWorkTime, "add resource", reciprocal_req, total_amount)
	end
end

function StorageDepot:CheatFill() 
	local resource = self.resource
	if self.supply[resource] then
		local max_name = "max_amount_"..resource
		self.supply[resource]:SetAmount(self[max_name])
		self.demand[resource]:SetAmount(0)
	end
	self:SetCount(self.supply[resource]:GetActualAmount())
end

function StorageDepot:CheatEmpty() 
	local resource = self.resource
	if self.supply[resource] then
		local max_name = "max_amount_"..resource
		self.supply[resource]:SetAmount(0)
		self.demand[resource]:SetAmount(self[max_name])
	end
	self:SetCount(self.supply[resource]:GetActualAmount())
end

function StorageDepot:GetStoredAmount(resource)
	local req = not resource and self.supply[next(self.supply)] or self.supply[resource]
	return req and req:GetActualAmount() or 0
end

function StorageDepot:GetEmptyStorage(resource)
	local request = self.demand[resource]
	return request and request:GetActualAmount() or 0
end

function StorageDepot:GetTargetEmptyStorage(resource)
	local request = self.demand[resource]
	return request and request:GetTargetAmount() or 0
end

function StorageDepot:Getui_Concrete() return T{766, "Concrete<right><concrete(Stored_Concrete,MaxAmount_Concrete)>", self} end
function StorageDepot:Getui_Metals() return T{767, "Metals<right><metals(Stored_Metals,MaxAmount_Metals)>", self} end
function StorageDepot:Getui_Polymers() return T{768, "Polymers<right><polymers(Stored_Polymers,MaxAmount_Polymers)>", self} end
function StorageDepot:Getui_Food() return T{769, "Food<right><food(Stored_Food,MaxAmount_Food)>", self} end
function StorageDepot:Getui_Electronics() return T{770, "Electronics<right><electronics(Stored_Electronics,MaxAmount_Electronics)>", self} end
function StorageDepot:Getui_MachineParts() return T{771, "Machine Parts<right><machineparts(Stored_MachineParts,MaxAmount_MachineParts)>", self} end
function StorageDepot:Getui_PreciousMetals() return T{772, "Rare Metals<right><preciousmetals(Stored_PreciousMetals,MaxAmount_PreciousMetals)>", self} end
function StorageDepot:Getui_Fuel() return T{773, "Fuel<right><fuel(Stored_Fuel,MaxAmount_Fuel)>", self} end

DefineClass.UniversalStorageDepot = {
	__parents = { "StorageDepot" },
	properties = {
		{ template = true, name = T{774, "Max Storage Per Resource"},  category = "Storage Space", id = "max_storage_per_resource",  editor = "number", default = 30000, scale = const.ResourceScale },
		{ template = true, name = T{775, "Max Boxes On The X Axis"}, category = "Storage Space", id = "max_x", editor = "number", default = 2, help = "Max amount of boxes per axis, for multiple resources its per resource type."},
		{ template = true, name = T{7626, "Max Boxes On The Y Axis"}, category = "Storage Space", id = "max_y", editor = "number", default = 5, help = "Max amount of boxes per axis, for multiple resources its per resource type." },
		{ template = true, name = T{7627, "Max Boxes On The Z Axis"}, category = "Storage Space", id = "max_z", editor = "number", default = 3, help = "Max amount of boxes per axis, for multiple resources its per resource type." },
		{ template = true, name = T{776, "Storable Resources"}, category = "Storage Space", id = "storable_resources", editor = "table", default = {"Concrete",  "Food", "Metals", "PreciousMetals","Polymers","Electronics", "MachineParts", "Fuel"}, help = "The type of resources this depot can store."},
		{ template = true, name = T{777, "Switch Fill Order"}, category = "Storage Space", id = "switch_fill_order", editor = "bool", default = true, help = "When true will fill in x of the spot dir first then y, the opposite when false."},
		{ template = true, name = T{7770, "Fill Group Idx"}, category = "Storage Space", id = "fill_group_idx", editor = "number", default = 5, help = "When true will fill in x of the spot dir first then y, the opposite when false."},
		
		{ id = "StoredAmount", editor = false },
		{ id = "stockpiled_amount", editor = "number", default = false, no_edit = true },
	},
	
	visual_cubes = false, --helper, to distinguish cube resource types
	auto_transportation_states = false,
	
	supply_r_flags = const.rfStorageDepot,
	demand_r_flags = const.rfStorageDepot + const.rfSpecialSupplyPairing,
	
	has_demand_request = true,
	has_supply_request = true,
	
	interest1 = false,
	interest2 = false,
	interest3 = false,
	interest4 = false,
	
	placed_cubes = false,
	counters = false,
}

function UniversalStorageDepot:Init()
	self.placement_offset = {}
end
	
function UniversalStorageDepot:GameInit()
	local len = #self.storable_resources
	for i = 1, len do
		local resource_name = self.storable_resources[i]
		local s_name = "Box" .. i
		if not self:HasSpot(s_name) and len == 1 and self:HasSpot("Box") then
			s_name = "Box"
		end
		
		self.placement_offset[resource_name] = GetEntitySpotPos(self:GetEntity(), self:GetSpotBeginIndex(s_name))
		
		local amount = (self.stockpiled_amount[resource_name] or 0)
		self:SetCount(amount, resource_name)
	end
	
	self.resource = self.storable_resources
	
	if self.class == "UniversalStorageDepot" then
		HintDisable("HintStorageDepot")
	end
end

function UniversalStorageDepot:SetCount(new_count, resource)
	new_count = Clamp(new_count, 0, self.max_storage_per_resource)
	new_count = new_count / const.ResourceScale
	resource = resource or self.resource[1]
	local placed_cubes = self.visual_cubes[resource]
	local counters = self.counters or {}
	local count = counters[resource] or #placed_cubes
	if count == new_count then
		return
	end
	counters[resource] = new_count
	self.counters = counters
	return self:SetCountInternal(new_count, count, resource, placed_cubes, self.placement_offset[resource], -90*60, 0)
end

function UniversalStorageDepot:CreateResourceRequests()
	Building.CreateResourceRequests(self)
	local storable_resources = self.storable_resources
	assert(storable_resources, "Shared Storage Depot cannot initialize properly!")
	self.demand = {}
	self.supply = {}
	self.visual_cubes = { }
	self.auto_transportation_states = {}
	self.stockpiled_amount = self.stockpiled_amount or {}
	local total_stored = 0
	
	for i = 1, #storable_resources do
		local resource_name = storable_resources[i]
		
		local amount = (self.stockpiled_amount[resource_name] or 0)
		local supply = self:AddSupplyRequest(resource_name, amount, bor(self.supply_r_flags, self.additional_supply_flags))
		local demand = self:AddDemandRequest(resource_name, self.max_storage_per_resource - amount, self.demand_r_flags + self.additional_demand_flags)
		self.supply[resource_name] = supply
		self.demand[resource_name] = demand
		self.auto_transportation_states[resource_name] = ResourceStates[1]
		self.visual_cubes[resource_name] = {} --use name as key, in case we need the arr part of the table for something clever
		total_stored = total_stored + amount
		
		
		self["GetStored_"..resource_name]=  function(self)
			return self.supply[resource_name]:GetActualAmount()
		end
		
		self["GetMaxAmount_"..resource_name] = function(self)
			return self.max_storage_per_resource
		end
	end
end

function UniversalStorageDepot:GetMaxStorage(resource)
	if resource then
		return self["GetMaxAmount_"..resource](self)
	else
		return #self.storable_resources * self.max_storage_per_resource
	end
end

--cpy paste from SharedStorageBaseVisualOnly
function UniversalStorageDepot:GetStoredAmount(resource)
	if resource then
		return self.stockpiled_amount[resource] or 0
	else
		local total = 0
		for k, v in pairs(self.stockpiled_amount) do
			total = total + v
		end
		
		return total
	end
end
function UniversalStorageDepot:IsFull()
	return self:GetStoredAmount()>=self:GetMaxStorage()
end

function UniversalStorageDepot:SetResourceAutoTransportationState(resource, state)
	self.auto_transportation_states[resource] = state
end

function UniversalStorageDepot:AddResource(amount, resource)
	self.supply[resource]:AddAmount(amount)
	self.demand[resource]:AddAmount(-amount)
	
	self.stockpiled_amount[resource] = (self.stockpiled_amount[resource] or 0) + amount
	self:SetCount(self.supply[resource]:GetActualAmount(), resource)
	RebuildInfopanel(self)
end

UniversalStorageDepot.AddDepotResource = UniversalStorageDepot.AddResource
UniversalStorageDepot.AddResourceAmount = UniversalStorageDepot.AddResource
UniversalStorageDepot.SetResourceAmount = false --not impl.
UniversalStorageDepot.SetCountFromRequest = false --not impl.

function UniversalStorageDepot:DroneLoadResource(drone, request, resource, amount, skip_presentation)
	if self.supply[resource] == request then
		if not skip_presentation then
			--presentation
			drone:Face(self:GetPos(), 100)
			drone:StartFX("Pickup", resource) --resource to string
			drone:SetState("interact")
			Sleep(500)
			drone:StopFX()
			if not IsValid(self) or not IsValid(drone) then
				return
			end
		end
		--not presentation
		self.demand[resource]:AddAmount(amount)
		self.stockpiled_amount[resource] = self.stockpiled_amount[resource] - amount
		self:SetCount(self.supply[resource]:GetActualAmount(), resource)
		RebuildInfopanel(self)
	end
end

function UniversalStorageDepot:DroneUnloadResource(drone, request, resource, amount)
	Building.DroneUnloadResource(self, drone, request, resource, amount)
	if self.demand[resource] == request then
		self.supply[resource]:AddAmount(amount)
		self.stockpiled_amount[resource] = (self.stockpiled_amount[resource] or 0) + amount
		self:SetCount(self.supply[resource]:GetActualAmount(), resource)
		RebuildInfopanel(self)
	end
end

function UniversalStorageDepot:IsResourceEnabled(res_id)
	local req = self.demand[res_id]
	assert(req)
	return table.find(self.task_requests, req)
end

function UniversalStorageDepot:ToggleAcceptResource(res_id)
	if not IsValid(self) then return end
	local req = self.demand[res_id]
	local s_req = self.supply[res_id]
	assert(req)
	local task_requests = self.task_requests
	if not self.exclude_from_lr_transportation then
		LRManagerInstance:RemoveBuilding(self)
	end
	if table.find(task_requests, req) then
		self:InterruptDrones(nil,function(drone) return drone.d_request==req and drone end)
		self:DisconnectFromCommandCenters()
		table.remove_entry(self.task_requests, req)
		s_req:AddFlags(const.rfPostInQueue)
		s_req:ClearFlags(const.rfStorageDepot)
	else
		self:DisconnectFromCommandCenters()
		table.insert(self.task_requests, req)
		s_req:ClearFlags(const.rfPostInQueue)
		s_req:AddFlags(const.rfStorageDepot)
	end
	if not self.exclude_from_lr_transportation then
		LRManagerInstance:AddBuilding(self)
	end	
	self:ConnectToCommandCenters()
end

function UniversalStorageDepot:GetIPTextColor(res_id)
	return self:IsResourceEnabled(res_id) and RGBA(233, 242, 255, 255) or RGBA(255, 69, 38, 255)
end

function OpenBaseResourcesSelector(context, idx, ctrl)
	context.resources_type = "base"
	OpenInfopanelItems(context, ctrl)
end

function OpenAdvancedResourcesSelector(context, idx, ctrl)
	context.resources_type = "advance"
	OpenInfopanelItems(context, ctrl)
end

function UniversalStorageDepot:CheatFill()
	local storable_resources = self.storable_resources
	local resource_count = #storable_resources
	
	self:InterruptDrones(nil, function(drone)
										local r = drone.d_request
										if r then
											if self.demand[r:GetResource()] == r then
												return drone
											end
										end
									end)
	
	for i = 1, resource_count do
		local resource_name = storable_resources[i]
		
		if self.supply[resource_name] then
			local a = self.demand[resource_name]:GetActualAmount()
			self:AddResource(a, resource_name)
		end
	end
end

function UniversalStorageDepot:ClearAllResources()
	local storable_resources = self.storable_resources
	local resource_count = #storable_resources
	
	for i = 1, resource_count do
		local resource_name = storable_resources[i]
		
		if self.supply[resource_name] then
			self.supply[resource_name]:SetAmount(0)
			self.demand[resource_name]:SetAmount(self.max_storage_per_resource)
			self.stockpiled_amount[resource_name] = 0
			self:SetCount(0, resource_name)
		end
	end
end

UniversalStorageDepot.CheatEmpty = UniversalStorageDepot.ClearAllResources

function UniversalStorageDepot:GetEmptyStorage(resource)
	if not resource then
		return self:GetMaxStorage() - self:GetStoredAmount()
	else
		return	self.demand[resource]:GetActualAmount()
	end
end

function UniversalStorageDepot:TestReqConsistency()
	for resource, s_req in pairs(self.supply) do
		local total = self:GetMaxStorage(resource)
		--assert(s_req:GetActualAmount() + self.demand[resource]:GetActualAmount() == total)
		
		if s_req:GetActualAmount() + self.demand[resource]:GetActualAmount() ~= total then
			self:SetColorModifier(RGBA(255,0,0,0))
			return false
		end
	end
	
	return true
end

function dbg_TestMapDepots()
	ForEach{class = "UniversalStorageDepot", area = "realm", exec = function(o) o:TestReqConsistency() end, }
end

DefineClass.MysteryDepot = {
	__parents = { "UniversalStorageDepot" },
}

function MysteryDepot:GetDisplayName()
	return MysteryDepot.Getdisplay_name(self)
end

function MysteryDepot:GetDescription()
	return MysteryDepot.Getdescription(self)
end

function MysteryDepot:GetIPDescription()
	return MysteryDepot.Getdescription(self)
end

function MysteryDepot:Getdescription()
	local m = UICity and UICity.mystery or MysteryBase
	return m.depot_description
end

function MysteryDepot:Getdisplay_name()
	local m = UICity and UICity.mystery or MysteryBase
	return m.depot_display_name
end

function MysteryDepot:Getdisplay_name_pl()
	local m = UICity and UICity.mystery or MysteryBase
	return m.depot_display_name_pl
end


--------------------------------------------
--------------------------------------------
DefineClass.MechanizedDepot = {
	__parents = { "Building", "StockpileController", "ResourceStockpileBase", "ElectricityConsumer" },
	
	properties = {
		{ template = true, name = T{776, "Storable Resources"}, category = "Storage Space", id = "storable_resources", editor = "table", default = {"Concrete",  "Food", "Metals", "PreciousMetals","Polymers","Electronics", "MachineParts", "Fuel"}, help = "The type of resources this depot can store."},
		{ template = true, name = T{774, "Max Storage Per Resource"},  category = "Storage Space", id = "max_storage_per_resource",  editor = "number", default = 30000, scale = const.ResourceScale },
	},
	
	stock_lanes = false,
	
	entity = false,
	has_supply_request = false,
	has_demand_request = false,
	stockpiled_resource = "Metals",
	stockpiled_amount = 0,
	
	max_x = 5, max_y = 26, max_z = 3,
	
	stockpile_spots = {"Inputpile"},
	stockpile_class = "ResourceStockpileLR",
	
	additional_stockpile_params = {
		additional_supply_flags = const.rfStorageDepot + const.rfMechanizedStorage,
		additional_demand_flags = const.rfStorageDepot + const.rfMechanizedStorage,
		has_supply_request = true,
		has_demand_request = true,
		min_threshold_amount = 0,
		max_x = 5, max_y = 2, max_z = 5,
	},
	
	is_storing = false,
	carrying = false, --if the hoist is carrying resource at this moment
	
	display_name = false,
	description = false,
	GetDisplayName = Building.GetDisplayName,
	GetShapePoints = GridObject.GetShapePoints,
	OnCommandCenterWorkingChanged = Building.OnCommandCenterWorkingChanged,
	OnRemovedByControl = Building.OnRemovedByControl,
	OnAddedByControl = Building.OnAddedByControl,
	InitOutside = Building.InitOutside,
	InitInside = Building.InitInside,
	GetStoredAmount = ResourceStockpileBase.GetStoredAmount,
	
	crane = false,
	pillars = false,
	beam = false,
	hoist = false,
	pillars_org_pos = false,
	beam_org_pos = false,
	hoist_org_pos = false,
	hoist_curr_pos = false,
	carried_cubes = false,
	
	--this is the function the will be called after the animation ends (see cheats)
	func_after_anim_end = false,
}

function MechanizedDepot:Init()
	self.parent = self
end

function MechanizedDepot:GameInit()
	local resource = self.storable_resources[1]
	self.resource = resource
	self.stockpiled_resource = resource
	
	local s = self.stockpiles[1]
	s.resource = resource
	s.CreateResourceRequests = function(self, ...)
		ResourceStockpileBase.CreateResourceRequests(self, ...)
		rawset(self, "supply", {[self.resource] = self.supply_request})
		rawset(self, "demand", {[self.resource] = self.demand_request})
	end
	
	rawset(self, "GetStored_"..resource, function(self)
		local stored = self.stockpiles[1].supply[self.resource]:GetActualAmount() + self.stockpiled_amount
		local carried = self.carrying and 5*const.ResourceScale or 0
		return stored + carried
	end)
	rawset(self, "GetMaxAmount_"..resource, function(self)
		return self.max_storage_per_resource + self:GetIOStockpileMaxAmount()
	end)
	
	self.stock_lanes = { }
	self:CreateLane(0,  self:GetSpotBeginIndex("Boxlong"), "long")
	self:CreateLane(-1, self:GetSpotBeginIndex("Box1"))
	self:CreateLane(1,  self:GetSpotBeginIndex("Box2"))	
	
	self.crane = self:GetAttach("WarehouseCrane")
	self.pillars = self.crane:GetAttach("WarehousePillars")
	self.beam = self.pillars:GetAttach("WarehouseBeam")
	self.hoist = self.beam:GetAttach("WarehouseHoist")
	
	self.hoist:Detach()
	self.hoist_org_pos = self.hoist:GetVisualPos() - self:GetVisualPos()
	self.beam:Detach()
	self.beam_org_pos = self.beam:GetVisualPos() - self:GetVisualPos()
	self.pillars:Detach()
	self.pillars_org_pos = self.pillars:GetVisualPos() - self:GetVisualPos()
	
	self.hoist_curr_pos = point(0, -1, 10)
	
	self.carried_cubes = { }
	local first, last = self.hoist:GetSpotRange("Box")
	for spot_idx = first, last do
		local cube = PlaceObject(self.cube_class, { resource = self.resource, is_group = false })
		self.hoist:Attach(cube, spot_idx)
		cube:SetVisible(false)
		table.insert(self.carried_cubes, cube)
	end
end

function MechanizedDepot:GetUIMaxStorageAmount()
	local p = self.additional_stockpile_params
	return self.max_storage_per_resource + p.max_x*p.max_y*p.max_z*const.ResourceScale
end

function MechanizedDepot:GetIPDescription()
	if IsKindOf(self, "MechanizedDepot") then --in build menu this is not true
		return Building.GetIPDescription(self)
	else
		local p = MechanizedDepot.additional_stockpile_params
		return T{self.description, UIMaxStorageAmount = self.max_storage_per_resource + p.max_x*p.max_y*p.max_z*const.ResourceScale}
	end
end

local base_row_length = 26
function MechanizedDepot:CreateLane(pos, spot_idx, long_lane)
	local idx = #self.stock_lanes + 1
	local adjust = long_lane and 1 or 0
	--difference between row lengths and their adjustments must always be equal !
	local max_rows = base_row_length + adjust
	local lane = PlaceObject("MechanizedDepotStockLane", {
		resource = self.resource,
		max_rows = max_rows,
		row_adjustment = adjust,
		lane_idx = idx,
		lane_pos = pos,
	})
	self:Attach(lane, spot_idx)
	self.stock_lanes[idx] = lane
end

function MechanizedDepot:Done()
	self:ReturnStockpiledResources()
	
	self.hoist:delete()
	self.beam:delete()
	self.pillars:delete()
	self.crane:delete()
end

function MechanizedDepot:OnSetWorking(working)
	if working then
		self:TryStore()
	end
end

function MechanizedDepot:DroneLoadResource(drone, request, resource, amount)
	self:TryStore()
end

function MechanizedDepot:DroneUnloadResource(drone, request, resource, amount)
	if request:GetBuilding() == self then
		Building.DroneUnloadResource(self, drone, request, resource, amount)
	end
	self:TryStore()
end

function MechanizedDepot:GetStoredAmount(resource)
	return self.resource == resource and self["GetStored_"..resource](self) or 0
end

function MechanizedDepot:GetIOStockpileMaxAmount()
	local io_stockpile = self.stockpiles[1]
	return io_stockpile:GetMax() * const.ResourceScale
end

local store_step = 5 * const.ResourceScale
function MechanizedDepot:TryStore()
	if self.is_storing then return false end
	if not self:HasPower() then return false end
	
	local s = self.stockpiles[1]
	local d_req = s.demand_request
	local s_req = s.supply_request
	if not d_req or not s_req then return false end
	
	local max = self:GetIOStockpileMaxAmount()
	local incoming_supply = d_req:GetActualAmount() - d_req:GetTargetAmount()
	local incoming_demand = s_req:GetActualAmount() - s_req:GetTargetAmount()
	local actually_stored = s_req:GetActualAmount()
	local total_expected = actually_stored - incoming_demand + incoming_supply
	
	if total_expected <= store_step and --less or eq then 5 with drone assignments
	   actually_stored + incoming_supply <= max - store_step and --has room for 5 cubes
	   self.stockpiled_amount >= store_step --has 5 cubes in storage
	then
		self.is_storing = CreateGameTimeThread(MechanizedDepot.Store, self, -store_step)
	elseif total_expected >=  20 * const.ResourceScale and --has more then 20 cubes with drone assignments in stock
	       actually_stored >= 10 * const.ResourceScale and --has at least 10 cubes right now in stock
	       self.max_storage_per_resource - self.stockpiled_amount >= store_step --has room in storage
	then
		self.is_storing = CreateGameTimeThread(MechanizedDepot.Store, self, store_step)
	end
end

local pause_time = 200 --time to pause between motions (makes it seem more smooth)
function MechanizedDepot:Store(amount)
	--'stock' refers to the long stock piles where large amounts are stored
	--'io' refers to the input/output stockpile that drones interact with
	local function interact_with_stock(self, amount)
		self:SetCount(self.stockpiled_amount + amount)
	end
	local function interact_with_io(self, amount)
		self:UpdateStockpileAmounts(self.total_stockpiled + amount)
	end
	
	local take_leave_time = 300
	local beam_up_pos, time
	
	if not IsValid(self) then return end
	if amount > 0 then
		beam_up_pos, time = self:CraneGoToIO()
		interact_with_io(self, -amount)
	else
		--curr pos
		local lane = self:FindStockLaneToTakeFrom()
		assert(lane)
		beam_up_pos, time = self:CraneGoToStock(lane.lane_idx, lane:CalculateLastCubesPos())
		interact_with_stock(self, amount)
	end
	
	--take boxes
	PlayFX("WarehouseCarryResource", "start", self.hoist)
	self.carrying = true
	self:SetHoistCubesVisible(true)
	Sleep(take_leave_time)
	if not IsValid(self) then return end
	--retract
	PlayFX("WarehouseBeamMovingVert", "start", self.hoist)
	self.beam:SetPos(beam_up_pos, time)
	Sleep(time)
	PlayFX("WarehouseBeamMovingVert", "end", self.hoist)
	if not IsValid(self) then return end
	
	if amount > 0 then
		--next pos
		local lane = self:FindStockLaneToGiveTo()
		assert(lane)
		beam_up_pos, time = self:CraneGoToStock(lane.lane_idx, lane:CalculateNextCubesPos())
		interact_with_stock(self, amount)
	else
		beam_up_pos, time = self:CraneGoToIO()
		interact_with_io(self, -amount)
	end
	
	--leave boxes
	PlayFX("WarehouseCarryResource", "end", self.hoist)
	self:SetHoistCubesVisible(false)
	self.carrying = false
	Sleep(take_leave_time)
	if not IsValid(self) then return end
	--retract
	PlayFX("WarehouseBeamMovingVert", "start", self.hoist)
	self.beam:SetPos(beam_up_pos, time)
	Sleep(time)
	PlayFX("WarehouseBeamMovingVert", "end", self.hoist)
	Sleep(pause_time)
	if not IsValid(self) then return end
	--center hoist
	self:CenterHoist()
	
	self.is_storing = false
	
	if self.func_after_anim_end then
		self[self.func_after_anim_end](self)
		self.func_after_anim_end = nil
	end
	
	self:TryStore()
end

function MechanizedDepot:FindStockLaneToGiveTo()
	--search for shortest lane
	local target_lane = false
	local least_available = self.max_storage_per_resource
	for i,lane in ipairs(self. stock_lanes) do
		local lane_max_count = lane.n * (lane.max_rows - lane.row_adjustment)
		local available = lane:CalculateSearchOrder()
		if available < lane_max_count and least_available > available then
			least_available = available
			target_lane = lane
		end
	end
	
	return target_lane
end

function MechanizedDepot:FindStockLaneToTakeFrom()
	--search for longest lane
	local target_lane = false
	local most_available = 0
	for i,lane in ipairs(self. stock_lanes) do
		local available = lane:CalculateSearchOrder()
		if available > 0 and most_available < available then
			most_available = available
			target_lane = lane
		end
	end
	----if all lanes are empty - try looking without adjustments
	--(this second search happens one a few times per emptying the whole storage)
	if not target_lane then
		for i,lane in ipairs(self. stock_lanes) do
			local available = lane.stockpiled_amount
			if available > 0 and most_available < available then
				most_available = available
				target_lane = lane
			end
		end
	end
	
	return target_lane
end

function MechanizedDepot:SetCount(new_count)
	if new_count == self.stockpiled_amount then
		return
	end

	if new_count > self.stockpiled_amount then --add
		local resources_left = new_count - self.stockpiled_amount --resources left to be added
		while resources_left > 0 do
			local target_lane = self:FindStockLaneToGiveTo()
			assert(target_lane, "No lane to put resources in")
			if not target_lane then break end
			
			local lane_max_count = target_lane.n * target_lane.max_rows * target_lane.row_size * const.ResourceScale
			local free_space = lane_max_count - target_lane.stockpiled_amount
			assert(free_space > 0, "All stock lanes are full")
			local next_added = Min(resources_left, free_space)
			target_lane:SetCount(target_lane.stockpiled_amount + next_added)
			resources_left = resources_left - next_added
		end
	else --take
		local resources_left = self.stockpiled_amount - new_count --resources left to be taken
		while resources_left > 0 do
			local target_lane = self:FindStockLaneToTakeFrom()
			assert(target_lane, "No lane to take resources from")
			if not target_lane then break end
			
			local available = target_lane.stockpiled_amount
			assert(available > 0, "All stock lanes are empty")
			local next_taken = Min(resources_left, available)
			target_lane:SetCount(target_lane.stockpiled_amount - next_taken)
			resources_left = resources_left - next_taken
		end
	end
	
	--this value might jump back/forward during the recursion but in the end it will be correct
	self.stockpiled_amount = new_count
end

function MechanizedDepot:SetDustVisuals(dust, in_dome)
	local normalized_dust = MulDivRound(dust, 255, self.visual_max_dust)
	SetObjDust(self,         normalized_dust, in_dome)
	SetObjDust(self.hoist,   normalized_dust, in_dome)
	SetObjDust(self.beam,    normalized_dust, in_dome)
	SetObjDust(self.pillars, normalized_dust, in_dome)
	SetObjDust(self.crane,   normalized_dust, in_dome)
end

--animation
function MechanizedDepot:SetHoistCubesVisible(visible)
	for i,cube in ipairs(self.carried_cubes) do
		cube:SetVisible(visible or false)
	end
end

local speed = 150 --ms per cube
local lane_x_tweaks = {
	[-1] = 10*guic,
	[0] = -16*guic,
	[1] = -28*guic,
}
function MechanizedDepot:CraneGoToCubes(x, y, z)
	if not CurrentThread() then
		return CreateGameTimeThread(MechanizedDepot.CraneGoToCubes, self, x, y, z)
	end
	
	--Note: x, y and z will be switch up and some will have inverted signs to align with the building
	
	--internal corrections
	local lane = x
	x = x*5 + x --*5 because there are 5 cubes in one lane; +1 for approx. 1 cube between lanes
	y = y + 1
	z = z + 1

	--parameters
	local max_z = 10
	local sx = self.box_diam + self.spacing_x
	local sy = self.box_diam + self.spacing_y
	local sz = self.box_height + self.spacing_z
	
	--starting position
	local start_x, start_y, start_z = self.hoist_curr_pos:xyz()
	
	local top_z = self:GetVisualPos():z() + self.beam_org_pos:z()
	
	--move up if needed
	if start_z ~= max_z then
		local time = abs((max_z + 1) - start_z) * speed
		local beam_up_pos = self.beam:GetPos():SetZ(top_z)
		PlayFX("WarehouseBeamMovingVert", "start", self.hoist)
		self.beam:SetPos(beam_up_pos, time)
		Sleep(time)
		PlayFX("WarehouseBeamMovingVert", "end", self.hoist)
		Sleep(pause_time)
		if not IsValid(self) then return end
	end
	
	--move horizontally
	if x ~= start_x or y ~= start_y then
		--detach hoist and set proper position
		local hoist_old_pos = self.hoist:GetVisualPos()
		self.hoist:Detach()
		self.hoist:SetPos(hoist_old_pos)
		
		--fix pillars and beams
		self.pillars:Detach()
		self.pillars:Attach(self.beam, self.pillars:GetSpotBeginIndex("Autoattach"))
		
		local y_tweak = y ~= 0 and 84*guic or 18*guic
		local x_tweak = y ~= 0 and lane_x_tweaks[lane] or -2*guic
		local pillars_offset = self:GetRelativePoint(y_tweak - sy*y, 0,              0)
		local hoist_offset =   self:GetRelativePoint(y_tweak - sy*y, x_tweak - sx*x, 0)
		
		local time = (abs(start_x - x) + abs(start_y - y))*speed
		
		PlayFX("WarehouseCraneMovingHor", "start", self.hoist)
		self.pillars:SetPos(self.pillars_org_pos + pillars_offset, time)
		if x ~= start_x then
			PlayFX("WarehouseHoistMovingHor", "start", self.hoist)
		end
		self.hoist:SetPos(self.hoist_org_pos + hoist_offset, time)
		Sleep(time)
		if x ~= start_x then
			PlayFX("WarehouseHoistMovingHor", "end", self.hoist)
		end
		PlayFX("WarehouseCraneMovingHor", "end", self.hoist)
		Sleep(pause_time)
		if not IsValid(self) then return end
	end
	
	--detach beam from pillars
	self.beam:Detach()
	local beam_up_pos = self.beam:GetVisualPos(top_z) --will return to this pos later
	local z_tweak = y ~= 0 and 68*guic or 55*guic
	local beam_down_pos = self.beam:GetVisualPos():SetZ(z_tweak + top_z - sz*(max_z - z + 2)) --hoist is up
	--attach hoist with correct offset
	local offset = self.hoist:GetVisualPos() - self.beam:GetVisualPos()
	offset = RotateAxis(offset, axis_z, -self:GetAngle())
	self.beam:Attach(self.hoist)
	self.hoist:SetAttachOffset(offset)
	
	--move beam down
	local time = abs((max_z + 1) - z)*speed
	PlayFX("WarehouseBeamMovingVert", "start", self.hoist)
	self.beam:SetPos(beam_down_pos, time)
	Sleep(time)
	PlayFX("WarehouseBeamMovingVert", "end", self.hoist)
	Sleep(pause_time)
	if not IsValid(self) then return end
	
	--move beam up (note: intentionally commented - this should be done in the calling function after showing/hiding carried resources)
	--PlayFX("WarehouseBeamMovingVert", "start", self.hoist)
	--self.beam:SetPos(beam_up_pos, time) --time for going up is the same as for going down
	--Sleep(time)
	--PlayFX("WarehouseBeamMovingVert", "end", self.hoist)
	--if not IsValid(self) then return end
	
	--this should be 'z', instead of 'max_z' but I trust the proper beam z will be set outside this func
	self.hoist_curr_pos = point(x, y, max_z)
	
	return beam_up_pos, time
end

function MechanizedDepot:CenterHoist()
	local x, y, z = self.hoist_curr_pos:xyz()
	if x == 0 then return end

	--parameters
	local sx = self.box_diam + self.spacing_x
	local sy = self.box_diam + self.spacing_y
	local sz = self.box_height + self.spacing_z

	--detach hoist and set proper position
	local hoist_old_pos = self.hoist:GetVisualPos()
	self.hoist:Detach()
	self.hoist:SetPos(hoist_old_pos)
	
	--position the hoist in the middle of the beam
	local x_tweak = lane_x_tweaks[0]
	local y_tweak = y ~= 0 and 84*guic or 18*guic
	local hoist_offset =   self:GetRelativePoint(y_tweak - sy*y, x_tweak, 0)
	local time = abs(z)*speed
	PlayFX("WarehouseHoistMovingHor", "start", self.hoist)
	self.hoist:SetPos(self.hoist_org_pos + hoist_offset, time)
	Sleep(time)
	PlayFX("WarehouseHoistMovingHor", "end", self.hoist)
	Sleep(pause_time)
	
	self.hoist_curr_pos = point(0, y, z)
end

function MechanizedDepot:CraneGoToIO()
	local io = self.stockpiles[1]
	local io_amount = io.supply[self.resource]:GetActualAmount()
	local io_row_size = io.max_x*io.max_y*const.ResourceScale
	local z = Min(io_amount/io_row_size, io.max_z - 1)
	return self:CraneGoToCubes(0, -1, z)
end

function MechanizedDepot:CraneGoToStock(lane_idx, hor, vert)
	local lane = self.stock_lanes[lane_idx]
	if not lane then return end
	return self:CraneGoToCubes(lane.lane_pos, lane.max_rows - hor, vert)
end

--demolishion
function MechanizedDepot:ShouldShowDemolishButton()
	return true
end

function MechanizedDepot:CanDemolish()
	return self.stockpiled_amount <= 50 * const.ResourceScale and Building.CanDemolish(self)
end

function MechanizedDepot:ToggleDemolish_Update(button)
	Demolishable.ToggleDemolish_Update(self, button)
	if not self:CanDemolish() then
		button:SetRolloverText(T{8897, "Cannot salvage mechanized depot with more than 50 resource stocked"})
	end
end

function MechanizedDepot:ReturnStockpiledResources()
	local pos = self:GetVisualPos()
	if pos ~= InvalidPos() then
		local stock_amount = self.stockpiled_amount
		local io_amount = self.stockpiles[1].supply[self.resource]:GetActualAmount()
		local total_amount = stock_amount + io_amount
		if total_amount > 0 then
			PlaceResourceStockpile_Delayed(pos, self.resource, total_amount, self:GetAngle(), true)
		end
	end
	
	self:ClearAllResources()
end

function MechanizedDepot:ClearAllResources()
	--calculate target stockpile amounts
	local resource = self.resource
	local io_stockpile = self.stockpiles[1]
	local io_supply_req = io_stockpile.supply[resource]
	local io_demand_req = io_stockpile.demand[resource]
	local io_max = self:GetIOStockpileMaxAmount()
	
	--handle io stockpile
	io_supply_req:SetAmount(0)
	io_demand_req:SetAmount(io_max)
	local io_actual_amount = io_supply_req:GetActualAmount()
	io_stockpile:SetCount(io_actual_amount)
	io_stockpile.stockpiled_amount = io_actual_amount
	
	--handle own stock
	self:SetCount(0)
end

--cheats
function MechanizedDepot:CheatFill()
	if self.is_storing then
		--using the cheats while the animation is running will put the building in an invalid state
		self.func_after_anim_end = "CheatFill"
	else
		--calculate target stockpile amounts
		local resource = self.resource
		local io_stockpile = self.stockpiles[1]
		local io_supply_req = io_stockpile.supply[resource]
		local io_demand_req = io_stockpile.demand[resource]
		local io_max = self:GetIOStockpileMaxAmount()
		local stock_max = self.max_storage_per_resource
		
		--handle io stockpile
		io_supply_req:SetAmount(io_max)
		io_demand_req:SetAmount(0)
		io_stockpile:SetCount(io_max)
		local io_actual_amount = io_supply_req:GetActualAmount()
		io_stockpile:SetCount(io_actual_amount)
		io_stockpile.stockpiled_amount = io_actual_amount
		
		--handle own stock
		self:SetCount(stock_max)
	end
end

function MechanizedDepot:CheatEmpty()
	if self.is_storing then
		--using the cheats while the animation is running will put the building in an invalid state
		self.func_after_anim_end = "CheatEmpty"
	else
		self:ClearAllResources()
	end
end

--mechanized stock lane
DefineClass.MechanizedDepotStockLane = {
	__parents = { "Object" },

	--lane parameters
	n = 10, --number of resource cubes stacked on top of each other
	row_size = 5, --number of cubes in one row
	max_rows = 26, --max row length in this lane
	row_adjustment = 0, --difference between the max_rows in this and other lanes (for search purposes)
	lane_idx = 0, --lane index in the 'stock_lane' array of the parent depot
	lane_pos = 0, --lane position relative to other lanes
	offset_x = guim + 16*guic, --horizontal (X) offset between the centers of two adjacent cubes
	offset_y = guim + 13*guic, --horizontal (Y) offset between the centers of two adjacent cubes
	offset_z = guim + 1*guic,  --vertical offset between the centers of two adjacent cubes
	
	--cube classes
	resource = false,
	cube_class = "ResourceStockpileBox",
	
	--members
	stockpiled_amount = false, --amount of cubes in the whole lane
	cubes = false, --array with cube objects by rows
}

function MechanizedDepotStockLane:Init()
	self.cubes = { }
	self.stockpiled_amount = 0
	for i=1,self.n do
		self.cubes[i] = { count = 0 }
	end
end

function MechanizedDepotStockLane:CalculateResourceCubePos(count)
	count = count / (self.row_size * const.ResourceScale)
	local n = self.n
	
	--counting goes like this (for n=3):
	--Y
	--| 5 8 11 14 17 20
	--| 2 4 7  10 13 16 19
	--| 0 1 3  6  9  12 15 18 ...
	------------------------------ X
	--for n=4, cnt=8:
	--| b
	--| B b
	--| B B B
	--| B B B B
	-----------------------------
	--for n=4, cnt=20:
	--| B N N
	--| B B N N
	--| B B B N N N
	--| B B B B N N N
	-----------------------------
	--for n=3, max_rows=3, cnt=7:
	--| N
	--| B N A
	--| B B N
	-----------------------------
	--B=below (before reaching the normal case), b=non-exiting below (for demonstration)
	--N=normal (normal arrangement)
	--A=above (edge case, symmetric to B)
	
	--calculates the size of the 'B' triangle in the diagram above (as if 'b' existed, but they won't)
	local find_subn = function(cnt)
		cnt = cnt + 1 --this function works with 1-based numbers
		-- subn = ceil((sqrt(8*cnt - 1) - 1)/2)
		local sqrt_cnt = sqrt(8*cnt*100*100 - 1) --scaled by 100
		local ceil_add_one = (sqrt_cnt % 100) ~= 0
		sqrt_cnt = sqrt_cnt / 100 --scale down
		local subn = (sqrt_cnt - 1) / 2
		return ceil_add_one and (subn + 1) or subn
	end

	--calculates coordinates of the 'cnt'-th cube, if the cubes count does not reach the normal arrangement
	--ie - handle edge case with low number of cubes that don't reach 'n' in height
	local below = function(cnt)
		local subn = find_subn(cnt)
		--correct for the 'b' cubes in the diagram above (the error that was made in find_subn)
		local lowern = subn - 1
		local filled_cnt = lowern*(lowern + 1)/2
		local offset = cnt - filled_cnt
		
		local y = offset
		local x = (subn - 1) - y
		return x, y, "below"
	end
	
	--calculates coordinates of the 'cnt'-th cube, if the cubes count reaches the normal arrangement
	--normal arrangement is when the cubes do reach the 'n' cube height
	local normal = function(cnt)
		local below_max_cnt = n*(n + 1)/2 - n --maximum cubes that can fit in the 'B' (below) category
		local y = (cnt - below_max_cnt) % n
		local x = (n - 1) + ((cnt - below_max_cnt) / n) - y
		--local x = (cnt/n - 1) + (n - 1) - y - 1
		--x is 1-based so far - get it to be 0-based as in below() and above()
		return x, y, "normal"
	end
	
	--calculates coordinates of the 'cnt'-th cube, if the cubes count exceede the normal arrangement
	--above arrangement is if the cubes reach the 'max_rows' limit and is somewhat symmetric to below
	local above = function(cnt)
		local empty_cnt = (n*self.max_rows - 1) - cnt
		local bx, by = below(empty_cnt)
		--we need to correct these coordinates ('above' is symmetric to 'below')
		local x = (self.max_rows - 1) - bx
		local y = (n - 1) - by
		return x, y, "above"
	end
	
	--calculates coordinates of the 'cnt'-th cube
	local getpos = function(cnt)
		if cnt == -1 then -- minus 1 because we're doing a 0-based counting (see the diagram), but the input to the main function is 1-based
			return -1, -1, "empty"
		end
		
		local max_cnt = n*self.max_rows --maximum cubes that can fit on the lane
		local below_max_cnt = n*(n + 1)/2 - n - 1 --maximum cubes that can fit in the 'B' (below) category (-1 for 0-based)
		local above_max_cnt = below_max_cnt + 1 --maximum cubes that can fit in the 'A' (above) category
		
		if cnt <= below_max_cnt then
			return below(cnt)
		elseif cnt >= max_cnt - above_max_cnt then
			return above(cnt)
		else
			return normal(cnt)
		end
	end
	
	return getpos(count - 1)
end

function MechanizedDepotStockLane:CalculateResourceCubeRows(count)
	--calculates the length of each row
	--for the third example diagram above this would be {3,4,6,7}
	
	local x, y, mode = self:CalculateResourceCubePos(count)
	--print(x, y, mode)
	x, y = x + 1, y + 1 --x and y are now 1-based
	
	local row_lengths = { }
	for row=1, self.n do
		if row <= y then
			row_lengths[row] = Min(x + (y - row), self.max_rows)
		else
			row_lengths[row] = Max((x - 1) - (row - y), 0)
		end
	end
	
	return row_lengths
end

function MechanizedDepotStockLane:CalculateNextCubesPos(cube_num)
	cube_num = cube_num or 0
	local step = self.row_size * const.ResourceScale
	local hor, vert = self:CalculateResourceCubePos(self.stockpiled_amount + step)
	return hor, vert
end

function MechanizedDepotStockLane:CalculateLastCubesPos(cube_num)
	cube_num = cube_num or 0
	local hor, vert = self:CalculateResourceCubePos(self.stockpiled_amount)
	return hor, vert
end

function MechanizedDepotStockLane:CalculateSearchOrder()
	local total = 0
	for i=1,self.n do
		total = total + Max(self.cubes[i].count - self.row_adjustment, 0)
	end
	return total
end

function MechanizedDepotStockLane:SetCount(new_count)
	local rows = self:CalculateResourceCubeRows(new_count)
	local total = 0
	for i=1,self.n do
		self:SetCountOnRow(i, rows[i])
		total = total + rows[i]
	end
	assert(total*self.row_size == new_count/const.ResourceScale)
	
	self.stockpiled_amount = new_count
end

function MechanizedDepotStockLane:SetCountOnRow(row, new_count)
	local cubes = self.cubes[row]
	if cubes.count == new_count then
		return
	end
	for i=1,#cubes do
		cubes[i]:delete()
	end
	
	cubes = { }
	cubes.count = new_count
	self.cubes[row] = cubes
	
	--place doubles
	if new_count >= 2 then
		for y=1,new_count/2 do
			self:PlaceCubes(y, row, "is_group")
		end
	end
	
	--place last row of cubes
	if (new_count % 2) == 1 then
		self:PlaceCubes(new_count, row)
	end
end

local single_angle = 90*60
local group_angle = 0
function MechanizedDepotStockLane:PlaceCubes(y, z, is_group)
	y, z = y - 1, z - 1
	if is_group then
		local cube = PlaceObject(self.cube_class, {resource = self.resource, is_group = true})
		self:Attach(cube)
		local offset = point(0, y*2 * self.offset_y, z * self.offset_z)
		cube:SetAttachOffset(offset)
		cube:SetAngle(group_angle)
		table.insert(self.cubes[z + 1], cube)
	else
		for x=0,4 do
			local cube = PlaceObject(self.cube_class, {resource = self.resource})
			self:Attach(cube)
			local offset = point(x * self.offset_x, y * self.offset_y, z * self.offset_z)
			cube:SetAttachOffset(offset)
			cube:SetAngle(single_angle)
			table.insert(self.cubes[z + 1], cube)
		end
	end
end

function OnMsg.GatherFXActors(list)
	list[#list + 1] = "WarehouseHoist"
end

function OnMsg.GatherFXActions(list)
	list[#list + 1] = "WarehouseBeamMovingVert"
	list[#list + 1] = "WarehouseCraneMovingHor"
	list[#list + 1] = "WarehouseHoistMovingHor"
	list[#list + 1] = "WarehouseCarryResource"
end

-----------------------------------------

DefineClass.MechanizedMysteryDepot = {
	__parents = { "MechanizedDepot" },
}

function MechanizedMysteryDepot:Getdescription()
	local m = UICity and UICity.mystery or MysteryBase
	return m.mech_depot_description
end

function MechanizedMysteryDepot:Getdisplay_name()
	local m = UICity and UICity.mystery or MysteryBase
	return m.mech_depot_display_name
end

function MechanizedMysteryDepot:Getdisplay_name_pl()
	local m = UICity and UICity.mystery or MysteryBase
	return m.mech_depot_display_name_pl
end

function MechanizedMysteryDepot:GetDisplayName()
	return MechanizedMysteryDepot.Getdisplay_name()
end

function MechanizedMysteryDepot:GetDescription()
	return MechanizedMysteryDepot.Getdescription(self)
end

function MechanizedMysteryDepot:GetIPDescription()
	return MechanizedMysteryDepot.Getdescription(self)
end
