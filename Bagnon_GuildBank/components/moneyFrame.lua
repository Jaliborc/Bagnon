--[[
	moneyFrame.lua
		A money frame object
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local MoneyFrame = Bagnon.Classy:New('Frame')
MoneyFrame:Hide()
Bagnon.GuildMoneyFrame = MoneyFrame


--[[ Things! ]]--

local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local GOLD_TEXT = string.format('|cffffd700%s|r', 'g')
local SILVER_TEXT = string.format('|cffc7c7cf%s|r', 's')
local COPPER_TEXT = string.format('|cffeda55f%s|r', 'c')


--[[ Constructor ]]--

function MoneyFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('Frame', 'BagnonGuildMoneyFrame' .. self:GetNextID(), parent, 'SmallMoneyFrameTemplate'))
	f:SetFrameID(frameID)
	f:AddClickFrame()

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:SetScript('OnEvent', f.OnEvent)

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
	f:RegisterForClicks('anyUp')

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

function MoneyFrame:GUILDBANK_UPDATE_MONEY()
	self:UpdateValue()
end

--[[ Frame Events ]]--

function MoneyFrame:OnShow()
	self:UpdateEverything()
end

function MoneyFrame:OnHide()
	self:UpdateEvents()
end

function MoneyFrame:OnClick(button)
	local cMoney = GetCursorMoney() or 0
	if cMoney > 0 then
		self:DepositMoney(cMoney)
		return
	end

	if button == 'LeftButton' and (not IsShiftKeyDown()) then
		self:ShowDepositDialog()
		return
	end

	if button == 'RightButton' or (button == 'LeftButton' and IsShiftKeyDown())  then
		self:ShowWithdrawDialog()
		return
	end
end

function MoneyFrame:OnEnter()
	GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
	self:UpdateTooltip()
end

function MoneyFrame:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

function MoneyFrame:OnEvent(event, ...)
	local action = self[event]
	if action then
		action(self, event, ...)
	end
end


--[[ Actions ]]--

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
	self:UnregisterAllEvents()
	if self:IsVisible() then
		self:RegisterEvent('GUILDBANK_UPDATE_MONEY')
	end
end

function MoneyFrame:UpdateTooltip()
	GameTooltip:SetText('Guild Funds')
	GameTooltip:AddLine('<Left Click> to deposit.', 1, 1, 1)

	if CanWithdrawGuildBankMoney() then
		local withdrawMoney = GetGuildBankWithdrawMoney()
		if withdrawMoney > 0 then
			GameTooltip:AddLine(string.format('<Right Click> to withdraw (%s remaining).', self:GetCurrencyText(withdrawMoney)), 1, 1, 1)
		else
			GameTooltip:AddLine('<Right Click> to withdraw.')
		end
	end

	GameTooltip:Show()
end

function MoneyFrame:DepositMoney(amount)
	DepositGuildBankMoney(cMoney)
	DropCursorMoney()
end

function MoneyFrame:ShowDepositDialog()
	PlaySound('igMainMenuOption')

	StaticPopup_Hide('GUILDBANK_WITHDRAW')
	if StaticPopup_Visible('GUILDBANK_DEPOSIT') then
		StaticPopup_Hide('GUILDBANK_DEPOSIT')
	else
		StaticPopup_Show('GUILDBANK_DEPOSIT')
	end
end

function MoneyFrame:ShowWithdrawDialog()
	if not CanWithdrawGuildBankMoney() then return end

	PlaySound('igMainMenuOption')

	StaticPopup_Hide('GUILDBANK_DEPOSIT')
	if StaticPopup_Visible('GUILDBANK_WITHDRAW') then
		StaticPopup_Hide('GUILDBANK_WITHDRAW')
	else
		StaticPopup_Show('GUILDBANK_WITHDRAW')
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
	return GetGuildBankMoney()
end

function MoneyFrame:GetGoldSilverCopper(money)
	local gold = math.floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
	local silver = math.floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = money % COPPER_PER_SILVER

	return gold, silver, copper
end

function MoneyFrame:GetCurrencyText(money)
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

	if copper > 0 or (gold == 0 and silver == 0) then
		if text then
			text = text .. string.format(' |cffffffff%d|r%s', copper, COPPER_TEXT)
		else
			text = string.format('|cffffffff%d|r%s', copper, COPPER_TEXT)
		end
	end

	return text
end