--[[
	legacy.lua
		Emulates old APIs to support outdated plugins
		Do not implement plugins using this code
--]]

local ADDON, Addon = ...
Addon.ItemSlot = Addon.Item

function Addon.Item:GetItem()
	return self.info.link
end

local createRule = Addon.Rules.New
function Addon.Rules:New(id, title, icon, filter)
	if type(id) == 'string' then
		createRule(Addon.Rules, {id = id, title = title, icon = icon, filter = filter})-- backwards compatibility
	else
		createRule(Addon.Rules, id)
	end
end

LibStub('LibItemCache-2.0'):Embed(Addon)