--[[
	Classy.lua
		Utility methods for constructing a Bagnon object class
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')
local Classy = {}
Bagnon.Classy = Classy

function Classy:New(frameType, parentClass)
	local class = CreateFrame(frameType)
	class.mt = {__index = class}

	if parentClass then
		class = setmetatable(class, {__index = parentClass})
		class.super = parentClass
	end

	class.Bind = function(self, obj)
		return setmetatable(obj, self.mt)
	end
	
	--callback support
	class.RegisterMessage = function(self, ...)
		Bagnon.Callbacks:Listen(self, ...)
	end
	
	class.SendMessage = function(self, ...)
		Bagnon.Callbacks:SendMessage(...)
	end
	
	class.UnregisterMessage = function(self, ...)
		Bagnon.Callbacks:Ignore(self, ...)
	end
	
	class.UnregisterAllMessages = function(self, ...)
		Bagnon.Callbacks:IgnoreAll(self, ...)
	end

	return class
end