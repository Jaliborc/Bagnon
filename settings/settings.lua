--[[
	profileSettings.lua
		Handles non specific frame settings
--]]

local _, Addon = ...
local Settings = {}
Addon.Settings = Settings


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------


function Settings:GetDB()
	return Addon.SavedSettings:GetDB()
end


--[[---------------------------------------------------------------------------
	Message Passing
--]]---------------------------------------------------------------------------

function Settings:SendMessage(msg, ...)
	Addon:SendCallback(msg, ...)
end


--[[---------------------------------------------------------------------------
	Settings...Setting
--]]---------------------------------------------------------------------------

--highlight items by quality
function Settings:SetHighlightItemsByQuality(enable)
	if self:HighlightItemsByQuality() ~= enable then
		self:GetDB().highlightItemsByQuality = enable
		self:SendMessage('ITEM_HIGHLIGHT_UPDATE')
	end
end

function Settings:HighlightItemsByQuality()
	return self:GetDB().highlightItemsByQuality
end

--highlight unusable items
function Settings:SetHighlightUnusableItems(enable)
	if self:HighlightUnusableItems() ~= enable then
		self:GetDB().highlightUnusableItems = enable
		self:SendMessage('ITEM_HIGHLIGHT_UPDATE')
	end
end

function Settings:HighlightUnusableItems()
	return self:GetDB().highlightUnusableItems
end

--highlight quest items
function Settings:SetHighlightQuestItems(enable)
	if self:HighlightQuestItems() ~= enable then
		self:GetDB().highlightQuestItems = enable
		self:SendMessage('ITEM_HIGHLIGHT_UPDATE')
	end
end

function Settings:HighlightQuestItems()
	return self:GetDB().highlightQuestItems
end

--highlight set items
function Settings:SetHighlightSetItems(enable)
	if self:HighlightSetItems() ~= enable then
		self:GetDB().highlightSetItems = enable
		self:SendMessage('ITEM_HIGHLIGHT_UPDATE')
	end
end

function Settings:HighlightSetItems()
	return self:GetDB().highlightSetItems
end

--highlight opacity
function Settings:SetHighlightOpacity(value)
	local value = math.max(math.min(value, 1), 0)
	if self:GetHighlightOpacity() ~= value then
		self:GetDB().highlightOpacity = value
		self:SendMessage('ITEM_HIGHLIGHT_UPDATE', value)
	end
end

function Settings:GetHighlightOpacity()
	return self:GetDB().highlightOpacity
end


--show empty item slots
function Settings:SetShowEmptyItemSlotTexture(enable)
	if self:ShowingEmptyItemSlotTextures() ~= enable then
		self:GetDB().showEmptyItemSlotTexture = enable
		self:SendMessage('SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE', enable)
	end
end

function Settings:ShowingEmptyItemSlotTextures()
	return self:GetDB().showEmptyItemSlotTexture
end


--lock frame positions
function Settings:SetLockFramePositions(enable)
	if self:AreFramePositionsLocked() ~= enable then
		self:GetDB().lockFramePositions = enable
		self:SendMessage('LOCK_FRAME_POSITIONS_UPDATE', enable)
	end
end

function Settings:AreFramePositionsLocked()
	return self:GetDB().lockFramePositions
end


--item slot coloring
function Settings:SetColorBagSlots(enable)
	if self:ColoringBagSlots() ~= enable then
		self:GetDB().colorBagSlots = enable
		self:SendMessage('ITEM_SLOT_COLOR_ENABLED_UPDATE', enable)
	end
end

function Settings:ColoringBagSlots()
	return self:GetDB().colorBagSlots
end

function Settings:SetItemSlotColor(type, r, g, b)
	local oR, oG, oB = self:GetItemSlotColor(type)
	if not(oR == r and oG == g and oB == b) then
		local slotColor = self:GetDB().slotColors[type]

		slotColor[1] = r
		slotColor[2] = g
		slotColor[3] = b

		self:SendMessage('ITEM_SLOT_COLOR_UPDATE', type, self:GetItemSlotColor(type))
	end
end

function Settings:GetItemSlotColor(type)
	local slotColor = self:GetDB().slotColors[type]
	return unpack(slotColor)
end

