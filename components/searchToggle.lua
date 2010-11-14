--[[
	searchToggle.lua
		A searcn toggle widget
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local SearchToggle = Bagnon.Classy:New('CheckButton')
Bagnon.SearchToggle = SearchToggle


local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)

--[[ Constructor ]]--

function SearchToggle:New(frameID, parent)
	local b = self:Bind(CreateFrame('CheckButton', nil, parent))
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

	local ct = b:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetAllPoints(b)
	ct:SetBlendMode('ADD')
	b:SetCheckedTexture(ct)

	local icon = b:CreateTexture()
	icon:SetAllPoints(b)
	icon:SetTexture([[Interface\Icons\INV_Misc_Spyglass_03]])

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnShow', b.OnShow)
	b:SetScript('OnHide', b.OnHide)

	b:SetFrameID(frameID)

	return b
end


--[[ Messages ]]--

function SearchToggle:TEXT_SEARCH_ENABLE(msg, frameID)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end

function SearchToggle:TEXT_SEARCH_DISABLE(msg, frameID)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end


--[[ Frame Events ]]--

function SearchToggle:OnShow()
	self:UpdateEvents()
	self:Update()
end

function SearchToggle:OnHide()
	self:UpdateEvents()
end

function SearchToggle:OnClick()
	self:ToggleSearch()
end

function SearchToggle:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	self:UpdateTooltip()
end

function SearchToggle:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Update Methods ]]--

function SearchToggle:Update()
	if self:IsVisible() then
		self:SetChecked(self:IsSearchEnabled())
	end
end

function SearchToggle:UpdateEvents()
	self:UnregisterAllMessages()
	
	if self:IsVisible() then
		self:RegisterMessage('TEXT_SEARCH_ENABLE')
		self:RegisterMessage('TEXT_SEARCH_DISABLE')
	end
end

function SearchToggle:UpdateTooltip()
	if not GameTooltip:IsOwned(self) then return end

	if self:IsSearchEnabled() then
		GameTooltip:SetText(L.TipHideSearch)
	else
		GameTooltip:SetText(L.TipShowSearch)
	end
end


--[[ Properties ]]--

function SearchToggle:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEvents()
		self:Update()
	end
end

function SearchToggle:GetFrameID()
	return self.frameID
end

function SearchToggle:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function SearchToggle:ToggleSearch()
	self:GetSettings():ToggleTextSearch()
end

function SearchToggle:IsSearchEnabled()
	return self:GetSettings():IsTextSearchEnabled()
end