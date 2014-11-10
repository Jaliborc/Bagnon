--[[
	bag.lua
		A bag button object
--]]

local ADDON, Addon = ...
local Addon = LibStub('AceAddon-3.0'):GetAddon(ADDON)
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Bag = Addon:NewClass('Bag', 'CheckButton')

Bag.SIZE = 32
Bag.TEXTURE_SIZE = 64 * (Bag.SIZE/36)
Bag.GetSlot = Bag.GetID


--[[ Constructor ]]--

function Bag:New(parent, id)
	local bag = self:Bind(CreateFrame('CheckButton', ADDON .. self.Name .. id, parent))
	
	local icon = bag:CreateTexture(bag:GetName() .. 'IconTexture', 'BORDER')
	icon:SetAllPoints(bag)

	local count = bag:CreateFontString(nil, 'OVERLAY')
	count:SetFontObject('NumberFontNormal')
	count:SetPoint('BOTTOM', 2, 3)
	count:SetJustifyH('RIGHT')

	local filter = CreateFrame('Frame', nil, bag)
	filter:SetPoint('TOPRIGHT', 4, 4)
	filter:SetSize(20, 20)

	local filterIcon = filter:CreateTexture()
	filterIcon:SetAllPoints()

	local nt = bag:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(self.TEXTURE_SIZE)
	nt:SetHeight(self.TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)

	local pt = bag:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints()

	local ht = bag:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints()

	local ct = bag:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetBlendMode('ADD')
	ct:SetAllPoints()

	bag:SetID(id)
	bag:SetNormalTexture(nt)
	bag:SetPushedTexture(pt)
	bag:SetCheckedTexture(ct)
	bag:SetHighlightTexture(ht)
	bag:RegisterForClicks('anyUp')
	bag:RegisterForDrag('LeftButton')
	bag:SetSize(self.SIZE, self.SIZE)
	bag.Count, bag.FilterIcon = count, filter
	bag.FilterIcon.Icon = filterIcon

	bag:SetScript('OnEnter', bag.OnEnter)
	bag:SetScript('OnLeave', bag.OnLeave)
	bag:SetScript('OnClick', bag.OnClick)
	bag:SetScript('OnDragStart', bag.OnDrag)
	bag:SetScript('OnReceiveDrag', bag.OnClick)
	bag:SetScript('OnEvent', bag.OnEvent)
	bag:SetScript('OnShow', bag.OnShow)
	bag:SetScript('OnHide', bag.OnHide)

	return bag
end


--[[ Events ]]--

function Bag:OnEvent(event, ...)
	local action = self[event]
	if action then
		action(self, event, ...)
	end
end

function Bag:UpdateEvents()
	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	self:UnregisterAllItemSlotEvents()

	if self:IsVisible() then
		self:RegisterMessage('BAG_SLOT_SHOW')
		self:RegisterMessage('BAG_SLOT_HIDE')
		self:RegisterMessage('BAG_DISABLE_UPDATE')
		self:RegisterMessage('PLAYER_UPDATE')
		self:RegisterEvent('BAG_UPDATE')

		if self:IsCustomSlot() then
			if not self:IsCached() then
				self:RegisterEvent('PLAYERBANKSLOTS_UPDATED')
				self:RegisterEvent('ITEM_LOCK_CHANGED')
				self:RegisterEvent('CURSOR_UPDATE')
			else
				self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
			end

			if self:IsBankBag() then
				self:RegisterItemSlotEvent('BANK_OPENED')
				self:RegisterItemSlotEvent('BANK_CLOSED')
				self:RegisterEvent('PLAYERBANKBAGSLOTS_UPDATED')
			end
		elseif self:IsReagents() then
			self:RegisterEvent('REAGENTBANK_PURCHASED')
		end
	end
end

function Bag:RegisterItemSlotEvent(...)
	Addon.BagEvents.Listen(self, ...)
end

function Bag:UnregisterAllItemSlotEvents(...)
	Addon.BagEvents.IgnoreAll(self, ...)
end


--[[ Messages ]]--

function Bag:ITEM_LOCK_CHANGED(event, inventorySlot)
	if self:GetInventorySlot() == inventorySlot then
		self:UpdateLock()
	end
end

function Bag:CURSOR_UPDATE()
	self:UpdateCursor()
end

function Bag:BAG_UPDATE(event, bag)
	self:UpdateLock()
	self:UpdateSlot()
  	self:UpdateToggle()
