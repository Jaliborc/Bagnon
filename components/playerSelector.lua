--[[
	playerSelector.lua
		A player selector button
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local PlayerSelector = Bagnon:NewClass('PlayerSelector', 'Button')
local ItemCache = LibStub('LibItemCache-1.0')

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function PlayerSelector:New(frameID, parent)
	local b = self:Bind(CreateFrame('Button', nil, parent))
	b:SetWidth(SIZE)
	b:SetHeight(SIZE)
	b:RegisterForClicks('anyUp')

	local nt = b:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(NORMAL_TEXTURE_SIZE)
	nt:SetHeight(NORMAL_TEXTURE_SIZE)
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
	icon:SetTexture(self:GetPlayerIcon())
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
	self.icon:SetTexture(self:GetPlayerIcon())
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
end

function PlayerSelector:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function PlayerSelector:GetPlayerIcon()
	local _, race = UnitRace('player')
  local sex = UnitSex('player') == 3 and 'Female' or 'Male'

  if race ~= 'Worgen' and race ~= 'Goblin' then
    if race == 'Scourge' then
      race = 'Undead'
    end

    return string.format([[Interface\Icons\Achievement_Character_%s_%s]], race, sex)
  else
    -- temporary portraits until the next holiday achievements bring the cata races in
    return string.format([[Interface\CharacterFrame\TEMPORARYPORTRAIT-%s-%s]], sex, race)
  end
end