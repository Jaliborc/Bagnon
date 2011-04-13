--[[
	Ears.lua
		A simple message passing object.
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Ears = {}
Bagnon.Ears = Ears


--ye old constructor
local ears_MT = {__index = Ears}

function Ears:New()
	local o = setmetatable({}, ears_MT)
	o.listeners = {}
	return o
end


--trigger a message, with the given args
function Ears:SendMessage(msg, ...)
	assert(msg, 'Usage: Ears:SendMessage(msg[, args])')
	assert(type(msg) == 'string', 'String expected for <msg>, got: \'' .. type(msg) .. '\'')

	local listeners = self.listeners[msg]
	if listeners then
		for obj, action in pairs(listeners) do
			action(obj, msg, ...)
		end
	end
end


--tells obj to do something when msg happens
function Ears:Listen(obj, msg, method)
	assert(obj and msg, 'Usage: Ears:Listen(obj, msg[, method])')
	assert(type(msg) == 'string', 'String expected for <msg>, got: \'' .. type(msg) .. '\'')

	local method = method or msg
	local action

	if type(method) == 'string' then
		assert(obj[method] and type(obj[method]) == 'function', 'Object does not have an instance of ' .. method)
		action = obj[method]
	else
		assert(type(method) == 'function', 'String or function expected for <method>, got: \'' .. type(method) .. '\'')
		action = method
	end

	local listeners = self.listeners[msg] or {}
	listeners[obj] = action
	self.listeners[msg] = listeners

--	assert(self.listeners[msg] and self.listeners[msg][obj], 'Ears: Failed to register ' .. msg)
end


--tells obj to do nothing when msg happens
function Ears:Ignore(obj, msg)
	assert(obj and msg, 'Usage: Ears:Ignore(obj, msg)')
	assert(type(msg) == 'string', 'String expected for <msg>, got: \'' .. type(msg) .. '\'')

	local listeners = self.listeners[msg]
	if listeners then
		listeners[obj] = nil
		if not next(listeners) then
			self.listeners[msg] = nil
		end
	end

--	assert(not(self.listeners[msg] and self.listeners[msg][obj]), 'Ears: Failed to ignore ' .. msg)
end


--ignore all messages for obj
function Ears:IgnoreAll(obj)
	assert(obj, 'Usage: Ears:IgnoreAll(obj)')

	for msg in pairs(self.listeners) do
		self:Ignore(obj, msg)
	end
end