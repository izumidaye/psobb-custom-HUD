local utility = require('custom hud.utility')
local updatewindowoption = utility.updatewindowoption
local paramtype = require('custom hud.paramtype')
local typedef = paramtype.typedef
local datatype = paramtype.datatype
local paramedit = require('custom hud.paramedit')
local default = require('custom hud.default')
local id = require('custom hud.id')

local datasource = {}
local globaloptions
local widget = {}
local gamewindowwidth, gamewindowheight
local boundary
--------------------------------------------------------------------------------
local function evaluategradient(gradient, value)
	local barvalue = value[1] / value[2]
	for index = #gradient, 1, -1 do -- change gradient data structure to be highest level -> lowest level (instead of the other way around, as it is now) so i can use 'for _, colorlevel in ipairs(gradient) do ... end'
		if barvalue >= gradient[index][1] then return gradient[index][2] end
	end -- for index = #self[gradientparam], 1, -1
end
--------------------------------------------------------------------------------
local function display(self, fieldlist)
	if self['same line'] then imgui.SameLine() end
	
	if self.fieldcombolist and fieldlist then
		for param, field in pairs(self.map) do self[param] = fieldlist[field] end
	elseif self.map then
		for param, datafunction in pairs(self.map) do
			self[param] = sourcedata.get[datafunction]()
		end
	end -- if self.fieldcombolist and fieldlist
end -- local function display(self)
--------------------------------------------------------------------------------
local widgets = {}
--------------------------------------------------------------------------------
widgets['text'] =
	{
	parameters =
		{'all', ['all'] = {'display text', 'text color', 'same line',},},
	
	display = function(self, fieldlist)
		display(self, fieldlist)
		if self['text color'] then
			imgui.TextColored(unpack(self['text color']), self['display text'])
		else imgui.Text(self['display text'])
		end -- if self['text color']
	end, -- display = function
	} -- widgets['text'] = {...}
--------------------------------------------------------------------------------
--[[widgets['color change text'] =
	{
	parameters =
		{
		'general', 'color',
		['general'] = {'display value', 'show range', 'same line',--[[ 'font scale',]]},
		['color'] = {'text gradient',},
		-- ['hidden'] ={'long name', 'short name',},
		}, -- parameters = {...}
	
	display = function(self, fieldlist)
		-- if not display(self, fieldlist) then return end
		display(self, fieldlist)
		self['text color'] =
			evaluategradient(self['text gradient'], self['display value'])
		local text
		if self['show range'] then
			text = self['display value'][1] .. '/' .. self['display value'][2]
		else text = self['display value'][1]
		end
		imgui.TextColored(unpack(self['text color']), text)
	end, -- display = function
	} -- widgets['color change text'] = {...}]]
--------------------------------------------------------------------------------
--[[widgets['labeled value'] =
	{
	parameters =
		{
		['all'] = {'display text', 'label text', 'same line', 'text color',}
		-- 'text gradient',
		}, -- parameters = {...}
		
	display = function(self, fieldlist)
		display(self, fieldlist)
		
		if self['label text'] then
			imgui.BeginGroup()
				imgui.Text('|\n|')
			imgui.EndGroup()
			
			imgui.BeginGroup()
				imgui.Text(self['label text'])
		end -- if self['label text']
		
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
		end -- if self['label text']
		
	end, -- display = function(self)
	} -- widgets['labeled value'] = {...}]]
--------------------------------------------------------------------------------
widgets['progress bar'] =
	{
	parameters =
		{
		'general', 'layout', 'bar color', 'text color',
		['general'] = {'bar value', 'show value', 'show range', 'overlay text',
			'scale progress bar',},
		['layout'] = {'same line', 'widget width', 'widget height',},
		['bar color'] = {'dynamic bar color', 'bar color', 'bar gradient',}
		['text color'] = {'dynamic text color', 'text color', 'text gradient',},
		}, -- parameters = {...}
	
	display = function(self)
		display(self, fieldlist)
		if self['dynamic bar color'] then self['bar color'] =
				evaluategradient(self['bar gradient'], self['bar value'])
		end
		if self['dynamic text color'] then self['text color'] =
				evaluategradient(self['text gradient'], self['bar value'])
		end
		if self['bar color'] then
			imgui.PushStyleColor('PlotHistogram', unpack(self['bar color']))
		end
		if self['text color'] then
			imgui.PushStyleColor('Text', unpack(self['text color']))
		end
		
		local progress
		if self['scale progress bar'] then
			progress = self['bar value'][1] / self['bar value'][2]
		else progress = 1
		end
		
		local text
		if self['show value'] then
			if self['show range'] then
				text = self['bar value'][1] .. '/' .. self['bar value'][2]
			else text = self['bar value'][1]
			end
		elseif self['overlay text'] then text = self['overlay text']
		else text = ''
		end
		
		imgui.ProgressBar
			{
			progress,
			self['widget width'],
			self['widget height'],
			self['overlay text'],
			}
		
		if self['text color'] then imgui.PopStyleColor() end
		if self['bar color'] then imgui.PopStyleColor() end
		
	end, -- display = function(self)
	} -- widgets['progress bar'] = {...}
