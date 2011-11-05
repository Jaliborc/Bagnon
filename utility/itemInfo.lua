--[[
	itemInfo.lua
		Generic methods for accessing item slot information
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Cache = LibStub('LibItemCache-1.0')

function Bagnon:GetItemInfo(...)
	return Cache:GetItemInfo(...)
end

function Bagnon:IsItemLocked(...)
  return select(3, self:GetItemInfo(...))
end

function Bagnon:IsItemCached(...)
	return select(8, self:GetItemInfo(...))
end