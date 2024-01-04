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
	return pairs(self.registry)
end


--[[ Built-In Skins ]]--

local border9S = function(f, ...) f:SetBorderColor(...) end
local center9s = function(f, ...) f:SetCenterColor(...) end
local vertexBg = function(f, ...) f.Bg:SetVertexColor(...) end

Skins:Register{ id = 'Bagnon', template = 'TooltipBackdropTemplate',
				borderColor = function(f, ...) f:SetBackdropBorderColor(...) end,
				centerColor = function(f, ...) f:SetBackdropColor(...) end }
Skins:Register{ id = 'Bubble', template = 'ChatBubbleTemplate',
				borderColor = function(f, ...) f:SetBorderColor(...); f.Tail:Hide() end }
Skins:Register{ id = 'Frame', template = 'BasicFrameTemplateWithInset', x=1,y=-6,y1=-6, inset=4,
				reset = function(f) f:GetParent().CloseButton:Show() end,
				load = function(f)
					f.CloseButton:SetScript('OnClick', function() ExecuteFrameScript(f:GetParent().CloseButton, 'OnClick') end)
					f:GetParent().CloseButton:Hide()
				end }
--Skins:Register{ id = 'Panel', template = 'DefaultPanelFlatTemplate',
--				load = function(f) f.NineSlice:SetFrameLevel(0) end }

Skins:Register{ id = 'Dialog', template = 'BagnonDialogSkinTemplate', borderColor = border9S, centerColor = vertexBg, x=-7,y=-7, x1=7,y1=7 }
Skins:Register{ id = 'Inset', template = 'BagnonInsetSkinTemplate', centerColor = vertexBg }
Skins:Register{ id = 'Flat', template = 'BagnonFlatSkinTemplate',
				reset = function(f) f:GetParent().Title:SetNormalFontObject(GameFontNormalLeft) end,
				centerColor = function(f, ...) f.Center:SetColorTexture(...) end,
				borderColor = function(f, ...)
					f:GetParent().Title:SetNormalFontObject(GameFontHighlightLeft)
					f.Top:SetColorTexture(...)
					f.Left:SetColorTexture(...)
					f.Right:SetColorTexture(...)
					f.Bottom:SetColorTexture(...)
				end }

--DefaultPanelTemplate
--ThinBorderTemplate