--enable frames
function Settings:SetEnableFrame(frameID, enable)
	local enable = enable and true or false
	if self:WillFrameBeEnabled(frameID) ~= enable then
		self.framesToEnable = self.framesToEnable or setmetatable({}, {__index = self:GetDB().enabledFrames})
		self.framesToEnable[frameID] = enable and true or false

		self:SendMessage('ENABLE_FRAME_UPDATE', frameID, self:WillFrameBeEnabled(frameID))
	end
end

function Settings:IsFrameEnabled(frameID)
	return self:GetDB().enabledFrames[frameID] and true or false
end

function Settings:WillFrameBeEnabled(frameID)
	self.framesToEnable = self.framesToEnable or setmetatable({}, {__index = self:GetDB().enabledFrames})
	return self.framesToEnable[frameID]
end

function Settings:AreAllFramesEnabled()
	for frameID, isEnabled in pairs(self:GetDB().enabledFrames) do
		if not isEnabled then
			return false
		end
	end
	return true
end


--automatic frame display
function Settings:SetShowFrameAtEvent(frameID, event, enable)
	local enable = enable and true or false
	if self:IsFrameShownAtEvent(frameID, event) ~= enable then
		Addon.SavedSettings:SetShowFrameAtEvent(frameID, event, enable)
		self:SendMessage('FRAME_DISPLAY_EVENT_UPDATE', frameID, event, self:IsFrameShownAtEvent(frameID, event))
	end
end

function Settings:IsFrameShownAtEvent(frameID, event)
	return Addon.SavedSettings:IsFrameShownAtEvent(frameID, event)
end

--bag disable
function Settings:AllowDisableBags(enable)
	local enable = enable and true or false
	if self:CanDisableBags() ~= enable then
		self:GetDB().allowDisableBags = enable
		self:SendMessage('BAG_DISABLE_UPDATE', enable)
	end
end

function Settings:CanDisableBags()
	return self:GetDB().allowDisableBags
end


--blizzard bag passthrough
function Settings:SetEnableBlizzardBagPassThrough(enable)
	local enable = enable and true or false
	if self:WillBlizzardBagPassThroughBeEnabled() ~= enable then
		self.enableBlizzardBagPassThrough = enable
		self:SendMessage('BLIZZARD_BAG_PASSTHROUGH_UPDATE', self:WillBlizzardBagPassThroughBeEnabled())
	end
end

function Settings:IsBlizzardBagPassThroughEnabled()
	return self:GetDB().enableBlizzardBagPassThrough
end

function Settings:WillBlizzardBagPassThroughBeEnabled()
	if self.enableBlizzardBagPassThrough == nil then
		self.enableBlizzardBagPassThrough = self:IsBlizzardBagPassThroughEnabled()
	end
	return self.enableBlizzardBagPassThrough
end

--item searching
function Settings:SetTextSearch(search)
	self.lastTextSearch = search ~= '' and search or self:GetTextSearch()
	self.textSearch = search

	self:SendMessage('TEXT_SEARCH_UPDATE', search)
end

function Settings:GetTextSearch()
	return self.textSearch or ''
end

function Settings:GetLastTextSearch()
	return self.lastTextSearch or ''
end

--flash find
function Settings:SetEnableFlashFind(enable)
	local enable = enable and true or false
	if self:IsFlashFindEnabled() ~= enable then
		self:GetDB().enableFlashFind = enable
		self:SendMessage('FLASH_FIND_UPDATE', self:IsFlashFindEnabled())
	end
end

function Settings:IsFlashFindEnabled()
	return self:GetDB().enableFlashFind
end

function Settings:FlashFind(link)
	if link and self:IsFlashFindEnabled() then
		self:SendMessage('FLASH_SEARCH_UPDATE', link)
	end
end

-- Function that is invoked when a chat link is clicked
hooksecurefunc("SetItemRef", function(_, link, button)
	if IsAltKeyDown() and button == "LeftButton" then
		local name = link and link:match('^|c%x+|Hitem.+|h%[(.*)%]')
		if name then
			Addon:ShowFrame('inventory')
			Addon:GetFrame('inventory'):GetSettings():EnableTextSearch()
			Settings:SetTextSearch(name)
		end
	end
end)

--fading
function Settings:SetFading(enable)
	self:GetDB().fading = enable and true or false
end

function Settings:IsFadingEnabled()
	return self:GetDB().fading
end

--tip count
function Settings:SetEnableTipCount(enable)
	self:GetDB().enableTipCount = enable and true or false
	Addon:HookTooltips()
end

function Settings:IsTipCountEnabled()
	return self:GetDB().enableTipCount
end