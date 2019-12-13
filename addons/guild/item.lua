--[[
	item.lua
		A guild item slot button
--]]

local MODULE =  ...
local ADDON, Addon = MODULE:match('[^_]+'), _G[MODULE:match('[^_]+')]
local Item = Addon.Item:NewClass('GuildItem')


--[[ Construct ]]--

function Item:Construct()
	local item = self:Super(Item):Construct()
	item:SetScript('OnReceiveDrag', self.OnReceiveDrag)
	item:SetScript('OnDragStart', self.OnDragStart)
	item:SetScript('OnClick', self.OnClick)
	item:RegisterForDrag('LeftButton')
	item:RegisterForClicks('anyUp')
	item.SplitStack = nil -- template onload screws this up
	return item
end

function Item:GetBlizzard()
end


--[[ Events ]]--

function Item:OnClick(button)
	if HandleModifiedItemClick(self.info.link) or self:IsCached() then
		return
	end

	if IsModifiedClick('SPLITSTACK') then
		if not CursorHasItem() and not self.info.locked and self.info.count > 1 then
			StackSplitFrame:OpenStackSplitFrame(self.info.count, self, 'BOTTOMLEFT', 'TOPLEFT')
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
	elseif button == 'RightButton' then
		AutoStoreGuildBankItem(self:GetSlot())
	else
		PickupGuildBankItem(self:GetSlot())
	end
end

function Item:OnDragStart(button)
	if not self:IsCached() then
		PickupGuildBankItem(self:GetSlot())
	end
end

function Item:OnReceiveDrag(button)
	if not self:IsCached() then
		PickupGuildBankItem(self:GetSlot())
	end
end


--[[ Update ]]--

function Item:ShowTooltip()
	GameTooltip:SetOwner(self:GetTipAnchor())

	local pet = {GameTooltip:SetGuildBankItem(self:GetSlot())}
	if pet[1] and pet[1] > 0 then
		BattlePetToolTip_Show(unpack(pet))
	end

	GameTooltip:Show()
	CursorUpdate(self)
end

function Item:SplitStack(split)
	local tab, slot = self:GetSlot()
	SplitGuildBankItem(tab, slot, split)
end

function Item:UpdateCooldown() end


--[[ Accessors ]]--

function Item:GetSlot()
	return self:GetBag(), self:GetID()
end

function Item:GetBag()
	return GetCurrentGuildBankTab()
end

function Item:IsQuestItem() end
function Item:IsNew() end
function Item:IsPaid() end
