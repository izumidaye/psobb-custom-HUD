local utility = require('custom hud.utility')
local paramtype = require('custom hud.paramtype')
local paramedit = require('custom hud.paramedit')
local default = require('custom hud.default')

local datasource = {}
local widget = {}
------------------------------------------------------------------------
local function evaluategradient(gradient, value)
	local barvalue = value[1] / value[2]
	for index = #gradient, 1, -1 do -- change gradient data structure to be highest level -> lowest level (instead of the other way around, as it is now) so i can use 'for _, colorlevel in ipairs(gradient) do ... end'
		if barvalue >= gradient[index][1] then
			return gradient[index][2]
		end
	end -- for index = #self[gradientparam], 1, -1
end -- local function evaluategradient(self)
------------------------------------------------------------------------
local function display(self, fieldlist)
	if self.gradient then
		for _, gradientname in ipairs(self.gradient) do
			evaluategradient(self, gradientname)
		end
	end
	
	if self['same line'] then imgui.SameLine() end
	
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
local widgets = {}
------------------------------------------------------------------------
widgets['text'] =
	{
	-- widgettype = 'text',
	parameters =
		{
		['all'] = {'display text', 'text color', 'same line',--[[ 'font scale',]]},
		['hidden'] = {'long name', 'short name',},
		}, -- parameters = {...}
	
	display = function(self, fieldlist)
		display(self, fieldlist)
		if self['text color'] then
			imgui.TextColored(unpack(self['text color']), self['display text'])
		else
			imgui.Text(self['display text'])
		end -- if self['text color']
	end, -- display = function
	} -- widgets['text'] = {...}
------------------------------------------------------------------------
--[[widgets['color change text'] =
	{
	-- widgettype = 'color change text',
	parameters =
		{
		'color',
		['all'] = {'display value', 'show range', 'same line',--[[ 'font scale',]]},
		['color'] = {'text gradient',},
		['hidden'] ={'long name', 'short name',},
		}, -- parameters = {...}
	
	display = function(self, fieldlist)
		-- if not display(self, fieldlist) then return end
		display(self, fieldlist)
		evaluategradient
			{self, 'text color', 'text gradient', 'display value',}
		imgui.TextColored(unpack(self['text color']), self['display number'])
	end, -- display = function
	} -- widgets['color change text'] = {...}]]
------------------------------------------------------------------------
--[[widgets['labeled value'] =
	{
	-- widgettype = 'labeled value',
	parameters =
		{
		['all'] = {'display text', 'label text', 'same line', 'text color',}
		-- 'text gradient',
		}, -- parameters = {...}
		
	display = function(self)
		-- if not display(self) then return end
		display(self, fieldlist)
		
		if self['label text'] then
			imgui.BeginGroup()
				imgui.Text('|\n|')
			imgui.EndGroup()
			
			imgui.BeginGroup()
				imgui.Text(self['label text'])
		end -- if self['label text']
		
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
		end -- if self['label text']
		
	end, -- display = function(self)
	} -- widgets['labeled value'] = {...}]]
------------------------------------------------------------------------
widgets['progress bar'] =
	{
	-- widgettype = 'progress bar',
	parameters =
		{
		'layout', 'bar color', 'text color',
		['all'] = {'bar value', 'show value', 'show range', 'overlay text',
			'scale progress bar',},
		['layout'] = {'same line', 'widget width', 'widget height',},
		['bar color'] = {'dynamic bar color', 'bar color', 'bar gradient',}
		['text color'] =
			{'dynamic text color', 'text color', 'text gradient',},
		}, -- parameters = {...}
	
	gradient = {'bar', 'text',},
	
	display = function(self)
		
		-- if not display(self) then return end
		display(self, fieldlist)
		if self['dynamic bar color'] then
			evaluategradient
				{self, 'bar color', 'bar gradient', 'bar value',}
		end
		if self['dynamic text color'] then
			evaluategradient
				{self, 'text color', 'text gradient', 'bar value',}
		end
		
		imgui.PushStyleColor
			{'PlotHistogram', unpack
				{self['bar color'] or paramtype['bar color'].default()}
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
	} -- widgets['progress bar'] = {...}
------------------------------------------------------------------------
widgets['widget list'] =
	{
	-- widgettype = 'widget list',
	parameters =
		{
		'widget list',
		'font scale',
		}, -- parameters = {...}
	
	display = function(self)
		for _, childwidget in ipairs(self['widget list']) do
			childwidget:display()
		end
	end, -- display = function
	} -- widgets['widget list'] = {...}
------------------------------------------------------------------------
widgets['window'] =
	{
	widgettype = 'window',
	hidden = true,
	
	parameters = {
		['general'] =
			{
			'window title',
			'enable window',
			},
		['layout'] =
			{
			'position and size',
			'auto resize',
			'move with mouse',
			'resize with mouse',
			},
		['hide window when:'] =
			{
			'not in field',
			'in lobby',
			'any menu is open',
			'lower screen menu is open',
			'main menu is open',
			'full screen menu is open',
			},
		['style'] =
			{
			'font scale',
			'text color',
			'background color',
			'show titlebar',
			'show scrollbar',
			},
	}, -- parameters = {...}
	
	display = function(self)
	
	end,
	}
------------------------------------------------------------------------
--[[widgets['formatted table'] = {
	widgettype = 'text',
	parameters =
		{
		
		},
	
	display = function(self)
	
	end,
	} -- widgets['formatted table'] = {...}]]
------------------------------------------------------------------------
widget.combolist = utility.tablecombolist(widgets)
------------------------------------------------------------------------
local function edit(self)
	if self.parameters['all'] then
		for _, param in ipairs(self.parameters['all']) do
			local typedef = paramtype[param]
			paramedit[typedef.datatype](self, param)
		end
	end -- if self.parameters['all']
end -- local function edit
------------------------------------------------------------------------
local function serialize(self)
	return utility.serialize(self, excludekeys = {'parameters' = true})
	-- local result
	-- for key, value in pairs(self) do
		-- if not (key == 'parameters' or type(value) == 'function') then
			-- if type(value) == 'table' then
				-- result[key] = serialize(value)
			-- result[key] = value
		-- end
	-- end -- for key, value in pairs(self)
	-- return result
end -- local function serialize
------------------------------------------------------------------------
widget.new = function(typename, fieldcombolist)
	
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
				end -- if fieldcombolist
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
