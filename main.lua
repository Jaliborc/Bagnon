--[[
	main.lua
		The bagnon driver thingy
--]]

local ADDON, Addon = ...
_G[ADDON] = LibStub('AceAddon-3.0'):NewAddon(Addon, ADDON, 'AceEvent-3.0', 'AceConsole-3.0')
Addon.frames = {}

local L = LibStub('AceLocale-3.0'):GetLocale(ADDON)
BINDING_HEADER_BAGNON = ADDON
BINDING_NAME_BAGNON_TOGGLE = L.ToggleBags
BINDING_NAME_BAGNON_BANK_TOGGLE = L.ToggleBank
BINDING_NAME_BAGNON_VAULT_TOGGLE = L.ToggleVault


--[[ Startup ]]--

function Addon:OnInitialize()
 	self:AddSlashCommands()
 	self:RegisterAutoDisplayEvents()
	self:HookBagClickEvents()
 	self:HookTooltips()

	self:CreateFrameLoader(ADDON .. '_GuildBank', 'GuildBankFrame_LoadUI')
	self:CreateFrameLoader(ADDON .. '_VoidStorage', 'VoidStorage_LoadUI')
	self:CreateOptionsLoader()
	self:CreateLDBLauncher()
end

function Addon:CreateOptionsLoader()
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function(self)
		self:SetScript('OnShow', nil)
		LoadAddOn(ADDON .. '_Config')
	end)
end

function Addon:CreateFrameLoader (addon, method)
	local name, title, notes, enabled, loadable = GetAddOnInfo(addon)
	if enabled and loadable then
		_G[method] = function()
			LoadAddOn(addon)
		end
	end
end

function Addon:CreateLDBLauncher()
	local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
	if not LDB then return end

	LDB:NewDataObject(ADDON .. 'Launcher', {
		type = 'launcher',
		icon = [[Interface\Icons\INV_Misc_Bag_07]],

		OnClick = function(_, button)
			if button == 'LeftButton' then
				if IsShiftKeyDown() then
					Addon:ToggleFrame('bank')
				else
					Addon:ToggleFrame('inventory')
				end
			elseif button == 'RightButton' then
				Addon:ShowOptions()
			end
		end,

		OnTooltipShow = function(tooltip)
			tooltip:AddLine(ADDON)
			tooltip:AddLine(L.TipShowInventory, 1, 1, 1)
			tooltip:AddLine(L.TipShowBank, 1, 1, 1)
			tooltip:AddLine(L.TipShowOptions, 1, 1, 1)
		end,
	})
end


--[[ Frames ]]--

function Addon:CreateFrame(frameID)
  self.Frame:New(frameID)
end

function Addon:GetFrame(frameID)
	for i, frame in pairs(self.frames) do
		if frame:GetFrameID() == frameID then
			return frame
		end
	end
end

function Addon:UpdateFrames()
	for _,frame in pairs(self.frames) do
		frame.itemFrame:UpdateEverything()
	end
end

function Addon:ShowFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		if not self:GetFrame(frameID) then
			self:CreateFrame(frameID)
		end

		self.FrameSettings:Get(frameID):Show()
		return true
	end
end

function Addon:HideFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		self.FrameSettings:Get(frameID):Hide()
		return true
	end
end

function Addon:ToggleFrame(frameID)
	if self:IsFrameEnabled(frameID) then
		if not self:GetFrame(frameID) then
			self:CreateFrame(frameID)
		end

		self.FrameSettings:Get(frameID):Toggle()
		return true
	end
end

function Addon:IsFrameEnabled(frameID)
	return self.Settings:IsFrameEnabled(frameID)
end

function Addon:FrameControlsBag(frameID, bagSlot)
	return self.FrameSettings:Get(frameID):IsBagSlotShown(bagSlot) or (not self:IsBlizzardBagPassThroughEnabled())
end

function Addon:IsBlizzardBagPassThroughEnabled()
	return self.Settings:IsBlizzardBagPassThroughEnabled()
end


--[[ Bag Buttons Hooks ]]--

function Addon:HookBagClickEvents()
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
		if Addon:IsFrameEnabled('inventory') then
			self:SetChecked(Addon.FrameSettings:Get('inventory'):IsShown())
		end
	end

	--handle checking/unchecking of the backpack buttons based on frame display
	hooksecurefunc('BagSlotButton_UpdateChecked', bag_checkIfInventoryShown)
	hooksecurefunc('BackpackButton_UpdateChecked', bag_checkIfInventoryShown)

	self.Callbacks:Listen(self, 'FRAME_SHOW')
	self.Callbacks:Listen(self, 'FRAME_HIDE')
end


--[[ Frames Events ]]--

function Addon:FRAME_SHOW(msg, frameID)
	if frameID == 'inventory' and self:IsFrameEnabled('inventory') then
		self:CheckBagButtons(true)
	end
end

function Addon:FRAME_HIDE(msg, frameID)
	if frameID == 'inventory' and self:IsFrameEnabled('inventory') then
		self:CheckBagButtons(false)
	end
end

