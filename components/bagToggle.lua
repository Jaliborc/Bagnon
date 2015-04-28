--[[
	bagToggle.lua
		A bag toggle widget
--]]

local ADDON, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
local BagToggle = Addon:NewClass('BagToggle', 'CheckButton')
local Dropdown = CreateFrame('Frame', ADDON .. 'BagToggleDropdown', nil, 'UIDropDownMenuTemplate')

local SIZE = 20
local NORMAL_TEXTURE_SIZE = 64 * (SIZE/36)


--[[ Constructor ]]--

function BagToggle:New(parent)
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
	b:SetScript('OnShow', b.Update)
	b:Update()

	return b
end


--[[ Events ]]--

function BagToggle:OnClick(button)
	if button == 'LeftButton' then
		local frame = self:GetFrame()
		frame.profile.showBags = not frame.profile.showBags or nil
		frame:Layout()
	else
		local menu = {}
		local function addLine(id, name, addon)
			if id ~= self:GetFrameID() and (not addon or GetAddOnEnableState(UnitName('player'), addon) >= 2) then
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
		addLine('bank', BANK)
		addLine('vault', VOID_STORAGE, ADDON .. '_VoidStorage')

		if Addon.Cache:GetPlayerGuild(self:GetPlayer()) then
			addLine('guild', GUILD_BANK, ADDON .. '_GuildBank')
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

	GameTooltip:SetText(L.TipBags)

	if self:IsBagFrameShown() then
		GameTooltip:AddLine(L.TipHideBags, 1,1,1)
	else
		GameTooltip:AddLine(L.TipShowBags, 1,1,1)
	end
	
	GameTooltip:AddLine(L.TipFrameToggle, 1,1,1)
	GameTooltip:Show()
end

function BagToggle:OnLeave()
	GameTooltip:Hide()
end


--[[ API ]]--

function BagToggle:OpenFrame(id, addon)
	if not addon or LoadAddOn(addon) then
		local frame = Addon:CreateFrame(id)
		frame.player = self:GetPlayer()
		frame:ShowFrame()
	end
end

function BagToggle:Update()
	self:SetChecked(self:IsBagFrameShown())
end

function BagToggle:IsBagFrameShown()
	return self:GetProfile().showBags
end