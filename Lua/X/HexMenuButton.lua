-- create up, down HexItems
DefineClass.HexButtonItem = {
	__parents = {"ItemMenuDef"},
	display_name = T{8664, "Uper Item definition"}, 
	icon = "UI/Icons/Buildings/academy_of_science.tga", 
	
	ButtonAlign = "top",
	HandleMouse = false,
	IdNode =  true,
	MinWidth =  260,
	MaxWidth =  260,
	RolloverZoom =  1100,
	RolloverDrawOnTop =  true,	
	prefabs = false,
	enabled = true,	
	Clip = false,
	RelativeFocusOrder = "next-in-line",
	
	int_fade_in = 20,
	int_fade_out = 500,
	int_perc = 1100,
	sel_fade_in = 500,
	sel_fade_out = 250,	
	highlighting = false,
	close_parent = true,
	hint = false,
	gamepad_hint = false,
} 

function HexButtonItem:Init()
	local top = self.ButtonAlign=="top"
	XImage:new( {
		Id =  "idSelection",
		Margins =  box(0, top and -55 or 0, 0, top and 0 or -55),
		FadeInTime =  self.sel_fade_in,
		FadeOutTime =  self.sel_fade_in,
		Image =  "UI/Common/watermark_shine_half.tga",
		Angle = top  and 180*60 or 0,
		VAlign =  self.ButtonAlign,
		HAlign =  "center",
	},self)
	--	"button",
	XTextButton:new( {
		Id =  "idButton",
		Shape =  "InHHex",
		HAlign =  "center",
		VAlign =  "top",
		MouseCursor =  "UI/Cursors/Rollover.tga",
		FXMouseIn =  "MainMenuItemHover",
		FXPress =  "MainMenuItemClick",
		FXPressDisabled =  "UIDisabledButtonPressed",
		DisabledBackground =  RGBA(120, 120, 120, 255),
		OnPressEffect =  "action",
		IconDisabledDesaturation = 255,
		SqueezeX =  true,
		SqueezeY =  true,
		ColumnsUse =  "abbbb",
		ScaleModifier = point(750, 750),
	},self)
	-- button image
	XImage:new( {
		Id =  "idShine",
		Margins =  box(-10, -10, -10, -10),
		ImageFit = "stretch",
		Image =  "UI/Common/Hex_2_shine.tga",
		Dock = "box",
	},self.idButton)
	
	-- lock image - idLockImage
	XImage:new( {
		Id =  "idLock",
		Margins = box(0, 0, 95, top and 0 or 70),
		FadeInTime =  100,
		FadeOutTime =  100,
		Image =  "UI/Icons/bmc_lock.tga",
		HAlign =  "right",
		VAlign =  "bottom",
		Dock = "box",
	},self)
	
	local prefabs = self.prefabs and UICity:GetPrefabs(self.name)
 	local locked = not self.enabled and not prefabs
	self.idLock:SetVisible(locked, "true")
	-- idNumPrefabs text & background
	XImage:new( {
		Id =  "idTextBkg",
		Margins =  box(10, 20, 10, 0),
		FadeInTime =  100,
		FadeOutTime =  100,
		Image =  "UI/Common/pin_shadow.tga",
		HAlign =  "center",
		VAlign =  "bottom",
		Dock = "box",
	},self.idButton)
	
	XText:new( {
		Id =  "idNumPrefabs",
		Padding =  box(2, 4, 2, 4),
		HAlign =  "center",
		VAlign =  "bottom",
		DisabledTextColor =  RGBA(128, 128, 128, 255),
		Translate =  true,
		TextFont = "BuildMenuBuilding",
		TextColor = RGBA(255, 254, 171, 255),
		Translate = true, 
		Dock = "box",
	},self.idButton)
	
	local show_uses_text = (not not prefabs) and (not self.enabled or prefabs > 0)	
	self.idButton.idNumPrefabs:SetVisible(show_uses_text, "true")
	self.idButton.idTextBkg:SetVisible(show_uses_text,"true")
	self.idButton.idNumPrefabs:SetText(Untranslated(prefabs))
	-- button title text 
	TextWithBkg:new({	
		Id = "idText", 
		image = "UI/Common/bm_name_shadow.tga", 
		Margins = box(0,  top and 0 or -15, 0, not top and 0 or -15),
	}, self)
	-- functions
	self.idButton.idShine:SetVisible(false, true)		
	
	self.idButton.SetRollover = function (this, ...)
		self:SetRollover(...)
		self.idButton.idShine:SetRollover(...)
		XTextButton.SetRollover(this, ...)
	end		
		
	-- align and settings
	local valign = self.ButtonAlign
	self:SetMargins(box(0, top and -28 or 0, 0, not top and -28 or 0))	
	self:SetVAlign(valign)
	self.idText:SetDock(valign)
	self.idText:SetText(self:GetName("", self))
	self.idButton:SetImage(self:GetIcon("", self))
	self:SetEnabled(self.enabled)
	self.idSelection:SetVisible(false, true)
	local parent = GetDialog(self)
	self.idButton.OnPress = function(this)
		if not self.enabled then return end
		if self.action then
			self.action(parent.context, self)
		end
		if self.close_parent then
			parent:Close()
		end
	end
