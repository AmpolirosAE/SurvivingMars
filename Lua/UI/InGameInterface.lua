if FirstLoad then
	InGameInterfaceMode = false
end

GlobalVar("g_FXBuildingType", false)

function OnMsg.SelectedObjChange(obj, prev)
	local dlg = GetInGameInterfaceModeDlg()
	if not IsKindOf(dlg, "UnitDirectionModeDialog") then
		return
	end
	
	dlg:RemoveSelectionArrow()
	dlg:CreateSelectionArrow(obj)
end

GlobalVar("g_HexRanges", {})

local function update_hex_range(obj)
	if not obj or not IsValid(obj) then return end
	local rxs = obj:GetAttaches("RangeHexMultiSelectRadius") or empty_table
	for i = 1, #rxs do
		rxs[i].size = -1
		rxs[i]:SetScale(obj:GetSelectionRadiusScale())
	end
end

function ShowHexRanges(city, class)
	city = city or UICity
	
	if not g_Classes[class] or not g_Classes[class]:HasMember("GetSelectionRadiusScale") then
		return
	end
	
	if city.labels[class] then
		for _, bld in ipairs(city.labels[class]) do
			if not g_HexRanges[bld] then
				local obj = PlaceObject("RangeHexMultiSelectRadius")
				bld:Attach(obj)
				g_HexRanges[bld] = obj
				obj:SetScale(bld:GetSelectionRadiusScale())
			end
		end
	end
	if city.labels.ConstructionSite then
		for _, site in ipairs(city.labels.ConstructionSite) do
			if IsKindOf(site.building_class_proto, class) and not g_HexRanges[site] then
				local obj = PlaceObject("RangeHexMultiSelectRadius")
				site:Attach(obj)
				g_HexRanges[site] = obj
				update_hex_range(site)
			end
		end
	end	
end

function HideHexRanges(city, class)
	city = city or UICity
	
	if city.labels[class] then
		for _, bld in ipairs(city.labels[class]) do
			if g_HexRanges[bld] then
				DoneObject(g_HexRanges[bld])
				g_HexRanges[bld] = nil
			end
		end
	end
	if city.labels.ConstructionSite then
		for _, site in ipairs(city.labels.ConstructionSite) do
			if IsKindOf(site.building_class_proto, class) and g_HexRanges[site] then
				DoneObject(g_HexRanges[site])
				g_HexRanges[site] = nil
			end
		end
	end	
end

function UpdateHexRanges(city, class)
	if city.labels[class] then
		for _, bld in ipairs(city.labels[class]) do
			update_hex_range(bld)
		end
	end
	if city.labels.ConstructionSite then
		for _, site in ipairs(city.labels.ConstructionSite) do			
			if IsKindOf(site.building_class_proto, class) then
				update_hex_range(site)
			end
		end
	end	
end

function OnMsg.SelectedObjChange(obj, prev)
	if g_FXBuildingType then
		if not obj or obj.class ~= g_FXBuildingType.class then
			HideHexRanges(UICity, g_FXBuildingType.class)
		else
			UpdateHexRanges(UICity, g_FXBuildingType.class)
		end
		-- ignore 'prev' so "end" is not fired twice
		PlayFXBuildingType("Select", "end", g_FXBuildingType.city, g_FXBuildingType.class, obj)
		g_FXBuildingType = false
	end

	local bld = GetBuildingObj(obj)
	if bld and (bld.show_range_all or g_BCHexRangeEnable[bld.class]) then
		-- ignore 'obj' so "start" is not fired twice
		PlayFXBuildingType("Select", "start", obj.city, bld.class, obj)	
		g_FXBuildingType = { city = obj.city, class = bld.class }
		ShowHexRanges(UICity, bld.class)
	end
end

