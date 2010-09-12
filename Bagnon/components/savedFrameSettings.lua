--[[
	savedFrameSettings.lua
		Persistent frame settings
--]]

local SavedFrameSettings = {}
local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
Bagnon.SavedFrameSettings = SavedFrameSettings


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

SavedFrameSettings.mt = {
	__index = SavedFrameSettings
}

SavedFrameSettings.objects = setmetatable({}, {__index = function(tbl, id)
	local obj = setmetatable({frameID = id}, SavedFrameSettings.mt)
	tbl[id] = obj
	return obj
end})

function SavedFrameSettings:Get(id)
	return self.objects[id]
end


--[[---------------------------------------------------------------------------
	Events
--]]---------------------------------------------------------------------------

--create an event handler
do
	local f = CreateFrame('Frame')
	f:SetScript('OnEvent', function(self, event, ...)
		local action = SavedFrameSettings[event]
		if action then
			action(SavedFrameSettings, event, ...)
		end
	end)

	f:RegisterEvent('PLAYER_LOGOUT')
end

--remove any settings that are set to defaults upon logout
function SavedFrameSettings:PLAYER_LOGOUT()
	self:ClearDefaults()
end


--[[---------------------------------------------------------------------------
	Accessor Methods
--]]---------------------------------------------------------------------------

--get settings for all frames
--only one instance of this for everything (hence the lack of self use)
function SavedFrameSettings:GetGlobalDB()
	if not SavedFrameSettings.db then
		SavedFrameSettings.db = _G['BagnonFrameSettings']

		if SavedFrameSettings.db then
			if self:IsDBOutOfDate() then
				self:UpgradeDB()
			end
		else
			SavedFrameSettings.db = {
				frames = {},
				version = self:GetAddOnVersion()
			}
			_G['BagnonFrameSettings'] = SavedFrameSettings.db
		end
	end
	return SavedFrameSettings.db
end

--get frame specific settings
function SavedFrameSettings:GetDB()
	if not self.frameDB then
		self.frameDB = self:GetGlobalDB().frames[self:GetFrameID()]

		if not self.frameDB then
			self.frameDB = {}
			self:GetGlobalDB().frames[self:GetFrameID()] = self.frameDB
		end

		copyDefaults(self.frameDB, self:GetDefaultSettings())
	end
	return self.frameDB
end

function SavedFrameSettings:GetFrameID()
	return self.frameID
end


--[[---------------------------------------------------------------------------
	Upgrade Methods
--]]---------------------------------------------------------------------------

function SavedFrameSettings:UpgradeDB()
	local major, minor, bugfix = self:GetDBVersion():match('(%w+)%.(%w+)%.(%w+)')
	local db = self:GetGlobalDB()
	
	--hidden bags upgrade
	for frameID, settings in pairs(db.frames) do
		local hiddenBags = settings.hiddenBags
		if hiddenBags then
			for k, v in pairs(hiddenBags) do
				if tonumber(k) and tonumber(v) then
					hiddenBags[v] = true
					hiddenBags[k] = nil
				end
			end
		end
	end

	db.version = self:GetAddOnVersion()
end

function SavedFrameSettings:IsDBOutOfDate()
	return self:GetDBVersion() ~= self:GetAddOnVersion()
end

function SavedFrameSettings:GetDBVersion()
	return self:GetGlobalDB().version
end

function SavedFrameSettings:GetAddOnVersion()
	return GetAddOnMetadata('Bagnon', 'Version')
end

function SavedFrameSettings:ClearDefaults()
	local db = self:GetGlobalDB()

	for frameID, settings in pairs(db.frames) do
		removeDefaults(settings, self:GetDefaultSettings(frameID))
		
		if next(settings) == nil then
			db[frameID] = nil
		end
	end
end


--[[---------------------------------------------------------------------------
	Update Methods
--]]---------------------------------------------------------------------------

--[[ Frame Color ]]--

--background
function SavedFrameSettings:SetColor(r, g, b, a)
	local color = self:GetDB().frameColor
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = a
end

function SavedFrameSettings:GetColor()
	local r, g, b, a = unpack(self:GetDB().frameColor)
	return r, g, b, a
