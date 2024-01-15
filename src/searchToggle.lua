--[[
	A search toggle button.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Toggle = Addon.Tipped:NewClass('SearchToggle', 'CheckButton', ADDON .. 'MenuButtonTemplate')

function Toggle:New(parent)
	local b = self:Super(Toggle):New(parent)
	b.Icon:SetTexture('Interface/Icons/INV_Misc_Spyglass_03')
	b:SetScript('OnHide', b.UnregisterAll)
	b:SetScript('OnShow', b.OnShow)
	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:RegisterForClicks('anyUp')
	return b
end

function Toggle:OnShow()
	self:RegisterSignal('SEARCH_TOGGLED', 'OnToggle')
	self:OnToggle()
end

function Toggle:OnToggle()
	self:SetChecked(Addon.canSearch)
end

function Toggle:OnEnter()
	self:ShowTooltip(SEARCH)
end

function Toggle:OnClick()
	Addon.canSearch = self:GetChecked()
	Addon:SendSignal('SEARCH_TOGGLED', self:GetChecked() and self:GetFrameID())
end
