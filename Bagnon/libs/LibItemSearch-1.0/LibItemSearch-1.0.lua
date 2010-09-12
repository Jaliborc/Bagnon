--[[
	ItemSearch
		An item text search engine of some sort

	Grammar:
		<search> 			:=	<intersect search>
		<intersect search> 	:=	<union search> & <union search> ; <union search>
		<union search>		:=	<negatable search>  | <negatable search> ; <negatable search>
		<negatable search> 	:=	!<primitive search> ; <primitive search>
		<primitive search>	:=	<tooltip search> ; <quality search> ; <type search> ; <text search>
		<tooltip search>	:=  bop ; boa ; bou ; boe ; quest
		<quality search>	:=	q<op><text> ; q<op><digit>
		<ilvl search>		:=	ilvl<op><number>
		<type search>		:=	t:<text>
		<text search>		:=	<text>
		<op>				:=  : | = | == | != | ~= | < | > | <= | >=

	I kindof half want to make a full parser for this
--]]

local MAJOR, MINOR = "LibItemSearch-1.0", 2
local ItemSearch = LibStub:NewLibrary(MAJOR, MINOR)
if not ItemSearch then return end

--[[ general search ]]--

function ItemSearch:Find(itemLink, search)
	if not search then
		return true
	end

	if not itemLink then
		return false
	end

	local search = search:lower()
	if search:match('\124') then
		return self:FindUnionSearch(itemLink, strsplit('\124', search))
	end
	return self:FindUnionSearch(itemLink, search)
end


--[[ union search: <search>&<search> ]]--

