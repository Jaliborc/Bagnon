--[[
	itemFrame.lua
		An item slot container
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemFrame = Bagnon.Classy:New('Frame')
ItemFrame:Hide()
Bagnon.ItemFrame = ItemFrame

local function hasBlizzQuestHighlight() 
	return GetContainerItemQuestInfo and true or false 
end


--[[ Extreme Constants! ]]--

ItemFrame.ITEM_SIZE = 39


--[[ Constructor ]]--

local function throttledUpdater_OnUpdate(self, elapsed)
	local p = self:GetParent()
	if p:NeedsLayout() then
		p:Layout()
	end
	self:Hide()
end

function ItemFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))

	f.itemSlots = {}
	f.throttledUpdater = CreateFrame('Frame', nil, f)
	f.throttledUpdater:SetScript('OnUpdate', throttledUpdater_OnUpdate)
	f:SetFrameID(frameID)
	f:SetScript('OnSizeChanged', f.OnSizeChanged)
	f:SetScript('OnEvent', f.OnEvent)
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

	return f
end


--[[ Messages ]]--

function ItemFrame:OnEvent(event, ...)
	local action = self[event]
	if action then
		action(self, event, ...)
	end
end

function ItemFrame:ITEM_SLOT_ADD(msg, bag, slot)
	if self:IsBagShown(bag) and (not self:IsBagSlotCached(bag)) then
		self:AddItemSlot(bag, slot)
	end
end

function ItemFrame:ITEM_SLOT_REMOVE(msg, bag, slot)
	if self:IsBagShown(bag) and (not self:IsBagSlotCached(bag)) then
		self:RemoveItemSlot(bag, slot)
	end
end

function ItemFrame:ITEM_LOCK_CHANGED(msg, bag, slot, ...)
	if slot and self:IsBagShown(bag) and (not self:IsBagSlotCached(bag)) then
		self:HandleSpecificItemEvent(msg, bag, slot, ...)
	end
end

function ItemFrame:BANK_OPENED(msg)
	self:UpdateEverything()
end

function ItemFrame:BANK_CLOSED(msg)
	self:UpdateEverything()
end

function ItemFrame:PLAYER_UPDATE(msg, frameID, player)
	if self:GetFrameID() == frameID then
		self:UpdateEverything()
	end
end

function ItemFrame:BAG_UPDATE_TYPE(msg, bag, type)
	if self:IsBagShown(bag) and not self:IsBagSlotCached(bag) then
		self:UpdateAllItemSlotsForBag(bag)
	end
end

function ItemFrame:BAG_SLOT_SHOW(msg, frameID, bagSlot)
	if self:GetFrameID() == frameID then
		self:AddAllItemSlotsForBag(bagSlot)
	end
end

function ItemFrame:BAG_SLOT_HIDE(msg, frameID, bagSlot)
	if self:GetFrameID() == frameID then
		self:RemoveAllItemSlotsForBag(bagSlot)
	end
end

function ItemFrame:ITEM_FRAME_SPACING_UPDATE(msg, frameID, spacing)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:ITEM_FRAME_COLUMNS_UPDATE(msg, frameID, columns)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:SLOT_ORDER_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:ITEM_FRAME_BAG_BREAK_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:RequestLayout()
	end
end

function ItemFrame:UNIT_QUEST_LOG_CHANGED(event, unit)
	if unit == 'player' then
		self:HandleGlobalItemEvent(event)
	end
end

function ItemFrame:QUEST_ACCEPTED(event)
	self:HandleGlobalItemEvent(event)
end

function ItemFrame:HandleGlobalItemEvent(msg, ...)
	for i, item in self:GetAllItemSlots() do
		item:HandleEvent(msg, ...)
	end
end

function ItemFrame:HandleSpecificItemEvent(msg, bag, slot, ...)
	if self:IsBagShown(bag) and (not self:IsBagSlotCached(bag)) then
		local item = self:GetItemSlot(bag, slot)
		if item then
			item:HandleEvent(msg, bag, slot, ...)
		end
	end
end

function ItemFrame:RegisterItemEvent(...)
	Bagnon.BagEvents:Listen(self, ...)
end

function ItemFrame:UnregisterItemEvent(...)
	Bagnon.BagEvents:Ignore(self, ...)
end

function ItemFrame:UnregisterAllItemEvents(...)
	Bagnon.BagEvents:IgnoreAll(self, ...)
end


--[[ Frame Events ]]--

function ItemFrame:OnShow()
	self:UpdateEverything()
end

function ItemFrame:OnHide()
	self:UpdateEvents()
end

function ItemFrame:OnSizeChanged()
	self:SendMessage('ITEM_FRAME_SIZE_CHANGE', self:GetFrameID())
