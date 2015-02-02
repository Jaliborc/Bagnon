--[[
	titleFrame.lua
		A title frame widget
--]]


local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local TitleFrame = Addon:NewClass('TitleFrame', 'Button')


--[[ Constructor ]]--

function TitleFrame:New(title, parent)
	local b = self:Bind(CreateFrame('Button', nil, parent))

	b:SetToplevel(true)
	b:SetNormalFontObject('GameFontNormalLeft')
	b:SetHighlightFontObject('GameFontHighlightLeft')
	b:RegisterForClicks('anyUp')

	b:SetScript('OnShow', b.OnShow)
	b:SetScript('OnHide', b.OnHide)
	b:SetScript('OnMouseDown', b.OnMouseDown)
	b:SetScript('OnMouseUp', b.OnMouseUp)
	b:SetScript('OnDoubleClick', b.OnDoubleClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnClick', b.OnClick)
	b.title = title
	b:Update()

	return b
end


--[[ Messages ]]--

function TitleFrame:PLAYER_UPDATE(msg, frameID)
	if frameID == self:GetFrameID() then
		self:UpdateText()
	end
end


--[[ Frame Events ]]--

function TitleFrame:OnShow()
	self:Update()
end

function TitleFrame:OnHide()
	self:OnMouseUp()
end

function TitleFrame:OnMouseDown()
	if self:IsFrameMovable() or IsAltKeyDown() then
		self:GetParent():StartMoving()
	end
end

function TitleFrame:OnMouseUp()
	self:GetParent():StopMovingOrSizing()
end

function TitleFrame:OnDoubleClick()
	self:ToggleSearchFrame()
end

function TitleFrame:OnClick(button)
	if button == 'RightButton' then
		if LoadAddOn(ADDON .. '_Config') then
			Addon.FrameOptions:ShowFrame(self:GetFrameID())
		end
	end
end

function TitleFrame:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end

	GameTooltip:SetText(L.TipDoubleClickSearch)
	GameTooltip:Show()
end

function TitleFrame:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ API ]]--

function TitleFrame:Update()
	self:SetFormattedText(self.title, self:GetPlayer())
	self:GetFontString():SetAllPoints(self)
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterMessage('PLAYER_UPDATE')
	end
end

function TitleFrame:IsFrameMovable()
	return self:GetSettings().movable
end

function TitleFrame:ToggleSearchFrame()
	self:GetSettings():ToggleTextSearch()
end