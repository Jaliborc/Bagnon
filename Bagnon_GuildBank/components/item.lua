--[[
	item.lua
		A guild item slot button
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local ItemSlot = Bagnon.Classy:New('Button')
ItemSlot:Hide()
Bagnon.GuildItemSlot = ItemSlot

local ItemSearch = LibStub('LibItemSearch-1.0')


--[[
	The item widget
--]]


--[[ ItemSlot Constructor ]]--

function ItemSlot:New(tab, slot, frameID, parent)
	local item = self:Restore() or self:Create()
	item:SetParent(parent)
	item:SetSlot(tab, slot)
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
	local item = self:Bind(self:ConstructNewItemSlot(id))

	item:RegisterForClicks('anyUp')
	item:RegisterForDrag('LeftButton')

	item:SetScript('OnEvent', item.HandleEvent)
	item:SetScript('OnClick', item.OnClick)
	item:SetScript('OnDragStart', item.OnDragStart)
	item:SetScript('OnReceiveDrag', item.OnReceiveDrag)
	item:SetScript('OnEnter', item.OnEnter)
	item:SetScript('OnLeave', item.OnLeave)
	item:SetScript('OnShow', item.OnShow)
	item:SetScript('OnHide', item.OnHide)

	return item
end

--creates a new item slot for <id>
function ItemSlot:ConstructNewItemSlot(id)
	local item = CreateFrame('Button', 'BagnonGuildItemSlot' .. id, nil, 'ItemButtonTemplate')
	item:Hide()

	--add a quality border texture
	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67)
	border:SetHeight(67)
	border:SetPoint('CENTER', item)
	border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
	border:SetBlendMode('ADD')
	border:Hide()
	item.border = border

	return item
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


function ItemSlot:GUILDBANK_ITEM_LOCK_CHANGED(event, tab, slot)
	self:UpdateLocked()
end

function ItemSlot:TEXT_SEARCH_UPDATE(msg, frameID, search)
	self:UpdateSearch()
end

function ItemSlot:ITEM_HIGHLIGHT_QUALITY_UPDATE(msg, enable)
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_QUEST_UPDATE(msg, enable)
	self:UpdateBorder()
end

function ItemSlot:SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE(msg, enable)
	self:Update()
end

function ItemSlot:ITEM_SLOT_COLOR_UPDATE(msg, enable)
	self:Update()
end

function ItemSlot:HandleEvent(msg, ...)
	local action = self[msg]
	if action then
		action(self, msg, ...)
	end
end


--[[ Frame Events ]]--

function ItemSlot:OnClick(button)
	if HandleModifiedItemClick(self:GetItem()) then
		return
	end

	if self:IsCached() then
		return
	end

	if IsModifiedClick('SPLITSTACK') then
		if not self:IsLocked() then
			OpenStackSplitFrame(self:GetCount(), self, 'BOTTOMLEFT', 'TOPLEFT')
		end
		return
	end

	local type, money = GetCursorInfo()
	if type == 'money' then
		DepositGuildBankMoney(money)
		ClearCursor()
	elseif type == 'guildbankmoney' then
		DropCursorMoney()
		ClearCursor()
	else
		if button == 'RightButton' then
			AutoStoreGuildBankItem(self:GetSlot())
		else
			PickupGuildBankItem(self:GetSlot())
		end
	end
end

function ItemSlot:OnDragStart(button)
	PickupGuildBankItem(self:GetSlot())
end

function ItemSlot:OnReceiveDrag(button)
	PickupGuildBankItem(self:GetSlot())
end

function ItemSlot:OnShow()
	self:Update()
	self:RegisterEvent('GUILDBANK_ITEM_LOCK_CHANGED')
end

function ItemSlot:OnHide()
	self:HideStackSplitFrame()
	self:UnregisterAllEvents()
end

function ItemSlot:OnEnter()
	self:AnchorTooltip()
	self:UpdateTooltip()
end

function ItemSlot:OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end


--[[ Update Methods ]]--

-- Update the texture, lock status, and other information about an item
function ItemSlot:Update()
	if not self:IsVisible() then return end
	local texture, itemCount, locked, itemLink = self:GetItemSlotInfo()

	self:SetItem(itemLink)
	self:SetTexture(texture)
	self:SetCount(itemCount)
	self:SetLocked(locked)

	self:UpdateBorder()
	self:UpdateSearch()
--	self:UpdateBagSearch()

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

local EMPTY_SLOT_TEXTURE = [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
function ItemSlot:GetEmptyItemTexture()
	if self:ShowingEmptyItemSlotTexture() then
		return EMPTY_SLOT_TEXTURE
	end
	return nil
end

--item count
function ItemSlot:SetCount(count)
	SetItemButtonCount(self, count)
end

function ItemSlot:GetCount()
	local texture, itemCount = self:GetItemSlotInfo()
	return itemCount or 0
end

--locked status
function ItemSlot:SetLocked(locked)
	SetItemButtonDesaturated(self, locked, 0.5, 0.5, 0.5)
end

function ItemSlot:UpdateLocked()
	self:SetLocked(self:IsLocked())
end

--returns true if the slot is locked, and false otherwise
function ItemSlot:IsLocked()
	local texture, itemCount, locked = self:GetItemSlotInfo()
	return locked
end

--colors the item border based on the quality of the item.  hides it for common/poor items
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

function ItemSlot:UpdateBorder()
	local itemLink = self:GetItem()

	if itemLink then
		local name, link, quality = GetItemInfo(itemLink)
		self:SetBorderQuality(quality)
	else
		self:SetBorderQuality(nil)
	end
end

--stack split frame
function ItemSlot:SplitStack(split)
	local tab, slot = self:GetSlot()
	SplitGuildBankItem(tab, slot, split)
end

function ItemSlot:HideStackSplitFrame()
	if self.hasStackSplit and self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end
end

--tooltip methods
function ItemSlot:UpdateTooltip()
	if self:IsCached() then
		GameTooltip:SetHyperlink(self:GetItem())
	else
		GameTooltip:SetGuildBankItem(self:GetSlot())
	end

	GameTooltip:Show()
end

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
--		self:UpdateSlotColor()
	end
end

function ItemSlot:GetItemSearch()
	return Bagnon.Settings:GetTextSearch()
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

function ItemSlot:SetSlot(tab, slot)
	self.tab = tab
	self:SetID(slot)
	self:Update()
end

function ItemSlot:GetSlot()
	return self.tab, self:GetID()
end

function ItemSlot:IsSlot(tab, slot)
	return self.tab == tab and self:GetID() == slot
end

function ItemSlot:IsCached()
	return false
end

function ItemSlot:GetItemSlotInfo()
	local texture, itemCount, locked = GetGuildBankItemInfo(self:GetSlot())
	local itemLink = GetGuildBankItemLink(self:GetSlot())

	return texture, itemCount, locked, itemLink
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

local QUEST_ITEM_SEARCH = string.format('t:%s|%s', select(12, GetAuctionItemClasses()), 'quest')
function ItemSlot:IsQuestItem()
	local itemLink = self:GetItem()
	if not itemLink then
		return false
	end

	return ItemSearch:Find(itemLink, QUEST_ITEM_SEARCH)
end


--[[ Empty Slot Visibility ]]--

function ItemSlot:ShowingEmptyItemSlotTexture()
	return Bagnon.Settings:ShowingEmptyItemSlotTextures()
end