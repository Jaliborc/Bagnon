--[[
	Data specific to Bagnon
--]]

local ADDON, Addon = ...
local apply9S = function(name) return function(f) NineSliceUtil.ApplyLayout(f, NineSliceLayouts[name]) end end
local center9S = NineSlicePanelMixin.SetCenterColor
local border9S = NineSlicePanelMixin.SetBorderColor

Addon.Slash = 'bgn'
Addon.Skins.Default = 'Bagnon'
Addon.Skins:Register { id = 'Bagnon', template = 'NineSliceCodeTemplate', load = apply9S('TooltipDefaultLayout'), centerColor = center9S, borderColor = border9S }
Addon.Skins:Register { id = 'Barber', template = 'NineSliceCodeTemplate', load = apply9S('CharacterCreateDropdown'), borderColor = border9S, x=-1,y=-20,y1=1 }
Addon.Skins:Register { id = 'Bubble', template = 'NineSliceCodeTemplate', load = apply9S('ChatBubble'), borderColor = border9S }
Addon.Skins:Register { id = 'Dialog', template = 'BagnonDialogSkinTemplate', centerColor = center9S, borderColor = border9S, x=-7,y=-7, x1=7,y1=7 }
Addon.Skins:Register { id = 'Inset', template = 'BagnonInsetSkinTemplate', centerColor = center9S }
Addon.Skins:Register { id = 'OnePixel', template = 'BagnonOnePixelTemplate', centerColor = center9S, borderColor = border9S }

Addon.Skins:Register {
	id = 'Panel - Flat', template = 'DefaultPanelFlatTemplate', font = GameFontNormalCenter, fontH = GameFontHighlightCenter,
	x = -2, x1 = -2, y = Addon.IsRetail and 0 or -6, y1 = -6, inset = 2, closeX = 4, closeY = Addon.IsRetail and -4,
	load = function(f)
		f.TitleContainer:SetFrameLevel(0)
		f.NineSlice:SetFrameLevel(0)
	end
}

Addon.Skins:Register {
	id = 'Panel - Marble', template = 'BasicFrameTemplateWithInset', font = GameFontNormalCenter, fontH = GameFontHighlightCenter,
	x = 1, y = -6, y1 = -6, inset = 4, closeX = Addon.IsRetail and 2 or 6, closeY = Addon.IsRetail and -3 or 1,
	load = function(f) f.CloseButton:Hide() end
}

Addon.Skins:Register {
	id = 'Thin', template = 'HelpPlateBox', font = GameFontHighlightLeft,
	centerColor = function(f, ...) f.BG:SetColorTexture(...) end,
	borderColor = function(f, ...)
		for i = 1, select('#', f:GetRegions()) do
			local texture = select(i, f:GetRegions())
			if texture:GetDrawLayer() == 'BORDER' then
				texture:SetVertexColor(...)
			end
		end
	end
}