end

function HexButtonItem:SetEnabled(bEnabled)
	self.enabled = bEnabled
	--self.idButton:SetEnabled(bEnabled)
	self.idButton:SetTransparency(bEnabled and 0 or 55)
	self.idButton.idIcon:SetDesaturation(bEnabled and 0 or 100)
	self.idButton.idShine:SetDesaturation(bEnabled and 0 or 100)
end	

function HexButtonItem:OnMouseEnter()
	self:SelectButton()
end

function HexButtonItem:FillRollover()
	if self.description then
		local parent = GetDialog(self)
		parent.idContainer:SetRolloverText(self.description or "")
		parent.idContainer:SetRolloverTitle(self.display_name or "")
		local gamepad = GetUIStyleGamepad()
		if gamepad then 
			parent.idContainer:SetRolloverHint(T{3545, "<ButtonA> Select"})
		end
		XUpdateRolloverWindow(parent.idContainer)	
	end	
end

function HexButtonItem:SelectButton()
	self.idSelection:SetVisible(not self.idLock:GetVisible())
	self.idButton.idShine:SetVisible(true)
	self.idText:OnMouseEnter()
	self:FillRollover()
	--[[if self:GetEnabled() then
		self.idButton:AddInterpolation{
			id = "zoom",
			type = const.intRect,
			duration = self.int_fade_in,
			startRect = self.idButton.box,
			endRect = self.idButton:CalcZoomedBox(self.int_perc),
		}
	end]]
end

function HexButtonItem:OnMouseLeft()
	self:DeselectButton()
end

function HexButtonItem:DeselectButton()
	self.idSelection:SetVisible(false)
	self.idButton.idShine:SetVisible(self.highlighting)
	self.idText:OnMouseLeft()
	--[[if self:GetEnabled() then
		self.idButton:AddInterpolation{
			id = "zoom",
			type = const.intRect,
			duration = self.int_fade_out,
			startRect = self.idButton.box,
			endRect = self.idButton:CalcZoomedBox(self.int_perc),
			flags = const.intfInverse,
			autoremove = true,
		}
	end]]
end

function HexButtonItem:SetHighlighting(visible)
	local element = self.idButton.idShine
	self.highlighting = visible
	if visible then
		element:SetVisible(true)
		local origianl_size = element.box
		local small_size = origianl_size:grow(-1)
		local big_size = origianl_size:grow(1)
		element:AddInterpolation{
			id = "HighlightAlpha",
			type = const.intAlpha,
			startValue = 80,
			endValue = 255,
			duration = 1500,
			flags = const.intfPingPong + const.intfLooping,
		}
		element:AddInterpolation{
			id = "HighlightZoom",
			type = const.intRect,
			startRect = small_size,
			endRect = big_size,
			duration = 1500,
			flags = const.intfPingPong + const.intfLooping,
		}
	else--if not visible then
		element:SetVisible(self:IsFocused())
		element:RemoveModifier("HighlightAlpha")
		element:RemoveModifier("HighlightZoom")
	end
end

----------------------------------------------
DefineClass.HexButtonResource = {
	__parents = {"HexButtonItem"},
}

