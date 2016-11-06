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

	b:SetScript('OnHide', b.OnMouseUp)
	b:SetScript('OnMouseDown', b.OnMouseDown)
	b:SetScript('OnMouseUp', b.OnMouseUp)
	b:SetScript('OnDoubleClick', b.OnDoubleClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnClick', b.OnClick)
	b.title = title

	b:RegisterMessage(b:GetFrameID() .. '_PLAYER_CHANGED', 'Update')
	b:Update()

	return b
end


--[[ Interaction ]]--

function TitleFrame:OnMouseDown()
	if self:IsFrameMovable() or IsAltKeyDown() then
		self:GetParent():StartMoving()
	end
end

function TitleFrame:OnMouseUp()
	local parent = self:GetParent()
	local x, y = parent:GetCenter()
	parent:StopMovingOrSizing()

	if x and y then
		local scale = parent:GetScale()
		local h = UIParent:GetHeight() / scale
		local w = UIParent:GetWidth() / scale
		local xPoint, yPoint

		if x > w/2 then
			x = parent:GetRight() - w
			xPoint = 'RIGHT'
		else
			x = parent:GetLeft()
			xPoint = 'LEFT'
		end

		if y > h/2 then
			y = parent:GetTop() - h
			yPoint = 'TOP'
		else
			y = parent:GetBottom()
			yPoint = 'BOTTOM'
		end

		parent:SetPosition(yPoint..xPoint, x, y)
	end
end

function TitleFrame:OnDoubleClick()
	self:GetParent().searchFrame:SetShown(true)
end

function TitleFrame:OnClick(button)
	if button == 'RightButton' and LoadAddOn(ADDON .. '_Config') then
		Addon.FrameOptions.frameID = self:GetFrameID()
		Addon.FrameOptions:Open()
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
end

function TitleFrame:IsFrameMovable()
	return not Addon.sets.locked
end