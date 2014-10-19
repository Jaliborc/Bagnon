--[[
	frame.lua
		The base frame widget
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Frame = Addon:NewClass('Frame', 'Frame')
Frame.OpenSound = 'igBackPackOpen'
Frame.CloseSound = 'igBackPackClose'
Frame.ItemFrame = Addon.ItemFrame
Frame.BagFrame = Addon.BagFrame
Frame.MoneyFrame = Addon.MoneyFrame


--[[ Constructor ]]--

function Frame:New(id)
	local f = self:Bind(CreateFrame('Frame', ADDON .. 'Frame' .. id, UIParent))
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:Hide()

	f:SetBackdrop{
	  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	  edgeSize = 16,
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	}

	f.frameID = id
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:Rescale()
	f:UpdateEverything()

	tinsert(UISpecialFrames, f:GetName())
	return f
end


--[[ Frame Messages ]]--

function Frame:UpdateEvents()
	self:UnregisterAllMessages()
	self:RegisterMessage('FRAME_SHOW')

	if self:IsVisible() then
		self:RegisterMessage('FRAME_HIDE')
		self:RegisterMessage('FRAME_LAYER_UPDATE')
		self:RegisterMessage('FRAME_MOVE_START')
		self:RegisterMessage('FRAME_MOVE_STOP')
		self:RegisterMessage('FRAME_POSITION_UPDATE')
		self:RegisterMessage('FRAME_OPACITY_UPDATE')
		self:RegisterMessage('FRAME_COLOR_UPDATE')
		self:RegisterMessage('FRAME_BORDER_COLOR_UPDATE')
		self:RegisterMessage('FRAME_SCALE_UPDATE')
		self:RegisterMessage('BAG_FRAME_UPDATE_SHOWN')
		self:RegisterMessage('BAG_FRAME_UPDATE_LAYOUT')
		self:RegisterMessage('ITEM_FRAME_SIZE_CHANGE')

		self:RegisterMessage('BAG_FRAME_ENABLE_UPDATE')
		self:RegisterMessage('MONEY_FRAME_ENABLE_UPDATE')
		self:RegisterMessage('DATABROKER_FRAME_ENABLE_UPDATE')
		self:RegisterMessage('SEARCH_TOGGLE_ENABLE_UPDATE')
		self:RegisterMessage('OPTIONS_TOGGLE_ENABLE_UPDATE')
		self:RegisterMessage('SORT_ENABLE_UPDATE')
	end
end

function Frame:FRAME_SHOW(msg, frameID)
	if self:GetFrameID() == frameID then
		self:FadeInFrame(self, self:GetFrameOpacity())
	end
end

function Frame:FRAME_HIDE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Hide()
	end
end

function Frame:FRAME_MOVE_START(msg, frameID)
	if self:GetFrameID() == frameID then
		self:StartMoving()
	end
end

function Frame:FRAME_MOVE_STOP (msg, frameID)
	if self:GetFrameID() == frameID then
		self:StopMovingOrSizing()
		self:SavePosition()
	end
end

function Frame:FRAME_POSITION_UPDATE (msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdatePosition()
	end
end

function Frame:FRAME_SCALE_UPDATE (msg, frameID, scale)
	if self:GetFrameID() == frameID then
		self:UpdateScale()
	end
end

function Frame:FRAME_OPACITY_UPDATE (msg, frameID, opacity)
	if self:GetFrameID() == frameID then
		self:UpdateOpacity()
	end
end

function Frame:FRAME_COLOR_UPDATE (msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:UpdateBackdrop()
	end
end

function Frame:FRAME_BORDER_COLOR_UPDATE (msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:UpdateBackdropBorder()
	end
end

function Frame:FRAME_LAYER_UPDATE(msg, frameID, layer)
	if self:GetFrameID() == frameID then
		self:SetFrameLayer(layer)
	end
end

do
	local function LayoutMessage (self, msg, frameID)
		if self:GetFrameID() == frameID then
			self:Layout()
		end
	end

	local messages = {
		'BAG_FRAME_UPDATE_LAYOUT',
		'BAG_FRAME_UPDATE_SHOWN',
		'ITEM_FRAME_SIZE_CHANGE',
		'BAG_FRAME_ENABLE_UPDATE',
		'MONEY_FRAME_ENABLE_UPDATE',
		'DATABROKER_FRAME_ENABLE_UPDATE',
		'SEARCH_TOGGLE_ENABLE_UPDATE',
		'OPTIONS_TOGGLE_ENABLE_UPDATE',
		'SORT_ENABLE_UPDATE'
	}
	
	for _, msg in ipairs(messages) do
		Frame[msg] = LayoutMessage
	end
end


--[[
  Frame Events
]]--

function Frame:OnShow()
	PlaySound(self.OpenSound)
	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:OnHide()
	PlaySound(self.CloseSound)
	self:UpdateEvents()

	-- fow when a frame is hidden not via bagnon
	if self:IsFrameShown() then
		self:HideFrame()
	end
end


--[[
  Update Methods
]]--

function Frame:UpdateEverything()
	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:UpdateLook()
	if not self:IsVisible() then
		return
	end

	self:UpdatePosition()
	self:UpdateScale()
	self:UpdateOpacity()
	self:UpdateBackdrop()
	self:UpdateBackdropBorder()
	self:UpdateShown()
	self:UpdateFrameLayer()
	self:Layout()
end


--[[
	Frame Scale
--]]

--alter the frame's cale, but maintain the same relative position of the frame
function Frame:UpdateScale()
	local oldScale = self:GetScale()
	local newScale = self:GetFrameScale()

	if oldScale ~= newScale then
		local point, x, y = self:GetFramePosition()
		local ratio = newScale / oldScale

		self:SetScale(newScale)
		self:GetSettings():SetPosition(point, x/ratio, y/ratio)
	end
end

function Frame:GetFrameScale()
	return self:GetSettings():GetScale()
end

--rescale frame without altering position, needed when loading settins
function Frame:Rescale()
	self:SetScale(self:GetFrameScale())
end


--[[
	Frame Opacity
--]]

function Frame:UpdateOpacity()
	self:SetAlpha(self:GetFrameOpacity())
end

function Frame:GetFrameOpacity()
	return self:GetSettings():GetOpacity()
end

function Frame:FadeInFrame(frame, alpha)
	if Addon.Settings:IsFadingEnabled() then
		UIFrameFadeIn(frame, 0.2, 0, alpha or 1)
	end
	
	frame:Show()
end

function Frame:FadeOutFrame(frame)
	if frame then
		frame:Hide()
	end
end


--[[
	Frame Position
--]]

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

		self:GetSettings():SetPosition(yPoint..xPoint, x, y)
	end
end

function Frame:UpdatePosition()
	self:ClearAllPoints()
	self:SetPoint(self:GetFramePosition())
end

function Frame:GetFramePosition()
	return self:GetSettings():GetPosition()
end


--[[
	Frame Color
--]]

--background
function Frame:UpdateBackdrop()
	self:SetBackdropColor(self:GetFrameBackdropColor())
end

function Frame:GetFrameBackdropColor()
	return self:GetSettings():GetColor()
end

--border
function Frame:UpdateBackdropBorder()
	self:SetBackdropBorderColor(self:GetFrameBackdropBorderColor())
end

function Frame:GetFrameBackdropBorderColor()
	return self:GetSettings():GetBorderColor()
end


--[[
	Frame Visibility
--]]

function Frame:UpdateShown()
	if self:IsFrameShown() then
		self:Show()
	else
		self:Hide()
	end
end

function Frame:IsFrameShown()
	return self:GetSettings():IsShown()
end

function Frame:HideFrame()
	self:GetSettings():Hide()
end


--[[
	Frame Layer/Strata
--]]

function Frame:UpdateFrameLayer()
	self:SetFrameLayer(self:GetFrameLayer())
end

function Frame:SetFrameLayer(layer)
	local topLevel, strata = true

	if layer == 'TOPLEVEL' then
		strata = 'HIGH'
	elseif layer == 'MEDIUMLOW' then
		strata = 'LOW'
	elseif layer == 'MEDIUMHIGH' then
		strata = 'MEDIUM'
	else
		strata = layer
		topLevel = false
	end

	self:SetFrameStrata(strata)
	self:SetToplevel(topLevel)
end

function Frame:GetFrameLayer()
	return self:GetSettings():GetLayer()
end


--[[ Layout Methods ]]--

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

	local w, h = self:PlaceItemFrame()
	width = max(w, width)
	height = height + h

	--place bottom menu frames
	local w, h = self:PlaceMoneyFrame()
	width = max(w, width)
	height = height + h

	local w, h = self:PlaceBrokerDisplayFrame()
	if not self:HasMoneyFrame() then
		height = height + h
	end

	--adjust size
	self:SetWidth(max(width, 156) + 16)
	self:SetHeight(height)
end


--[[ Menu Button Placement ]]--

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
		tinsert(menuButtons, self:GetPlayerSelector())
	end
	self:GetSpecificButtons(menuButtons)

	if self:HasSearchToggle() then
		tinsert(menuButtons, self:GetSearchToggle() or self:CreateSearchToggle())
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

function Frame:GetMenuButtons()
	if not self.menuButtons then
		self:PlaceMenuButtons()
	end
	return self.menuButtons
end


--[[ close button ]]--

local function CloseButton_OnClick(self)
	self:GetParent():GetSettings():Hide(true) --force hide the frame
end

function Frame:CreateCloseButton()
	local b = CreateFrame('Button', self:GetName() .. 'CloseButton', self, 'UIPanelCloseButton')
	b:SetScript('OnClick', CloseButton_OnClick)
	self.closeButton = b
	return b
end

function Frame:GetCloseButton()
	return self.closeButton
end

function Frame:PlaceCloseButton()
	local b = self:GetCloseButton() or self:CreateCloseButton()
	b:ClearAllPoints()
	b:SetPoint('TOPRIGHT', -2, -2)
	b:Show()

	return 20, 20 --make the same size as the other menu buttons
end


--[[ search frame ]]--

function Frame:CreateSearchFrame()
	local f = Addon.SearchFrame:New(self:GetFrameID(), self)
	self.searchFrame = f
	return f
end

function Frame:GetSearchFrame()
	return self.searchFrame
end

function Frame:PlaceSearchFrame()
	local menuButtons = self:GetMenuButtons()
	local frame = self:GetSearchFrame() or self:CreateSearchFrame()
	frame:ClearAllPoints()

	if #menuButtons > 0 then
		frame:SetPoint('LEFT', menuButtons[#menuButtons], 'RIGHT', 2, 0)
	else
		frame:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
	end

	if self:HasOptionsToggle() then
		frame:SetPoint('RIGHT', self:GetOptionsToggle(), 'LEFT', -2, 0)
	else
		frame:SetPoint('RIGHT', self:GetCloseButton(), 'LEFT', -2, 0)
	end

	frame:SetHeight(28)

	return frame:GetWidth(), frame:GetHeight()
end


--[[ search toggle ]]--

function Frame:CreateSearchToggle()
	local toggle =  Addon.SearchToggle:New(self:GetFrameID(), self)
	self.searchToggle = toggle
	return toggle
end

function Frame:GetSearchToggle()
	return self.searchToggle
end

function Frame:HasSearchToggle()
	return self:GetSettings():HasSearchToggle()
end


--[[ specific buttons ]]--

function Frame:GetSpecificButtons(list)
	if self:HasBagFrame() then
		tinsert(list, self.bagToggle or self:CreateBagToggle())
	end

	if self:HasSortButton() then
		tinsert(list, self.sortButton or self:CreateSortButton())
	end
end

function Frame:CreateBagToggle()
	local toggle = Addon.BagToggle:New(self:GetFrameID(), self)
	self.bagToggle = toggle
	return toggle
end

function Frame:CreateSortButton()
	local button = Addon.SortButton:New(self)
	self.sortButton = button
	return button
end



--[[ title frame ]]--

function Frame:GetTitleFrame()
	return self.titleFrame or self:CreateTitleFrame()
end

function Frame:CreateTitleFrame()
	local f = Addon.TitleFrame:New(self:GetFrameID(), self.Title, self)
	self.titleFrame = f
	return f
end

function Frame:PlaceTitleFrame()
	local menuButtons = self:GetMenuButtons()
	local frame = self:GetTitleFrame()
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
		frame:SetPoint('RIGHT', self:GetOptionsToggle(), 'LEFT', -4, 0)
	else
		frame:SetPoint('RIGHT', self:GetCloseButton(), 'LEFT', -4, 0)
	end
	frame:SetHeight(20)

	return w, h
end


--[[ player selector ]]--

function Frame:GetPlayerSelector()
	return self.playerSelector or self:CreatePlayerSelector()
end

function Frame:CreatePlayerSelector()
	local f = Addon.PlayerSelector:New(self:GetFrameID(), self)
	self.playerSelector = f
	return f
end

function Frame:HasPlayerSelector()
	return LibStub('LibItemCache-1.1'):HasCache()
end


--[[ bag frame ]]--

function Frame:CreateBagFrame()
	local f =  self.BagFrame:New(self)
	self.bagFrame = f
	return f
end

function Frame:GetBagFrame()
	return self.bagFrame
end

function Frame:HasBagFrame()
	return self:GetSettings():HasBagFrame()
end

function Frame:HasSortButton()
	return self:GetSettings():HasSortButton()
end

function Frame:IsBagFrameShown()
	return self:GetSettings():IsBagFrameShown()
end

function Frame:PlaceBagFrame()
	if self:HasBagFrame() then
		--the bag frame has to be created here to respond to events
		local frame = self:GetBagFrame() or self:CreateBagFrame()
		if self:IsBagFrameShown() then
			frame:ClearAllPoints()

			local menuButtons = self:GetMenuButtons()
			if #menuButtons > 0 then
				frame:SetPoint('TOPLEFT', menuButtons[1], 'BOTTOMLEFT', 0, -4)
			else
				frame:SetPoint('TOPLEFT', self:GetTitleFrame(), 'BOTTOMLEFT', 0, -4)
			end

			frame:Show()

			return frame:GetWidth(), frame:GetHeight() + 4
		else
			frame:Hide()
			return 0, 0
		end
	end

	local frame = self:GetBagFrame()
	if frame then
		frame:Hide()
	end
	return 0, 0
end


--[[ item frame ]]--

function Frame:CreateItemFrame()
	local f = self.ItemFrame:New(self:GetFrameID(), self)
	self.itemFrame = f
	return f
end

function Frame:GetItemFrame()
	return self.itemFrame
end

function Frame:PlaceItemFrame()
	local frame = self:GetItemFrame() or self:CreateItemFrame()
	frame:ClearAllPoints()

	if self:HasBagFrame() and self:IsBagFrameShown() then
		frame:SetPoint('TOPLEFT', self:GetBagFrame(), 'BOTTOMLEFT', 0, -4)
	else
		local menuButtons = self:GetMenuButtons()
		if #menuButtons > 0 then
			frame:SetPoint('TOPLEFT', menuButtons[1], 'BOTTOMLEFT', 0, -4)
		else
			frame:SetPoint('TOPLEFT', self:GetTitleFrame(), 'BOTTOMLEFT', 0, -4)
		end
	end

	frame:Show()
	return frame:GetWidth() - 2, frame:GetHeight()
end


--[[ money frame ]]--

function Frame:CreateMoneyFrame()
	local f = self.MoneyFrame:New(self:GetFrameID(), self)
	self.moneyFrame = f
	return f
end

function Frame:GetMoneyFrame()
	return self.moneyFrame
end

function Frame:HasMoneyFrame()
	return self:GetSettings():HasMoneyFrame()
end

function Frame:PlaceMoneyFrame()
	if self:HasMoneyFrame() then
		local frame = self:GetMoneyFrame() or self:CreateMoneyFrame()
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -(frame.ICON_SIZE or 0) - (frame.ICON_OFF or 0), 4)
		frame:Show()
		return frame:GetSize()
	end

	local frame = self:GetMoneyFrame()
	if frame then
		frame:Hide()
	end
	return 0, 0
end



--[[ libdatabroker display ]]--

function Frame:GetBrokerDisplay()
	return self.brokerDisplay
end

function Frame:CreateBrokerDisplay()
	local f = Addon.BrokerDisplay:New(1, self:GetFrameID(), self)
	self.brokerDisplay = f
	return f
end

function Frame:HasBrokerDisplay()
	return self:GetSettings():HasDBOFrame()
end

function Frame:PlaceBrokerDisplayFrame()
	if self:HasBrokerDisplay() then
		local frame = self:GetBrokerDisplay() or self:CreateBrokerDisplay()
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 8, 10)

		if self:HasMoneyFrame() then
			frame:SetPoint('RIGHT', self:GetMoneyFrame(), 'LEFT', -4, 10)
		else
			frame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -8, 10)
		end

		frame:Show()
		return frame:GetWidth(), 24
	end

	local frame = self:GetBrokerDisplay()
	if frame then
		frame:Hide()
	end
	return 0, 0
end


--[[ options toggle ]]--

function Frame:GetOptionsToggle()
	return self.optionsToggle
end

function Frame:CreateOptionsToggle()
	local f = Addon.OptionsToggle:New(self:GetFrameID(), self)
	self.optionsToggle = f
	return f
end

function Frame:PlaceOptionsToggle()
	if self:HasOptionsToggle() then
		local toggle = self:GetOptionsToggle() or self:CreateOptionsToggle()
		toggle:ClearAllPoints()
		toggle:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -32, -8)
		toggle:Show()

		return toggle:GetWidth(), toggle:GetHeight()
	end

	local toggle = self:GetOptionsToggle()
	if toggle then
		toggle:Hide()
	end
	return 0, 0
end

function Frame:HasOptionsToggle()
	return GetAddOnEnableState(UnitName('player'), ADDON .. '_Config') >= 2 and self:GetSettings():HasOptionsToggle()
end


--[[ Usual Acessor Functions ]]--

function Frame:GetFrameID()
	return self.frameID
end

function Frame:GetSettings()
	return Addon.FrameSettings:Get(self:GetFrameID())
end