--[[
  playerDropdown.lua
    A player selector dropdown
--]]

local Cache = LibStub('LibItemCache-1.0')
if not Cache:HasCache() then
  return
end

local currentFrame
local dropdown
local info = {}

local function CharSelect_OnClick(self, player, delete)
  if delete then
    -- set to current player if deleted is selected
    if player == currentFrame:GetPlayer() then
      currentFrame:SetPlayer(UnitName('player'))
    end

    Cache:DeletePlayer(player)
  else
    currentFrame:SetPlayer(player)
  end

  --hide the previous dropdown menus (hack)
  for i = 1, UIDROPDOWNMENU_MENU_LEVEL-1 do
    _G['DropDownList'..i]:Hide()
  end
end

--adds a checkable item to a dropdown menu
local function AddItem(text, checkable, checked, hasArrow, level, arg1, arg2)
  info.func = CharSelect_OnClick
	info.text = text
	info.value = text
	info.hasArrow = hasArrow
	info.notCheckable = not checkable
	info.checked = checked
	info.arg1 = arg1
	info.arg2 = arg2
	UIDropDownMenu_AddButton(info, level)
end

--populate the list, add a delete button to all characters that aren't the current player
local function CharSelect_Initialize(self, level)
	if level == 2 then
		AddItem(REMOVE, nil, nil, nil, level, UIDROPDOWNMENU_MENU_VALUE, true)
  else
    local selected = currentFrame:GetPlayer()

    for i, player in Cache:IteratePlayers() do
      AddItem(player, true, player == selected, Cache:IsPlayerCached(player), level, player)
    end
	end
end

local function CharSelect_Create()
	dropdown = CreateFrame("Frame", "BagnonPlayerDropdown", UIParent, "UIDropDownMenuTemplate")
	dropdown:SetID(1)
	UIDropDownMenu_Initialize(dropdown, CharSelect_Initialize, "MENU")
	return dropdown
end


--[[ Usable Function ]]--

--show the character select list at the given location
function Bagnon:TogglePlayerDropdown(anchor, offX, offY)
 	currentFrame = anchor
	ToggleDropDownMenu(1, nil, dropdown or CharSelect_Create(), anchor, offX, offY)
end