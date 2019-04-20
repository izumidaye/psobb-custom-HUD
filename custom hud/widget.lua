local utility = require('custom hud.utility')
local paramtype = require('custom hud.paramtype')
local typedef = paramtype.typedef
local datatype = paramtype.datatype
local default = require('custom hud.default')
local id = require('custom hud.id')
local neondebug = require('custom hud.neondebug')
local shortname = require('custom hud.shortname')
local textconstant = require('custom hud.language_english')

local datasource = {}
local globaloptions
local widget = {}
local gamewindowwidth, gamewindowheight
local boundary
--------------------------------------------------------------------------------
local function combobox(data, key, combolist)
	local changed = false
	local newvalue
	imgui.PushItemWidth(8 + (8 * combolist.longest))
		changed, newvalue = imgui.Combo('##' .. key, combolist[data[key]], combolist, #combolist)
	imgui.PopItemWidth()
	if changed then data[key] = combolist[newvalue] end
	return changed
end
--------------------------------------------------------------------------------
local function optionalparamtoggle(self, param, label)
	local enabled
	local changed = false
	if self[param] == nil  then
		if imgui.Button(textconstant('enable ') .. textconstant(label)) then
			changed, enabled = true, true
		end
	else
		imgui.SameLine()
		if imgui.Button(textconstant('disable ') .. textconstant(label)) then
			changed, enabled = true, false
		end
	end
	return changed, enabled
end
--------------------------------------------------------------------------------
local function fieldsourcechooser(self, param, fieldlist)
	local changed = false
	imgui.SameLine()
	if self.map[param] then
		changed = combobox(self.map, param, fieldlist)
	elseif imgui.Button('use list field##' .. param) then
		changed = true
		self.map[param] = fieldlist[1]
	end
	return changed
end
--------------------------------------------------------------------------------
local function functionsourcechooser(self, param, datatype)
	local changed = false
	imgui.SameLine()
	if self.map[param] then
		changed = combobox(self.map, param, datasource.combolist[datatype])
	elseif imgui.Button('use game data##' .. param) then
		changed = true
		self.map[param] = datasource.combolist[datatype][1]
	end
	return changed
end
--------------------------------------------------------------------------------
local function updatewindowoption(self, newvalue, optionindex, flag)
	if newvalue then
		self['window options'][optionindex] = flag
	else
		self['window options'][optionindex] = ''
	end
end
--------------------------------------------------------------------------------
local function updatename(self, param)
	local newname = self.map[param] or self[param]
	self.longname = self.widgettype .. ': ' .. newname
	self.shortname = shortname[newname] or newname
end -- local function updatename
--------------------------------------------------------------------------------
local colorlabels = {'r', 'g', 'b', 'a'}
local function editcolor(self, param, label)
	imgui.Text(textconstant(label))
	
	imgui.PushItemWidth(globaloptions.fontscale * 40)
		for i = 1, 4 do
			imgui.SameLine()
			local changed, newvalue = imgui.DragFloat(
				'##' .. param .. colorlabels[i], self[param][i] * 255, 1, 0,
				255, colorlabels[i] .. ':%.0f')
			if changed then self[param][i] = newvalue / 255 end
		end
	imgui.PopItemWidth()
	
	imgui.SameLine()
	imgui.ColorButton(unpack(self[param]))
end -- local function editcolor
--------------------------------------------------------------------------------
local function editboolean(self, param, label)
	local changed, newvalue = imgui.Checkbox(label, self[param])
	if changed then self[param] = newvalue end
end
--------------------------------------------------------------------------------
local function editstring(self, param, label)
	local changed = false
	local newvalue
	imgui.Text(label)
	imgui.SameLine()
	imgui.PushItemWidth(globaloptions.textinputwidth)
		changed, newvalue =
			imgui.InputText('##' .. param, self[param], 72)
	imgui.PopItemWidth()
	if changed then self[param] = newvalue end
	return changed
end
--------------------------------------------------------------------------------
local function editgradient(self, param, label)

end
--------------------------------------------------------------------------------
local editparam =
	{
	fontscale = function(self)
		if self.fontscale then
			imgui.Text(textconstant'font scale')
			imgui.SameLine()
			imgui.PushItemWidth(globaloptions.fontscale * 96)
				local changed, newvalue = imgui.InputFloat('##fontscale',
					self.fontscale, .1, 1, 1, '%.1f')
			imgui.PopItemWidth()
			if changed then
				if newvalue < .5 then newvalue = .5
				elseif newvalue > 5 then newvalue = 5
				end
				self.fontscale = newvalue
			end
		end
		local changed, enabled = optionalparamtoggle(self, 'fontscale', 'font scale')
		if changed then
			if enabled then self.fontscale = 1
			else self.fontscale = nil
			end
		end
	end, -- fontscale = function
	
	textcolor = function(self)
		if self.textcolor then editcolor(self, 'textcolor', 'text color') end
		local changed, enabled = optionalparamtoggle(self, 'textcolor', 'text color')
		if changed then
			if enabled then self.textcolor = {.8, .8, .8, 1}
			else self.textcolor = nil
			end
		end
	end,
	
	bgcolor = function(self)
		if self.bgcolor then editcolor(self, 'bgcolor', 'background color') end
		local changed, enabled = optionalparamtoggle(self, 'bgcolor', 'background color')
		if changed then
			if enabled then self.bgcolor = {.1, .1, .1, .5}
			else self.bgcolor = nil
			end
		end
	end,
	
	sameline = function(self)
		editboolean(self, 'sameline', textconstant'same line')
	end,
	
	textgradient = function(self)
		editboolean(self, 'dynamictextcolor', textconstant'dynamic text color')
		if self.dynamictextcolor then
			editgradient(self, 'textgradient', textconstant'text gradient')
		else
			self.editparam.textcolor(self)
		end
	end,
	}
--------------------------------------------------------------------------------
local function evaluategradient(gradient, value)
	local barvalue = value[1] / value[2]
	for index = #gradient, 1, -1 do -- change gradient data structure to be highest level -> lowest level (instead of the other way around, as it is now) so i can use 'for _, colorlevel in ipairs(gradient) do ... end'
		if barvalue >= gradient[index][1] then return gradient[index][2] end
	end -- for index = #self[gradientparam], 1, -1
end
--------------------------------------------------------------------------------
local function display(self, fieldlist)
	if self.sameline then imgui.SameLine() end
	
	if self.fieldcombolist and fieldlist then
		for param, field in pairs(self.map) do self[param] = fieldlist[field] end
	elseif self.map then
		for param, datafunction in pairs(self.map) do
			self[param] = datasource.get[datafunction]()
		end
	end -- if self.fieldcombolist and fieldlist
end -- local function display(self)
--------------------------------------------------------------------------------
local widgets = {}
--------------------------------------------------------------------------------
widgets['text'] =
	{
	parameters =
		{['all'] = {'displaytext', 'textcolor', 'sameline',},},
	
	displaytext = '',
	
	init = function(self)
		updatename(self, 'displaytext')
	end,
	
	editparam =
		{
		displaytext = function(self)
			local changed
			if not self.map.displaytext then
				changed = changed
					or editstring(self, 'displaytext', textconstant'display text')
			end
			if self.fieldcombolist then
				changed = changed
					or fieldsourcechooser(self, 'displaytext', self.fieldcombolist)
			else
				changed = changed
					or functionsourcechooser(self, 'displaytext', 'string')
			end
			if changed then
				updatename(self, 'displaytext')
			end
		end
		},
	
	display = function(self, fieldlist)
		display(self, fieldlist)
		
		if self.textcolor then
			imgui.PushStyleColor('text', unpack(self.textcolor))
		end
		
		imgui.Text(self['displaytext'])
		
		if self.textcolor then imgui.PopStyleColor() end
	end, -- display = function
	} -- widgets['text'] = {...}
setmetatable(widgets['text'].editparam, {__index = editparam})
--------------------------------------------------------------------------------
--[[widgets['color change text'] =
	{
	parameters =
		{
		'general', 'color',
		['general'] = {'display value', 'show range', 'same line',},
		['color'] = {'text gradient',},
		-- ['hidden'] ={'long name', 'short name',},
		}, -- parameters = {...}
	
	display = function(self, fieldlist)
		-- if not display(self, fieldlist) then return end
		display(self, fieldlist)
		self.textcolor =
			evaluategradient(self['text gradient'], self['display value'])
		local text
		if self['show range'] then
			text = self['display value'][1] .. '/' .. self['display value'][2]
		else text = self['display value'][1]
		end
		imgui.TextColored(unpack(self.textcolor), text)
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
		
		if self.textcolor then
			imgui.TextColored(unpack(self.textcolor), self['display text'])
		else
			imgui.Text(self['display text'])
		end -- if self.textcolor
		
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
		['general'] = {'barvalue', 'showvalue', 'showrange', 'overlaytext',
			'scalebar',},
		['layout'] = {'sameline', 'size'},
		['bar color'] = {'bargradient'},
		['text color'] = {'textgradient'},
		}, -- parameters = {...}
	
	w = -1,
	h = -1,
	showvalue = true,
	showrange = true,
	overlaytext = '',
	
	init = function(self)
		self.map = {barvalue = 'player hp'}
		updatename(self, 'barvalue')
	end,
	
	editparam =
		{
		barvalue = function(self)
			if self.fieldcombolist then
				fieldsourcechooser(self, 'barvalue', self.fieldcombolist)
			else
				functionsourcechooser(self, 'barvalue', 'progress')
			end
		end,
		
		showvalue = function(self) editboolean(self, 'showvalue', 'show value') end,
		
		showrange = function(self)
			if self.showvalue then editboolean(self, 'showrange', 'show range') end
		end,
		
		overlaytext = function(self)
			if not self.showvalue then
				editstring(self, 'overlaytext', 'overlay text')
			end
		end,
		
		scalebar = function(self)
			editboolean(self, 'scalebar', 'scale progress bar')
		end,
		
		barcolor = function(self)
			if self.barcolor then editcolor(self, 'barcolor', 'bar color') end
			local changed, enabled = optionalparamtoggle(self, 'barcolor', 'bar color')
			if changed then
				if enabled then self.barcolor = {0, .9, .3, 1}
				else self.barcolor = nil
				end
			end
		end,
		
		bargradient = function(self)
			editboolean(self, 'dynamicbarcolor', 'dynamic bar color')
			if self.dynamicbarcolor then
				editgradient(self, 'bargradient', 'bar gradient')
			else
				self.editparam.barcolor(self)
			end
		end,
		
		size = function(self)
		
		end,
		},
	
	display = function(self)
		neondebug.log('begin progress bar.display...', 'add new widget to window')
		display(self, fieldlist)
		if self['dynamic bar color'] then self.barcolor =
				evaluategradient(self['bar gradient'], self.barvalue)
		end
		if self['dynamic text color'] then self.textcolor =
				evaluategradient(self['text gradient'], self.barvalue)
		end
		if self.barcolor then
			imgui.PushStyleColor('PlotHistogram', unpack(self.barcolor))
		end
		if self.textcolor then
			imgui.PushStyleColor('Text', unpack(self.textcolor))
		end
		
		local progress
		if self.scalebar then
			progress = self.barvalue[1] / self.barvalue[2]
			if progress ~= progress then progress = 0 end
		else progress = 1
		end
		
		local text
		if self.showvalue then
			if self.showrange then
				text = self.barvalue[1] .. '/' .. self.barvalue[2]
			else text = self.barvalue[1]
			end
		else text = self.overlaytext or ''
		end
		
		-- neondebug.log('progress bar: progress: ' .. progress .. ' width: ' .. self['widget width'] .. ' height: ' .. self['widget height'] .. ' text: ' .. text, 'add new widget to window')
		imgui.ProgressBar(progress, self.w, self.h, text)
		
		if self.textcolor then imgui.PopStyleColor() end
		if self.barcolor then imgui.PopStyleColor() end
		
		neondebug.log('end progress bar.display.', 'add new widget to window')
	end, -- display = function(self)
	} -- widgets['progress bar'] = {...}
setmetatable(widgets['progress bar'].editparam, {__index = editparam})
--------------------------------------------------------------------------------
widgets['widget list'] =
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
	} -- widgets['widget list'] = {...}
--------------------------------------------------------------------------------
widget.combolist = utility.tablecombolist(widgets)
--------------------------------------------------------------------------------
widgets['window'] =
	{
	hidden = true,
	
	parameters =
		{
		'general', 'layout', 'hide window when:', 'style',
		['general'] = {'title', 'enable'},
		['layout'] = {'layoutoptions'},
		['hide window when:'] = {'hideoptions'},
		['style'] = {'fontscale', 'textcolor', 'bgcolor', 'showtitlebar',
			'showscrollbar'},
		}, -- parameters = {...}
	
	title = 'moo',
	enable = 'true',
	autoresize = true,
	allowmousemove = true,
	hideoptions = {inlobby=true},
	showtitlebar = true,
	showscrollbar = true,
	w = 10,
	h = 10,
	hideoptions = {},
	['window option changed'] = true,
	
	editparam =
		{
		title = function(self)
			editstring(self, 'title', textconstant'window title')
		end,
		
		enable = function(self)
			editboolean(self, 'enable', textconstant'enable window')
		end,
		
		showtitlebar = function(self)
			editboolean(self, 'showtitlebar', textconstant'show titlebar')
		end,
		
		showscrollbar = function(self)
			editboolean(self, 'showscrollbar', textconstant'show scrollbar')
		end,
		
		layoutoptions = function(self)
			--edit position and size
			
			local changed, newvalue
			
			changed, newvalue =
				imgui.Checkbox(textconstant'auto resize window to fit contents', self.autoresize)
			if changed then
				self.autoresize = newvalue
				updatewindowoption(self, self.autoresize, 5, 'AlwaysAutoResize')
			end
			
			changed, newvalue =
				imgui.Checkbox(textconstant'move window with mouse', self.allowmousemove)
			if changed then
				self.allowmousemove = newvalue
				updatewindowoption(self, not self.allowmousemove, 3, 'nomove')
			end
			
			if not self.autoresize then
				changed, newvalue =
					imgui.Checkbox(textconstant'resize window with mouse', self.allowmouseresize)
				if changed then
					self.allowmouseresize = newvalue
					updatewindowoption(self, not self.allowmouseresize, 2, 'noresize')
				end
			end
		end, -- layoutoptions = function
		
		hideoptions = function(self)
			editboolean(self.hideoptions, 'notinfield', textconstant'not in field')
			
			if not self.hideoptions.notinfield then
				editboolean(self.hideoptions, 'inlobby', textconstant'in lobby')
			end
			
			editboolean(self.hideoptions, 'anymenu', textconstant'any menu is open')
			
			if not self.hideoptions.anymenu then
				editboolean(self.hideoptions, 'lowermenu', textconstant'lower screen menu is open')
				
				if not self.hideoptions.lowermenu then
					editboolean(self.hideoptions, 'mainmenu', textconstant'main menu is open')
					editboolean(self.hideoptions, 'fullmenu', textconstant'full screen menu is open')
				end
			end
		end, -- hideoptions = function
		},
	
	firsttimeinit = function(self)
		-- still need to actually initialize widget list (i think? this might be it)
		self['widget list'] = default('widget list')
		
		self:init()
	end, -- init = function(self)
	
	additemlist = widget.combolist,
	
	listitem = function(self, id, active)
		-- neondebug.log('begin widget list.listitem', 'add new widget to window')
		local clicked = false
		
		if active then
			-- neondebug.log('showing active-style button', 'add new widget to window')
			imgui.PushStyleColor('Button', .2, .5, 1, 1)
			imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
			imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
			clicked = imgui.Button(self.shortname .. '##' .. id)
			imgui.PopStyleColor()
			imgui.PopStyleColor()
			imgui.PopStyleColor()
		else
			-- neondebug.log('showing regular-style button', 'add new widget to window')
			imgui.PushStyleColor('Button', .5, .5, .5, .3)
			clicked = imgui.Button(self.shortname .. '##' .. id)
			imgui.PopStyleColor()
		end -- if active
		-- neondebug.log('successfully displayed button.', 'add new widget to window')
		
		if imgui.IsItemHovered() and (not imgui.IsMouseDown(0)) then
			-- neondebug.log('showing tooltip', 'add new widget to window')
			imgui.SetTooltip(self.longname)
		end
		
		-- neondebug.log('end widget list.listitem', 'add new widget to window')
		return clicked
	end, -- listitem = function
	
	init = function(self)
		neondebug.log('init window: initializing widget list', 'new window')
		self['widget list'].changed = true
		for _, item in ipairs(self['widget list']) do
			widget.restore(item)
		end
		
		neondebug.log('init window: generating window id', 'new window')
		self.id = id.new()
		self.x = self.id * 5
		self.y = self.id * 5
		
		neondebug.log('init window: initializing window options', 'new window')
		self['window options'] = {}
		updatewindowoption(self, not self.showtitlebar, 1, 'NoTitleBar')
		updatewindowoption(self, not self.allowmouseresize, 2, 'NoResize')
		updatewindowoption(self, not self.allowmousemove, 3, 'NoMove')
		updatewindowoption(self, not self.showscrollbar, 4, 'NoScrollBar')
		updatewindowoption(self, self.autoresize, 5, 'AlwaysAutoResize')
		
		neondebug.log('init window: initializing layout', 'new window')
		self.layout = {}
		self.layout.w = utility.scale(self.w, gamewindowwidth)
		self.layout.h = utility.scale(self.h, gamewindowheight)
		self:updatelayoutx()
		self:updatelayouty()
		
		neondebug.log('init window: adding to dontserialize', 'new window')
		self.dontserialize['id'] = true
		self.dontserialize['window options'] = true
		self.dontserialize['layout'] = true
		self.dontserialize['show options'] = true
		
		neondebug.log('init window: setting up edit function', 'new window')
		local basicedit = self.edit
		self.edit = function(self)
			if self['show options'] then
				if imgui.Button('edit window contents' .. '##' .. self.id) then
					self['show options'] = false
				end
				imgui.Separator()
				basicedit(self)
			else
				if imgui.Button('edit window options' .. '##' .. self.id) then
					self['show options'] = true
				end
				imgui.Separator()
				editlist(self, 'widget list')
			end -- if self['show options']
		end -- self.edit = function(self)
	end, -- restore = function(self)
--------------------------------------------------------------------------------
	updatelayoutx = function(self)
		self.layout.x = utility.scale(self.x, gamewindowwidth, self.w)
	end,
--------------------------------------------------------------------------------
	updatelayouty = function(self)
		self.layout.y = utility.scale(self.y, gamewindowheight, self.h)
	end,
--------------------------------------------------------------------------------
	detectmouseresize = function(self)
		if self['window options'][2] ~= 'NoResize'
		and self['window options'][5] ~= 'AlwaysAutoResize' then
			-- neondebug.alwayslog('updating window size', 'add new widget to window')
			local neww, newh = imgui.GetWindowSize()
			if neww ~= self.layout.w then
				self.w = utility.unscale(neww, gamewindowwidth)
				self.layout.w = neww
				self:updatelayoutx()
			end
			if newh ~= self.layout then
				self.h = utility.unscale(newh, gamewindowheight)
				self.layout.h = newh
				self:updatelayouty()
			end
		end
	end,
--------------------------------------------------------------------------------
	detectmousemove = function(self)
		if self['window options'][3] ~= 'NoMove' then
			local newx, newy = imgui.GetWindowPos()
			if newx ~= self.layout.x then
				self.x = utility.bindnumber(
					utility.unscale(newx, gamewindowwidth, self.w),
					boundary.left, boundary.right - self.w)
				self:updatelayoutx()
			end -- if newx ~= self.layout.x
			if newy ~= self.layout.y then
				self.y = utility.bindnumber(
					utility.unscale(newy, gamewindowheight, self.h),
					boundary.top, boundary.bottom - self.h)
				self:updatelayouty()
			end -- if newy ~= self.layout.y
		end -- if self['window options'][3] ~= 'NoMove'
	end,
--------------------------------------------------------------------------------
	display = function(self)
		if (self['in lobby'] and datasource.currentlocation() == 'lobby')
		or (self['not in field'] and datasource.currentlocation() ~= 'field')
		or (not self.enable)
		--[[or datasource.currentlocation() == 'login']]
		then return end
		for menu, _ in pairs(self.hideoptions) do
			if datasource.get(menu) then return end
		end
		
		if self['window option changed'] then
			imgui.SetNextWindowPos(
				self.layout.x, self.layout.y, 'Always')
			
			if self['window options'][5] ~= 'AlwaysAutoResize' then
				imgui.SetNextWindowSize(
					self.layout.w, self.layout.h, 'Always')
			end
			self['window option changed'] = false
		end
		
		local bgcolor = self['background color']
			or globaloptions['background color']
		if bgcolor then
			imgui.PushStyleColor('WindowBg', unpack(bgcolor))
			-- imgui.PushStyleColor('framebg', 1,0,0,1)
			-- neondebug.log('used custom bg color', 'add new widget to window')
		end
		
		local success
		success, self.enable = imgui.Begin(self.title .. '###' .. self.id, true,
			self['window options'])
			if not success then
				imgui.End()
				return
			end
			
			self:detectmouseresize()
			self:detectmousemove()
			
			imgui.SetWindowFontScale(self['font scale'] or globaloptions.fontscale)
			
			for _, item in ipairs(self['widget list']) do
				item:display()
			end
			
		imgui.End()
		if bgcolor then imgui.PopStyleColor() end
	end,
	} -- widgets['window'] = {...}
setmetatable(widgets.window.editparam, {__index = editparam})
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
local function editparamgroup(self, group)
	-- neondebug.log('displaying parameter group: ' .. group, 5, 'widget')
	for _, param in ipairs(self.parameters[group]) do
		-- neondebug.log('displaying editor for ' .. group .. '.' .. param, 5, 'widget')
			self.editparam[param](self)
		-- neondebug.log('displayed ' .. group .. '.' .. param, 5, 'widget')
	end
	-- neondebug.log('done displaying parameter group: ' .. group, 5, 'widget')
end
--------------------------------------------------------------------------------
local function edit(self)
	if self.parameters.all then editparamgroup(self, 'all')
	else
		imgui.NewLine()
		for _, group in ipairs(self.parameters) do
			imgui.SameLine()
			if imgui.Button(group .. '##' .. (self.longname or self.id)) then
				if self.selectedgroup == group then
					self.selectedgroup = nil
				else
					self.selectedgroup = group
				end
			end
		end -- for _, group in ipairs(self.parameters)
		if self.selectedgroup then editparamgroup(self, self.selectedgroup) end
	end -- if self.parameters.all
end -- local function edit
--------------------------------------------------------------------------------
widget.globaloptions =
	{
	parameters =
		{
		['general'] = {'taskinterval', 'offscreenspace',},
		['default values'] = {'bgcolor', 'textcolor', 'fontscale', 'defaultautoresize',},
		['parameter editing'] = {'textinputwidth', 'numberwidgettype',},
		}, -- need to add these to paramtypes
	
	edit = edit,
	
	taskinterval = 1,
	allowoffscreen = false,
	offscreenx = 0,
	offscreeny = 0,
	autoresizedefault = true,
	textinputwidth = 144,
	numberinputmethod = 'dragint',
	
	-- firsttimeinit = function(self)
		
		-- for _, param in ipairs(self.parameters) do
			-- self[param] = default(param)
		-- end
	-- end,
	
	init = function(self, savedoptions)
		if savedoptions then
			utility.listcopyinto(self, savedoptions)
		else self:firsttimeinit()
		end
	end,
	} -- widget.globaloptions = {...}
--------------------------------------------------------------------------------
function widget.restore(self)
	setmetatable(self, {__index = widgets[self.widgettype]})
	self.edit = edit
	self.dontserialize = default('dontserialize')
	if self.init then self:init() end
end
--------------------------------------------------------------------------------
widget.new = function(typename, fieldcombolist)
	neondebug.log('creating widget of type: ' .. typename, 'new window')
	
	local newwidget = {}
	setmetatable(newwidget, {__index = widgets[typename]})
	neondebug.log('new widget metatable set.', 'new window')
	
	newwidget.widgettype = typename
	newwidget.edit = edit
	newwidget.dontserialize={dontserialize=true,parameters=true,editparam=true,}
	newwidget.fieldcombolist = fieldcombolist
	newwidget.map = {}
	neondebug.log('widgettype, edit, dontserialize, fieldcombolist, and map set.', 'new window')
	
	if newwidget.firsttimeinit then
		neondebug.log('starting ' .. typename .. ' specific init.', 'new window')
		newwidget:firsttimeinit()
		neondebug.log(typename .. ' specific init complete.', 'new window')
	elseif newwidget.init then newwidget:init()
	end
	
	return newwidget
	
end -- widget.new = function(typename)
--------------------------------------------------------------------------------
local function addwidgettype(newwidgetname, newwidgetdef)
	widgets[newwidgetname] = newwidgetdef
	widget.combolist = utility.buildcombolist(widgets)
end
--------------------------------------------------------------------------------
function widget.init(newdatasource, newglobaloptions, neww, newh)
	datasource = newdatasource
	globaloptions = newglobaloptions
	boundary = {}
	boundary.left = 0 - globaloptions.allowoffscreenx
	boundary.right = 100 + globaloptions.allowoffscreenx
	boundary.top = 0 - globaloptions.allowoffscreeny
	boundary.bottom = 100 + globaloptions.allowoffscreeny
	gamewindowwidth, gamewindowheight = neww, newh
end
--------------------------------------------------------------------------------
return widget
