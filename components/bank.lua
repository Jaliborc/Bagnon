--[[
	bank.lua
		A specialized version of the bagnon frame for the bank
--]]

local ADDON, Addon = ...
local Frame = Addon:NewClass('BankFrame', 'Frame', Addon.Frame)
Frame.Title = LibStub('AceLocale-3.0'):GetLocale(ADDON).TitleBank

function Frame:OnHide()
	CloseBankFrame()
	Bagnon.Frame.OnHide(self)
end