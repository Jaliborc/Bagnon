--[[
	optionsToggle.lua
		A options frame toggle widget
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local OptionsToggle = Addon:NewClass('OptionsToggle', 'Button')


--[[ Constructor ]]--

function OptionsToggle:New(parent)
	local b = self:Bind(CreateFrame('Button', nil, parent, ADDON .. 'MenuButtonTemplate'))
	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:RegisterForClicks('anyUp')

	local icon = b:CreateTexture(nil, 'BACKGROUND')
	icon:SetTexture([[Interface\Icons\Trade_Engineering]])
	icon:SetAllPoints(b)

	return b
end


--[[ Interaction ]]--

function OptionsToggle:OnClick()
	Addon:ShowOptions()
end

function OptionsToggle:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	GameTooltip:SetText(L.TipShowFrameConfig)
end

function OptionsToggle:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end