end


--[[ Update Methods ]]--

function ItemFrame:UpdateEverything()
	self:UpdateEvents()

	if self:IsVisible() then
		self:ReloadAllItemSlots()
		self:RequestLayout()
	end
end

function ItemFrame:UpdateEvents()
	self:UnregisterAllEvents()
	self:UnregisterAllItemEvents()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		--live item events
		if not self:IsCached() then
			self:RegisterEvent('ITEM_LOCK_CHANGED')
			
			if hasBlizzQuestHighlight() then
				self:RegisterEvent('QUEST_ACCEPTED')
				self:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
			end

			self:RegisterItemEvent('ITEM_SLOT_ADD')
			self:RegisterItemEvent('ITEM_SLOT_REMOVE')
			self:RegisterItemEvent('ITEM_SLOT_UPDATE', 'HandleSpecificItemEvent')
			self:RegisterItemEvent('ITEM_SLOT_UPDATE_COOLDOWN', 'HandleSpecificItemEvent')
			self:RegisterItemEvent('BAG_UPDATE_TYPE')

			if self:HasBankBags() then
				self:RegisterItemEvent('BANK_OPENED')
				self:RegisterItemEvent('BANK_CLOSED')
			end
		end

		self:RegisterMessage('BAG_SLOT_SHOW')
		self:RegisterMessage('BAG_SLOT_HIDE')
		self:RegisterMessage('PLAYER_UPDATE')
		self:RegisterMessage('ITEM_FRAME_SPACING_UPDATE')
		self:RegisterMessage('ITEM_FRAME_COLUMNS_UPDATE')
		self:RegisterMessage('SLOT_ORDER_UPDATE')
		self:RegisterMessage('ITEM_FRAME_BAG_BREAK_UPDATE')

		self:RegisterMessage('TEXT_SEARCH_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('BAG_SEARCH_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('ITEM_HIGHLIGHT_QUEST_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('ITEM_HIGHLIGHT_QUALITY_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('ITEM_HIGHLIGHT_OPACITY_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('ITEM_SLOT_COLOR_UPDATE', 'HandleGlobalItemEvent')
		self:RegisterMessage('ITEM_SLOT_COLOR_ENABLED_UPDATE', 'HandleGlobalItemEvent')
	end
end


--[[ Item Slot Management ]]--

--if an item is not assigned to the given slotIndex, then add an item
function ItemFrame:AddItemSlot(bag, slot)
	if self:IsBagShown(bag) and not self:GetItemSlot(bag, slot) then
		local itemSlot = self:NewItemSlot(bag, slot)
		self.itemSlots[self:GetSlotIndex(bag, slot)] = itemSlot
		self:RequestLayout()
	end
end

function ItemFrame:NewItemSlot(bag, slot)
	return Bagnon.ItemSlot:New(bag, slot, self:GetFrameID(), self)
end

--removes any item slot associated with the given slotIndex
function ItemFrame:RemoveItemSlot(bag, slot)
	local itemSlot = self:GetItemSlot(bag, slot)
	if itemSlot then
		itemSlot:Free()
		self.itemSlots[self:GetSlotIndex(bag, slot)] = nil
		self:RequestLayout()
	end
end

function ItemFrame:UpdateItemSlot(bag, slot)
	local itemSlot = self:GetItemSlot(bag, slot)
	if itemSlot then
		itemSlot:Update()
	end
end

--returns the item slot assigned to the given slotIndex
function ItemFrame:GetItemSlot(bag, slot)
	return self.itemSlots[self:GetSlotIndex(bag, slot)]
end

function ItemFrame:GetAllItemSlots()
	return pairs(self.itemSlots)
end

--takes a bag and a slot, and returns an array index
function ItemFrame:GetSlotIndex(bag, slot)
	if bag < 0 then
		return bag*100 - slot
	end
	return bag * 100 + slot
end

--remove all item slots from the frame
function ItemFrame:AddAllItemSlotsForBag(bag)
	for slot = 1, self:GetBagSize(bag) do
		self:AddItemSlot(bag, slot)
	end
end

function ItemFrame:RemoveAllItemSlotsForBag(bag)
	for slot = 1, self:GetBagSize(bag) do
		self:RemoveItemSlot(bag, slot)
	end
end

function ItemFrame:UpdateAllItemSlotsForBag(bag)
	for slot = 1, self:GetBagSize(bag) do
		self:UpdateItemSlot(bag, slot)
	end
end

--remove all unused item slots from the frame
--add all missing slots to the frame
--update all existing slots on the frame
--if slots have been added or removed, then request a layout update
function ItemFrame:ReloadAllItemSlots()
	local changed = false

	local itemSlots = self.itemSlots
	for i, itemSlot in pairs(itemSlots) do
		local used = self:IsBagShown(itemSlot:GetBag()) and (itemSlot:GetID() <= self:GetBagSize(itemSlot:GetBag()))
		if not used then
			itemSlot:Free()
			itemSlots[i] = nil
			changed = true
		end
	end

	for _, bag in self:GetVisibleBags() do
		for slot = 1, self:GetBagSize(bag) do
			local itemSlot = self:GetItemSlot(bag, slot)
			if not itemSlot then
				self:AddItemSlot(bag, slot)
				changed = true
			else
				itemSlot:Update()
			end
		end
	end

	if changed then
		self:RequestLayout()
	end
end


--[[ Layout Methods ]]--

function ItemFrame:Layout()
	if self:IsBagBreakEnabled() then
		self:Layout_BagBreak()
	else
		self:Layout_Default()
	end
end

--arranges itemSlots on the itemFrame, and adjusts size to fit
function ItemFrame:Layout_Default()
	self.needsLayout = nil

	local columns = self:NumColumns()
	local spacing = self:GetSpacing()
	local effItemSize = self.ITEM_SIZE + spacing

	local i = 0
	for _, bag in self:GetVisibleBags() do
		for slot = 1, self:GetBagSize(bag) do
			local itemSlot = self:GetItemSlot(bag, slot)
			if itemSlot then
				i = i + 1
				local row = (i - 1) % columns
				local col = math.ceil(i / columns) - 1
				itemSlot:ClearAllPoints()
				itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', effItemSize * row, -effItemSize * col)
			end
		end
	end

	local width = effItemSize * math.min(columns, i) - spacing
	local height = effItemSize * ceil(i / columns) - spacing
	self:SetWidth(width)
	self:SetHeight(height)
end


function ItemFrame:Layout_BagBreak()
	self.needsLayout = nil

	local columns = self:NumColumns()
	local spacing = self:GetSpacing()
	local effItemSize = self.ITEM_SIZE + spacing

	local rows = 1
	local col = 1
	local maxCols = 0

	for _, bag in self:GetVisibleBags() do
		local bagSize = self:GetBagSize(bag)
		for slot = 1, bagSize do
			local itemSlot = self:GetItemSlot(bag, slot)

			itemSlot:ClearAllPoints()
			itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', effItemSize * (col - 1), -effItemSize * (rows - 1))

			if col == columns then
				col = 1
				if slot < bagSize then
					rows = rows + 1
				end
			else
				col = col + 1
				maxCols = math.max(maxCols, col)
			end
		end

		rows = rows + 1
		col = 1
	end

	local width = effItemSize * maxCols - spacing*2
	local height = effItemSize * (rows - 1) - spacing*2
	self:SetWidth(width)
	self:SetHeight(height)
end

--request a layout update on this frame
function ItemFrame:RequestLayout()
	self.needsLayout = true
	self.throttledUpdater:Show()
end

--returns true if the frame should have its layout updated, and false otherwise
function ItemFrame:NeedsLayout()
	return self.needsLayout
end


--[[ Frame Properties ]]--

--frameID
function ItemFrame:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function ItemFrame:GetFrameID()
	return self.frameID
end

--frame settings
function ItemFrame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

--player info
function ItemFrame:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function ItemFrame:IsCached()
	return Bagnon.PlayerInfo:IsCached(self:GetPlayer())
end

--bag info
function ItemFrame:HasBag(bag)
	return self:GetSettings():HasBagSlot(slot)
end

function ItemFrame:GetBagSize(bag)
	return Bagnon.BagSlotInfo:GetSize(self:GetPlayer(), bag)
end

function ItemFrame:IsBagShown(bag)
	return self:GetSettings():IsBagSlotShown(bag)
end

function ItemFrame:IsBagSlotCached(bag)
	return Bagnon.BagSlotInfo:IsCached(self:GetPlayer(), bag)
end

function ItemFrame:GetVisibleBags()
	return self:GetSettings():GetVisibleBagSlots()
end

function ItemFrame:HasBankBags()
	for _, bag in self:GetVisibleBags() do
		if Bagnon.BagSlotInfo:IsBank(bag) or Bagnon.BagSlotInfo:IsBankBag(bag) then
			return true
		end
	end
	return false
end

--layout info
function ItemFrame:NumColumns()
	return self:GetSettings():GetItemFrameColumns()
end

function ItemFrame:GetSpacing()
	return self:GetSettings():GetItemFrameSpacing()
end

function ItemFrame:IsBagBreakEnabled()
	return self:GetSettings():IsBagBreakEnabled()
end