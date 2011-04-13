--[[
	frameSettings.lua
		A bagnon frame settings object
--]]

local FrameSettings = {}
local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
Bagnon.FrameSettings = FrameSettings


--[[---------------------------------------------------------------------------
	Constructorish
--]]---------------------------------------------------------------------------

FrameSettings.mt = {
	__index = FrameSettings
}

FrameSettings.objects = setmetatable({}, {__index = function(tbl, id)
	local obj = setmetatable({frameID = id, shown = 0}, FrameSettings.mt)
	tbl[id] = obj
	return obj
end})

function FrameSettings:Get(id)
	return self.objects[id]
end


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------


function FrameSettings:GetID()
	return self.frameID
end

function FrameSettings:GetDB()
	local db = self.db or Bagnon.SavedFrameSettings:Get(self:GetID())
	self.db = db
	return db
end


--[[---------------------------------------------------------------------------
	Message Passing
--]]---------------------------------------------------------------------------

function FrameSettings:SendMessage(msg, ...)
	Bagnon.Callbacks:SendMessage(msg, self:GetID(), ...)
end


--[[---------------------------------------------------------------------------
	Update Methods
--]]---------------------------------------------------------------------------


--[[ Frame Visibility ]]--

--the logic here is a little wacky, since we deal with auto open/close events
--if a frame was manually opened, then it should only be closable manually
function FrameSettings:Show()
	local wasShown = self:IsShown()

	self.shown = (self.shown or 0) + 1
	if not wasShown then
		self:SendMessage('FRAME_SHOW')
	end
end

function FrameSettings:Hide(forceHide)
	self.shown = (self.shown or 1) - 1

	if forceHide or self.shown <= 0 then
		self.shown = 0

		--reset player filter on hide
		self:SetPlayerFilter(UnitName('player'))
		self:SendMessage('FRAME_HIDE')
	end
end

function FrameSettings:Toggle()
	if self:IsShown() then
		self:Hide(true)
	else
		self:Show()
	end
end

function FrameSettings:IsShown()
	return (self.shown or 0) > 0
end


--[[ Frame Position ]]--

--position
function FrameSettings:SetPosition(point, x, y)
	local oPoint, oX, oY = self:GetPosition()

	if not(point == oPoint and x == oX and y == oY) then
		self:GetDB():SetPosition(point, x, y)
		self:SendMessage('FRAME_POSITION_UPDATE', self:GetPosition())
	end
end

function FrameSettings:GetPosition()
	local point, x, y = self:GetDB():GetPosition()
	return point, x, y
end

function FrameSettings:IsMovable()
	return not Bagnon.Settings:AreFramePositionsLocked()
end


--[[ Frame Layout ]]--

--scale
function FrameSettings:SetScale(scale)
	if self:GetScale() ~= scale then
		self:GetDB():SetScale(scale)
		self:SendMessage('FRAME_SCALE_UPDATE', self:GetScale())
	end
end

function FrameSettings:GetScale()
	return self:GetDB():GetScale()
end

--opacity
function FrameSettings:SetOpacity(opacity)
	if self:GetOpacity() ~= opacity then
		self:GetDB():SetOpacity(opacity)
		self:SendMessage('FRAME_OPACITY_UPDATE', self:GetOpacity())
	end
end

function FrameSettings:GetOpacity()
	return self:GetDB():GetOpacity()
end

--frame color
function FrameSettings:SetColor(r, g, b, a)
	local pR, pG, pB, pA = self:GetColor()

	if not(pR == r and pG == g and pB == b and pA == a) then
		self:GetDB():SetColor(r, g, b, a)
		self:SendMessage('FRAME_COLOR_UPDATE', self:GetColor())
	end
end

function FrameSettings:GetColor()
	return self:GetDB():GetColor()
end

--border color
function FrameSettings:SetBorderColor(r, g, b, a)
	local pR, pG, pB, pA = self:GetBorderColor()

	if not(pR == r and pG == g and pB == b and pA == a) then
		self:GetDB():SetBorderColor(r, g, b, a)
		self:SendMessage('FRAME_BORDER_COLOR_UPDATE', self:GetBorderColor())
	end
end

function FrameSettings:GetBorderColor()
	return self:GetDB():GetBorderColor()
end

--frame layer
function FrameSettings:SetLayer(layer)
	if self:GetLayer() ~= layer then
		self:GetDB():SetLayer(layer)
		self:SendMessage('FRAME_LAYER_UPDATE', self:GetLayer())
	end
end

function FrameSettings:GetLayer()
	return self:GetDB():GetLayer()
end

--returns a list of all possible frame layers
function FrameSettings:GetAvailableLayers()
	if not FrameSettings.availableFrameLayers then
		FrameSettings.availableFrameLayers = {'LOW', 'MEDIUMLOW', 'MEDIUM', 'MEDIUMHIGH', 'HIGH', 'TOPLEVEL'}
	end
	return FrameSettings.availableFrameLayers
