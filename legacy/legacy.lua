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

LibStub('LibItemCache-2.0'):Embed(Addon)