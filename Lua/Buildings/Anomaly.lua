local anomaly_tech_actions = {
	{ text = T{1, "Unlock Breakthrough"}, value = "breakthrough" },
	{ text = T{2, "Unlock Tech"}, value = "unlock" },
	{ text = T{3, "Grant Research"}, value = "complete" },
	{ text = T{8693, "Grant Resources"}, value = "resources" },
}

DefineClass.SubsurfaceAnomalyMarker = {
	__parents = { "DepositMarker" },
	properties = {
		{ category = "Anomaly", name = T{4, "Tech Action"},             id = "tech_action",              editor = "dropdownlist", default = false, items = anomaly_tech_actions },
		{ category = "Anomaly", name = T{5, "Sequence"},                id = "sequence",                 editor = "dropdownlist", default = "",    items = function() return table.map(DataInstances.Scenario.Anomalies, "name") end, help = "Sequence to start when the anomaly is scanned" },
		{ category = "Anomaly", name = T{6, "Depth Layer"},             id = "depth_layer",              editor = "number",       default = 1,     min = 1, max = const.DepositDeepestLayer}, --depth layer
		{ category = "Anomaly", name = T{7, "Is Revealed"},             id = "revealed",                 editor = "bool",         default = false },
		{ category = "Anomaly", name = T{8, "Breakthrough Tech"},       id = "breakthrough_tech",        editor = "text",       default = "" },
		{ category = "Anomaly", name = T{8694, "Granted Resource"}, 				id = "granted_resource",			 editor = "dropdownlist", default = "", items = ResourcesDropDownListItems, },
		{ category = "Anomaly", name = T{8695, "Granted Amount"},				id = "granted_amount",				 editor = "number", 		 default = 0, min = 0, scale = const.ResourceScale, },
	},
	new_pos_if_obstruct = true,
}
function SubsurfaceAnomalyMarker:EditorGetText()
	return "Anomaly " .. (self.tech_action or self.sequence)
end

function SubsurfaceAnomalyMarker:GetDepthClass()
	return self.depth_layer <= 1 and "subsurface" or "deep"
end

function PlaceAnomaly(params)
	local classdef = params.tech_action and rawget(g_Classes, "SubsurfaceAnomaly_" .. params.tech_action) or SubsurfaceAnomaly
	return classdef:new(params)
end

function SubsurfaceAnomalyMarker:SpawnDeposit()
	return PlaceAnomaly{
		depth_layer = self.depth_layer,
		revealed = self.revealed,
		tech_action = self.tech_action,
		granted_resource = self.granted_resource,
		granted_amount = self.granted_amount,
		sequence = self.sequence,
		breakthrough_tech = self.breakthrough_tech, --randomly assigned in City:InitBreakThroughAnomalies
		marker = self,
	}
end

DefineClass.SubsurfaceAnomaly = {
	__parents = { "SubsurfaceDeposit", "PinnableObject", "UngridedObstacle", "InfopanelObj" },
	game_flags = { gofRealTimeAnim = true },
	
	entity = "Anomaly_01",
	
	properties =
	{
		{ name = T{4, "Tech Action"},             id = "tech_action",              editor = "dropdownlist", default = false, items = anomaly_tech_actions },
		{ name = T{5, "Sequence"},                id = "sequence",                 editor = "dropdownlist", items = function() return table.map(DataInstances.Scenario.Anomalies, "name") end, default = "", help = "Sequence to start when the anomaly is scanned" },
		{ name = T{8694, "Granted Resource"}, 			id = "granted_resource",			 editor = "dropdownlist", default = "", items = ResourcesDropDownListItems, },
		{ name = T{8695, "Granted Amount"},				id = "granted_amount",				 editor = "number", 		 default = 0, min = 0, scale = const.ResourceScale, },
		{ name = T{8696, "Expiration Time"},				id = "expiration_time",			 editor = "number",		 default = 0, scale = const.HourDuration },
	},
	
	display_name = T{9, "Anomaly"},
	display_icon = "UI/Icons/Buildings/anomaly.tga",
	
	-- pin section
	pin_rollover = T{10, "<Description>"},
	pin_summary1 = "",
	pin_progress_value = "",
	pin_progress_max = "",
	pin_on_start = false,
	
	scanning_progress = false,
	spawn_time = false,
	expiration_thread = false,
	
	resource = "Anomaly",
	breakthrough_tech = false,
	description = false,
	
	city_label = "Anomaly",
	
	fx_actor_class = "SubsurfaceAnomaly",
	ip_template = "ipAnomaly",
}

