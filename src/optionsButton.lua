--[[
	A options frame toggle button.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local Toggle = Addon.Tipped:NewClass('OptionsToggle', 'Button', ADDON .. 'ButtonTemplate')
local C = LibStub('C_Everywhere')

function Toggle:New(parent)
	local b = self:Super(Toggle):New(parent)
	b.Icon:SetTexture('Interface/Icons/Trade_Engineering')
	return b
end

function Toggle:OnClick()
	if C.AddOns.LoadAddOn(ADDON .. '_Config') then
		Addon.FrameOptions.frame = self:GetFrameID()
		Addon.FrameOptions:Open()
	end
end

function Toggle:OnEnter()
	self:ShowTooltip(OPTIONS)
end