function ResetRTSCamera()
	local igi = GetInGameInterface()
	if not CameraTransitionThread and igi and igi:GetVisible() and GetInGameInterfaceMode() ~= "overview" then
		local eye = cameraRTS.GetEye()
		local lookat = cameraRTS.GetLookAt()
		local v = SetLen(eye:SetInvalidZ() - lookat, const.DefaultCameraRTS.LookatDist*guim)
		v = RotateAxis(v, axis_z, 90*60 - CalcOrientation(lookat + v, lookat))
		eye = lookat + v
		eye = eye:SetZ((lookat:z() or 0 ) + const.DefaultCameraRTS.MaxHeight*guim)
		cameraRTS.SetCamera(eye, lookat, 100)
		local min, max = cameraRTS.GetZoomLimits()
		cameraRTS.SetZoom((min+max)/2, 100)
	end
end

function ViewObjectMars(obj, ...)
	if not IsValid(obj) and not IsPoint(obj) then return end
	CreateRealTimeThread(function(obj, ...)
		local dlg = GetInGameInterface()
		if dlg and dlg.mode == "overview" then
			dlg.mode_dialog.saved_camera = nil
			dlg.mode_dialog.target_obj = obj
			dlg:SetMode("selection")
		elseif not CameraTransitionThread then
			ViewObjectRTS(obj, ...)
		end
	end, obj, ...)
end

function ViewAndSelectObject(obj)
	SelectObj(obj)
	ViewObjectMars(obj)
end

function ViewAndSelectDome(obj)
	SelectObj(obj)
	
	local cur_pos, cur_la = cameraRTS.GetPosLookAt()
	local radius = obj:GetRadius()
	local dx, dy = (cur_la - cur_pos):xy()
	local norm = SetLen(point(-dy, dx, 0), radius)
	local la = obj:GetPos() + norm
	local pos = la - SetLen(point(dx, dy, 0), radius/3) + point(0, 0, radius/3)
	
	ViewObjectMars(la, nil, pos, 7000)
end

IGIModeClasses = {}
function OnMsg.ClassesBuilt()
	local classes = ClassDescendantsList("InterfaceModeDialog")
	for i=1,#classes do
		IGIModeClasses[g_Classes[classes[i]].mode_name] = classes[i]
	end
end

DefineClass.InGameInterface = {
	__parents = { "XDialog" }, 
	mode = false,
	switching_mode = false,
	mode_dialog = false,
	Dock = "box",
}

function InGameInterface:Open(...)
	XDialog.Open(self, ...)
	XVignetteOverlay:new({}, self)
	self.idVignetteOverlay:SetVisible(false)
	self:SetFocus()
	self:SetMode("selection")
	ShowMouseCursor("InGameInterface")
	OpenXDialog("HUD", self, UICity)
	OpenXDialog("OnScreenIndication", self)
	
	HideGamepadCursorReasons = false
	if GetUIStyleGamepad() then 
		-- instead of ShowGamepadCursor because the ingameinterface is not created yet and creates gamepad cursor as child of desktop
		local dlg = GetGamepadCursor()
		if dlg then
			dlg:SetParent(self)
		end
	end
	local popup = GetDialog("PopupNotification")
	if popup and popup.parent ~= self then
		popup:SetParent(self)
		popup:SetFocus()
		popup:SetModal()
	end
	local infopanel = GetXDialog("Infopanel")
	if infopanel and infopanel.parent ~= self then
		infopanel:SetParent(self)
	end
	Msg("InGameInterfaceCreated", self)
end

function InGameInterface:GetVignette()
	return self.idVignetteOverlay
end

function InGameInterface:Close(...)
	XDialog.Close(self, ...)
	HideMouseCursor("InGameInterface")
	InGameInterfaceMode = false
end

local LastZoomOut = 0
local ZoomOutCount = 0

local FirstZoomAll = now()
local FirstZoom = 0

function OnMsg.NewMap()
	LastZoomOut = 0
	ZoomOutCount = 0
	FirstZoomAll = 0
	FirstZoom = 0
end