DefineClass.SubsurfaceAnomaly_breakthrough = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_02",
	tech_action = "breakthroug",
	description = T{11, "Our scientists believe that this Anomaly may lead to a <em>Breakthrough</em>.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."},
}

DefineClass.SubsurfaceAnomaly_unlock = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_04",
	tech_action = "unlock",
	description = T{12, "Scans have detected some interesting readings that might help us discover <em>new Technologies</em>.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."},
}
function SubsurfaceAnomaly_breakthrough:EditorGetText()
	return "Breakthrough Anomaly"
end

DefineClass.SubsurfaceAnomaly_complete = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_05",
	tech_action = "complete",
	description = T{13, "Sensors readings suggest that this Anomaly will help us with our current <em>Research</em> goals.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."},
}
DefineClass.SubsurfaceAnomaly_aliens = {
	__parents = { "SubsurfaceAnomaly" },
	entity = "Anomaly_03",
	tech_action = "aliens",
	description = T{14, "We have detected alien artifacts at this location that will <em>speed up</em> our Research efforts.<newline><newline>Send an <em>Explorer</em> to analyze the Anomaly."},
}

function SubsurfaceAnomaly:Init()
	self.scanning_progress = 0
end

function SubsurfaceAnomaly:GameInit()
	if self.expiration_time > 0 then
		self.spawn_time = GameTime()
		self.expiration_thread = CreateGameTimeThread(function()
			Sleep(self.expiration_time)
			if not IsValid(self) then
				return
			end
			self:OnExpired()
			DoneObject(self)
		end)
	end
end

function SubsurfaceAnomaly:Done()
	if self == SelectedObj then
		SelectObj()
	end
end

function SubsurfaceAnomaly:StartSequence(sequence, scanner, pos)
	if sequence ~= ""  then
		local list = DataInstances.Scenario.Anomalies
		
		local checked = { Anomalies = true }
		local found = true
		
		if not list or not table.find(list, "name", sequence) then
			--the sequence is in another castle.
			found = false
			for k, v in pairs(DataInstances.Scenario) do
				if not checked[k] then
					checked[k] = true
					list = v
					if table.find(list, "name", sequence) then
						found = true
						break
					end
				end
			end
		end
		
		if not found then
			print("Could not find sequence " .. sequence .. " in DataInstances.Scenario!")
			return 
		end
		
		local player = CreateSequenceListPlayer(list)
		local state = player:StartSequence(sequence)
		if not state then
			printf("Subsurface anomaly sequence start failed - probably missing sequence %s?", sequence)
			return
		end
		local registers = player.seq_states[sequence].registers
		registers.anomaly_pos = pos
		if scanner then
			assert(IsKindOf(scanner, "ExplorerRover"))
			registers.rover = scanner
		end
	end
end

