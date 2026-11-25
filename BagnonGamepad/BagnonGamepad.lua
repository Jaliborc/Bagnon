-- Bagnon Gamepad: controller navigation for Bagnon windows on WoW Forever.
--
-- Forever's own controller navigation can't be used for addon windows: handing an addon frame to
-- GamepadMode.FrameControlsManager taints its binding switch, and the game then blocks
-- SetPreferredGamepadInteractTarget ("ADDON FORBIDDEN"). Instead, while a Bagnon window is open
-- (gamepad UI on, out of combat), this addon takes over a few controller buttons with its own
-- priority override bindings, ConsolePort-style:
--   D-pad          move a highlight between item slots and header controls (tooltip follows)
--   A (PAD1)       use / equip / sell the item (right click on the slot); on other controls a
--                  normal click, on the search box focus
--   X (PAD3)       pick up / place the item (left click); on other controls a right click
--   Y (PAD4)       split the stack (small prompt: D-pad amount, A split, B cancel)
--   LB / RB        switch between open Bagnon windows (inventory, bank, ...)
-- B, LT and RT stay Forever's: B closes the bag (Bagnon follows), LT/RT switch to the vendor,
-- bank, mail or trade window and back. A legend under the window shows these buttons with the
-- game's icons for the connected controller. In combat the bindings are released (they can't
-- change then); the bags keep working with the mouse.
--
-- Taint notes. Forever's controller code blocks protected calls once anything it reads was
-- touched by addon code, so this addon never changes Blizzard frames or calls Blizzard UI from
-- addon code where Forever's controller code reads it:
--  * Blizzard's hidden combined bag is made invisible and click-through, never moved.
--  * Secure buttons (bank slot purchase, putting a held item into a bag, Bagnon's X while the
--    combined bag is open) click Blizzard's own buttons; they are parented to UIParent and only
--    anchored over Bagnon's controls out of combat (a protected child would make Bagnon's window
--    protected).
--  * Bagnon's options open through Settings.OpenToCategory (the game opens the panel itself);
--    Bagnon_Config is loaded at login, and its pages are kept out of the Settings window until
--    selected (FixBagnonPages). On its pages this addon drives the D-pad itself.
--  * Blizzard drop-down menus opened by addon code taint the controller focus manager: Bagnon's
--    character selector and option drop-downs open this addon's own picker instead; its other
--    right-click menus are skipped while the gamepad UI is on.
--  * Money windows that need a keyboard open this addon's money prompt (guild bank, mail gold).

local AddToBagnonOptions
local LogSession, Snapshot, SetDebug
local Bags = _G.Bagnon or _G.BagBrother -- Bagnon embeds the BagBrother core (src/main.xml)
if not (Bags and Bags.Frames) then
	return
end

local owner = CreateFrame("Frame", "BagnonGamepadOwner")
local frames = {}       -- Bagnon windows we hooked, in the order they were last shown
local hooked = {}
local active            -- Bagnon window the highlight is in
local selected          -- selected button
local bound = false
local released = false  -- Forever's frame manager has focused another window (vendor, ...)
local split             -- { button, bag, slot, max, amount } while the split prompt is open
local picker            -- { anchor, entries, index } while the character / location picker is open
local money             -- { mode, amount, max, unit, anchor } while the money prompt is open
local OpenMoneyPrompt   -- defined below
local MoneyClicks       -- defined below
local OpenPicker        -- defined below
local AboveLegend       -- defined below
local opts = {}         -- Bagnon options page navigation: page, list, selected, bound
local ApplyOptions      -- defined below
local optOwnerFrame     -- owner of the options-page bindings (below)

local DPAD = { PADDUP = "UP", PADDDOWN = "DOWN", PADDLEFT = "LEFT", PADDRIGHT = "RIGHT" }
local OUR_KEYS = { PADDUP = true, PADDDOWN = true, PADDLEFT = true, PADDRIGHT = true,
	PAD1 = true, PAD3 = true, PADLSHOULDER = true, PADRSHOULDER = true,
	PADLTRIGGER = true, PADRTRIGGER = true, PAD2 = true, PAD4 = true }
local triggersBound = false

local function GamepadUI()
	return InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
end

--[[ Debug log ]]--

-- Off by default (Bagnon options > Controller, or /bagnonpad log on). Records into the saved
-- variable BagnonGamepadLog (written to WTF/Account/<account>/SavedVariables/BagnonGamepad.lua on
-- /reload or logout), newest last, at most LOG_MAX lines across sessions (oldest dropped first):
--   BLOCKED/FORBIDDEN  every ADDON_ACTION_BLOCKED / _FORBIDDEN (any addon) with the call stack
--   ERROR              Lua errors (message + stack), passed on to the normal error handler
--   TAINT              keys of Forever's controller tables (frame manager, smart navigation, the
--                      game menu, Settings, Blizzard's bag) that turn tainted, and by which addon;
--                      this usually shows up before anything is blocked
--   BIND/FOCUS/WIN/OVERLAY/CLICK/COMBAT/GUARD  what this addon did, for context
local LOG_MAX = 100000
local Log
local function Name(object)
	if object == nil then return "nil" end
	if type(object) ~= "table" then return tostring(object) end
	local ok, name = pcall(function()
		return (object.GetDebugName and object:GetDebugName()) or (object.GetName and object:GetName())
	end)
	return (ok and name) or tostring(object)
end

-- one value for a log line: frames by name, plain tables as "table#<length>"
local function Describe(value)
	if type(value) == "table" and rawget(value, 0) == nil and not value.GetObjectType then
		return "table#" .. #value
	end
	return Name(value)
end

local function ArgsText(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = Describe((select(i, ...)))
	end
	return table.concat(parts, ", ")
end

local function Verbose()
	return BagnonGamepadDB and BagnonGamepadDB.debug and BagnonGamepadDB.debugVerbose
end
local V -- V(category, fmt, ...): Log, only with verbose logging on

do
	local function Enabled()
		return BagnonGamepadDB and BagnonGamepadDB.debug
	end

	local function Store(line)
		BagnonGamepadLog = BagnonGamepadLog or {}
		local lines = BagnonGamepadLog
		lines[#lines + 1] = line
		-- trim in one go once 10% over the limit (removing line by line would shift the whole log
		-- on every new line)
		local n = #lines
		if n > LOG_MAX * 1.1 then
			local drop = n - LOG_MAX
			for i = 1, LOG_MAX do lines[i] = lines[i + drop] end -- (no table.move in this Lua)
			for i = n, LOG_MAX + 1, -1 do lines[i] = nil end
		end
		if BagnonGamepadDB.debugChat then
			print("|cff888888BGP|r " .. line)
		end
	end

	V = function(category, fmt, ...)
		if Verbose() then Log(category, fmt, ...) end
	end

	local wall0, game0
	local function Stamp()
		local now = GetTime()
		if not wall0 then wall0, game0 = time(), now end
		local t = wall0 + (now - game0)
		return ("%s.%03d"):format(date("%H:%M:%S", math.floor(t)), math.floor((t % 1) * 1000))
	end

	Log = function(category, fmt, ...)
		if not Enabled() then return end
		local ok, msg = pcall(string.format, fmt, ...)
		if not ok then msg = tostring(fmt) end
		Store(("%s %s [%s]%s %s"):format(Stamp(), GamepadUI() and "pad" or "kbm", category, InCombatLockdown() and "{combat}" or "", msg))
	end

	-- taint watch
	local WATCH = {
		{ "FrameControlsManager", function() return GamepadMode and GamepadMode.FrameControlsManager end, true },
		{ "SmartNavigation", function() return SmartNavigation end, true },
		{ "GamepadMode", function() return GamepadMode end },
		{ "ContainerFrameCombinedBags", function() return ContainerFrameCombinedBags end },
		{ "GameMenuFrame", function() return GameMenuFrame end },
		{ "SettingsPanel", function() return SettingsPanel end },
		{ "StaticPopup1", function() return StaticPopup1 end },
	}
	local known = {}

	local function Check(label, t, key)
		local secure, by = issecurevariable(t, key)
		local id = label .. "." .. tostring(key)
		if not secure then
			by = by or "?"
			if known[id] ~= by then
				known[id] = by
				Log("TAINT", "%s tainted by %s (value %s)", id, by, Name(rawget(t, key)))
			end
		elseif known[id] then
			known[id] = nil
			Log("TAINT", "%s secure again", id)
		end
	end

	local function ScanTable(label, t, deep)
		for key, value in pairs(t) do
			local kt = type(key)
			if kt == "string" or kt == "number" then
				Check(label, t, key)
				-- one level into plain tables (frame lists, binding sets), not into frames
				if deep and type(value) == "table" and rawget(value, 0) == nil then
					for k2 in pairs(value) do
						local k2t = type(k2)
						if k2t == "string" or k2t == "number" then
							Check(label .. "." .. tostring(key), value, k2)
						end
					end
				end
			end
		end
	end

	local function ScanTaint()
		if not Enabled() then return end
		for _, entry in ipairs(WATCH) do
			local t = entry[2]()
			if type(t) == "table" and not (t.IsForbidden and t:IsForbidden()) then
				pcall(ScanTable, entry[1], t, entry[3])
			end
		end
	end
	BagnonGamepadScanTaint = ScanTaint

	-- deep scan: every global, plus Blizzard registries addons may write into (UISpecialFrames,
	-- UIPanelWindows, EventRegistry callbacks, the gamepad tables), for values tainted by an
	-- addon whose name isn't the addon's own (Bagnon writing into Blizzard's state is what breaks
	-- the controller UI). Run after a Bagnon module loads, after a blocked call, every 10 s with verbose
	-- logging, and with /bagnonpad log scan.
	local deepKnown = {}
	local OWN = { Bagnon = true, BagBrother = true, Sushi = true, BagnonGamepad = true }
	local function OwnName(key, by)
		if type(key) ~= "string" then return false end
		local prefix = key:match("^%a+")
		return (prefix and (OWN[prefix] or prefix:find("^Bagnon") or prefix:find("^BagBrother"))) or (by and key:find("^" .. by))
	end
	local function Report(id, by, value)
		if deepKnown[id] ~= by then
			deepKnown[id] = by
			Log("TAINT", "deep: %s tainted by %s (value %s)", id, by, Name(value))
		end
	end
	local function Walk(label, t, depth, seen)
		if seen[t] or depth < 0 then return end
		if type(t.IsForbidden) == "function" and t:IsForbidden() then return end
		seen[t] = true
		for key, value in pairs(t) do
			local kt = type(key)
			if kt == "string" or kt == "number" then
				local secure, by = issecurevariable(t, key)
				if not secure and by and by:find("Bag") then
					Report(label .. "." .. tostring(key), by, value)
				end
				if depth > 0 and type(value) == "table" and rawget(value, 0) == nil then
					Walk(label .. "." .. tostring(key), value, depth - 1, seen)
				end
			end
		end
	end
	local function DeepScan(reason)
		if not Enabled() then return end
		local start = debugprofilestop()
		local found = 0
		for key in pairs(_G) do
			if type(key) == "string" then
				local secure, by = issecurevariable(key)
				if not secure and by and by:find("Bag") and not OwnName(key, by) then
					found = found + 1
					Report("_G." .. key, by, rawget(_G, key))
				end
			end
		end
		local seen = {}
		if type(UISpecialFrames) == "table" then Walk("UISpecialFrames", UISpecialFrames, 0, seen) end
		if type(UIPanelWindows) == "table" then Walk("UIPanelWindows", UIPanelWindows, 1, seen) end
		if type(EventRegistry) == "table" then Walk("EventRegistry", EventRegistry, 4, seen) end
		if type(GamepadMode) == "table" then Walk("GamepadMode", GamepadMode, 2, seen) end
		if type(SmartNavigation) == "table" then Walk("SmartNavigation", SmartNavigation, 2, seen) end
		Log("TAINT", "deep scan (%s): %d foreign globals, %.1f ms", reason, found, debugprofilestop() - start)
	end
	BagnonGamepadDeepScan = DeepScan
	-- the global walk can take tens of ms: on a timer only with verbose logging
	C_Timer.NewTicker(10, function()
		if BagnonGamepadDB and BagnonGamepadDB.debugVerbose then DeepScan("timer") end
	end)

	local ticker
	local errorWrapped = false
	local function Start()
		if not ticker then
			ticker = C_Timer.NewTicker(1, ScanTaint)
		end
		-- Lua errors: log, then hand on to whatever handler was there
		if not errorWrapped and geterrorhandler and seterrorhandler then
			errorWrapped = true
			local previous = geterrorhandler()
			seterrorhandler(function(msg, ...)
				if Enabled() then
					Log("ERROR", "%s\n%s", tostring(msg), debugstack(2, 20, 0) or "")
				end
				return previous(msg, ...)
			end)
		end
	end
	local function Stop()
		if ticker then ticker:Cancel() ticker = nil end
	end
	BagnonGamepadDebugStart, BagnonGamepadDebugStop = Start, Stop

	local events = CreateFrame("Frame")
	for _, event in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN",
		"MACRO_ACTION_BLOCKED", "MACRO_ACTION_FORBIDDEN", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
		"GAME_PAD_ACTIVE_CHANGED", "GAME_PAD_CONNECTED", "GAME_PAD_DISCONNECTED", "LOADING_SCREEN_DISABLED" }) do
		pcall(events.RegisterEvent, events, event)
	end
	pcall(events.RegisterEvent, events, "ADDON_LOADED")
	if type(StaticPopup_Show) == "function" then
		hooksecurefunc("StaticPopup_Show", function(which, text1)
			Log("POPUP", "StaticPopup_Show(%s, %s)\n%s", tostring(which), tostring(text1), debugstack(3, 12, 0) or "")
		end)
	end
	events:SetScript("OnEvent", function(_, event, ...)
		if not Enabled() then return end
		if event == "ADDON_LOADED" then
			local addon = tostring((...))
			Log("EVENT", "ADDON_LOADED %s\n%s", addon, debugstack(2, 12, 0) or "")
			if addon:find("^Bag") then
				C_Timer.After(0, function() BagnonGamepadDeepScan("after loading " .. addon) end)
			end
			return
		end
		if event:find("_ACTION_") then
			-- these fire inside the blocked call, so the stack shows who made it
			local a, b = ...
			Log(event:find("FORBIDDEN") and "FORBIDDEN" or "BLOCKED", "%s %s %s\n%s", event,
				tostring(a), tostring(b), debugstack(2, 40, 0) or "")
			ScanTaint()
			C_Timer.After(0, function() BagnonGamepadDeepScan("after " .. event) end)
		elseif event:find("REGEN") then
			Log("COMBAT", event == "PLAYER_REGEN_DISABLED" and "enter combat" or "leave combat")
		else
			Log("EVENT", "%s %s", event, tostring((...)))
		end
	end)
end

--[[ Debug log: Bagnon activity (mouse and keyboard as well as controller) ]]--

