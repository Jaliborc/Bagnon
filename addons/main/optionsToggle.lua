--[[
	optionsToggle.lua
		A options frame toggle widget.
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Toggle = Addon.Tipped:NewClass('OptionsToggle', 'Button', ADDON .. 'MenuButtonTemplate')


--[[ Construct ]]--

function Toggle:New(parent)
	local button = self:Super(Toggle):New(parent)
	button.Icon:SetTexture('Interface/Icons/Trade_Engineering')
	button:SetScript('OnClick', button.OnClick)
	button:SetScript('OnEnter', button.OnEnter)
	button:SetScript('OnLeave', button.OnLeave)
	button:RegisterForClicks('anyUp')
	return button
end


--[[ Events ]]--

function Toggle:OnClick()
	if LoadAddOn(ADDON .. '_Config') then
		local frame = self:GetFrame()
		if frame then
			Addon.FrameOptions.frame = frame
			Addon.FrameOptions:Open()
		end
	end
end

function Toggle:OnEnter()
	GameTooltip:SetOwner(self:GetTipAnchor())

function Toggle:OnLeave()
	GameTooltip:Hide()
end
	GameTooltip:SetText(L.TipConfigure:format(L.Click))
end
