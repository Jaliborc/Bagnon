--[[
	itemFrame.lua
		An item slot container
--]]

local _, Addon = ...
local ItemFrame = Addon:NewClass('ItemFrame', 'Frame')
local Cache = LibStub('LibItemCache-1.0')
ItemFrame.ITEM_SIZE = 39
ItemFrame.COLUMN_OFF = 0


--[[ Constructor ]]--

local function throttledUpdater_OnUpdate(self, elapsed)
	local p = self:GetParent()
	if p:NeedsLayout() then
		p:Layout()
	end
	self:Hide()
end

function ItemFrame:New(frameID, parent, kind)
	local f = self:Bind(CreateFrame('Frame', nil, parent))

	f.kind = kind
	f.itemSlots = {}
	f.throttledUpdater = CreateFrame('Frame', nil, f)
	f.throttledUpdater:SetScript('OnUpdate', throttledUpdater_OnUpdate)
	
	f.title = f:CreateFontString(nil, nil, 'GameFontHighlight')
	f.title:SetPoint('TOPLEFT', 0, 15)
	
	f:SetSize(1,1)
	f:SetFrameID(frameID)
	f:SetScript('OnSizeChanged', f.OnSizeChanged)
	f:SetScript('OnEvent', f.OnEvent)
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

	return f
end


--[[ Client Events ]]--

function ItemFrame:OnEvent(event, ...)
	local action = self[event]
	if action then
		action(self, event, ...)
	end
end

do
	local function UpdateEverything(self)
		self:UpdateEverything()
	end
	
	ItemFrame.GET_ITEM_INFO_RECEIVED = UpdateEverything
	ItemFrame.BANK_OPENED = UpdateEverything
	ItemFrame.BANK_CLOSED = UpdateEverything
end


--[[ Item Events ]]--

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

function ItemFrame:BAG_DISABLE_UPDATE()
	self:ReloadAllItemSlots()
end

function ItemFrame:EQUIPMENT_SETS_CHANGED()
	self:HandleGlobalItemEvent('EQUIPMENT_SETS_CHANGED')
end

function ItemFrame:QUEST_ACCEPTED()
	self:HandleGlobalItemEvent('QUEST_LOG_CHANGED')
end

function ItemFrame:UNIT_QUEST_LOG_CHANGED(_, unit)
	if unit == 'player' then
		self:HandleGlobalItemEvent('QUEST_LOG_CHANGED')
	end
end

do
	local function LayoutEvent(self, msg, frameID)
        if self:GetFrameID() == frameID then
        	self:RequestLayout()
        end
	end

	ItemFrame.SLOT_ORDER_UPDATE = LayoutEvent
	ItemFrame.ITEM_FRAME_SPACING_UPDATE = LayoutEvent
	ItemFrame.ITEM_FRAME_COLUMNS_UPDATE = LayoutEvent
	ItemFrame.ITEM_FRAME_BAG_BREAK_UPDATE = LayoutEvent
end


--[[ Item Events API ]]--

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
	Addon.BagEvents.Listen(self, ...)
end

function ItemFrame:UnregisterItemEvent(...)
	Addon.BagEvents.Ignore(self, ...)
end

function ItemFrame:UnregisterAllItemEvents(...)
	Addon.BagEvents.IgnoreAll(self, ...)
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
		if not self:IsCached() then
			self:RegisterEvent('ITEM_LOCK_CHANGED')
      		self:RegisterEvent('QUEST_ACCEPTED')
      		self:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
      		self:RegisterEvent('EQUIPMENT_SETS_CHANGED')

			self:RegisterItemEvent('ITEM_SLOT_ADD')
			self:RegisterItemEvent('ITEM_SLOT_REMOVE')
			self:RegisterItemEvent('ITEM_SLOT_UPDATE', 'HandleSpecificItemEvent')
			self:RegisterItemEvent('ITEM_SLOT_UPDATE_COOLDOWN', 'HandleSpecificItemEvent')
			self:RegisterItemEvent('BAG_UPDATE_TYPE')

			if self:HasBankBags() then
				self:RegisterItemEvent('BANK_OPENED')
				self:RegisterItemEvent('BANK_CLOSED')
			end
		else
			self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
		end

		self:RegisterMessage('BAG_SLOT_SHOW')
		self:RegisterMessage('BAG_SLOT_HIDE')
		self:RegisterMessage('PLAYER_UPDATE')
		self:RegisterMessage('SLOT_ORDER_UPDATE')
		self:RegisterMessage('ITEM_FRAME_BAG_BREAK_UPDATE')
		self:RegisterMessage('BAG_DISABLE_UPDATE')
		self:RegisterGlobalItemEvents()
	end