end


--[[ Frame Components ]]--

--returns true if the frame has a bag frame, and false otherwise
function FrameSettings:SetHasBagFrame(enable)
	local enable = enable and true or false --done to handle 1/nil cases

	if self:HasBagFrame() ~= enable then
		self:GetDB():SetHasBagFrame(enable)
		self:SendMessage('BAG_FRAME_ENABLE_UPDATE', self:HasBagFrame())
	end
end

function FrameSettings:HasBagFrame()
	return self:GetDB():HasBagFrame()
end

--returns true if the frame has a money frame, and false otherwise
function FrameSettings:SetHasMoneyFrame(enable)
	local enable = enable and true or false

	if self:HasMoneyFrame() ~= enable then
		self:GetDB():SetHasMoneyFrame(enable)
		self:SendMessage('MONEY_FRAME_ENABLE_UPDATE', self:HasMoneyFrame())
	end
end

function FrameSettings:HasMoneyFrame()
	return self:GetDB():HasMoneyFrame()
end

--returns true if the frame has a databroker object frame, and false otherwise
function FrameSettings:SetHasDBOFrame(enable)
	local enable = enable and true or false

	if self:HasDBOFrame() ~= enable then
		self:GetDB():SetHasDBOFrame(enable)
		self:SendMessage('DATABROKER_FRAME_ENABLE_UPDATE', self:HasDBOFrame())
	end
end

function FrameSettings:HasDBOFrame()
	return self:GetDB():HasDBOFrame()
end

--returns true if the search frame TOGGLE is shown, and false otherwise
function FrameSettings:SetHasSearchToggle(enable)
	local enable = enable and true or false

	if self:HasSearchToggle() ~= enable then
		self:GetDB():SetHasSearchToggle(enable)
		self:SendMessage('SEARCH_TOGGLE_ENABLE_UPDATE', self:HasSearchToggle())
	end
end

function FrameSettings:HasSearchToggle()
	return self:GetDB():HasSearchToggle()
end

--options toggle
function FrameSettings:SetHasOptionsToggle(enable)
	local enable = enable and true or false

	if self:HasOptionsToggle() ~= enable then
		self:GetDB():SetHasOptionsToggle(enable)
		self:SendMessage('OPTIONS_TOGGLE_ENABLE_UPDATE', self:HasOptionsToggle())
	end
end

function FrameSettings:HasOptionsToggle()
	return self:GetDB():HasOptionsToggle()
end


--[[ Broker Display Object ]]--

function FrameSettings:SetBrokerDisplayObject(objectName)
	if self:GetBrokerDisplayObject() ~= objectName then
		self:GetDB():SetBrokerDisplayObject(objectName)
		self:SendMessage('DATABROKER_OBJECT_UPDATE', self:GetBrokerDisplayObject())
	end
end

function FrameSettings:GetBrokerDisplayObject()
	return self:GetDB():GetBrokerDisplayObject()
end


--[[ Bag Frame Visibility ]]--

function FrameSettings:ShowBagFrame()
	if not self:IsBagFrameShown() then
		self.showBagFrame = true
		self:SendMessage('BAG_FRAME_SHOW')
	end
end

function FrameSettings:HideBagFrame()
	if self:IsBagFrameShown() then
		self.showBagFrame = false
		self:SendMessage('BAG_FRAME_HIDE')
	end
end

function FrameSettings:ToggleBagFrame()
	if self:IsBagFrameShown() then
		self:HideBagFrame()
	else
		self:ShowBagFrame()
	end
end

function FrameSettings:IsBagFrameShown()
	return self.showBagFrame
end


--[[ Item Frame Layout ]]--

--spacing
function FrameSettings:SetItemFrameSpacing(spacing)
	if self:GetItemFrameSpacing() ~= spacing then
		self:GetDB():SetItemFrameSpacing(spacing)
		self:SendMessage('ITEM_FRAME_SPACING_UPDATE', self:GetItemFrameSpacing())
	end
end

function FrameSettings:GetItemFrameSpacing()
	return self:GetDB():GetItemFrameSpacing()
end

--columns
function FrameSettings:SetItemFrameColumns(columns)
	if self:GetItemFrameColumns() ~= columns then
		self:GetDB():SetItemFrameColumns(columns)
		self:SendMessage('ITEM_FRAME_COLUMNS_UPDATE', self:GetItemFrameColumns())
	end
end

function FrameSettings:GetItemFrameColumns()
	return self:GetDB():GetItemFrameColumns()
end

