local shortname = require('customhud.shortname')

local function updatename(self, paramname)
	local newname = self.map[paramname] or self[paramname]
	self['long name'] = self.widgettype .. ': ' .. newname
	self['short name'] = datasource.shortname[newname] or newname
end -- local function updatename
------------------------------------------------------------------------
local paramtype = {}
------------------------------------------------------------------------
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
* category: data, style, layout, or miscellaneous
* default value
]]
------------------------------------------------------------------------
--[[paramtype['widget name'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	category = 'miscellaneous',
	default = '',
	update = function(self)
		updatename(self, 'widget name')
	end,
	},]]
------------------------------------------------------------------------
paramtype['short name'] = {
	datatype = 'string',
	hidden = true,
	default = '',
	},
------------------------------------------------------------------------
paramtype['long name'] = {
	datatype = 'string',
	hidden = true,
	default = '',
	},
------------------------------------------------------------------------
paramtype['display text'] = {
	datatype = 'string',
	staticsource = true,
	functionsource = true,
	fieldsource = true,
	category = 'data',
	default = 'taco cat backwards is taco cat',
	update = function(self)
		updatename(self, 'display text')
	end,
	},
------------------------------------------------------------------------
paramtype['overlay text'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	functionsource = true,
	fieldsource = true,
	category = 'data',
	default = 'taco cat backwards is taco cat',
	},
------------------------------------------------------------------------
paramtype['label text'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	category = 'data',
	default = 'taco cat backwards is taco cat',
	},
------------------------------------------------------------------------
paramtype['font scale'] = {
	datatype = 'slow number',
	optional = true,
	staticsource = true,
	category = 'style',
	default = 1,
	step = 0.1,
	minimum = 0.5,
	maximum = 5,
	displayformat = '%.1f',
	},
------------------------------------------------------------------------
paramtype['widget width'] = {
	datatype = 'number',
	optional = true,
	staticsource = true,
	category = 'layout',
	default = 10,
	largestep = .01,
	smallstep = .0001
	minimum = 0,
	maximum = 1,
	scale = 640,
	},
------------------------------------------------------------------------
paramtype['widget height'] = {
	datatype = 'number',
	optional = true,
	staticsource = true,
	category = 'layout',
	default = 2,
	largestep = .01,
	smallstep = .0001
	minimum = 0,
	maximum = 1,
	scale = 480,
	},
------------------------------------------------------------------------
paramtype['text padding'] = {
	datatype = 'slow number',
	optional = true,
	staticsource = true,
	category = 'layout',
	default = 0,
	step = 1,
	minimum = 0,
	maximum = 48,
	},
------------------------------------------------------------------------
paramtype['same line'] = {
	datatype = 'boolean',
	staticsource = true,
	category = 'layout',
	default = true,
	},
------------------------------------------------------------------------
paramtype['scale progress bar'] = {
	datatype = 'boolean',
	staticsource = true,
	category = 'style',
	default = true,
	},
------------------------------------------------------------------------
paramtype['bar progress'] = {
	datatype = 'progress',
	fieldsource = 'true',
	functionsource = 'true',
	category = 'data',
	default = 1,
	update = function(self)
		updatename(self, 'bar progress')
	end,
	}
------------------------------------------------------------------------
paramtype['text gradient index'] = {
	datatype = 'progress',
	optional = true,
	functionsource = true,
	fieldsource = true,
	category = 'data',
	default = 1,
	},
------------------------------------------------------------------------
paramtype['widget color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	category = 'style',
	default = function() return {.9, .2, .2, 1} end,
	},
------------------------------------------------------------------------
paramtype['text color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	category = 'style',
	default = function() return {.8, .8, .8, 1} end,
	},
------------------------------------------------------------------------
paramtype['text color gradient'] = {
	datatype = 'list',
	subtype = 'color level',
	optional = true,
	staticsource = true,
	category = 'style',
	default = function() return {} end,
	},
------------------------------------------------------------------------
paramtype['progress color gradient'] = {
	datatype = 'list',
	subtype = 'color level',
	optional = true,
	staticsource = true,
	category = 'style',
	default = function() return {} end,
	},
------------------------------------------------------------------------
paramtype['widget list'] = {
	datatype = 'list',
	subtype = 'widget',
	staticsource = true,
	category = 'data',
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
	}, -- paramtype['widget list'] = {...}
------------------------------------------------------------------------
return paramtype
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
* category: data, style, layout, or miscellaneous
* default value
]]
