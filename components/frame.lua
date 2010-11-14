--[[
	frame.lua
		A Bagnon frame widget
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local Frame = Bagnon.Classy:New('Frame')
Frame:Hide()
Bagnon.Frame = Frame


--[[
	Constructor
--]]

function Frame:New(frameID)
	local f = self:Bind(CreateFrame('Frame', 'BagnonFrame' .. frameID, UIParent))
	f:Hide()
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)

	f:SetBackdrop{
	  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	  edgeSize = 16,
	  tile = true, tileSize = 16,
	  insets = {left = 4, right = 4, top = 4, bottom = 4}
	}

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f.frameID = frameID
	f:Rescale()
	f:UpdateEverything()

	table.insert(UISpecialFrames, f:GetName())

	return f
end


--[[
	Frame Messages
--]]

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
	end
end

function Frame:FRAME_SHOW(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Show()
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

function Frame:FRAME_MOVE_STOP(msg, frameID)
	if self:GetFrameID() == frameID then
		self:StopMovingOrSizing()
		self:SavePosition()
	end
end

function Frame:FRAME_POSITION_UPDATE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdatePosition()
	end
end

function Frame:FRAME_SCALE_UPDATE(msg, frameID, scale)
	if self:GetFrameID() == frameID then
		self:UpdateScale()
	end
end

function Frame:FRAME_OPACITY_UPDATE(msg, frameID, opacity)
	if self:GetFrameID() == frameID then
		self:UpdateOpacity()
	end
end

function Frame:FRAME_COLOR_UPDATE(msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:UpdateBackdrop()
	end
end

function Frame:FRAME_BORDER_COLOR_UPDATE(msg, frameID, r, g, b, a)
	if self:GetFrameID() == frameID then
		self:UpdateBackdropBorder()
	end
end

function Frame:BAG_FRAME_UPDATE_SHOWN(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:BAG_FRAME_UPDATE_LAYOUT(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:ITEM_FRAME_SIZE_CHANGE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:FRAME_LAYER_UPDATE(msg, frameID, layer)
	if self:GetFrameID() == frameID then
		self:SetFrameLayer(layer)
	end
end

function Frame:BAG_FRAME_ENABLE_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:MONEY_FRAME_ENABLE_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:DATABROKER_FRAME_ENABLE_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:SEARCH_TOGGLE_ENABLE_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end

function Frame:OPTIONS_TOGGLE_ENABLE_UPDATE(msg, frameID, enable)
	if self:GetFrameID() == frameID then
		self:Layout()
	end
end


--[[
	Frame Events
--]]

function Frame:OnShow()
	PlaySound('igBackPackOpen')

	self:UpdateEvents()
	self:UpdateLook()
end

function Frame:OnHide()
	PlaySound('igBackPackClose')

	if self:IsBankFrame() then
		self:CloseBankFrame()
	end

	self:UpdateEvents()

	--fix issue where a frame is hidden, but not via bagnon controlled methods (ie, close on escape)
	if self:IsFrameShown() then
		self:HideFrame()
	end
end

function Frame:CloseBankFrame()
	if Bagnon.PlayerInfo:AtBank() then
		CloseBankFrame()
	end
end

function Frame:IsBankFrame()
	return self:GetFrameID() == 'bank'
end


--[[
	Update Methods
--]]

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


--[[
	Frame Position
--]]

--position
function Frame:SavePosition()
	local point, x, y = self:GetRelativePosition()
	if point then
		self:GetSettings():SetPosition(point, x, y)
	end
end

--get a frame's position relative to its parent
function Frame:GetRelativePosition()
	local parent = self:GetParent()
	local w, h = parent:GetWidth(), parent:GetHeight()
	local x, y = self:GetCenter()
	local s = self:GetScale()
	if not (x and y) then return end

	w = w/s h = h/s

	local dx, dy
	local hHalf = (x > w/2) and 'RIGHT' or 'LEFT'
	if hHalf == 'RIGHT' then
		dx = self:GetRight() - w
	else
		dx = self:GetLeft()
	end

	local vHalf = (y > h/2) and 'TOP' or 'BOTTOM'
	if vHalf == 'TOP' then
		dy = self:GetTop() - h
	else
		dy = self:GetBottom()
	end

	return vHalf..hHalf, dx, dy
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
	local strata, topLevel = nil, false

	if layer == 'TOPLEVEL' then
		strata = 'HIGH'
		topLevel = true
	elseif layer == 'MEDIUMLOW' then
		strata = 'LOW'
		topLevel = true
	elseif layer == 'MEDIUMHIGH' then
		strata = 'MEDIUM'
		topLevel = true
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


--[[
	Layout Methods
--]]

--place components & update size
function Frame:Layout()
	if not self:IsVisible() then
		return
	end

	local padW = 16
	local padH = 16
	local width, height = 0, 0

	--place menu butons, this determines our base width
	local w, h = self:PlaceMenuButtons()
	width = width + w

	local w, h = self:PlaceCloseButton()
	width = width + w

	local w, h = self:PlaceOptionsToggle()
	width = width + w + 24 --append spacing between close button and this
	height = height + 20

	local w, h = self:PlaceTitleFrame()
	width = width + w

	local w, h = self:PlaceSearchFrame()

	--place the middle frames
	local w, h = self:PlaceBagFrame()
	width = math.max(w, width)
	height = height + h

	local w, h = self:PlaceItemFrame()
	width = math.max(w, width)
	height = height + h

	--place the bottom menu frames
	local w, h = self:PlaceMoneyFrame()
	width = math.max(w, width)
	height = height + h

	local w, h = self:PlaceBrokerDisplayFrame()
	if not self:HasMoneyFrame() then
		height = height + h
	end

	--adjust size
	self:SetWidth(math.max(width, 156) + padW)
	self:SetHeight(height + padH)
	self:SavePosition()
end


--[[ Menu Button Placement ]]--

function Frame:PlaceMenuButtons()
	local menuButtons = self.menuButtons or {}
	self.menuButtons = menuButtons

	--hide the old buttons
	for i, button in pairs(menuButtons) do
		button:Hide()
		menuButtons[i] = nil
	end

	if self:HasPlayerSelector() then
		local selector = self:GetPlayerSelector() or self:CreatePlayerSelector()
		table.insert(menuButtons, selector)
	end

	if self:HasBagFrame() and self:HasBagToggle() then
		local toggle = self:GetBagToggle() or self:CreateBagToggle()
		table.insert(menuButtons, toggle)
	end

	if self:HasSearchToggle() then
		local toggle = self:GetSearchToggle() or self:CreateSearchToggle()
		table.insert(menuButtons, toggle)
	end

	for i, button in ipairs(menuButtons) do
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -8)
		else
			button:SetPoint('TOPLEFT', menuButtons[i-1], 'TOPRIGHT', 4, 0)
		end
		button:Show()
	end

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


--[[
	Frame Components
--]]


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
	local f = Bagnon.SearchFrame:New(self:GetFrameID(), self)
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
	local toggle =  Bagnon.SearchToggle:New(self:GetFrameID(), self)
	self.searchToggle = toggle
	return toggle
end

function Frame:GetSearchToggle()
	return self.searchToggle
end

function Frame:HasSearchToggle()
	return self:GetSettings():HasSearchToggle()
end


--[[ bag frame ]]--

function Frame:CreateBagFrame()
	local f =  Bagnon.BagFrame:New(self:GetFrameID(), self)
	self.bagFrame = f
	return f
end

function Frame:GetBagFrame()
	return self.bagFrame
end

function Frame:HasBagFrame()
	return self:GetSettings():HasBagFrame()
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


--[[ bag toggle ]]--

function Frame:CreateBagToggle()
	local toggle = Bagnon.BagToggle:New(self:GetFrameID(), self)
	self.bagToggle = toggle
	return toggle
end

function Frame:GetBagToggle()
	return self.bagToggle
end

--this exists purely so that it can be overridden by guildBank
function Frame:HasBagToggle()
	return true
end


--[[ title frame ]]--

function Frame:CreateTitleFrame()
	local f = Bagnon.TitleFrame:New(self:GetFrameID(), self)
	self.titleFrame = f
	return f
end

function Frame:GetTitleFrame()
	return self.titleFrame
end

function Frame:PlaceTitleFrame()
	local menuButtons = self:GetMenuButtons()
	local frame = self:GetTitleFrame() or self:CreateTitleFrame()
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


--[[ item frame ]]--

function Frame:CreateItemFrame()
	local f = Bagnon.ItemFrame:New(self:GetFrameID(), self)
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


--[[ player selector ]]--

function Frame:GetPlayerSelector()
	return self.playerSelector
end

function Frame:CreatePlayerSelector()
	local f = Bagnon.PlayerSelector:New(self:GetFrameID(), self)
	self.playerSelector = f
	return f
end

function Frame:HasPlayerSelector()
	return BagnonDB and true or false
end


--[[ money frame ]]--

function Frame:GetMoneyFrame()
	return self.moneyFrame
end

function Frame:CreateMoneyFrame()
	local f = Bagnon.MoneyFrame:New(self:GetFrameID(), self)
	self.moneyFrame = f
	return f
end

function Frame:HasMoneyFrame()
	return self:GetSettings():HasMoneyFrame()
end

function Frame:PlaceMoneyFrame()
	if self:HasMoneyFrame() then
		local frame = self:GetMoneyFrame() or self:CreateMoneyFrame()
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 10)
		frame:Show()
		return frame:GetWidth(), 24
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
	local f = Bagnon.BrokerDisplay:New(1, self:GetFrameID(), self)
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
			frame:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -(self:GetMoneyFrame():GetWidth() + 4), 10)
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
	local f = Bagnon.OptionsToggle:New(self:GetFrameID(), self)
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
	local name, title, notes, enabled = GetAddOnInfo('Bagnon_Config')
	return enabled and self:GetSettings():HasOptionsToggle()
end


--[[
	Frame Settings Access
--]]

function Frame:GetFrameID()
	return self.frameID
end

function Frame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end