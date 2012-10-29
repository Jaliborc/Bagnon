--[[
	item.lua
		An item slot button
--]]

local AddonName, Addon = ...
local ItemSlot = Addon:NewClass('ItemSlot', 'Button')
ItemSlot.nextID = 0
ItemSlot.unused = {}

local Cache = LibStub('LibItemCache-1.0')
local ItemSearch = LibStub('LibItemSearch-1.0')
local Unfit = LibStub('Unfit-1.0')


--[[ Constructor ]]--

function ItemSlot:New(bag, slot, frameID, parent)
	local item = self:Restore() or self:Create()
	item:SetFrame(parent, bag, slot)
	item:SetFrameID(frameID)

	if item:IsVisible() then
		item:Update()
	else
		item:Show()
	end
	return item
end

function ItemSlot:SetFrame(parent, bag, slot)
  self:SetParent(self:GetDummyBag(parent, bag))
  self:SetID(slot)
end

--constructs a brand new item slot
function ItemSlot:Create()
	local id = self:GetNextItemSlotID()
	local item = self:Bind(self:GetBlizzardItemSlot(id) or self:ConstructNewItemSlot(id))
	local name = item:GetName()

	--add a quality border texture
	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetSize(67, 67)
	border:SetPoint('CENTER', item)
	border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
	border:SetBlendMode('ADD')
	border:Hide()
	
	--hack, make sure the cooldown model stays visible
	item.questBorder = _G[name .. 'IconQuestTexture']
	item.cooldown = _G[name .. 'Cooldown']
	item.UpdateTooltip = nil
	item.border = border

	--get rid of any registered frame events, and use our own
	item:HookScript('OnClick', item.OnClick)
	item:SetScript('PreClick', item.OnPreClick)
	item:HookScript('OnDragStart', item.OnDragStart)
	item:SetScript('OnEnter', item.OnEnter)
	item:SetScript('OnLeave', item.OnLeave)
	item:SetScript('OnShow', item.OnShow)
	item:SetScript('OnHide', item.OnHide)
	item:SetScript('OnEvent', nil)
	item:Hide()

	return item
end

function ItemSlot:ConstructNewItemSlot(id)
	return CreateFrame('Button', ('%sItem%d'):format(AddonName, id), nil, 'ContainerFrameItemButtonTemplate')
end

function ItemSlot:GetBlizzardItemSlot(id)
	if not self:CanReuseBlizzardBagSlots() then
		return
	end

	local bag = ceil(id / MAX_CONTAINER_ITEMS)
	local slot = (id-1) % MAX_CONTAINER_ITEMS + 1
	local item = _G[format('ContainerFrame%dItem%d', bag, slot)]

	if item then
		item:SetID(0)
		item:ClearAllPoints()
		return item
	end
end

function ItemSlot:CanReuseBlizzardBagSlots()
	return Addon.Settings:AreAllFramesEnabled() and (not Addon.Settings:IsBlizzardBagPassThroughEnabled())
end

function ItemSlot:Restore()
	local item = self.unused and next(self.unused)
	if item then
		self.unused[item] = nil
		return item
	end
end

function ItemSlot:GetNextItemSlotID()
  self.nextID = self.nextID + 1
  return self.nextID
end


--[[ Destructor ]]--

function ItemSlot:Free()
	self:Hide()
	self:SetParent(nil)
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	self.unused[self] = true
	self.depositSlot = nil
end


--[[ Events ]]--

function ItemSlot:ITEM_SLOT_UPDATE()
	self:Update()
end

function ItemSlot:ITEM_LOCK_CHANGED()
	self:UpdateLocked()
end

function ItemSlot:ITEM_SLOT_UPDATE_COOLDOWN()
	self:UpdateCooldown()
end

function ItemSlot:TEXT_SEARCH_UPDATE()
	self:UpdateSearch()
end

function ItemSlot:BAG_SEARCH_UPDATE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdateBagSearch()
	end
end

function ItemSlot:ITEM_HIGHLIGHT_QUALITY_UPDATE()
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_UNUSABLE_UPDATE()
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_QUEST_UPDATE()
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_OPACITY_UPDATE()
	self:UpdateBorder()
end

function ItemSlot:SHOW_EMPTY_ITEM_SLOT_TEXTURE_UPDATE()
	self:Update()
end

function ItemSlot:ITEM_SLOT_COLOR_ENABLED_UPDATE()
	self:Update()
end

function ItemSlot:ITEM_SLOT_COLOR_UPDATE()
	self:Update()
end

function ItemSlot:QUEST_ACCEPTED()
	self:UpdateBorder()
