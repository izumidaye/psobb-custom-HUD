local utility = require('custom hud.utility')

local datasource
local widget = {}
------------------------------------------------------------------------
local paramtype =
	{
--[[
what makes up a parameter type?

* data type
* optional or not
* source of data: static, function, or table field
* category: data, style, layout, or miscellaneous
* default value
]]
	
	['widget name'] =
		{
		datatype = 'string',
		optional = true,
		staticsource = true,
		category = 'miscellaneous',
		default = '',
		},
	
	['display text'] =
		{
		datatype = 'string',
		staticsource = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 'taco cat backwards is taco cat',
		},
	
	['overlay text'] =
		{
		datatype = 'string',
		optional = true,
		staticsource = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 'taco cat backwards is taco cat',
		},
	
	['label text'] =
		{
		datatype = 'string',
		optional = true,
		staticsource = true,
		category = 'data',
		default = 'taco cat backwards is taco cat',
		},
	
	['text gradient index'] =
		{
		datatype = 'number',
		optional = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 1,
		},
	
	['text gradient range'] =
		{
		datatype = 'number',
		optional = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 1,
		},
	
	['progress index'] =
		{
		datatype = 'number',
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 1,
		},
	
	['progress range'] =
		{
		datatype = 'number',
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 1,
		},
	
	-- ['font scale'] =
		-- {
		-- datatype = 'number',
		-- optional = true,
		-- staticsource = true,
		-- category = 'style',
		-- default = 1,
		-- largestep = 0.1,
		-- smallstep = 0.01,
		-- minimum = 0.5,
		-- maximum = 5,
		-- displayformat = '%.2f',
		-- },
	
	['widget width'] =
		{
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
	
	['widget height'] =
		{
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
	
	['text padding'] =
		{
		datatype = 'slow number',
		optional = true,
		staticsource = true,
		category = 'layout',
		default = 0,
		step = 1,
		minimum = 0,
		maximum = 48,
		},
	
	['same line'] =
		{
		datatype = 'boolean',
		staticsource = true,
		category = 'layout',
		default = function() return true end,
		},
	
	['scale progress bar'] =
		{
		datatype = 'boolean',
		staticsource = true,
		category = 'style',
		default = function() return true end,
		},
	
	['widget color'] =
		{
		datatype = 'color',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {.9, .2, .2, 1} end,
		},
	
	['text color'] =
		{
		datatype = 'color',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {.8, .8, .8, 1} end,
		},
	
	['text color gradient'] =
		{
		datatype = 'color gradient',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {} end,
		},
	
	['progress color gradient'] =
		{
		datatype = 'color gradient',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {} end,
		},
	
	['format table'] =
		{
		datatype = 'format table',
		staticsource = true,
		category = 'data',
		},
	
	}
------------------------------------------------------------------------
local function validateparameters(self)
	for _, parameter in ipairs(self.parameters) do
		if (not paramtype[parameter].optional) and (not self[parameter]) then
			self.ready = false
			return
		end
	end
	self.ready = true
end -- local function validateparameters(self)
------------------------------------------------------------------------
local function evaluategradient(self, colorparam, gradientparam, indexparam, rangeparam)
	
	if self[gradientparam] then
		local index = self[indexparam] / self[rangeparam]
		for _, colorlevel in ipairs(self[gradientparam]) do
			if index >= colorlevel[1] then
				self[colorparam] = colorlevel[2]
			else
				return
			end
		end -- for _, colorlevel in ipairs(self['color gradient'])
	end -- if self['color gradient']
	
end -- local function evaluategradient(self)
------------------------------------------------------------------------
local function display(self)
	if self['ready'] then
		if self['same line'] then imgui.SameLine() end
		evaluategradient(self, 'text color', 'text color gradient', 'text gradient index', 'text gradient range')
		return true
	else
		return false
	end
end -- local function display(self)
------------------------------------------------------------------------
local function combobox(data, key, combolist)
	imgui.PushItemWidth(8 + (8 * combolist.longest))
		local changed, newvalue = imgui.Combo('##' .. key, combolist[data[key]], combolist, #combolist)
	imgui.PopItemWidth()
	if changed then data[key] = combolist[newvalue] end
end
------------------------------------------------------------------------
local function paramsourceeditor(widget, paramname)
	
	local typedef = paramtype[paramname]
	
	if typedef.optional then
		if imgui.Button('clear##' .. paramname) then
			widget[paramname] = nil
			widget.map[paramname] = nil
		end
		imgui.SameLine()
	end
	
	if widget.fieldcombolist then
		if typedef.fieldsource then
			imgui.Text('source:')
			imgui.SameLine()
			if widget.map[paramname] then
				combobox(widget.map, paramname, widget.fieldcombolist)
			else
				if imgui.Button('use list field##' .. paramname) then
					widget.map[paramname] = widget.fieldcombolist[1]
				end
			end -- if widget.map[paramname]
			imgui.SameLine()
		end -- if typedef.fieldsource
		
	elseif typedef.functionsource then
		if widget.map[paramname] then
			combobox(widget.map, paramname, datasource[typedef.datatype].combolist)
		else
			if imgui.Button('use game data##' .. paramname) then
				widget.map[paramname] = datasource[typedef.datatype].combolist[1]
			end
		end -- if widget.map[paramname]
		imgui.SameLine()
	end -- if widget.fieldcombolist
	
	if typedef.staticsource and widget.map[paramname] then
		if imgui.Button('use static value##' .. paramname) then
			widget.map[paramname] = nil
			widget[paramname] = typedef.default()
		end
	end
	
end -- local function paramsourceeditor
------------------------------------------------------------------------
local paramedit = {}
------------------------------------------------------------------------
paramedit['string'] = function(widget, paramname)
	imgui.Text(paramname)
	imgui.SameLine()
	local changed, newvalue = imgui.InputText('##' .. paramname, widget[paramname], 72)
	if changed then widget[paramname] = newvalue end
	
	paramsourceeditor(widget, paramname)
end -- paramedit['string'] = function
------------------------------------------------------------------------
paramedit['boolean'] = function(widget, paramname)
	local changed, newvalue = imgui.Checkbox(paramname, widget[paramname])
	if changed then widget[paramname] = newvalue end
	
	-- paramsourceeditor(widget, paramname)
	-- so far, there's no reason to use game data for a boolean parameter
end -- paramedit['boolean'] = function
------------------------------------------------------------------------
paramedit['number'] = function(widget, paramname)
	local typedef = paramtype[paramname]
	local displayvalue
	if typedef.scale then
		displayvalue = utility.round(widget[paramname] * typedef.scale)
		-- displayvalue = string.format
			-- {'%s', utility.round(widget[paramname] * typedef.scale)}
			-- not sure if i need to convert to string
	else
		displayvalue = widget[paramname]
	end -- if typedef.scale
	
	imgui.Text(paramname .. ':')
	imgui.SameLine()
	imgui.PushItemWidth(72)
		
		local changed, newvalue = imgui.DragFloat
			{
			'##' .. paramname,
			widget[paramname],
			typedef.largestep,
			typedef.minimum,
			typedef.maximum,
			displayvalue
			}
		if changed then widget[paramname] = newvalue end
		imgui.SameLine()
		
		changed, newvalue = imgui.DragFloat
			{
			'##finetune' .. paramname,
			widget[paramname],
			typedef.smallstep,
			typedef.minimum,
			typedef.maximum,
			'fine tune'
			}
		if changed then widget[paramname] = newvalue end
		
	imgui.PopItemWidth()
	
	paramsourceeditor(widget, paramname)
end -- paramedit['number'] = function
------------------------------------------------------------------------
paramedit['slow number'] = function(widget, paramname)
	local typedef = paramtype[paramname]
	
	imgui.Text(paramname)
	imgui.SameLine()
	
	imgui.PushItemWidth(96)
		local changed, newvalue = imgui.InputFloat
			{
			'##' .. paramname,
			data[paramname],
			typedef.step,
			1,
			1,
			data[paramname]
			}
	imgui.PopItemWidth()
	if changed then
		if newvalue < typedef.minimum then
			newvalue = typedef.minimum
		elseif newvalue > typedef.maximum then
			newvalue = typedef.maximum
		end
		widget[paramname] = newvalue
	end
	
end -- paramedit['slow number'] = function
------------------------------------------------------------------------
paramedit['color'] = function(widget, paramname)
	
end
------------------------------------------------------------------------
paramedit['color gradient'] = function(widget, paramname)

end
------------------------------------------------------------------------
paramedit['format table'] = function(widget, paramname)

end
------------------------------------------------------------------------
local widgets =
	{
	['text'] =
		{
		parameters = {'widget name', 'display text', 'text color', 'same line', 'text color gradient', 'text gradient index', 'text gradient range', --[['font scale',]]},
		display = function(self)
			if not display(self) then return end
			-- evaluategradient(self, 'text color', 'text color gradient', 'text gradient index', 'text gradient range',)
			if self['text color'] then
				imgui.TextColored(unpack(self['text color']), self['display text'])
			else
				imgui.Text(self['display text'])
			end -- if self['text color']
		end, -- display = function(self)
		}, -- ['text'] = {
	
	['labeled value'] =
		{
		parameters = {'widget name', 'text color', 'same line', 'display text', 'label text', 'text color gradient', 'text gradient index', 'text gradient range',},
		display = function(self)
			if not display(self) then return end
			
			if self['label text'] then
				imgui.BeginGroup()
					imgui.Text('|\n|')
				imgui.EndGroup()
				
				imgui.BeginGroup()
					imgui.Text(self['label text'])
			end
			
			if self['text color'] then
				imgui.TextColored
					{unpack(self['text color']), self['display text']}
			else
				imgui.Text(self['display text'])
			end -- if self['text color']
			
			if self['label text'] then
				imgui.EndGroup()
				
				imgui.BeginGroup()
					imgui.Text('|\n|')
				imgui.EndGroup()
			end
			
		end, -- display = function(self)
		}, -- ['labeled value'] = {
	
	['progress bar'] =
		{
		
		parameters =
			{
			'widget name',
			'overlay text',
			'text color',
			'text color gradient',
			'same line',
			'progress color gradient',
			'progress index',
			'progress range',
			'widget color',
			'widget width',
			'widget height',
			'scale progress bar',
			},
		
		display = function(self)
			
			if not display(self) then return end
			evaluategradient
				{
				self,
				'widget color',
				'progress color gradient',
				'progress index',
				'progress range',
				}
			
			imgui.PushStyleColor
				{
				'PlotHistogram',
				unpack
					(
					self['widget color'] or
					paramtype['widget color'].default()
					)
				}
			if self['text color'] then
				imgui.PushStyleColor('Text', unpack(self['text color']))
			end
			
			local progress
			if self['scale progress bar'] then
				progress = self['progress index'] / self['progress range']
			else
				progress = 1
			end
			
			imgui.ProgressBar
				{
				progress,
				self['widget width'] or -1,
				self['widget height'] or -1,
				self['overlay text'] or '',
				}
			
			if self['text color'] then imgui.PopStyleColor() end
			imgui.PopStyleColor()
			
		end, -- display = function(self)
		}, -- ['progress bar'] = {
	
	-- ['formatted table'] =
		-- {
		
		-- },
	
	} -- local widgets = {
------------------------------------------------------------------------
widget.combolist = utility.buildcombolist(widgets)
------------------------------------------------------------------------
widget.new = function(typename, fieldlist)
	
	local newwidget = {}
	setmetatable(newwidget, {__index = widgets[typename]})
	
	-- if fieldlist then
		-- newwidget.fieldcombolist = utility.buildcombobox(fieldlist)
	-- end
	newwidget.fieldcombolist = fieldlist
	newwidget.map = {}
	
	for _, param in ipairs(newwidget.parameters) do
		local typedef = paramtype[param]
		if not typedef.optional then
			if type(typedef.default) == 'function' then
				newwidget[param] = typedef.default()
			else
				newwidget[param] = typedef.default
			end -- if type(typedef.default) == 'function'
			
			if not typedef.staticsource then
				if fieldlist then
					newwidget.map[param] = fieldlist[1]
				else
					newwidget.map[param] = datasource[typedef.datatype].combolist[1]
				end
			end
		end -- if not typedef.optional
	end -- for _, param in ipairs(newwidget.parameters)
	
	return newwidget
	
end -- widget.new = function(typename)
------------------------------------------------------------------------
local addwidgettype = function(newwidgetname, newwidgetdef)
	widgets[newwidgetname] = newwidgetdef
	widget.combolist = utility.buildcombolist(widgets)
end
------------------------------------------------------------------------
widget.setdatasource = function(newdatasource)
	datasource = newdatasource
end
------------------------------------------------------------------------
widget.setscreenresolution(width, height)
	for _, typedef in pairs(paramtype) do
		-- if 
	end
end
------------------------------------------------------------------------
return widget