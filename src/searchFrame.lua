--[[
	A search frame editbox.
	All Rights Reserved
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local Search = Addon.Parented:NewClass('SearchFrame', 'EditBox', 'TooltipBackdropTemplate')


--[[ Construct ]]--

function Search:New(parent)
	local f = self:Super(Search):New(parent)
	f:SetFontObject('ChatFontNormal')
	f:SetTextInsets(8, 8, 0, 0)
	f:SetFrameStrata('DIALOG')
	f:SetToplevel(true)
	f:Hide()

	f:RegisterSignal('SEARCH_TOGGLED', 'OnToggle')
	f:SetScript('OnTextChanged', f.OnTextChanged)
	f:SetScript('OnEscapePressed', f.OnEscape)
	f:SetScript('OnEnterPressed', f.OnEscape)
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f:SetAutoFocus(false)

	return f
end


--[[ Frame Events ]]--

function Search:OnToggle(_, shownFrame)
	if shownFrame then
		if not self:IsShown() then
			UIFrameFadeIn(self, 0.1)

			if shownFrame == self:GetFrameID() then
				self:HighlightText()
				self:SetFocus()
			end
		end
	else
		self:Hide()
	end
end

function Search:OnShow()
	self:RegisterSignal('SEARCH_CHANGED', 'UpdateText')
	self:UpdateText()
end

function Search:OnHide()
	self:UnregisterSignal('SEARCH_CHANGED')
	self:ClearFocus()
end

function Search:OnTextChanged()
	local text = self:GetText():lower()
	if text ~= Addon.search then
		Addon.search = text
		Addon:SendSignal('SEARCH_CHANGED', text)
	end
end

function Search:OnEscape()
	Addon.canSearch = nil
	self:SendSignal('SEARCH_TOGGLED', nil)
	self:Hide()
end


--[[ API ]]--

function Search:UpdateText()
	if Addon.search ~= self:GetText() then
		self:SetText(Addon.search or '')
	end
end
