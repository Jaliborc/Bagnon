--[[
	main.lua
		The bagnon driver thingy
--]]

Bagnon = LibStub('AceAddon-3.0'):NewAddon('Bagnon', 'AceEvent-3.0', 'AceConsole-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')

BINDING_HEADER_BAGNON = 'Bagnon'
BINDING_NAME_BAGNON_TOGGLE = L.ToggleBags
BINDING_NAME_BANKNON_TOGGLE = L.ToggleBank


--[[ Startup ]]--

Bagnon.frames = {}
function Bagnon:OnInitialize()
 	self:AddSlashCommands()
 	self:RegisterAutoDisplayEvents()
	self:HookBagClickEvents()
 	self:HookTooltips()

	self:CreateFrameLoader('Bagnon_GuildBank', 'GuildBankFrame_LoadUI')
	self:CreateFrameLoader('Bagnon_VoidStorage', 'VoidStorage_LoadUI')
	self:CreateOptionsLoader()
	self:CreateLDBLauncher()
end

function Bagnon:CreateOptionsLoader()
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn('Bagnon_Config')
	end)
end

function Bagnon:CreateFrameLoader (addon, method)
	local name, title, notes, enabled, loadable = GetAddOnInfo(addon)
	if enabled and loadable then
		_G[method] = function()
			LoadAddOn(addon)
		end
	end
end

