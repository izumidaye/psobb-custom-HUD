<<<<<<< HEAD
local utility = require('custom hud.utility')
=======
local utility = require('Custom HUD.utility')
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec

local datasource
local widget = {}
------------------------------------------------------------------------
local paramtype =
	{
--[[
what makes up a parameter type?

* data type: string, number, slow number, boolean, progress, color, list
* subtype: color level, widget
* optional or not
* source of data: static, function, or table field
* category: data, style, layout, or miscellaneous
* default value
]]
	
	['widget name'] =
<<<<<<< HEAD
=======
		{
		datatype = 'string',
		optional = true,
		staticsource = true,
		category = 'miscellaneous',
		default = function() return '' end,
		}
	
	['format table'] =
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
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
		default = true,
		},
	
	['scale progress bar'] =
		{
		datatype = 'boolean',
		staticsource = true,
		category = 'style',
		default = true,
		},
	
	['bar progress'] =
		{
		datatype = 'progress',
		fieldsource = 'true',
		functionsource = 'true',
		category = 'data',
		default = 1,
		}
	
	['text gradient index'] =
		{
		datatype = 'progress',
		optional = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = 1,
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
		datatype = 'list',
		subtype = 'color level',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {} end,
		},
	
	['progress color gradient'] =
		{
		datatype = 'list',
		subtype = 'color level',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {} end,
		},
	
	['widget list'] =
		{
		datatype = 'list',
		subtype = 'widget',
		staticsource = true,
		category = 'data',
		default = function() return {} end,
		listitem = function(self, id, active)
			local clicked = false
			local name
			if self['widget name'] then
				name = self['widget name']
			else
			if active then
				imgui.PushStyleColor('Button', .2, .5, 1, 1)
				imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
				imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
				clicked = imgui.Button(name .. '##' .. id)
				imgui.PopStyleColor()
				imgui.PopStyleColor()
				imgui.PopStyleColor()
			else
				imgui.PushStyleColor('Button', .5, .5, .5, .3)
				clicked = imgui.Button(name .. '##' .. index)
				imgui.PopStyleColor()
			end -- if list.selected == index
		end, -- listitem = function(self
		}, -- ['widget list'] = {...}
	
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
<<<<<<< HEAD
local function evaluategradient(self, colorparam, gradientparam, indexparam)
=======
local function evaluategradient(self, colorparam, gradientparam, indexparam, rangeparam,)
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
	
	if self[gradientparam] then
		for _, colorlevel in ipairs(self[gradientparam]) do
			if self[indexparam] >= colorlevel[1] then
				self[colorparam] = colorlevel[2]
			else
				return
			end
		end -- for _, colorlevel in ipairs(self['color gradient'])
	end -- if self['color gradient']
	
end -- local function evaluategradient(self)
------------------------------------------------------------------------
<<<<<<< HEAD
local function display(self, fieldlist)
=======
local function display(self)
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
	if self['ready'] then
		if self['same line'] then imgui.SameLine() end
		evaluategradient(self, 'text color', 'text color gradient', 'text gradient index', 'text gradient range')
		return true
	else
		return false
	end -- if self['ready']
	
	if self.fieldcombolist and fieldlist then
		for param, field in pairs(self.map) do
			self[param] = fieldlist[field]
		end
	elseif self.map then
		for param, datafunction in pairs(self.map) do
			self[param] = sourcedata.get[datafunction]()
		end
	end -- if self.fieldcombolist and fieldlist
end -- local function display(self)
------------------------------------------------------------------------
local function combobox(data, key, combolist)
	imgui.PushItemWidth(8 + (8 * combolist.longest))
<<<<<<< HEAD
		local changed, newvalue = imgui.Combo('##' .. key, combolist[data[key]], combolist, #combolist)
=======
		local changed, newvalue = imgui.Combo
			('##' .. key, combolist[data[key]], combolist, #combolist)
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
	imgui.PopItemWidth()
	if changed then data[key] = combolist[newvalue] end
end
------------------------------------------------------------------------
<<<<<<< HEAD
local function paramsourceeditor(self, paramname)
=======
local function paramsourceeditor(widget, paramname)
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
	
	local typedef = paramtype[paramname]
	
	if typedef.optional then
		if imgui.Button('clear##' .. paramname) then
<<<<<<< HEAD
			self[paramname] = nil
			self.map[paramname] = nil
=======
			widget[paramname] = nil
			widget.map[paramname] = nil
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
		end
		imgui.SameLine()
	end
	
<<<<<<< HEAD
	if self.fieldcombolist then
		if typedef.fieldsource then
			imgui.Text('source:')
			imgui.SameLine()
			if self.map[paramname] then
				combobox(self.map, paramname, self.fieldcombolist)
			else
				if imgui.Button('use list field##' .. paramname) then
					self.map[paramname] = self.fieldcombolist[1]
				end
			end -- if self.map[paramname]
=======
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
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
			imgui.SameLine()
		end -- if typedef.fieldsource
		
	elseif typedef.functionsource then
<<<<<<< HEAD
		if self.map[paramname] then
			combobox(self.map, paramname, datasource[typedef.datatype].combolist)
		else
			if imgui.Button('use game data##' .. paramname) then
				self.map[paramname] = datasource[typedef.datatype].combolist[1]
			end
		end -- if self.map[paramname]
		imgui.SameLine()
	end -- if self.fieldcombolist
	
	if typedef.staticsource and self.map[paramname] then
		if imgui.Button('use static value##' .. paramname) then
			self.map[paramname] = nil
			self[paramname] = typedef.default()
=======
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
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
		end
	end
	
end -- local function paramsourceeditor
------------------------------------------------------------------------
<<<<<<< HEAD
local colorlabels = {'r', 'g', 'b', 'a'}
local paramedit
paramedit =
	{
	['string'] = function(self, paramname)
		imgui.Text(paramname)
		imgui.SameLine()
		local changed, newvalue =
			imgui.InputText('##' .. paramname, self[paramname], 72)
		if changed then self[paramname] = newvalue end
		
		paramsourceeditor(self, paramname)
	end, -- ['string'] = function

	['number'] = function(self, paramname)
		local typedef = paramtype[paramname]
		local displayvalue
		if typedef.scale then
			displayvalue = utility.round(self[paramname] * typedef.scale)
			-- displayvalue = string.format
				-- {'%s', utility.round(self[paramname] * typedef.scale)}
				-- not sure if i need to convert to string
		else
			displayvalue = self[paramname]
		end -- if typedef.scale
		
		imgui.Text(paramname .. ':')
		imgui.SameLine()
		imgui.PushItemWidth(72)
			
			local changed, newvalue = imgui.DragFloat
				{
				'##' .. paramname,
				self[paramname],
				typedef.largestep,
				typedef.minimum,
				typedef.maximum,
				displayvalue
				}
			if changed then self[paramname] = newvalue end
			imgui.SameLine()
			
			changed, newvalue = imgui.DragFloat
				{
				'##finetune' .. paramname,
				self[paramname],
				typedef.smallstep,
				typedef.minimum,
				typedef.maximum,
				'fine tune'
				}
			if changed then self[paramname] = newvalue end
			
		imgui.PopItemWidth()
		
		paramsourceeditor(self, paramname)
	end, -- ['number'] = function

	['slow number'] = function(self, paramname)
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
			self[paramname] = newvalue
		end
		
	end, -- ['slow number'] = function

	['boolean'] = function(self, paramname)
		local changed, newvalue = imgui.Checkbox(paramname, self[paramname])
		if changed then self[paramname] = newvalue end
		
		-- paramsourceeditor(self, paramname)
		-- no reason to use game data for a boolean parameter?
	end, -- ['boolean'] = function

	['progress'] = function(self, paramname)
		imgui.Text(paramname)
		imgui.SameLine()
		
		paramsourceeditor(self, paramname)
	end, -- ['progress'] = function

	['color'] = function(self, paramname)
		imgui.Text(paramname)
		
		imgui.PushItemWidth(40)
			for i = 1, 4 do
				imgui.SameLine()
				local changed, newvalue = imgui.DragFloat
					{
					'##' .. paramname .. colorlabels[i],
					self[paramname][i] * 255,
					1,
					0,
					255,
					colorlabels[i] .. ':%.0f'
					}
				if changed then self[paramname][i] = newvalue / 255 end
			end
		imgui.PopItemWidth()
		
		imgui.SameLine()
		imgui.ColorButton(unpack(self[paramname]))
	end, -- ['color'] = function
	
	['list'] = function(self, paramname)
		
	end, -- ['list'] = function
	
	['color gradient'] = function(self, paramname)
		-- paramedit['color'](self, paramname)
	end, -- ['color gradient'] = function
	
	['format table'] = function(self, paramname)
	
	end, -- ['format table'] = function
	} -- local paramedit = {...}
=======
local paramedit = {}
------------------------------------------------------------------------
paramedit['string'] = function(widget, paramname)
	imgui.Text(paramname)
	imgui.SameLine()
	local changed, newvalue = imgui.InputText
end
------------------------------------------------------------------------
paramedit['boolean'] = function(widget, paramname)

end
------------------------------------------------------------------------
paramedit['number'] = function(widget, paramname)

end
------------------------------------------------------------------------
paramedit['color'] = function(widget, paramname)

end
------------------------------------------------------------------------
paramedit['color gradient'] = function(widget, paramname)

end
------------------------------------------------------------------------
paramedit['format table'] = function(widget, paramname)

end
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
------------------------------------------------------------------------
local widgets =
	{
	['text'] =
		{
<<<<<<< HEAD
		parameters = {'widget name', 'display text', 'text color', 'same line', 'text color gradient', 'text gradient index', --[['font scale',]]},
		display = function(self, fieldlist)
			if not display(self, fieldlist) then return end
			-- evaluategradient(self, 'text color', 'text color gradient', 'text gradient index')
=======
		parameters = {'widget name', 'display text', 'text color', 'same line', 'text color gradient', 'text gradient index', 'text gradient range', --[['font scale',]]},
		display = function(self)
			if not display(self) then return end
			-- evaluategradient(self, 'text color', 'text color gradient', 'text gradient index', 'text gradient range',)
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
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
			'bar progress',
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
				'bar progress',
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
				progress = self['bar progress']
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
	
<<<<<<< HEAD
	['widget list'] =
		{
		parameters =
			{
			'widget list',
			},
		
		display = function(self)
			
		end,
		}, -- ['widget list'] = {...}
	
	-- ['formatted table'] =
		-- {
		
		-- }, -- ['formatted table'] = {...}
	
	} -- local widgets = {
------------------------------------------------------------------------
widget.combolist = utility.tablecombolist(widgets)
------------------------------------------------------------------------
local function edit(self)
	for _, param in ipairs(self.parameters) do
		paramedit[paramtype[param].datatype](self, param)
	end
end -- local function edit
------------------------------------------------------------------------
widget.new = function(typename, fieldcombolist)
=======
	-- ['formatted table'] =
		-- {
		
		-- },
	
	} -- local widgets = {
------------------------------------------------------------------------
widget.new = function(typename, fieldlist)
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
	
	local newwidget = {}
	setmetatable(newwidget, {__index = widgets[typename]})
	newwidget.edit = edit
	
	newwidget.fieldcombolist = fieldcombolist
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
				if fieldcombolist then
					newwidget.map[param] = fieldcombolist[1]
				else
					newwidget.map[param] = datasource.combolist[typedef.datatype][1]
				end
			end
		end -- if not typedef.optional
	end -- for _, param in ipairs(newwidget.parameters)
	
	-- if fieldlist then
		-- newwidget.fieldcombolist = utility.buildcombobox(fieldlist)
	-- end
	newwidget.fieldcombolist = fieldlist
	newwidget.map = {}
	
	return newwidget
	
end -- widget.new = function(typename)
------------------------------------------------------------------------
<<<<<<< HEAD
=======
widget.combolist = utility.buildcombolist(widgets)
------------------------------------------------------------------------
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
local addwidgettype = function(newwidgetname, newwidgetdef)
	widgets[newwidgetname] = newwidgetdef
	widget.combolist = utility.buildcombolist(widgets)
end
------------------------------------------------------------------------
<<<<<<< HEAD
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
=======
local function setdatasource(newdatasource)
	datasource = newdatasource
end
------------------------------------------------------------------------
>>>>>>> 9c04c7cd01a29cdf0f43029f2280da6d32f1e0ec
return widget