--[[
	itemFrame.lua
		An guild bank item slot container
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemFrame = Bagnon.Classy:New('Frame')
ItemFrame:Hide()
Bagnon.GuildItemFrame = ItemFrame


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

function ItemFrame:GUILDBANKBAGSLOTS_CHANGED(event, ...)
	self:ReloadAllItemSlots()
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

function ItemFrame:HandleGlobalItemEvent(msg, ...)
	for i, item in self:GetAllItemSlots() do
		item:HandleEvent(msg, ...)
	end
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
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterEvent('GUILDBANKBAGSLOTS_CHANGED')
		
		self:RegisterMessage('ITEM_FRAME_SPACING_UPDATE')
		self:RegisterMessage('ITEM_FRAME_COLUMNS_UPDATE')

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
function ItemFrame:AddItemSlot(slot)
	if not self:GetItemSlot(slot) then
		local itemSlot = self:NewItemSlot(slot)
		self.itemSlots[slot] = itemSlot
		self:RequestLayout()
	end
end

function ItemFrame:NewItemSlot(slot)
	return Bagnon.GuildItemSlot:New(self:GetCurrentTab(), slot, self:GetFrameID(), self)
end

--returns the item slot assigned to the given slotIndex
function ItemFrame:GetItemSlot(slot)
	return self.itemSlots[slot]
end

function ItemFrame:GetAllItemSlots()
	return ipairs(self.itemSlots)
end


--remove all unused item slots from the frame
--add all missing slots to the frame
--update all existing slots on the frame
--if slots have been added or removed, then request a layout update
function ItemFrame:ReloadAllItemSlots()
	local changed = false

	local currentTab = self:GetCurrentTab()
	for slot = 1, self:GetCurrentTabSize() do
		local itemSlot = self:GetItemSlot(slot)
		if not itemSlot then
			self:AddItemSlot(slot)
			changed = true
		else
			itemSlot:SetSlot(currentTab, slot)
		end
	end

	if changed then
		self:RequestLayout()
	end
end


--[[ Layout Methods ]]--

--arranges itemSlots on the ItemFrame, and adjusts size to fit
--it should be noted that the guild bank is wacky in that items go down a column
function ItemFrame:Layout()
	self.needsLayout = nil

	local numItems = self:GetCurrentTabSize()
	local numColumns = math.min(self:NumColumns(), numItems)
	local numRows = math.floor(numItems / numColumns + 0.5)
	local spacing = self:GetSpacing()
	local effItemSize = self.ITEM_SIZE + spacing

	local row, col = 0, 1
	for i, itemSlot in self:GetAllItemSlots() do
		row = row + 1
		if row > numRows then
			row = 1
			col = col + 1
		end
		
		itemSlot:ClearAllPoints()
		itemSlot:SetPoint('TOPLEFT', self, 'TOPLEFT', effItemSize * (col - 1), -effItemSize * (row - 1))
	end

	local width = effItemSize * col - spacing
	local height = effItemSize * numRows - spacing
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

--layout info
function ItemFrame:NumColumns()
	return self:GetSettings():GetItemFrameColumns()
end

function ItemFrame:GetSpacing()
	return self:GetSettings():GetItemFrameSpacing()
end

--guild bank info
function ItemFrame:GetCurrentTab()
	return GetCurrentGuildBankTab() or 0
end

function ItemFrame:GetCurrentTabSize()
	return 98
end