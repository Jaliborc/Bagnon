--[[
	bagFrame.lua
		A container object for bags
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local BagFrame = Bagnon.Classy:New('Frame')
Bagnon.BagFrame = BagFrame


--[[ Constructor ]]--

function BagFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))
	f:Hide()

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

	f:SetFrameID(frameID)
	f:CreateBagSlots()
	f:UpdateEvents()

	return f
end

function BagFrame:CreateBagSlots()
	local bags = {}

	for i, slotID in self:GetBagSlots() do
		bags[i] = Bagnon.Bag:New(slotID, self:GetFrameID(), self)
	end

	self.bags = bags
end


--[[ Messages ]]--

function BagFrame:BAG_FRAME_SHOW(msg, frameID)
	if frameID == self:GetFrameID() then
		self:UpdateShown()
	end
end

function BagFrame:BAG_FRAME_HIDE(msg, frameID)
	if frameID == self:GetFrameID() then
		self:UpdateShown()
	end
end


--[[ Frame Events ]]--

function BagFrame:OnShow()
	self:Layout()
	self:SendMessage('BAG_FRAME_UPDATE_SHOWN', self:GetFrameID())
end

function BagFrame:OnHide()
	self:SendMessage('BAG_FRAME_UPDATE_SHOWN', self:GetFrameID())
end


--[[ Update Methods ]]--

function BagFrame:UpdateShown()
	if self:IsBagFrameShown() then
		if not self:IsShown() then
			UIFrameFadeIn(self, 0.1)
		end
	else
		self:Hide()
	end
end

function BagFrame:UpdateEvents()
	self:UnregisterAllMessages()

	self:RegisterMessage('BAG_FRAME_SHOW')
	self:RegisterMessage('BAG_FRAME_HIDE')
end

function BagFrame:Layout()
	if not self:IsVisible() then return end

	local width = 0
	local height = 0
	local spacing = self:GetSpacing()
	local padding = self:GetPadding()

	width = self.bags[1]:GetWidth() * #self.bags + spacing * (#self.bags - 1) + padding * 2
	height = self.bags[1]:GetHeight() + padding * 2

	local prev
	for i, bag in self:GetBags() do
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


--[[ Properties ]]--

function BagFrame:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateShown()
	end
end

function BagFrame:GetFrameID()
	return self.frameID
end

function BagFrame:GetBags()
	return ipairs(self.bags)
end


--[[ Frame Settings ]]--

function BagFrame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function BagFrame:IsBagFrameShown()
	return self:GetSettings():IsBagFrameShown()
end

function BagFrame:GetSpacing()
	return 4
end

function BagFrame:GetPadding()
	return 0
end

function BagFrame:GetBagSlots()
	return self:GetSettings():GetBagSlots()
end