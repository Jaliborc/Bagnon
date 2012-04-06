--[[
	Classy.lua
		Utility methods for constructing a Bagnon object class
--]]

local Bagnon = LibStub('AceAddon-3.0'):GetAddon('Bagnon')

function Bagnon:NewClass(name, type, parent)
	local class = CreateFrame(type)
	class.mt = {__index = class}
  class:Hide()
  
	if parent then
		class = setmetatable(class, {__index = parent})
		class.super = parent
	end

	class.Bind = function(self, obj)
		return setmetatable(obj, self.mt)
	end
	
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

  self[name] = class
	return class
end