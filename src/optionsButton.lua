--[[
	A options frame toggle button.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local Toggle = Addon.Tipped:NewClass('OptionsToggle', 'Button', ADDON .. 'MenuButtonTemplate')

function Toggle:New(parent)
	local b = self:Super(Toggle):New(parent)
	b.Icon:SetTexture('Interface/Icons/Trade_Engineering')
	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:RegisterForClicks('anyUp')
	return b
end

function Toggle:OnClick()
	if LoadAddOn(ADDON .. '_Config') then
		Addon.FrameOptions.frame = self:GetFrameID()
		Addon.FrameOptions:Open()
	end
end

function Toggle:OnEnter()
	self:ShowTooltip(OPTIONS)
end
