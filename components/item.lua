--[[
	item.lua
		An item slot button
--]]

local ADDON, Addon = ...
local ItemSlot = Addon:NewClass('ItemSlot', 'Button')
ItemSlot.dummyBags = {}
ItemSlot.unused = {}
ItemSlot.nextID = 0

local Cache = LibStub('LibItemCache-1.1')
local ItemSearch = LibStub('LibItemSearch-1.2')
local Unfit = LibStub('Unfit-1.0')
local QuestSearch = format('t:%s|%s', select(10, GetAuctionItemClasses()), 'quest')


--[[ Constructor ]]--

function ItemSlot:New()
	return self:Restore() or self:Create()
end

function ItemSlot:Create()
	local id = self:GetNextItemSlotID()
	local item = self:Bind(self:GetBlizzardItemSlot(id) or self:ConstructNewItemSlot(id))
	local name = item:GetName()

	-- add a quality border texture
	local border = item:CreateTexture(nil, 'OVERLAY')
	border:SetSize(67, 67)
	border:SetPoint('CENTER', item)
	border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
	border:SetBlendMode('ADD')
	border:Hide()

	-- add flash find animation
	local flash = item:CreateAnimationGroup()
	for i = 1, 3 do
		local fade = flash:CreateAnimation('Alpha')
		fade:SetDuration(.2)
		fade:SetChange(-.8)
		fade:SetOrder(i * 2)

		local fade = flash:CreateAnimation('Alpha')
		fade:SetDuration(.3)
		fade:SetChange(.8)
		fade:SetOrder(i * 2 + 1)
	end
	
	item.UpdateTooltip = nil
	item.Border, item.Flash = border, flash
	item.newitemglowAnim:SetLooping('NONE')
	item.QuestBorder = _G[name .. 'IconQuestTexture']
	item.Cooldown = _G[name .. 'Cooldown']
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
	return CreateFrame('Button', ('%s%s%d'):format(ADDON, self.Name, id), nil, 'ContainerFrameItemButtonTemplate')
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

function ItemSlot:Restore()
	return tremove(self.unused)
end

function ItemSlot:GetNextItemSlotID()
  self.nextID = self.nextID + 1
  return self.nextID
end

function ItemSlot:Free()
	self:Hide()
	self:SetParent(nil)
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	self.depositSlot = nil
	tinsert(self.unused, self)
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

function ItemSlot:FLASH_SEARCH_UPDATE(event, search)
	self.Flash:Stop()

	if ItemSearch:Matches(self:GetItem(), search) then
		self.Flash:Play()
	end
end

function ItemSlot:BAG_SEARCH_UPDATE(event, frameID)
	if self:GetFrameID() == frameID then
		self:UpdateBagSearch()
	end
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

function ItemSlot:QUEST_LOG_CHANGED()
	self:UpdateBorder()
end

function ItemSlot:EQUIPMENT_SETS_CHANGED()
	self:UpdateBorder()
end

function ItemSlot:ITEM_HIGHLIGHT_UPDATE()
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
	if self.hasStackSplit == 1 then
		StackSplitFrame:Hide()
	end

	if self:IsNew() then
		C_NewItems.RemoveNewItem(self:GetBag(), self:GetID())
	end
end

function ItemSlot:OnDragStart()
	ItemSlot.Cursor = self
end

function ItemSlot:OnPreClick(button)
	if button == 'RightButton' then 
		if Addon.BagEvents.atBank and IsReagentBankUnlocked() then
			return UseContainerItem(self:GetBag(), self:GetID(), nil, true)
		end

		if not self.canDeposit then
			for i = 1,9 do
				if not GetVoidTransferDepositInfo(i) then
					self.depositSlot = i
					return
				end
			end
		end
	end
end

function ItemSlot:OnClick(button)
	if IsAltKeyDown() and button == 'LeftButton' then
		Addon.Settings:FlashFind(self:GetItem())
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
	ResetCursor()

	if self:IsCached() then
		local dummy = self:GetDummySlot()
		dummy:SetParent(self)
		dummy:SetAllPoints(self)
		dummy:Show()
	elseif self:GetItem() then
		self:AnchorTooltip()
		self:ShowTooltip()
		self:UpdateBorder()
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

