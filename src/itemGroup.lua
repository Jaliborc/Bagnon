--[[
	The classic static item grid.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local Items = Addon.ItemGroup

function Items:LayoutTraits()
	local profile = self:GetProfile()
	return profile.columns, profile.itemScale, 37 + profile.spacing, self.Transposed
end