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
	self:SetSearch(self:GetLastSearch())
	self:UpdateText()
	self:UpdateVisibility()
	self:HighlightText()
	self:SetFocus()
end

function SearchFrame:OnHide()
	self:UpdateVisibility()
	self:ClearFocus()
	self:SetSearch('')
end

function SearchFrame:OnTextChanged()
	self:SetSearch(self:GetText())
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
	local toggle = self:GetParent().searchToggle
	if toggle then
		toggle:SetChecked(self:IsShown())
	end
	
	if self:IsVisible() then
		self:RegisterMessage('SEARCH_UPDATE', 'UpdateText')
	else
		self:UnregisterMessages()
	end
end

function SearchFrame:UpdateText()
	local text = self:GetSearch()
	if text ~= self:GetText() then -- required for asian locales
		self:SetText(text)
	end
end


--[[ Static ]]--

function SearchFrame:SetSearch(search)
	Addon.lastSearch = search ~= '' and search or self:GetSearch()
	Addon.search = search
	Addon:SendMessage('SEARCH_UPDATE', search)
end

function SearchFrame:GetSearch()
	return Addon.search or ''
end

function SearchFrame:GetLastSearch()
	return Addon.lastSearch or ''
end