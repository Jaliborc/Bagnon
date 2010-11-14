--[[
	item.lua
		An item slot button
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemSlot = Bagnon.Classy:New('Button')
ItemSlot:Hide()
Bagnon.ItemSlot = ItemSlot

local ItemSearch = LibStub('LibItemSearch-1.0')

local function hasBlizzQuestHighlight() 
	return GetContainerItemQuestInfo and true or false 
end

--[[
	The item widget
--]]


--[[ ItemSlot Constructor ]]--

function ItemSlot:New(bag, slot, frameID, parent)
	local item = self:Restore() or self:Create()

	item:SetParent(item:GetDummyBag(parent, bag))
	item:SetID(slot)
	item:SetFrameID(frameID)

	if item:IsVisible() then
		item:Update()
	else
		item:Show()
	end

	return item
end

--constructs a brand new item slot
function ItemSlot:Create()
	local id = self:GetNextItemSlotID()
	local item = self:Bind(self:GetBlizzardItemSlot(id) or self:ConstructNewItemSlot(id))
	item:Hide()

	--add a quality border texture
	item.questBorder = _G[item:GetName() .. 'IconQuestTexture']

	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67)
	border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	--hack, make sure the cooldown model stays visible
	item.cooldown = _G[item:GetName() .. 'Cooldown']

	--get rid of any registered frame events, and use my own
	item:SetScript('OnEvent', nil)
	item:SetScript('OnEnter', item.OnEnter)
	item:SetScript('OnLeave', item.OnLeave)
	item:SetScript('OnShow', item.OnShow)
	item:SetScript('OnHide', item.OnHide)
	item:SetScript('PostClick', item.PostClick)
	item.UpdateTooltip = nil

	return item
end

--creates a new item slot for <id>
function ItemSlot:ConstructNewItemSlot(id)
	return CreateFrame('Button', 'BagnonItemSlot' .. id, nil, 'ContainerFrameItemButtonTemplate')
end

--returns an available blizzard item slot for <id>
function ItemSlot:GetBlizzardItemSlot(id)
	--only allow reuse of blizzard frames if all frames are enabled
	if not self:CanReuseBlizzardBagSlots() then
		return nil
	end

	local bag = math.ceil(id / MAX_CONTAINER_ITEMS)
	local slot = (id-1) % MAX_CONTAINER_ITEMS + 1
	local item = _G[format('ContainerFrame%dItem%d', bag, slot)]

	if item then
		item:SetID(0)
		item:ClearAllPoints()
		return item
	end
end

function ItemSlot:CanReuseBlizzardBagSlots()
	return Bagnon.Settings:AreAllFramesEnabled() and (not Bagnon.Settings:IsBlizzardBagPassThroughEnabled())
end

--returns the next available item slot
function ItemSlot:Restore()
	local item = ItemSlot.unused and next(ItemSlot.unused)
	if item then
		ItemSlot.unused[item] = nil
		return item
	end
end

--gets the next unique item slot id
do
	local id = 1
	function ItemSlot:GetNextItemSlotID()
		local nextID = id
		id = id + 1
		return nextID
	end
end



--[[ ItemSlot Destructor ]]--

function ItemSlot:Free()
	self:Hide()
	self:SetParent(nil)
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

	ItemSlot.unused = ItemSlot.unused or {}
	ItemSlot.unused[self] = true
end


--[[ Events ]]--

function ItemSlot:ITEM_SLOT_UPDATE(msg, bag, slot)
	self:Update()
end

function ItemSlot:ITEM_LOCK_CHANGED(event, bag, slot)
	self:UpdateLocked()
end

function ItemSlot:ITEM_SLOT_UPDATE_COOLDOWN(msg, bag, slot)
	self:UpdateCooldown()
end

function ItemSlot:TEXT_SEARCH_UPDATE(msg, frameID, search)
	self:UpdateSearch()
end

function ItemSlot:BAG_SEARCH_UPDATE(msg, frameID, search)
	if self:GetFrameID() == frameID then
		self:UpdateBagSearch()
	end
end

function ItemSlot:ITEM_HIGHLIGHT_QUALITY_UPDATE(msg, enable)
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_QUEST_UPDATE(msg, enable)
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_OPACITY_UPDATE(msg, opacity)
	self:UpdateBorder()
end

function ItemSlot:SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE(msg, enable)
	self:Update()
end

function ItemSlot:ITEM_SLOT_COLOR_ENABLED_UPDATE(msg, type, r, g, b)
	self:Update()
end

function ItemSlot:ITEM_SLOT_COLOR_UPDATE(msg, type, r, g, b)
	self:Update()
end

function ItemSlot:QUEST_ACCEPTED()
	self:UpdateBorder()
end

function ItemSlot:UNIT_QUEST_LOG_CHANGED()
	self:UpdateBorder()
end

function ItemSlot:HandleEvent(msg, ...)
	local action = self[msg]
	if action then
		action(self, msg, ...)
	end
end


--[[ Frame Events ]]--

function ItemSlot:OnShow()
	self:Update()
end

function ItemSlot:OnHide()
	self:HideStackSplitFrame()
end

function ItemSlot:OnDragStart()
	if self:IsCached() and CursorHasItemSlot() then
		ClearCursor()
	end
end

function ItemSlot:OnModifiedClick(button)
	local link = self:IsCached() and self:GetItem()
	if link then
		HandleModifiedItemClick(link)
	end
end

function ItemSlot:OnEnter()
	local dummySlot = self:GetDummyItemSlot()

	if self:IsCached() then
		dummySlot:SetParent(self)
		dummySlot:SetAllPoints(self)
		dummySlot:Show()
	else
		dummySlot:Hide()

		if self:IsBank() then
			if self:GetItem() then
				self:AnchorTooltip()
				GameTooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(self:GetID()))
				GameTooltip:Show()
				CursorUpdate(self)
			end
		else
			ContainerFrameItemButton_OnEnter(self)
		end
	end