-- Post-hooks only (hooksecurefunc), so logging can't change what Bagnon or Blizzard do. Each line
-- carries "pad" or "kbm" for the input mode at that moment.
local LogActivityHooks
do
	local hookedMethods = {}

	local function Args(...)
		local parts = {}
		for i = 1, select("#", ...) do
			parts[#parts + 1] = Name((select(i, ...)))
		end
		return table.concat(parts, ", ")
	end

	local function HookMethods(label, class, methods)
		if type(class) ~= "table" then return end
		for _, method in ipairs(methods) do
			local key = label .. ":" .. method
			if not hookedMethods[key] and type(rawget(class, method)) == "function" then
				hookedMethods[key] = true
				hooksecurefunc(class, method, function(self, ...)
					if self == class then
						Log("BAGNON", "%s(%s)", key, Args(...))
					else
						Log("BAGNON", "%s(%s) on %s", key, Args(...), Name(self))
					end
				end)
			end
		end
	end

	local function ItemText(button)
		local bag = button.GetBag and button:GetBag()
		local slot = button.GetID and button:GetID()
		local info = button.info
		return ("%s bag=%s slot=%s item=%s count=%s"):format(Name(button), tostring(bag), tostring(slot),
			tostring(info and (info.hyperlink or info.itemID)), tostring(info and info.stackCount))
	end

	local function CursorText()
		local kind, a, b = GetCursorInfo()
		if not kind then return "empty" end
		return ("%s %s %s"):format(tostring(kind), tostring(a), tostring(b))
	end

	LogActivityHooks = function()
		HookMethods("Frames", Bags.Frames, { "Toggle", "Show", "Hide", "ToggleBag", "ShowBag", "HideBag" })
		HookMethods("Bag", Bags.Bag, { "OnClick", "OnDragStart", "Toggle", "ShowMenu" })
		HookMethods("SortButton", Bags.SortButton, { "OnClick" })
		HookMethods("Sorting", Bags.Sorting, { "Start", "Stop" })
		HookMethods("Tab", Bags.Tab, { "OnClick" })
		HookMethods("DepositButton", Bags.DepositButton, { "OnClick" })
		HookMethods("OfflineSelector", Bags.OfflineSelector, { "OnClick" })
		HookMethods("Owners", Bags.Owners, { "SetCurrent" })
		local item = Bags.Item
		if type(item) == "table" and not hookedMethods["Item:OnEnter"] and type(rawget(item, "OnEnter")) == "function" then
			hookedMethods["Item:OnEnter"] = true
			hooksecurefunc(item, "OnEnter", function(self)
				V("HOVER", "%s", ItemText(self))
			end)
		end
		local item = Bags.Item
		if type(item) == "table" and not hookedMethods["Item:PostClick"] and type(rawget(item, "PostClick")) == "function" then
			hookedMethods["Item:PostClick"] = true
			hooksecurefunc(item, "PostClick", function(self, button)
				Log("ITEM", "%s click %s, cursor now %s", ItemText(self), tostring(button), CursorText())
			end)
		end
	end

	-- Blizzard's bag/panel entry points (Bagnon hooks the same ones to take over)
	for _, name in ipairs({ "ToggleBag", "ToggleBackpack", "ToggleAllBags", "OpenAllBags", "CloseAllBags",
		"OpenBag", "CloseBag", "OpenBackpack", "CloseBackpack", "ShowUIPanel", "HideUIPanel", "MaximizeUIPanel" }) do
		if type(_G[name]) == "function" then
			hooksecurefunc(name, function(...)
				Log("BLIZZ", "%s(%s)", name, Args(...))
			end)
		end
	end

	local lastCursor
	local events = CreateFrame("Frame")
	local EVENTS = {
		"BANKFRAME_OPENED", "BANKFRAME_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "MAIL_SHOW", "MAIL_CLOSED",
		"AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "GUILDBANKFRAME_OPENED", "GUILDBANKFRAME_CLOSED",
		"TRADE_SHOW", "TRADE_CLOSED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
		"UI_ERROR_MESSAGE", "CURSOR_CHANGED", "BAG_CONTAINER_UPDATE", "PLAYERBANKSLOTS_CHANGED",
		"BANK_TABS_CHANGED", "BANK_TAB_SETTINGS_UPDATED", "EQUIPMENT_SWAP_FINISHED",
	}
	for _, event in ipairs(EVENTS) do
		pcall(events.RegisterEvent, events, event)
	end
	events:SetScript("OnEvent", function(_, event, ...)
		if not (BagnonGamepadDB and BagnonGamepadDB.debug) then return end
		if event == "CURSOR_CHANGED" then
			local text = CursorText()
			if text ~= lastCursor then
				lastCursor = text
				Log("EVENT", "CURSOR_CHANGED -> %s", text)
			end
		else
			Log("EVENT", "%s %s", event, Args(...))
		end
	end)
end
LogActivityHooks()

--[[ Highlight ]]--

local cursor = CreateFrame("Frame", nil, UIParent)
cursor:SetFrameStrata("TOOLTIP")
cursor:Hide()
do
	local function edge(p1, p2, w, h)
		local t = cursor:CreateTexture(nil, "OVERLAY")
		t:SetColorTexture(1, 0.82, 0, 1)
		t:SetPoint(p1)
		t:SetPoint(p2)
		if w then t:SetWidth(w) end
		if h then t:SetHeight(h) end
	end
	edge("TOPLEFT", "TOPRIGHT", nil, 2)
	edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
	edge("TOPLEFT", "BOTTOMLEFT", 2, nil)
	edge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
end

-- Forever's gold navigation arrow, drawn next to the selection (same art, colour and anchor as
-- SmartNavigation's pointer, with a smaller bob: RIGHT of the arrow on the LEFT of the button). Forever's
-- own pointer points at the invisible Blizzard bag while Bagnon has focus, so it is hidden then
-- (SmartNavigation:HideCursor, called without arguments) and comes back by itself when Forever
-- focuses another window.
local arrow = CreateFrame("Frame", "BagnonGamepadArrow", UIParent)
arrow:SetSize(10, 10)
arrow:SetFrameStrata("TOOLTIP")
arrow:Hide()
do
	local icon = CreateFrame("Frame", nil, arrow)
	icon:SetAllPoints()
	local tex = icon:CreateTexture(nil, "ARTWORK")
	tex:SetAtlas("gamepad-largecursor-white", true)
	tex:SetScale(0.8)
	tex:SetPoint("RIGHT") -- the arrow's tip is the frame's right edge
	-- gentle bob like Forever's pointer (its template uses 4px; 2px here)
	local bob = icon:CreateAnimationGroup()
	bob:SetLooping("REPEAT")
	local out = bob:CreateAnimation("Translation")
	out:SetOffset(2, 0)
	out:SetDuration(1)
	out:SetOrder(1)
	out:SetSmoothing("IN_OUT")
	local back = bob:CreateAnimation("Translation")
	back:SetOffset(-2, 0)
	back:SetDuration(1)
	back:SetOrder(2)
	back:SetSmoothing("IN_OUT")
	bob:Play()
	local color = GAMEPAD_SMARTNAV_CURSOR_COLOR
	if color and color.GetRGBA then
		tex:SetVertexColor(color:GetRGBA())
	else
		tex:SetVertexColor(1, 0.82, 0, 1)
	end
end

-- The held item travels with the arrow, like Forever's GamepadItemPickupCursor (item icon with
-- the cursor_item_32 hand overlay, BOTTOMLEFT on the pointer's BOTTOMRIGHT +5). Forever's own one
-- hangs off its hidden pointer (over the invisible Blizzard bag) while Bagnon has focus, so it is
-- faded out then.
local held = CreateFrame("Frame", nil, arrow)
held:SetSize(32, 32)
held:SetPoint("BOTTOMLEFT", arrow, "BOTTOMRIGHT", 5, 0)
held:Hide()
held.icon = held:CreateTexture(nil, "ARTWORK")
held.icon:SetAllPoints()
held.hand = held:CreateTexture(nil, "OVERLAY")
held.hand:SetAtlas("cursor_item_32")
held.hand:SetAllPoints()

-- gold box and arrow on a frame (bag slots, header buttons, picker rows)
local function PointAt(frame, above, arrowOnly)
	cursor:ClearAllPoints()
	cursor:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
	cursor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
	arrow:ClearAllPoints()
	arrow:SetScale(frame:GetEffectiveScale() / UIParent:GetEffectiveScale())
	arrow:SetPoint("RIGHT", frame, "LEFT", 13, 0)
	if above then
		-- over a TOOLTIP-strata window (picker): stay on top of it
		cursor:SetFrameLevel(above:GetFrameLevel() + 20)
		arrow:SetFrameLevel(above:GetFrameLevel() + 20)
	end
	cursor:SetShown(not arrowOnly)
	arrow:Show()
end

-- Our small windows (picker, split prompt) wear the skin and colours of the Bagnon window they
-- belong to (Bagnon options: Skin, Background and Border colour), through Bagnon's skin API.
-- Panel skins (Blizzard's big panel frames with a title bar) only draw right on large windows:
-- their top corners reach above the frame to hold the title bar. Small windows get the matching
-- compact metal frame (SimplePanelTemplate, same art family) on the panels' flat background.
local PANEL_SKINS = { Bagnonium = true, Combuctor = true, Barber = true }

local function CompactMetal(frame, show)
	if not frame.metal then
		if not show then return end
		local holder = CreateFrame("Frame", nil, frame)
		holder:SetAllPoints()
		holder:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
		-- the panels' flat background colour as one texture (FlatPanelBackgroundTemplate's rounded
		-- corner pieces have a fixed size and stick out of a frame this small)
		holder.flat = holder:CreateTexture(nil, "BACKGROUND")
		holder.flat:SetPoint("TOPLEFT", 3, -3)
		holder.flat:SetPoint("BOTTOMRIGHT", -3, 3)
		local color = PANEL_BACKGROUND_COLOR
		if color and color.GetRGB then
			local r, g, b = color:GetRGB()
			holder.flat:SetColorTexture(r, g, b, 0.96)
		else
			holder.flat:SetColorTexture(0.07, 0.07, 0.07, 0.96)
		end
		pcall(function()
			-- drawn at a smaller scale: the layout's side edges run between fixed-size corners and
			-- are drawn flipped (sticking out) when the frame is shorter than two corners
			holder.border = CreateFrame("Frame", nil, holder, "NineSlicePanelTemplate")
			holder.border:SetScale(0.6)
			holder.border:SetAllPoints()
			NineSliceUtil.ApplyLayoutByName(holder.border, "SimplePanelTemplate")
		end)
		frame.metal = holder
	end
	frame.metal:SetShown(show)
end

-- background, then border, then text / rows, all from the window's own level up
local function LayerSmallWindow(frame, contents)
	local level = frame:GetFrameLevel()
	if frame.bagnonSkin and frame.bagnonSkin:IsShown() then
		frame.bagnonSkin:SetFrameLevel(level)
		-- panel skins put their pieces (title bar, nine-slice, background) at level 0
		for _, piece in ipairs({ frame.bagnonSkin:GetChildren() }) do
			piece:SetFrameLevel(level)
		end
	end
	local metal = frame.metal
	if metal and metal:IsShown() then
		metal:SetFrameLevel(level)
		if metal.bg then metal.bg:SetFrameLevel(level) end
		if metal.border then metal.border:SetFrameLevel(level + 1) end
	end
	for _, f in ipairs(contents) do
		f:SetFrameLevel(level + 3)
	end
end

local function ApplyBagnonSkin(frame, bagnonFrame, skinID, fullPanel)
	local profile = bagnonFrame and bagnonFrame.profile
	if not (profile and Bags.Skins and Bags.Skins.Acquire) then return end
	skinID = skinID or profile.skin
	if PANEL_SKINS[skinID] and not fullPanel then
		if frame.skinKey == "metal" then return end
		if frame.bagnonSkin then frame.bagnonSkin:Release() frame.bagnonSkin = nil end
		CompactMetal(frame, true)
		frame.skinKey = "metal"
		if frame.plainBg then frame.plainBg:Hide() end
		return
	end
	CompactMetal(frame, false)
	local key = tostring(skinID) .. table.concat(profile.color or {}, ",") .. table.concat(profile.borderColor or {}, ",")
	if frame.skinKey == key then return end
	if frame.bagnonSkin then frame.bagnonSkin:Release() end
	local ok, skin = pcall(Bags.Skins.Acquire, Bags.Skins, skinID, frame)
	if not ok or not skin then return end
	local border, center = profile.borderColor or { 1, 1, 1, 1 }, profile.color or { 0, 0, 0, 0.8 }
	skin("load")
	skin("borderColor", border[1], border[2], border[3], border[4])
	skin("centerColor", center[1], center[2], center[3], center[4])
	frame.bagnonSkin, frame.skinKey = skin, key
	if frame.plainBg then frame.plainBg:Hide() end
	if frame.plainEdge then frame.plainEdge:Hide() end
end

local function BagnonFrameOf(control)
	local f = control
	while f do
		if f.profile and f.GetFrameID then return f end
		f = f.GetParent and f:GetParent()
	end
	if active then return active end
	local inventory = Bags.Frames and Bags.Frames.Get and Bags.Frames:Get("inventory")
	return inventory and inventory.profile and inventory or nil
end

local function UpdateHeldItem(ours)
	local icon
	if ours then
		local kind, id = GetCursorInfo()
		if kind == "item" then
			local location = C_Cursor and C_Cursor.GetCursorItem and C_Cursor.GetCursorItem()
			icon = (location and C_Item.GetItemIcon(location)) or (id and C_Item.GetItemIconByID(id))
		end
	end
	held.icon:SetTexture(icon)
	held:SetShown(icon ~= nil)
	-- (Forever makes it off-limits to addons at times, e.g. during a trade)
	local pickup = GamepadItemPickupCursor
	if pickup and not (pickup.IsForbidden and pickup:IsForbidden()) then
		pcall(pickup.SetAlpha, pickup, ours and 0 or 1)
	end
end

local function HideBlizzardPointer()
	local nav = SmartNavigation
	-- (Forever makes it off-limits to addons at times, e.g. during a trade)
	if not nav or (nav.IsForbidden and nav:IsForbidden()) or InCombatLockdown() then return end
	local ok, alpha = pcall(nav.GetAlpha, nav)
	if ok and alpha and alpha > 0 and nav.HideCursor then
		pcall(nav.HideCursor, nav)
	end
end

--[[ Button legend ]]--

-- The game's own icon for a controller button, from the icon set it picked for the connected
-- controller (Xbox, PlayStation or Switch art). Xbox art if the game has none (keyboard mode).
local KEYS = { A = "GAMEPAD_FACE_BOTTOM", B = "GAMEPAD_FACE_RIGHT", X = "GAMEPAD_FACE_LEFT",
	LB = "GAMEPAD_SHOULDER_LEFT", RB = "GAMEPAD_SHOULDER_RIGHT", DPAD = "GAMEPAD_DPAD",
	LT = "GAMEPAD_TRIGGER_LEFT", RT = "GAMEPAD_TRIGGER_RIGHT", Y = "GAMEPAD_FACE_TOP" }
local FALLBACK = { A = "gamepad-xbox1-buttona-normal", B = "gamepad-xbox1-buttonb-normal",
	X = "gamepad-xbox1-buttonx-normal", LB = "gamepad-xbox1-trigger-lb-normal",
	RB = "gamepad-xbox1-trigger-rb-normal", DPAD = "gamepad-xbox1-dpadall-normal",
	LT = "gamepad-xbox1-trigger-lt-normal", RT = "gamepad-xbox1-trigger-rt-normal",
	Y = "gamepad-xbox1-buttony-normal" }

local function GameIcon(key)
	local buttonKey = _G[KEYS[key]]
	local util = InputIconTextureSetUtility
	if buttonKey and util and util.GetNormalActiveInputIconButtonTexture then
		local ok, atlas = pcall(util.GetNormalActiveInputIconButtonTexture, buttonKey)
		if ok and atlas then return atlas end
	end
	return FALLBACK[key]
end

local legend = CreateFrame("Frame", nil, UIParent)
legend:SetFrameStrata("TOOLTIP")
legend:SetHeight(26)
legend:Hide()
do
	local bg = legend:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.75)
