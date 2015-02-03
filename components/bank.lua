--[[
	bank.lua
		A specialized version of the bagnon frame for the bank
--]]

local ADDON, Addon = ...
local Frame = Addon:NewClass('BankFrame', 'Frame', Addon.Frame)
Frame.Title = LibStub('AceLocale-3.0'):GetLocale(ADDON).TitleBank
Frame.Bags = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11, REAGENTBANK_CONTAINER}

function Frame:OnHide()
	CloseBankFrame()
	Addon.Frame.OnHide(self)
end