function ItemSlot:Set(parent, bag, slot)
  	self:SetParent(self:GetDummyBag(parent, bag))
  	self:SetID(slot)
  	self.bag = bag
	self:Update()
	self:Show()
end

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
	self:UpdateBorder()
	self:UpdateCooldown()
	self:UpdateSlotColor()
	self:UpdateSearch()
	self:UpdateBagSearch()

	if GameTooltip:IsOwned(self) then
		self:UpdateTooltip()
	end
end

function ItemSlot:SetItem(item)
	self.item = item
end

function ItemSlot:GetItem()
	return self.item
end


--[[ Icon ]]--

function ItemSlot:SetTexture(texture)
	SetItemButtonTexture(self, texture or self:GetEmptyItemIcon())
end

function ItemSlot:GetEmptyItemIcon()
	if Addon.Settings:ShowingEmptyItemSlotTextures() then
		return [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
	end
end


--[[ Slot Color ]]--

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


--[[ Border Glow ]]--

function ItemSlot:UpdateBorder()
	local _,_,_, quality = self:GetInfo()
	local item = self:GetItem()
	self:HideBorder()

	if item then
		if self:HighlightNewItems() and self:IsNew() then
			if not self.flashAnim:IsPlaying() then
				self.flashAnim:Play()
				self.newitemglowAnim:SetLooping('NONE')
				self.newitemglowAnim:Play()
			end

			if self:IsPaid() then
				return self.BattlepayItemTexture:Show()
			else
				self.NewItemTexture:SetAtlas(quality and NEW_ITEM_ATLAS_BY_QUALITY[quality] or 'bags-glow-white')
				self.NewItemTexture:Show()
				return
			end
		end

		if self:HighlightQuestItems() then
			local isQuestItem, isQuestStarter = self:IsQuestItem()
			if isQuestItem then
				return self:SetBorderColor(1, .82, .2)
			end

			if isQuestStarter then
				self.QuestBorder:SetTexture(TEXTURE_ITEM_QUEST_BANG)
				self.QuestBorder:Show()
				return
			end
		end

		if self:HighlightUnusableItems() and Unfit:IsItemUnusable(item) then
			return self:SetBorderColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		end

		if self:HighlightItemsByQuality() and quality and quality > 1 then
			self:SetBorderColor(GetItemQualityColor(quality))
		end
	end
end

function ItemSlot:SetBorderColor(r, g, b)
	self.Border:SetVertexColor(r, g, b, self:GetHighlightAlpha())
	self.Border:Show()
end

function ItemSlot:HideBorder()
	self.QuestBorder:Hide()
	self.Border:Hide()
	self.NewItemTexture:Hide()
	self.BattlepayItemTexture:Hide()
end


--[[ Misk ]]--

function ItemSlot:UpdateCooldown()
	if self:GetItem() and (not self:IsCached()) then
		ContainerFrame_UpdateCooldown(self:GetBag(), self)
	else
		CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0)
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	end
end


--[[ Tooltip ]]--

function ItemSlot:UpdateTooltip()
	self:OnEnter()
end

