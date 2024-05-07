--[[
	The Bagnon frame design.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local C = LibStub('C_Everywhere')
local Frame = Addon.Frame
Frame.Font, Frame.FontH = GameFontNormalLeft, GameFontHighlightLeft
Frame.BrokerSpacing = 2
Frame.MoneySpacing = 8


--[[ Construct ]]--

function Frame:New(id)
	local f = self:Super(Frame):New(UIParent)
	f.id, f.quality = id, 0
	f.profile = f:GetBaseProfile()

	f.MenuButtons = {}
	f.Title = Addon.Title(f, f.Title)
	f.SearchFrame = Addon.SearchFrame(f)
	f.ItemGroup = self.ItemGroup(f, f.Bags)
	f.CloseButton = CreateFrame('Button', nil, f, 'UIPanelCloseButtonNoScripts')
	f.CloseButton:SetScript('OnClick', function() Addon.Frames:Hide(f.id, true) end)

	f:Hide()
	f:FindRules()
	f:SetMovable(true)
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:SetScript('OnShow', self.OnShow)
	f:SetScript('OnHide', self.OnHide)

	tinsert(UISpecialFrames, f:GetName())
	return f
end

function Frame:RegisterEvents()
end


--[[ Update ]]--

function Frame:Layout()
	local width, height = 44, 36
	local grow = function(w, h)
		width = max(width, w)
		height = height + h
	end

	--place top menu
	width = width + self:PlaceMenuButtons()
	width = width + self:PlaceOptionsToggle()
	width = width + self:PlaceTitle()
	self:PlaceSearchBar()

	--place main grid
	grow(self:PlaceBagGroup())
	grow(self:PlaceItemGroup())

	--place bottom displays
	grow(self:PlaceMoney())
	grow(self:PlaceCurrencies(width, height))
	self:PlaceBrokerCarrousel(width, height)

	--adjust size
	self:SetSize(max(width, 156) + 16, height)
	Addon.Skins:Call('layout', self.bg)
end


--[[ Top Menu ]]--

function Frame:PlaceMenuButtons()
	local buttons = {}
	tinsert(buttons, self:HasOwnerSelector() and self:Get('OwnerSelector', function() return Addon.OwnerSelector(self) end))
	tAppendAll(buttons, self:GetExtraButtons())
	tinsert(buttons, self:HasSortButton() and self:Get('SortButton', function() return Addon.SortButton(self) end))
	tinsert(buttons, self:HasSearchToggle() and self:Get('SearchToggle', function() return Addon.SearchToggle(self) end))

	for i, button in pairs(self.MenuButtons) do
		button:Hide()
	end
	self.MenuButtons = tFilter(buttons, function(v) return v end, true)

	for i, button in ipairs(self.MenuButtons) do
		if i == 1 then
			button:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		else
			button:SetPoint('TOPLEFT', self.MenuButtons[i-1], 'TOPRIGHT', 4, 0)
		end
		button:Show()
	end

	return 20 * #self.MenuButtons, 20
end

function Frame:PlaceSearchBar()
	self.SearchFrame:ClearAllPoints()
	self.SearchFrame:SetHeight(28)

	if #self.MenuButtons > 0 then
		self.SearchFrame:SetPoint('LEFT', self.MenuButtons[#self.MenuButtons], 'RIGHT', 2, 0)
	else
		self.SearchFrame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
	end

	if self:HasOptionsToggle() then
		self.SearchFrame:SetPoint('RIGHT', self.OptionsToggle, 'LEFT', -2, 0)
	else
		self.SearchFrame:SetPoint('RIGHT', self.CloseButton, 'LEFT', -2, 0)
	end
end

function Frame:PlaceOptionsToggle()
	if self:HasOptionsToggle() then
		self.OptionsToggle = self.OptionsToggle or Addon.OptionsToggle(self)
		self.OptionsToggle:ClearAllPoints()
		self.OptionsToggle:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -32, -8)
		self.OptionsToggle:Show()

		return self.OptionsToggle:GetWidth(), self.OptionsToggle:GetHeight()
	elseif self.OptionsToggle then
		self.OptionsToggle:Hide()
	end

	return 0,0
end

function Frame:PlaceTitle()
	local frame = self.Title
	local w = 0

	frame:ClearAllPoints()
	frame:SetHeight(20)

	if #self.MenuButtons > 0 then
		frame:SetPoint('LEFT', self.MenuButtons[#self.MenuButtons], 'RIGHT', 4, 0)
		w = frame:GetTextWidth() / 2 + 4
	else
		frame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		w = frame:GetTextWidth() + 8
	end

	if self:HasOptionsToggle() then
		frame:SetPoint('RIGHT', self.OptionsToggle, 'LEFT', -4, 0)
	else
		frame:SetPoint('RIGHT', self.CloseButton, 'LEFT', -4, 0)
	end

	return w, 20
end

function Frame:HasOptionsToggle()
	return C.Addons.GetAddOnEnableState(ADDON .. '_Config', UnitName('player')) >= 2 and self.profile.options
end

function Frame:HasOwnerSelector()
	return Addon.Owners:Count() > 1
end

function Frame:HasSearchToggle()
	return self.profile.search
end

function Frame:HasSortButton()
	return self.profile.sort
end


--[[ Grid ]]--

function Frame:PlaceBagGroup()
	if self:IsBagGroupShown() then
		local inset = self.bg.skin.inset or 0 
		self.bagGroup = self.bagGroup or self.BagGroup(self, 'LEFT', 36, 0)
		self.bagGroup:Show()

		if #self.MenuButtons > 0 then
			self.bagGroup:SetPoint('TOPLEFT', self.MenuButtons[1], 'BOTTOMLEFT', inset, -4-inset)
		else
			self.bagGroup:SetPoint('TOPLEFT', self.Title, 'BOTTOMLEFT', inset, -4-inset)
		end

		return self.bagGroup:GetWidth() + inset*2, self.bagGroup:GetHeight() + 4
	elseif self.bagGroup then
		self.bagGroup:Hide()
	end

	return 0, 0
end

function Frame:PlaceItemGroup()
	local anchor = self:IsBagGroupShown() and self.bagGroup
					or #self.MenuButtons > 0 and self.MenuButtons[1]
					or self.Title
	local inset = anchor ~= self.bagGroup and self.bg.skin.inset or 0

	self.ItemGroup:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', inset, -4-inset)
	return self.ItemGroup:GetWidth() - 2 + (self.bg.skin.inset or 0) * 2, self.ItemGroup:GetHeight()
end

function Frame:IsBagGroupShown()
	return self:GetProfile().showBags
end


--[[ Bottom Displays ]]--

function Frame:PlaceMoney()
	if self:HasMoney() then
		self.Money = self.Money or self.MoneyFrame(self)
		self.Money:SetPoint('TOPRIGHT', self.ItemGroup, 'BOTTOMRIGHT', self.MoneySpacing, 0)
		self.Money:Show()

		return self.Money:GetSize()
	elseif self.Money then
		self.Money:Hide()
	end
	return 0,0
end

function Frame:PlaceCurrencies(width)
	if self:HasCurrencies() then
		self.Currency = self.Currency or Addon.CurrencyTracker(self)
		self.Currency:ClearAllPoints()
		self.Currency:Show()

		if self:HasMoney() and self.Currency:GetWidth() < (width - self.Money:GetWidth() - (self:HasBrokerCarrousel() and 24 or 2)) then
			self.Currency:SetPoint('TOPLEFT', self.ItemGroup, 'BOTTOMLEFT')
		else
			self.Currency:SetPoint('TOPRIGHT', self:HasMoney() and self.Money or self, 'BOTTOMRIGHT', -7,2)
			return self.Currency:GetSize()
		end
	elseif self.Currency then
		self.Currency:Hide()
	end
	return 0,0
end

function Frame:PlaceBrokerCarrousel()
	if self:HasBrokerCarrousel() then
		local right = self:HasMoney() and 
		              {'RIGHT', self.Money, 'LEFT', -5, self.BrokerSpacing} or
		              {'BOTTOMRIGHT', self, 'BOTTOMRIGHT', -4,4}
		local left = self:HasCurrencies() and self.Currency:GetPoint(1) == 'TOPLEFT' and
		              {'LEFT', self.Currency, 'RIGHT', -2,0} or
		              {'TOPLEFT', self.ItemGroup, 'BOTTOMLEFT', 0, self.BrokerSpacing}

		self.Broker = self.Broker or Addon.BrokerCarrousel(self)
		self.Broker:ClearAllPoints()
		self.Broker:SetPoint(unpack(right))
		self.Broker:SetPoint(unpack(left))
		self.Broker:Show()
		return 48, 24
	elseif self.Broker then
		self.Broker:Hide()
	end
	return 0, 0
end

function Frame:HasMoney()
	return self.profile.money
end

function Frame:HasCurrencies()
	return self.profile.currency
end

function Frame:HasBrokerCarrousel()
	return self.profile.broker
end
