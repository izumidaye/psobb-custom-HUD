local utility = require('custom hud.utility')
local paramtype = require('custom hud.paramtype')
local paramedit = require('custom hud.paramedit')

local datasource = {}
local widget = {}
------------------------------------------------------------------------
local function evaluategradient(self, colorparam, gradientparam, progressparam)
	
	if self[gradientparam] then
		self[colorparam] = self[gradientparam][utility.binarysearch
			{self[progressparam][1] / self[progressparam][2],
			function(index) return self[gradientparam][index][1] end}][2]
		-- local progress = self[progressparam][1] / self[progressparam][2]
		-- for _, colorlevel in ipairs(self[gradientparam]) do
			-- if progress >= colorlevel[1] then
				-- self[colorparam] = colorlevel[2]
			-- else
				-- return
			-- end
		-- end -- for _, colorlevel in ipairs(self['color gradient'])
	end -- if self['color gradient']
	
end -- local function evaluategradient(self)
------------------------------------------------------------------------
local function display(self, fieldlist)
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
widgets['text'] = {
	-- widgettype = 'text',
	parameters = {
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
widgets['color change text'] = {
	-- widgettype = 'color change text',
	parameters =
		{
		['all'] = {'display value', 'show range', 'same line',--[[ 'font scale',]]},
		['color'] = {'text color gradient',},
		['hidden'] ={'long name', 'short name',},
		}, -- parameters = {...}
	
	display = function(self, fieldlist)
		-- if not display(self, fieldlist) then return end
		display(self, fieldlist)
		evaluategradient
			{self, 'text color', 'text color gradient', 'display value',}
		imgui.TextColored(unpack(self['text color']), self['display number'])
	end, -- display = function
	} -- widgets['text'] = {...}
------------------------------------------------------------------------
widgets['labeled value'] = {
	-- widgettype = 'labeled value',
	parameters = {
		'text color',
		'same line',
		'display text',
		'label text',
		'text color gradient',
		'text gradient index',
		'text gradient range',
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
	} -- widgets['labeled value'] = {...}
------------------------------------------------------------------------
widgets['progress bar'] = {
	-- widgettype = 'progress bar',
	parameters =
		{
		'overlay text',
		'text color',
		-- 'text color gradient',
		'same line',
		'bar color gradient',
		'bar progress',
		'bar color',
		'widget width',
		'widget height',
		'scale progress bar',
		}, -- parameters = {...}
	
	display = function(self)
		
		-- if not display(self) then return end
		display(self, fieldlist)
		evaluategradient
			{
			self,
			'bar color',
			'bar color gradient',
			'bar progress',
			}
		
		imgui.PushStyleColor
			{
			'PlotHistogram',
			unpack
				{
				self['bar color'] or
				paramtype['bar color'].default()
				}
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
widgets['widget list'] = {
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
widgets['window'] = {
	widgettype = 'window',
	hidden = true,
	
	parameters = {
		['general'] = {'window title', 'enable window',},
		['layout'] = {
			'position and size',
			'auto resize',
			'move with mouse',
			'resize with mouse',
			},
		['hide window when:'] = {
			'not in field',
			'in lobby',
			'any menu is open',
			'lower screen menu is open',
			'main menu is open',
			'full screen menu is open',
			},
		['style'] = {
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
	for _, param in ipairs(self.parameters) do
		local typedef = paramtype[param]
		if not typedef.hidden then
			paramedit[typedef.datatype](self, param)
		end
	end
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
