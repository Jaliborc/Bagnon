--[[
	frame.lua
		The base frame widget
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Frame = Addon:NewClass('Frame', 'Frame')
Frame.ItemFrame = Addon.ItemFrame
Frame.BagFrame = Addon.BagFrame
Frame.MoneyFrame = Addon.MoneyFrame

Frame.OpenSound = 'igBackPackOpen'
Frame.CloseSound = 'igBackPackClose'
Frame.BrokerSpacing = 2


--[[ Constructor ]]--

function Frame:New(id)
	local f = self:Bind(CreateFrame('Frame', ADDON .. 'Frame' .. id, UIParent))
	f.shownCount = 0
	f.frameID = id

	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetMovable(true)

	f:Hide()
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)

	f:SetBackdrop{
	  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	  edgeSize = 16,
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	}

	tinsert(UISpecialFrames, f:GetName())
	return f
end


--[[ Visibility ]]--

function Frame:UpdateShown()
	if self:IsFrameShown() then
		self:Show()
	else
		self:Hide()
	end
end

function Frame:ShowFrame()
	self.shownCount = self.shownCount + 1
	self:Show()
end

function Frame:HideFrame(force) -- if a frame was manually opened, then it should only be closable manually
	self.shownCount = self.shownCount - 1

	if force or self.shownCount <= 0 then
		self.shownCount = 0
		self:Hide()
	end
end

function Frame:IsFrameShown()
	return self.shownCount > 0
end

function Frame:OnShow()
	PlaySound(self.OpenSound)
	self:RegisterMessage('UPDATE_ALL', 'Update')
	self:Update()
end

function Frame:OnHide()
	PlaySound(self.CloseSound)
	self:UnregisterMessages()

	if self:IsFrameShown() then -- for when a frame is hidden not via bagnon
		self:HideFrame()
		self:SetPlayer(nil)
	end
end


--[[ Update ]]--

function Frame:Update()
	self.profile = Addon.profile[self.frameID]
	self:UpdateShown()

	if self:IsVisible() then
		self:UpdatePosition()
		self:UpdateScale()
		self:UpdateOpacity()
		self:UpdateBackdrop()
		self:UpdateBackdropBorder()
		self:UpdateFrameLayer()
		self:Layout()
	end
end


-- scale
function Frame:UpdateScale() -- maintain the same relative position of the frame
	local oldScale = self:GetScale()
	local newScale = self:GetFrameScale()

	if oldScale ~= newScale then
		local point, x, y = self:GetPosition()
		local ratio = newScale / oldScale

		self:SetScale(newScale)
		self:SetPosition(point, x/ratio, y/ratio)
	end
end

function Frame:GetFrameScale()
	return self.profile.scale
end


-- position
function Frame:UpdatePosition()
	self:ClearAllPoints()
	self:SetPoint(self:GetPosition())
end

function Frame:SavePosition()
	local x, y = self:GetCenter()

	if x and y then
		local scale = self:GetScale()
		local h = UIParent:GetHeight() / scale
		local w = UIParent:GetWidth() / scale
		local xPoint, yPoint

		if x > w/2 then
			x = self:GetRight() - w
			xPoint = 'RIGHT'
		else
			x = self:GetLeft()
			xPoint = 'LEFT'
		end

		if x > w/2 then
			y = self:GetTop() - h
			yPoint = 'TOP'
		else
			y = self:GetBottom()
			yPoint = 'BOTTOM'
		end

		self:SetPosition(yPoint..xPoint, x, y)
	end
end

function Frame:SetPosition(point, x, y)
	self.profile.x, self.profile.y = x, y
	self.profile.point = point
end

function Frame:GetPosition()
	return self.profile.point, self.profile.x, self.profile.y
end


-- opacity
function Frame:UpdateOpacity()
	self:SetAlpha(self:GetOpacity())
end

function Frame:GetOpacity()
	return self.profile.alpha
end

function Frame:FadeInFrame(frame, alpha)
	if Addon.sets.fading then
		UIFrameFadeIn(frame, 0.2, 0, alpha or 1)
	end
	
	frame:Show()
end

function Frame:FadeOutFrame(frame)
	if frame then
		frame:Hide()
	end
end


-- colors
function Frame:UpdateBackdrop()
	self:SetBackdropColor(self:GetFrameBackdropColor())
end

function Frame:GetFrameBackdropColor()
	local color = self.profile.color
	return color[1], color[2], color[3], color[4]
end

function Frame:UpdateBackdropBorder()
	self:SetBackdropBorderColor(self:GetFrameBackdropBorderColor())
end

function Frame:GetFrameBackdropBorderColor()
	local color = self.profile.borderColor
	return color[1], color[2], color[3], color[4]
end


-- strata
function Frame:UpdateFrameLayer()
	self:SetFrameStrata(self:GetFrameLayer())
end

function Frame:GetFrameLayer()
	return self.profile.strata
end


--[[ Layout ]]--

function Frame:Layout()
	if not self:IsVisible() then
		return
	end

	local width, height = 24, 36

	--place top menu frames
	width = width + self:PlaceMenuButtons()
	width = width + self:PlaceCloseButton()
	width = width + self:PlaceOptionsToggle()
	width = width + self:PlaceTitleFrame()
	self:PlaceSearchFrame()

	--place middle frames
	local w, h = self:PlaceBagFrame()
	width = max(w, width)
	height = height + h
	self:PlaceItemFrame()

	--place bottom menu frames
	local w, h = self:PlaceMoneyFrame()
	width = max(w, width)
	height = height + h

	local w, h = self:PlaceBrokerDisplayFrame()
	if not self:HasMoneyFrame() then
		height = height + h
	end

	--adjust size
	self.width, self.height = max(width, 156), height
	self:UpdateSize()
end

function Frame:UpdateSize()
	self:SetWidth(max(self.width, self.itemFrame:GetWidth() - 2) + 16)
	self:SetHeight(self.height + self.itemFrame:GetHeight())
end

function Frame:PlaceMenuButtons()
	local menuButtons = self.menuButtons or {}
	self.menuButtons = menuButtons

	--hide the old
	for i, button in pairs(menuButtons) do
		button:Hide()
		menuButtons[i] = nil
	end

	--initiate new
	if self:HasPlayerSelector() then
		tinsert(menuButtons, self.playerSelector or self:CreatePlayerSelector())
	end
	self:GetSpecificButtons(menuButtons)

	if self:HasSearchToggle() then
		tinsert(menuButtons, self.searchToggle or self:CreateSearchToggle())
	end

	--position them
	for i, button in ipairs(menuButtons) do
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		else
			button:SetPoint('TOPLEFT', menuButtons[i-1], 'TOPRIGHT', 4, 0)
		end
		button:Show()
	end

	--get used space
	local numButtons = #menuButtons
	if numButtons > 0 then
		return (menuButtons[1]:GetWidth() + 4 * numButtons - 4), menuButtons[1]:GetHeight()
	end
	return 0, 0
end


-- close button
function Frame:PlaceCloseButton()
	local b = self.closeButton or self:CreateCloseButton()
	b:ClearAllPoints()
	b:SetPoint('TOPRIGHT', -2, -2)
	b:Show()

	return 20, 20 --make the same size as the other menu buttons
end

function Frame:CreateCloseButton()
	local b = CreateFrame('Button', self:GetName() .. 'CloseButton', self, 'UIPanelCloseButton')
	b:SetScript('OnClick', function() self:HideFrame(true) end)
	self.closeButton = b
	return b
end


-- search frame
function Frame:PlaceSearchFrame()
	local menuButtons = self.menuButtons
	local frame = self.searchFrame or self:CreateSearchFrame()
	frame:ClearAllPoints()

	if #menuButtons > 0 then
		frame:SetPoint('LEFT', menuButtons[#menuButtons], 'RIGHT', 2, 0)
	else
		frame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
	end

	if self:HasOptionsToggle() then
		frame:SetPoint('RIGHT', self.optionsToggle, 'LEFT', -2, 0)
	else
		frame:SetPoint('RIGHT', self.closeButton, 'LEFT', -2, 0)
	end

	frame:SetHeight(28)

	return frame:GetWidth(), frame:GetHeight()
end

function Frame:CreateSearchFrame()
	local f = Addon.SearchFrame:New(self)
	self.searchFrame = f
	return f
end


-- search toggle
function Frame:CreateSearchToggle()
	local toggle = Addon.SearchToggle:New(self)
	self.searchToggle = toggle
	return toggle
end

function Frame:HasSearchToggle()
	return self.profile.search
end


-- specific buttons
function Frame:GetSpecificButtons(list)
	if self:HasBagFrame() then
		tinsert(list, self.bagToggle or self:CreateBagToggle())
	end

	if self:HasSortButton() then
		tinsert(list, self.sortButton or self:CreateSortButton())
	end
end

function Frame:HasBagFrame()
	return self.profile.bagFrame
end

function Frame:HasSortButton()
	return self.profile.sort
end

function Frame:CreateBagToggle()
	local toggle = Addon.BagToggle:New(self)
	self.bagToggle = toggle
	return toggle
end

function Frame:CreateSortButton()
	local button = Addon.SortButton:New(self)
	self.sortButton = button
	return button
end


-- bag frame
function Frame:CreateBagFrame()
	local f =  self.BagFrame:New(self, 'LEFT', 36, 0)
	self.bagFrame = f
	return f
end

function Frame:IsBagFrameShown()
	return self.profile.showBags
end

function Frame:PlaceBagFrame()
	if self:HasBagFrame() and self:IsBagFrameShown() then
		local frame = self.bagFrame or self:CreateBagFrame()
		frame:ClearAllPoints()
		frame:Show()

		local menuButtons = self.menuButtons
		if #menuButtons > 0 then
			frame:SetPoint('TOPLEFT', menuButtons[1], 'BOTTOMLEFT', 0, -4)
		else
			frame:SetPoint('TOPLEFT', self.titleFrame, 'BOTTOMLEFT', 0, -4)
		end

		return frame:GetWidth(), frame:GetHeight() + 4
	elseif self.bagFrame then
		self.bagFrame:Hide()
	end

	return 0, 0
end 


-- title frame
function Frame:PlaceTitleFrame()
	local frame = self.titleFrame or self:CreateTitleFrame()
	local menuButtons = self.menuButtons
	local w, h = 0, 0

	frame:ClearAllPoints()
	if #menuButtons > 0 then
		frame:SetPoint('LEFT', menuButtons[#menuButtons], 'RIGHT', 4, 0)
		w = frame:GetTextWidth() / 2 + 4
		h = 20
	else
		frame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		w = frame:GetTextWidth() + 8
		h = 20
	end

	if self:HasOptionsToggle() then
		frame:SetPoint('RIGHT', self.optionsToggle, 'LEFT', -4, 0)
	else
		frame:SetPoint('RIGHT', self.closeButton, 'LEFT', -4, 0)
	end
	frame:SetHeight(20)

	return w, h
end

function Frame:CreateTitleFrame()
	local f = Addon.TitleFrame:New(self.Title, self)
	self.titleFrame = f
	return f
end


-- player selector
function Frame:HasPlayerSelector()
	return LibStub('LibItemCache-1.1'):HasCache()
end

function Frame:CreatePlayerSelector()
	local f = Addon.PlayerSelector:New(self)
	self.playerSelector = f
	return f
end


-- item frame
function Frame:PlaceItemFrame()
	local anchor = self:HasBagFrame() and self:IsBagFrameShown() and self.bagFrame
					or #self.menuButtons > 0 and self.menuButtons[1]
					or self.titleFrame

	local frame = self.itemFrame or self:CreateItemFrame()
	frame:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -4)
	frame:Show()
end

function Frame:CreateItemFrame()
	local f = self.ItemFrame:New(self, self.Bags)
	self.itemFrame = f
	return f
end


-- money frame
function Frame:HasMoneyFrame()
	return self.profile.money
end

function Frame:PlaceMoneyFrame()
	if self:HasMoneyFrame() then
		local frame = self.moneyFrame or self:CreateMoneyFrame()
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -(frame.ICON_SIZE or 0) - (frame.ICON_OFF or 0), 4)
		frame:Show()

		return frame:GetSize()
	elseif self.moneyFrame then
		self.moneyFrame:Hide()
	end
	return 0, 0
end

function Frame:CreateMoneyFrame()
	local f = self.MoneyFrame:New(self)
	self.moneyFrame = f
	return f
end


-- databroker display
function Frame:HasBrokerDisplay()
	return self.profile.broker
end

function Frame:PlaceBrokerDisplayFrame()
	if self:HasBrokerDisplay() then
		local x, x2, y = 4 * self.BrokerSpacing, 2 * self.BrokerSpacing, 5 * self.BrokerSpacing
		local frame = self.brokerDisplay or self:CreateBrokerDisplay()
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', x, y)

		if self:HasMoneyFrame() then
			frame:SetPoint('RIGHT', self.moneyFrame, 'LEFT', -x2, y)
		else
			frame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -x, y)
		end

		frame:Show()
		return frame:GetWidth(), 24
	elseif self.brokerDisplay then
		self.brokerDisplay:Hide()
	end

	return 0, 0
end

function Frame:CreateBrokerDisplay()
	local f = Addon.BrokerDisplay:New(1, self)
	self.brokerDisplay = f
	return f
end


-- options toggle
function Frame:CreateOptionsToggle()
	local f = Addon.OptionsToggle:New(self)
	self.optionsToggle = f
	return f
end

function Frame:PlaceOptionsToggle()
	if self:HasOptionsToggle() then
		local toggle = self.optionsToggle or self:CreateOptionsToggle()
		toggle:ClearAllPoints()
		toggle:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -32, -8)
		toggle:Show()

		return toggle:GetWidth(), toggle:GetHeight()
	elseif self.optionsToggle then
		self.optionsToggle:Hide()
	end

	return 0,0
end

function Frame:HasOptionsToggle()
	return GetAddOnEnableState(UnitName('player'), ADDON .. '_Config') >= 2 and self.profile.options
end


--[[ Shared ]]--

function Frame:SetPlayer(player)
	self.player = player
	self:SendMessage(self.frameID .. '_PLAYER_CHANGED')
end

function Frame:GetPlayer()
	return self.player or UnitName('player')
end

function Frame:GetProfile()
	return Addon:GetProfile(self.player)[self.frameID]
end

function Frame:IsCached()
	return Addon:IsBagCached(self.player, self.Bags[1])
end