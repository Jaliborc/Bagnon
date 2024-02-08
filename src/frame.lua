--[[
	The Bagnon frame design.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local C = LibStub('C_Everywhere')
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Frame = Addon.Frame
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

	--[[
		This is not working properly since the name of the frame
		always nil. I'm not sure how could you set it properly or
		what's the actual problem
		The interesting part is when both the bag and the bank is open,
		it is closing but only the bag, though both name is still nil.
		That's some sort of black magic.
	]]
	tinsert(UISpecialFrames, f:GetName())
	return f
end

function Frame:RegisterSignals()
	self:RegisterSignal('UPDATE_ALL', 'Update')
	self:RegisterSignal('RULES_LOADED', 'FindRules')
	self:RegisterSignal('SKINS_LOADED', 'UpdateBackdrop')
	self:RegisterFrameSignal('BAG_FRAME_TOGGLED', 'Layout')
	self:RegisterFrameSignal('ELEMENT_RESIZED', 'Layout')
	self:SetScript('OnKeyDown', function(_, key)
		if key == 'ESCAPE' or key == 27 then
			self:SetPropagateKeyboardInput(false)
			self:Hide()
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	self:Update()
end


--[[ Update ]]--

function Frame:Update()
	self.profile = self:GetBaseProfile()
	self:UpdateAppearance()
	self:UpdateBackdrop()
	self:Layout()
end

function Frame:UpdateBackdrop()
	if self.bg then
		Addon.Skins:Release(self.bg)
	end

	local center = self.profile.color
	local border = self.profile.borderColor
	local bg = Addon.Skins:Acquire(self.profile.skin)
	bg:SetParent(self)
	bg:SetFrameLevel(self:GetFrameLevel())
	bg:SetPoint('BOTTOMLEFT', bg.skin.x or 0, bg.skin.y or 0)
	bg:SetPoint('TOPRIGHT', bg.skin.x1 or 0, bg.skin.y1 or 0)
	bg:EnableMouse(true)

	self.CloseButton:SetPoint('TOPRIGHT', (bg.skin.closeX or 0)-2, (bg.skin.closeY or 0)-2)
	self.bg = bg

	Addon.Skins:Call('load', bg)
	Addon.Skins:Call('borderColor', bg, border[1], border[2], border[3], border[4])
	Addon.Skins:Call('centerColor', bg, center[1], center[2], center[3], center[4])
end

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
			self.Currency:SetPoint('TOPRIGHT', self:HasMoney() and self.Money or self, 'BOTTOMRIGHT', -7,0)
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
	return self.profile.currency and BackpackTokenFrame
end

function Frame:HasBrokerCarrousel()
	return self.profile.broker
end
