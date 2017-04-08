--[[
	sortButton.lua
		Sorting options button
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local SortButton = Addon:NewClass('SortButton', 'Button')

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function SortButton:New(parent)
	local b = self:Bind(CreateFrame('Button', nil, parent))
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
	icon:SetTexture([[Interface\Icons\Achievement_GuildPerk_Quick and Dead]])
	icon:SetAllPoints(b)

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)

	return b
end


--[[ Interaction ]]--

function SortButton:OnClick(button)
	local isBank = self:GetParent():IsBank()

	if button == 'RightButton' then
		if isBank then
			SortReagentBankBags()
			SortBankBags()
		end
	elseif isBank then
		DepositReagentBank()
	else
		SortBags()
	end
end

function SortButton:OnEnter()
	GameTooltip:SetOwner(self, self:GetRight() > (GetScreenWidth() / 2) and 'ANCHOR_LEFT' or 'ANCHOR_RIGHT')
	
	if self:GetParent():IsBank() then
		GameTooltip:SetText(L.TipManageBank)
		GameTooltip:AddLine(L.TipDepositReagents, 1,1,1)
		GameTooltip:AddLine(L.TipCleanBank, 1,1,1)
	else
		GameTooltip:SetText(L.TipCleanBags)
	end

	GameTooltip:Show()
end

function SortButton:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end