--[[
	Methods for registering and browsing skins for Bagnon frames.
	All Rights Reserved
--]]


local ADDON, Addon = ...
local Skins = Addon:NewModule('Skins', 'MutexDelay-1.0')
Skins.registry = {}


--[[ Public API ]]--

function Skins:Register(skin)
	assert(type(skin) == 'table', '#1 argument must be a table')
    assert(type(skin.id) == 'string', 'skin.id must be a string')
	assert(type(skin.template) == 'string', 'skin.template must be a string')

	self.registry[skin.id] = skin
	self:Delay(0, 'SendSignal', 'SKINS_LOADED')
end

function Skins:Get(id)
	return type(id) == 'string' and self.registry[id]
end

function Skins:Iterate()
	local skins = GetValuesArray(self.registry)
	sort(skins, function(a, b) return a.id < b.id end)
	return ipairs(skins)
end


--[[ Built-In Skins ]]--

local apply9S = function(name) return function(f) NineSliceUtil.ApplyLayout(f, NineSliceLayouts[name]) end end
local border9S = function(f, ...) f:SetBorderColor(...) end
local center9S = function(f, ...) f:SetCenterColor(...) end

local resetClose = function(f) f:GetParent().CloseButton:SetPoint('TOPRIGHT', -2, -2) end
local centerBG = function(f, ...) f.BG:SetColorTexture(...) end

Skins:Register { id = 'Bagnon', template = 'NineSliceCodeTemplate', load = apply9S('TooltipDefaultLayout'), borderColor = border9S, centerColor = center9S }
Skins:Register { id = 'Barber', template = 'NineSliceCodeTemplate', load = apply9S('CharacterCreateDropdown'), borderColor = border9S, x=-1,y=-20,y1=1 }
Skins:Register { id = 'Bubble', template = 'NineSliceCodeTemplate', load = apply9S('ChatBubble'), borderColor = border9S }
Skins:Register { id = 'Dialog', template = 'BagnonDialogSkinTemplate', borderColor = border9S, centerColor = centerBG, x=-7,y=-7, x1=7,y1=7 }
Skins:Register { id = 'Inset', template = 'BagnonInsetSkinTemplate', centerColor = centerBG }

Skins:Register {
	id = 'Panel - Flat', template = 'DefaultPanelFlatTemplate', reset = resetClose,
	x = -2, x1 = -2, y = Addon.IsRetail and 0 or -6, y1 = -6, inset = 2,
	load = function(f)
		f:GetParent().CloseButton:SetPoint('TOPRIGHT', 2, Addon.IsRetail and -6 or -2)
		f.TitleContainer:SetFrameLevel(0)
		f.NineSlice:SetFrameLevel(0)
	end
}

Skins:Register {
	id = 'Panel - Marble', template = 'BasicFrameTemplateWithInset', reset = resetClose,
	x = 1, y = -6, y1 = -6, inset = 4,
	load = function(f)
		f:GetParent().CloseButton:SetPoint('TOPRIGHT', Addon.IsRetail and 0 or 4, Addon.IsRetail and -5 or -1)
		f.CloseButton:Hide()
	end
}

Skins:Register {
	id = 'Thin', template = 'HelpPlateBox', centerColor = centerBG,
	borderColor = function(f, ...)
		for i = 1, select('#', f:GetRegions()) do
			local texture = select(i, f:GetRegions())
			if texture:GetDrawLayer() == 'BORDER' then
				texture:SetVertexColor(...)
			end
		end
	end
}