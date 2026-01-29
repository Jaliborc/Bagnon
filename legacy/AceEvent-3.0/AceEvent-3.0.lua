--- AceEvent-3.0 provides event registration and dispatching.
-- 12.0 SAFE VERSION (static event registration)

local CallbackHandler = LibStub("CallbackHandler-1.0")

local MAJOR, MINOR = "AceEvent-3.0", 4
local AceEvent = LibStub:NewLibrary(MAJOR, MINOR)
if not AceEvent then return end

-- Lua APIs
local pairs = pairs

-- =========================================================
-- Use an anonymous frame (never protected)
-- =========================================================
AceEvent.frame = AceEvent.frame or CreateFrame("Frame")
AceEvent.embeds = AceEvent.embeds or {}

-- =========================================================
-- CallbackHandler registry (NO dynamic RegisterEvent)
-- =========================================================
if not AceEvent.events then
	AceEvent.events = CallbackHandler:New(
		AceEvent,
		"RegisterEvent",
		"UnregisterEvent",
		"UnregisterAllEvents"
	)
end

-- =========================================================
-- 12.0 FIX: DO NOTHING HERE (critical)
-- Blizzard forbids this path entirely
-- =========================================================
function AceEvent.events:OnUsed(target, eventname)
	-- intentionally empty
end

function AceEvent.events:OnUnused(target, eventname)
	-- intentionally empty
end

-- =========================================================
-- IPC messages (safe, no Blizzard API)
-- =========================================================
if not AceEvent.messages then
	AceEvent.messages = CallbackHandler:New(
		AceEvent,
		"RegisterMessage",
		"UnregisterMessage",
		"UnregisterAllMessages"
	)
	AceEvent.SendMessage = AceEvent.messages.Fire
end

-- =========================================================
-- Embedding support
-- =========================================================
local mixins = {
	"RegisterEvent", "UnregisterEvent",
	"RegisterMessage", "UnregisterMessage",
	"SendMessage",
	"UnregisterAllEvents", "UnregisterAllMessages",
}

function AceEvent:Embed(target)
	for _, method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

function AceEvent:OnEmbedDisable(target)
	target:UnregisterAllEvents()
	target:UnregisterAllMessages()
end

-- =========================================================
-- Event dispatcher
-- =========================================================
local events = AceEvent.events
AceEvent.frame:SetScript("OnEvent", function(_, event, ...)
	events:Fire(event, ...)
end)

-- =========================================================
-- STATIC EVENT REGISTRATION (12.0 SAFE)
-- These cover Bagnon + BagBrother
-- =========================================================
local staticEvents = {
	"BAG_UPDATE",
	"BAG_UPDATE_DELAYED",
	"PLAYERBANKSLOTS_CHANGED",
	-- "PLAYERBANKBAGSLOTS_CHANGED",
	-- "PLAYERREAGENTBANKSLOTS_CHANGED",
	"PLAYER_MONEY",
	"BANKFRAME_OPENED",
	"BANKFRAME_CLOSED",
}

for _, event in ipairs(staticEvents) do
	AceEvent.frame:RegisterEvent(event)
end

-- =========================================================
-- Upgrade existing embeds
-- =========================================================
for target in pairs(AceEvent.embeds) do
	AceEvent:Embed(target)
end
