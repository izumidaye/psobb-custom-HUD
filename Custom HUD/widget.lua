
-- local defaulttextcolor = {.8, .8, .8, 1},
local widget = {}
-- local prototype = {}
local paramtype =
	{
--[[
what makes up an argtype?

* data type
* optional or not
* source of data: static, function, or table field
* category: data, style, or layout
* default value
]]
	
	['widget name']
	
	['format table'] =
		{
		datatype = 'format table',
		staticsource = true,
--		main = true,
		category = 'data',
		},
	
	['text color'] =
		{
		datatype = 'color',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {.8, .8, .8, 1} end,
		},
	
	['same line'] =
		{
		datatype = 'boolean',
		-- optional = true,
		staticsource = true,
		category = 'layout',
		default = function() return true end,
		},
	
	['display text'] =
		{
		datatype = 'string',
		staticsource = true,
		functionsource = true,
		fieldsource = true,
--		main = true,
		category = 'data',
		default = function() return 'taco cat backwards is taco cat' end,
		},
	
	['overlay text'] =
		{
		datatype = 'string',
		optional = true,
		staticsource = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = function() return 'taco cat backwards is taco cat' end,
		},
	
	['label text'] =
		{
		datatype = 'string',
		optional = true,
		staticsource = true,
		-- main = true,
		category = 'data',
		default = function() return 'taco cat backwards is taco cat' end,
		},
	
	['text color gradient'] =
		{
		datatype = 'color gradient',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {} end,
		},
	
	['text gradient index'] =
		{
		datatype = 'number',
		optional = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = function() return 1 end,
		},
	
	['text gradient range'] =
		{
		datatype = 'number',
		optional = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = function() return 2 end,
		},
	
	['progress color gradient'] =
		{
		datatype = 'color gradient',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {} end,
		},
	
	['progress index'] =
		{
		datatype = 'number',
--		main = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = function() return {} end,
		},
	
	['progress range'] =
		{
		datatype = 'number',
--		main = true,
		functionsource = true,
		fieldsource = true,
		category = 'data',
		default = function() return {} end,
		},
	
	['widget color'] =
		{
		datatype = 'color',
		optional = true,
		staticsource = true,
		category = 'style',
		default = function() return {.9, .2, .2, 1} end,
		},
	
	-- ['font scale'] =
		-- {
		-- datatype = 'number',
		-- optional = true,
		-- staticsource = true,
		-- },
	
	['scale progress bar'] =
		{
		datatype = 'boolean',
		-- optional = true,
		staticsource = true,
		category = 'style',
		default = function() return true end,
		},
	
	['widget width'] =
		{
		datatype = 'number',
		optional = true,
		staticsource = true,
		category = 'layout',
		default = function() return 48 end,
		},
	
	['widget height'] =
		{
		datatype = 'number',
		optional = true,
		staticsource = true,
		category = 'layout',
		default = function() return 24 end,
		},
	
	}

local function validateparameters(self)
	for _, parameter in ipairs(self.parameters) do
		if (not paramtype[parameter].optional) and (not self[parameter]) then
			self.ready = false
			return
		end
	end
	self.ready = true
end -- local function validateparameters(self)

local function evaluategradient(self, colorparam, gradientparam, indexparam, rangeparam,)
	
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

local function display(self)
	if self['ready'] then
		if self['same line'] then imgui.SameLine() end
		evaluategradient(self, 'text color', 'text color gradient', 'text gradient index', 'text gradient range',)
		return true
	else
		return false
	end
end -- local function display(self)

local widgets =
	{
	['text'] =
		{
		parameters = {'display text', 'text color', 'same line', 'text color gradient', 'text gradient index', 'text gradient range', --[['font scale',]]},
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
		parameters = {'text color', 'same line', 'display text', 'label text', 'text color gradient', 'text gradient index', 'text gradient range',},
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
				imgui.TextColored(unpack(self['text color']), self['display text'])
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
			}
		
		display = function(self)
			
			if not display(self) then return end
			evaluategradient
				(
				self,
				'widget color',
				'progress color gradient',
				'progress index',
				'progress range',
				)
			
			imgui.PushStyleColor
				(
				'PlotHistogram',
				unpack
					(
					self['widget color'] or
					paramtype['widget color'].default()
					)
				)
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
				(
				progress,
				self['widget width'] or -1,
				self['widget height'] or -1,
				self['overlay text'] or '',
				)
			
			if self['text color'] then imgui.PopStyleColor() end
			imgui.PopStyleColor()
			
		end, -- display = function(self)
		}, -- ['progress bar'] = {
	
	['formatted table'] =
		{
		
		},
	
	} -- local widgets = {

widget.new = function(typename)
	
	local newwidget = {}
	setmetatable(newwidget, {__index = widgets[typename]})
	
	for _, param in ipairs(newwidget.parameters) do
		if not paramtype[param].optional then
			newwidget[param] = paramtype[param].default()
		end
	end
	
	return newwidget
	
end -- widget.new = function(typename)

local addwidgettype = function(newwidgetname, newwidgetdef)
	widgets[newwidgetname] = newwidgetdef
end

return widget