-- ========== THIS IS AN AUTOMATICALLY GENERATED FILE! ==========

PlaceObj('XTemplate', {
	__is_kind_of = "XWindow",
	group = "PreGame",
	id = "SaveLoadContentWindow",
	PlaceObj('XTemplateWindow', {
		'comment', "margins",
		'Margins', box(0, 80, 100, 80),
	}, {
		PlaceObj('XTemplateFunc', {
			'name', "Open",
			'func', function (self, ...)
XWindow.Open(self, ...)
self:SetMargins(GetSafeMargins(self:GetMargins()))
end,
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "DialogTitle",
		}),
		PlaceObj('XTemplateTemplate', {
			'__template', "ActionBar",
			'MinWidth', 300,
		}),
		PlaceObj('XTemplateWindow', {
			'Dock', "right",
		}, {
			PlaceObj('XTemplateWindow', {
				'MaxWidth', 500,
			}, {
				PlaceObj('XTemplateWindow', {
					'__class', "XContentTemplate",
					'Id', "idTopContent",
					'Dock', "top",
					'LayoutMethod', "VList",
				}, {
					PlaceObj('XTemplateWindow', {
						'__class', "XText",
						'Margins', box(0, 40, 0, -40),
						'HandleMouse', false,
						'TextFont', "PGListItem",
						'TextColor', RGBA(140, 140, 140, 255),
						'Translate', true,
						'Text', T{836192190578, --[[XTemplate SaveLoadContentWindow Text]] "<SyncInfo>"},
						'HideOnEmpty', true,
						'TextHAlign', "right",
					}),
					PlaceObj('XTemplateMode', {
						'mode', "save",
					}, {
						PlaceObj('XTemplateTemplate', {
							'__context', function (parent, context) return {id = 0} end,
							'__template', "SaveItem",
							'Id', "idNewSave",
							'Margins', box(0, 40, 0, 6),
							'OnPress', function (self, gamepad)
local obj = GetDialogContext(self)
local dlg = GetDialog(self)
obj:ShowNewSavegameNamePopup(dlg)
end,
						}, {
							PlaceObj('XTemplateFunc', {
								'name', "OnSetRollover(self, rollover)",
								'func', function (self, rollover)
XTextButton.OnSetRollover(self, rollover)
if rollover then
	ShowSavegameDescription(self.context, GetDialog(self))
end
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnMouseEnter",
								'func', function (self, ...)
self.parent:ResolveId("idList"):SetSelection(self.context.id)
XTextButton.OnMouseEnter(self, ...)
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnMouseLeft",
								'func', function (self, ...)
return "break"
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnShortcut(self, shortcut, source)",
								'func', function (self, shortcut, source)
if shortcut == "DPadUp" or shortcut == "LeftThumbUp" or shortcut == "Up"
	or shortcut == "DPadDown" or shortcut == "LeftThumbDown" or shortcut == "Down" then
	local dlg = GetDialog(self)
	local scroll = dlg.idScroll
	local current_page = scroll.current_page
	local page_info = scroll.page_info and scroll.page_info[current_page]
	if page_info then
		local list = dlg.idList
		if shortcut == "DPadUp" or shortcut == "LeftThumbUp" or shortcut == "Up" then
			if current_page > 1 then
				scroll:PreviousPage()
				list:SetFocus()
				list:SetSelection(page_info:y() - 1)
				dlg:UpdateActionViews(dlg.idActionBar)
			end
			return "break"
		elseif shortcut == "DPadDown" or shortcut == "LeftThumbDown" or shortcut == "Down" then
			local item_num = page_info:y()
			if list[item_num] then
				list:SetFocus()
				list:SetSelection(item_num)
				dlg:UpdateActionViews(dlg.idActionBar)
				return "break"
			end
		end
	end
end
end,
							}),
							}),
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
local dlg = GetDialog(parent)
dlg.idTitle:SetTitle(T{1133, "SAVE GAME"})
parent.idNewSave.idValue:SetText(T{4182, "<<< New Savegame >>>"})
parent.idNewSave:SetFocus()
dlg.idList:SetSelection(false)
dlg.idList:SetMargins(box(0,0,0,10))
dlg.idList:SetGamepadInitialSelection(false)
dlg.idList:SetForceInitialSelection(false)
local scroll = dlg.idScroll
scroll:SetForceFocusFirstItem(false)
scroll.NextPage = function()
	XPageScroll.NextPage(scroll)
	if dlg.Mode == "save" then
		dlg.idList:SetSelection(false)
		parent.idNewSave:SetFocus()
		dlg:UpdateActionViews(dlg.idActionBar)
	end
end
scroll.PreviousPage = function()
	XPageScroll.PreviousPage(scroll)
	if dlg.Mode == "save" then
		dlg.idList:SetSelection(false)
		parent.idNewSave:SetFocus()
		dlg:UpdateActionViews(dlg.idActionBar)
	end
end
end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "save",
							'ActionName', T{5467, --[[XTemplate SaveLoadContentWindow ActionName]] "SAVE"},
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonA",
							'OnAction', function (self, host, source, toggled)
local focused_item = host.idList.focused_item
if focused_item then
	host.idList[focused_item]:Press()
else
	host.idTopContent.idNewSave:Press()
end
end,
							'__condition', function (parent, context) return GetUIStyleGamepad() end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "delete",
							'ActionName', T{5451, --[[XTemplate SaveLoadContentWindow ActionName]] "DELETE"},
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonY",
							'ActionState', function (self, host)
local items = host.context.items
return (GetUIStyleGamepad() and not host.idList.focused_item or not items or #items <= 0) and "disabled"
end,
							'OnActionEffect', "mode",
							'OnActionParam', "delete",
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "cancel",
							'ActionName', T{5450, --[[XTemplate SaveLoadContentWindow ActionName]] "CANCEL"},
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "mode",
						}),
						}),
					PlaceObj('XTemplateMode', {
						'mode', "load",
					}, {
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
parent:ResolveId("idTitle"):SetTitle(T{1128, "LOAD GAME"})
end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "load",
							'ActionName', T{5466, --[[XTemplate SaveLoadContentWindow ActionName]] "LOAD"},
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonA",
							'ActionState', function (self, host)
local items = host.context.items
return (not items or #items == 0) and "disabled"
end,
							'OnAction', function (self, host, source, toggled)
LoadSaveGame(host)
end,
							'__condition', function (parent, context) return GetUIStyleGamepad() end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "delete",
							'ActionName', T{5451, --[[XTemplate SaveLoadContentWindow ActionName]] "DELETE"},
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonY",
							'ActionState', function (self, host)
local items = host.context.items
return (not items or #items == 0) and "disabled"
end,
							'OnActionEffect', "mode",
							'OnActionParam', "delete",
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "cancel",
							'ActionName', T{5450, --[[XTemplate SaveLoadContentWindow ActionName]] "CANCEL"},
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "mode",
						}),
						}),
					PlaceObj('XTemplateMode', {
						'mode', "delete",
					}, {
						PlaceObj('XTemplateCode', {
							'run', function (self, parent, context)
parent:ResolveId("idTitle"):SetTitle(T{5471, "DELETE GAME"})
local dlg = GetDialog(parent)
dlg.idList:SetMargins(box(0,40,0,10))
dlg.idList:SetGamepadInitialSelection(true)
dlg.idList:SetForceInitialSelection(true)
dlg.idScroll:SetForceFocusFirstItem(true)
end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "delete",
							'ActionName', T{5451, --[[XTemplate SaveLoadContentWindow ActionName]] "DELETE"},
							'ActionToolbar', "ActionBar",
							'ActionGamepad', "ButtonA",
							'ActionState', function (self, host)
local items = host.context.items
return (not items or #items == 0) and "disabled"
end,
							'OnAction', function (self, host, source, toggled)
DeleteSaveGame(host)
end,
							'__condition', function (parent, context) return GetUIStyleGamepad() end,
						}),
						PlaceObj('XTemplateAction', {
							'ActionId', "cancel",
							'ActionName', T{5450, --[[XTemplate SaveLoadContentWindow ActionName]] "CANCEL"},
							'ActionToolbar', "ActionBar",
							'ActionShortcut', "Escape",
							'ActionGamepad', "ButtonB",
							'OnActionEffect', "back",
						}),
						}),
					}),
				PlaceObj('XTemplateWindow', {
					'__class', "XContentTemplateList",
					'Id', "idList",
					'Margins', box(0, 40, 0, 10),
					'BorderWidth', 0,
					'Dock', "top",
					'LayoutVSpacing', 6,
					'Clip', false,
					'Background', RGBA(0, 0, 0, 0),
					'FocusedBackground', RGBA(0, 0, 0, 0),
					'VScroll', "idScroll",
					'ShowPartialItems', false,
					'ForceInitialSelection', true,
				}, {
					PlaceObj('XTemplateFunc', {
						'name', "OnShortcut(self, shortcut, source)",
						'func', function (self, shortcut, source)
if shortcut == "Pageup" or shortcut == "MouseWheelFwd" then
	self:ResolveId(self.VScroll):PreviousPage()
	return "break"
elseif shortcut == "Pagedown" or shortcut == "MouseWheelBack" then
	self:ResolveId(self.VScroll):NextPage()
	return "break"
elseif shortcut == "Delete" or shortcut == "ButtonY" then
	DeleteSaveGame(GetDialog(self))
	return "break"
elseif shortcut == "Up" or shortcut == "Down" then
	local dlg = GetDialog(self)
	if dlg.Mode == "save" then
		local scroll = self:ResolveId(self.VScroll)
		local current_page = scroll.current_page
		local page_info = scroll.page_info
		local focus = self.focused_item
		if shortcut == "Up" and focus == page_info[current_page]:y() then
			self:SetSelection(false)
			dlg.idTopContent.idNewSave:SetFocus()
			dlg:UpdateActionViews(dlg.idActionBar)
			return "break"
		elseif shortcut == "Down" and page_info[current_page + 1] and focus == (page_info[current_page + 1]:y() - 1) then
			scroll:NextPage()
			return "break"
		end
	end
end
return XContentTemplateList.OnShortcut(self, shortcut, source)
end,
					}),
					PlaceObj('XTemplateForEach', {
						'comment', "item",
						'array', function (parent, context) return context.items end,
						'__context', function (parent, context, item, i, n) return item end,
						'run_after', function (child, context, item, i, n)
child.idValue:SetText(context.text)
local metadata = context.metadata
if metadata and (metadata.corrupt or metadata.incompatible) then
	child.idCorrupted:SetVisible(true)
elseif PopsCloudSavesAllowed() then
	if metadata.paradox_user_hash and metadata.paradox_user_hash == g_ParadoxHashedUserId then
		local local_save = table.find_value(SaveStateData, "local_name", context.savename)
		local synced = local_save and local_save.is_synchronized
		child.idSynced:SetVisible(synced)
		child.idNotSynced:SetVisible(not synced)
		child.idDoNotSync:SetVisible(false)
	else
		child.idDoNotSync:SetVisible(true)
	end
end
end,
					}, {
						PlaceObj('XTemplateTemplate', {
							'__template', "SaveItem",
							'OnPress', function (self, gamepad)
local dlg = GetDialog(self)
local mode = dlg.Mode
if mode == "load" then
	LoadSaveGame(dlg)
elseif mode == "save" then
	local obj = GetDialogContext(dlg)
	obj:ShowNewSavegameNamePopup(dlg, self.context)
elseif mode == "delete" then
	DeleteSaveGame(dlg)
end
end,
						}, {
							PlaceObj('XTemplateFunc', {
								'name', "OnSetRollover(self, rollover)",
								'func', function (self, rollover)
XTextButton.OnSetRollover(self, rollover)
if rollover then
	ShowSavegameDescription(self.context, GetDialog(self))
end
end,
							}),
							PlaceObj('XTemplateFunc', {
								'name', "OnMouseEnter",
								'func', function (self, ...)
local id = self.context.id
local list = self.parent
if list.focused_item ~= id then
	list:SetSelection(id)
	local dlg = GetDialog(self)
	if dlg.Mode == "save" then
		XTextButton.OnMouseLeft(dlg.idTopContent.idNewSave)
	end
end
end,
							}),
							}),
						}),
					}),
				}),
			PlaceObj('XTemplateWindow', {
				'__class', "XPageScroll",
				'Id', "idScroll",
				'Dock', "bottom",
				'Target', "idList",
				'ForceFocusFirstItem', true,
			}),
			}),
		PlaceObj('XTemplateWindow', {
			'Id', "idDescription",
			'LayoutMethod', "VList",
			'Visible', false,
			'FadeInTime', 200,
			'FadeOutTime', 200,
		}, {
			PlaceObj('XTemplateWindow', {
				'__class', "XFrame",
				'IdNode', false,
				'Padding', box(20, 20, 20, 20),
				'HAlign', "center",
				'VAlign', "top",
				'MaxHeight', 370,
				'Image', "UI/Common/mod_image_shadow.tga",
				'FrameBox', box(20, 20, 20, 20),
			}, {
				PlaceObj('XTemplateWindow', {
					'__class', "XImage",
					'Id', "idImage",
					'Image', "UI/Mods/Placeholder.tga",
					'ImageFit', "smallest",
				}),
				}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idSavegameTitle",
				'TextFont', "PGModTitle",
				'TextColor', RGBA(255, 255, 255, 255),
				'RolloverTextColor', RGBA(255, 255, 255, 255),
				'ShadowType', "outline",
				'ShadowSize', 1,
				'ShadowColor', RGBA(32, 32, 32, 255),
				'Translate', true,
				'HideOnEmpty', true,
				'TextHAlign', "center",
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idLastUpdate",
				'TextFont', "PGPage",
				'TextColor', RGBA(202, 202, 202, 255),
				'RolloverTextColor', RGBA(202, 202, 202, 255),
				'ShadowType', "outline",
				'ShadowSize', 2,
				'ShadowColor', RGBA(70, 70, 70, 255),
				'Translate', true,
				'HideOnEmpty', true,
				'TextHAlign', "center",
			}),
			PlaceObj('XTemplateWindow', {
				'__class', "XText",
				'Id', "idPlaytime",
				'TextFont', "PGPage",
				'TextColor', RGBA(202, 202, 202, 255),
				'RolloverTextColor', RGBA(202, 202, 202, 255),
				'ShadowType', "outline",
				'ShadowSize', 2,
				'ShadowColor', RGBA(70, 70, 70, 255),
				'Translate', true,
				'HideOnEmpty', true,
				'TextHAlign', "center",
			}),
			PlaceObj('XTemplateWindow', {
				'Margins', box(170, 0, 150, 0),
				'LayoutMethod', "VList",
			}, {
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idProblem",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idCoordinates",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idSols",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idSponsor",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idCommanderProfile",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idActiveMods",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idActiveGameRules",
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				PlaceObj('XTemplateWindow', {
					'__class', "XText",
					'Id', "idDelInfo",
					'Margins', box(0, 20, 0, 0),
					'TextFont', "PGPage",
					'TextColor', RGBA(202, 202, 202, 255),
					'RolloverTextColor', RGBA(202, 202, 202, 255),
					'ShadowType', "outline",
					'ShadowSize', 2,
					'ShadowColor', RGBA(70, 70, 70, 255),
					'Translate', true,
					'HideOnEmpty', true,
				}),
				}),
			}),
		}),
})

