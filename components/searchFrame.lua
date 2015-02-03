--[[
	searchFrame.lua
		A searcn frame widget
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local SearchFrame = Addon:NewClass('SearchFrame', 'EditBox')

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


--[[ Constructor ]]--

function SearchFrame:New(parent)
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
	f:SetAutoFocus(false)

	return f
end


--[[ Events ]]--

function SearchFrame:OnShow()
	SearchFrame:SetSearch(SearchFrame:GetLastSearch())
	self:UpdateText()
	self:UpdateVisibility()
	self:HighlightText()
	self:SetFocus()
end

function SearchFrame:OnHide()
	self:UpdateVisibility()
	self:ClearFocus()
	SearchFrame:SetSearch('')
end

function SearchFrame:OnTextChanged()
	SearchFrame:SetSearch(self:GetText())
end

function SearchFrame:OnEscapePressed()
	self:Hide()
end

function SearchFrame:OnEnterPressed()
	self:Hide()
end


--[[ Actions ]]--

function SearchFrame:SetShown(shown)
	if shown then
		if not self:IsShown() then
			UIFrameFadeIn(self, 0.1)
		end
	else
		self:Hide()
	end
end

function SearchFrame:UpdateVisibility()
	self:GetParent().searchToggle:SetChecked(self:IsShown())
	self:UnregisterAllMessages()
	
	if self:IsVisible() then
		self:RegisterMessage('TEXT_SEARCH_UPDATE', 'UpdateText')
	end
end

function SearchFrame:UpdateText()
	local text = SearchFrame:GetSearch()
	if text ~= self:GetText() then -- required for asian locales
		self:SetText(text)
	end
end


--[[ Static ]]--

function SearchFrame:SetSearch(search)
	self.lastSearch = search ~= '' and search or self:GetSearch()
	self.search = search
	self:SendMessage('TEXT_SEARCH_UPDATE', search)
end

function SearchFrame:GetSearch()
	return self.search or ''
end

function SearchFrame:GetLastSearch()
	return self.lastSearch or ''
end