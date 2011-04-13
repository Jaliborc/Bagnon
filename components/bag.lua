--[[
	bag.lua
		A bag button object for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local Bag = Bagnon.Classy:New('CheckButton')
Bagnon.Bag = Bag

--constants
local SIZE = 32
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function Bag:New(slotID, frameID, parent)
	local bag = Bag:CreateBag(slotID, parent)
	bag:SetFrameID(frameID)

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

function Bag:CreateBag(slotID, parent)
	local bag = self:Bind(CreateFrame('CheckButton', 'BagnonBag' .. self:GetNextBagSlotID(), parent))
	bag:SetWidth(SIZE)
	bag:SetHeight(SIZE)
	bag:SetID(slotID)

	local name = bag:GetName()
	local icon = bag:CreateTexture(name .. 'IconTexture', 'BORDER')
	icon:SetAllPoints(bag)

	local count = bag:CreateFontString(name .. 'Count', 'OVERLAY')
	count:SetFontObject('NumberFontNormalSmall')
	count:SetJustifyH('RIGHT')
	count:SetPoint('BOTTOMRIGHT', -2, 2)

	local nt = bag:CreateTexture(name .. 'NormalTexture')
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(NORMAL_TEXTURE_SIZE)
	nt:SetHeight(NORMAL_TEXTURE_SIZE)
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
	elseif bag:IsKeyRing() then
		SetItemButtonTexture(bag, [[Interface\ContainerFrame\KeyRing-Bag-Icon]])
		SetItemButtonTextureVertexColor(bag, 1, 1, 1)
		_G[bag:GetName() .. 'IconTexture']:SetTexCoord(0, 0.9, 0.1, 1)
	end

	bag:RegisterForClicks('anyUp')
	bag:RegisterForDrag('LeftButton')

	return bag
end

do
	local id = 0
	function Bag:GetNextBagSlotID()
		local nextID = id + 1
		id = nextID
		return nextID
	end
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

		if self:IsBagSlot() then
			self:RegisterMessage('PLAYER_UPDATE')

			if not self:IsCached() then
				self:RegisterEvent('ITEM_LOCK_CHANGED')
				self:RegisterEvent('CURSOR_UPDATE')
				self:RegisterEvent('BAG_UPDATE')
				self:RegisterEvent('PLAYERBANKSLOTS_UPDATED')
				self:RegisterEvent('PLAYERBANKBAGSLOTS_UPDATED')
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
	Bagnon.BagEvents:Listen(self, ...)
end

function Bag:UnregisterAllItemSlotEvents(...)
	Bagnon.BagEvents:IgnoreAll(self, ...)
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
end

function Bag:PLAYERBANKSLOTS_UPDATED(event)
	self:UpdateLock()
	self:UpdateSlotInfo()
end

function Bag:PLAYERBANKBAGSLOTS_UPDATED(event)
	self:UpdateLock()
	self:UpdateSlotInfo()
end

function Bag:BANK_OPENED(msg)
	self:UpdateLock()
	self:UpdateSlotInfo()
end

function Bag:BANK_CLOSED(msg)
	self:UpdateLock()
	self:UpdateSlotInfo()
end

function Bag:BAG_SLOT_SHOW(msg, frameID, slotID)
	if frameID == self:GetFrameID() and slotID == self:GetID() then
		self:UpdateShown()
	end
end

function Bag:BAG_SLOT_HIDE(msg, frameID, slotID)
	if frameID == self:GetFrameID() and slotID == self:GetID() then
		self:UpdateShown()
	end
end

function Bag:PLAYER_UPDATE(msg, frameID, player)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end


--[[ Frame Events ]]--

function Bag:OnShow()
	self:UpdateEverything()
end

function Bag:OnHide()
	self:UpdateEvents()
end

function Bag:OnClick()
	if self:IsPurchasable() and not self:IsCached() then
		self:PurchaseSlot()
	elseif CursorHasItem() and not self:IsCached() then
		if self:IsBackpack() then
			PutItemInBackpack()
		elseif self:IsKeyRing() then
			PutKeyInKeyRing()
		else
			PutItemInBag(self:GetInventorySlot())
		end
	elseif self:CanToggleSlot() then
		self:ToggleSlot()
	end

	self:UpdateShown()
end

function Bag:OnDrag()
	if self:IsBagSlot() and not self:IsCached() then
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
	elseif self:IsKeyRing() then
		GameTooltip:SetText(KEYRING, 1, 1, 1)
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
	local link = (self:GetItemInfo())

	if link then
		GameTooltip:SetHyperlink(link)
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
	if not self:IsVisible() then return end

	self:UpdateLock()
	self:UpdateSlotInfo()
	self:UpdateCursor()
	self:UpdateShown()
end

function Bag:UpdateLock()
	if not self:IsBagSlot() then return end

	SetItemButtonDesaturated(self, self:IsLocked())
end

function Bag:UpdateCursor()
	if not self:IsBagSlot() then return end

	if CursorCanGoInSlot(self:GetInventorySlot()) then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end
end

function Bag:UpdateSlotInfo()
	if not self:IsBagSlot() then return end

	local link, count, texture = self:GetItemInfo()
	if link then
		self.hasItem = link

		SetItemButtonTexture(self, texture or GetItemIcon(link))
		SetItemButtonTextureVertexColor(self, 1, 1, 1)
	else
		self.hasItem = nil

		SetItemButtonTexture(self, [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]])

		--color red if the bag can be purchased
		if self:IsPurchasable() then
			SetItemButtonTextureVertexColor(self, 1, 0.1, 0.1)
		else
			SetItemButtonTextureVertexColor(self, 1, 1, 1)
		end
	end
	self:SetCount(count)
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

			OnAccept = function()
				PurchaseSlot()
			end,

			OnShow = function(self)
				MoneyFrame_Update(self:GetName() .. 'MoneyFrame', GetBankSlotCost(GetNumBankSlots()))
			end,

			hasMoneyFrame = 1,
			timeout = 0,
			hideOnEscape = 1,
		}
	end