end

function Bag:PLAYER_UPDATE(msg, frameID, player)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end

function Bag:GET_ITEM_INFO_RECEIVED()
	self:UpdateSlot()
end

do
	local function updateSlot(self)
		self:UpdateLock()
		self:UpdateSlot()
	end
	
	Bag.PLAYERBANKSLOTS_UPDATED = updateSlot
	Bag.PLAYERBANKBAGSLOTS_UPDATED = updateSlot
	Bag.BANK_OPENED = updateSlot
	Bag.BANK_CLOSED = updateSlot
end

function Bag:BAG_DISABLE_UPDATE()
	self:UpdateToggle()
end

do
	local function updateToggle(self) 
		if frameID == self:GetFrameID() and slot == self:GetSlot() then
			self:UpdateToggle()
		end
	end
	
	Bag.BAG_SLOT_SHOW = updateToggle
	Bag.BAG_SLOT_HIDE = updateToggle
end


--[[ Frame Events ]]--

function Bag:OnShow()
	self:UpdateEverything()
end

function Bag:OnHide()
	self:UpdateEvents()
end

function Bag:OnClick(button)
	if button == 'RightButton' then
		if not self:IsCached() and not self:IsReagents() and not self:IsPurchasable() then
			ContainerFrame1FilterDropDown:SetParent(self)
			PlaySound('igMainMenuOptionCheckBoxOn')
			ToggleDropDownMenu(1, nil, ContainerFrame1FilterDropDown, self, 0, 0)
		end
	else
		if self:IsPurchasable() then
			self:Purchase()
		elseif CursorHasItem() and not self:IsCached() then
			if self:IsBackpack() then
				PutItemInBackpack()
			else
				PutItemInBag(self:GetInventorySlot())
			end
		elseif self:CanToggle() then
			self:Toggle()
		end
	end

	self:UpdateToggle()
end

function Bag:OnDrag()
	if self:IsCustomSlot() and not self:IsCached() then
		PlaySound('BAGMENUBUTTONPRESS')
		PickupBagFromSlot(self:GetInventorySlot())
	end
end

function Bag:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	self:UpdateTooltip()
	self:SetSearch()
end

function Bag:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
	self:ClearSearch()
end


--[[ Update ]]--

function Bag:UpdateEverything()
	self:UpdateEvents()
	self:Update()
end

function Bag:Update()
	if not self:IsVisible() then
    	return
  	end

  	if self:IsBackpack() or self:IsBank() then
		self:SetIcon('Interface/Buttons/Button-Backpack-Up')
	elseif self:IsReagents() then
		self:SetIcon('Interface/Icons/Achievement_GuildPerk_BountifulBags')
	end

	local filterIndex = self:GetFilterIndex()

	self.FilterIcon.Icon:SetAtlas(BAG_FILTER_ICONS[filterIndex])
	self.FilterIcon:SetShown(filterIndex and not self:IsCached())
	self:UpdateSlot()
	self:UpdateLock()
	self:UpdateCursor()
	self:UpdateToggle()
end

function Bag:UpdateSlot()
	local link, count, texture = self:GetInfo()

	if self:IsCustomSlot() then
		self:SetIcon(texture or link and GetItemIcon(link) or 'Interface/PaperDoll/UI-PaperDoll-Slot-Bag')
	  	self.link = link
	end

	self.Count:SetText(not self:IsPurchasable() and count > 0 and count)
end

function Bag:UpdateLock()
	if self:IsCustomSlot() then
    	SetItemButtonDesaturated(self, self:IsLocked())
 	end
end

function Bag:UpdateCursor()
	if not self:IsCustomSlot() then
     	return
  	end

	if CursorCanGoInSlot(self:GetInventorySlot()) then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function Bag:UpdateTooltip()
	GameTooltip:ClearLines()

	-- title
	if self:IsPurchasable() then
		GameTooltip:SetText(self:IsReagents() and REAGENT_BANK or BANK_BAG_PURCHASE, 1, 1, 1)
		GameTooltip:AddLine(L.PurchaseBag)
		SetTooltipMoney(GameTooltip, self:GetCost())
	elseif self:IsBackpack() then
		GameTooltip:SetText(BACKPACK_TOOLTIP, 1,1,1)
	elseif self:IsBank() then
		GameTooltip:SetText(BANK, 1,1,1)
	elseif self:IsReagents() then
		GameTooltip:SetText(REAGENT_BANK, 1,1,1)
	elseif self.link then
		GameTooltip:SetHyperlink(self.link)
	elseif self:IsBankBag() then
		GameTooltip:SetText(BANK_BAG, 1, 1, 1)
	else
		GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
	end

	-- instructions
	if self:CanToggle() then
		GameTooltip:AddLine(self:IsToggled() and L.TipHideBag or L.TipShowBag)
	end

	GameTooltip:Show()
