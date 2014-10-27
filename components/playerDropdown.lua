--[[
  playerDropdown.lua
    A player selector dropdown
--]]

local ADDON, Addon = ...
local Cache = LibStub('LibItemCache-1.1')
if not Cache:HasCache() then
  return
end

local CurrentFrame
local Dropdown


--[[ Local Functions ]]--

local function OnClick(self, player, delete)
  if delete then
    if player == CurrentFrame:GetPlayer() then
      CurrentFrame:SetPlayer(UnitName('player'))
    end

    Cache:DeletePlayer(player)
  else
    CurrentFrame:SetPlayer(player)
  end

  for i = 1, UIDROPDOWNMENU_MENU_LEVEL-1 do
    _G['DropDownList'..i]:Hide()
  end
end

local function UpdateDropdown(self, level)
  if level == 2 then
    UIDropDownMenu_AddButton({text = REMOVE, notCheckable = true, arg1 = UIDROPDOWNMENU_MENU_VALUE}, 2)
  else
    local selected = CurrentFrame:GetPlayer()

    for i, player in Cache:IteratePlayers() do
      UIDropDownMenu_AddButton {
        text = format('|T%s:14:14:-3:0|t', Addon:GetPlayerIcon(player)) .. Addon:GetPlayerColorString(player):format(player),
        hasArrow = Cache:IsPlayerCached(player),
        checked = player == selected,
        func = OnClick,
        arg1 = player
      }
    end
  end
end

local function Startup()
	Dropdown = CreateFrame("Frame", "BagnonPlayerDropdown", UIParent, "UIDropDownMenuTemplate")
	Dropdown:SetID(1)
	UIDropDownMenu_Initialize(Dropdown, UpdateDropdown, "MENU")
	return Dropdown
end


--[[ Public Methods ]]--

function Addon:TogglePlayerDropdown(anchor, frame, offX, offY)
  CurrentFrame = frame
  ToggleDropDownMenu(1, nil, Dropdown or Startup(), anchor, offX, offY)
end