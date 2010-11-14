--[[
	moneyFrame.lua
		A money frame object
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local MoneyFrame = Bagnon.Classy:New('Frame')
MoneyFrame:Hide()
Bagnon.MoneyFrame = MoneyFrame


--[[ Things! ]]--

local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local GOLD_TEXT = string.format('|cffffd700%s|r', 'g')
local SILVER_TEXT = string.format('|cffc7c7cf%s|r', 's')
local COPPER_TEXT = string.format('|cffeda55f%s|r', 'c')


--[[ Constructor ]]--

function MoneyFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('Frame', 'BagnonMoneyFrame' .. self:GetNextID(), parent, 'SmallMoneyFrameTemplate'))
	f:SetFrameID(frameID)
	f:AddClickFrame()

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:RegisterMessage('PLAYER_UPDATE')

	return f
end

--creates a clickable frame for tooltips/etc
local function ClickFrame_OnClick(self, button)
	self:GetParent():OnClick(button)
end

local function ClickFrame_OnEnter(self)
	self:GetParent():OnEnter()
end

local function ClickFrame_OnLeave(self)
	self:GetParent():OnLeave()
end

function MoneyFrame:AddClickFrame()
	local f = CreateFrame('Button', self:GetName() .. 'Click', self)
	f:SetFrameLevel(self:GetFrameLevel() + 3)
	f:SetAllPoints(self)

	f:SetScript('OnClick', ClickFrame_OnClick)
	f:SetScript('OnEnter', ClickFrame_OnEnter)
	f:SetScript('OnLeave', ClickFrame_OnLeave)

	return f
end

do
	local id = 0
	function MoneyFrame:GetNextID()
		local nextID = id + 1
		id = nextID
		return nextID
	end
end


--[[ Events ]]--

function MoneyFrame:PLAYER_UPDATE(msg, frameID, player)
	if self:GetFrameID() == frameID then
		self:UpdateValue()
	end
end


--[[ Frame Events ]]--

function MoneyFrame:OnShow()
	self:UpdateEverything()
end

function MoneyFrame:OnHide()
	self:UpdateEvents()
end

function MoneyFrame:OnClick()
	local name = self:GetName()

	if MouseIsOver(_G[name .. 'GoldButton']) then
		OpenCoinPickupFrame(COPPER_PER_GOLD, MoneyTypeInfo[self.moneyType].UpdateFunc(), self)
		self.hasPickup = 1
	elseif MouseIsOver(_G[name .. 'SilverButton']) then
		OpenCoinPickupFrame(COPPER_PER_SILVER, MoneyTypeInfo[self.moneyType].UpdateFunc(), self)
		self.hasPickup = 1
	elseif MouseIsOver(_G[name .. 'CopperButton']) then
		OpenCoinPickupFrame(1, MoneyTypeInfo[self.moneyType].UpdateFunc(), self)
		self.hasPickup = 1
	end
	
	self:OnLeave()
end

function MoneyFrame:OnEnter()
	if not BagnonDB then return end

	GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
	GameTooltip:SetText(string.format(L.TipGoldOnRealm, GetRealmName()))

	local totalMoney = 0
	for i, player in pairs(BagnonDB:GetPlayerList()) do
		local money = Bagnon.PlayerInfo:GetMoney(player)
		if money > 0 then
			totalMoney = totalMoney + money
			self:AddPlayerTotalToTooltip(player, money, GameTooltip)
		end
	end

	GameTooltip:AddLine('----------------------------------------')
	self:AddPlayerTotalToTooltip(L.Total, totalMoney, GameTooltip)
	GameTooltip:Show()
end

function MoneyFrame:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Update Methods ]]--

function MoneyFrame:UpdateEverything()
	self:UpdateEvents()
	self:UpdateValue()
end

function MoneyFrame:UpdateValue()
	if self:IsVisible() then
		MoneyFrame_Update(self:GetName(), self:GetMoney())
	end
end

function MoneyFrame:UpdateEvents()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterMessage('PLAYER_UPDATE')
	end
end


--[[ Frame Properties ]]--

function MoneyFrame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function MoneyFrame:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function MoneyFrame:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function MoneyFrame:GetFrameID()
	return self.frameID
end

function MoneyFrame:GetMoney()
	return Bagnon.PlayerInfo:GetMoney(self:GetPlayer())
end

function MoneyFrame:GetGoldSilverCopper(money)
	local gold = math.floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
	local silver = math.floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = money % COPPER_PER_SILVER

	return gold, silver, copper
end

function MoneyFrame:AddPlayerTotalToTooltip(player, money, tooltip)
	local gold, silver, copper = self:GetGoldSilverCopper(money)
	local text

	if gold > 0 then
		text = string.format('|cffffffff%d|r%s', gold, GOLD_TEXT)
	end

	if silver > 0 then
		if text then
			text = text .. string.format(' |cffffffff%d|r%s', silver, SILVER_TEXT)
		else
			text = string.format('|cffffffff%d|r%s', silver, SILVER_TEXT)
		end
	end

	if copper > 0 then
		if text then
			text = text .. string.format(' |cffffffff%d|r%s', copper, COPPER_TEXT)
		else
			text = string.format('|cffffffff%d|r%s', copper, COPPER_TEXT)
		end
	end

	tooltip:AddDoubleLine(player, text, 1, 1, 1, 1, 1, 1, 0)
end