end

--border
function SavedFrameSettings:SetBorderColor(r, g, b, a)
	local color = self:GetDB().frameBorderColor
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = a
end

function SavedFrameSettings:GetBorderColor()
	local r, g, b, a = unpack(self:GetDB().frameBorderColor)
	return r, g, b, a
end


--[[ Frame Position ]]--

function SavedFrameSettings:SetPosition(point, x, y)
	local db = self:GetDB()
	db.point = point
	db.x = x
	db.y = y
end

function SavedFrameSettings:GetPosition()
	local db = self:GetDB()
	return db.point, db.x, db.y
end


--[[ Frame Scale ]]--

function SavedFrameSettings:SetScale(scale)
	self:GetDB().scale = scale
end

function SavedFrameSettings:GetScale()
	return self:GetDB().scale
end


--[[ Frame Opacity ]]--

function SavedFrameSettings:SetOpacity(opacity)
	self:GetDB().opacity = opacity
end

function SavedFrameSettings:GetOpacity()
	return self:GetDB().opacity
end


--[[ Frame Layer]]--

function SavedFrameSettings:SetLayer(layer)
	self:GetDB().frameLayer = layer
end

function SavedFrameSettings:GetLayer()
	return self:GetDB().frameLayer
end


--[[ Frame Components ]]--

function SavedFrameSettings:SetHasBagFrame(enable)
	self:GetDB().hasBagFrame = enable or false
end

function SavedFrameSettings:HasBagFrame()
	return self:GetDB().hasBagFrame
end

function SavedFrameSettings:SetHasMoneyFrame(enable)
	self:GetDB().hasMoneyFrame = enable or false
end

function SavedFrameSettings:HasMoneyFrame()
	return self:GetDB().hasMoneyFrame
end

function SavedFrameSettings:SetHasDBOFrame(enable)
	self:GetDB().hasDBOFrame = enable or false
end

function SavedFrameSettings:HasDBOFrame()
	return self:GetDB().hasDBOFrame
end

function SavedFrameSettings:SetHasSearchToggle(enable)
	self:GetDB().hasSearchToggle = enable or false
end

function SavedFrameSettings:HasSearchToggle()
	return self:GetDB().hasSearchToggle
end

function SavedFrameSettings:SetHasOptionsToggle(enable)
	self:GetDB().hasOptionsToggle = enable or false
end

function SavedFrameSettings:HasOptionsToggle()
	return self:GetDB().hasOptionsToggle
end


--[[ Frame Bags ]]--

--show a bag
function SavedFrameSettings:ShowBag(bag)
	self:GetDB().hiddenBags[bag] = false
end

--hide a bag
function SavedFrameSettings:HideBag(bag)
	self:GetDB().hiddenBags[bag] = true
end

function SavedFrameSettings:IsBagShown(bag)
	return not self:GetDB().hiddenBags[bag]
end

--get all available bags
function SavedFrameSettings:GetBags()
	return self:GetDB().availableBags
end

--get all hidden bags
function SavedFrameSettings:GetHiddenBags()
	return self:GetDB().hiddenBags
end


--[[ Item Frame Layout ]]--

--columns
function SavedFrameSettings:SetItemFrameColumns(columns)
	self:GetDB().itemFrameColumns = columns
end

function SavedFrameSettings:GetItemFrameColumns()
	return self:GetDB().itemFrameColumns
end

--spacing
function SavedFrameSettings:SetItemFrameSpacing(spacing)
	self:GetDB().itemFrameSpacing = spacing
end

function SavedFrameSettings:GetItemFrameSpacing()
	return self:GetDB().itemFrameSpacing
end

--bag break layout
function SavedFrameSettings:SetBagBreak(enable)
	self:GetDB().bagBreak = enable
end

function SavedFrameSettings:IsBagBreakEnabled()
	return self:GetDB().bagBreak
end


--[[ Item Frame Slot ORdering ]]--

function SavedFrameSettings:SetReverseSlotOrder(enable)
	self:GetDB().reverseSlotOrder = enable
end