end
legend.entries = {}

local function Entry(i)
	local e = legend.entries[i]
	if not e then
		e = { icons = {} }
		for j = 1, 2 do
			local t = legend:CreateTexture(nil, "ARTWORK")
			t:SetSize(20, 20)
			e.icons[j] = t
		end
		e.text = legend:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		legend.entries[i] = e
	end
	return e
end

local function UpdateLegend(show, windowCount)
	if not (show and active and active:IsShown()) or picker then
		legend:Hide()
		return
	end
	local items = {
		{ { "DPAD" }, "Move" },
		{ { "A" }, "Use" },
		{ { "X" }, "Pick up" },
	}
	if money then
		items = { { { "DPAD" }, "Amount" }, { { "LB", "RB" }, "x10" }, { { "Y" }, "Max" },
			{ { "A" }, "OK" }, { { "B" }, "Cancel" } }
		windowCount = 0
	elseif picker then
		items = { { { "DPAD" }, "Choose" }, { { "A" }, "Show" }, { { "B" }, "Back" } }
		windowCount = 0
	elseif split then
		items = { { { "DPAD" }, "Amount" }, { { "A" }, "Split" }, { { "B" }, "Cancel" } }
		windowCount = 0
	elseif selected and selected.bag ~= nil and selected.GetID then
		local info = C_Container.GetContainerItemInfo(selected.bag, selected:GetID())
		if info and (info.stackCount or 0) > 1 then
			items[#items + 1] = { { "Y" }, "Split" }
		end
	end
	if windowCount > 1 then
		items[#items + 1] = { { "LB", "RB" }, "Switch" }
	end
	-- Forever's own window switch (vendor, bank, ...): its triggers move the focus there
	local manager = GamepadMode and GamepadMode.FrameControlsManager
	local ok, shown = pcall(function() return manager and manager:GetShownFrameCount() end)
	if ok and shown and shown > 1 and not split and not picker and not money then
		items[#items + 1] = { { "LT", "RT" }, "Other window" }
	end
	if not split and not picker and not money then
		items[#items + 1] = { { "B" }, "Close" }
	end

	for _, e in pairs(legend.entries) do
		e.icons[1]:Hide(); e.icons[2]:Hide(); e.text:Hide()
	end
	local x = 8
	for i, item in ipairs(items) do
		local e = Entry(i)
		for j, key in ipairs(item[1]) do
			local t = e.icons[j]
			t:SetAtlas(GameIcon(key))
			t:ClearAllPoints()
			t:SetPoint("LEFT", legend, "LEFT", x, 0)
			t:Show()
			x = x + 22
		end
		e.text:SetText(item[2])
		e.text:ClearAllPoints()
		e.text:SetPoint("LEFT", legend, "LEFT", x + 2, 0)
		e.text:Show()
		x = x + e.text:GetStringWidth() + 14
	end
	legend:SetWidth(x - 6)
	legend:SetScale(active:GetEffectiveScale() / UIParent:GetEffectiveScale())
	legend:ClearAllPoints()
	legend:SetPoint("TOP", active, "BOTTOM", 0, -4)
	legend:Show()
end

--[[ Item buttons and controls ]]--

local function IsItemButton(b)
	return b.bag ~= nil and b:IsObjectType("Button") and b:GetName() ~= nil and b:IsVisible()
end

-- any other control a mouse user could click: header buttons, bag toggles, search box, close
local function IsControl(f)
	if not f:IsVisible() or not f:IsMouseEnabled() then return false end
	local w, h = f:GetSize()
	if not (w and h and w > 4 and h > 4) then return false end
	return f:IsObjectType("Button") or f:IsObjectType("EditBox")
end

local function Collect(frame)
	local list, items = {}, {}
	local function walk(f)
		for _, child in ipairs({ f:GetChildren() }) do
			if IsItemButton(child) then
				list[#list + 1] = child
				items[#items + 1] = child
			elseif child:IsVisible() then
				if IsControl(child) then
					list[#list + 1] = child -- don't descend: a button's children are its parts
				else
					walk(child)
				end
			end
		end
	end
	walk(frame)
	return list, items
end

local function Center(b)
	local x, y = b:GetCenter()
	local s = b:GetEffectiveScale()
	return x * s, y * s
end

local function TopLeft(list)
	local best, bx, by
	for _, b in ipairs(list) do
		local x, y = Center(b)
		if not best or y > by + 1 or (math.abs(y - by) <= 1 and x < bx) then
			best, bx, by = b, x, y
		end
	end
	return best
end

local function Neighbour(list, from, dir)
	local x, y = Center(from)
	-- left/right never leave the row: a shorter row (or the end of a row) would otherwise
	-- jump to the next slot in the row above or below instead of wrapping
	local rowTolerance = from:GetHeight() * from:GetEffectiveScale() / 2
	local best, score
	for _, b in ipairs(list) do
		if b ~= from then
			local bx, by = Center(b)
			local along, across
			if dir == "UP" then along, across = by - y, bx - x
			elseif dir == "DOWN" then along, across = y - by, bx - x
			elseif dir == "LEFT" then along, across = x - bx, by - y
			else along, across = bx - x, by - y end
			local sameRow = (dir == "UP" or dir == "DOWN") or math.abs(across) <= rowTolerance
			if along > 1 and sameRow then
				local s = along + 3 * math.abs(across)
				if not score or s < score then
					best, score = b, s
				end
			end
		end
	end
	return best
end

-- Past an edge: wrap to the far side of the same row (left/right) or column (up/down).
-- Staying in the row/column wins over everything (rows are 1000x the weight of positions).
local function Wrap(list, from, dir)
	local x, y = Center(from)
	local best, score
	for _, b in ipairs(list) do
		if b ~= from then
			local bx, by = Center(b)
			local across, pos
			if dir == "RIGHT" then across, pos = math.abs(by - y), bx      -- leftmost in the row
			elseif dir == "LEFT" then across, pos = math.abs(by - y), -bx  -- rightmost in the row
			elseif dir == "UP" then across, pos = math.abs(bx - x), by     -- bottom of the column
			else across, pos = math.abs(bx - x), -by end                  -- top of the column
			local s = across * 1000 + pos
			if not score or s < score then
				best, score = b, s
			end
		end
	end
	return best
end

--[[ Options gear ]]--

-- Bagnon's gear opens Settings from addon code (tainting it on Forever). While the gamepad
-- interface is on, a secure button sits over the gear instead and clicks the game menu's own
-- "Options" button through Blizzard's secure click, so Settings opens untainted (then AddOns >
-- Bagnon). The micro menu button can't be used: it ignores clicks unless the mouse is over it.
-- The game menu's buttons come from a pool and are re-assigned whenever the menu is rebuilt
-- (InitButtons), so the Options button is re-captured by its label after every rebuild, and the
-- reference is cleared before combat (attributes can't change in combat). Until the game menu has
-- been opened once this session there is nothing to click: the gear prints the Esc note instead.
local gearOverlays = {}
local optionsButton

-- Secure overlay buttons are NOT children of Bagnon's frames: a frame with a protected child is
-- protected itself, and Bagnon could then no longer show or hide its window in combat
-- ("ADDON BLOCKED: BagnonInventory1:Hide()"). They are parented to UIParent and anchored over their
-- target only while shown out of combat; they let go of it when the target hides and before combat.
local allOverlays = {}

local function NewOverlay(name, target)
	local overlay = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
	overlay.target = target
	overlay:RegisterForClicks("AnyUp", "AnyDown") -- the template picks up or down itself
	overlay:SetAttribute("type", "click")
	overlay:Hide()
	overlay:SetScript("PostClick", function(self, button, down)
		Log("CLICK", "%s %s %s -> %s", self:GetName(), tostring(button), down and "down" or "up",
			Name(self:GetAttribute("clickbutton")))
	end)
	target:HookScript("OnHide", function()
		if not InCombatLockdown() then
			overlay:Hide()
			overlay:ClearAllPoints()
		end
	end)
	allOverlays[#allOverlays + 1] = overlay
	return overlay
end

local function ShowOverlay(overlay, show)
	if InCombatLockdown() then return end
	if (show and true or false) ~= overlay:IsShown() then
		Log("OVERLAY", "%s %s over %s -> %s", overlay:GetName(), show and "show" or "hide",
			Name(overlay.target), Name(overlay:GetAttribute("clickbutton")))
	end
	if show then
		local target = overlay.target
		overlay:ClearAllPoints()
		overlay:SetAllPoints(target)
		overlay:SetFrameStrata(target:GetFrameStrata())
		overlay:SetFrameLevel(target:GetFrameLevel() + 2)
		overlay:Show()
	else
		overlay:Hide()
		overlay:ClearAllPoints()
	end
end

local function ReleaseOverlays()
	for _, overlay in ipairs(allOverlays) do
		overlay:SetAttribute("clickbutton", nil)
		overlay:Hide()
		overlay:ClearAllPoints()
	end
end

local function SetOverlayTargets()
	if InCombatLockdown() then return end
	for _, overlay in ipairs(gearOverlays) do
		overlay:SetAttribute("clickbutton", optionsButton)
		ShowOverlay(overlay, GamepadUI() and optionsButton ~= nil and overlay.target:IsVisible())
	end
end

local function CaptureOptionsButton()
	if InCombatLockdown() or not GameMenuFrame then return end
	optionsButton = nil
	for _, button in ipairs(GameMenuFrame.buttons or {}) do
		if button.GetText and button:GetText() == GAMEMENU_OPTIONS then
			optionsButton = button
			break
		end
	end
	SetOverlayTargets()
end

-- the game menu may not exist yet when this addon loads: hook it whenever it is first seen
-- (and pick up the buttons it already built)
local menuHooked = false
local function HookGameMenu()
	if menuHooked or not (GameMenuFrame and GameMenuFrame.InitButtons) then return end
	menuHooked = true
	hooksecurefunc(GameMenuFrame, "InitButtons", CaptureOptionsButton)
	GameMenuFrame:HookScript("OnShow", CaptureOptionsButton)
	CaptureOptionsButton()
end
HookGameMenu()

local function GearOverlay(frame)
	local gear = frame.OptionsToggle
	-- Bagnon's own gear now opens its page securely (see OpenSecurely); the overlay is only a
	-- fallback for clients without Settings.OpenToCategory / C_SettingsUtil
	if not gear or (Settings and Settings.OpenToCategory and C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel) then
		return nil
	end
	local overlay = gearOverlays[gear]
	if not overlay then
		if InCombatLockdown() then return nil end
		overlay = NewOverlay("BagnonGamepadGear" .. (#gearOverlays + 1), gear)
		gearOverlays[#gearOverlays + 1] = overlay
		gearOverlays[gear] = overlay
		overlay:SetAttribute("clickbutton", optionsButton)
		overlay:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:AddLine(OPTIONS)
			GameTooltip:AddLine("Opens the game's Options: AddOns > Bagnon", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		overlay:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	return overlay
end

local function UpdateGearOverlay(frame)
	if InCombatLockdown() or not frame then return end
	HookGameMenu()
	if not optionsButton then CaptureOptionsButton() end
	local overlay = GearOverlay(frame)
	if overlay then
		ShowOverlay(overlay, GamepadUI() and optionsButton ~= nil and frame.OptionsToggle:IsVisible())
	end
end

--[[ Close button ]]--

-- In the controller UI Blizzard's combined bag (invisible, see ConcealBlizzardBag) is open behind
-- Bagnon's inventory. Bagnon's X only hid Bagnon, so the next bag press closed the invisible bag
-- and seemed to do nothing. While the combined bag is open, a secure button over Bagnon's X clicks
-- the combined bag's own close button instead: Blizzard closes its bag (securely) and Bagnon
-- follows it (see the combined bag's OnHide hook).
local closeOverlay

local function UpdateCloseOverlay()
	if InCombatLockdown() then return end
	local frame = Bags.Frames:Get("inventory")
	local x = frame and frame[0] and frame.CloseButton
	local blizzard = ContainerFrameCombinedBags and ContainerFrameCombinedBags.CloseButton
	if not (x and blizzard) then return end
	if not closeOverlay then
		closeOverlay = NewOverlay("BagnonGamepadClose", x)
		closeOverlay:SetAttribute("clickbutton", blizzard)
		closeOverlay:SetScript("OnEnter", function()
			local enter = x:GetScript("OnEnter")
			if enter then enter(x) end
		end)
		closeOverlay:SetScript("OnLeave", function()
			local leave = x:GetScript("OnLeave")
			if leave then leave(x) end
		end)
	end
	closeOverlay:SetAttribute("clickbutton", blizzard)
	ShowOverlay(closeOverlay, x:IsVisible() and ContainerFrameCombinedBags:IsShown())
end

--[[ Bagnon menus ]]--

-- Bagnon opens Blizzard context menus from its own buttons (sort and deposit right-click, bag
-- slot right-click, character selector, tab rules). On Forever a menu opened by addon code
-- registers with the controller focus manager and taints it when it closes (seen at the bank).
-- While the gamepad interface is on, those clicks are skipped; the plain clicks (sort, deposit,
-- toggle a bag) still work. Bagnon creates each button's click handler from its class when the
-- button is made, so wrapping the class methods covers every button made afterwards.
local MENU_CLICKS = {
	{ "SortButton", "OnClick", function(_, button) return button == "RightButton" end },
	{ "DepositButton", "OnClick", function(_, button) return button == "RightButton" end },
	{ "Tab", "OnClick", function(_, button) return button == "RightButton" end },
	{ "OfflineSelector", "OnClick", function(_, button) return button == "LeftButton" end, function(self) OpenPicker(self) end },
	-- money windows need a keyboard: the money prompt instead (A deposit / trade, X withdraw)
	{ "PlayerMoney", "OnClick", function() return true end, function(self, ...) MoneyClicks.own(self, ...) end },
	{ "GuildMoney", "OnClick", function() return true end, function(self, button) MoneyClicks.guild(self, button) end },
	{ "Bag", "ShowMenu", function() return true end },
}
local menuNoted = false

local function GuardBagnonMenus()
	for _, entry in ipairs(MENU_CLICKS) do
		local class, method, opensMenu = Bags[entry[1]], entry[2], entry[3]
		local original = class and rawget(class, method)
		if original and not rawget(class, "bagnonGamepad" .. method) then
			class["bagnonGamepad" .. method] = original
			class[method] = function(self, ...)
				if GamepadUI() and opensMenu(self, ...) then
					if entry[4] then
						Log("GUARD", "%s.%s on %s: own picker instead of Blizzard's menu", entry[1], method, Name(self))
						return entry[4](self, ...)
					end
					Log("GUARD", "skipped menu %s.%s on %s", entry[1], method, Name(self))
					if not menuNoted then
						menuNoted = true
						print("|cff33eeffBagnon Gamepad:|r Bagnon's right-click menus are off while the controller interface is on (on Forever they break the controller UI).")
					end
					return
				end
				return original(self, ...)
			end
		end
	end
end
GuardBagnonMenus()

--[[ Split stack ]]--

-- Y on a stack opens a small prompt (our own frame; Blizzard's StackSplitFrame opened from addon
-- code would taint Forever's controller UI): D-pad left/right +-1, up/down +-10, A splits onto the
-- cursor (place it with X on an empty slot), B cancels.
local splitFrame = CreateFrame("Frame", nil, UIParent)
splitFrame:SetFrameStrata("TOOLTIP")
-- the window's own skin, Bagnonium's title-bar panel included (it needs ~100px of height to draw
-- its corners): title in the title bar, the stack's icon and name, then the amount
splitFrame:SetSize(220, 104)
splitFrame:Hide()
do
	local bg = splitFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.85)
	splitFrame.plainBg = bg
	splitFrame.textLayer = CreateFrame("Frame", nil, splitFrame)
	splitFrame.textLayer:SetAllPoints()
	splitFrame.title = splitFrame.textLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	splitFrame.title:SetPoint("TOP", 0, -9)
	splitFrame.title:SetText("Split stack")
	splitFrame.icon = splitFrame.textLayer:CreateTexture(nil, "OVERLAY")
	splitFrame.icon:SetSize(24, 24)
	splitFrame.icon:SetPoint("TOPLEFT", 18, -36)
	splitFrame.name = splitFrame.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	splitFrame.name:SetPoint("LEFT", splitFrame.icon, "RIGHT", 8, 0)
	splitFrame.name:SetPoint("RIGHT", -16, 0)
	splitFrame.name:SetJustifyH("LEFT")
	splitFrame.name:SetWordWrap(false)
	splitFrame.amount = splitFrame.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	splitFrame.amount:SetPoint("BOTTOM", 0, 16)
end

local Apply -- defined below

-- a level above the legend (its entries are child frames with their own, higher levels), the
-- selection box and the arrow
AboveLegend = function()
	local top = math.max(legend:GetFrameLevel(), cursor:GetFrameLevel(), arrow:GetFrameLevel())
	for _, child in ipairs({ legend:GetChildren() }) do
		top = math.max(top, child:GetFrameLevel())
	end
	return top + 10
end

local function ShowSplit()
	if not split then
		splitFrame:Hide()
		return
	end
	splitFrame.amount:SetText(("|cff999999<|r  %d / %d  |cff999999>|r"):format(split.amount, split.max + 1))
	local info = C_Container.GetContainerItemInfo(split.bag, split.slot)
	splitFrame.icon:SetTexture(info and info.iconFileID)
	local link = info and info.hyperlink
	local name = link and (link:match("%[(.-)%]")) or ""
	local quality = info and info.quality
	local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
	splitFrame.name:SetText(color and color.hex and (color.hex .. name .. "|r") or name)
	splitFrame:ClearAllPoints()
	splitFrame:SetScale(split.button:GetEffectiveScale() / UIParent:GetEffectiveScale())
	-- below the stack in the upper half of the bag, above it in the lower half (no room below the
	-- bottom rows, and the button legend sits there); the item tooltip is hidden while it's open
	local window = BagnonFrameOf(split.button)
	local _, by = split.button:GetCenter()
	local wy
	if window then
		local _, y = window:GetCenter() -- (not "window and window:GetCenter()": that keeps only x)
		wy = y
	end
	if wy and by and by * split.button:GetEffectiveScale() < wy * window:GetEffectiveScale() then
		splitFrame:SetPoint("BOTTOM", split.button, "TOP", 0, 8)
	else
		splitFrame:SetPoint("TOP", split.button, "BOTTOM", 0, -8)
	end
	splitFrame:SetClampedToScreen(true)
	splitFrame:SetFrameLevel(AboveLegend())
	ApplyBagnonSkin(splitFrame, BagnonFrameOf(split.button), nil, true)
	LayerSmallWindow(splitFrame, { splitFrame.textLayer })
	splitFrame:Show()
	if GameTooltip:IsOwned(split.button) then GameTooltip:Hide() end
	PointAt(split.button)
end

local function CloseSplit()
	local button = split and split.button
	split = nil
	splitFrame:Hide()
	Apply()
	-- tooltip back on the selected stack
	if button and button == selected and button:IsVisible() then
		local enter = button:GetScript("OnEnter")
		if enter then enter(button) end
	end
end

local function OpenSplit()
	local button = selected
	if not (button and button.bag ~= nil and button:IsVisible()) then return end
	local info = C_Container.GetContainerItemInfo(button.bag, button:GetID())
	local count = info and info.stackCount or 0
	if count < 2 or (info and info.isLocked) then return end
	split = { button = button, bag = button.bag, slot = button:GetID(), max = count - 1,
		amount = math.floor(count / 2) }
	ShowSplit()
	Apply()
end

local function AdjustSplit(dir)
	local step = (dir == "LEFT" and -1) or (dir == "RIGHT" and 1) or (dir == "DOWN" and -10) or 10
	split.amount = math.max(1, math.min(split.max, split.amount + step))
	ShowSplit()
end

do
	local function button(name, onClick)
		local b = CreateFrame("Button", name, UIParent)
		b:RegisterForClicks("AnyDown")
		b:SetScript("OnClick", onClick)
	end
	button("BagnonGamepadSplit", OpenSplit)
	button("BagnonGamepadSplitOK", function()
		if split and not CursorHasItem() then
			C_Container.SplitContainerItem(split.bag, split.slot, split.amount)
		end
		CloseSplit()
	end)
	button("BagnonGamepadSplitCancel", CloseSplit)
end



--[[ Money prompt ]]--

-- Bagnon's money windows (guild bank deposit / withdraw: a Sushi popup to type gold, silver and
-- copper into; your own money: Blizzard's coin pickup) need a keyboard. With the controller UI,
-- A / X on them open this prompt instead:
--   guild money in the guild bank window: A deposit, X withdraw (within the withdraw limit)
--   your money in the bag window: gold for a mail being written (Send Mail tab), deposit at the
--   guild bank (trade gold: only in the trade window)
-- D-pad left/right picks gold / silver / copper, up/down +-1, LB/RB +-10, Y max (again: 0),
-- A confirms, B cancels. It calls the same game functions Bagnon / Blizzard's windows use.
local MONEY_UNITS = { COPPER_PER_GOLD or 10000, COPPER_PER_SILVER or 100, 1 }
local MONEY_TEXT = {
	deposit = GUILDBANK_DEPOSIT or "Deposit",
	withdraw = GUILDBANK_WITHDRAW or "Withdraw",
	mail = SEND_MONEY or "Send Money",
}

local moneyFrame = CreateFrame("Frame", "BagnonGamepadMoney", UIParent)
moneyFrame:SetFrameStrata("TOOLTIP")
moneyFrame:SetSize(250, 104)
moneyFrame:Hide()
do
	local bg = moneyFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.85)
	moneyFrame.plainBg = bg
	moneyFrame.textLayer = CreateFrame("Frame", nil, moneyFrame)
	moneyFrame.textLayer:SetAllPoints()
	moneyFrame.title = moneyFrame.textLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	moneyFrame.title:SetPoint("TOP", 0, -9)
	moneyFrame.amount = moneyFrame.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	moneyFrame.amount:SetPoint("CENTER", 0, -4)
	moneyFrame.limit = moneyFrame.textLayer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	moneyFrame.limit:SetPoint("BOTTOM", 0, 14)
end

local function MoneyParts(amount)
	local gold = math.floor(amount / MONEY_UNITS[1])
	local silver = math.floor((amount % MONEY_UNITS[1]) / MONEY_UNITS[2])
	local copper = amount % MONEY_UNITS[2]
	return gold, silver, copper
end

local function ShowMoney()
	if not money then
		moneyFrame:Hide()
		return
	end
	local parts = { MoneyParts(money.amount) }
	local icons = { "|TInterface/MoneyFrame/UI-GoldIcon:0|t", "|TInterface/MoneyFrame/UI-SilverIcon:0|t",
		"|TInterface/MoneyFrame/UI-CopperIcon:0|t" }
	local text = {}
	for i = 1, 3 do
		local value = tostring(parts[i])
		if i == money.unit then
			value = "|cffffd100< " .. value .. " >|r"
		end
		text[i] = value .. " " .. icons[i]
	end
	moneyFrame.title:SetText(MONEY_TEXT[money.mode] or "")
	moneyFrame.amount:SetText(table.concat(text, "   "))
	moneyFrame.limit:SetText((MAXIMUM or "Max") .. ": " .. GetMoneyString(money.max, true))
	local anchor = money.anchor
	moneyFrame:ClearAllPoints()
	moneyFrame:SetScale(anchor:GetEffectiveScale() / UIParent:GetEffectiveScale())
	moneyFrame:SetPoint("BOTTOM", anchor, "TOP", 0, 10)
	moneyFrame:SetClampedToScreen(true)
	moneyFrame:SetFrameLevel(AboveLegend())
	ApplyBagnonSkin(moneyFrame, BagnonFrameOf(anchor), nil, true)
	LayerSmallWindow(moneyFrame, { moneyFrame.textLayer })
	if GameTooltip:IsOwned(anchor) then GameTooltip:Hide() end
	moneyFrame:Show()
	PointAt(anchor)
end

local function CloseMoney()
	money = nil
	moneyFrame:Hide()
	Apply()
end

local function MoneyMax(mode)
	if mode == "withdraw" then
		local allowed = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0
		local funds = GetGuildBankMoney and GetGuildBankMoney() or 0
		if allowed < 0 then allowed = funds end -- -1: no limit
		return math.max(0, math.min(allowed, funds))
	end
	return GetMoney()
end

-- what A on your own money means right now (nil: nothing for the controller). Trade gold can't
-- be set by addons at all (Blizzard forbids the trade window's gold field and restricts
-- SetTradeMoney to its own code, against scams): it is set in the trade window itself.
local function MoneyContext()
	if TradeFrame and TradeFrame:IsShown() then return "trade-window" end
	if SendMailFrame and SendMailFrame:IsVisible() and SendMailMoneyGold then return "mail" end
	local guild = Bags.Frames:Get("guild")
	if guild and guild[0] and guild:IsShown() and not (guild.IsCached and guild:IsCached()) then
		return "deposit"
	end
end

OpenMoneyPrompt = function(mode, anchor)
	if InCombatLockdown() or not mode then return end
	if mode == "withdraw" and not (CanWithdrawGuildBankMoney and CanWithdrawGuildBankMoney()) then
		print("|cff33eeffBagnon Gamepad:|r you can't withdraw from this guild bank.")
		return
	end
	money = { mode = mode, amount = 0, max = MoneyMax(mode), unit = 1, anchor = anchor }
	Log("MONEY", "prompt %s, max %d", mode, money.max)
	ShowMoney()
	Apply()
end

local function ChangeMoney(steps)
	if not money then return end
	local amount = money.amount + steps * MONEY_UNITS[money.unit]
	money.amount = math.max(0, math.min(money.max, amount))
	ShowMoney()
end

local function ConfirmMoney()
	if not money then return end
	local mode, amount = money.mode, money.amount
	Log("MONEY", "%s %d", mode, amount)
	CloseMoney()
	if mode == "deposit" and amount > 0 then
		DepositGuildBankMoney(amount)
	elseif mode == "withdraw" and amount > 0 then
		WithdrawGuildBankMoney(amount)
	elseif mode == "mail" then
		-- the send-mail gold boxes (not forbidden, unlike the trade window's): Blizzard reads them
		-- itself when the mail is sent; only their text is set here
		local gold, silver, copper = MoneyParts(amount)
		SendMailMoneyGold:SetText(gold > 0 and tostring(gold) or "")
		SendMailMoneySilver:SetText(silver > 0 and tostring(silver) or "")
		SendMailMoneyCopper:SetText(copper > 0 and tostring(copper) or "")
	end
end

do
	local function button(name, onClick)
		local b = CreateFrame("Button", name, UIParent)
		b:RegisterForClicks("AnyDown")
		b:SetScript("OnClick", onClick)
	end
	button("BagnonGamepadMoneyUP", function() ChangeMoney(1) end)
	button("BagnonGamepadMoneyDOWN", function() ChangeMoney(-1) end)
	button("BagnonGamepadMoneyMORE", function() ChangeMoney(10) end)
	button("BagnonGamepadMoneyLESS", function() ChangeMoney(-10) end)
	button("BagnonGamepadMoneyLEFT", function()
		if money then money.unit = math.max(1, money.unit - 1) ShowMoney() end
	end)
	button("BagnonGamepadMoneyRIGHT", function()
		if money then money.unit = math.min(3, money.unit + 1) ShowMoney() end
	end)
	button("BagnonGamepadMoneyMAX", function()
		if money then money.amount = (money.amount == money.max) and 0 or money.max ShowMoney() end
	end)
	button("BagnonGamepadMoneyOK", ConfirmMoney)
	button("BagnonGamepadMoneyCancel", CloseMoney)
end

-- the money buttons themselves (see MENU_CLICKS)
local function OwnMoneyClick(self)
	local mode = MoneyContext()
	if mode == "trade-window" then
		print("|cff33eeffBagnon Gamepad:|r trade gold can only be set in the trade window itself (LT/RT to it); the game doesn't let addons set it.")
	elseif mode then
		OpenMoneyPrompt(mode, self)
	else
		print("|cff33eeffBagnon Gamepad:|r with the controller, your gold is used in a trade or at the guild bank (A on it there).")
	end
end
local function GuildMoneyClick(self, button)
	if self.IsCached and self:IsCached() then return end
	OpenMoneyPrompt(button == "RightButton" and "withdraw" or "deposit", self)
end
MoneyClicks = { own = OwnMoneyClick, guild = GuildMoneyClick }

-- closed with the window and before combat (see Refresh / PLAYER_REGEN_DISABLED)
local function DropMoney()
	money = nil
	moneyFrame:Hide()
end

--[[ Character / location picker ]]--

-- Bagnon's character selector (offline viewing) opens Blizzard's drop-down menu from addon code;
-- on Forever such a menu registers with the controller frame manager and taints it when it closes.
-- While the gamepad interface is on, A (or a click) on the selector opens this picker instead: our
-- own frame and bindings, nothing of Blizzard's is touched. It offers what the menu's main part
-- offers: the locations (inventory, bank, ...) and every character / guild Bagnon knows; choosing
-- one does what the menu does (Bagnon's Frames:Show). Favourites and deleting characters stay in
-- Bagnon's menu (mouse and keyboard mode). D-pad chooses, A shows, B closes.
local PICKER_ROWS = 14
local pickerFrame = CreateFrame("Frame", "BagnonGamepadPicker", UIParent)
pickerFrame:SetFrameStrata("TOOLTIP")
pickerFrame:SetWidth(290)
pickerFrame:EnableMouse(true)
pickerFrame:Hide()
tinsert(UISpecialFrames, "BagnonGamepadPicker") -- Esc closes it
do
	local bg = pickerFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.9)
	pickerFrame.plainBg = bg
	pickerFrame.titleLayer = CreateFrame("Frame", nil, pickerFrame)
	pickerFrame.titleLayer:SetAllPoints()
	pickerFrame.title = pickerFrame.titleLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	pickerFrame.title:SetPoint("TOP", 0, -9)
	pickerFrame.rows = {}
	for i = 1, PICKER_ROWS do
		local row = CreateFrame("Button", nil, pickerFrame)
		row:SetHeight(20)
		row.index = i
		row.highlight = row:CreateTexture(nil, "BACKGROUND")
		row.highlight:SetAllPoints()
		-- soft highlight like Blizzard's menus (the arrow marks the row as well)
		row.highlight:SetColorTexture(1, 1, 1, 0.12)
		row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		row.text:SetPoint("LEFT", 16, 0) -- room for the arrow tip
		row.text:SetPoint("RIGHT", -4, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetWordWrap(false) -- one line per row (long names are cut with "...")
		row.text:SetMaxLines(1)
		row:RegisterForClicks("LeftButtonUp")
		pickerFrame.rows[i] = row
	end
end

local ChoosePicker, ShowPicker

local function ClosePicker()
	if not picker then return end
	Log("PICKER", "closed")
	local anchor = picker.anchor
	picker = nil
	pickerFrame:Hide()
	if opts.page then
		if anchor and anchor:IsVisible() then PointAt(anchor) end
		ApplyOptions()
		return
	end
	if selected and selected:IsVisible() then PointAt(selected) end
	Apply()
end
pickerFrame:SetScript("OnHide", function()
	if picker then
		picker = nil
		if not InCombatLockdown() then
			if opts.page then ApplyOptions() else Apply() end
		end
	end
end)

ShowPicker = function()
	if not picker then
		pickerFrame:Hide()
		return
	end
	local entries, index = picker.entries, picker.index
	local first = math.max(1, math.min(index - math.floor(PICKER_ROWS / 2), #entries - PICKER_ROWS + 1))
	local shownRows = math.min(PICKER_ROWS, #entries)
	for i, row in ipairs(pickerFrame.rows) do
		local n = first + i - 1
		local entry = entries[n]
		if i <= shownRows and entry then
			row.text:SetText(entry.text)
			row.text:SetFontObject(entry.header and "GameFontNormalSmall" or "GameFontHighlight")
			row.highlight:SetShown(n == index)
			row:SetScript("OnClick", not entry.header and function() picker.index = n; ChoosePicker() end or nil)
			-- mouse hover moves the highlight only in mouse mode: in the controller UI the hidden
			-- pointer may rest over the list and would steal the D-pad's choice
			row:SetScript("OnEnter", not entry.header and function()
				if picker and not GamepadUI() then picker.index = n; ShowPicker() end
			end or nil)
			row:Show()
		else
			row:Hide()
		end
	end
	-- the window's own skin with its title bar (Bagnonium) when tall enough, else compact metal
	local fullPanel = shownRows >= 4
	local top = fullPanel and 34 or 14
	for _, row in ipairs(pickerFrame.rows) do
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 12, -top - (row.index - 1) * 20)
		row:SetPoint("TOPRIGHT", -12, -top - (row.index - 1) * 20)
	end
	pickerFrame.title:SetText(fullPanel and (picker.title or "") or "")
	pickerFrame:SetHeight(top + 14 + shownRows * 20)
	pickerFrame:ClearAllPoints()
	local anchor = picker.anchor
	pickerFrame:SetScale(anchor:GetEffectiveScale() / UIParent:GetEffectiveScale())
	pickerFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
	pickerFrame:SetClampedToScreen(true)
	pickerFrame:SetFrameLevel(AboveLegend())
	ApplyBagnonSkin(pickerFrame, BagnonFrameOf(anchor), nil, fullPanel)
	LayerSmallWindow(pickerFrame, pickerFrame.rows)
	pickerFrame.titleLayer:SetFrameLevel(pickerFrame:GetFrameLevel() + 3)
	if GameTooltip:IsOwned(anchor) then GameTooltip:Hide() end
	pickerFrame:Show()
	local row = pickerFrame.rows[index - first + 1]
	if row and row:IsShown() then
		PointAt(row, pickerFrame, true)
	end
end

local function StepPicker(step)
	local entries = picker.entries
	local index = picker.index
	repeat
		index = (index - 1 + step) % #entries + 1
	until not entries[index].header or index == picker.index
	picker.index = index
	Log("PICKER", "step %d -> %s", step, tostring(picker.entries[index].log))
	ShowPicker()
end

ChoosePicker = function()
	local entry = picker and picker.entries[picker.index]
	if not entry or entry.header then return end
	Log("PICKER", "chose %s", entry.log)
	ClosePicker()
	entry.choose()
end

OpenPicker = function(selector)
	if InCombatLockdown() then return end
	local entries = {}
	local current = selector.GetOwner and selector:GetOwner()
	local frameID = selector.GetFrameID and selector:GetFrameID() or "inventory"
	entries[#entries + 1] = { header = true, text = "Locations" }
	for _, frame in Bags.Frames:Iterate() do
		if Bags.Frames:IsEnabled(frame.id) then
			local id = frame.id
			entries[#entries + 1] = {
				text = (frame.icon and CreateSimpleTextureMarkup(frame.icon, 16, 16) .. " " or "") .. tostring(frame.name or id),
				log = "location " .. tostring(id),
				choose = function() Bags.Frames:Show(id) end,
			}
		end
	end
	entries[#entries + 1] = { header = true, text = "Characters" }
	local start
	local guildsHeader = false
	for _, ownerInfo in Bags.Owners:Iterate() do
		if ownerInfo.isguild and not guildsHeader then
			guildsHeader = true
			entries[#entries + 1] = { header = true, text = "Guilds" }
		end
		do
			local name = ownerInfo.GetDisplayName and ownerInfo:GetDisplayName(16) or tostring(ownerInfo.name)
			local isCurrent = ownerInfo == current
			entries[#entries + 1] = {
				text = (isCurrent and "|cffffd100>|r " or "   ") .. name,
				log = "owner " .. tostring(ownerInfo.name or name),
				choose = function() Bags.Frames:Show(ownerInfo.isguild and "guild" or frameID, ownerInfo) end,
			}
			if isCurrent then start = #entries end
		end
	end
	picker = { anchor = selector, entries = entries, index = start or 2, title = "Offline Viewing" }
	Log("PICKER", "opened with %d entries", #entries)
	ShowPicker()
	Apply()
end

do
	local function button(name, onClick)
		local b = CreateFrame("Button", name, UIParent)
		b:RegisterForClicks("AnyDown")
		b:SetScript("OnClick", onClick)
	end
	button("BagnonGamepadPickerPrev", function() if picker then StepPicker(-1) end end)
	button("BagnonGamepadPickerNext", function() if picker then StepPicker(1) end end)
	button("BagnonGamepadPickerOK", function() if picker then ChoosePicker() end end)
	button("BagnonGamepadPickerCancel", ClosePicker)
end

-- Some Bagnon controls carry a secure Blizzard button (e.g. the bank slot purchase button, which
-- Bagnon puts over an unbought slot on hover). A on such a control clicks that button through a
-- secure click, so Blizzard's purchase prompt opens untainted.
local secureClicker = CreateFrame("Button", "BagnonGamepadSecureClick", UIParent, "SecureActionButtonTemplate")
secureClicker:RegisterForClicks("AnyUp", "AnyDown")
secureClicker:SetAttribute("type", "click")

-- Bagnon's bank slots carry Blizzard's purchase buttons from Bag.Proxies (plain Blizzard
-- buttons, not protected); clicking them through the secure clicker runs Blizzard's own handler.
local function IsProxy(control, child)
	local proxies = control.Proxies
	if type(proxies) ~= "table" then return false end
	for _, frame in pairs(proxies) do
		if frame == child then return true end
	end
	return false
end

local function SecureChild(control)
	for _, child in ipairs({ control:GetChildren() }) do
		if child:IsShown() and child:IsObjectType("Button") and (child:IsProtected() or IsProxy(control, child)) then
			return child
		end
	end
end

--[[ Bank slot purchase ]]--

-- Bagnon buys bank slots by moving Blizzard's purchase button onto its slot (SetParent) and setting
-- its 'overrideBankType' attribute from addon code. Blizzard's click handler reads both, so the
-- purchase confirmation popup runs tainted; that popup's controller icons stay tainted and Forever
-- then blocks controller actions until /reload. On Forever, Bagnon's takeover is skipped (its hover
-- shows only the tooltip), and a secure button of ours covers each unbought slot instead: it clicks
-- Blizzard's purchase button where it belongs, inside Blizzard's (invisible) bank panel, so only
-- Blizzard values are read. Works for the mouse and for A.
local buyOverlays = {}

local function BlizzardPurchaseButton()
	local panel = BankPanel or (BankFrame and BankFrame.BankPanel)
	local generic = panel and panel.PurchasePrompt and panel.PurchasePrompt.TabCostFrame
		and panel.PurchasePrompt.TabCostFrame.PurchaseButton
	return generic or _G.BankFramePurchaseButton
end

local function BuyOverlay(slot)
	local overlay = buyOverlays[slot]
	if not overlay then
		if InCombatLockdown() then return nil end
		overlay = NewOverlay("BagnonGamepadBuy" .. (#buyOverlays + 1), slot)
		buyOverlays[#buyOverlays + 1] = overlay
		buyOverlays[slot] = overlay
		overlay:SetScript("OnEnter", function(self)
			local enter = slot:GetScript("OnEnter")
			if enter then enter(slot) end
		end)
		overlay:SetScript("OnLeave", function()
			local leave = slot:GetScript("OnLeave")
			if leave then leave(slot) end
		end)
	end
	return overlay
end

local function IsUnboughtBankSlot(control)
	return control and Bags.BankBag and getmetatable(control) and control.GetType and control.IsCached
		and control.Proxies ~= nil and not control.owned and not control:IsCached()
end

local function UpdateBuyOverlays(frame)
	if not Bags.IsForever or InCombatLockdown() or not frame then return end
	local target = BlizzardPurchaseButton()
	local function walk(f)
		for _, child in ipairs({ f:GetChildren() }) do
			if child.Proxies ~= nil and child.GetType then
				local overlay = BuyOverlay(child)
				if overlay then
					overlay:SetAttribute("clickbutton", target)
					ShowOverlay(overlay, target ~= nil and child:IsVisible() and IsUnboughtBankSlot(child))
				end
			elseif child:IsVisible() then
				walk(child)
			end
		end
	end
	walk(frame)
end

local function GuardBankPurchase()
	local class = Bags.BankBag
	if not (Bags.IsForever and class and rawget(class, "OnEnter")) or rawget(class, "bagnonGamepadOnEnter") then
		return
	end
	local original = class.OnEnter
	class.bagnonGamepadOnEnter = original
	class.OnEnter = function(self, ...)
		if self.owned then
			return original(self, ...)
		end
		-- tooltip only (price), no takeover of Blizzard's purchase button
		GameTooltip:SetOwner(self:GetTipAnchor())
		self:UpdateTooltip()
	end
end

--[[ Putting the held item into a bag ]]--

-- PutItemInBag is protected on Forever; Bagnon's bag buttons call it from addon code
-- ("ADDON BLOCKED: PutItemInBag()"). While an item is held, a secure button of ours covers each
-- of Bagnon's inventory bag buttons and clicks Blizzard's own bag bar button for that bag, whose
-- handler (BagSlotOnClick / backpack) puts the item in. Mouse and A both use it.
local bagOverlays = {}

local function BlizzardBagButton(bag)
	if bag:GetID() == 0 then
		return MainMenuBarBackpackButton
	end
	local slot = bag.slot
	if not slot then return nil end
	local found
	local function search(frame, depth)
		if found or depth > 4 or not frame then return end
		for _, child in ipairs({ frame:GetChildren() }) do
			if child.PutItemInBag and child.GetID and child:GetID() == slot then
				found = child
				return
			end
			search(child, depth + 1)
		end
	end
	for i = 0, 3 do
		local named = _G["CharacterBag" .. i .. "Slot"]
		if named and named:GetID() == slot then return named end
	end
	local reagent = _G.CharacterReagentBag0Slot
	if reagent and reagent:GetID() == slot then return reagent end
	search(BagsBar, 0)
	search(BagSlotCluster, 0)
	search(GamepadBagBar, 0)
	return found
end

local function IsInventoryBag(control)
	return control and control.UpdateToggle and control.Proxies == nil and control.GetID
		and (control.slot ~= nil or control:GetID() == 0) and not (control.IsCached and control:IsCached())
end

local function UpdateBagOverlays(frame)
	if InCombatLockdown() or not frame then return end
	local holding = CursorHasItem()
	local function walk(f)
		for _, child in ipairs({ f:GetChildren() }) do
			if IsInventoryBag(child) then
				local overlay = bagOverlays[child]
				if not overlay and holding then
					overlay = NewOverlay("BagnonGamepadBag" .. (#bagOverlays + 1), child)
					bagOverlays[#bagOverlays + 1] = overlay
					bagOverlays[child] = overlay
				end
				if overlay then
					local target = holding and BlizzardBagButton(child) or nil
					overlay:SetAttribute("clickbutton", target)
					ShowOverlay(overlay, target ~= nil and child:IsVisible())
				end
			elseif child:IsVisible() then
				walk(child)
			end
		end
	end
	walk(frame)
end

--[[ Bindings ]]--

local function OpenWindows()
	local n = 0
	for _, f in ipairs(frames) do
		if f:IsShown() then n = n + 1 end
	end
	return n
end

-- Forever orders windows for LT/RT by their position on screen, left to right. Its "bag" is
-- Blizzard's hidden bag, whose position has nothing to do with where Bagnon's window is (Bagnon
-- shrinks it near the left edge), so the triggers could come out mirrored. Forever runs its window
-- switch from one named click button per key; when its order disagrees with what's on screen,
-- bind LT to its RT button and RT to its LT button. Still its own secure handlers.
local function TriggersMirrored()
	local manager = GamepadMode and GamepadMode.FrameControlsManager
	local bag = ContainerFrameCombinedBags
	local list = manager and manager.shownFrames
	if not (active and active:IsShown() and bag and type(list) == "table" and #list > 1) then
		return false
	end
	local bagIndex, other, otherIndex
	for i, frame in ipairs(list) do
		if frame == bag then
			bagIndex = i
		elseif not other and frame.IsVisible and frame:IsVisible() then
			other, otherIndex = frame, i
		end
	end
	if not (bagIndex and other) then return false end
	local bx = select(1, active:GetCenter()) * active:GetEffectiveScale()
	local ox = select(1, other:GetCenter()) * other:GetEffectiveScale()
	return (bagIndex < otherIndex) ~= (bx < ox)
end

local function BindTriggers()
	triggersBound = false
	if InCombatLockdown() or not GamepadUI() or not TriggersMirrored() then return end
	local left, right = _G.InputFunctionBindingButton_PADLTRIGGER, _G.InputFunctionBindingButton_PADRTRIGGER
	if not (left and right) then return end
	SetOverrideBindingClick(owner, true, "PADLTRIGGER", right:GetName(), "LeftButton")
	SetOverrideBindingClick(owner, true, "PADRTRIGGER", left:GetName(), "LeftButton")
	triggersBound = true
end

local function Clear()
	if (bound or triggersBound) and not InCombatLockdown() then
		ClearOverrideBindings(owner)
		bound = false
		triggersBound = false
	end
	if active and active:IsShown() then BindTriggers() end
	UpdateLegend(false)
end

Apply = function()
	if InCombatLockdown() then
		return
	end
	ClearOverrideBindings(owner)
	bound = false
	UpdateHeldItem(false)
	BindTriggers()
	if not (active and active:IsShown() and GamepadUI()) or released
		or (BagnonGamepadDB and BagnonGamepadDB.enabled == false) then
		Log("BIND", "cleared (active=%s shown=%s gamepadUI=%s released=%s enabled=%s)", Name(active),
			tostring(active and active:IsShown()), tostring(GamepadUI()), tostring(released),
			tostring(not (BagnonGamepadDB and BagnonGamepadDB.enabled == false)))
		cursor:Hide()
		arrow:Hide()
		UpdateLegend(false)
		return
	end
	for key, dir in pairs(DPAD) do
		SetOverrideBindingClick(owner, true, key, "BagnonGamepadNav" .. dir)
	end
	if money then
		for key, dir in pairs(DPAD) do
			SetOverrideBindingClick(owner, true, key, "BagnonGamepadMoney" .. dir)
		end
		SetOverrideBindingClick(owner, true, "PADLSHOULDER", "BagnonGamepadMoneyLESS")
		SetOverrideBindingClick(owner, true, "PADRSHOULDER", "BagnonGamepadMoneyMORE")
		SetOverrideBindingClick(owner, true, "PAD4", "BagnonGamepadMoneyMAX")
		SetOverrideBindingClick(owner, true, "PAD1", "BagnonGamepadMoneyOK")
		SetOverrideBindingClick(owner, true, "PAD2", "BagnonGamepadMoneyCancel")
		bound = true
		Log("BIND", "money prompt (%s)", money.mode)
		UpdateLegend(true, OpenWindows())
		HideBlizzardPointer()
		return
	end
	if picker then
		SetOverrideBindingClick(owner, true, "PADDUP", "BagnonGamepadPickerPrev")
		SetOverrideBindingClick(owner, true, "PADDLEFT", "BagnonGamepadPickerPrev")
		SetOverrideBindingClick(owner, true, "PADDDOWN", "BagnonGamepadPickerNext")
		SetOverrideBindingClick(owner, true, "PADDRIGHT", "BagnonGamepadPickerNext")
		SetOverrideBindingClick(owner, true, "PAD1", "BagnonGamepadPickerOK")
		SetOverrideBindingClick(owner, true, "PAD2", "BagnonGamepadPickerCancel")
		bound = true
		Log("BIND", "picker")
		UpdateLegend(true, OpenWindows())
		HideBlizzardPointer()
		return
	end
	if split then
		SetOverrideBindingClick(owner, true, "PAD1", "BagnonGamepadSplitOK")
		SetOverrideBindingClick(owner, true, "PAD2", "BagnonGamepadSplitCancel")
		bound = true
		Log("BIND", "split prompt on %s", Name(split.button))
		UpdateLegend(true, OpenWindows())
		HideBlizzardPointer()
		return
	end
	SetOverrideBindingClick(owner, true, "PADLSHOULDER", "BagnonGamepadNavPREV")
	SetOverrideBindingClick(owner, true, "PADRSHOULDER", "BagnonGamepadNavNEXT")
	if selected and selected:IsVisible() then
		local overlay = active and active.OptionsToggle == selected and gearOverlays[selected]
		if overlay and overlay:IsShown() then
			SetOverrideBindingClick(owner, true, "PAD1", overlay:GetName(), "LeftButton")
		elseif IsItemButton(selected) then
			-- the click goes straight to Bagnon's secure item button, like a mouse click
			SetOverrideBindingClick(owner, true, "PAD1", selected:GetName(), "RightButton")
			SetOverrideBindingClick(owner, true, "PAD3", selected:GetName(), "LeftButton")
			SetOverrideBindingClick(owner, true, "PAD4", "BagnonGamepadSplit")
		elseif closeOverlay and closeOverlay.target == selected and closeOverlay:IsShown() then
			SetOverrideBindingClick(owner, true, "PAD1", closeOverlay:GetName(), "LeftButton")
		elseif bagOverlays[selected] and bagOverlays[selected]:IsShown() then
			SetOverrideBindingClick(owner, true, "PAD1", bagOverlays[selected]:GetName(), "LeftButton")
		elseif buyOverlays[selected] and buyOverlays[selected]:IsShown() then
			SetOverrideBindingClick(owner, true, "PAD1", buyOverlays[selected]:GetName(), "LeftButton")
		elseif SecureChild(selected) then
			secureClicker:SetAttribute("clickbutton", SecureChild(selected))
			SetOverrideBindingClick(owner, true, "PAD1", secureClicker:GetName(), "LeftButton")
		else
			SetOverrideBindingClick(owner, true, "PAD1", "BagnonGamepadPress", "LeftButton")
			SetOverrideBindingClick(owner, true, "PAD3", "BagnonGamepadPress", "RightButton")
		end
	end
	bound = true
	Log("BIND", "set: window=%s selected=%s A=%s X=%s", Name(active), Name(selected),
		tostring(GetBindingAction("PAD1", true)), tostring(GetBindingAction("PAD3", true)))
	UpdateLegend(true, OpenWindows())
	HideBlizzardPointer()
	UpdateHeldItem(true)
end

local function Select(button)
	if (picker or money) and button then
		-- the picker / money prompt has the box, arrow and tooltip; just remember where to return to
		selected = button
		Apply()
		return
	end
	if selected and selected ~= button then
		local leave = selected:GetScript("OnLeave")
		if leave then leave(selected) end
	end
	selected = button
	if button then
		cursor:ClearAllPoints()
		cursor:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
		cursor:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
		cursor:Show()
		-- like Forever's pointer at a vendor: left of the item, tip a little over its edge
		arrow:ClearAllPoints()
		arrow:SetScale(button:GetEffectiveScale() / UIParent:GetEffectiveScale())
		arrow:SetPoint("RIGHT", button, "LEFT", 13, 0)
		arrow:Show()
		local enter = button:GetScript("OnEnter")
		if enter then enter(button) end
	else
		cursor:Hide()
		arrow:Hide()
	end
	Apply()
end

local function Refresh()
	UpdateCloseOverlay()
	UpdateGearOverlay(active) -- also hides it again in mouse-and-keyboard mode
	UpdateBuyOverlays(active)
	UpdateBagOverlays(active)
	if not (active and active:IsShown() and GamepadUI()) or InCombatLockdown() then
		split = nil
		splitFrame:Hide()
		picker = nil
		pickerFrame:Hide()
		DropMoney()
		Select(nil)
		Clear()
		return
	end
	local list, items = Collect(active)
	local keep = false
	for _, b in ipairs(list) do
		if b == selected then keep = true break end
	end
	Select(keep and selected or TopLeft(#items > 0 and items or list))
end

-- several things ask for a refresh in the same frame (window shown, Bagnon's layout): run it once
local refreshQueued = false
local function QueueRefresh()
	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(0, function()
		refreshQueued = false
		Refresh()
	end)
end

local function Move(dir)
	if split then
		AdjustSplit(dir)
		return
	end
	if not active then return end
	local list, items = Collect(active)
	if not (selected and selected:IsVisible()) then
		Select(TopLeft(#items > 0 and items or list))
		return
	end
	local nextButton = Neighbour(list, selected, dir) or Wrap(list, selected, dir)
	if nextButton then
		Select(nextButton)
	end
end

local function Cycle(step)
	local shown = {}
	for _, f in ipairs(frames) do
		if f:IsShown() then shown[#shown + 1] = f end
	end
	if #shown < 2 then return end
	local index = 1
	for i, f in ipairs(shown) do
		if f == active then index = i end
	end
	active = shown[(index - 1 + step) % #shown + 1]
	selected = nil
	Refresh()
end

-- A / X on a header control: Bagnon's header buttons are plain (unnamed) addon buttons,
-- so a proxy clicks them; the search box gets keyboard focus instead
do
	local press = CreateFrame("Button", "BagnonGamepadPress", UIParent)
	press:RegisterForClicks("AnyDown")
	press:SetScript("OnClick", function(_, mouseButton)
		local target = selected
		if not (target and target:IsVisible()) then return end
		if target:IsObjectType("EditBox") then
			target:SetFocus()
		elseif target.Click then
			target:Click(mouseButton)
		end
		-- the click may open/close the search bar or hide bags: re-collect
		C_Timer.After(0, function() if bound then Refresh() end end)
	end)
end

for _, dir in ipairs({ "UP", "DOWN", "LEFT", "RIGHT" }) do
	local b = CreateFrame("Button", "BagnonGamepadNav" .. dir, UIParent)
	b:RegisterForClicks("AnyDown")
	b:SetScript("OnClick", function() Move(dir) end)
end
do
	local prev = CreateFrame("Button", "BagnonGamepadNavPREV", UIParent)
	prev:RegisterForClicks("AnyDown")
	prev:SetScript("OnClick", function() Cycle(-1) end)
	local nxt = CreateFrame("Button", "BagnonGamepadNavNEXT", UIParent)
	nxt:RegisterForClicks("AnyDown")
	nxt:SetScript("OnClick", function() Cycle(1) end)
end

--[[ Bagnon windows ]]--

local function OnShown(frame)
	Log("WIN", "shown %s", Name(frame))
	for i, f in ipairs(frames) do
		if f == frame then table.remove(frames, i) break end
	end
	table.insert(frames, frame)
	active = frame
	selected = nil
	released = false
	-- wait a frame: Bagnon lays out its slots right after showing (and Blizzard sets its
	-- own controller bindings for the bag it opened; ours must come after them)
	QueueRefresh()
end

local function OnHidden(frame)
	Log("WIN", "hidden %s", Name(frame))
	if frame ~= active then return end
	active = nil
	for i = #frames, 1, -1 do
		if frames[i]:IsShown() then active = frames[i] break end
	end
	selected = nil
	Refresh()
end

local function Hook(frame)
	if not frame or hooked[frame] or not frame.HookScript then return end
	hooked[frame] = true
	frame:HookScript("OnShow", OnShown)
	frame:HookScript("OnHide", OnHidden)
	if frame.Layout then
		hooksecurefunc(frame, "Layout", function(f)
			V("BAGNON", "Layout %s (%dx%d)", Name(f), f:GetWidth() or 0, f:GetHeight() or 0)
			if f == active then QueueRefresh() end
		end)
	end
	if frame:IsShown() then OnShown(frame) end
end

hooksecurefunc(Bags.Frames, "New", function(self, id)
	local frame = self:Get(id)
	if frame and frame[0] then Hook(frame) end
end)
for _, frame in Bags.Frames:Iterate() do
	if frame and frame[0] then Hook(frame) end
end

-- Blizzard opens its own combined bag through paths Bagnon doesn't catch (OpenAllBags at a
-- vendor, mail, bank ...), so it showed next to Bagnon. While Bagnon handles the inventory, make
-- it invisible and click-through whenever it shows. Alpha and mouse only: it isn't moved or
-- reparented (that taints Forever's controller code), and it stays open, so Forever's own window
-- switch (triggers) still treats it as "the bag".
local mouseOff = setmetatable({}, { __mode = "k" })
local function ConcealBlizzardBag()
	local bag = ContainerFrameCombinedBags
	if not bag then return end
	local hide = Bags.Frames:IsEnabled("inventory") and true or false
	bag:SetAlpha(hide and 0 or 1)
	if InCombatLockdown() then return end
	local function mouse(frame)
		if hide then
			if frame:IsMouseEnabled() then
				mouseOff[frame] = true
				frame:EnableMouse(false)
			end
		elseif mouseOff[frame] then
			mouseOff[frame] = nil
			frame:EnableMouse(true)
		end
	end
	mouse(bag)
	if bag.EnumerateValidItems then
		for _, button in bag:EnumerateValidItems() do
			mouse(button)
		end
	end
end

-- B closes the (hidden) Blizzard bag through Forever's own navigation; close Bagnon with it
if ContainerFrameCombinedBags then
	ContainerFrameCombinedBags:HookScript("OnShow", function()
		ConcealBlizzardBag()
		C_Timer.After(0, UpdateCloseOverlay)
	end)
	ContainerFrameCombinedBags:HookScript("OnHide", function()
		C_Timer.After(0, UpdateCloseOverlay)
		-- wait a frame: when the bags are toggled (bag button), Bagnon's own hook closes its
		-- window in the same call; only act if Bagnon is still open afterwards (closed by B)
		C_Timer.After(0, function()
			if GamepadUI() and not ContainerFrameCombinedBags:IsShown()
				and Bags.Frames:IsShown("inventory") then
				Bags.Frames:Hide("inventory")
			end
		end)
	end)
end

-- Forever's frame manager switches windows with the triggers (vendor <-> bag, bank, ...). Its
-- "bag" is Blizzard's hidden bag that Bagnon replaces, so follow its focus: on another visible
-- window our bindings step aside (its own navigation drives that window); back on the bag (or a
-- frame Bagnon shrank out of sight), they return. Post-hooks only; they can't taint the manager.
local function RealWindow(frame)
	if not (frame and frame.IsVisible and frame:IsVisible()) then return false end
	if frame == ContainerFrameCombinedBags then return false end
	return frame:GetEffectiveScale() > 0.05 and frame:GetEffectiveAlpha() > 0.05
end

-- A trade opens with Forever's focus on the trade window, but the work is in the bags (A adds an
-- item, the money prompt sets the gold): Bagnon keeps the controller then; LT/RT (Forever's own
-- window switch) still go to the trade window and back.
local KEEP_BAGNON = { TradeFrame = true }
local userSwitched = false

local syncQueued = false
local function SyncFocus()
	syncQueued = false
	local manager = GamepadMode and GamepadMode.FrameControlsManager
	if not (manager and active and active:IsShown() and GamepadUI()) then return end
	local wasReleased = released
	local focus = manager:GetActiveFrame()
	released = RealWindow(focus)
	if released and not userSwitched and focus and KEEP_BAGNON[focus:GetName() or ""] and not wasReleased then
		released = false
	end
	userSwitched = false
	if released ~= wasReleased then
		Log("FOCUS", "frame manager focus %s -> %s", Name(manager:GetActiveFrame()),
			released and "released to it" or "back to Bagnon")
		if released then
			Select(nil)
			Clear()
		else
			selected = nil
			Refresh()
		end
	end
end

local function QueueSync()
	if not syncQueued then
		syncQueued = true
		C_Timer.After(0, SyncFocus)
	end
end

do
	local manager = GamepadMode and GamepadMode.FrameControlsManager
	if manager then
		for _, method in ipairs({ "FocusNextFrame", "FocusPreviousFrame", "FocusFrame", "FrameShown", "FrameHidden" }) do
			if type(manager[method]) == "function" then
				hooksecurefunc(manager, method, function()
					if method == "FocusNextFrame" or method == "FocusPreviousFrame" then userSwitched = true end
					QueueSync()
				end)
			end
		end
	end
end

if SmartNavigation and SmartNavigation.ShowCursor then
	hooksecurefunc(SmartNavigation, "ShowCursor", function()
		if opts.bound then
			C_Timer.After(0, function() if opts.bound then HideBlizzardPointer() end end)
		end
		if bound and not released then
			C_Timer.After(0, function()
				if bound and not released then HideBlizzardPointer() end
			end)
		end
	end)
end

-- Forever re-binds the controller whenever its UI focus changes; if it rebinds one of
-- our buttons while a Bagnon window is open, put ours back on top.
local reassertQueued = false
local function MaybeReassert(who, _, key)
	if who == owner or who == optOwnerFrame or not (bound or triggersBound or opts.bound) or not OUR_KEYS[key]
		or reassertQueued then return end
	Log("BIND", "%s re-bound %s, putting ours back", Name(who), tostring(key))
	reassertQueued = true
	C_Timer.After(0, function()
		reassertQueued = false
		if opts.bound then ApplyOptions() end
		if bound or triggersBound then Apply() end
	end)
end
hooksecurefunc("SetOverrideBinding", MaybeReassert)
hooksecurefunc("SetOverrideBindingClick", MaybeReassert)



--[[ Bagnon options page ]]--

-- Forever's controller pointer (SmartNavigation) only moves while its data is untainted. Bagnon's
-- options page is made of Bagnon's own (Sushi) widgets; scanning them taints SmartNavigation's
-- button groups ("SmartNavigation.activeInfo.buttonGroups tainted by Bagnon") and Navigate() then
-- refuses to run: the pointer gets stuck. While a Bagnon page is shown in Settings (gamepad UI),
-- this addon drives it instead, with its own bindings and the gold box:
--   D-pad   move between the page's controls and Settings' category list (left side)
--   A       click: checkboxes and buttons directly; a category through a secure click (Blizzard's
--           handler selects it untainted); drop-downs open the picker (Blizzard's menu would taint)
--   D-pad left/right on a slider changes its value (like the mouse wheel)
--   B       Forever's own: closes Settings
-- Colour swatches open Blizzard's colour picker from addon code; they stay mouse-only.
local optOwner = CreateFrame("Frame", "BagnonGamepadOptionsOwner")
optOwnerFrame = optOwner
local categoryButtons = {}

local function BagnonPage()
	if not (GamepadUI() and SettingsPanel and SettingsPanel:IsShown()) then return end
	for _, value in pairs(Bags) do
		if type(value) == "table" and rawget(value, "Populate") and value.IsVisible and value:IsVisible() then
			return value
		end
	end
end

local function IsOptionControl(f)
	if not (f:IsVisible() and f:IsMouseEnabled()) then return false end
	if f:IsObjectType("Slider") or f:IsObjectType("CheckButton") then
		return f:IsEnabled() ~= false
	end
	if f:IsObjectType("Button") then
		return f:IsEnabled() and f:GetScript("OnClick") ~= nil
	end
	return false
end

local function IsColorSwatch(f)
	return f.HasAlpha ~= nil and f.GetValue ~= nil and f.SetValue ~= nil and not f:IsObjectType("CheckButton")
		and not f.GetChoices
end

local function CollectOptions(page)
	local list, pageList = {}, {}
	wipe(categoryButtons)
	local function walk(f, into, mark)
		for _, child in ipairs({ f:GetChildren() }) do
			if IsOptionControl(child) then
				into[#into + 1] = child
				list[#list + 1] = child
				if mark then categoryButtons[child] = true end
			elseif child:IsVisible() then
				walk(child, into, mark)
			end
		end
	end
	walk(page, pageList, false)
	if SettingsPanel.CategoryList then
		walk(SettingsPanel.CategoryList, {}, true)
	end
	return list, pageList
end

-- nearest control in a direction (free 2D, unlike the bag grid)
local function NearestInDirection(list, from, dir)
	local fx, fy = Center(from)
	local best, bestScore
	for _, b in ipairs(list) do
		if b ~= from then
			local x, y = Center(b)
			local dx, dy = x - fx, y - fy
			local primary, secondary
			if dir == "UP" then primary, secondary = dy, dx
			elseif dir == "DOWN" then primary, secondary = -dy, dx
			elseif dir == "RIGHT" then primary, secondary = dx, dy
			else primary, secondary = -dx, dy end
			if primary > 2 then
				local score = primary + 2 * math.abs(secondary)
				if not bestScore or score < bestScore then best, bestScore = b, score end
			end
		end
	end
	return best
end

local function SelectOption(control)
	local previous = opts.selected
	if previous and previous ~= control then
		local leave = previous:GetScript("OnLeave")
		if leave then pcall(leave, previous) end
	end
	opts.selected = control
	if control then
		PointAt(control)
		local enter = control:GetScript("OnEnter")
		if enter then pcall(enter, control) end
	end
	ApplyOptions()
end

local function LeaveOptions()
	if not opts.page then return end
	Log("OPTIONS", "left Bagnon's page")
	if picker then ClosePicker() end
	local previous = opts.selected
	if previous then
		local leave = previous:GetScript("OnLeave")
		if leave then pcall(leave, previous) end
	end
	opts.page, opts.list, opts.pageList, opts.selected = nil, nil, nil, nil
	if not InCombatLockdown() then ClearOverrideBindings(optOwner) end
	opts.bound = false
	cursor:Hide()
	arrow:Hide()
end

local function RefreshOptions()
	local page = BagnonPage()
	if not page then
		LeaveOptions()
		return
	end
	if page ~= opts.page then
		Log("OPTIONS", "driving Bagnon's page %s", Name(page))
		opts.page, opts.selected = page, nil
	end
	opts.list, opts.pageList = CollectOptions(page)
	if picker then return end
	if not (opts.selected and opts.selected:IsVisible()) then
		SelectOption(TopLeft(opts.pageList) or TopLeft(opts.list))
	else
		PointAt(opts.selected)
		if not opts.bound then ApplyOptions() end
	end
end

ApplyOptions = function()
	if InCombatLockdown() then return end
	ClearOverrideBindings(optOwner)
	opts.bound = false
	if not opts.page then return end
	if picker then
		SetOverrideBindingClick(optOwner, true, "PADDUP", "BagnonGamepadPickerPrev")
		SetOverrideBindingClick(optOwner, true, "PADDLEFT", "BagnonGamepadPickerPrev")
		SetOverrideBindingClick(optOwner, true, "PADDDOWN", "BagnonGamepadPickerNext")
		SetOverrideBindingClick(optOwner, true, "PADDRIGHT", "BagnonGamepadPickerNext")
		SetOverrideBindingClick(optOwner, true, "PAD1", "BagnonGamepadPickerOK")
		SetOverrideBindingClick(optOwner, true, "PAD2", "BagnonGamepadPickerCancel")
		opts.bound = true
		HideBlizzardPointer()
		return
	end
	for key, dir in pairs(DPAD) do
		SetOverrideBindingClick(optOwner, true, key, "BagnonGamepadOptNav" .. dir)
	end
	local control = opts.selected
	if control and categoryButtons[control] then
		secureClicker:SetAttribute("clickbutton", control)
		SetOverrideBindingClick(optOwner, true, "PAD1", secureClicker:GetName(), "LeftButton")
	else
		SetOverrideBindingClick(optOwner, true, "PAD1", "BagnonGamepadOptPress", "LeftButton")
	end
	opts.bound = true
	HideBlizzardPointer()
end

local function OpenChoicePicker(control)
	local entries, start = {}, nil
	local current = control.GetValue and control:GetValue()
	for _, choice in ipairs(control:GetChoices() or {}) do
		local key = choice.key
		local isCurrent = key == current
		entries[#entries + 1] = {
			text = (isCurrent and "|cffffd100>|r " or "   ") .. tostring(choice.text or key),
			log = "choice " .. tostring(key),
			choose = function()
				control:SetValue(key)
				control:FireCalls("OnValue", key)
				control:FireCalls("OnInput", key)
				control:FireCalls("OnUpdate")
			end,
		}
		if isCurrent then start = #entries end
	end
	if #entries == 0 then return end
	local label = control.GetLabel and control:GetLabel()
	picker = { anchor = control, entries = entries, index = start or 1, title = label ~= "" and label or "Choose" }
	Log("PICKER", "choices of %s: %d", Name(control), #entries)
	ShowPicker()
	ApplyOptions()
end

local function MoveOption(dir)
	local control = opts.selected
	if not (opts.page and control) then return end
	if control:IsObjectType("Slider") and (dir == "LEFT" or dir == "RIGHT") then
		local wheel = control:GetScript("OnMouseWheel")
		local lo, hi = control:GetMinMaxValues()
		local step = control:GetValueStep() or 1
		local times = ((hi - lo) / math.max(step, 0.0001) > 40) and 5 or 1
		for _ = 1, times do
			if wheel then wheel(control, dir == "RIGHT" and 1 or -1)
			else control:SetValue(control:GetValue() + (dir == "RIGHT" and step or -step), true) end
		end
		Log("OPTIONS", "slider %s -> %s", Name(control), tostring(control:GetValue()))
		return
	end
	local nextControl = NearestInDirection(opts.list or {}, control, dir)
	if nextControl then SelectOption(nextControl) end
end

do
	for _, dir in ipairs({ "UP", "DOWN", "LEFT", "RIGHT" }) do
		local b = CreateFrame("Button", "BagnonGamepadOptNav" .. dir, UIParent)
		b:RegisterForClicks("AnyDown")
		b:SetScript("OnClick", function() MoveOption(dir) end)
	end
	local press = CreateFrame("Button", "BagnonGamepadOptPress", UIParent)
	press:RegisterForClicks("AnyDown")
	press:SetScript("OnClick", function()
		local control = opts.selected
		if not (control and control:IsVisible()) then return end
		if control.GetChoices and control.FireCalls then
			OpenChoicePicker(control)
		elseif IsColorSwatch(control) then
			print("|cff33eeffBagnon Gamepad:|r colours open Blizzard's colour picker; change them in mouse and keyboard mode.")
		elseif not control:IsObjectType("Slider") then
			Log("OPTIONS", "click %s", Name(control))
			control:Click("LeftButton")
			C_Timer.After(0, RefreshOptions)
		end
	end)
end

if SettingsPanel then
	local ticker
	SettingsPanel:HookScript("OnShow", function()
		if not ticker then ticker = C_Timer.NewTicker(0.25, RefreshOptions) end
	end)
	SettingsPanel:HookScript("OnHide", function()
		if ticker then ticker:Cancel() ticker = nil end
		LeaveOptions()
	end)
end

--[[ Debug log: verbose tracing ]]--

-- With "Verbose" on, every call of the functions below is logged with its arguments, results and
-- run time (TRACE), plus every override binding change by anyone (BINDING), every call into
-- Forever's frame manager (FCM), and every 10 s frame rate / latency, every 60 s memory (PERF).
local function Trace(name, fn)
	return function(...)
		if not Verbose() then return fn(...) end
		local start = debugprofilestop()
		local results = { n = 0 }
		local function pack(...) results.n = select("#", ...) for i = 1, results.n do results[i] = (select(i, ...)) end end
		pack(fn(...))
		Log("TRACE", "%s(%s) -> %s  %.2f ms", name, ArgsText(...),
			results.n > 0 and ArgsText(unpack(results, 1, results.n)) or "-", debugprofilestop() - start)
		return unpack(results, 1, results.n)
	end
end

Collect = Trace("Collect", Collect)
TopLeft = Trace("TopLeft", TopLeft)
Neighbour = Trace("Neighbour", Neighbour)
Wrap = Trace("Wrap", Wrap)
Select = Trace("Select", Select)
Refresh = Trace("Refresh", Refresh)
Move = Trace("Move", Move)
Cycle = Trace("Cycle", Cycle)
Clear = Trace("Clear", Clear)
Apply = Trace("Apply", Apply)
SyncFocus = Trace("SyncFocus", SyncFocus)
UpdateLegend = Trace("UpdateLegend", UpdateLegend)
UpdateHeldItem = Trace("UpdateHeldItem", UpdateHeldItem)
HideBlizzardPointer = Trace("HideBlizzardPointer", HideBlizzardPointer)
ConcealBlizzardBag = Trace("ConcealBlizzardBag", ConcealBlizzardBag)
UpdateGearOverlay = Trace("UpdateGearOverlay", UpdateGearOverlay)
UpdateCloseOverlay = Trace("UpdateCloseOverlay", UpdateCloseOverlay)
UpdateBuyOverlays = Trace("UpdateBuyOverlays", UpdateBuyOverlays)
UpdateBagOverlays = Trace("UpdateBagOverlays", UpdateBagOverlays)
BlizzardBagButton = Trace("BlizzardBagButton", BlizzardBagButton)
SecureChild = Trace("SecureChild", SecureChild)
TriggersMirrored = Trace("TriggersMirrored", TriggersMirrored)
BindTriggers = Trace("BindTriggers", BindTriggers)
OpenSplit = Trace("OpenSplit", OpenSplit)
CloseSplit = Trace("CloseSplit", CloseSplit)
AdjustSplit = Trace("AdjustSplit", AdjustSplit)
CaptureOptionsButton = Trace("CaptureOptionsButton", CaptureOptionsButton)

for _, name in ipairs({ "SetOverrideBinding", "SetOverrideBindingClick", "SetOverrideBindingSpell",
	"SetOverrideBindingMacro", "SetOverrideBindingItem", "ClearOverrideBindings" }) do
	if type(_G[name]) == "function" then
		hooksecurefunc(name, function(...)
			V("BINDING", "%s(%s)", name, ArgsText(...))
		end)
	end
end

do
	local manager = GamepadMode and GamepadMode.FrameControlsManager
	if manager then
		for _, method in ipairs({ "FocusNextFrame", "FocusPreviousFrame", "FocusFrame", "FrameShown",
			"FrameHidden", "SetUIFocusState", "SetFallThroughCatcherActive" }) do
			if type(manager[method]) == "function" then
				hooksecurefunc(manager, method, function(_, ...)
					V("FCM", "%s(%s) focus=%s", method, ArgsText(...),
						Name(manager.GetActiveFrame and manager:GetActiveFrame()))
				end)
			end
		end
	end
	if SmartNavigation then
		for _, method in ipairs({ "ShowCursor", "HideCursor", "ActivateBinding", "DeactivateBinding" }) do
			if type(SmartNavigation[method]) == "function" then
				hooksecurefunc(SmartNavigation, method, function(_, ...)
					V("SMARTNAV", "%s(%s)", method, ArgsText(...))
				end)
			end
		end
	end
end

do
	local ticks = 0
	C_Timer.NewTicker(10, function()
		if not Verbose() then return end
		ticks = ticks + 1
		local _, _, home, world = GetNetStats()
		local line = ("fps %.1f, latency home %d / world %d ms"):format(GetFramerate(), home or 0, world or 0)
		if ticks % 6 == 0 and UpdateAddOnMemoryUsage then
			UpdateAddOnMemoryUsage()
			local function kb(addon) return GetAddOnMemoryUsage and GetAddOnMemoryUsage(addon) or 0 end
			line = line .. (", memory BagnonGamepad %.0f KB, Bagnon %.0f KB, BagBrother %.0f KB, log %d lines")
				:format(kb("BagnonGamepad"), kb("Bagnon"), kb("BagBrother"), #(BagnonGamepadLog or {}))
		end
		Log("PERF", "%s", line)
	end)
end

--[[ Combat ]]--

local wasHolding = false
owner:RegisterEvent("CURSOR_CHANGED")
owner:RegisterEvent("PLAYER_REGEN_DISABLED")
owner:RegisterEvent("PLAYER_REGEN_ENABLED")
owner:SetScript("OnEvent", function(_, event)
	if event == "CURSOR_CHANGED" then
		UpdateHeldItem(bound and not released)
		local holding = CursorHasItem() and true or false
		if holding ~= wasHolding and not InCombatLockdown() then
			wasHolding = holding
			for _, f in ipairs(frames) do
				if f:IsShown() then UpdateBagOverlays(f) end
			end
			if bound then Apply() end
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		Log("COMBAT", "releasing bindings and overlays")
		ClearOverrideBindings(optOwnerFrame)
		opts.bound = false
		-- last moment bindings and secure attributes may still change: navigation pauses and the
		-- gear overlays let go of the game menu button (it may be rebuilt during combat)
		ClearOverrideBindings(owner)
		bound = false
		triggersBound = false
		split = nil
		splitFrame:Hide()
		picker = nil
		pickerFrame:Hide()
		DropMoney()
		cursor:Hide()
		arrow:Hide()
		UpdateLegend(false)
		optionsButton = nil
		ReleaseOverlays()
	else
		CaptureOptionsButton()
		Refresh()
	end
end)

--[[ Bagnon options ]]--

-- Blizzard's Settings window calls every addon page's OnCommit directly (no securecall) when it
-- closes. Bagnon's pages (Sushi option groups) only use it to fire 'OnOkay', which Bagnon
-- doesn't use: remove it.
--
-- Also: Blizzard keeps an addon's options page (canvas) without a parent until it is selected
-- (SettingsPanelMixin:DisplayLayout parents it, ClearCurrentCategoryCanvas sets it back to nil).
-- Sushi creates Bagnon's pages as permanent children of SettingsPanel, so Forever's controller
-- navigation, which scans every child of the Settings window, walks into Bagnon's addon frames
-- whenever Settings is open and taints itself (confirmed: no error with Bagnon_Config disabled).
-- Put the pages where Blizzard expects them: unparented and hidden until displayed.
local function FixBagnonPages()
	for _, value in pairs(Bags) do
		if type(value) == "table" and type(value.GetParent) == "function" then
			local ok, dock = pcall(value.GetParent, value)
			if ok and type(dock) == "table" and dock.GetParent and dock:GetParent() == SettingsPanel then
				dock.OnCommit = nil
				dock:Hide()
				dock:SetParent(nil)
				dock:ClearAllPoints()
			end
		end
	end
end

-- Bagnon opens its options with SettingsPanel:Show() + SelectCategory() from addon code (Sushi
-- OptionsGroup:Open), which taints the Settings window; closing it then closes the bags tainted
-- and Forever's controller code blocks. The game has a taint-free way: Settings.OpenToCategory()
-- goes through C_SettingsUtil.OpenSettingsPanel, which fires SETTINGS_PANEL_OPEN, and the Settings
-- window opens itself on that page from its own (secure) event handler. Bagnon's pages are opened
-- that way, in both input modes. In combat it is restricted: say so instead.
local function OpenSecurely(page)
	local category = page.GetCategory and page:GetCategory()
	local id = category and category.GetID and category:GetID()
	if not (id and Settings and Settings.OpenToCategory and C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel) then
		return false
	end
	if InCombatLockdown() then
		print("|cff33eeffBagnon Gamepad:|r Bagnon's options can't open in combat.")
		return true
	end
	Log("OPTIONS", "opening %s (category %s) through Settings.OpenToCategory", Name(page), tostring(id))
	Settings.OpenToCategory(id)
	if BagnonGamepadScanTaint then BagnonGamepadScanTaint() end
	return true
end

local function GuardOptionsOpen()
	for _, value in pairs(Bags) do
		if type(value) == "table" and rawget(value, "Populate") and type(value.Open) == "function"
			and not rawget(value, "bagnonGamepadOpen") then
			local open = value.Open
			value.bagnonGamepadOpen = open
			value.Open = function(page, ...)
				if OpenSecurely(page) then return end
				if GamepadUI() then
					Log("GUARD", "skipped Bagnon options open (%s), no secure opener", Name(page))
					print("|cff33eeffBagnon Gamepad:|r use Esc > Options > AddOns > Bagnon.")
					return
				end
				return open(page, ...)
			end
		end
	end
end

-- A "Controller" section at the end of Bagnon's main options page (Bagnon_Config is
-- load-on-demand; its pages are Sushi option groups rebuilt through Populate()). The other
-- pages (Display, Frames, Help ...) are subclasses of the main page, so the hook checks self.
AddToBagnonOptions = function()
	FixBagnonPages()
	GuardOptionsOpen()
	local page = Bags.GeneralOptions
	if not page or page.bagnonGamepadHooked then return end
	page.bagnonGamepadHooked = true
	hooksecurefunc(page, "Populate", function(self)
		if self ~= page then return end
		self:Add("Header", "Controller (Bagnon Gamepad)", "GameFontHighlight", true)
		local enable = self:Add("Check", "Controller navigation in Bagnon windows")
		enable:SetTip("Controller navigation",
			"D-pad moves between slots and header buttons, A uses / clicks, X picks up, LB/RB switch windows. Only while the gamepad interface is on and out of combat.")
		enable:SetValue(BagnonGamepadDB.enabled ~= false)
		enable:SetCall("OnClick", function(_, _, v)
			BagnonGamepadDB.enabled = v and true or false
			Refresh()
		end)

		local debug = self:Add("Check", "Debug log")
		debug:SetTip("Debug log",
			"Records blocked/forbidden calls with their stack, Lua errors, taint in the controller UI and what Bagnon Gamepad does. Saved on /reload or logout to WTF > Account > SavedVariables > BagnonGamepad.lua (BagnonGamepadLog). /bagnonpad log for more.")
		debug:SetValue(BagnonGamepadDB.debug and true or false)
		debug:SetCall("OnClick", function(_, _, v)
			SetDebug(v)
		end)

		local verbose = self:Add("Check", "Verbose debug log")
		verbose:SetTip("Verbose debug log",
			"Also logs every navigation step, binding change, frame manager call, item hover and timing (ms per call), plus frame rate and memory. Large logs; for finding slow or wrong behaviour.")
		verbose:SetValue(BagnonGamepadDB.debugVerbose and true or false)
		verbose:SetCall("OnClick", function(_, _, v)
			BagnonGamepadDB.debugVerbose = v and true or false
			Log("SESSION", "verbose %s", v and "on" or "off")
		end)

		local chat = self:Add("Check", "Also print the debug log to chat")
		chat:SetValue(BagnonGamepadDB.debugChat and true or false)
		chat:SetCall("OnClick", function(_, _, v)
			BagnonGamepadDB.debugChat = v and true or false
		end)
	end)
end

local function AddonList()
	local names = {}
	local count = C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
	for i = 1, count do
		if C_AddOns.IsAddOnLoaded(i) then
			local addon = C_AddOns.GetAddOnInfo(i)
			local version = C_AddOns.GetAddOnMetadata(i, "Version")
			names[#names + 1] = version and (addon .. " " .. version) or addon
		end
	end
	return table.concat(names, ", ")
end

LogSession = function(tag)
	local version, build, _, toc = GetBuildInfo()
	Log("SESSION", "==== %s: %s, game %s.%s (toc %s), BagnonGamepad %s, Bagnon %s ====", tag,
		date("%Y-%m-%d %H:%M:%S"), tostring(version), tostring(build), tostring(toc),
		tostring(C_AddOns.GetAddOnMetadata("BagnonGamepad", "Version")),
		tostring(C_AddOns.GetAddOnMetadata("Bagnon", "Version")))
end

Snapshot = function(tag)
	if not (BagnonGamepadDB and BagnonGamepadDB.debug) then return end
	local manager = GamepadMode and GamepadMode.FrameControlsManager
	local shown = {}
	if manager and type(manager.shownFrames) == "table" then
		for _, f in ipairs(manager.shownFrames) do shown[#shown + 1] = Name(f) end
	end
	local keys = {}
	for key in pairs(OUR_KEYS) do
		keys[#keys + 1] = key .. "=" .. tostring(GetBindingAction(key, true))
	end
	table.sort(keys)
	Log("STATE", "%s: gamepadUI=%s enabled=%s bound=%s released=%s window=%s selected=%s split=%s"
		.. " | manager focus=%s shown=[%s] | blizzard bag shown=%s alpha=%.2f | optionsButton=%s"
		.. " | cvars GamePadEnable=%s combinedBags=%s | keys %s",
		tag, tostring(GamepadUI()), tostring(BagnonGamepadDB.enabled), tostring(bound), tostring(released),
		Name(active), Name(selected), tostring(split ~= nil),
		Name(manager and manager.GetActiveFrame and manager:GetActiveFrame()), table.concat(shown, ", "),
		tostring(ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown()),
		ContainerFrameCombinedBags and ContainerFrameCombinedBags:GetAlpha() or -1,
		Name(optionsButton), tostring(C_CVar.GetCVar("GamePadEnable")), tostring(C_CVar.GetCVar("combinedBags")),
		table.concat(keys, " "))
end

SetDebug = function(on)
	BagnonGamepadDB.debug = on and true or false
	if on then
		BagnonGamepadDebugStart()
		LogSession("debug on")
		Log("SESSION", "addons: %s", AddonList())
		Snapshot("debug on")
		BagnonGamepadScanTaint()
	else
		BagnonGamepadDebugStop()
	end
	print("|cff33eeffBagnon Gamepad:|r debug log " .. (on and "on (saved on /reload or logout)" or "off"))
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		-- Bagnon loads Bagnon_Config from a hook on Settings' category list, i.e. in the middle of
		-- Blizzard opening Settings (in combat too): its pages and categories are then registered
		-- inside that secure path, which taints Settings and Forever's controller code ("execution
		-- tainted by 'Bagnon_Config'"). Loaded here at login instead, the hook finds it loaded and
		-- does nothing.
		if Bags.IsForever and C_AddOns and C_AddOns.IsAddOnLoaded and not C_AddOns.IsAddOnLoaded("Bagnon_Config")
			and not InCombatLockdown() then
			local ok, loaded, reason = pcall(C_AddOns.LoadAddOn, "Bagnon_Config")
			Log("OPTIONS", "preloaded Bagnon_Config: %s %s", tostring(ok and loaded), tostring(reason))
		end
		HookGameMenu()
		Snapshot("login")
	elseif name == "BagnonGamepad" then
		BagnonGamepadDB = BagnonGamepadDB or {}
		-- settings of earlier versions (icon styles)
		BagnonGamepadDB.glyphs, BagnonGamepadDB.gameIcons, BagnonGamepadDB.originalLabels = nil, nil, nil
		if BagnonGamepadDB.enabled == nil then BagnonGamepadDB.enabled = true end
		BagnonGamepadLog = BagnonGamepadLog or {}
		if BagnonGamepadDB.debug then
			BagnonGamepadDebugStart()
			LogSession("load")
		end
	elseif name and name:find("^Bagnon") then
		LogActivityHooks()
	end
	if name == "Bagnon_Config" then
		AddToBagnonOptions()
		GuardBagnonMenus()
	elseif name == "Bagnon_Bank" or name == "Bagnon_GuildBank" then
		GuardBagnonMenus()
		GuardBankPurchase()
	elseif name == "Blizzard_GameMenu" then
		HookGameMenu()
	end
end)

SLASH_BAGNONGAMEPAD1 = "/bagnonpad"
SlashCmdList.BAGNONGAMEPAD = function(msg)
	msg = strtrim(msg or "")
	local cmd, arg = msg:match("^(%S*)%s*(.-)$")
	if cmd == "log" then
		if arg == "on" or arg == "off" then
			SetDebug(arg == "on")
		elseif arg == "verbose on" or arg == "verbose off" then
			BagnonGamepadDB.debugVerbose = arg == "verbose on"
			if BagnonGamepadDB.debugVerbose and not BagnonGamepadDB.debug then SetDebug(true) end
			Log("SESSION", "verbose %s", BagnonGamepadDB.debugVerbose and "on" or "off")
			print("|cff33eeffBagnon Gamepad:|r verbose debug log " .. (BagnonGamepadDB.debugVerbose and "on" or "off"))
		elseif arg == "clear" then
			wipe(BagnonGamepadLog)
			if BagnonGamepadDB.debug then LogSession("cleared") end
			print("|cff33eeffBagnon Gamepad:|r debug log cleared")
		elseif arg == "mark" or arg:match("^mark ") then
			Log("MARK", "%s", arg:sub(6) ~= "" and arg:sub(6) or "----")
			Snapshot("mark")
			print("|cff33eeffBagnon Gamepad:|r mark added")
		elseif arg == "scan" then
			BagnonGamepadDeepScan("manual")
			print("|cff33eeffBagnon Gamepad:|r deep taint scan written to the log")
		elseif arg == "state" then
			Snapshot("manual")
			BagnonGamepadScanTaint()
			print("|cff33eeffBagnon Gamepad:|r state written to the log")
		else
			print("|cff33eeffBagnon Gamepad:|r debug log is " .. (BagnonGamepadDB.debug and "on" or "off")
				.. (BagnonGamepadDB.debugVerbose and " (verbose)" or "")
				.. (", %d lines. /bagnonpad log on | off | verbose on | verbose off | clear | state | mark <note>"):format(#BagnonGamepadLog))
		end
		return
	end
	BagnonGamepadDB.enabled = not BagnonGamepadDB.enabled
	print("|cff33eeffBagnon Gamepad:|r controller navigation " .. (BagnonGamepadDB.enabled and "on" or "off"))
	Refresh()
end

if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Bagnon_Config") then
	AddToBagnonOptions()
end
