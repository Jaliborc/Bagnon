--[[
	playerSelector.lua
		A player selector button
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local PlayerSelector = Bagnon:NewClass('PlayerSelector', 'Button')
local ItemCache = LibStub('LibItemCache-1.0')

local SIZE = 20
local TEXTURE_SIZE = 64 * (SIZE/36)
local ALTERNATIVE_ICONS = [[Interface\CharacterFrame\TEMPORARYPORTRAIT-%s-%s]]
local ICONS = [[Interface\Icons\Achievement_Character_%s_%s]]


--[[ Constructor ]]--

function PlayerSelector:New(frameID, parent)
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
	b:SetScript('OnShow', b.OnShow)
	b:SetFrameID(frameID)

	return b
end


--[[ Frame Events ]]--

function PlayerSelector:OnShow()
	self:UpdateIcon()
end

function PlayerSelector:OnClick()
	self:ShowPlayerSelector()
end

function PlayerSelector:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	self:UpdateTooltip()
end

function PlayerSelector:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Update Methods ]]--

function PlayerSelector:ShowPlayerSelector()
	if ItemCache:HasCache() then
		Bagnon:TogglePlayerDropdown(self, -4, -2)
	end
end

function PlayerSelector:UpdateIcon()
	local _, race, sex = ItemCache:GetPlayerInfo(self:GetPlayer())
	if not race then
		return
	else
		sex = sex == 3 and 'Female' or 'Male'
 	end

	if race ~= 'Worgen' and race ~= 'Goblin' and race ~= "Pandaren" then
		if race == 'Scourge' then
			race = 'Undead'
		end

		self.icon:SetTexture( ICONS:format(race, sex) )
	else
		-- temporary portraits until the holiday achievements bring the cata races in
		self.icon:SetTexture( ALTERNATIVE_ICONS:format(sex, race) )
	end
end

function PlayerSelector:UpdateTooltip()
	GameTooltip:SetText(L.TipChangePlayer)
end


--[[ Properties ]]--

function PlayerSelector:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
	end
end

function PlayerSelector:GetFrameID()
	return self.frameID
end

function PlayerSelector:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function PlayerSelector:SetPlayer(player)
	self:GetSettings():SetPlayerFilter(player)
	self:UpdateIcon()
end

function PlayerSelector:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end