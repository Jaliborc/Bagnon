--[[
	searchFrame.lua
		A searcn frame widget
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local SearchFrame = Bagnon.Classy:New('EditBox')
SearchFrame:Hide()

Bagnon.SearchFrame = SearchFrame

SearchFrame.backdrop = {
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	insets = {
		left = 2,
		right = 2,
		top = 2,
		bottom = 2
	},
	tile = true,
	tileSize = 16,
	edgeSize = 16,
}

function SearchFrame:New(frameID, parent)
	local f = self:Bind(CreateFrame('EditBox', nil, parent))
	f:SetToplevel(true)
	f:Hide()

	f:SetFrameStrata('DIALOG')
	f:SetTextInsets(8, 8, 0, 0)
	f:SetFontObject('ChatFontNormal')

	f:SetBackdrop(f.backdrop)
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(1, 1, 1, 0.8)

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:SetScript('OnTextChanged', f.OnTextChanged)
	f:SetScript('OnEscapePressed', f.OnEscapePressed)
	f:SetScript('OnEnterPressed', f.OnEnterPressed)

	f:SetFrameID(frameID)
	f:UpdateEvents()
	f:SetAutoFocus(false)
--	f:UpdateShown()
--	f:UpdateText()

	return f
end

--[[ Messages ]]--

function SearchFrame:TEXT_SEARCH_ENABLE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdateShown()
	end
end

function SearchFrame:TEXT_SEARCH_DISABLE(msg, frameID)
	if self:GetFrameID() == frameID then
		self:UpdateShown()
	end
end

function SearchFrame:TEXT_SEARCH_UPDATE(msg, search)
	self:UpdateText()
end


--[[ Frame Events ]]--

function SearchFrame:OnShow()
	self:UpdateEvents()
	self:SetSearch(self:GetLastSearch())
	self:HighlightText()
	self:SetFocus()
end

function SearchFrame:OnHide()
	self:UpdateEvents()
	
	self:ClearFocus()
	self:SetSearch('')
end

function SearchFrame:OnTextChanged()
	self:SetSearch(self:GetText())
end

function SearchFrame:OnEscapePressed()
	self:DisableSearch()
end

function SearchFrame:OnEnterPressed()
	self:DisableSearch()
end


--[[ Update Methods ]]--

function SearchFrame:UpdateEvents()
	self:UnregisterAllMessages()

	self:RegisterMessage('TEXT_SEARCH_ENABLE')
	self:RegisterMessage('TEXT_SEARCH_DISABLE')
--[[	
	if self:IsVisible() then
		self:RegisterMessage('TEXT_SEARCH_UPDATE')
	end
--]]
end

function SearchFrame:UpdateShown()
	if self:IsSearchEnabled() then
		if not self:IsShown() then
			UIFrameFadeIn(self, 0.1)
		end
	else
		self:Hide()
	end
end

function SearchFrame:UpdateText()
	self:SetText(self:GetSearch())
end


--[[ Propertiesish ]]--

function SearchFrame:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateShown()
		self:UpdateText()
	end
end

function SearchFrame:GetFrameID()
	return self.frameID
end


--[[ Frame Settings ]]--

function SearchFrame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function SearchFrame:SetSearch(search)
	Bagnon.Settings:SetTextSearch(search)
end

function SearchFrame:GetSearch()
	return Bagnon.Settings:GetTextSearch()
end

function SearchFrame:GetLastSearch()
	return Bagnon.Settings:GetLastTextSearch()
end

function SearchFrame:EnableSearch()
	self:GetSettings():EnableTextSearch()
end

function SearchFrame:DisableSearch()
	self:GetSettings():DisableTextSearch()
end

function SearchFrame:IsSearchEnabled()
	return self:GetSettings():IsTextSearchEnabled()
end