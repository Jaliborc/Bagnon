--[[
	bagToggle.lua
		A bag toggle widget
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local BagToggle = Addon:NewClass('BagToggle', 'CheckButton')
local Dropdown = CreateFrame('Frame', 'BagnonBagToggleDropdown', nil, 'UIDropDownMenuTemplate')

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function BagToggle:New(frameID, parent)
	local b = self:Bind(CreateFrame('CheckButton', nil, parent))
	b:SetWidth(SIZE)
	b:SetHeight(SIZE)
	b:RegisterForClicks('anyUp')

	local nt = b:CreateTexture()
	nt:SetTexture([[Interface\Buttons\UI-Quickslot2]])
	nt:SetWidth(NORMAL_TEXTURE_SIZE)
	nt:SetHeight(NORMAL_TEXTURE_SIZE)
	nt:SetPoint('CENTER', 0, -1)
	b:SetNormalTexture(nt)

	local pt = b:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints(b)
	b:SetPushedTexture(pt)

	local ht = b:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints(b)
	b:SetHighlightTexture(ht)

	local ct = b:CreateTexture()
	ct:SetTexture([[Interface\Buttons\CheckButtonHilight]])
	ct:SetAllPoints(b)
	ct:SetBlendMode('ADD')
	b:SetCheckedTexture(ct)

	local icon = b:CreateTexture()
	icon:SetAllPoints(b)
	icon:SetTexture([[Interface\Buttons\Button-Backpack-Up]])

	b:SetScript('OnClick', b.OnClick)
	b:SetScript('OnEnter', b.OnEnter)
	b:SetScript('OnLeave', b.OnLeave)
	b:SetScript('OnShow', b.OnShow)
	b:SetScript('OnHide', b.OnHide)

	b:SetFrameID(frameID)

	return b
end


--[[ Messages ]]--

function BagToggle:FRAME_BAGS_SHOW(msg, frameID)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end

function BagToggle:FRAME_BAGS_HIDE(msg, frameID)
	if frameID == self:GetFrameID() then
		self:Update()
	end
end


--[[ Frame Events ]]--

function BagToggle:OnClick(button)
	if button == 'LeftButton' then
		self:GetSettings():ToggleBagFrame()
	else
		local menu = {}
		local function addLine(id, name, addon)
			if id ~= self:GetFrameID() and (not addon or select(5, GetAddOnInfo(addon))) then
				tinsert(menu, {
					text = name,
					notCheckable = 1,
					func = function()
						self:OpenFrame(id, addon)
					end
				})
			end
		end

		addLine('inventory', INVENTORY_TOOLTIP)
		addLine('bank', L.Bank)
		addLine('voidstorage', VOID_STORAGE, 'Bagnon_VoidStorage')

		if self:GetSettings():GetGuild() then
			addLine('guildbank', GUILD_BANK, 'Bagnon_GuildBank')
		end
		
		if #menu > 1 then
			EasyMenu(menu, Dropdown, self, 0, 0, 'MENU')
		else
			self:OpenFrame(self:GetFrameID() == 'inventory' and 'bank' or 'inventory')
		end
	end
end

function BagToggle:OnEnter()
	if self:GetRight() > (GetScreenWidth() / 2) then
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	self:UpdateTooltip()
end

function BagToggle:OnLeave()
	GameTooltip:Hide()
end

function BagToggle:OnShow()
	self:UpdateEvents()
	self:Update()
end

function BagToggle:OnHide()
	self:UpdateEvents()
	self:Update()
end


--[[ Open Frames ]]--

function BagToggle:OpenFrame(id, addon)
	if not addon or LoadAddOn(addon) then
		Bagnon.FrameSettings:Get(id):SetPlayerFilter(self:GetSettings():GetPlayerFilter())
		Addon:ToggleFrame(id)
	end
end


--[[ Update Methods ]]--

function BagToggle:Update()
	self:SetChecked(self:IsBagFrameShown())
end

function BagToggle:UpdateEvents()
	if self:IsVisible() then
		self:RegisterMessage('FRAME_BAGS_SHOW')
		self:RegisterMessage('FRAME_BAGS_HIDE')
	end
end

function BagToggle:UpdateTooltip()
	if not GameTooltip:IsOwned(self) then
		return
	end
	
	GameTooltip:SetText(L.TipBags)
	if self:IsBagFrameShown() then
		GameTooltip:AddLine(L.TipHideBags, 1,1,1)
	else
		GameTooltip:AddLine(L.TipShowBags, 1,1,1)
	end
	
	GameTooltip:AddLine(L.TipFrameToggle, 1,1,1)
	GameTooltip:Show()
end


--[[ Properties ]]--

function BagToggle:SetFrameID(frameID)
	if self:GetFrameID() ~= frameID then
		self.frameID = frameID
		self:Update()
	end
end

function BagToggle:GetFrameID()
	return self.frameID
end


--[[ Settings ]]--

function BagToggle:GetSettings()
	return Bagnon.FrameSettings:Get(self:GetFrameID())
end

function BagToggle:IsBagFrameShown()
	return self:GetSettings():IsBagFrameShown()
end