function SavedFrameSettings:IsSlotOrderReversed()
	return self:GetDB().reverseSlotOrder
end


--[[ Databroker Display Object ]]--

function SavedFrameSettings:SetBrokerDisplayObject(objectName)
	self:GetDB().dataBrokerObject = objectName
end

function SavedFrameSettings:GetBrokerDisplayObject()
	return self:GetDB().dataBrokerObject
end


--[[---------------------------------------------------------------------------
	Frame Defaults
--]]---------------------------------------------------------------------------

--generic
function SavedFrameSettings:GetDefaultSettings(frameID)
	local frameID = frameID or self:GetFrameID()

	if frameID == 'keys' then
		return self:GetDefaultKeyRingSettings()
	elseif frameID == 'bank' then
		return self:GetDefaultBankSettings()
	elseif frameID == 'guildbank' then
		return self:GetDefaultGuildBankSettings()
	end

	return self:GetDefaultInventorySettings()
end

--inventory
function SavedFrameSettings:GetDefaultInventorySettings()
	local defaults = SavedFrameSettings.invDefaults or {
		--bag settings
		availableBags = {BACKPACK_CONTAINER, 1, 2, 3, 4, KEYRING_CONTAINER},
	
		hiddenBags = {			
			[BACKPACK_CONTAINER] = false,
			[1] = false,
			[2] = false,
			[3] = false,
			[4] = false,
			[KEYRING_CONTAINER] = true,
		},

		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {1, 1, 1, 1},
		scale = 1,
		opacity = 1,
		point = 'BOTTOMRIGHT',
		x = 0,
		y = 150,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 8,
		itemFrameSpacing = 2,
		bagBreak = false,

		--optional components
		hasMoneyFrame = true,
		hasBagFrame = true,
		hasDBOFrame = true,
		hasSearchToggle = true,
		hasOptionsToggle = true,
		hasKeyringToggle = true,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
		
		--slot ordering
		reverseSlotOrder = false,
	}

	SavedFrameSettings.invDefaults = defaults
	return defaults
end

--bank
function SavedFrameSettings:GetDefaultBankSettings()
	local defaults = SavedFrameSettings.bankDefaults or {
		--bag settings
		availableBags = {BANK_CONTAINER, 5, 6, 7, 8, 9, 10, 11},
		hiddenBags = {
			[BANK_CONTAINER] = false,
			[5] = false,
			[6] = false,
			[7] = false,
			[8] = false,
			[9] = false,
			[10] = false,
			[11] = false
		},

		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {1, 1, 0, 1},
		scale = 1,
		opacity = 1,
		point = 'BOTTOMLEFT',
		x = 0,
		y = 150,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 10,
		itemFrameSpacing = 2,
		bagBreak = false,

		--optional components
		hasMoneyFrame = true,
		hasBagFrame = true,
		hasDBOFrame = true,
		hasSearchToggle = true,
		hasOptionsToggle = true,
		hasKeyringToggle = false,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
		
		--slot ordering
		reverseSlotOrder = false,
	}
	SavedFrameSettings.bankDefaults = defaults
	return defaults
end

--keys
function SavedFrameSettings:GetDefaultKeyRingSettings()
	local defaults = SavedFrameSettings.keyDefaults or {
		--bag settings
		availableBags = {KEYRING_CONTAINER},
		hiddenBags = {
			[KEYRING_CONTAINER] = false
		},

		--frame,
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {0, 1, 1, 1},
		scale = 1,
		opacity = 1,
		point = 'BOTTOMRIGHT',
		x = -350,
		y = 150,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 4,
		itemFrameSpacing = 2,
		bagBreak = false,

		--optional components
		hasMoneyFrame = false,
		hasBagFrame = false,
		hasDBOFrame = false,
		hasSearchToggle = false,
		hasOptionsToggle = true,
		hasKeyringToggle = false,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
		
		--slot ordering
		reverseSlotOrder = false,
	}
	SavedFrameSettings.keyDefaults = defaults
	return defaults
end

function SavedFrameSettings:GetDefaultGuildBankSettings()
	return self:GetDefaultInventorySettings()
end