--	PlaySound('igMainMenuOption')
	StaticPopup_Show('CONFIRM_BUY_BANK_SLOT_BAGNON')
end


--item viewing
function Bag:ToggleSlot()
	self:GetSettings():ToggleBagSlot(self:GetID())
end

function Bag:UpdateShown()
	self:SetChecked(self:IsSlotShown())
end

function Bag:IsSlotShown()
	return self:CanToggleSlot() and self:GetSettings():IsBagSlotShown(self:GetID())
end

function Bag:CanToggleSlot()
	return self:IsBank() or self:IsBackpack() or self:IsKeyRing() or (self:IsBagSlot() and self.hasItem)
end


--searching
function Bag:SetSearch()
	self:GetSettings():SetBagSearch(self:GetID())
end

function Bag:ClearSearch()
	if self:GetSearch() == self:GetID() then
		self:GetSettings():SetBagSearch(false)
	end
end

function Bag:GetSearch()
	return self:GetSettings():GetBagSearch()
end


--[[ Accessor Functions ]]--

--returns true if the bag is loaded from offline data, and false otehrwise
function Bag:IsCached()
	return Bagnon.BagSlotInfo:IsCached(self:GetPlayer(), self:GetID())
end

--returns true if the given bag represents the backpack container
function Bag:IsBackpack()
	return Bagnon.BagSlotInfo:IsBackpack(self:GetID())
end

--returns true if the given bag represetns the main bank container
function Bag:IsBank()
	return Bagnon.BagSlotInfo:IsBank(self:GetID())
end

function Bag:IsKeyRing()
	return Bagnon.BagSlotInfo:IsKeyRing(self:GetID())
end

--returns true if the given bag slot is an inventory bag slot
function Bag:IsInventoryBagSlot()
	return Bagnon.BagSlotInfo:IsBackpackBag(self:GetID())
end

--returns true if the given bag slot is a purchasable bank bag slot
function Bag:IsBankBagSlot()
	return Bagnon.BagSlotInfo:IsBankBag(self:GetID())
end

--returns true if the given bagSlot is one the player can place a bag in, and false otherwise
function Bag:IsBagSlot()
	return self:IsInventoryBagSlot() or self:IsBankBagSlot()
end

--returns true if the bag is a purchasable bank slot, and false otherwise
function Bag:IsPurchasable()
	return Bagnon.BagSlotInfo:IsPurchasable(self:GetPlayer(), self:GetID())
end

--returns the inventory slot id representation of the given bag
function Bag:GetInventorySlot()
	return Bagnon.BagSlotInfo:ToInventorySlot(self:GetID())
end

function Bag:GetItemInfo()
	local link, count, texture = Bagnon.BagSlotInfo:GetItemInfo(self:GetPlayer(), self:GetID())
	return link, count, texture
end

function Bag:IsLocked()
	return Bagnon.BagSlotInfo:IsLocked(self:GetPlayer(), self:GetID())
end

--returns the currently selected player for this frame
function Bag:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

--returns the bagnon frame we're attached to
function Bag:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function Bag:GetFrameID()
	return self.frameID
end

--return the settings object associated with this frame
function Bag:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end