--[[
	bag.lua
		A bag button object for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local Bag = Bagnon:NewClass('Bag', 'CheckButton')

Bag.SIZE = 32
Bag.TEXTURE_SIZE = 64 * (Bag.SIZE/36)
Bag.count = 0


--[[ Constructor ]]--

function Bag:New(id, frame, parent)
	local bag = self:Create(parent)
	bag:SetTarget(frame, id)

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

function Bag:Create(parent)
	local bag = self:Bind(CreateFrame('CheckButton', 'BagnonBag' .. self:NextID(), parent))
	bag:SetSize(self.SIZE, self.SIZE)

	local name = bag:GetName()
	local icon = bag:CreateTexture(name .. 'IconTexture', 'BORDER')
	icon:SetAllPoints(bag)

	local count = bag:CreateFontString(name .. 'Count', 'OVERLAY')
	count:SetFontObject('NumberFontNormalSmall')
	count:SetJustifyH('RIGHT')
	count:SetPoint('BOTTOMRIGHT', -2, 2)

	local nt = bag:CreateTexture(name .. 'NormalTexture')
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(self.TEXTURE_SIZE)
	nt:SetHeight(self.TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)
	bag:SetNormalTexture(nt)

	local pt = bag:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(bag)
	bag:SetPushedTexture(pt)

	local ht = bag:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(bag)
	bag:SetHighlightTexture(ht)

	local ct = bag:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetAllPoints(bag)
	ct:SetBlendMode('ADD')
	bag:SetCheckedTexture(ct)

	if bag:IsBackpack() or bag:IsBank() then
		SetItemButtonTexture(bag, [[Interface\Buttons\Button-Backpack-Up]])
		SetItemButtonTextureVertexColor(bag, 1, 1, 1)
	end

	bag:RegisterForClicks('anyUp')
	bag:RegisterForDrag('LeftButton')

	return bag
end

function Bag:NextID()
	local id = self.count + 1
	self.count = id
	return id
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

		if self:IsCustomSlot() then
			self:RegisterMessage('PLAYER_UPDATE')

			if not self:IsCached() then
				self:RegisterEvent('ITEM_LOCK_CHANGED')
				self:RegisterEvent('CURSOR_UPDATE')
				self:RegisterEvent('BAG_UPDATE')
				self:RegisterEvent('PLAYERBANKSLOTS_UPDATED')
				self:RegisterEvent('PLAYERBANKBAGSLOTS_UPDATED')
			else
				self:RegisterEvent('GET_ITEM_INFO_RECEIVED')
			end
		end

		if self:IsBankBagSlot() then
			self:RegisterItemSlotEvent('BANK_OPENED')
			self:RegisterItemSlotEvent('BANK_CLOSED')
		end
	end
end

--event registration
function Bag:RegisterItemSlotEvent(...)
	Bagnon.BagEvents.Listen(self, ...)
end

function Bag:UnregisterAllItemSlotEvents(...)
	Bagnon.BagEvents.IgnoreAll(self, ...)
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
	self:UpdateSlotInfo()
  	self:UpdateToggle()
end

function Bag:PLAYER_UPDATE(msg, frameID, player)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end

function Bag:GET_ITEM_INFO_RECEIVED()
	self:UpdateSlotInfo()
end

do
	local function updateSlot(self)
		self:UpdateLock()
		self:UpdateSlotInfo()
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

function Bag:OnClick()
	if self:IsPurchasable() then
		self:PurchaseSlot()
	elseif CursorHasItem() and not self:IsCached() then
		if self:IsBackpack() then
			PutItemInBackpack()
		else
			PutItemInBag(self:GetInventorySlot())
		end
	elseif self:CanToggleSlot() then
		self:ToggleSlot()
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


--[[ Tooltip Methods ]]--

function Bag:UpdateTooltip()
	GameTooltip:ClearLines()

	if self:IsBackpack() then
		GameTooltip:SetText(BACKPACK_TOOLTIP, 1, 1, 1)
	elseif self:IsBank() then
		GameTooltip:SetText(L.TipBank, 1, 1, 1)
	elseif self:IsCached() then
		self:UpdateCachedBagTooltip()
	else
		self:UpdateBagTooltip()
	end

	if self:CanToggleSlot() then
		GameTooltip:AddLine(self:IsSlotShown() and L.TipHideBag or L.TipShowBag)
	end

	GameTooltip:Show()
end

function Bag:UpdateCachedBagTooltip()
	if self.link then
		GameTooltip:SetHyperlink(self.link)
	elseif self:IsPurchasable() then
		GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
	elseif self:IsBankBagSlot() then
		GameTooltip:SetText(BANK_BAG, 1, 1, 1)
	else
		GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
	end
end

function Bag:UpdateBagTooltip()
	if not GameTooltip:SetInventoryItem('player', self:GetInventorySlot()) then
		if self:IsPurchasable() then
			GameTooltip:SetText(BANK_BAG_PURCHASE, 1, 1, 1)
			GameTooltip:AddLine(L.TipPurchaseBag)
			SetTooltipMoney(GameTooltip, GetBankSlotCost(GetNumBankSlots()))
		else
			GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
		end
	end
end


--[[ Display Updating ]]--

function Bag:UpdateEverything()
	self:UpdateEvents()
	self:Update()
end

function Bag:Update()
	if not self:IsVisible() then
    return
  end

	self:UpdateLock()
	self:UpdateSlotInfo()
	self:UpdateCursor()
	self:UpdateToggle()
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

function Bag:UpdateSlotInfo()
	if not self:IsCustomSlot() then
    return
  end

	local link, count, texture = self:GetInfo()
	if link then
		SetItemButtonTexture(self, texture or GetItemIcon(link))
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	else
		SetItemButtonTexture(self, [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]])

		--color red if the bag can be purchased
		if self:IsPurchasable() then
			SetItemButtonTextureVertexColor(self, 1, 0.1, 0.1)
		else
			SetItemButtonTextureVertexColor(self, 1, 1, 1)
		end
	end

	self:SetCount(count)
  	self.link = link
end

function Bag:SetCount(count)
	local text = _G[self:GetName() .. 'Count']
	local count = count or 0

	if count > 1 then
		if count > 999 then
			text:SetFormattedText('%.1fk', count/1000)
		else
			text:SetText(count)
		end
		text:Show()
	else
		text:Hide()
	end
end


--[[ Bag Slot Actions ]]--

--show the purchase slot dialog
function Bag:PurchaseSlot()
	if not StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_BAGNON'] then
		StaticPopupDialogs['CONFIRM_BUY_BANK_SLOT_BAGNON'] = {
			text = CONFIRM_BUY_BANK_SLOT,
			button1 = YES,
			button2 = NO,
			OnAccept = PurchaseSlot,

			OnShow = function(self)
				MoneyFrame_Update(self:GetName() .. 'MoneyFrame', GetBankSlotCost(GetNumBankSlots()))
			end,

			hasMoneyFrame = 1,
			hideOnEscape = 1, timeout = 0,
			preferredIndex = STATICPOPUP_NUMDIALOGS
		}
	end

  	PlaySound('igMainMenuOption')
	StaticPopup_Show('CONFIRM_BUY_BANK_SLOT_BAGNON')
end


--item viewing
function Bag:ToggleSlot()
	self:GetSettings():ToggleBagSlot(self:GetSlot())
end

function Bag:UpdateToggle()
	self:SetChecked(self:IsSlotShown())
end

function Bag:IsSlotShown()
	return self:CanToggleSlot() and self:GetSettings():IsBagSlotShown(self:GetSlot())
end

function Bag:CanToggleSlot()
	if Bagnon.Settings:CanDisableBags() then
		return self:IsBank() or self:IsBackpack() or (self:IsCustomSlot() and self.link)
	end
end


--searching
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


--[[ Bag Type Functions ]]--

function Bag:IsBackpack()
	return Bagnon:IsBackpack(self:GetSlot())
end

function Bag:IsBackpackBag()
  return Bagnon:IsBackpackBag(self:GetSlot())
end

function Bag:IsBank()
	return Bagnon:IsBank(self:GetSlot())
end

function Bag:IsBankBagSlot()
	return Bagnon:IsBankBag(self:GetSlot())
end

function Bag:IsCustomSlot()
	return self:IsBackpackBag() or self:IsBankBagSlot()
end


--[[ Bag Info Functions ]]--

function Bag:GetInfo()
  return Bagnon:GetBagInfo(self:GetPlayer(), self:GetSlot())
end

function Bag:GetInventorySlot()
  return Bagnon:BagToInventorySlot(self:GetPlayer(), self:GetSlot())
end


--[[ Bag State Functions ]]--

function Bag:IsPurchasable()
	return Bagnon:IsBagPurchasable(self:GetPlayer(), self:GetSlot())
end

function Bag:IsLocked()
	return Bagnon:IsBagLocked(self:GetPlayer(), self:GetSlot())
end

function Bag:IsCached()
  return Bagnon:IsBagCached(self:GetPlayer(), self:GetSlot())
end

function Bag:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function Bag:GetSlot()
	return self:GetID()
end


--[[ Usual Acessor Functions ]]--

function Bag:SetTarget(frame, id)
	if self:GetFrameID() ~= frame or self:GetID() ~= id then
		self.frameID = frame
		self:SetID(id)
		self:UpdateEverything()
	end
end

function Bag:GetFrameID()
	return self.frameID
end

function Bag:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end