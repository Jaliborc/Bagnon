--[[
	titleFrame.lua
		A title frame widget
--]]


local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local TitleFrame = Bagnon:NewClass('TitleFrame', 'Button')


--[[ Constructor ]]--

function TitleFrame:New(frameID, title, parent)
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

	b:SetTitleText(title)
	b:SetFrameID(frameID)
	b:UpdateEvents()

	return b
end


--[[ Messages ]]--

function TitleFrame:PLAYER_UPDATE(msg, frameID, player)
	if frameID == self:GetFrameID() then
		self:UpdateText()
	end
end


--[[ Frame Events ]]--

function TitleFrame:OnShow()
	self:UpdateText()
	self:UpdateEvents()
end

function TitleFrame:OnHide()
	self:StopMovingFrame()
end

function TitleFrame:OnMouseDown()
	if self:IsFrameMovable() or IsAltKeyDown() then
		self:StartMovingFrame()
	end
end

function TitleFrame:OnMouseUp()
	self:StopMovingFrame()
end

function TitleFrame:OnDoubleClick()
	self:ToggleSearchFrame()
end

function TitleFrame:OnClick(button)
	if button == 'RightButton' then
		if LoadAddOn('Bagnon_Config') then
			Bagnon.FrameOptions:ShowFrame(self:GetFrameID())
		end
	end
end

function TitleFrame:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	self:UpdateTooltip()
end

function TitleFrame:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


--[[ Update Methods ]]--

function TitleFrame:UpdateText()
	self:SetFormattedText(self:GetTitleText(), self:GetPlayer())
	self:GetFontString():SetAllPoints(self)
end

function TitleFrame:UpdateTooltip()
	GameTooltip:SetText(L.TipDoubleClickSearch)
	GameTooltip:Show()
end

function TitleFrame:UpdateEvents()
	self:UnregisterAllMessages()

	if self:IsVisible() then
		self:RegisterMessage('PLAYER_UPDATE')
	end
end

function TitleFrame:StartMovingFrame()
	self:SendMessage('FRAME_MOVE_START', self:GetFrameID())
end

function TitleFrame:StopMovingFrame()
	self:SendMessage('FRAME_MOVE_STOP', self:GetFrameID())
end


--[[ Properties ]]--

function TitleFrame:SetFrameID (frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:UpdateText()
	end
end

function TitleFrame:GetFrameID()
	return self.frameID
end

function TitleFrame:SetTitleText (title)
	self.title = title
end

function TitleFrame:GetTitleText()
	return self.title or self:GetFrameID() == 'bank' and L.TitleBank or L.TitleBags
end


--[[ Frame Settings ]]--

function TitleFrame:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function TitleFrame:GetPlayer()
	return self:GetSettings():GetPlayerFilter()
end

function TitleFrame:IsFrameMovable()
	return self:GetSettings():IsMovable()
end

function TitleFrame:ToggleSearchFrame()
	self:GetSettings():ToggleTextSearch()
end