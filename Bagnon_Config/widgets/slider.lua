--[[
	slider.lua
		A bagnon options slider
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local OptionsSlider = Bagnon.Classy:New('Slider')
Bagnon.OptionsSlider = OptionsSlider


--[[ Constructor ]]--

function OptionsSlider:New(name, parent, low, high, step)
	local f = self:Bind(CreateFrame('Slider', parent:GetName() .. name, parent, 'OptionsSliderTemplate'))
	f:SetMinMaxValues(low, high)
	f:SetValueStep(step)
	f:EnableMouseWheel(true)

	_G[f:GetName() .. 'Text']:SetText(name)
	_G[f:GetName() .. 'Text']:SetFontObject('GameFontNormalLeft')
	_G[f:GetName() .. 'Text']:ClearAllPoints()
	_G[f:GetName() .. 'Text']:SetPoint('BOTTOMLEFT', f, 'TOPLEFT')
--	_G[f:GetName() .. 'Text']:SetJustifyH('LEFT')
	_G[f:GetName() .. 'Low']:SetText('')
	_G[f:GetName() .. 'High']:SetText('')

	local text = f:CreateFontString(nil, 'BACKGROUND', 'GameFontHighlightSmall')
	text:SetJustifyH('RIGHT')
	text:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT')
--	text:SetPoint('LEFT', f, 'RIGHT', 7, 0)
	f.valText = text

	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnMouseWheel', f.OnMouseWheel)
	f:SetScript('OnValueChanged', f.OnValueChanged)
	f:SetScript('OnMouseWheel', f.OnMouseWheel)

	return f
end


--[[ Frame Events ]]--

function OptionsSlider:OnShow()
	self:UpdateValue()
end

function OptionsSlider:OnValueChanged(value)
	self:SetSavedValue(value)
	self:UpdateText(self:GetSavedValue())
end

function OptionsSlider:OnMouseWheel(direction)
	local step = self:GetValueStep() *  direction
	local value = self:GetValue()
	local minVal, maxVal = self:GetMinMaxValues()

	if step > 0 then
		self:SetValue(math.min(value+step, maxVal))
	else
		self:SetValue(math.max(value+step, minVal))
	end
end


--[[ Update Methods ]]--

function OptionsSlider:SetSavedValue(value)
	assert(false, 'Hey, you forgot to set SetSavedValue for ' .. self:GetName())
end

function OptionsSlider:GetSavedValue()
	assert(false, 'Hey, you forgot to set GetSavedValue for ' .. self:GetName())
end

function OptionsSlider:UpdateValue()
	self:SetValue(self:GetSavedValue())
	self:UpdateText(self:GetSavedValue())
end

function OptionsSlider:UpdateText(value)
	if self.GetFormattedText then
		self.valText:SetText(self:GetFormattedText(value))
	else
		self.valText:SetText(value)
	end
end