end


--[[ Display ]]--

function Bag:SetIcon(icon)
	local color = self:IsPurchasable() and .1 or 1

	SetItemButtonTexture(self, icon)
	SetItemButtonTextureVertexColor(self, 1, color, color)
end


--[[ Actions ]]--

function Bag:Purchase()
	PlaySound('igMainMenuOption')

	if self:IsReagents() then
		StaticPopup_Show('CONFIRM_BUY_REAGENTBANK_TAB')
	else
		if not StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_' .. ADDON] then
			StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_' .. ADDON] = {
				text = CONFIRM_BUY_BANK_SLOT,
				button1 = YES,
				button2 = NO,
				OnAccept = PurchaseSlot,
				OnShow = function(self)
					MoneyFrame_Update(self.moneyFrame, GetBankSlotCost(GetNumBankSlots()))
				end,
				hasMoneyFrame = 1,
				hideOnEscape = 1, timeout = 0,
				preferredIndex = STATICPOPUP_NUMDIALOGS
			}
		end

		StaticPopup_Show('CONFIRM_BUY_BANK_SLOT_' .. ADDON)
	end
end

function Bag:Toggle()
	self:GetSettings():ToggleBagSlot(self:GetSlot())
end

function Bag:UpdateToggle()
	self:SetChecked(self:IsToggled())
end

function Bag:CanToggle()
	if Addon.Settings:CanDisableBags() then
		return self:IsBackpack() or self:IsBank() or not self:IsPurchasable()
	end
end

function Bag:IsToggled()
	return self:CanToggle() and self:GetSettings():IsBagSlotShown(self:GetSlot())
end

function Bag:SetSearch()
	self:GetSettings():SetBagSearch(self:GetSlot())
end

function Bag:ClearSearch()
	if self:GetSearch() == self:GetSlot() then
		self:GetSettings():SetBagSearch(false)
	end
end

function Bag:GetSearch()
	return self:GetSettings():GetBagSearch()
end


--[[ Bag Type ]]--

function Bag:IsBackpack()
	return Addon:IsBackpack(self:GetSlot())
end

function Bag:IsBackpackBag()
  return Addon:IsBackpackBag(self:GetSlot())
end

function Bag:IsBank()
	return Addon:IsBank(self:GetSlot())
end

function Bag:IsReagents()
	return Addon:IsReagents(self:GetSlot())
end

function Bag:IsBankBag()
	return Addon:IsBankBag(self:GetSlot())
end

function Bag:IsCustomSlot()
	return self:IsBackpackBag() or self:IsBankBag()
end


--[[ Info ]]--

function Bag:GetInfo()
	return Addon:GetBagInfo(self:GetPlayer(), self:GetSlot())
end

function Bag:GetInventorySlot()
	return Addon:BagToInventorySlot(self:GetPlayer(), self:GetSlot())
end

function Bag:GetCost()
	return self:IsReagents() and GetReagentBankCost() or GetBankSlotCost(GetNumBankSlots())
end

function Bag:IsPurchasable()
	if not self:IsCached() then
		return self:IsBankBag() and (self:GetSlot() - NUM_BAG_SLOTS) > GetNumBankSlots() or self:IsReagents() and not IsReagentBankUnlocked()
	end
end

function Bag:IsLocked()
	return Addon:IsBagLocked(self:GetPlayer(), self:GetSlot())
end

function Bag:IsCached()
 	return Addon:IsBagCached(self:GetPlayer(), self:GetSlot())
end

function Bag:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function Bag:GetSettings()
	return Addon.FrameSettings:Get(self:GetFrameID())
end

function Bag:GetFrameID()
	return self:GetParent():GetFrameID()
end

function Bag:GetFilterIndex()
	local id = self:GetSlot()

	for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
		local active = id > NUM_BAG_SLOTS and GetBankBagSlotFlag(id - NUM_BAG_SLOTS, i) or GetBagSlotFlag(id, i)

		if active then
			return i
		end
	end
end
