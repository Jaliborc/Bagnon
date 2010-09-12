--[[
	frame.lua
		A specialized version of the bagnon frame for guild banks
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Frame = Bagnon.Classy:New('Frame', Bagnon.Frame)
Frame:Hide()
Bagnon.GuildFrame = Frame


--[[
	Events
--]]

function Frame:OnShow()
	PlaySound('GuildVaultOpen')

	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:OnHide()
--	GuildBankPopupFrame:Hide()
	StaticPopup_Hide('GUILDBANK_WITHDRAW')
	StaticPopup_Hide('GUILDBANK_DEPOSIT')
	StaticPopup_Hide('CONFIRM_BUY_GUILDBANK_TAB')
	CloseGuildBankFrame()
	PlaySound('GuildVaultClose')

	self:UpdateEvents()

	--fix issue where a frame is hidden, but not via bagnon controlled methods (ie, close on escape)
	if self:IsFrameShown() then
		self:HideFrame()
	end
end


--[[
	Actions
--]]

function Frame:CreateItemFrame()
	local f = Bagnon.GuildItemFrame:New(self:GetFrameID(), self)
	self.itemFrame = f
	return f
end

function Frame:CreateBagFrame()
	local f = Bagnon.GuildTabFrame:New(self:GetFrameID(), self)
	self.bagFrame = f
	return f
end

function Frame:CreateMoneyFrame()
	local f = Bagnon.GuildMoneyFrame:New(self:GetFrameID(), self)
	self.moneyFrame = f
	return f
end

function Frame:HasBagFrame()
	return true
end

function Frame:IsBagFrameShown()
	return true
end

function Frame:HasBagToggle()
	return false
end

function Frame:HasPlayerSelector()
	return false
end