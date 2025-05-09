--[[
	Component proprieties to implement a dynamic frame with a static item grid.
	All Rights Reserved
--]]

local ADDON, Addon = ...

function Addon.ItemGroup:LayoutTraits()
	local profile = self:GetProfile()
	return profile.columns, profile.itemScale, 37 + profile.spacing, self.Transposed
end

function Addon.TabGroup:LayoutTraits()
	return 0,1, 0,6
end

function Addon.CurrencyTracker:MaxWidth()
	return self.frame.ItemGroup:GetWidth() - 20
end