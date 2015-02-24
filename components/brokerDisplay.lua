--[[
	brokerDisplay.lua
		A databroker display object
--]]

local ADDON, Addon = ...
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
local BrokerDisplay = Addon:NewClass('BrokerDisplay', 'Button')
local ICON_SIZE = 18

--[[ Constructor ]]--

function BrokerDisplay:New(id, parent)
	local obj = self:Bind(CreateFrame('Button', nil, parent))
	obj:RegisterForClicks('anyUp')
	obj:SetID(id)

	obj.left = obj:CreateLeftButton()
	obj.left:SetPoint('LEFT')
	obj.right = obj:CreateRightButton()
	obj.right:SetPoint('RIGHT')
	obj.icon = obj:AddIcon()
	obj.icon:SetPoint('LEFT', obj.left, 'RIGHT')
	obj.text = obj:AddText()

	obj:SetScript('OnShow', obj.OnShow)
	obj:SetScript('OnHide', obj.OnHide)
	obj:SetScript('OnEnter', obj.OnEnter)
	obj:SetScript('OnLeave', obj.OnLeave)
	obj:SetScript('OnClick', obj.OnClick)
	obj:SetScript('OnMouseWheel', obj.OnMouseWheel)

	obj:SetHeight(13)
	obj:EnableMouseWheel(true)
	obj:UpdateEverything()

	return obj
end

function BrokerDisplay:AddIcon()
	local texture = self:CreateTexture(nil, 'OVERLAY')
	texture:SetSize(ICON_SIZE, ICON_SIZE)

	return texture
end

function BrokerDisplay:AddText()
	local text = self:CreateFontString()
	text:SetFontObject('NumberFontNormalRight')
	text:SetJustifyH('LEFT')

	return text
end


--[[
	Broker Selection Buttons
--]]

function BrokerDisplay:CreateLeftButton()
	local b = CreateFrame('Button', nil, self)

	b:SetNormalFontObject('GameFontNormal')
	b:SetHighlightFontObject('GameFontHighlight')
	b:SetText('<')
	b:SetWidth(b:GetTextWidth() + 4)
	b:SetHeight(b:GetTextHeight())
	b:SetScript('OnClick', function(self) self:GetParent():SetPreviousObject() end)
	b:SetToplevel(true)

	return b
end

function BrokerDisplay:CreateRightButton()
	local b = CreateFrame('Button', nil, self)
	b:SetSize(ICON_SIZE, ICON_SIZE)

	b:SetNormalFontObject('GameFontNormal')
	b:SetHighlightFontObject('GameFontHighlight')
	b:SetText('>')
	b:SetWidth(b:GetTextWidth() + 2)
	b:SetHeight(b:GetTextHeight())
	b:SetScript('OnClick', function(self) self:GetParent():SetNextObject() end)
	b:SetToplevel(true)

	return b
end


--[[ Messages ]]--

function BrokerDisplay:LibDataBroker_DataObjectCreated(msg, name, dataobj)
	if self:GetObjectName() == name then
		self:UpdateDisplay()
	end
end

function BrokerDisplay:LibDataBroker_AttributeChanged(msg, name, attr, value, dataobj)
	if self:GetObjectName() == name then
		if attr == 'icon' then
			self:UpdateIcon()
		elseif attr == 'text' then
			self:UpdateText()
		end
	end
end


--[[ Frame Events ]]--

function BrokerDisplay:OnEnter()
	local dbo = self:GetObject()
	if not dbo then return end

	if dbo.OnEnter then
		dbo.OnEnter(self)
	elseif dbo.OnTooltipShow then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:ClearLines()

		dbo.OnTooltipShow(GameTooltip)

		GameTooltip:Show()
	else
		GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
		GameTooltip:ClearLines()
		GameTooltip:SetText(self:GetObjectName())
		GameTooltip:Show()
	end
end

function BrokerDisplay:OnLeave()
	local dbo = self:GetObject()
	if not dbo then return end

	if dbo.OnLeave then
		dbo.OnLeave(self)
	else
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end
	end
end

function BrokerDisplay:OnClick(...)
	local dbo = self:GetObject()
	if dbo and dbo.OnClick then
		dbo.OnClick(self, ...)
	end
end

function BrokerDisplay:OnShow()
	self:UpdateEverything()
end

function BrokerDisplay:OnHide()
	self:UpdateEvents()
end

function BrokerDisplay:OnMouseWheel(direction)
	if direction > 0 then
		self:SetNextObject()
	else
		self:SetPreviousObject()
	end
end


--[[ Update Methods ]]--

function BrokerDisplay:UpdateEverything()
	self:UpdateEvents()
	self:UpdateDisplay()
end

function BrokerDisplay:UpdateEvents()
	LDB.UnregisterAllCallbacks(self)

	if self:IsVisible() then
		LDB.RegisterCallback(self, 'LibDataBroker_DataObjectCreated')
		LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged')
	end
end

function BrokerDisplay:UpdateDisplay()
	self:UpdateIcon()
	self:UpdateText()
end

function BrokerDisplay:UpdateText()
	local obj = self:GetObject()
	local text

	if obj then
		text = obj.text or obj.label or ''
	else
		text = 'Select Databroker Plugin'
	end

	self.text:SetText(text)
	self:Layout()
end

function BrokerDisplay:UpdateIcon()
	local obj = self:GetObject()
	local icon = obj and obj.icon

	if icon then
		self.icon:SetTexture(icon)
		self.icon:Show()
	else
		self.icon:Hide()
	end

	self:Layout()
end

function BrokerDisplay:Layout()
	if self.icon:IsShown() then
		self.text:SetPoint('LEFT', self.icon, 'RIGHT', 2, 0)
		self.text:SetPoint('RIGHT', self.right, 'LEFT', -2, 0)
	else
		self.text:SetPoint('LEFT', self.left, 'RIGHT', 2, 0)
		self.text:SetPoint('RIGHT', self.right, 'LEFT', -2, 0)
	end

	self:UpdateInsets()
end

--calculate the clickable portion of the frame
function BrokerDisplay:UpdateInsets()
	local realWidth = self.left:GetWidth()

	if self.text:IsShown() then
		realWidth = realWidth + (self.text:GetStringWidth() or 0)
	end

	if self.icon:IsShown() then
		realWidth = realWidth + (self.icon:GetWidth() or 0)
	end

	self:SetHitRectInsets(0, self:GetWidth() - realWidth, 0, 0)
end


--[[ Display Object Updating ]]--


function BrokerDisplay:SetNextObject()
	local objects = self:GetAvailableObjects()
	local current = self:GetObjectName()

	for i, object in ipairs(objects) do
		if current == object then
			self:SetObject(objects[(i % #objects) + 1])
			return
		end
	end
end

function BrokerDisplay:SetPreviousObject()
	local objects = self:GetAvailableObjects()
	local current = self:GetObjectName()

	for i, object in ipairs(objects) do
		if current == object then
			self:SetObject(objects[i == 1 and #objects or i - 1])
			return
		end
	end
end

function BrokerDisplay:SetObject(name)
	self:GetProfile().brokerObject = name
	self:UpdateDisplay()

	if GameTooltip:IsOwned(self) then
		self:OnEnter()
	end
end

function BrokerDisplay:GetObject()
	return LDB:GetDataObjectByName(self:GetObjectName())
end

function BrokerDisplay:GetObjectName()
	return self:GetProfile().brokerObject
end

do
	local objects = {}

	function BrokerDisplay:GetAvailableObjects()
		wipe(objects)

		for name, obj in LDB:DataObjectIterator() do
			tinsert(objects, name)
		end
		sort(objects)

		return objects
	end
end