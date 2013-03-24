--[[
	Classy.lua
		Utility method for constructing object classes
--]]

local _, Addon = ...

function Addon:NewClass(name, type, parent)
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
		Bagnon.RegisterCallback(self, ...)
	end
	
	class.SendMessage = function(self, ...)
		Bagnon:SendCallback(...)
	end
	
	class.UnregisterMessage = function(self, ...)
		Bagnon.UnregisterCallback(self, ...)
	end
	
	class.UnregisterAllMessages = function(self)
		Bagnon.UnregisterAllCallbacks(self)
	end

	self[name] = class
	return class
end