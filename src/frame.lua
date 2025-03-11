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

function Frame:New(params)
	local f = self:Super(Frame):New(UIParent)
	tinsert(UISpecialFrames, f:GetName())
	MergeTable(f, params)

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
	foot = grow(foot, false, self:PlaceBroker())

	local height = grow(main + foot, false, self:PlaceSidebar())
		
	self:PlaceSearchBar()
	self:PlaceFooter(foot)
	self:SetSize(max(156, width) + 16, height + 30)
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
	return self:PlaceWidget('OptionsToggle', self:HasOptionsToggle() and function(toggle)
		toggle:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -32, -8)
	end)
end

function Frame:PlaceTitle()
	local title = self.Title
	local w = 0

	title:ClearAllPoints()
	title:SetPoint('RIGHT', self:HasOptionsToggle() and self.OptionsToggle or self.CloseButton, 'LEFT', -4, 0)
	title:SetHeight(20)

	if #self.MenuButtons > 0 then
		title:SetPoint('LEFT', self.MenuButtons[#self.MenuButtons], 'RIGHT', 4, 0)
		w = title:GetTextWidth() / 2 + 4
	else
		title:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		w = title:GetTextWidth() + 8
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

function Frame:PlaceItemGroup()
	local anchor = self:AreBagsShown() and self.BagGroup
					or #self.MenuButtons > 0 and self.MenuButtons[1]
					or self.Title
	local inset = anchor ~= self.BagGroup and self.inset or 0

	self.ItemGroup:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', inset, -4-inset)
	return self.ItemGroup:GetWidth() - 2 + (self.bg.skin.inset or 0) * 2, self.ItemGroup:GetHeight() + 6
end

function Frame:PlaceBagGroup()
	return self:PlaceWidget('BagGroup', self:AreBagsShown() and function(bags)
		if #self.MenuButtons > 0 then
			bags:SetPoint('TOPLEFT', self.MenuButtons[1], 'BOTTOMLEFT', self.inset, -4-self.inset)
		else
			bags:SetPoint('TOPLEFT', self.Title, 'BOTTOMLEFT', self.inset, -4-self.inset)
		end

		return bags:GetWidth() + self.inset*2, bags:GetHeight() + 4
	end)
end


--[[ Sidebar ]]--

function Frame:PlaceSidebar()
	return self:PlaceWidget('FilterGroup', self:HasSidebar() and function(filters)
		if self.id == 'inventory' then
			filters:SetPoint('TOPRIGHT', self, 'TOPLEFT', 4,0)
		else
			filters:SetPoint('TOPLEFT', self, 'TOPRIGHT')
		end
	end)
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
	return self:PlaceWidget('MoneyFrame', self:HasMoney() and function(money)
		money:SetPoint('TOPRIGHT', self.Footer, self.MoneySpacing, 0)
	end)
end

function Frame:PlaceCurrencies(width)
	return self:PlaceWidget('CurrencyTracker', self:HasCurrencies() and function(tracker)
		local wide = self:HasMoney() and tracker:GetWidth() > (width - self.MoneyFrame:GetWidth() - (self:HasBroker() and 24 or 2))
		if wide then
			tracker:SetPoint('BOTTOMRIGHT', self.Footer, -4,2)
		else
			tracker:SetPoint('TOPLEFT', self.Footer, 6,0)
		end

		return not wide and self:HasMoney() and 0
	end)
end

function Frame:PlaceBroker()
	return self:PlaceWidget('BrokerCarrousel', self:HasBroker() and function(broker)
		local right = self:HasMoney() and 
		              {'RIGHT', self.MoneyFrame, 'LEFT', -5,0} or
		              {'RIGHT', self.Footer, 'RIGHT', -4,0}
		local left = self:HasCurrencies() and self.CurrencyTracker:GetPoint(1) == 'TOPLEFT' and
		              {'TOPLEFT', self.CurrencyTracker, 'TOPRIGHT', -2,1} or
		              {'TOPLEFT', self.Footer, 'TOPLEFT', 4,0}

		broker:SetPoint(unpack(right))
		broker:SetPoint(unpack(left))

		return 48,24
	end)
end

function Frame:HasMoney()
	return self.profile.money
end

function Frame:HasCurrencies()
	return self.profile.currency
end

function Frame:HasBroker()
	return self.profile.broker
end


--[[ Utilities ]]--

function Frame:PlaceWidget(key, setup)
    local widget = rawget(self, key)
    if setup then
        widget = widget or self:GetWidget(key)
        widget:ClearAllPoints()
        widget:Show()

        local width, height = setup(widget)
        if not width then
            width, height = widget:GetSize()
        end

        return width, height or width
    elseif widget then
        widget:Hide()
    end
    
    return 0, 0
end