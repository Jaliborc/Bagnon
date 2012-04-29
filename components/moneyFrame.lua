--[[
	moneyFrame.lua
		A money frame object
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local MoneyFrame = Bagnon:NewClass('MoneyFrame', 'Frame')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local ItemCache = LibStub('LibItemCache-1.0')


--[[ Constructor ]]--

function MoneyFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('Button', parent:GetName() .. 'MoneyFrame', parent, 'SmallMoneyFrameTemplate'))
	f:SetFrameID(frameID)
	f:SetHeight(24)
	
	local click = CreateFrame('Button', f:GetName() .. 'Click', f)
	click:SetFrameLevel(self:GetFrameLevel() + 4)
	click:RegisterForClicks('anyUp')
	click:SetAllPoints()
	
	click:SetScript('OnClick', function(_, ...) f:OnClick(...) end)
	click:SetScript('OnEnter', function() f:OnEnter() end)
	click:SetScript('OnLeave', function() f:OnLeave() end)

	f:SetScript('OnShow', f.UpdateEverything)
	f:SetScript('OnHide', f.UpdateEvents)
	f:SetScript('OnEvent', f.UpdateValue)

	return f
end


--[[ Events ]]--

function MoneyFrame:PLAYER_UPDATE(msg, frameID, player)
	if self:GetFrameID() == frameID then
		self:UpdateValue()
	end
end


--[[ Frame Events ]]--

function MoneyFrame:OnClick()
	local name = self:GetName()

	if MouseIsOver(_G[name .. 'GoldButton']) then
		OpenCoinPickupFrame(COPPER_PER_GOLD, MoneyTypeInfo[self.moneyType].UpdateFunc(self), self)
		self.hasPickup = 1
	elseif MouseIsOver(_G[name .. 'SilverButton']) then
		OpenCoinPickupFrame(COPPER_PER_SILVER, MoneyTypeInfo[self.moneyType].UpdateFunc(self), self)
		self.hasPickup = 1
	elseif MouseIsOver(_G[name .. 'CopperButton']) then
		OpenCoinPickupFrame(1, MoneyTypeInfo[self.moneyType].UpdateFunc(self), self)
		self.hasPickup = 1
	end
	
	self:OnLeave()
end

function MoneyFrame:OnEnter()
	if not ItemCache:HasCache() then
    	return
  	end

	-- Total
	local total = 0
	for i, player in ItemCache:IteratePlayers() do
		total = total + ItemCache:GetMoney(player)
	end

	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
	GameTooltip:AddDoubleLine(L.Total, GetCoinTextureString(total), nil,nil,nil, 1,1,1)
	GameTooltip:AddLine(' ')
	
	-- Each player
	for i, player in ItemCache:IteratePlayers() do
		local money = ItemCache:GetMoney(player)
		if money > 0 then
			GameTooltip:AddDoubleLine(player, self:GetCoinsText(money), 1,1,1, 1,1,1)
		end
	end
	
	GameTooltip:Show()
end

function MoneyFrame:OnLeave()
	GameTooltip:Hide()
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


--[[ Properties ]]--

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
	return ItemCache:GetMoney(self:GetPlayer())
end


--[[ Methods ]]--

function MoneyFrame:GetCoinsText(money)
	local gold, silver, copper = self:GetCoins(money)
	local text = ''

	if gold > 0 then
		text = format('%d|cffffd700%s|r', gold, GOLD_AMOUNT_SYMBOL)
	end

	if silver > 0 then
		text = text .. format(' %d|cffc7c7cf%s|r', silver, SILVER_AMOUNT_SYMBOL)
	end

	if copper > 0 or money == 0 then
		text = text .. format(' %d|cffeda55f%s|r', copper, COPPER_AMOUNT_SYMBOL)
	end

	return text
end

function MoneyFrame:GetCoins(money)
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = money % COPPER_PER_SILVER
	return gold, silver, copper
end