--------------------------------------------------------------------------------
--[[widgets['widget list'] =
	{
	-- widgettype = 'widget list',
	parameters =
		{
		['general'] = {'widget list', 'font scale',},
		}, -- parameters = {...}
	
	display = function(self)
		for _, childwidget in ipairs(self['widget list']) do
			childwidget:display()
		end
	end, -- display = function
	} -- widgets['widget list'] = {...}]]
--------------------------------------------------------------------------------
widgets['window'] =
	{
	-- widgettype = 'window',
	hidden = true,
	
	parameters =
		{
		'general', 'layout', 'hide window when:', 'style',
		['general'] = {'window title', 'enable window',},
		['layout'] = {'position and size', 'auto resize', 'move with mouse',
			'resize with mouse',},
		['hide window when:'] = {'not in field', 'in lobby',
			'any menu is open', 'lower screen menu is open',
			'main menu is open', 'full screen menu is open',},
		['style'] = {'font scale', 'text color', 'background color',
			'show titlebar', 'show scrollbar',},
		['content'] = {'widget list',},
		['hidden'] =
			{'id', 'window options', 'layout',},
		}, -- parameters = {...}
	
	init = function(self)
		self.id = id.new()
		
		updatewindowoption(self, not self['show titlebar'], 1, 'NoTitleBar')
		updatewindowoption(self, not self['resize with mouse'], 2, 'NoResize')
		updatewindowoption(self, not self['move with mouse'], 3, 'NoMove')
		updatewindowoption(self, not self['show scrollbar'], 4, 'NoScrollBar')
		updatewindowoption(self, self['auto resize'], 5, 'AlwaysAutoResize')
		
		self.layout.w = utility.scale(self['position and size'].w, gamewindowwidth)
		self.layout.h = utility.scale(self['position and size'].h, gamewindowheight)
		updatelayoutx(self)
		updatelayouty(self)
		
		self.dontserialize['id'] = true
		self.dontserialize['window options'] = true
		self.dontserialize['layout'] = true
	end
	
	menustate = {},
--------------------------------------------------------------------------------
	updatelayoutx = function(self)
		self.layout.x = utility.scale(self['position and size'].x, gamewindowwidth, self['position and size'].w)
	end,
--------------------------------------------------------------------------------
	updatelayouty = function(self)
		self.layout.y = utility.scale(self['position and size'].y, gamewindowheight, self['position and size'].h)
	end,
--------------------------------------------------------------------------------
	detectmouseresize = function(self)
		if self['window options'][2] ~= 'NoResize' then
			local neww, newh = imgui.GetWindowSize()
			if neww ~= self['layout'].w then
				self['position and size'].w = utility.unscale(neww, gamewindowwidth)
				self['layout'].w = neww
				self:updatelayoutx()
			end
			if newh ~= self['layout'] then
				self['position and size'].h = utility.unscale(newh, gamewindowheight)
				self['layout'].h = newh
				self:updatelayouty()
			end
		end
	end,
--------------------------------------------------------------------------------
	detectmousemove = function(self)
		if self['window options'][3] ~= 'NoMove' then
			local newx, newy = imgui.GetWindowPos()
			if newx ~= self['layout'].x then
				self['position and size'].x = utility.bindnumber(
					utility.unscale(newx, gamewindowwidth, self['position and size'].w),
					boundary.left, boundary.right - self['position and size'].w)
				self:updatelayoutx()
			end -- if newx ~= self['layout'].x
			if newy ~= self['layout'].y then
				self['position and size'].y = utility.bindnumber(
					utility.unscale(newy, gamewindowheight, self['position and size'].h),
					boundary.top, boundary.bottom - self['position and size'].h)
				self:updatelayouty()
			end -- if newy ~= self['layout'].y
		end -- if self['window options'][3] ~= 'NoMove'
	end,
--------------------------------------------------------------------------------
	display = function(self)
		if (self['in lobby'] and datasource.get(currentlocation) == 'lobby')
		or (self['not in field'] and datasource.get(currentlocation) ~= 'field')
		or (not self['enable window'])
		--[[or datasource.currentlocation() == 'login']]
		then return end
		for menu, _ in pairs(self.menustate) do
			if datasource.get(menu) then return end
		end
		
		if self['window option changed'] and datasource.screenwidth then
			imgui.SetNextWindowPos(
				self['layout'].x, self['layout'].y, 'Always')
			
			if self['window options'][5] ~= 'AlwaysAutoResize' then
				imgui.SetNextWindowSize(
					self['layout'].w, self['layout'].h, 'Always')
			end
			self['window option changed'] = false
		end
		
		local success
		success, self['enable window'] = imgui.Begin(self['window title']
			.. '###' .. self['id'], true, self['window options'])
			if not success then
				imgui.End()
				return
			end
			
			self:detectmouseresize()
			self:detectmousemove()
			
			local bgcolor = self['background color']
				or globaloptions['background color']
			if bgcolor then
				imgui.PushStyleColor('WindowBg', unpack(bgcolor)) end
			
			imgui.SetWindowfontScale(self['font scale'] or globaloptions.fontscale)
			
			for _, item in ipairs(self['widget list']) do
				item:display()
			end
			
			if bgcolor then imgui.PopStyleColor() end
		imgui.End()
	end,
	}
