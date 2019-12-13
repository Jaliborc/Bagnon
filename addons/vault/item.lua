--[[
	item.lua
		A void storage item slot button
--]]

local MODULE =  ...
local ADDON, Addon = MODULE:match('[^_]+'), _G[MODULE:match('[^_]+')]
local Item = Addon.Item:NewClass('VaultItem')


--[[ Construct ]]--

function Item:Construct()
	local b = self:Super(Item):Construct()
	b:SetScript('OnReceiveDrag', self.OnDragStart)
	b:SetScript('OnDragStart', self.OnDragStart)
	b:SetScript('OnClick', self.OnClick)
	return b
end

function Item:GetBlizzard()
end


--[[ Interaction ]]--

function Item:OnClick(button)
	if IsModifiedClick() then
		if self.info.link then
			HandleModifiedItemClick(self.info.link)
		end
	elseif self.bag == 'vault' and not self:IsCached() then
		local isRight = button == 'RightButton'
		local type, _, link = GetCursorInfo()
		local cursor = self.Cursor

		if not isRight and cursor and type == 'item' and link == cursor:GetItem() then
			cursor:GetScript('PreClick')(cursor, 'RightButton') -- simulates a click on the button, less code to maintain
			cursor:GetScript('OnClick')(cursor, 'RightButton')

		elseif isRight and self.info.locked then
			for i = 1,9 do
				if GetVoidTransferWithdrawalInfo(i) == self.info.id then
						ClickVoidTransferWithdrawalSlot(i, true)
				end
			end
		else
			ClickVoidStorageSlot(1, self:GetID(), isRight)
		end
	end
end

function Item:OnDragStart()
	self:OnClick('LeftButton')
end


--[[ Tooltip ]]--

function Item:ShowTooltip()
	GameTooltip:SetOwner(self:GetTipAnchor())

	if self.bag == 'vault' then
		GameTooltip:SetVoidItem(1, self:GetID())
	elseif self.bag == DEPOSIT then
		GameTooltip:SetVoidDepositItem(self:GetID())
	else
		GameTooltip:SetVoidWithdrawalItem(self:GetID())
	end

	GameTooltip:Show()
	CursorUpdate(self)

	if IsModifiedClick('DRESSUP') then
		ShowInspectCursor()
	end
end


--[[ Proprieties ]]--

function Item:IsCached()
	-- delicious hack: behave as cached (disable interaction) while vault has not been purchased
	return not CanUseVoidStorage() or self:Super(Item):IsCached()
end

function Item:IsQuestItem() end
function Item:IsNew() end
function Item:IsPaid() end
function Item:IsUpgrade() end
function Item:UpdateSlotColor() end
function Item:UpdateCooldown() end