end

function ItemSlot:UNIT_QUEST_LOG_CHANGED()
	self:UpdateBorder()
end

-- Flash search broadcast hook
function ItemSlot:FLASH_SEARCH_UPDATE(msg, search)
	self:FlashSearch(search)
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
	ItemSlot.Cursor = self
end

function ItemSlot:OnPreClick(button)
	if button == 'RightButton' and not self.canDeposit then
		for i = 1,9 do
			if not GetVoidTransferDepositInfo(i) then
				self.depositSlot = i
				return
			end
		end
	end
end

function ItemSlot:OnClick(button)
	if IsAltKeyDown() and button == 'LeftButton' then
		local link = self:GetItem()
		if link then
			Addon.Settings:FlashFind(link:match('^|c%x+|Hitem.+|h%[(.*)%]'))
		end
	elseif GetNumVoidTransferDeposit() > 0 and button == 'RightButton' then
		if self.canDeposit and self.depositSlot then
			ClickVoidTransferDepositSlot(self.depositSlot, true)
		end

		self.canDeposit = not self.canDeposit
	end
end

function ItemSlot:OnModifiedClick(...)
	local link = self:IsCached() and self:GetItem()
	if link and not HandleModifiedItemClick(link) then
		self:OnClick(...)
	end
end

function ItemSlot:OnEnter()
	local dummySlot = self:GetDummyItemSlot()
	ResetCursor()

	if self:IsCached() then
		dummySlot:SetParent(self)
		dummySlot:SetAllPoints(self)
		dummySlot:Show()
		
	elseif self:GetItem() then
		self:AnchorTooltip()
		self:ShowTooltip()

	else
		self:OnLeave()
	end
end

function ItemSlot:OnLeave()
	GameTooltip:Hide()
	BattlePetTooltip:Hide()
	ResetCursor()
end


--[[ Update Methods ]]--


-- Update the texture, lock status, and other information about an item
function ItemSlot:Update()
  if not self:IsVisible() then
    return
  end

	local icon, count, locked, quality, readable, lootable, link = self:GetInfo()
	self:SetItem(link)
	self:SetTexture(icon)
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
function ItemSlot:SetItem(item)
	self.item = item
end

function ItemSlot:GetItem()
	return self.item
end

--item texture
function ItemSlot:SetTexture(texture)
	SetItemButtonTexture(self, texture or self:GetEmptyItemTexture())
end

