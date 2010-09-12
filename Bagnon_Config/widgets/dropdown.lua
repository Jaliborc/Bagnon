--[[
	dropdown.lua
		A bagnon dropdown menu
--]]

local OptionsDropdown = Bagnon.Classy:New('Frame')
Bagnon.OptionsDropdown = OptionsDropdown

function OptionsDropdown:New(name, parent, width)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. name, parent, 'UIDropDownMenuTemplate'))
	f.width = width

	local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmall')
	text:SetPoint('BOTTOMLEFT', f, 'TOPLEFT', 21, 0)
	text:SetText(name)
	f.titleText = text

	f:SetScript('OnShow', f.OnShow)
	return f
end


--[[ Frame Evnets ]]--

function OptionsDropdown:OnShow()
	UIDropDownMenu_SetWidth(self, self.width)
	UIDropDownMenu_Initialize(self, self.Initialize)
	UIDropDownMenu_SetSelectedValue(self, self:GetSavedValue())
end


--[[ Update Methods ]]--

function OptionsDropdown:Initialize()
	assert(false, 'Hey you forgot to implement Initialize for ' .. self:GetName())
end

function OptionsDropdown:SetSavedValue(value)
	assert(false, 'Hey you forgot to implement SetSavedValue for ' .. self:GetName())
end

function OptionsDropdown:GetSavedValue()
	assert(false, 'Hey you forgot to implement GetSavedValue for ' .. self:GetName())
end


--[[ Item Adding ]]--

local function item_OnClick(self, dropdown)
	dropdown:SetSavedValue(self.value)
	UIDropDownMenu_SetSelectedValue(dropdown, self.value)		
end

function OptionsDropdown:AddItem(name, value)
	local info = UIDropDownMenu_CreateInfo()
	info.text = name
	info.value = value or name
	info.arg1 = self
	info.func = item_OnClick
	info.checked = (self:GetSavedValue() == info.value)
	
	UIDropDownMenu_AddButton(info)
end