function InGameInterface:CheckAboveZoomLimit()
	if self.mode == "selection" and editor.Active == 0 and not CameraTransitionThread and cameraRTS.IsActive() then
		if now() - FirstZoomAll > 500 then
			FirstZoomAll = now()
			FirstZoom = cameraRTS.GetZoom()
		end
		local minZoom, maxZoom = cameraRTS.GetZoomLimits()
		if cameraRTS.GetZoom() >= maxZoom then
			if now() - LastZoomOut < 500 then
				ZoomOutCount = ZoomOutCount + 1
			else
				ZoomOutCount = 1
			end
			LastZoomOut = now()
			if ZoomOutCount > 4 and FirstZoom == maxZoom then
				self:SetMode("overview")
				LastZoomOut = now()
				return "break"
			end
		end
	end

	return "continue"
end

function InGameInterface:CheckBelowZoomLimit()
	if self.mode == "overview" and not CameraTransitionThread then
		self.mode_dialog.saved_camera = nil
		self.mode_dialog.exit_to = GetTerrainCursor()
		self:SetMode("selection")
		return "break"
	end

	return "continue"
end

function InGameInterface:OnMouseWheelForward(...)
	if AccountStorage and AccountStorage.Options and AccountStorage.Options.InvertMouseWheel then
		return self:CheckAboveZoomLimit()
	end
	return self:CheckBelowZoomLimit()
end

function InGameInterface:OnMouseWheelBack(...)
	if AccountStorage and AccountStorage.Options and AccountStorage.Options.InvertMouseWheel then
		return self:CheckBelowZoomLimit()
	end
	return self:CheckAboveZoomLimit()
end

function InGameInterface:OnXButtonDown(button, controller_id)
	if self.desktop:GetModalWindow() == self.desktop and self.mode_dialog then
		if self.mode_dialog:OnXButtonDown(button, controller_id)=="break" then
			return "break"
		end
		local dlg = GetDialog("Infopanel")
		if dlg and IsKindOf(dlg.context,"ResourceOverview") then
			return ResourceOverviewObj:OnShortcut(button)
		end
	end
	return "continue"
end

function InGameInterface:OnXButtonUp(button, controller_id)
	if self.desktop:GetModalWindow() == self.desktop and self.mode_dialog then
		return self.mode_dialog:OnXButtonUp(button, controller_id)
	end

	return "continue"
end

function InGameInterface:OnShortcut(shortcut, source)
	local desktop = self.desktop
	if desktop:GetModalWindow() == desktop and self.mode_dialog and desktop.keyboard_focus and not desktop.keyboard_focus:IsWithin(self.mode_dialog) then
		if self.mode_dialog:OnShortcut(shortcut, source)=="break" then
			return "break"
		end	
	end
	local dlg = GetDialog("Infopanel")
	if dlg and IsKindOf(dlg.context,"ResourceOverview") then
		return ResourceOverviewObj:OnShortcut(shortcut, source)
	end
end

function InGameInterface:OnDesktopSize()
	local children = self.children
	for i, child in ipairs(children) do
		if child:IsKindOf("Window") then
			child:SetWindowScale(GetUIScale())
			Window.OnDesktopSize(child)
		end
	end
	if GetUIStyleGamepad() then
		HideGamepadCursor()
		ShowGamepadCursor()
	end
end

function OnMsg.GamepadUIStyleChanged(...)
	if GetUIStyleGamepad() then
		HideGamepadCursor()
		ShowGamepadCursor()
	end
end

function InGameInterface:RecalcWindowScale()
	self:SetWindowScale(GetUIScale())
end

function InGameInterface:SetMode(mode, params)
	self.switching_mode = true
	if self.mode_dialog then
		self.mode_dialog:Close()
	end
	local class_name = IGIModeClasses[mode]
	local class = class_name and g_Classes[class_name]
	assert(class and class:IsKindOf("InterfaceModeDialog"))
	self.mode_dialog = OpenXDialog(class_name, self, params)
	self.mode = mode
	InGameInterfaceMode = mode
	if IsKindOfClasses(SelectedObj, "DroneBase", "Colonist") and self.mode_dialog:IsKindOf("UnitDirectionModeDialog") then
		self.mode_dialog:ActivateUnitControl(SelectedObj, SelectedObj.start_player_controllable)
	end
	if self.mode == "selection" then
		--resurrect infopanel
		if SelectedObj or ShowResourceOverview then
			ReopenSelectionXInfopanel()
		end
	end
	if self.mode == "overview" then
		--close any open infopanels
		CloseXInfopanel()
	end
	--close the gamepad menu when switching modes
	CloseXGamepadMainMenu()
	self.switching_mode = false
	Msg("UIModeChange", mode)