function ItemSlot:GetEmptyItemTexture()
	if self:ShowingEmptyItemSlotTexture() then
		return [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
	end
end

--item slot color
function ItemSlot:UpdateSlotColor()
	if (not self:GetItem()) and self:ColoringBagSlots() then
		self:SetSlotColor(self:GetBagColor(self:GetBagType()))
	else 
		self:SetSlotColor(1, 1, 1)
	end
end

function ItemSlot:SetSlotColor(...)
	SetItemButtonTextureVertexColor(self, ...)
	self:GetNormalTexture():SetVertexColor(...)
end

function ItemSlot:SetCount(count)
	SetItemButtonCount(self, count)
end

function ItemSlot:SetReadable(readable)
	self.readable = readable
end


--[[ Locked ]]--

function ItemSlot:SetLocked(locked)
	SetItemButtonDesaturated(self, locked)
end

function ItemSlot:UpdateLocked()
	self:SetLocked(self:IsLocked())
end

function ItemSlot:IsLocked()
	return select(3, self:GetInfo())
end


--[[ Border Quality ]]--

function ItemSlot:SetBorderQuality(quality)
	local border = self.border
	local qBorder = self.questBorder
	
	qBorder:Hide()
	border:Hide()

	if self:HighlightingQuestItems() then
		local isQuestItem, isQuestStarter = self:IsQuestItem()
		if isQuestItem then
			border:SetVertexColor(1, .82, .2,  self:GetHighlightAlpha())
			border:Show()
			return
		end

		if isQuestStarter then
			qBorder:SetTexture(TEXTURE_ITEM_QUEST_BANG)
			qBorder:Show()
			return
		end
	end
	
	if self:HighlightUnusableItems() then
		local link = self:GetItem()
		if Unfit:IsItemUnusable(link) then
			local r, g, b = RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b
			border:SetVertexColor(r, g, b, self:GetHighlightAlpha())
			border:Show()
			return
		end
	end
	
	if self:HighlightingItemsByQuality() then
		if self:GetItem() and quality and quality > 1 then
			local r, g, b = GetItemQualityColor(quality)
			border:SetVertexColor(r, g, b, self:GetHighlightAlpha())
			border:Show()
		end
	end
end

function ItemSlot:UpdateBorder()
	self:SetBorderQuality(select(4, self:GetInfo()))
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
function ItemSlot:UpdateTooltip()
	self:OnEnter()
end

function ItemSlot:ShowTooltip()
	if self:IsBank() then
		GameTooltip:SetInventoryItem('player', BankButtonIDToInvSlotID(self:GetID()))
		GameTooltip:Show()
		CursorUpdate(self)
	else
		ContainerFrameItemButton_OnEnter(self)
	end	
end

function ItemSlot:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end


--[[ Search ]]--

function ItemSlot:UpdateSearch()
	local shouldFade = false
	local search = self:GetItemSearch()

	if search and search ~= '' then
		local link = self:GetItem()
		shouldFade = not (link and ItemSearch:Find(link, search))
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
	return Addon.Settings:GetTextSearch()
end

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

-- if the current item does match the sought name, flash it
function ItemSlot:FlashSearch(search)
	if search and search ~= '' then
		local link = self:GetItem()
		if ItemSearch:Find(link, search) then
			UIFrameFlash(self, 0.2, 0.3, 1.5, true, 0.0, 0.0 )
		end
	end
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
	return Addon.FrameSettings:Get(self:GetFrameID())
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
	return select(8, self:GetInfo())
end

function ItemSlot:IsBank()
	return Addon:IsBank(self:GetBag())
end

function ItemSlot:IsBankSlot()
	local bag = self:GetBag()
	return Addon:IsBank(bag) or Addon:IsBankBag(bag)
end

function ItemSlot:GetInfo()
	return Cache:GetItemInfo(self:GetPlayer(), self:GetBag(), self:GetID())
end


--[[ Item Type Highlighting ]]--

function ItemSlot:HighlightingItemsByQuality()
	return Addon.Settings:HighlightingItemsByQuality()
end

function ItemSlot:HighlightUnusableItems()
	return Addon.Settings:HighlightUnusableItems()
end

function ItemSlot:HighlightingQuestItems()
	return Addon.Settings:HighlightingQuestItems()
end

function ItemSlot:GetHighlightAlpha()
	return Addon.Settings:GetHighlightOpacity()
end

--returns true if the item is a quest item or not
--includes a second return to determine if the item is a quest starter for a quest the player lacks
local QUEST_ITEM_SEARCH = format('t:%s|%s', select(10, GetAuctionItemClasses()), 'quest')

function ItemSlot:IsQuestItem()
	local item = self:GetItem()
	if not item then
		return false
	end

	if self:IsCached() then
		return ItemSearch:Find(item, QUEST_ITEM_SEARCH), false
	else
		local isQuestItem, questID, isActive = GetContainerItemQuestInfo(self:GetBag(), self:GetID())
		return isQuestItem, (questID and not isActive)
	end
end


--[[ Item Slot Coloring ]]--

function ItemSlot:GetBagType()
	return Addon:GetBagType(self:GetPlayer(), self:GetBag())
end

function ItemSlot:GetBagColor(bagType)
	return Addon.Settings:GetItemSlotColor(bagType)
end

function ItemSlot:ColoringBagSlots()
	return Addon.Settings:ColoringBagSlots()
end


--[[ Empty Slot Visibility ]]--

function ItemSlot:ShowingEmptyItemSlotTexture()
	return Addon.Settings:ShowingEmptyItemSlotTextures()
end


--[[ Delicious Hacks ]]--

-- dummy slot - A hack, used to provide a tooltip for cached items without tainting other item code
function ItemSlot:GetDummyItemSlot()
	ItemSlot.dummySlot = ItemSlot.dummySlot or ItemSlot:CreateDummyItemSlot()
	ItemSlot.dummySlot:Hide()
	return ItemSlot.dummySlot
end

function ItemSlot:CreateDummyItemSlot()
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:SetToplevel(true)
	slot:Hide()

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		local item = parent:IsCached() and parent:GetItem()
		
		if item then
			parent.AnchorTooltip(self)
			
			if item:find('battlepet:') then
				local _, specie, level, quality, health, power, speed = strsplit(':', item)
				local name = item:match('%[(.-)%]')
				
				BattlePetToolTip_Show(
					tonumber(specie), level, tonumber(quality), health, power, speed, name)
			else
				GameTooltip:SetHyperlink(item)
				GameTooltip:Show()
			end
		end
		
		parent:LockHighlight()
	end

	local function Slot_OnLeave(self)
		self:GetParent():OnLeave()
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