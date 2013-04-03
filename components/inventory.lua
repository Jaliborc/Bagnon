--[[
	inventory.lua
		A specialized version of the bagnon frame for the inventory
--]]

local ADDON, Addon = ...
local Frame = Addon:NewClass('InventoryFrame', 'Frame', Addon.Frame)
Frame.Title = LibStub('AceLocale-3.0'):GetLocale(ADDON).TitleBags

function Frame:OnShow()
	Bagnon.Frame.OnShow(self)
	self:CheckBagButtons(true)
end

function Frame:OnHide()
	Bagnon.Frame.OnHide(self)
	self:CheckBagButtons(false)
end

function Frame:CheckBagButtons(checked)
	_G['MainMenuBarBackpackButton']:SetChecked(checked)
	_G["CharacterBag0Slot"]:SetChecked(checked)
	_G["CharacterBag1Slot"]:SetChecked(checked)
	_G["CharacterBag2Slot"]:SetChecked(checked)
	_G["CharacterBag3Slot"]:SetChecked(checked)
end