--check/uncheck the bag buttons
function Addon:CheckBagButtons(checked)
	_G['MainMenuBarBackpackButton']:SetChecked(checked)
	_G["CharacterBag0Slot"]:SetChecked(checked)
	_G["CharacterBag1Slot"]:SetChecked(checked)
	_G["CharacterBag2Slot"]:SetChecked(checked)
	_G["CharacterBag3Slot"]:SetChecked(checked)
end


--[[ Automatic Display ]]--

function Addon:RegisterAutoDisplayEvents()
	self.BagEvents:Listen(self, 'BANK_OPENED')
	self.BagEvents:Listen(self, 'BANK_CLOSED')
	self:RegisterEvent('MAIL_CLOSED')
	self:RegisterEvent('SOCKET_INFO_UPDATE')
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
	f:SetScript('OnShow', function() Addon:PLAYER_FRAME_SHOW() end)
	f:SetScript('OnHide', function() Addon:PLAYER_FRAME_HIDE() end)
end

function Addon:ShowFrameAtEvent(frameID, event)
	if self:AutoDisplayingFrameOnEvent(frameID, event) then
		self:ShowFrame(frameID)
	end
end

function Addon:HideFrameAtEvent(frameID, event)
	if self:AutoDisplayingFrameOnEvent(frameID, event) then
		self:HideFrame(frameID)
	end
end

function Addon:AutoDisplayingFrameOnEvent(frameID, event)
	return self.Settings:IsFrameShownAtEvent(frameID, event)
end

function Addon:ShowBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_OPENED')
end

function Addon:HideBlizzardBankFrame()
	BankFrame_OnEvent(_G['BankFrame'], 'BANKFRAME_CLOSED')
end


--[[ Display Events ]]--

-- combat
function Addon:PLAYER_REGEN_DISABLED()
	self:HideFrameAtEvent('inventory', 'combat')
end

function Addon:UNIT_ENTERED_VEHICLE(unit)
	if unit == 'player' then
		self:HideFrameAtEvent('inventory', 'vehicle')
	end
end

--visiting the bank
function Addon:BANK_OPENED()
	if not self:ShowFrame('bank') then
		self:ShowBlizzardBankFrame()
	end
	self:ShowFrameAtEvent('inventory', 'bank')
end

function Addon:BANK_CLOSED()
	if not self:HideFrame('bank') then
		self:HideBlizzardBankFrame()
	end
	self:HideFrameAtEvent('inventory', 'bank')
end

--visiting the mailbox
--mail frame is a special case, since its automatically handled by the stock interface
function Addon:MAIL_CLOSED()
	self:HideFrame('inventory')
end

function Addon:SOCKET_INFO_UPDATE()
	self:ShowFrameAtEvent('inventory', 'gems')
end

--visiting the auction house
function Addon:AUCTION_HOUSE_SHOW()
	self:ShowFrameAtEvent('inventory', 'ah')
end

function Addon:AUCTION_HOUSE_CLOSED()
	self:HideFrameAtEvent('inventory', 'ah')
end

--visitng a vendor
function Addon:MERCHANT_SHOW()
	self:ShowFrameAtEvent('inventory', 'vendor')
end

function Addon:MERCHANT_CLOSED()
	self:HideFrameAtEvent('inventory', 'vendor')
end

--trading
function Addon:TRADE_SHOW()
	self:ShowFrameAtEvent('inventory', 'trade')
end

function Addon:TRADE_CLOSED()
	self:HideFrameAtEvent('inventory', 'trade')
end

--visiting the guild bank
function Addon:GUILDBANKFRAME_OPENED()
	self:ShowFrameAtEvent('inventory', 'guildbank')
end

function Addon:GUILDBANKFRAME_CLOSED()
	self:HideFrameAtEvent('inventory', 'guildbank')
end

--crafting
function Addon:TRADE_SKILL_SHOW()
	self:ShowFrameAtEvent('inventory', 'craft')
end

function Addon:TRADE_SKILL_CLOSE()
	self:HideFrameAtEvent('inventory', 'craft')
end

--player frame
function Addon:PLAYER_FRAME_SHOW()
	self:ShowFrameAtEvent('inventory', 'player')
end

function Addon:PLAYER_FRAME_HIDE()
	self:HideFrameAtEvent('inventory', 'player')
end


--[[ Slash Commands ]]--

function Addon:AddSlashCommands()
	self:RegisterChatCommand(ADDON:lower(), 'HandleSlashCommand')
	self:RegisterChatCommand('bgn', 'HandleSlashCommand')
end

function Addon:HandleSlashCommand(cmd)
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

function Addon:PrintVersion()
	self:Print(self.SavedSettings:GetDBVersion())
end

function Addon:PrintHelp()
	local function PrintCmd(cmd, desc)
		print(string.format(' - |cFF33FF99%s|r: %s', cmd, desc))
	end

	self:Print(L.Commands)
	PrintCmd('bags', L.CmdShowInventory)
	PrintCmd('bank', L.CmdShowBank)
	PrintCmd('version', L.CmdShowVersion)
end

function Addon:ShowOptions()
	if LoadAddOn(ADDON .. '_Config') then
		InterfaceOptionsFrame_OpenToCategory(self.GeneralOptions)
		return true
	end
end