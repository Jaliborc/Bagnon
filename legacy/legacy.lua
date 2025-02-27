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

function Addon.Rules:New(data, title, icon, filter)
	if type(data) == 'string' then
		self:Register {id = data, title = title, icon = icon, filter = filter }
	else
		self:Register(data)
	end
end

LibStub('LibItemCache-2.0'):Embed(Addon)