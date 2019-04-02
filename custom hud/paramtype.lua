local shortname = require('custom hud.shortname')
local updatewindowoption = require('custom hud.utility').updatewindowoption

--[[local function updatename(self, paramname)
	local newname = self.map[paramname] or self[paramname]
	self['long name'] = self.widgettype .. ': ' .. newname
	self['short name'] = datasource.shortname[newname] or newname
end -- local function updatename]]
--------------------------------------------------------------------------------
local function updatehidecondition(self, condition)
	if self[condition] then
		self.menustate[condition] = true
	else
		self.menustate[condition] = nil
	end
end
--------------------------------------------------------------------------------
local paramtype = {}
--------------------------------------------------------------------------------
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list, window position and size
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
]]
--------------------------------------------------------------------------------
paramtype['short name'] = {
	datatype = 'string',
	hidden = true,
	}
--------------------------------------------------------------------------------
paramtype['long name'] = {
	datatype = 'string',
	hidden = true,
	}
--------------------------------------------------------------------------------
paramtype['display text'] = {
	datatype = 'string',
	staticsource = true,
	functionsource = true,
	fieldsource = true,
	-- update = function(self)
		-- updatename(self, 'display text')
	-- end,
	updatename = true
	}
--------------------------------------------------------------------------------
paramtype['overlay text'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	functionsource = true,
	fieldsource = true,
	hideif = function(self) return self['show value'] end,
	}
--------------------------------------------------------------------------------
paramtype['label text'] = {
	datatype = 'string',
	optional = true,
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['window title'] = {
	datatype = 'string',
	staticsource = true,
}
--------------------------------------------------------------------------------
paramtype['font scale'] = {
	datatype = 'slow number',
	optional = true,
	staticsource = true,
	step = 0.1,
	minimum = 0.5,
	maximum = 5,
	displayformat = '%.1f',
	}
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
--[[paramtype['display number range'] = {
	datatype = 'number',
	optional = true,
	functionsource = true,
	fieldsource = true,
	default = 0,
	}]]
--------------------------------------------------------------------------------
paramtype['widget width'] = {
	datatype = 'number',
	staticsource = true,
	largestep = .01,
	smallstep = .0001
	minimum = 0,
	maximum = 1,
	scale = 640,
	}
--------------------------------------------------------------------------------
paramtype['widget height'] = {
	datatype = 'number',
	staticsource = true,
	largestep = .01,
	smallstep = .0001
	minimum = 0,
	maximum = 1,
	scale = 480,
	}
--------------------------------------------------------------------------------
paramtype['text padding'] = {
	datatype = 'slow number',
	optional = true,
	staticsource = true,
	step = 1,
	minimum = 0,
	maximum = 48,
	}
--------------------------------------------------------------------------------
paramtype['same line'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['scale progress bar'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['dynamic bar color'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['dynamic text color'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['show value'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['show range'] = {
	datatype = 'boolean',
	staticsource = true,
	hideif = function(self) return not self['show value'] end,
	}
--------------------------------------------------------------------------------
paramtype['enable window'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['auto resize'] = {
	datatype = 'boolean',
	staticsource = true,
	update = function(self)
		updatewindowoption(self, self['auto resize'], 5, 'AlwaysAutoResize')
		self['window option changed'] = true
	end,
	}
--------------------------------------------------------------------------------
paramtype['move with mouse'] = {
	datatype = 'boolean',
	staticsource = true,
	update = function(self)
		updatewindowoption(self, not self['move with mouse'], 3, 'NoMove')
	end,
	}
--------------------------------------------------------------------------------
paramtype['resize with mouse'] = {
	datatype = 'boolean',
	staticsource = true,
	disableif = 'auto resize',
	update = function(self)
		updatewindowoption(self, not self['resize with mouse'], 2, 'NoResize')
	end,
	}
--------------------------------------------------------------------------------
paramtype['not in field'] = {
	datatype = 'boolean',
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['in lobby'] = {
	datatype = 'boolean',
	staticsource = true,
	hideif = function(self) return self['not in field'] end,
	}
--------------------------------------------------------------------------------
paramtype['any menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	-- update = function(self)
		-- updatehidecondition(self, 'any menu is open') end,
	}
--------------------------------------------------------------------------------
paramtype['lower screen menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	disableif = 'any menu is open',
	-- update = function(self)
		-- updatehidecondition(self, 'lower screen menu is open') end,
	}
--------------------------------------------------------------------------------
paramtype['main menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	disableif = 'any menu is open',
	-- update = function(self)
		-- updatehidecondition(self, 'main menu is open') end,
	}
--------------------------------------------------------------------------------
paramtype['full screen menu is open'] = {
	datatype = 'boolean',
	staticsource = true,
	disableif = 'any menu is open'
	-- update = function(self)
		-- updatehidecondition(self, 'full screen menu is open') end,
	}
--------------------------------------------------------------------------------
paramtype['show titlebar'] = {
	datatype = 'boolean',
	staticsource = true,
	update = function(self)
		updatewindowoption(self, not self['show titlebar'], 1, 'NoTitleBar')
	end,
	}
--------------------------------------------------------------------------------
paramtype['show scrollbar'] = {
	datatype = 'boolean',
	staticsource = true,
	update = function(self)
		updatewindowoption(self, not self['show scrollbar'], 4, 'NoScrollBar')
	end,
	}
--------------------------------------------------------------------------------
paramtype['bar value'] = {
	datatype = 'progress',
	fieldsource = 'true',
	functionsource = 'true',
	-- update = function(self)
		-- updatename(self, 'bar progress')
	-- end,
	updatename = true
	}
--------------------------------------------------------------------------------
paramtype['display value'] = {
	datatype = 'progress',
	functionsource = true,
	fieldsource = true,
	-- update = function(self)
		-- updatename(self, 'display value')
	-- end,
	updatename = true
	}
--------------------------------------------------------------------------------
paramtype['bar color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	hideif = function(self) return self['dynamic bar color'] end,
	}
--------------------------------------------------------------------------------
paramtype['widget color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['text color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	hideif = function(self) return self['dynamic text color'] end,
	}
--------------------------------------------------------------------------------
paramtype['background color'] = {
	datatype = 'color',
	optional = true,
	staticsource = true,
	}
--------------------------------------------------------------------------------
paramtype['text gradient'] = {
	datatype = 'list',
	subtype = 'color level',
	-- optional = true,
	staticsource = true,
	hideif = function(self) return not self['dynamic text color'] end,
	}
--------------------------------------------------------------------------------
paramtype['bar gradient'] = {
	datatype = 'list',
	subtype = 'color level',
	optional = true,
	staticsource = true,
	hideif = function(self) return not self['dynamic bar color'] end,
	}
--------------------------------------------------------------------------------
paramtype['widget list'] = {
	datatype = 'list',
	subtype = 'widget',
	staticsource = true,
	dragtargetmargin = 48,
	
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
--------------------------------------------------------------------------------
paramtype['position and size'] = {
	datatype = 'window position and size',
	staticsource = true,
	update = function(self) self['window option changed'] = true end,
}
--------------------------------------------------------------------------------
paramtype['window options'] = {hidden = true,}
--------------------------------------------------------------------------------
return
	{
	typedef = function(typename) return paramtype[typename] end,
	datatype = function(typename)
			if paramtype[typename] then return paramtype[typename].datatype end
		end,
	}
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
* default value
]]
