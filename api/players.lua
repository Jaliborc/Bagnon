--[[
	player.lua
		Utility methods for player display operations
--]]

local ADDON, Addon = ...
local Cache = LibStub('LibItemCache-1.1')

local ALTERNATIVE_ICONS = 'Interface/CharacterFrame/TEMPORARYPORTRAIT-%s-%s'
local ICONS = 'Interface/Icons/Achievement_Character_%s_%s'
local CLASS_COLOR = '|cff%02x%02x%02x'


--[[ Methods ]]--

function Addon:GetPlayerIcon(player)
	local _, race, sex = Cache:GetPlayerInfo(player)
	if not race then
		return
	else
		sex = sex == 3 and 'Female' or 'Male'
	end

	if race ~= 'Worgen' and race ~= 'Goblin' and (race ~= 'Pandaren' or sex == 'Female') then
		if race == 'Scourge' then
			race = 'Undead'
		end

		return ICONS:format(race, sex)
	end

	return ALTERNATIVE_ICONS:format(sex, race)
end

function Addon:GetPlayerColorString(player)
	local color = self:GetPlayerColor(player)
	return CLASS_COLOR:format(color.r * 255, color.g * 255, color.b * 255) .. '%s|r'
end

function Addon:GetPlayerColor(player)
	local class = Cache:GetPlayerInfo(player) or 'PRIEST'
	return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
end