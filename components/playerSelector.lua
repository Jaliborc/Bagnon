--[[
	playerSelector.lua
		A player selector button
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local PlayerSelector = Addon:NewClass('PlayerSelector', 'Button')

local SIZE = 20
local TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function PlayerSelector:New(parent)
	local b = self:Bind(CreateFrame('Button', nil, parent))
	b:SetWidth(SIZE)
	b:SetHeight(SIZE)
	b:RegisterForClicks('anyUp')

	local nt = b:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetSize(TEXTURE_SIZE, TEXTURE_SIZE)
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
	icon:SetAllPoints(b)
	b.icon = icon

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)

	b:RegisterMessage(b:GetFrameID() .. '_PLAYER_CHANGED', 'Update')
	b:Update()

	return b
end


--[[ Interaction ]]--

function PlayerSelector:OnClick()
	Addon:TogglePlayerDropdown(self, self:GetFrame(), -4, -2)
end

function PlayerSelector:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	GameTooltip:SetText(L.TipChangePlayer)
end

function PlayerSelector:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Update ]]--

function PlayerSelector:Update()
	self.icon:SetTexture(Addon:GetPlayerIcon(self:GetPlayer()))
end