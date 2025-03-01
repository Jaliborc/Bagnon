--[[
	The Bagnon frame design.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local C = LibStub('C_Everywhere')
local Frame = Addon.Frame
Frame.Font, Frame.FontH = GameFontNormalLeft, GameFontHighlightLeft
Frame.MoneySpacing = 2


--[[ Construct ]]--

function Frame:New(id)
	local f = self:Super(Frame):New(UIParent)
	f.id, f.quality = id, 0
	f.profile = f:GetBaseProfile()

	f.MenuButtons = {}
	f.Search = Addon.SearchFrame(f)
	f.Title = Addon.Title(f, f.Title)
	f.ItemGroup = self.ItemGroup(f, f.Bags)
	f.Footer = CreateFrame('Frame', nil, f)
	f.CloseButton = CreateFrame('Button', nil, f, 'UIPanelCloseButtonNoScripts')
	f.CloseButton:SetScript('OnClick', function() Addon.Frames:Hide(f.id, true) end)

	f:SetMovable(true)
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)

	tinsert(UISpecialFrames, f:GetName())
	return f
end


--[[ Update ]]--

function Frame:Layout()
	local width = 44 + self:PlaceMenuButtons()
	                 + self:PlaceOptionsToggle() + self:PlaceTitle()
			
	local function grow(height, stack, w,h)
		width = max(width, w)
		return stack and (height + h) or max(height, h)
	end					

	local main = 0
	main = grow(main, true, self:PlaceBagGroup())
	main = grow(main, true, self:PlaceItemGroup())

	local foot = 0
	foot = grow(foot, true, self:PlaceMoney())
	foot = grow(foot, true, self:PlaceCurrencies(width))
	foot = grow(foot, false, self:PlaceBrokerCarrousel())

	local height = grow(main + foot, false, 156, self:PlaceSidebar())
		
	self:PlaceSearchBar()
	self:PlaceFooter(foot)
	self:SetSize(width + 16, height + 30)
	self:SendFrameSignal('LAYOUT_FINISHED')
end


--[[ Top Menu ]]--

function Frame:PlaceMenuButtons()
	local buttons = {}
	tinsert(buttons, self:HasOwnerSelector() and self:GetWidget('OwnerSelector'))
	tAppendAll(buttons, self:GetExtraButtons())
	tinsert(buttons, self:HasSortButton() and self:GetWidget('SortButton'))
	tinsert(buttons, self:HasSearchToggle() and self:GetWidget('SearchToggle'))

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
	self.Search:ClearAllPoints()
	self.Search:SetPoint('RIGHT', self:HasOptionsToggle() and self.OptionsToggle or self.CloseButton, 'LEFT', -2, 0)
	self.Search:SetHeight(28)

	if #self.MenuButtons > 0 then
		self.Search:SetPoint('LEFT', self.MenuButtons[#self.MenuButtons], 'RIGHT', 2, 0)
	else
		self.Search:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
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
	frame:SetPoint('RIGHT', self:HasOptionsToggle() and self.OptionsToggle or self.CloseButton, 'LEFT', -4, 0)
	frame:SetHeight(20)

	if #self.MenuButtons > 0 then
		frame:SetPoint('LEFT', self.MenuButtons[#self.MenuButtons], 'RIGHT', 4, 0)
		w = frame:GetTextWidth() / 2 + 4
	else
		frame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		w = frame:GetTextWidth() + 8
	end

	return w, 20
end

function Frame:HasOptionsToggle()
	return C.AddOns.GetAddOnEnableState(ADDON .. '_Config', UnitName('player')) >= 2 and self.profile.options
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


--[[ Main Grid ]]--

function Frame:PlaceBagGroup()
	if self:IsBagGroupShown() then
		self.bagGroup = self.bagGroup or self.BagGroup(self, 'LEFT', 36, 0)
		self.bagGroup:Show()

		if #self.MenuButtons > 0 then
			self.bagGroup:SetPoint('TOPLEFT', self.MenuButtons[1], 'BOTTOMLEFT', self.inset, -4-self.inset)
		else
			self.bagGroup:SetPoint('TOPLEFT', self.Title, 'BOTTOMLEFT', self.inset, -4-self.inset)
		end

		return self.bagGroup:GetWidth() + self.inset*2, self.bagGroup:GetHeight() + 4
	elseif self.bagGroup then
		self.bagGroup:Hide()
	end

	return 0, 0
end

function Frame:PlaceItemGroup()
	local anchor = self:IsBagGroupShown() and self.bagGroup
					or #self.MenuButtons > 0 and self.MenuButtons[1]
					or self.Title
	local inset = anchor ~= self.bagGroup and self.inset or 0

	self.ItemGroup:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', inset, -4-inset)
	return self.ItemGroup:GetWidth() - 2 + (self.bg.skin.inset or 0) * 2, self.ItemGroup:GetHeight() + 6
end

function Frame:IsBagGroupShown()
	return self:GetProfile().showBags
end


--[[ Sidebar ]]--

function Frame:PlaceSidebar()
	if self:HasSidebar() then
		self:GetWidget('FilterGroup'):Show()
		return self.FilterGroup:GetHeight()
	elseif self.FilterGroup then
		self.FilterGroup:Hide()
	end
	return 0
end

function Frame:HasSidebar()
	return self.profile.sidebar
end


--[[ Bottom Displays ]]--

function Frame:PlaceFooter(size)
	self.Footer:SetPoint('BOTTOMLEFT', self.inset, 4-self.inset)
	self.Footer:SetPoint('BOTTOMRIGHT', -self.inset, 4-self.inset)
	self.Footer:SetHeight(size)
end

function Frame:PlaceMoney()
	if self:HasMoney() then
		self.Money = self.Money or self.MoneyFrame(self)
		self.Money:SetPoint('TOPRIGHT', self.Footer, self.MoneySpacing, 0)
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

		if self:HasMoney() and self.Currency:GetWidth() > (width - self.Money:GetWidth() - (self:HasBrokerCarrousel() and 24 or 2)) then
			self.Currency:SetPoint('BOTTOMRIGHT', self.Footer, -4,2)
			return self.Currency:GetSize()
		else
			self.Currency:SetPoint('TOPLEFT', self.Footer, 6,0)
		end
	elseif self.Currency then
		self.Currency:Hide()
	end
	return 0,0
end

function Frame:PlaceBrokerCarrousel()
	if self:HasBrokerCarrousel() then
		local right = self:HasMoney() and 
		              {'RIGHT', self.Money, 'LEFT', -5,0} or
		              {'RIGHT', self.Footer, 'RIGHT', -4,0}
		local left = self:HasCurrencies() and self.Currency:GetPoint(1) == 'TOPLEFT' and
		              {'TOPLEFT', self.Currency, 'TOPRIGHT', -2,1} or
		              {'TOPLEFT', self.Footer, 'TOPLEFT', 4,0}

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