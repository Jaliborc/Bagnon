--[[
	Methods for registering and browsing skins for Bagnon frames.
	All Rights Reserved
--]]


local ADDON, Addon = ...
local Skins = Addon:NewModule('Skins', 'MutexDelay-1.0')
Skins.registry = {}


--[[ Public API ]]--

function Skins:New(skin)
	assert(type(skin) == 'table', '#1 argument must be a table')
    assert(type(skin.id) == 'string', 'skin.id must be a string')

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

local function copy(to, from) return setmetatable(to, {__index = from}) end
local NS = NineSliceLayouts

Skins:New(copy({id = 'Bagnon'}, NS.TooltipDefaultLayout))
Skins:New(copy({id = 'Bubble', bgColor=false}, NS.ChatBubble))
Skins:New(copy({id = 'Dialog', x=-6,y=-5,x1=6,y1=6, Center=copy({x=-22,y=22,x1=22,y1=-22}, NS.TooltipMixedLayout.Center)}, NS.Dialog))
Skins:New(copy({id = 'Barber', x=-2,y=-19,x1=2,y1=2, bgColor=false}, NS.CharacterCreateDropdown))

