--[[
	sortButton.lua
		Sorting options button
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local DepositReagent = Addon:NewClass('DepositReagent', 'CheckButton')

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function DepositReagent:New(frameID, parent)
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

	local ct = b:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetAllPoints(b)
	ct:SetBlendMode('ADD')
	b:SetCheckedTexture(ct)

	local icon = b:CreateTexture()
	icon:SetAllPoints(b)
	icon:SetTexture([[Interface\Icons\ACHIEVEMENT_GUILDPERK_QUICK AND DEAD]])

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetFrameID(frameID)

	return b
end


--[[ Frame Events ]]--

function DepositReagent:OnClick()
	DepositReagentBank()
end

function DepositReagent:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	
	GameTooltip:SetText(L.TipSortItems)
end

function DepositReagent:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Usual Acessor Functions ]]--

function DepositReagent:SetFrameID(frameID)
	self.frameID = frameID
end

function DepositReagent:GetFrameID()
	return self.frameID
end