function SubsurfaceAnomaly:UnlockTechs(scanner)
	local city = scanner and scanner.city or UICity
	local new_unlocked = {}
	local fields = {}
	for field_id, field in pairs(TechFields) do
		if field.discoverable then
			fields[#fields + 1] = field_id
		end
	end
	table.sort(fields)
	if city:Random(100) < 75 then
		while table.count(new_unlocked) < 2 do
			local field, idx = city:TableRand(fields)
			if not field then
				break
			end
			local tech_id = city:DiscoverTechInField(field)
			if tech_id then
				new_unlocked[tech_id] = true
			else
				table.remove(fields, idx)
			end
		end
	else
		for i=1,#fields do
			local tech_id = city:DiscoverTechInField(fields[i])
			if tech_id then
				new_unlocked[tech_id] = true
			end
		end
	end
	return table.keys(new_unlocked, true)
end

function SubsurfaceAnomaly:GrantRP(scanner)
	local city = scanner and scanner.city or UICity
	local points = city:TableRand{1000, 1250, 1500}
	city:AddResearchPoints(points)
	return points
end

function SubsurfaceAnomaly:OnRevealedValueChanged()
	if not self.revealed then return end
	self:SetScale(const.SignsOverviewCameraScaleDown)
	self:SetVisible(not IsEditorActive())
	self:OnReveal()
end

function SubsurfaceAnomaly:PickVisibilityState()
	self:SetVisible(not IsEditorActive() and self.revealed and g_SignsVisible and g_ResourceIconsVisible)
end

SubsurfaceAnomaly.EditorEnter = SubsurfaceAnomaly.PickVisibilityState
SubsurfaceAnomaly.EditorExit = SubsurfaceAnomaly.PickVisibilityState

function SubsurfaceAnomaly:Setdepth_layer(depth)
	if depth ~= self.depth_layer and depth >= 1 and depth <= const.DepositDeepestLayer then
		self.depth_layer = depth
	end
end

function SubsurfaceAnomaly:ScanCompleted(scanner)
	local city = scanner and scanner.city or UICity
	local tech_action = self.tech_action
	if tech_action == "breakthrough" then
		local def = TechDef[self.breakthrough_tech]
		if def and city:SetTechDiscovered(self.breakthrough_tech) then
			AddOnScreenNotification("BreakthroughDiscovered", OpenResearchDialog, {name = def.display_name, context = def, rollover_title = def.display_name, rollover_text = def.description})
		else
			assert(false, print_format("Failed to discover", self.breakthrough_tech, "by subsurface anomaly!"))
			tech_action = "unlock"
		end
	end
	if tech_action == "unlock" then
		local new_unlocks = self:UnlockTechs(scanner)
		if #new_unlocks > 0 then
			local list_of_techs = {}
			for i=1,#new_unlocks do
				list_of_techs[i] = TechDef[new_unlocks[i]].display_name
			end
			local list_text = table.concat(list_of_techs, '\n')
			AddOnScreenNotification("TechUnlockAnomalyAnalyzed", function()
				CreateRealTimeThread(function()
					local res = WaitPopupNotification("AnomalyAnalyzed", { params = {list_text = list_text} })
					if res == 1 then
						OpenResearchDialog()
					end
					RemoveOnScreenNotification("TechUnlockAnomalyAnalyzed")
				end)
			end)
		else
			tech_action = "complete"
		end
	end
	if tech_action == "complete" then
		local points = self:GrantRP(scanner)
		if points then
			AddOnScreenNotification("GrantRP", nil, {points = points})
		end
	elseif tech_action == "resources" then
		if self.granted_resource ~= "" and self.granted_amount > 0 then
			PlaceResourceStockpile_Delayed(self:GetPos(), self.granted_resource, self.granted_amount, self:GetAngle(), true)
		end
	elseif tech_action == "aliens" then
		AddOnScreenNotification("AlienArtifactsAnomalyAnalyzed", nil, {})
	elseif not tech_action then
		g_AnalyzedAnomalyPositions[#g_AnalyzedAnomalyPositions + 1] = self:GetVisualPos()
		AddOnScreenNotification("AnomalyAnalyzed", 
			function(pos, params, res) 		
				table.remove_entry(g_AnalyzedAnomalyPositions, pos)
				if #g_AnalyzedAnomalyPositions<=0 then
					RemoveOnScreenNotification("AnomalyAnalyzed")
				end
			end, 
			{
				GetPopupPreset  =  function()
					return "AnomalyAnalyzed_"..self.sequence
				end}, 
			g_AnalyzedAnomalyPositions)
	end
	HintDisable("HintAnomaly")
	--@@@msg AnomalyAnalyzed,anomaly- fired when a new anomaly has been completely analized.
	Msg("AnomalyAnalyzed", self)
	self:StartSequence(self.sequence, scanner, self:GetVisualPos())
end

function SubsurfaceAnomaly:OnReveal()
	table.insert_unique(g_RecentlyRevAnomalies, self)
	--@@@msg AnomalyRevealed,anomaly- fired when an anomaly has been releaved.
	Msg("AnomalyRevealed", self)
	--[[
	print("--ANOMALY REVEALED--")
	print("")
	print("Anomaly:")
	print(" Max Amount", self.max_amount)
	print(" Amount Left", self.amount)
	print(" Grade", self.grade)
	print(" Depth(Layer)", self.depth_layer)
	--]]
end

function SubsurfaceAnomaly:Getexpiration_progress()
	if not self.spawn_time or self.expiration_time <= 0 then
		return 0
	end
	return MulDivRound(GameTime() - self.spawn_time, 100, self.expiration_time)
end

function SubsurfaceAnomaly:OnExpired()
end

function SubsurfaceAnomaly:CheatScan()
	self:ScanCompleted(nil)
	self:delete()
end

GlobalVar("g_RecentlyRevAnomalies", {})
GlobalVar("g_AnalyzedAnomalyPositions", {})
GlobalGameTimeThread("RecentlyRevAnomaliesNotif", function()
	HandleNewObjsNotif(g_RecentlyRevAnomalies, "NewAnomalies", "expire")
end)

DefineClass.SA_SpawnDepositAtAnomaly = {
	__parents = { "SequenceAction" },
	
	properties =
	{
		{ name = T{15, "Resource"}, id = "resource", default = "all", editor = "dropdownlist", items = function() return ResourcesDropDownListItems end },
		{ name = T{1000100, "Amount"}, id = "amount", editor = "number", default = 50000, scale = const.ResourceScale},	 --quantity
		{ name = T{16, "Grade"}, id = "grade", editor = "dropdownlist", default = "Average", items = function() return DepositGradesTable end}, --grade
		{ name = T{6, "Depth Layer"}, id = "depth_layer", editor = "number", default = 1, min = 1, max = const.DepositDeepestLayer}, --depth layer
	},

	Menu = "Gameplay",
	MenuName = "Spawn Deposit at Anomaly",
	MenuSection = "Anomaly",
	RestrictToList = "Scenario",
}

function SA_SpawnDepositAtAnomaly:ShortDescription()
	return string.format("Spawn %s deposit", self.resource)
end

function SA_SpawnDepositAtAnomaly:Exec(sequence_player, ip, seq, registers)
	local class = "SubsurfaceDeposit" .. self.resource
	if not g_Classes[class] then 
		sequence_player:Error(self, string.format("invalid resource %s", self.resource))
		return false
	end
	if registers.anomaly_pos then
		local marker = SubsurfaceDepositMarker:new()
		marker.resource = self.resource
		marker:SetPos(registers.anomaly_pos)

		marker.grade = self.grade
		marker.max_amount = self.amount
		marker.depth_layer = self.depth_layer
		marker.revealed = true
		
		local deposit = marker:PlaceDeposit()
		if deposit then
			deposit:PickVisibilityState()
		end
	else
		sequence_player:Error(self, string.format("invalid anomaly"))
	end
end

DefineClass.SA_SpawnDustDevilAtAnomaly = {
	__parents = { "SequenceAction" },
	
	properties = {
		{ name = T{17, "Period, base (s)"}, id = "period", editor = "number", min = 0, max = 300*1000, scale = 1000, default = 30*1000 },
		{ name = T{18, "Period, random (s)"}, id = "period_random", editor = "number", min = 0, max = 300*1000, scale = 1000, default = 30*1000 },
		{ name = T{19, "Spawn Chance (%)"}, id = "probability", editor = "number", min = 0, max = 100, default = 30 },
		{ name = T{20, "Lifetime (s)"}, id = "lifetime", editor = "number", min = 0, max = 300*1000, scale = 1000, default = 60*1000 },
--		{ id = "range", editor = "number", min = 50, max = 500, scale = guim },
		{ name = T{21, "Speed (m/s)"}, id = "speed", editor = "number", min = 5*guim, max = 100*guim, scale = guim, default = 3*guim}
	},
	
	Menu = "Gameplay",
	MenuName = "Spawn Dust Devil at Anomaly",
	MenuSection = "Anomaly",
	RestrictToList = "Scenario",
	ip_template = "ipAnomaly",
}

function SA_SpawnDustDevilAtAnomaly:ShortDescription()
	return "Spawn dust devil"
end

function SA_SpawnDustDevilAtAnomaly:Exec(sequence_player, ip, seq, registers)
	local marker = PrefabFeatureMarker:new { FeatureType = "Dust Devils" }
	
	marker:SetVisible(false)
	marker:SetPos( registers.anomaly_pos )
	
	local descr = GetDustDevilsDescr()
	if descr and not descr.forbidden then	
		marker.thread = CreateDustDevilMarkerThread(descr, marker)
	end
end

function SubsurfaceAnomaly:GetDescription()
	return self.description or T{22, "Our scans have found some interesting readings in this Sector. Further analysis is needed.<newline><newline>Send an RC Explorer to analyze the Anomaly."}
end

function SubsurfaceAnomaly:GetDisplayName()
	return self.display_name
end

function OnMsg.GatherFXTargets(list)
	list[#list + 1] = "SubsurfaceAnomaly"
end

function City:InitBreakThroughAnomalies()
	local markers = GetObjects{
		class = "SubsurfaceAnomalyMarker",
		filter = function(a) return a.tech_action == "breakthrough" end
	}
	local rand, trand = self:CreateSessionRand("InitBreakThroughAnomalies")
	markers = table.shuffle(markers)
	local field = TechFields.Breakthroughs or ""
	assert(#field >= #markers, "Too many breakthrough anomalies found!")
	local techs = table.icopy(field)
	-- assign breakthrough tech to each marker
	local assigned = 0
	while assigned < #markers do
		local tech, idx = trand(techs)
		if not tech then
			break
		end
		if not self:IsTechDiscovered(tech.id) then
			assigned = assigned + 1
			markers[assigned].breakthrough_tech = tech.id
		end
		table.remove(techs, idx)
	end
	if #markers > assigned then
		print("Removing", #markers - assigned, "unassigned breakthrough anomaly markers.")
		for i = assigned + 1, #markers do
			DoneObject(markers[i])
		end
	end
end