function ItemSearch:FindUnionSearch(itemLink, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if search and search ~= '' then
			if search:match('\038') then
				if self:FindIntersectSearch(itemLink, strsplit('\038', search)) then
					return true
				end
			else
				if self:FindIntersectSearch(itemLink, search) then
					return true
				end
			end
		end
	end
	return false
end


--[[ intersect search: <search>|<search> ]]--

function ItemSearch:FindIntersectSearch(itemLink, ...)
	for i = 1, select('#', ...) do
		local search = select(i, ...)
		if search and search ~= '' then
			if not self:FindNegatableSearch(itemLink, search) then
				return false
			end
		end
	end
	return true
end


--[[ negated search: !<search> ]]--

function ItemSearch:FindNegatableSearch(itemLink, search)
	local negatedSearch = search:match('^\033(.+)$')
	if negatedSearch then
		return not self:FindTypedSearch(itemLink, negatedSearch)
	end
	return self:FindTypedSearch(itemLink, search)
end


--[[
	typed search:
		user defined search types

	A typed search object should look like the following:
		{
			string id
				unique identifier for the search type,

			string searchCapture = function isSearch(self, search)
				returns a capture if the given search matches this typed search
				returns nil if the search is not a match for this type

			bool isMatch = function findItem(self, itemLink, searchCapture)
				returns true if <itemLink> is in the search defined by <searchCapture>
		}
--]]

local typedSearches = {}
function ItemSearch:RegisterTypedSearch(typedSearchObj)
	typedSearches[typedSearchObj.id] = typedSearchObj
end

function ItemSearch:GetTypedSearches()
	return pairs(typedSearches)
end

function ItemSearch:GetTypedSearch(id)
	return typedSearches[id]
end

function ItemSearch:FindTypedSearch(itemLink, search)
	if not search then
		return false
	end

	for id, searchInfo in self:GetTypedSearches() do
		local capture1, capture2, capture3 = searchInfo:isSearch(search)
		if capture1 then
			return searchInfo:findItem(itemLink, capture1, capture2, capture3)
		end
	end

	return self:GetTypedSearch('itemTypeGeneric'):findItem(itemLink, search) or self:GetTypedSearch('itemName'):findItem(itemLink, search)
end


--[[
	Basic typed searches
--]]

function ItemSearch:Compare(op, lhs, rhs)
	--ugly, but it works
	if op == ':' or op == '=' or op == '==' then
		return lhs == rhs
	end
	if op == '!=' or op == '~=' then
		return lhs ~= rhs
	end
	if op == '<=' then
		return lhs <= rhs
	end
	if op == '<' then
		return lhs < rhs
	end
	if op == '>' then
		return lhs > rhs
	end
	if op == '>=' then
		return lhs >= rhs
	end
	return false
end


--[[ basic text search n:(.+) ]]--

local function search_IsInText(search, ...)
	for i = 1, select('#', ...) do
		local text = select(i, ...)
		text = text and tostring(text):lower()
		if text and (text == search or text:match(search)) then
			return true
		end
	end
	return false
end

ItemSearch:RegisterTypedSearch{
	id = 'itemName',

	isSearch = function(self, search)
		return search and search:match('^n:(.+)$')
	end,

	findItem = function(self, itemLink, search)
		local itemName = (GetItemInfo(itemLink))
		return search_IsInText(search, itemName)
	end
}


--[[ item type,subtype,equip loc search t:(.+) ]]--

ItemSearch:RegisterTypedSearch{
	id = 'itemTypeGeneric',

	isSearch = function(self, search)
		return search and search:match('^t:(.+)$')
	end,

	findItem = function(self, itemLink, search)
		local name, link, quality, iLevel, reqLevel, type, subType, maxStack, equipSlot = GetItemInfo(itemLink)
		if not name then
			return false
		end
		return search_IsInText(search, type, subType, _G[equipSlot])
	end
}


--[[ item quality search: q(sign)(%d+) | q:(qualityName) ]]--

ItemSearch:RegisterTypedSearch{
	id = 'itemQuality',

	isSearch = function(self, search)
		if search then
			return search:match('^q([%~%:%<%>%=%!]+)(%w+)$')
		end
	end,

	descToQuality = function(self, desc)
		local q = 0

		local quality = _G['ITEM_QUALITY' .. q .. '_DESC']
		while quality and quality:lower() ~= desc do
			q = q + 1
			quality = _G['ITEM_QUALITY' .. q .. '_DESC']
		end

		if quality then
			return q
		end
	end,

	findItem = function(self, itemLink, op, search)
		local name, link, quality = GetItemInfo(itemLink)
		if not name then
			return false
		end

		local num = tonumber(search) or self:descToQuality(search)
		return num and ItemSearch:Compare(op, quality, num) or false
	end,
}

--[[ item level search: lvl(sign)(%d+) ]]--

ItemSearch:RegisterTypedSearch{
	id = 'itemLevel',

	isSearch = function(self, search)
		if search then
			return search:match('^ilvl([:<>=!]+)(%d+)$')
		end
	end,

	findItem = function(self, itemLink, op, search)
		local name, link, quality, iLvl = GetItemInfo(itemLink)
		if not iLvl then
			return false
		end

		local num = tonumber(search)
		return num and ItemSearch:Compare(op, iLvl, num) or false
	end,
}


--[[ tooltip keyword search ]]--

local tooltipCache = setmetatable({}, {__index = function(t, k) local v = {} t[k] = v return v end})
local tooltipScanner = _G['LibItemSearchTooltipScanner'] or CreateFrame('GameTooltip', 'LibItemSearchTooltipScanner', UIParent, 'GameTooltipTemplate')

local function link_FindSearchInTooltip(itemLink, search)
	--look in the cache for the result
	local itemID = itemLink:match('item:(%d+)')
	local cachedResult = tooltipCache[search][itemID]
	if cachedResult ~= nil then
		return cachedResult
	end

	--no match?, pull in the resut from tooltip parsing
	tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
	tooltipScanner:SetHyperlink(itemLink)

	local result = false
	if tooltipScanner:NumLines() > 1 and _G[tooltipScanner:GetName() .. 'TextLeft2']:GetText() == search then
		result = true
	elseif tooltipScanner:NumLines() > 2 and _G[tooltipScanner:GetName() .. 'TextLeft3']:GetText() == search then
		result = true
	end
	tooltipScanner:Hide()

	tooltipCache[search][itemID] = result
	return result
end

ItemSearch:RegisterTypedSearch{
	id = 'tooltip',

	isSearch = function(self, search)
		return self.keywords[search]
	end,

	findItem = function(self, itemLink, search)
		return search and link_FindSearchInTooltip(itemLink, search)
	end,

	keywords = {
		['boe'] = ITEM_BIND_ON_EQUIP,
		['bop'] = ITEM_BIND_ON_PICKUP,
		['bou'] = ITEM_BIND_ON_USE,
		['quest'] = ITEM_BIND_QUEST,
		['boa'] = ITEM_BIND_TO_ACCOUNT
	}
}


--[[ equipment set search ]]--

local function IsWardrobeLoaded()
	local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo('Wardrobe')
	return enabled
end

local function findEquipmentSetByName(search)
	local startsWithSearch = '^' .. search
	local partialMatch = nil

	for i = 1, GetNumEquipmentSets() do
		local setName = (GetEquipmentSetInfo(i))
		local lSetName = setName:lower()

		if lSetName == search then
			return setName
		end

		if lSetName:match(startsWithSearch) then
			partialMatch = setName
		end
	end

	-- Wardrobe Support
	if Wardrobe then
		for i, outfit in ipairs( Wardrobe.CurrentConfig.Outfit) do
			local setName = outfit.OutfitName
			local lSetName = setName:lower()

			if lSetName == search then
				return setName
			end

			if lSetName:match(startsWithSearch) then
				partialMatch = setName
			end
		end
	end

	return partialMatch
end

local function isItemInEquipmentSet(itemLink, setName)
	if not setName then
		return false
	end

	local itemIDs = GetEquipmentSetItemIDs(setName)
	if not itemIDs then
		return false
	end

	local itemID = tonumber(itemLink:match('item:(%d+)'))
	for inventoryID, setItemID in pairs(itemIDs) do
		if itemID == setItemID then
			return true
		end
	end

	return false
end

local function isItemInWardrobeSet(itemLink, setName)
	if not Wardrobe then return false end

	local itemName = (GetItemInfo(itemLink))
	for i, outfit in ipairs(Wardrobe.CurrentConfig.Outfit) do
		if outfit.OutfitName == setName then
			for j, item in pairs(outfit.Item) do
				if item and (item.IsSlotUsed == 1) and (item.Name == itemName) then
					return true
				end
			end
		end
	end

	return false
end

ItemSearch:RegisterTypedSearch{
	id = 'equipmentSet',

	isSearch = function(self, search)
		return search and search:match('^s:(.+)$')
	end,

	findItem = function(self, itemLink, search)
		local setName = findEquipmentSetByName(search)
		if not setName then
			return false
		end

		return isItemInEquipmentSet(itemLink, setName)
			or isItemInWardrobeSet(itemLink, setName)
	end,
}