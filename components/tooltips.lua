--[[
	tooltips.lua
		Adds item counts to tooltips
]]--

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)

local SILVER = '|cffc7c7cf%s|r'
local HEARTHSTONE = tostring(HEARTHSTONE_ITEM_ID)
local TOTAL = SILVER:format(L.Total)

local ItemCache = LibStub('LibItemCache-1.1')
local ItemText, ItemCount, Enabled, Hooked = {}, {}


--[[ Local Functions ]]--

local function FormatCounts(color, ...)
	local places = 0
	local total = 0
	local text = ''
	
	for i = 1, select('#', ...) do
		local count = select(i, ...)
		if count > 0 then
			text = text .. L.TipDelimiter .. L['TipCount' .. i]:format(count)
			total = total + count
			places = places + 1
		end
	end
	
	text = text:sub(#L.TipDelimiter + 1)
	if places > 1 then
		text = color:format(total) .. ' ' .. SILVER:format('('.. text .. ')')
	else
		text = color:format(text)
	end
		
	return total, total > 0 and text
end

local function AddOwners(tooltip, link)
	local id = link and link:match('item:(%d+)')
	if not id or id == HEARTHSTONE then
		return
	end
	
	local players = 0
	local total = 0
	
	for i, player in ItemCache:IteratePlayers() do
		local color = Addon:GetPlayerColorString(player)
		local countText = ItemText[player][id]
		local count = ItemCount[player][id]
		
		if countText == nil then
			count, countText = FormatCounts(color, ItemCache:GetItemCounts(player, id))

			if ItemCache:IsPlayerCached(player) then
				ItemText[player][id] = countText or false
				ItemCount[player][id] = count
			end
		end

		if countText then
			tooltip:AddDoubleLine(color:format(player), countText)
			total = total + count
			players = players + 1
		end
	end
	
	if players > 1 and total > 0 then
		tooltip:AddDoubleLine(TOTAL, SILVER:format(total))
	end
	
	tooltip:Show()
end

local function hookTip(tooltip)
	local modified = false

	tooltip:HookScript('OnTooltipCleared', function(self)
		modified = false
	end)

	tooltip:HookScript('OnTooltipSetItem', function(self)
		if not modified and Enabled then
			modified = true
			
			local name, link = self:GetItem()
			if link and GetItemInfo(link) then --fix for blizzard doing craziness when doing getiteminfo
				AddOwners(self, link)
			end
		end
	end)
end


--[[ Public Methods ]]--

function Addon:HookTooltips()
	if ItemCache:HasCache() and self.Settings:IsTipCountEnabled() then
		if not Hooked then
			for i, player in ItemCache:IteratePlayers() do
				ItemCount[player] = {}
				ItemText[player] = {}
			end
		
			hookTip(GameTooltip)
			hookTip(ItemRefTooltip)
			Hooked = true
		end
		
		Enabled = true
	else
		Enabled = nil
	end
end