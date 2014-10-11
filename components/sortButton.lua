--[[
	sortButton.lua
		Sorting options button
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local SortButton = Addon:NewClass('SortButton', 'CheckButton')

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)
local FIRST_FLAG, LAST_FLAG = LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, NUM_LE_BAG_FILTER_FLAGS


--[[ Constructor ]]--

function SortButton:New(parent)
	local b = self:Bind(CreateFrame('CheckButton', nil, parent))
	b:RegisterForClicks('anyUp')
	b:SetSize(SIZE, SIZE)

	local nt = b:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetSize(NORMAL_TEXTURE_SIZE, NORMAL_TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)
	b:SetNormalTexture(nt)

	local pt = b:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(b)
	b:SetPushedTexture(pt)

	local ht = b:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(b)
	b:SetHighlightTexture(ht)

	local icon = b:CreateTexture()
	icon:SetTexture([[Interface\Icons\ACHIEVEMENT_GUILDPERK_QUICK AND DEAD]])
	icon:SetAllPoints(b)
	--icon:SetAtlas('bags-button-autosort-up')

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)

	return b
end


--[[ Frame Events ]]--

function SortButton:OnClick()
	local frameID = self:GetParent():GetFrameID()

	-- Override blizz settings
	SetSortBagsRightToLeft(true)
	SetBackpackAutosortDisabled(false)
	SetBankAutosortDisabled(false)

	for i, slot in Addon.FrameSettings:Get(frameID):GetBagSlots() do
		if slot > NUM_BAG_SLOTS then
			slot = slot - NUM_BAG_SLOTS

			for flag = FIRST_FLAG, LAST_FLAG do
				if GetBankBagSlotFlag(slot, flag) then
					SetBankBagSlotFlag(slot, flag, false)
				end
			end
		elseif slot > 0 then
			for flag = FIRST_FLAG, LAST_FLAG do
				if GetBagSlotFlag(slot, flag) then
					SetBagSlotFlag(slot, flag, false)
				end
			end
		end
	end

	-- Sort
	if frameID == 'bank' then
		SortReagentBankBags()
		SortBankBags()
	else
		SortBags()
	end
end

function SortButton:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	
	GameTooltip:SetText(L.TipSortItems)
end

function SortButton:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end