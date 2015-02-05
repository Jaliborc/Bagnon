--[[
	bagFrame.lua
		A container object for bags
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local BagFrame = Addon:NewClass('BagFrame', 'Frame')
BagFrame.Button = Addon.Bag


--[[ Constructor ]]--

function BagFrame:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))
	f:SetScript('OnShow', f.Layout)
	f.bags = {}
	f:Hide()

	for i, slot in ipairs(f:GetFrame().Bags) do
		f.bags[i] = f.Button:New(f, slot)
	end

	return f
end


--[[ Update ]]--

function BagFrame:Layout()
	local height, width = 0, 0
	local spacing, padding = 4, 0

	width = self.bags[1]:GetWidth() * #self.bags + spacing * (#self.bags - 1) + padding * 2
	height = self.bags[1]:GetHeight() + padding * 2

	local prev
	for i, bag in ipairs(self.bags) do
		if prev then
			bag:SetPoint('LEFT', prev, 'RIGHT', spacing, 0)
		else
			bag:SetPoint('LEFT', padding, 0)
		end
		bag:Show()
		prev = bag
	end

	self:SetWidth(width)
	self:SetHeight(height)
end