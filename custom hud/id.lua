-- local neondebug = require('custom hud.neondebug')

local id = {}
local taken = {}
local freed = {}

id.new = function()
	local newid = next(freed)
	if newid then
		freed[newid] = nil
	else
		newid = #taken + 1
	end
	taken[newid] = true
	return newid
end

id.free = function(newfreeid)
	taken[newfreeid] = nil
	freed[newfreeid] = true
end

return id