--------------------------------------------------------------------------------
--[[widgets['formatted table'] = {
	widgettype = 'text',
	parameters =
		{
		
		},
	
	display = function(self)
	
	end,
	} -- widgets['formatted table'] = {...}]]
--------------------------------------------------------------------------------
widget.combolist = utility.tablecombolist(widgets)
--------------------------------------------------------------------------------
local function editparamgroup(self, group, label)
	for _, param in ipairs(self.parameters[group]) do
		if imgui.TreeNode(label or group) then
			paramedit(self, param) imgui.TreePop()
		end
	end
end
--------------------------------------------------------------------------------
local function edit(self)
	if self.parameters['all'] then editparamgroup(self, 'all', self['long name'])
	end -- if self.parameters['all']
	for _, group in ipairs(self.parameters) do
		if group ~= 'all' then editparamgroup(self, group) end
	end
end -- local function edit
--------------------------------------------------------------------------------
widget.new = function(typename, fieldcombolist)
	
	local newwidget = {}
	setmetatable(newwidget, {__index = widgets[typename]})
	
	newwidget.widgettype = typename
	
	newwidget.edit = edit
	
	if newwidget.dontserialize then
		local extra = newwidget.dontserialize
		newwidget.dontserialize = default('dontserialize')
		for param, _ in pairs(extra) do
			newwidget.dontserialize[param] = true
		end
	else
		newwidget.dontserialize = default('dontserialize')
	end
	
	newwidget.fieldcombolist = fieldcombolist
	newwidget.map = {}
	
	for _, param in ipairs(newwidget.parameters) do
		local thistype = typedef(param)
		if not thistype.optional then
			newwidget[param] = default(param)
			
			if not thistype.staticsource then
				if fieldcombolist then
					newwidget.map[param] = fieldcombolist[1]
				else
					newwidget.map[param] = datasource.combolist[thistype.datatype][1]
				end -- if fieldcombolist
			end
		end -- if not thistype.optional
	end -- for _, param in ipairs(newwidget.parameters)
	
	return newwidget
	
end -- widget.new = function(typename)
--------------------------------------------------------------------------------
local function addwidgettype(newwidgetname, newwidgetdef)
	widgets[newwidgetname] = newwidgetdef
	widget.combolist = utility.buildcombolist(widgets)
end
--------------------------------------------------------------------------------
function widget.init(newdatasource, newglobaloptions)
	datasource = newdatasource
	globaloptions = newglobaloptions
	boundary.left = 0 - globaloptions.allowoffscreenx
	boundary.right = 100 + globaloptions.allowoffscreenx
	boundary.top = 0 - globaloptions.allowoffscreeny
	boundary.bottom = 100 + globaloptions.allowoffscreeny
end
--------------------------------------------------------------------------------
function widget.setgamewindowsize(neww, newh)
	gamewindowwidth, gamewindowheight = neww, newh
end
--------------------------------------------------------------------------------
return widget