end

function InGameInterface:SetVisible(bShow, instant)
	XDialog.SetVisible(self, bShow, instant)
	if bShow then
		ShowGamepadCursor("ingame_interface_hidden")
	else
		HideGamepadCursor("ingame_interface_hidden")
	end
	UpdateCrosshairVisibility()
end

function InGameInterface:OnSetFocus()
	local pins = GetDialog("PinsDlg")
	if pins then pins:UpdateGamepadHint() end
end

function InGameInterface:OnKillFocus()
	local pins = GetDialog("PinsDlg")
	if pins then pins:UpdateGamepadHint() end
end

function GetInGameInterface()
	return GetXDialog("InGameInterface")
end

function GetInGameInterfaceMode()
	return InGameInterfaceMode
end

function GetInGameInterfaceModeDlg()
	local dlg = GetInGameInterface()
	return dlg and dlg.mode_dialog
end

function ShowInGameInterface(bShow, instant)
	if not mapdata.GameLogic then
		return
	end
	if not bShow and not GetInGameInterface() then 
		return
	end
	local dlg = OpenXDialog("InGameInterface")
	dlg:SetVisible(bShow, instant)
	dlg.desktop:RestoreFocus()
end

-- deactivate mode dialog and set it to select
function CloseModeDialog()
	local igi = GetInGameInterface()
	if igi then
		local dlg = GetDialog("HUD")
		if dlg then dlg.idtxtConstructionStatus:SetVisible(false) end
		igi:SetMode("selection")
	end
end

function RefreshSectorInfopanel(sector)
	if IsKindOf(sector, "MapSector") then
		local dlg = GetInGameInterfaceModeDlg()
		if dlg and dlg.mode_name == "overview" then
			dlg:UpdateSectorRollover(sector)
		end
	end
end

function OnMsg.CityStart()
	ShowInGameInterface(true)
	CreateRealTimeThread(function()
		-- wait for the game to boot so we have the camera properly initialized
		LoadingScreenOpen("idLoadingScreen", "OverviewCameraInit")
		WaitRenderMode("scene")
		WaitNextFrame()
		Sleep(100)
		while true do
			local eye, lookat = cameraRTS.GetEye(), cameraRTS.GetLookAt()
			
			if eye and eye ~= InvalidPos() and lookat and lookat ~= InvalidPos() then
				break
			end
			Sleep(5)
		end
		
		LoadingScreenClose("idLoadingScreen", "OverviewCameraInit")

		local igi = GetInGameInterface()
		if not igi then return end
		igi:SetMode("overview", {camera_transition_time = 0, exit_to = g_InitialSector and g_InitialSector.area:Center()}) -- make the transition immediate
		igi.mode_dialog.camera_transition_time = nil -- restore to default for a smooth zoom in
		WaitLoadingScreenClose()
		igi = GetInGameInterface()
		if not igi then return end
		if not g_Tutorial then
			ShowStartGamePopup()
		end
	end)
end

function OnMsg.DoneMap()
	local dlg = GetInGameInterface()
	if dlg then
		if dlg.mode_dialog then
			dlg.mode_dialog:DoneMap()
		end
		dlg:delete()
	end
end

function OnGameEnterEditor()
	ShowInGameInterface(false)
	HideExploration()
	ShowPauseDialog(false, "force")
	if GetInGameInterfaceMode() == "overview" then
		local dlg = GetInGameInterfaceModeDlg()
		if dlg and IsValid(dlg.sector_obj) then
			dlg.sector_obj:ClearEnumFlags(const.efVisible)
		end
		local dlgOverviewMapCurtains = GetDialog("OverviewMapCurtains")
		if dlgOverviewMapCurtains then
			dlgOverviewMapCurtains:SetVisible(false)
		end
	end
	UnlockCamera("overview")
