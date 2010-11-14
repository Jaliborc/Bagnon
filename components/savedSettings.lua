--[[
	dbSettings.lua
		Database access for Bagnon
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon')
local SavedSettings = {}
Bagnon.SavedSettings = SavedSettings


--[[---------------------------------------------------------------------------
	Local Functions of Justice
--]]---------------------------------------------------------------------------

local function removeDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(tbl[k]) == 'table' and type(v) == 'table' then
			removeDefaults(tbl[k], v)

			if next(tbl[k]) == nil then
				tbl[k] = nil
			end
		elseif tbl[k] == v then
			tbl[k] = nil
		end
	end
end

local function copyDefaults(tbl, defaults)
	for k, v in pairs(defaults) do
		if type(v) == 'table' then
			tbl[k] = copyDefaults(tbl[k] or {}, v)
		elseif tbl[k] == nil then
			tbl[k] = v
		end
	end
	return tbl
end


--[[---------------------------------------------------------------------------
	Constructorish
--]]---------------------------------------------------------------------------

function SavedSettings:GetDB()
	if not self.db then
		self.db = _G['BagnonGlobalSettings']
		
		if self.db then
			if self:IsDBOutOfDate() then
				self:UpgradeDB()
			end
		else
			self.db = self:CreateNewDB()
			Bagnon:Print(L.NewUser)
		end
		
		copyDefaults(self.db, self:GetDefaultSettings())
	end
	return self.db
end

function SavedSettings:GetDefaultSettings()
	self.defaults = self.defaults or {
		highlightItemsByQuality = true,
		highlightQuestItems = true,
		showEmptyItemSlotTexture = true,
		lockFramePositions = false,
		colorBagSlots = true,
		
		enableBlizzardBagPassThrough = false,
		
		enabledFrames = {
			inventory = true,
			bank = true,
			keys = true,
		},
		
		autoDisplayEvents = {
			inventory = {
				ah = false,
				bank = true,
				vendor = true,
				mail = true,
				guildbank = true,
				trade = false,
				craft = false,
				player = false
			},
		},
		
		slotColors = {
			ammo = {0.7, 0.7, 1},
			trade = {0.5, 1, 0.5},
			shard = {0.9, 0.7, 1},
			keyring = {1, 0.8, 0},
		},
		
		highlightOpacity = 0.5,
	}
	
	return self.defaults
end

--[[---------------------------------------------------------------------------
	Upgrade Methods
--]]---------------------------------------------------------------------------


function SavedSettings:CreateNewDB()
	local db = {
		version = self:GetAddOnVersion()
	}
	
	_G['BagnonGlobalSettings'] = db
	return db
end

function SavedSettings:UpgradeDB()
	local major, minor, bugfix = self:GetDBVersion():match('(%w+)%.(%w+)%.(%w+)')
	
	--do upgrade stuff
	if tonumber(minor) <= 6 and tonumber(bugfix) <= 2 then
		local db = self.db
		local autoDisplayEvents = self.db.autoDisplayEvents
		if autoDisplayEvents then
			for i = 1, #autoDisplayEvents do
				autoDisplayEvents[i] = nil
			end
		end
	end

	self:GetDB().version = self:GetAddOnVersion()
	Bagnon:Print(string.format(L.Updated, self:GetDBVersion()))
end

function SavedSettings:IsDBOutOfDate()
	return self:GetDBVersion() ~= self:GetAddOnVersion()
end

function SavedSettings:GetDBVersion()
	return self:GetDB().version
end

function SavedSettings:GetAddOnVersion()
	return GetAddOnMetadata('Bagnon', 'Version')
end


--[[---------------------------------------------------------------------------
	Events
--]]---------------------------------------------------------------------------


--create an event handler
do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, ...)
		local action = SavedSettings[event]
		
		if action then
			action(SavedSettings, event, ...)
		end
	end)
	
	f:RegisterEvent('PLAYER_LOGOUT')
end

--remove any settings that are set to defaults upon logout
function SavedSettings:PLAYER_LOGOUT()
	self:UpdateEnableFrames()
	self:UpdateEnableBlizzardBagPassThrough()
	self:ClearDefaults()
end

--handle enabling/disabling of frames
function SavedSettings:UpdateEnableFrames()
	local framesToEnable = Bagnon.Settings.framesToEnable
	
	if framesToEnable then
		for frameID, enableStatus in pairs(framesToEnable) do
			self:GetDB().enabledFrames[frameID] = enableStatus
		end
	end
end

function SavedSettings:UpdateEnableBlizzardBagPassThrough()
	self:GetDB().enableBlizzardBagPassThrough = Bagnon.Settings:WillBlizzardBagPassThroughBeEnabled()
end

function SavedSettings:ClearDefaults()
	if self.db then
		removeDefaults(self.db, self:GetDefaultSettings())
	end
end


--[[---------------------------------------------------------------------------
	Complex Settings
--]]---------------------------------------------------------------------------

--frame auto display events
function SavedSettings:SetShowFrameAtEvent(frameID, event, enable)
	self:GetDB().autoDisplayEvents[frameID][event] = enable and true or false
end

function SavedSettings:IsFrameShownAtEvent(frameID, event)
	return self:GetDB().autoDisplayEvents[frameID][event]
end