end

function ItemFrame:RegisterGlobalItemEvents()
	self:RegisterMessage('ITEM_FRAME_SPACING_UPDATE')
	self:RegisterMessage('ITEM_FRAME_COLUMNS_UPDATE')
	
	self:RegisterMessage('TEXT_SEARCH_UPDATE', 'HandleGlobalItemEvent')
	self:RegisterMessage('FLASH_SEARCH_UPDATE', 'HandleGlobalItemEvent')
	self:RegisterMessage('BAG_SEARCH_UPDATE', 'HandleGlobalItemEvent')
	self:RegisterMessage('ITEM_HIGHLIGHT_UPDATE', 'HandleGlobalItemEvent')
	self:RegisterMessage('SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE', 'HandleGlobalItemEvent')
	self:RegisterMessage('ITEM_SLOT_COLOR_UPDATE', 'HandleGlobalItemEvent')
	self:RegisterMessage('ITEM_SLOT_COLOR_ENABLED_UPDATE', 'HandleGlobalItemEvent')
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
	return Addon.ItemSlot:New(bag, slot, self:GetFrameID(), self)
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
		return bag * 100 - slot
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
	self.needsLayout = nil
	
	if self.HasRowLayout then
		self:Layout_NoBag()
	elseif self:IsBagBreakEnabled() then
		self:Layout_BagBreak()
	else
		self:Layout_Default()
	end
end

--arranges itemSlots on the itemFrame, and adjusts size to fit
function ItemFrame:Layout_Default()
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
				local col = ceil(i / columns) - 1
				itemSlot:ClearAllPoints()
				itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', effItemSize * row, -effItemSize * col)
			end
		end
	end

	local width = effItemSize * min(columns, i) - spacing
	local height = effItemSize * ceil(i / columns) - spacing
	self:SetSize(width, height)
end


-- groups items in bags, much alike text in paragraphs
function ItemFrame:Layout_BagBreak()
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
				maxCols = max(maxCols, col)
			end
		end

		rows = rows + 1
		col = 1
	end

	local width = effItemSize * maxCols - spacing*2
	local height = effItemSize * (rows - 1) - spacing*2
	self:SetSize(width, height)
end


-- for use on non-bag frames (ex: guilBank). Items go down a column or a row.
function ItemFrame:Layout_NoBag()
	local numSlots = self:GetNumSlots()
	if numSlots == 0 then
		return
	end
	
	local numCol = min(self:NumColumns() - self.COLUMN_OFF, numSlots)
	local numRows = ceil(numSlots / numCol)
	
	local useRows = self:HasRowLayout()
	local limit = useRows and numCol or numRows
	
	local spacing = self:GetSpacing()
	local itemSize = self.ITEM_SIZE + spacing

	local a, b = 0, 0
	for i, itemSlot in self:GetAllItemSlots() do
		if a == limit then
			a = 0
			b = b + 1
		end
	
		itemSlot:ClearAllPoints()
		if useRows then
			itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', itemSize * a, -itemSize * b)
		else
			itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', itemSize * b, -itemSize * a)
		end
		
		a = a + 1
	end

	local width = itemSize * numCol - spacing
	local height = itemSize * numRows - spacing
	self:SetSize(width, height)
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
	return Addon.FrameSettings:Get(self:GetFrameID())
end

--player info
function ItemFrame:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function ItemFrame:IsCached()
	return Cache:IsPlayerCached(self:GetPlayer())
end

--bag info
function ItemFrame:HasBag(bag)
	return self:GetSettings():HasBagSlot(slot)
end

function ItemFrame:GetBagSize(bag)
	return Addon:GetBagSize(self:GetPlayer(), bag)
end

function ItemFrame:IsBagShown(bag)
	return self:GetSettings():IsBagSlotShown(bag)
end

function ItemFrame:IsBagSlotCached(bag)
	return Addon:IsBagCached(self:GetPlayer(), bag)
end

function ItemFrame:GetVisibleBags()
	return self:GetSettings():GetVisibleBagSlots()
end

function ItemFrame:HasBankBags()
	for _, bag in self:GetVisibleBags() do
		if Addon:IsBank(bag) or Addon:IsBankBag(bag) then
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