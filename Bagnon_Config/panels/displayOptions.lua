--[[
	Frame.lua
		General Bagnon settings
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-Config')
local DisplayOptions = Bagnon.OptionsPanel:New('BagnonOptions_Display', 'Bagnon', L.DisplaySettings, L.DisplaySettingsTitle)
DisplayOptions:Hide()

Bagnon.DisplayOptions = DisplayOptions

local SPACING = 4


--[[
	Startup
--]]

function DisplayOptions:Load()
	self:SetScript('OnShow', self.OnShow)
	self:SetScript('OnHide', self.OnHide)
	self:AddWidgets()
	self:SetFrameID('inventory')
end

function DisplayOptions:ShowFrame(frameID)
	self:SetFrameID(frameID)
	InterfaceOptionsFrame_OpenToCategory(self)
end


--[[
	Messages
--]]

function DisplayOptions:UpdateMessages()
	if self:IsVisible() then
		self:RegisterMessage('FRAME_DISPLAY_EVENT_UPDATE')
	else
		self:UnregisterMessage('FRAME_DISPLAY_EVENT_UPDATE')
	end
end

function DisplayOptions:FRAME_DISPLAY_EVENT_UPDATE(msg, frameID, event, enable)
	if self:GetFrameID() == frameID then
		self:GetDisplayEventCheckbox(event):UpdateChecked()
	end
end


--[[
	Frame Events
--]]

function DisplayOptions:OnShow()
	self:UpdateMessages()
end

function DisplayOptions:OnHide()
	self:UpdateMessages()
end


--[[
	Components
--]]

function DisplayOptions:AddWidgets()
	local displayEvents = {'bank', 'ah', 'vendor', 'trade', 'guildbank', 'craft', 'player'}

	for i, event in ipairs(displayEvents) do
		self:AddDisplayEventCheckbox(event)
	end
end

function DisplayOptions:UpdateWidgets()
	if not self:IsVisible() then
		return
	end

	for i, button in self:GetDisplayEventCheckboxes() do
		button:UpdateChecked()
	end
end


--[[ Check Boxes ]]--

--bag frame
function DisplayOptions:AddDisplayEventCheckbox(event)
	local button = Bagnon.OptionsCheckButton:New(L['EnableAutoDisplay_' .. event], self)
	button.event = event

	button.OnEnableSetting = function(self, enable)
		Bagnon.Settings:SetShowFrameAtEvent(self:GetParent():GetFrameID(), self.event, enable)
	end

	button.IsSettingEnabled = function(self, enable)
		return Bagnon.Settings:IsFrameShownAtEvent(self:GetParent():GetFrameID(), self.event)
	end

	if self.displayEventCheckboxes then
		button:SetPoint('TOPLEFT', self.displayEventCheckboxes[#self.displayEventCheckboxes], 'BOTTOMLEFT', 0, -SPACING)
	else
		self.displayEventCheckboxes = {}
		button:SetPoint('TOPLEFT', self, 'TOPLEFT', 14, -72)
	end

	table.insert(self.displayEventCheckboxes, button)
	return button
end

function DisplayOptions:GetDisplayEventCheckbox(event)
	for i, button in self:GetDisplayEventCheckboxes() do
		if button.event == event then
			return button
		end
	end
	return false
end

function DisplayOptions:GetDisplayEventCheckboxes()
	return ipairs(self.displayEventCheckboxes)
end


--[[
	Update Methods
--]]

function DisplayOptions:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateWidgets()
	end
end

function DisplayOptions:GetFrameID()
	return self.frameID
end


--[[ Load the thing ]]--

DisplayOptions:Load()