end

function OnGameExitEditor()
	ShowInGameInterface(true)
	if GetTimeFactor() == 0 then
		ShowPauseDialog(true)
	end
	if GetInGameInterfaceMode() == "overview" then
		local dlg = GetInGameInterfaceModeDlg()
		LockCamera("overview")
		ShowExploration()
		if IsValid(dlg.sector_obj) then
			dlg.sector_obj:SetEnumFlags(const.efVisible)
			dlg:OnMousePos()
		end
		local dlgOverviewMapCurtains = GetDialog("OverviewMapCurtains")
		if dlgOverviewMapCurtains then
			dlgOverviewMapCurtains:SetVisible(true)
		end
	end
end

OnMsg.GameEnterEditor = OnGameEnterEditor
OnMsg.GameExitEditor = OnGameExitEditor

oldReloadMap = ReloadMap
function ReloadMap()
	oldReloadMap(true)
end

function OnMsg.DesignerWindowMode(window)
	ShowInGameInterface(not window)
end

function OnMsg.SelectionChange()
	local dlg = GetInGameInterfaceModeDlg()
	if IsKindOf(dlg, "UnitDirectionModeDialog") then
		if IsKindOfClasses(SelectedObj, "DroneBase", "Colonist") then
			if SelectedObj ~= dlg.unit then
				if dlg.mode_name == "overview" then
					dlg.saved_camera = nil
					dlg.target_obj = SelectedObj			
				end
				SetUnitControlInteractionMode(dlg.unit, false)
				dlg:ActivateUnitControl(SelectedObj, SelectedObj.start_player_controllable)
			end
		else
			dlg:DeactivateUnitControl()
		end
	end

	ReopenSelectionXInfopanel()
end

function OnMsg.PersistSave(data)
	if GetInGameInterfaceMode() == "overview" then
		local dlg = GetInGameInterfaceModeDlg()
		data.InGameInterface_OverviewState = {
			camera_transition_time = 0,
			exit_to = dlg.exit_to,
			saved_camera = dlg.saved_camera,
			saved_angle = dlg.saved_angle,
			saved_dist = dlg.saved_dist,
		}
	end
end

InGameInterface_OverviewState = false

function OnMsg.PersistLoad(data)
	InGameInterface_OverviewState = data.InGameInterface_OverviewState or false
end

function RestoreInGameInterfaceOnLoadGame()
	ShowInGameInterface(true)
	CameraTransitionThread = false
	for reason, _ in pairs(s_CameraLockReasons) do
		UnlockCamera(reason)
	end
	
	if InGameInterface_OverviewState then
		SetDefaultCameraRTS() -- initialize, needed when game is loaded without ever going on a map
		local igi = GetInGameInterface()
		
		-- set overview camera
		igi:SetMode("overview", { camera_transition_time = 0 } )
		WaitMsg("CameraTransitionEnd")
		
		-- restore parameters to return to normal camera
		local dlg = igi.mode_dialog
		dlg.exit_to = InGameInterface_OverviewState.exit_to
		dlg.saved_camera = InGameInterface_OverviewState.saved_camera
		dlg.saved_angle = InGameInterface_OverviewState.saved_angle
		dlg.saved_dist = InGameInterface_OverviewState.saved_dist
		dlg.camera_transition_time = nil 
	end
	
	SelectObj()
	
	ShowNotifications()
	OpenXDialog("PinsDlg", GetInGameInterface())
	local time_factor = GetTimeFactor()
	SetTimeFactor(time_factor)
	GetOnScreenHintDlg()
	
	--DO NOT use IsPaused() here, it always returns 1
	if time_factor == 0 then
		OpenMarsPauseDlg()
	end
end

