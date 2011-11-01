--[[
	tooltips.lua
		Adds item counts to tooltips
]]--

local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local ItemCache = LibStub('LibItemCache-1.0')
local Items = {}

local HEARTHSTONE = tostring(HEARTHSTONE_ITEM_ID)
local SILVER = '|cffc7c7cf%s|r'
local TEAL = '|cff00ff9a%s|r'

print('hello')
--[[ Methods ]]--

local function FormatCounts(...)
	local text = ''
	local total = 0
	
	for i = 1, select('#', ...) do
		local count = select(i, ...)
		if count and count > 0 then
			--text = text .. ', ' .. L['TipCount' .. i]:format(count)
			text = text .. ', ' .. count
			total = total + count
		end
	end

	if total > 0 then
		return TEAL:format(total) .. ' ' .. SILVER:format(text)
	end
end

local function AddOwners(tooltip, link)
	local id = link and link:match('item:(%d+)')
	if not id or id == HEARTHSTONE then
		return
	end

	for player in ItemCache:IteratePlayers() do
		local countText = Items[player][id]
		
		if countText ~= false then
			countText = FormatCounts(ItemCache:GetItemCounts(player, id))
			
			if ItemCache:PlayerCached(player) then
				Items[player][id] = countText or false
			end
		end

		if countText then
			tooltip:AddDoubleLine(TEAL:format(player), countText)
		end
	end
	
	tooltip:Show()
end

local function hookTip(tooltip)
	local modified = false

	tooltip:HookScript('OnTooltipCleared', function(self)
		modified = false
	end)

	tooltip:HookScript('OnTooltipSetItem', function(self)
		if not modified  then
			modified = true
			
			local name, link = self:GetItem()
			if link and GetItemInfo(link) then --fix for blizzard doing craziness when doing getiteminfo
				AddOwners(self, link)
			end
		end
	end)
end)


--[[ Start this Thing! ]]--

function Bagnon:HookTooltips()
	if self.Settings:IsTipCountEnabled() then
		hookTip(GameTooltip)
		hookTip(ItemRefTooltip)
	end
end