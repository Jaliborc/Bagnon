--[[
	tooltips.lua
		Adds item counts to tooltips
]]--

local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local ItemCache = LibStub('LibItemCache-1.0')
local Items, Enabled, Hooked = {}

local HEARTHSTONE = tostring(HEARTHSTONE_ITEM_ID)
local CLASS_COLOR = '|cff%02x%02x%02x'
local SILVER = '|cffc7c7cf%s|r'
local TEAL = '|cff00ff9a%s|r'


--[[ Methods ]]--

local function GetColor(class)
	if class then
		local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local color = colors[class]
		return CLASS_COLOR:format(color.r * 255, color.g * 255, color.b * 255) .. '%s|r'
	else
		return TEAL
	end
end

local function FormatCounts(color, ...)
	local text = ''
	local total = 0
	
	for i = 1, select('#', ...) do
		local count = select(i, ...)
		if count and count > 0 then
			text = text .. L['TipCount' .. i]:format(count)
			total = total + count
		end
	end

	if total > 0 then
		return color:format(total) .. ' ' .. SILVER:format('('.. text:sub(3) .. ')')
	end
end

local function AddOwners(tooltip, link)
	local id = link and link:match('item:(%d+)')
	if not id or id == HEARTHSTONE then
		return
	end

	for i, player in ItemCache:IteratePlayers() do
		local class = ItemCache:GetPlayerInfo(player)
		local countText = Items[player][id]
		local color = GetColor(class)
		
		if countText ~= false then
			countText = FormatCounts(color, ItemCache:GetItemCounts(player, id))
			
			if ItemCache:IsPlayerCached(player) then
				Items[player][id] = countText or false
			end
		end

		if countText then
			tooltip:AddDoubleLine(color:format(player), countText)
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
		if not modified and Enabled then
			modified = true
			
			local name, link = self:GetItem()
			if link and GetItemInfo(link) then --fix for blizzard doing craziness when doing getiteminfo
				AddOwners(self, link)
			end
		end
	end)
end


--[[ Start this Thing! ]]--

function Bagnon:HookTooltips()
	if BagBrother and ItemCache:HasCache() and self.Settings:IsTipCountEnabled() then
		if not Hooked then
			for i, player in ItemCache:IteratePlayers() do
				Items[player] = {}
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