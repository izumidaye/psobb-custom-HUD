local paramtype = require('custom hud.paramtype')
local typedef = paramtype.typedef
local datatype = paramtype.datatype

local defaultvalue =
	{
	['string'] = 'taco cat backwards is taco cat',
	['short name'] = '',
	['long name'] = '',
	['window title'] = '',


	['widget width'] = -1,
	['widget height'] = -1,
	-- ['text padding'] = 0,
	['inputtext buffer size'] = 72,
	
	['boolean'] = false,
	-- ['same line'] = false,
	['scale progress bar'] = true,
	['show value'] = true,
	['show range'] = true,
	['enable window'] = true,
	['auto resize'] = true,
	['move with mouse'] = true,
	['in lobby'] = true,
	['full screen menu is open'] = true,
	
	['progress'] = function() return {0, 1} end,

	['color'] = function() return {.5, .5, .5, 1} end,
	['bar color'] = function() return {.2, .9, .2, 1} end,
	['widget color'] = function() return {.9, .2, .2, 1} end,
	['text color'] = function() return {.8, .8, .8, 1} end,
	['background color'] = function() return {.1, .1, .1, .5} end,
	
	['window position and size'] = function() return {x=0, y=0, w=5, h=5,} end,
	['window options'] = function() return {'', '', '', '', ''} end,

	['dontserialize'] = {['dontserialize'] = true, ['parameters'] = true,},
	}

defaultvalue['list'] =
	{
	['color level'] = function() return {} end,
	['widget'] = function() return {changed = true, buttonedges = {8},
		buttoncenters = {}, orientation = 'horizontal',
		dragtarget = {left = 0, right = 0, top = 0, bottom = 0},}
		end,
	}

return function(param)
	local result
	if defaultvalue[param] then result = defaultvalue[param]
	else
		local thistype = typedef(param)
		if defaultvalue[thistype.datatype] then
			result = defaultvalue[thistype.datatype]
			if thistype.subtype then result = result[thistype.subtype] end
		else return
		end
	end
	if result then
		if type(result) == 'function' then return result() else return result end
	end -- if result
end -- return function(param, subtype)