end

function ItemSlot:OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end


--[[ Update Methods ]]--


-- Update the texture, lock status, and other information about an item
function ItemSlot:Update()
	if not self:IsVisible() then return end

	local texture, count, locked, quality, readable, lootable, link = self:GetItemSlotInfo()

	self:SetItem(link)
	self:SetTexture(texture)
	self:SetCount(count)
	self:SetLocked(locked)
	self:SetReadable(readable)
	self:SetBorderQuality(quality)
	self:UpdateCooldown()
	self:UpdateSlotColor()
	self:UpdateSearch()
	self:UpdateBagSearch()

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	end
end

--item link
function ItemSlot:SetItem(itemLink)
	self.hasItem = itemLink or nil
end

function ItemSlot:GetItem()
	return self.hasItem
end

--item texture
function ItemSlot:SetTexture(texture)
	SetItemButtonTexture(self, texture or self:GetEmptyItemTexture())
end

function ItemSlot:GetEmptyItemTexture()
	if self:ShowingEmptyItemSlotTexture() then
		return [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
	end
	return nil
end

--item slot color
function ItemSlot:UpdateSlotColor()
	if (not self:GetItem()) and self:ColoringBagSlots() then
		if self:IsKeyRingSlot() then
			local r, g, b = self:GetKeyringSlotColor()
			SetItemButtonTextureVertexColor(self, r, g, b)
			self:GetNormalTexture():SetVertexColor(r, g, b)
			return
		end

		if self:IsAmmoBagSlot() then
			local r, g, b = self:GetAmmoSlotColor()
			SetItemButtonTextureVertexColor(self, r, g, b)
			self:GetNormalTexture():SetVertexColor(r, g, b)
			return
		end

		if self:IsTradeBagSlot() then
			local r, g, b = self:GetTradeSlotColor()
			SetItemButtonTextureVertexColor(self, r, g, b)
			self:GetNormalTexture():SetVertexColor(r, g, b)
			return
		end

		if self:IsShardBagSlot() then
			local r, g, b = self:GetShardSlotColor()
			SetItemButtonTextureVertexColor(self, r, g, b)
			self:GetNormalTexture():SetVertexColor(r, g, b)
			return
		end
	end

	SetItemButtonTextureVertexColor(self, 1, 1, 1)
	self:GetNormalTexture():SetVertexColor(1, 1, 1)
end

--item count
function ItemSlot:SetCount(count)
	SetItemButtonCount(self, count)
end

--readable status
function ItemSlot:SetReadable(readable)
	self.readable = readable
end

--locked status
function ItemSlot:SetLocked(locked)
	SetItemButtonDesaturated(self, locked)
end

function ItemSlot:UpdateLocked()
	self:SetLocked(self:IsLocked())
end

--returns true if the slot is locked, and false otherwise
function ItemSlot:IsLocked()
	return Bagnon.ItemSlotInfo:IsLocked(self:GetPlayer(), self:GetBag(), self:GetID())
end

--colors the item border based on the quality of the item.  hides it for common/poor items
if hasBlizzQuestHighlight() then
	function ItemSlot:SetBorderQuality(quality)
		local border = self.border
		local qBorder = self.questBorder

		if self:HighlightingQuestItems() then
			local isQuestItem, isQuestStarter = self:IsQuestItem()
			if isQuestItem then
				qBorder:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
				qBorder:SetAlpha(self:GetHighlightAlpha())
				qBorder:Show()
				border:Hide()
				return
			end

			if isQuestStarter then
				qBorder:SetTexture(TEXTURE_ITEM_QUEST_BANG)
				qBorder:SetAlpha(self:GetHighlightAlpha())
				qBorder:Show()
				border:Hide()
				return
			end
		end

		if self:HighlightingItemsByQuality() then
			if self:GetItem() and quality and quality > 1 then
				local r, g, b = GetItemQualityColor(quality)
				border:SetVertexColor(r, g, b, self:GetHighlightAlpha())
				border:Show()
				qBorder:Hide()
				return
			end
		end

		qBorder:Hide()
		border:Hide()
	end
else
	function ItemSlot:SetBorderQuality(quality)
		local border = self.border

		if self:HighlightingItemsByQuality() then
			if self:GetItem() and quality and quality > 1 then
				local r, g, b = GetItemQualityColor(quality)
				border:SetVertexColor(r, g, b, self:GetHighlightAlpha())
				border:Show()
				return
			end
		end

		if self:HighlightingQuestItems() then
			if self:IsQuestItem() then
				border:SetVertexColor(1, 1, 0, self:GetHighlightAlpha())
				border:Show()
				return
			end
		end

		border:Hide()
	end
end

function ItemSlot:UpdateBorder()
	local texture, count, locked, quality = self:GetItemSlotInfo()
	self:SetBorderQuality(quality)
end

--cooldown
function ItemSlot:UpdateCooldown()
	if self:GetItem() and (not self:IsCached()) then
		ContainerFrame_UpdateCooldown(self:GetBag(), self)
	else
		CooldownFrame_SetTimer(self.cooldown, 0, 0, 0)
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	end
end

--stack split frame
function ItemSlot:HideStackSplitFrame()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

--tooltip methods
ItemSlot.UpdateTooltip = ItemSlot.OnEnter

function ItemSlot:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end

--search
function ItemSlot:UpdateSearch()
	local shouldFade = false
	local search = self:GetItemSearch()

	if search and search ~= '' then
		local itemLink = self:GetItem()
		shouldFade = not(itemLink and ItemSearch:Find(itemLink, search))
	end

	if shouldFade then
		self:SetAlpha(0.4)
		SetItemButtonDesaturated(self, true)
		self.border:Hide()
	else
		self:SetAlpha(1)
		self:UpdateLocked()
		self:UpdateBorder()
		self:UpdateSlotColor()
	end
end

function ItemSlot:GetItemSearch()
	return Bagnon.Settings:GetTextSearch()
end

--bag search
function ItemSlot:UpdateBagSearch()
	local search = self:GetBagSearch()
	if self:GetBag() == search then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function ItemSlot:GetBagSearch()
	return self:GetSettings():GetBagSearch()
end



--[[ Accessor Methods ]]--

function ItemSlot:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:Update()
	end
end

function ItemSlot:GetFrameID()
	return self.frameID
end

function ItemSlot:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function ItemSlot:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function ItemSlot:GetBag()
	return self:GetParent() and self:GetParent():GetID() or 1
end

function ItemSlot:IsSlot(bag, slot)
	return self:GetBag() == bag and self:GetID() == slot
end

function ItemSlot:IsCached()
	return Bagnon.BagSlotInfo:IsCached(self:GetPlayer(), self:GetBag())
end

function ItemSlot:IsBank()
	return Bagnon.BagSlotInfo:IsBank(self:GetBag())
end

function ItemSlot:IsBankSlot()
	local bag = self:GetBag()
	return Bagnon.BagSlotInfo:IsBank(bag) or Bagnon.BagSlotInfo:IsBankBag(bag)
end

function ItemSlot:AtBank()
	return Bagnon.PlayerInfo:AtBank()
end

function ItemSlot:GetItemSlotInfo()
	local texture, count, locked, quality, readable, lootable, link = Bagnon.ItemSlotInfo:GetItemInfo(self:GetPlayer(), self:GetBag(), self:GetID())
	return texture, count, locked, quality, readable, lootable, link
end


--[[ Item Type Highlighting ]]--

function ItemSlot:HighlightingItemsByQuality()
	return Bagnon.Settings:HighlightingItemsByQuality()
end

function ItemSlot:HighlightingQuestItems()
	return Bagnon.Settings:HighlightingQuestItems()
end

function ItemSlot:GetHighlightAlpha()
	return Bagnon.Settings:GetHighlightOpacity()
end

--returns true if the item is a quest item or not
--in 3.3, includes a second return to determine if the item is a quest starter for a quest the player lacks
local QUEST_ITEM_SEARCH = string.format('t:%s|%s', select(12, GetAuctionItemClasses()), 'quest')

if hasBlizzQuestHighlight() then
	function ItemSlot:IsQuestItem()
		local itemLink = self:GetItem()
		if not itemLink then
			return false, false
		end

		if self:IsCached() then
			return ItemSearch:Find(itemLink, QUEST_ITEM_SEARCH), false
		else
			local isQuestItem, questID, isActive = GetContainerItemQuestInfo(self:GetBag(), self:GetID())
			return isQuestItem, (questID and not isActive)
		end
	end
else
	function ItemSlot:IsQuestItem()
		local itemLink = self:GetItem()
		if not itemLink then
			return false
		end

		return ItemSearch:Find(itemLink, QUEST_ITEM_SEARCH)
	end
end


--[[ Item Slot Coloring ]]--

function ItemSlot:IsAmmoBagSlot()
	return Bagnon.BagSlotInfo:IsAmmoBag(self:GetPlayer(), self:GetBag())
end

function ItemSlot:GetAmmoSlotColor()
	return Bagnon.Settings:GetItemSlotColor('ammo')
end

function ItemSlot:IsTradeBagSlot()
	return Bagnon.BagSlotInfo:IsTradeBag(self:GetPlayer(), self:GetBag())
end

function ItemSlot:GetTradeSlotColor()
	return Bagnon.Settings:GetItemSlotColor('trade')
end

function ItemSlot:IsShardBagSlot()
	return Bagnon.BagSlotInfo:IsShardBag(self:GetPlayer(), self:GetBag())
end

function ItemSlot:GetShardSlotColor()
	return Bagnon.Settings:GetItemSlotColor('shard')
end

function ItemSlot:IsKeyRingSlot()
	return Bagnon.BagSlotInfo:IsKeyRing(self:GetBag())
end

function ItemSlot:GetKeyringSlotColor()
	return Bagnon.Settings:GetItemSlotColor('keyring')
end

function ItemSlot:ColoringBagSlots()
	return Bagnon.Settings:ColoringBagSlots()
end


--[[ Empty Slot Visibility ]]--

function ItemSlot:ShowingEmptyItemSlotTexture()
	return Bagnon.Settings:ShowingEmptyItemSlotTextures()
end


--[[ Delicious Hacks ]]--

-- dummy slot - A hack, used to provide a tooltip for cached items without tainting other item code
function ItemSlot:GetDummyItemSlot()
	ItemSlot.dummySlot = ItemSlot.dummySlot or ItemSlot:CreateDummyItemSlot()
	return ItemSlot.dummySlot
end

function ItemSlot:CreateDummyItemSlot()
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:SetToplevel(true)
	slot:Hide()

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		parent:LockHighlight()

		if parent:IsCached() and parent:GetItem() then
			ItemSlot.AnchorTooltip(self)
			GameTooltip:SetHyperlink(parent:GetItem())
			GameTooltip:Show()
		end
	end

	local function Slot_OnLeave(self)
		GameTooltip:Hide()
		self:Hide()
	end

	local function Slot_OnHide(self)
		local parent = self:GetParent()
		if parent then
			parent:UnlockHighlight()
		end
	end

	local function Slot_OnClick(self, button)
		self:GetParent():OnModifiedClick(button)
	end

	slot.UpdateTooltip = Slot_OnEnter
	slot:SetScript('OnClick', Slot_OnClick)
	slot:SetScript('OnEnter', Slot_OnEnter)
	slot:SetScript('OnLeave', Slot_OnLeave)
	slot:SetScript('OnShow', Slot_OnEnter)
	slot:SetScript('OnHide', Slot_OnHide)

	return slot
end


--dummy bag, a hack to enforce the internal blizzard rule that item:GetParent():GetID() == bagID
function ItemSlot:GetDummyBag(parent, bag)
	local dummyBags = parent.dummyBags

	--metatable magic to create a new frame on demand
	if not dummyBags then
		dummyBags = setmetatable({}, {
			__index = function(t, k)
				local f = CreateFrame('Frame', nil, parent)
				f:SetID(k)
				t[k] = f
				return f
			end
		})
		parent.dummyBags = dummyBags
	end

	return dummyBags[bag]
end