function ItemSlot:AnchorTooltip()
	if self:GetRight() >= (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
end

function ItemSlot:ShowTooltip()
	local bag = self:GetBag()
	local getSlot = Addon:IsBank(bag) and BankButtonIDToInvSlotID or Addon:IsReagents(bag) and ReagentBankButtonIDToInvSlotID
	
	if getSlot then
		GameTooltip:SetInventoryItem('player', getSlot(self:GetID()))
		GameTooltip:Show()
		CursorUpdate(self)
	else
		ContainerFrameItemButton_OnEnter(self)
	end	
end


--[[ Search ]]--

function ItemSlot:UpdateSearch()
	local search = self:GetItemSearch()
	local matches = search == '' or ItemSearch:Matches(self:GetItem(), search)

	if matches then
		self:SetAlpha(1)
		self:UpdateLocked()
		self:UpdateSlotColor()
		self:UpdateBorder()
	else	
		SetItemButtonDesaturated(self, true)
		self:SetAlpha(0.4)
		self:HideBorder()
	end
end

function ItemSlot:GetItemSearch()
	return Addon.Settings:GetTextSearch()
end

function ItemSlot:UpdateBagSearch()
	self:SetHighlight(self:GetBag() == self:GetBagSearch())
end

function ItemSlot:SetHighlight(enable)
	if enable then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end
function ItemSlot:GetBagSearch()
	return self:GetSettings():GetBagSearch()
end


--[[ Options ]]--

function ItemSlot:CanReuseBlizzardBagSlots()
	return Addon.Settings:AreAllFramesEnabled() and not Addon.Settings:IsBlizzardBagPassThroughEnabled()
end

function ItemSlot:HighlightItemsByQuality()
	return Addon.Settings:HighlightItemsByQuality()
end

function ItemSlot:HighlightNewItems()
	return Addon.Settings:HighlightNewItems()
end

function ItemSlot:HighlightUnusableItems()
	return Addon.Settings:HighlightUnusableItems()
end

function ItemSlot:HighlightQuestItems()
	return Addon.Settings:HighlightQuestItems()
end

function ItemSlot:HighlightSetItems()
	return Addon.Settings:HighlightSetItems()
end

function ItemSlot:GetHighlightAlpha()
	return Addon.Settings:GetHighlightOpacity()
end

function ItemSlot:ColoringBagSlots()
	return Addon.Settings:ColoringBagSlots()
end

function ItemSlot:GetBagColor(bagType)
	return Addon.Settings:GetItemSlotColor(bagType)
end

function ItemSlot:GetSettings()
	return Addon.FrameSettings:Get(self:GetFrameID())
end


--[[ Accessor Methods ]]--

function ItemSlot:IsQuestItem()
	local item = self:GetItem()
	if not item then
		return false
	end

	if self:IsCached() then
		return ItemSearch:Matches(item, QuestSearch), false
	else
		local isQuestItem, questID, isActive = GetContainerItemQuestInfo(self:GetBag(), self:GetID())
		return isQuestItem, (questID and not isActive)
	end
end

function ItemSlot:IsSlot(bag, slot)
	return self:GetBag() == bag and self:GetID() == slot
end

function ItemSlot:GetBagType()
	return Addon:GetBagType(self:GetPlayer(), self:GetBag())
end

function ItemSlot:GetBag()
	return self.bag
end

function ItemSlot:IsNew()
	return C_NewItems.IsNewItem(self:GetBag(), self:GetID())
end

function ItemSlot:IsPaid()
	return IsBattlePayItem(self:GetBag(), self:GetID())
end

function ItemSlot:IsCached()
	return select(8, self:GetInfo())
end

function ItemSlot:GetInfo()
	return Cache:GetItemInfo(self:GetPlayer(), self:GetBag(), self:GetID())
end

function ItemSlot:GetPlayer()
	return self:GetParent():GetParent():GetPlayer()
end

function ItemSlot:GetFrameID()
	return self:GetParent():GetParent().frameID
end


--[[ Dummies ]]--

function ItemSlot:GetDummyBag(parent, bag)
	parent.dummyBags = parent.dummyBags or {}

	if not parent.dummyBags[bag] then
		parent.dummyBags[bag] = CreateFrame('Frame', nil, parent)
		parent.dummyBags[bag]:SetID(tonumber(bag) or 1)
	end

	return parent.dummyBags[bag]
end

function ItemSlot:GetDummySlot()
	self.dummySlot = self.dummySlot or self:CreateDummySlot()
	self.dummySlot:Hide()
	return self.dummySlot
end

function ItemSlot:CreateDummySlot()
	local slot = CreateFrame('Button')
	slot:RegisterForClicks('anyUp')
	slot:SetToplevel(true)

	local function Slot_OnEnter(self)
		local parent = self:GetParent()
		local item = parent:IsCached() and parent:GetItem()
		
		if item then
			parent.AnchorTooltip(self)
			
			if item:find('battlepet:') then
				local _, specie, level, quality, health, power, speed = strsplit(':', item)
				local name = item:match('%[(.-)%]')
				
				BattlePetToolTip_Show(tonumber(specie), level, tonumber(quality), health, power, speed, name)
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