--[[
	SavedFrameSettings.lua
		behold the monkeypatching
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local SavedFrameSettings = Bagnon.SavedFrameSettings

function SavedFrameSettings:GetDefaultGuildBankSettings()
	local defaults = SavedFrameSettings.guildBankDefaults or {
		--frame
		frameColor = {0, 0, 0, 0.5},
		frameBorderColor = {0, 1, 0, 1},
		scale = 1,
		opacity = 1,
		point = 'CENTER',
		x = 0,
		y = 0,
		frameLayer = 'HIGH',

		--itemFrame
		itemFrameColumns = 14,
		itemFrameSpacing = 2,

		--optional components
		hasMoneyFrame = false,
		hasBagFrame = true,
		hasDBOFrame = true,
		hasSearchToggle = true,
		hasOptionsToggle = true,

		--dbo display object
		dataBrokerObject = 'BagnonLauncher',
	}

	SavedFrameSettings.guildBankDefaults = defaults
	return defaults
end