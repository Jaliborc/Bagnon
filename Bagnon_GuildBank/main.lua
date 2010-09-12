--[[
	main.lua
		The bagnon driver thingy
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local GuildBank = Bagnon:NewModule('GuildBank', 'AceEvent-3.0')

function GuildBank:OnEnable()
	Bagnon.GuildFrame:New('guildbank')

	self:RegisterEvent('GUILDBANKFRAME_OPENED')
	self:RegisterEvent('GUILDBANKFRAME_CLOSED')
end

function GuildBank:GUILDBANKFRAME_OPENED()
	Bagnon.FrameSettings:Get('guildbank'):Show()
	QueryGuildBankTab(GetCurrentGuildBankTab())
end

function GuildBank:GUILDBANKFRAME_CLOSED()
	Bagnon.FrameSettings:Get('guildbank'):Hide()
end
