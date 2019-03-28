local shortname = require('customhud.shortname')

--[[local function updatename(self, paramname)
	local newname = self.map[paramname] or self[paramname]
	self['long name'] = self.widgettype .. ': ' .. newname
	self['short name'] = datasource.shortname[newname] or newname
end -- local function updatename]]
------------------------------------------------------------------------
local paramtype = {}
------------------------------------------------------------------------
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list, window position and size
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
* default value
]]
------------------------------------------------------------------------
--[[paramtype['widget name'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	default = '',
	-- update = function(self)
		-- updatename(self, 'widget name')
	-- end,
	updatename = true
	}]]
------------------------------------------------------------------------
paramtype['short name'] = {
	datatype = 'string',
	hidden = true,
	default = '',
	}
------------------------------------------------------------------------
paramtype['long name'] = {
	datatype = 'string',
	hidden = true,
	default = '',
	}
------------------------------------------------------------------------
paramtype['display text'] = {
	datatype = 'string',
	staticsource = true,
	functionsource = true,
	fieldsource = true,
	default = 'taco cat backwards is taco cat',
	-- update = function(self)
		-- updatename(self, 'display text')
	-- end,
	updatename = true
	}
------------------------------------------------------------------------
paramtype['overlay text'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	functionsource = true,
	fieldsource = true,
	default = 'taco cat backwards is taco cat',
	hideif = function(self) return self['show value'] end,
	}
------------------------------------------------------------------------
paramtype['label text'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	default = 'taco cat backwards is taco cat',
	}
------------------------------------------------------------------------
paramtype['window title'] = {
	datatype = 'string',
	staticsource = true,
	default = '',
}
------------------------------------------------------------------------
paramtype['font scale'] = {
	datatype = 'slow number',
	optional = true,
	staticsource = true,
	default = 1,
	step = 0.1,
	minimum = 0.5,
	maximum = 5,
	displayformat = '%.1f',
	}
------------------------------------------------------------------------
--[[paramtype['display number'] = {
	datatype = 'number',
	optional = false,
	functionsource = true,
	fieldsource = true,
	default = 0,
	-- update = function(self)
		-- updatename(self, 'display number')
	-- end,
	updatename = true
	}]]
------------------------------------------------------------------------
--[[paramtype['display number range'] = {
	datatype = 'number',
	optional = true,
	functionsource = true,
	fieldsource = true,
	default = 0,
	}]]
------------------------------------------------------------------------
paramtype['widget width'] = {
	datatype = 'number',
	optional = true,
	staticsource = true,
	default = 10,
	largestep = .01,
	smallstep = .0001
	minimum = 0,
	maximum = 1,
	scale = 640,
	}
------------------------------------------------------------------------
paramtype['widget height'] = {
	datatype = 'number',
	optional = true,
	staticsource = true,
	default = 2,
	largestep = .01,
	smallstep = .0001
	minimum = 0,
	maximum = 1,
	scale = 480,
	}
------------------------------------------------------------------------
paramtype['text padding'] = {
	datatype = 'slow number',
	optional = true,
	staticsource = true,
	default = 0,
	step = 1,
	minimum = 0,
	maximum = 48,
	}
------------------------------------------------------------------------
paramtype['same line'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['scale progress bar'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['dynamic bar color'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['dynamic text color'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['show value'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['show range'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	hideif = function(self) return not self['show value'] end,
	}
------------------------------------------------------------------------
paramtype['enable window'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['auto resize'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	}
------------------------------------------------------------------------
paramtype['move with mouse'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	}
------------------------------------------------------------------------
paramtype['resize with mouse'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	disableif = 'auto resize',
	}
------------------------------------------------------------------------
paramtype['not in field'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	}
------------------------------------------------------------------------
paramtype['in lobby'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	disableif = 'not in field',
	}
------------------------------------------------------------------------
paramtype['any menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	}
------------------------------------------------------------------------
paramtype['lower screen menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	disableif = 'any menu is open',
	}
------------------------------------------------------------------------
paramtype['main menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	disableif = 'any menu is open',
	}
------------------------------------------------------------------------
paramtype['full screen menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	default = true,
	disableif = 'any menu is open'
	}
------------------------------------------------------------------------
paramtype['show titlebar'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	}
------------------------------------------------------------------------
paramtype['show scrollbar'] = {
	datatype = 'boolean',
	staticsource = true,
	default = false,
	}
------------------------------------------------------------------------
paramtype['bar value'] = {
	datatype = 'progress',
	fieldsource = 'true',
	functionsource = 'true',
	default = 1,
	-- update = function(self)
		-- updatename(self, 'bar progress')
	-- end,
	updatename = true
	}
------------------------------------------------------------------------
paramtype['display value'] = {
	datatype = 'progress',
	functionsource = true,
	fieldsource = true,
	default = 1,
	-- update = function(self)
		-- updatename(self, 'display value')
	-- end,
	updatename = true
	}
------------------------------------------------------------------------
paramtype['bar color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	hideif = function(self) return self['dynamic bar color'] end,
	}
------------------------------------------------------------------------
paramtype['widget color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	default = function() return {.9, .2, .2, 1} end,
	}
------------------------------------------------------------------------
paramtype['text color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	default = function() return {.8, .8, .8, 1} end,
	hideif = function(self) return self['dynamic text color'] end,
	}
------------------------------------------------------------------------
paramtype['background color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	default = function() return {.1, .1, .1, .5} end,
	}
------------------------------------------------------------------------
paramtype['text gradient'] = {
	datatype = 'list',
	subtype = 'color level',
	-- optional = true,
	staticsource = true,
	default = function() return {} end,
	hideif = function(self) return not self['dynamic text color'] end,
	}
------------------------------------------------------------------------
paramtype['bar gradient'] = {
	datatype = 'list',
	subtype = 'color level',
	optional = true,
	staticsource = true,
	default = function() return {} end,
	hideif = function(self) return not self['dynamic bar color'] end,
	}
------------------------------------------------------------------------
paramtype['widget list'] = {
	datatype = 'list',
	subtype = 'widget',
	staticsource = true,
	dragtargetmargin = 48,
	
	default = function()
		return
			{
			changed = true,
			buttonedges = {8},
			buttoncenters = {},
			orientation = 'horizontal',
			dragtarget = {left = 0, right = 0, top = 0, bottom = 0},
			}
	end, -- default = function
	
	listitem = function(self, id, active)
		local clicked = false
		
		if active then
			imgui.PushStyleColor('Button', .2, .5, 1, 1)
			imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
			imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
			clicked = imgui.Button(self['short name'] .. '##' .. id)
			imgui.PopStyleColor()
			imgui.PopStyleColor()
			imgui.PopStyleColor()
		else
			imgui.PushStyleColor('Button', .5, .5, .5, .3)
			clicked = imgui.Button(self['short name'] .. '##' .. id)
			imgui.PopStyleColor()
		end -- if active
		
		if imgui.IsItemHovered() and (not imgui.IsMouseDown(0)) then
			imgui.SetTooltip(self['long name'])
		end
		
		return clicked
	end, -- listitem = function
	
	tooltip = function(self) return self['long name'] end,
	} -- paramtype['widget list'] = {...}
------------------------------------------------------------------------
paramtype['position and size'] = {
	datatype = 'window position and size',
	staticsource = true,
	default = function()
		return {x=0, y=0, w=5, h=5,}
	end,
}
------------------------------------------------------------------------
return paramtype
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
* default value
]]
