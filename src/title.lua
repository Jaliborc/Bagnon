--[[
	A title frame widget that can search on double-click
--]]


local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Title = Addon.Tipped:NewClass('Title', 'Button')


--[[ Construct ]]--

function Title:New(parent, title)
	local b = self:Super(Title):New(parent)
	b.title = title

	b:SetScript('OnHide', b.OnMouseUp)
	b:SetScript('OnMouseUp', b.OnMouseUp)
	b:SetScript('OnMouseDown', b.OnMouseDown)
	b:SetScript('OnDoubleClick', b.OnDoubleClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnClick', b.OnClick)
	b:RegisterSignal('SEARCH_TOGGLED', 'UpdateVisible')
	b:RegisterFrameSignal('OWNER_CHANGED', 'Update')
	b:RegisterForClicks('anyUp')
	b:SetToplevel(true)
	b:Update()

	return b
end


--[[ Interaction ]]--

function Title:OnEnter()
	self:ShowTooltip(self:GetText(), format('|L %s   |L|L %s', L.Drag, SEARCH), '|R ' .. OPTIONS)
end

function Title:OnMouseDown()
	local parent = self:GetParent()
	if not parent.profile.managed and (not Addon.sets.locked or IsAltKeyDown()) then
		parent:StartMoving()
	end
end

function Title:OnMouseUp()
	local parent = self:GetParent()
	parent:StopMovingOrSizing()
	parent:RecomputePosition()
end

function Title:OnDoubleClick()
	Addon.canSearch = true
	Addon:SendSignal('SEARCH_TOGGLED', self:GetFrameID())
end

function Title:OnClick(button)
	if button == 'RightButton' and LoadAddOn(ADDON .. '_Config') then
		Addon.FrameOptions.frame = self:GetFrameID()
		Addon.FrameOptions:Open()
	end
end


--[[ API ]]--

function Title:Update()
	self:SetFormattedText(self.title, self:GetOwner().name or ' ')
	self:GetFontString():SetAllPoints(self)
end

function Title:UpdateVisible(_, busy)
	self:SetShown(not busy)
end

function Title:IsFrameMovable()
	return not Addon.sets.locked
end

function Title:GetTipAnchor()
	return self, 'ANCHOR_TOPLEFT'
  end