--bag break layout
function FrameSettings:SetBagBreak(enable)
	local enable = enable and true or false

	if self:IsBagBreakEnabled() ~= enable then
		self:GetDB():SetBagBreak(enable)
		self:SendMessage('ITEM_FRAME_BAG_BREAK_UPDATE', self:IsBagBreakEnabled())
	end
end

function FrameSettings:IsBagBreakEnabled()
	return self:GetDB():IsBagBreakEnabled()
end


--[[ Bag Slot Availability ]]--

--returns true if the slot is available to this frame, and false otherwise
function FrameSettings:HasBagSlot(slot)
	for i, bagSlot in self:GetBagSlots() do
		if bagSlot == slot then
			return true
		end
	end
	return false
end

--returns an iterator for all bag slots available to this frame
function FrameSettings:GetBagSlots()
	return ipairs(self:GetDB():GetBags())
end


--[[ Bag Slot Visibility ]]--

function FrameSettings:ShowBagSlot(slotToShow)
	if not self:IsBagSlotShown(slotToShow) then
		self:GetDB():ShowBag(slotToShow)
		self:SendMessage('BAG_SLOT_SHOW', slotToShow)
	end
end

function FrameSettings:HideBagSlot(slotToHide)
	if self:IsBagSlotShown(slotToHide) then
		self:GetDB():HideBag(slotToHide)
		self:SendMessage('BAG_SLOT_HIDE', slotToHide)
	end
end

function FrameSettings:ToggleBagSlot(slot)
	if self:IsBagSlotShown(slot) then
		self:HideBagSlot(slot)
	else
		self:ShowBagSlot(slot)
	end
end

function FrameSettings:IsBagSlotShown(slot)
	for i, bagSlot in self:GetVisibleBagSlots() do
		if bagSlot == slot then
			return true
		end
	end
	return false
end

function FrameSettings:IsBagSlotHidden(slot)
	return not self:GetDB():IsBagShown(slot)
end


--[[ Bag Slot Iterators ]]--

--returns an iterator for all bag slots that are available to this frame and marked as visible
local function reverseVisibleSlotIterator(obj, i)
	local bagSlots = obj:GetDB():GetBags()
	local nextSlot = i - 1

	for j = nextSlot, 1, -1 do
		local slot = bagSlots[j]
		if not obj:IsBagSlotHidden(slot) then
			return j, slot
		end
	end
end

local function visibleSlotIterator(obj, i)
	local bagSlots = obj:GetDB():GetBags()
	local nextSlot = i + 1

	for j = nextSlot, #bagSlots do
		local slot = bagSlots[j]
		if not obj:IsBagSlotHidden(slot) then
			return j, slot
		end
	end
end

function FrameSettings:GetVisibleBagSlots()
	if self:IsSlotOrderReversed() then
		local bagSlots = self:GetDB():GetBags()
		return reverseVisibleSlotIterator, self, #bagSlots + 1
	end
	return visibleSlotIterator, self, 0
end


function FrameSettings:SetReverseSlotOrder(enable)
	local enable = enable and true or false
	if self:IsSlotOrderReversed() ~= enable then
		self:GetDB():SetReverseSlotOrder(enable)
		self:SendMessage('SLOT_ORDER_UPDATE', self:IsSlotOrderReversed())
	end
end

function FrameSettings:IsSlotOrderReversed()
	return self:GetDB():IsSlotOrderReversed()
end


--[[ Text Filtering ]]--

function FrameSettings:EnableTextSearch()
	if not self:IsTextSearchEnabled() then
		self.enableTextSearch = true
		self:SendMessage('TEXT_SEARCH_ENABLE')
	end
end

function FrameSettings:DisableTextSearch()
	if self:IsTextSearchEnabled() then
		self.enableTextSearch = false
		self:SendMessage('TEXT_SEARCH_DISABLE')
	end
end

function FrameSettings:ToggleTextSearch()
	if self:IsTextSearchEnabled() then
		self:DisableTextSearch()
	else
		self:EnableTextSearch()
	end
end

function FrameSettings:IsTextSearchEnabled()
	return self.enableTextSearch
end


--[[ Bag Filtering ]]--

function FrameSettings:SetBagSearch(bagSlotID)
	if self:GetBagSearch() ~= bagSlotID then
		self.bagSearch = bagSlotID
		self:SendMessage('BAG_SEARCH_UPDATE', self:GetBagSearch())
	end
end

function FrameSettings:GetBagSearch()
	return self.bagSearch or false
end


--[[ Player Filtering ]]--

function FrameSettings:SetPlayerFilter(player)
	local currentFilter = self:GetPlayerFilter()
	if currentFilter ~= player then
		self.playerFilter = player
		self:SendMessage('PLAYER_UPDATE', self:GetPlayerFilter())
	end
end

function FrameSettings:GetPlayerFilter()
	return self.playerFilter or UnitName('player')
end