function CloseMenuDialogs()
	local menu = GetXDialog("IGMainMenu") or GetXDialog("PGMainMenu")
	if menu and menu.window_state ~= "destroying" then
		CloseXDialog(menu)
	end
end

function ToggleOverviewMode()
	local dlg = GetInGameInterface()
	if dlg and not CameraTransitionThread and not Dialogs.EarthPlanetDlg then
		dlg:SetMode(dlg.mode == "overview" and "selection" or "overview")
	end
end

function DeployOrbitalProbe()
	local dlg = GetInGameInterface()
	if dlg and dlg.mode == "overview" then
		dlg.mode_dialog:DeployProbe()
	end
end

if Platform.developer then

GlobalVar("g_OffgameOverview", false)

function ToggleOffGameOverview()
	local map = GetMapName()
	if true or IsEditorActive() or map == "" or map == "PreGame" then
		return
	end

	if not g_OffgameOverview then
		g_OffgameOverview = {}
		local old_pos = cameraRTS.GetEye()
		local old_lookat = cameraRTS.GetLookAt()
		local angle = 45*60
		
		local pos, lookat = CalcOverviewCameraPos(angle)
		
		pos = lookat + MulDivRound((pos - lookat), 1000, cameraRTS.GetZoom())
		g_OffgameOverview.saved_camera = { 
			eye = old_lookat + MulDivRound((old_pos - old_lookat), 1000, cameraRTS.GetZoom()), 
			lookat = old_lookat,
		}
		
		LockCamera("overview")
		table.change(hr, "overview", {
			FarZ = 1500000,
			ShadowRangeOverride = 1500000,
			ShadowFadeOutRangePercent = 0,
			NearZ = 1000
		})
		cameraRTS.SetCamera(pos, lookat, 0)
		camera.SetAutoFovX(1, 0, const.Camera.OverviewFovX_4_3, 4, 3, const.Camera.OverviewFovX_16_9, 16, 9)
	else
		cameraRTS.SetCamera(g_OffgameOverview.saved_camera.eye, g_OffgameOverview.saved_camera.lookat, 0)
		camera.SetAutoFovX(1, 0, const.Camera.DefaultFovX_16_9, 16, 9)
		table.restore(hr, "overview")
		UnlockCamera("overview")
		g_OffgameOverview = false
	end
end

function AddModifiersRolloverInfo(infopanel, obj)
	if not config.BuildingInfopanelCheats then
		return
	end
	
	if not IsKindOf(obj, "Modifiable") then
		return
	end
	local descr = {}
	for name, mods in pairs(obj.modifications or empty_table) do
		descr[#descr + 1] = string.format("<left>%s<right>%d, %d%%", name, mods.amount, mods.percent - 100)
		for i=1,#mods do
			local mod = mods[i]
			descr[#descr + 1] = string.format("<left>    %d. %s<right>%d, %d%%", i, mod.id, mod.amount, mod.percent)
		end
	end
	descr = Untranslated(table.concat(descr, '\n'))
	local rollover_t = { content = {title = T{4064, "Modifiers"}, descr = descr}, }
	local name = T{27, "Cheats"}
	local text = TDevModeGetEnglishText(name)
	local cheats_entry
	for i=1,#infopanel do
		local entry = infopanel[i]
		if type(entry)=="function" then
			entry = entry(obj)
		end
		if entry then
			for j=1,#entry do
				if type(entry[j]) == "table" and entry[j].section then
					entry = entry[j]
					break
				end
			end
		end
		if entry and type(entry.section) == "table" and TDevModeGetEnglishText(entry.section.name) == text then
			cheats_entry = entry
			break
		end
	end
	if not cheats_entry then
		cheats_entry = { section = { name = name, icon = "UI/Icons/Sections/dust.tga" } }
		infopanel[#infopanel + 1] = cheats_entry
	end
	cheats_entry.section.rollover_t = rollover_t
	if #cheats_entry == 0 then
		cheats_entry[#cheats_entry + 1] = {id = false, ui = "space"}
	end
end

end -- Platform.developer