function HexButtonResource:Init()
	self.idButton.AltPress = true
	local top = self.ButtonAlign=="top"
	self.idText:SetScaleModifier(point(1350, 1350))
	-- align and settings
	local valign = self.ButtonAlign
	self:SetMargins(box(0, top and -52 or 0, 0, not top and -54 or 0))	
	
	local parent = GetDialog(self)
	self.idButton.OnPress = function(this, gamepad)
		if not self:GetEnabled() then return end
		local meta = parent.context.meta_key and (gamepad or Platform.desktop and terminal.IsKeyPressed(parent.context.meta_key))
		if meta then
			if self.action then
				self.action(parent.context, meta)
				-- refresh rolllover				
				self:FillRollover()	
				XCreateRolloverWindow(parent.idContainer, gamepad, parent.context)
				self:SelectButton()
			end
		else
			UIL.Invalidate()
			if self.action then
				self.action(parent.context, false)
			end
			parent:Close()
		end
	end
	
	self.idButton.OnAltPress = function(this,gamepad)
		if self:GetEnabled() and parent.context.close_on_rmb then
			parent:Close()
		end
	end
end

function HexButtonResource:FillRollover()
	if self.description and self.description~="" then
		local parent = GetDialog(self)
		parent.idContainer:SetRolloverText(self.description)
		parent.idContainer:SetRolloverTitle(self.display_name)
		local gamepad = GetUIStyleGamepad()
		if gamepad then 
			parent.idContainer:SetRolloverHint(self.gamepad_hint or T{3545, "<ButtonA> Select"})
		else
			parent.idContainer:SetRolloverHint(self.hint or "")
		end
		XUpdateRolloverWindow(parent.idContainer)
	end	
end

----------------------------------------------------------------
DefineClass.HexButtonInfopanel = {
	__parents = {"HexButtonItem"},
}

function HexButtonInfopanel:Init()
	self.idButton.AltPress = true
	local top = self.ButtonAlign=="top"
	self.idLock.Image =  "UI/Icons/bmc_check.tga"
	self.idLock.Margins = box(0, 0, 94, top and 0 or 95)
	self.idText:SetScaleModifier(point(1350, 1350))
	self:SetMargins(box(0, top and -52 or 0, 0, not top and -54 or 0))	
	
	local parent = GetDialog(self)
	self.idButton.Press = function(this, alt, gamepad)	
		if alt and not gamepad then 
			parent:Close() 
			return
		end	
		if not self:GetEnabled() then return end
		if self.action then
			self.action(parent.context, alt and -1 or 1, gamepad)
			-- refresh rolllover
			self:FillRollover()
			parent:Close()
		end
	end	
end

function HexButtonInfopanel:FillRollover()
	if self.description and self.description~="" then
		local parent = GetDialog(self)
		parent.idContainer:SetRolloverText(self.description)
		parent.idContainer:SetRolloverTitle(self.display_name)
		local gamepad = GetUIStyleGamepad()
		if gamepad then 
			parent.idContainer:SetRolloverHint(self.gamepad_hint or "")
		else
			parent.idContainer:SetRolloverHint(self.hint or "")
		end
		XUpdateRolloverWindow(parent.idContainer)
	end	
end

----------------------------
--[[ItemMenuDef and can have the following members:
  - GetName(context, item) by default returns item.display_name
  - GetIcon by default returns item.icon
  - GetRolloverText by default returns item.RollverText
  - GetRolloverHint
  - anchor, anchor_type - used to position the window, by default bottom mid-screen
  - GetCount by default returns nil
  - GetState by default returns nil, can return "disabled" and "hidden"
  - GetCategory - by default returns nil
  --]]
DefineClass.ItemMenuDef = {
	__parents = {"XControl"},
} 

function ItemMenuDef:GetName(context, item)
	return item and item.display_name or ""
end

function ItemMenuDef:GetIcon(context, item)
	return item and item.icon or ""
end

function ItemMenuDef:GetRolloverText(context, item)
	return item and item.RollverText or ""
end

function ItemMenuDef:GetRolloverHint(context, item)
end

function ItemMenuDef:GetCount(context, item)
	return 
end

function ItemMenuDef:GetState(context, item)
	return 
end

function ItemMenuDef:GetCategory(context, item)
	return 
end

--[[
local item = UIItemMenu(context, items, item_def, categories, category_def)
--]]