function Bagnon:CreateLDBLauncher()
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if not LDB then return end

	LDB:NewDataObject('BagnonLauncher', {
		type = 'launcher',
		icon = [[Interface\Icons\INV_Misc_Bag_07]],

		OnClick = function(_, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					Bagnon:ToggleFrame('bank')
				else
					Bagnon:ToggleFrame('inventory')
				end
			elseif button == 'RightButton' then
				Bagnon:ShowOptions()
			end
		end,

		OnTooltipShow = function(tooltip)
			tooltip:AddLine('Bagnon')
			tooltip:AddLine(L.TipShowInventory, 1, 1, 1)
			tooltip:AddLine(L.TipShowBank, 1, 1, 1)
			tooltip:AddLine(L.TipShowOptions, 1, 1, 1)
		end,
	})
end


--[[ Frames ]]--

function Bagnon:CreateFrame(frameID)
  self.Frame:New(frameID)
end

function Bagnon:GetFrame(frameID)
	for i, frame in pairs(self.frames) do
		if frame:GetFrameID() == frameID then
			return frame
		end
	end
end

function Bagnon:ShowFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		if not self:GetFrame(frameID) then
			self:CreateFrame(frameID)
		end

		self.FrameSettings:Get(frameID):Show()
		return true
	end
end

function Bagnon:HideFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		self.FrameSettings:Get(frameID):Hide()
		return true
	end
end

function Bagnon:ToggleFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		if not self:GetFrame(frameID) then
			self:CreateFrame(frameID)
		end

		self.FrameSettings:Get(frameID):Toggle()
		return true
	end
end

function Bagnon:IsFrameEnabled(frameID)
	return self.Settings:IsFrameEnabled(frameID)
end

function Bagnon:FrameControlsBag(frameID, bagSlot)
	return self.FrameSettings:Get(frameID):IsBagSlotShown(bagSlot) or (not self:IsBlizzardBagPassThroughEnabled())
end

function Bagnon:IsBlizzardBagPassThroughEnabled()
	return self.Settings:IsBlizzardBagPassThroughEnabled()
end


--[[ Bag Buttons Hooks ]]--

function Bagnon:HookBagClickEvents()
	--backpack
	hooksecurefunc('CloseBackpack', function()
		self:HideFrame('inventory')
	end)

	local oOpenBackpack = OpenBackpack
	OpenBackpack = function()
		local shown = self:FrameControlsBag('inventory', BACKPACK_CONTAINER) and self:ShowFrame('inventory')

		if not shown then
			oOpenBackpack()
		end
	end

	local oToggleBackpack = ToggleBackpack
	ToggleBackpack = function()
		local toggled = self:FrameControlsBag('inventory', BACKPACK_CONTAINER) and self:ToggleFrame('inventory')

		if not toggled then
			oToggleBackpack()
		end
	end

	--single bag
	local oToggleBag = ToggleBag
	ToggleBag = function(bagSlot)
		local frameID = self:IsBankBag(bagSlot) and 'bank' or 'inventory'
		local toggled = self:FrameControlsBag(frameID, bagSlot) and self:ToggleFrame(frameID)

		if not toggled then
			oToggleBag(bagSlot)
		end
	end

	--all bags
	--closing the game menu triggers this function, and can be done in combat
	hooksecurefunc('CloseAllBags', function()
		self:HideFrame('inventory')
	end)

	local oOpenAllBags = OpenAllBags
	OpenAllBags = function(frame)
		local opened = self:FrameControlsBag('inventory', BACKPACK_CONTAINER) and self:ShowFrame('inventory')
		if not opened then
			oOpenAllBags(frame)
		end
	end

	if ToggleAllBags then
		local oToggleAllBags = ToggleAllBags
		ToggleAllBags = function()
			local toggled = self:FrameControlsBag('inventory', BACKPACK_CONTAINER) and self:ToggleFrame('inventory')
			if not toggled then
				oToggleAllBags()
			end
		end
	end

	local function bag_checkIfInventoryShown(self)
		if Bagnon:IsFrameEnabled('inventory') then
			self:SetChecked(Bagnon.FrameSettings:Get('inventory'):IsShown())
		end
	end

	--handle checking/unchecking of the backpack buttons based on frame display
	hooksecurefunc('BagSlotButton_UpdateChecked', bag_checkIfInventoryShown)
	hooksecurefunc('BackpackButton_UpdateChecked', bag_checkIfInventoryShown)

	self.Callbacks:Listen(self, 'FRAME_SHOW')
	self.Callbacks:Listen(self, 'FRAME_HIDE')
end


--[[ Frames Events ]]--

function Bagnon:FRAME_SHOW(msg, frameID)
	if frameID == 'inventory' and self:IsFrameEnabled('inventory') then
		self:CheckBagButtons(true)
	end
end

function Bagnon:FRAME_HIDE(msg, frameID)
	if frameID == 'inventory' and self:IsFrameEnabled('inventory') then
		self:CheckBagButtons(false)
	end
end

--check/uncheck the bag buttons
function Bagnon:CheckBagButtons(checked)
	_G['MainMenuBarBackpackButton']:SetChecked(checked)
	_G["CharacterBag0Slot"]:SetChecked(checked)
	_G["CharacterBag1Slot"]:SetChecked(checked)
	_G["CharacterBag2Slot"]:SetChecked(checked)
	_G["CharacterBag3Slot"]:SetChecked(checked)
end


--[[ Automatic Display ]]--

function Bagnon:RegisterAutoDisplayEvents()
	self.BagEvents:Listen(self, 'BANK_OPENED')
	self.BagEvents:Listen(self, 'BANK_CLOSED')
	self:RegisterEvent('MAIL_CLOSED')
	self:RegisterEvent('AUCTION_HOUSE_SHOW')
	self:RegisterEvent('AUCTION_HOUSE_CLOSED')
	self:RegisterEvent('MERCHANT_SHOW')
	self:RegisterEvent('MERCHANT_CLOSED')
	self:RegisterEvent('TRADE_SHOW')
	self:RegisterEvent('TRADE_CLOSED')
	self:RegisterEvent('TRADE_SKILL_SHOW')
	self:RegisterEvent('TRADE_SKILL_CLOSE')
	self:RegisterEvent('GUILDBANKFRAME_OPENED')
	self:RegisterEvent('GUILDBANKFRAME_CLOSED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('UNIT_ENTERED_VEHICLE')

	--override normal bank display
	BankFrame:UnregisterEvent('BANKFRAME_OPENED')
	BankFrame:UnregisterEvent('BANKFRAME_CLOSED')

	local f = CreateFrame('Frame', nil, CharacterFrame)
	f:SetScript('OnShow', function() Bagnon:PLAYER_FRAME_SHOW() end)
	f:SetScript('OnHide', function() Bagnon:PLAYER_FRAME_HIDE() end)
end

function Bagnon:ShowFrameAtEvent(frameID, event)
	if self:AutoDisplayingFrameOnEvent(frameID, event) then
		self:ShowFrame(frameID)
	end
end

function Bagnon:HideFrameAtEvent(frameID, event)
	if self:AutoDisplayingFrameOnEvent(frameID, event) then
		self:HideFrame(frameID)
	end
end

function Bagnon:AutoDisplayingFrameOnEvent(frameID, event)
	return self.Settings:IsFrameShownAtEvent(frameID, event)
end

function Bagnon:ShowBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_OPENED')
end

function Bagnon:HideBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_CLOSED')
end


--[[ Display Events ]]--

-- combat
function Bagnon:PLAYER_REGEN_DISABLED()
	self:HideFrameAtEvent('inventory', 'combat')
end

function Bagnon:UNIT_ENTERED_VEHICLE(unit)
	if unit == 'player' then
		self:HideFrameAtEvent('inventory', 'vehicle')
	end
end

--visiting the bank
function Bagnon:BANK_OPENED()
	if not self:ShowFrame('bank') then
		self:ShowBlizzardBankFrame()
	end
	self:ShowFrameAtEvent('inventory', 'bank')
end

function Bagnon:BANK_CLOSED()
	if not self:HideFrame('bank') then
		self:HideBlizzardBankFrame()
	end
	self:HideFrameAtEvent('inventory', 'bank')
end

--visiting the mailbox
--mail frame is a special case, since its automatically handled by the stock interface
function Bagnon:MAIL_CLOSED()
	self:HideFrame('inventory')
end

--visiting the auction house
function Bagnon:AUCTION_HOUSE_SHOW()
	self:ShowFrameAtEvent('inventory', 'ah')
end

function Bagnon:AUCTION_HOUSE_CLOSED()
	self:HideFrameAtEvent('inventory', 'ah')
end

--visitng a vendor
function Bagnon:MERCHANT_SHOW()
	self:ShowFrameAtEvent('inventory', 'vendor')
end

function Bagnon:MERCHANT_CLOSED()
	self:HideFrameAtEvent('inventory', 'vendor')
end

--trading
function Bagnon:TRADE_SHOW()
	self:ShowFrameAtEvent('inventory', 'trade')
end

function Bagnon:TRADE_CLOSED()
	self:HideFrameAtEvent('inventory', 'trade')
end

--visiting the guild bank
function Bagnon:GUILDBANKFRAME_OPENED()
	self:ShowFrameAtEvent('inventory', 'guildbank')
end

function Bagnon:GUILDBANKFRAME_CLOSED()
	self:HideFrameAtEvent('inventory', 'guildbank')
end

--crafting
function Bagnon:TRADE_SKILL_SHOW()
	self:ShowFrameAtEvent('inventory', 'craft')
end

function Bagnon:TRADE_SKILL_CLOSE()
	self:HideFrameAtEvent('inventory', 'craft')
end

--player frame
function Bagnon:PLAYER_FRAME_SHOW()
	self:ShowFrameAtEvent('inventory', 'player')
end

function Bagnon:PLAYER_FRAME_HIDE()
	self:HideFrameAtEvent('inventory', 'player')
end


--[[ Slash Commands ]]--

function Bagnon:AddSlashCommands()
	self:RegisterChatCommand('bagnon', 'HandleSlashCommand')
	self:RegisterChatCommand('bgn', 'HandleSlashCommand')
end

function Bagnon:HandleSlashCommand(cmd)
	cmd = cmd and cmd:lower() or ''
	
	if cmd == 'bank' then
		self:ToggleFrame('bank')
	elseif cmd == 'bags' or cmd == 'inventory' then
		self:ToggleFrame('inventory')
	elseif cmd == 'version' then
		self:PrintVersion()
	elseif cmd == '?' or cmd == 'help' then
		self:PrintHelp()
	else
		if not self:ShowOptions() and cmd ~= 'config' and cmd ~= 'options' then
			self:PrintHelp()
		end
	end
end

function Bagnon:PrintVersion()
	self:Print(self.SavedSettings:GetDBVersion())
end

function Bagnon:PrintHelp()
	local function PrintCmd(cmd, desc)
		print(string.format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print(L.Commands)
	PrintCmd('bags', L.CmdShowInventory)
	PrintCmd('bank', L.CmdShowBank)
	PrintCmd('version', L.CmdShowVersion)
end

function Bagnon:ShowOptions()
	if LoadAddOn('Bagnon_Config') then
		InterfaceOptionsFrame_OpenToCategory(self.GeneralOptions)
		return true
	end
end