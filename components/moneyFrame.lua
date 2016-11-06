--[[
	moneyFrame.lua
		A money frame object
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local MoneyFrame = Addon:NewClass('MoneyFrame', 'Frame')


--[[ Constructor ]]--

function MoneyFrame:New(parent)
	local f = self:Bind(CreateFrame('Button', parent:GetName() .. 'MoneyFrame', parent, 'SmallMoneyFrameTemplate'))
	f:SetHeight(24)
	
	local click = CreateFrame('Button', f:GetName() .. 'Click', f)
	click:SetFrameLevel(self:GetFrameLevel() + 4)
	click:RegisterForClicks('anyUp')
	click:SetAllPoints()
	
	click:SetScript('OnClick', function(_, ...) f:OnClick(...) end)
	click:SetScript('OnEnter', function() f:OnEnter() end)
	click:SetScript('OnLeave', function() f:OnLeave() end)

	f:SetScript('OnShow', f.RegisterEvents)
	f:SetScript('OnHide', f.UnregisterEvents)
	f:SetScript('OnEvent', nil)
	f:UnregisterAllEvents()
	f:RegisterEvents()

	return f
end


--[[ Interaction ]]--

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
	if not Addon.Cache:HasCache() then
    	return
  	end

	-- Total
	local total = 0
	for i, player in Addon.Cache:IteratePlayers() do
		total = total + Addon.Cache:GetPlayerMoney(player)
	end

	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
	GameTooltip:AddDoubleLine(L.Total, GetCoinTextureString(total), nil,nil,nil, 1,1,1)
	GameTooltip:AddLine(' ')
	
	-- Each player
	for i, player in Addon.Cache:IteratePlayers() do
		local money = Addon.Cache:GetPlayerMoney(player)
		if money > 0 then
			local color = Addon:GetPlayerColor(player)
			local coins = self:GetCoinsText(money)

			GameTooltip:AddDoubleLine(player, coins, color.r, color.g, color.b, 1,1,1)
		end
	end
	
	GameTooltip:Show()
end

function MoneyFrame:OnLeave()
	GameTooltip:Hide()
end


--[[ Update ]]--

function MoneyFrame:RegisterEvents()
	self:RegisterMessage(self:GetFrameID() .. '_PLAYER_CHANGED', 'Update')
	self:RegisterEvent('PLAYER_MONEY', 'Update')
	self:Update()
end

function MoneyFrame:Update()
	MoneyFrame_Update(self:GetName(), self:GetMoney())
end


--[[ API ]]--

function MoneyFrame:GetMoney()
	return Addon.Cache:GetPlayerMoney(self:GetPlayer())
end

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