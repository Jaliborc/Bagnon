--[[
	brokerDisplay.lua
		A databroker display object
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local BrokerDisplay = Bagnon.Classy:New('Button')
BrokerDisplay:Hide()
Bagnon.BrokerDisplay = BrokerDisplay

local ICON_SIZE = 18


--[[ Constructor ]]--

function BrokerDisplay:New(id, frameID, parent)
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

	obj:SetFrameID(frameID)
	obj:SetHeight(13)
	obj:EnableMouseWheel(true)
	obj:UpdateInsets()

	return obj
end

function BrokerDisplay:AddIcon()
	local texture = self:CreateTexture(nil, 'OVERLAY')
	texture:SetWidth(ICON_SIZE)
	texture:SetHeight(ICON_SIZE)

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
	b:SetWidth(ICON_SIZE)
	b:SetHeight(ICON_SIZE)

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

function BrokerDisplay:DATABROKER_OBJECT_UPDATE(msg, frameID, objectName)
	if self:GetFrameID() == frameID then
		self:UpdateDisplay()

		if GameTooltip:IsOwned(self) then
			self:OnEnter()
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
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if LDB then
		LDB.UnregisterAllCallbacks(self)
		if self:IsVisible() then
			LDB.RegisterCallback(self, 'LibDataBroker_DataObjectCreated')
			LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged')
		end
	end

	self:UnregisterAllMessages()
	if self:IsVisible() then
		self:RegisterMessage('DATABROKER_OBJECT_UPDATE')
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
		text = obj.text or ''
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

function BrokerDisplay:SetObject(objectName)
	self:GetSettings():SetBrokerDisplayObject(objectName)
end

function BrokerDisplay:GetObject()
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if LDB then
		return LDB:GetDataObjectByName(self:GetObjectName())
	end
	return nil
end

function BrokerDisplay:GetObjectName()
	return self:GetSettings():GetBrokerDisplayObject()
end

function BrokerDisplay:SetNextObject()
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if not LDB then return end

	local currObjName = self:GetObjectName()
	local prevObjName = nil

	for i, nextObjName in self:GetAvailableObjects() do
		if currObjName == prevObjName then
			self:SetObject(nextObjName)
			return
		end
		prevObjName = nextObjName
	end

	for i, nextObjName in self:GetAvailableObjects() do
		if currObjName == prevObjName then
			self:SetObject(nextObjName)
			return
		end
		prevObjName = nextObjName
	end

	self:SetObject(prevObjName)
end

function BrokerDisplay:SetPreviousObject()
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if not LDB then return end

	local currObjName = self:GetObjectName()
	local prevObjName = nil

	for i, nextObjName in self:GetAvailableObjects() do
		if prevObjName and (currObjName == nextObjName) then
			self:SetObject(prevObjName)
			return
		end
		prevObjName = nextObjName
	end

	for i, nextObjName in self:GetAvailableObjects() do
		if prevObjName and (currObjName == nextObjName) then
			self:SetObject(prevObjName)
			return
		end
		prevObjName = nextObjName
	end

	self:SetObject(prevObjName)
end

do
	local objects = {}
	function BrokerDisplay:GetAvailableObjects()
		if next(objects) ~= nil then
			for k, v in pairs(objects) do
				objects[k] = nil
			end
		end

		local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
		if LDB then
			for name, obj in LDB:DataObjectIterator() do
				table.insert(objects, name)
			end
		end
		table.sort(objects)

		return ipairs(objects)
	end
end


--[[ Properties ]]--

function BrokerDisplay:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateEverything()
	end
end

function BrokerDisplay:GetFrameID()
	return self.frameID
end

function BrokerDisplay:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end