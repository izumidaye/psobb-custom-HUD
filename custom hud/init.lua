--[[
PSOBB Dynamic Info Addon
Catherine S (IzumiDaye/NeonLuna)
2018-10-05
]]
--------------------------------------------------------------------------------
local core_mainmenu, neondebug, psodata, utility, shortname do
	core_mainmenu = require 'core_mainmenu'
	neondebug = require 'custom hud.neondebug'
	psodata = require 'custom hud.psodata'
	utility = require 'custom hud.utility'
	shortname = require 'custom hud.shortname'
	 -- = require 'custom hud.language_english'
end
--------------------------------------------------------------------------------
do -- enable debugging on specific areas of code
	-- neondebug.enablelogging('general')
	-- neondebug.enablelogging('init.lua')
	-- neondebug.enablelogging('new window')
	-- neondebug.enablelogging('presentwindowlist')
	-- neondebug.enablelogging('widget')
	-- neondebug.enablelogging('save serialize')
	-- neondebug.enablelogging('paramedit')
	-- neondebug.enablelogging('add new widget to window')
	-- neondebug.enablelogging'window options'
end
--------------------------------------------------------------------------------
local lasttime, huddata, ready, statusheight, status, freedids, takenids, tasks, gamewindowwidth, gamewindowheight, boundary do
	lasttime = os.time()
	huddata = {}
	status = ''
	freedids = {}
	takenids = {}
	tasks = {}
	boundary = {}
end
--------------------------------------------------------------------------------
local function newid()
	local genid
	if #freedids > 0 then genid = table.remove(freedids, 1)
	else genid = #takenids + 1
	end
	takenids[genid] = true
	return genid
end -- local function newid ----------------------------------------------------
local function freeid(idtofree)
	table.insert(freedids, idtofree)
	takenids[idtofree] = nil
end -- local function freeid ---------------------------------------------------
local function evaluategradient(gradient, value)
	local barvalue = value[1] / value[2]
	for index = #gradient, 1, -1 do -- change gradient data structure to be highest level -> lowest level (instead of the other way around, as it is now) so i can use 'for _, colorlevel in ipairs(gradient) do ... end'
		if barvalue >= gradient[index][1] then return gradient[index][2] end
	end -- for index = #self[gradientparam], 1, -1
end -- local function evaluategradient -----------------------------------------
local function updatexboundary()
	boundary.left = 0 - huddata.offscreenx
	boundary.right = 100 + huddata.offscreenx
end -- local function updatexboundary ------------------------------------------
local function updateyboundary()
	boundary.top = 0 - huddata.offscreeny
	boundary.bottom = 100 + huddata.offscreeny
end -- local function updateyboundary ------------------------------------------
--------------------------------------------------------------------------------
local function stringeditor(param, label)
	return function(data)
		local changed = false
		local newvalue
		imgui.Text(label)
		imgui.SameLine()
		imgui.PushItemWidth(huddata.inputtextwidth)
			changed, newvalue = imgui.InputText('##' .. param, data[param], 72)
		imgui.PopItemWidth()
		if changed then data[param] = newvalue end
		return changed
	end -- return function
end -- local function editstring -----------------------------------------------
local function numbereditor(param, label, min, max, step)
	return function(data)
		imgui.Text(label .. ':')
		imgui.SameLine()
		imgui.PushItemWidth(72)
		local changed, newvalue = imgui.DragFloat('##' .. param, data[param], step, min, max, data[param])
		-- label, value, step, min, max, displayvalue (aka format)
		if changed then data[param] = newvalue end
		imgui.SameLine()
		changed, newvalue = imgui.DragFloat('##finetune' .. param, data[param], step / 10, min, max, step / 10 .. 'x')
		if changed then data[param] = newvalue end
		imgui.SameLine()
		changed, newvalue = imgui.DragFloat('##quick' .. param, data[param], step * 10, min, max, step * 10 .. 'x')
		if changed then data[param] = newvalue end
		imgui.PopItemWidth()
	end -- return function
end -- local function numbereditor -----------------------------------------------
local function slownumbereditor(param, label, min, max, step)
	return function(data)
		imgui.Text(label)
		imgui.SameLine()
		imgui.PushItemWidth(96)
			local changed, newvalue = imgui.InputFloat('##' .. param, data[param], step, 1, 1, data[param])
		imgui.PopItemWidth()
		if changed then data[param] = utility.bindnumber(newvalue, min, max) end
	end
end -- local function editslownumber -------------------------------------------
local function booleaneditor(param, label, callback)
	return function(data)
		local changed, newvalue = imgui.Checkbox(label, data[param])
		if changed then
			data[param] = newvalue
			if callback then callback() end
		end
		return changed
	end -- return function
end -- local function booleaneditor ----------------------------------------------
local colorlabels = {'r', 'g', 'b', 'a'}
local function coloreditor(param, label)
	return function(data)
		imgui.Text(label)
		imgui.PushItemWidth(40)
			for i = 1, 4 do
				imgui.SameLine()
				local changed, newvalue = imgui.DragFloat('##' .. param .. i,
					data[param][i] * 255, 1, 0, 255, colorlabels[i] .. ':%.0f')
				if changed then data[param][i] = newvalue / 255 end
			end
		imgui.PopItemWidth()
		imgui.SameLine()
		imgui.ColorButton(unpack(data[param]))
	end -- return function
end -- local function coloreditor
local function editgradient(self, param, label)

end -- local function editgradient ---------------------------------------------
local function flageditor(param, label, flag, index, invert)
	return function(data)
		local changed, newvalue = imgui.Checkbox(label, data[param])
		if changed then
			data[param] = newvalue
			if invert then newvalue = not newvalue end
			if newvalue then
				data['window options'][index] = flag
			else
				data['window options'][index] = ''
			end
		end -- if changed
		return changed
	end -- return function
end -- local function flageditor -------------------------------------------------
local function optionalparametereditor(arg)--(param, editlabel, resetlabel, editfunction, defaultvalue)
	local param = arg.param
	local editlabel = arg.editlabel
	local resetlabel = arg.resetlabel
	local editfunction = arg.editfunction
	local defaultvalue = arg.defaultvalue
	return function(data)
		if data[param] then
			editfunction(data)
			imgui.SameLine()
			if imgui.Button(resetlabel .. '##' .. param) then data[param] = nil end
		else
			if imgui.Button(editlabel) then data[param] = defaultvalue() end
		end
	end -- return function
end -- local function editoptionalparameter
local function setactivebuttonstyle()
	imgui.PushStyleColor('Button', .2, .5, 1, 1)
	imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
	imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
end -- local function setactivebuttonstyle
local function button(param, label)
	return function(data)
		if data[param] then setactivebuttonstyle() end
		local newvalue
		newvalue = imgui.Button(label)
		if data[param] then imgui.PopStyleColor(3) end
		if newvalue then data[param] = not data[param] end
	end -- return function
end -- local function listbutton
local function togglebutton(label, callback, isactive)
	return function()
		local active = isactive()
		if active then setactivebuttonstyle() end
		
		if imgui.Button(label) then callback() end
		
		if active then imgui.PopStyleColor(3) end
	end -- return function
end -- local function togglebutton
local function simpletogglebutton(param, label)
	return function(data)
		local active = data[param]
		if active then
			imgui.PushStyleColor('Button', .2, .5, 1, 1)
			imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
			imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
		end
		
		if imgui.Button(label) then data[param] = not data[param] end
		
		if active then imgui.PopStyleColor(3) end
	end -- return function
end -- local function togglebutton ---------------------------------------------
local function radiolist(param, label, list)
	return function(data)
		local changed = false
		local clicked, newvalue
		imgui.Text(label .. ':')
		for _, option in ipairs(list) do
			clicked, newvalue = imgui.RadioButton(option[2], data[param] == option[1])
			if clicked then data[param] = option[1] end
			changed = changed or clicked
		end -- for _, option in ipairs(list)
		return changed
	end -- return function
end -- local function radiolist
--------------------------------------------------------------------------------
local function combobox(param, combolist)
	return function(data)
		local changed = false
		local newvalue
		imgui.PushItemWidth(8 + (8 * combolist.longest))
			changed, newvalue = imgui.Combo('##' .. param, combolist[data[param]],
				combolist, #combolist)
		imgui.PopItemWidth()
		if changed then data[param] = combolist[newvalue] end
		return changed
	end -- return function
end -- local function combobox -------------------------------------------------
local function text(textdata, color)
	color = color or huddata.defaulttextcolor
	imgui.TextColored(color[1], color[2], color[3], color[4], textdata)
end -- local function text -----------------------------------------------------
--------------------------------------------------------------------------------
local widgets = {}
local function restorewidget(self, parent)
	setmetatable(self, {__index = widgets[self.widgettype]})
	self.parent = parent
	self.dontserialize = {['dontserialize'] = true, ['parameters'] = true,} -- remove ['parameters'] = true after checking that 'parameters' has been removed from all widgets
	if self.init then self:init() end
end -- local function restorewidget --------------------------------------------
local function newwidget(typename, parent)
	neondebug.log('creating widget of type: ' .. typename, 'new window')
	
	local thisnewwidget = {}
	setmetatable(thisnewwidget, {__index = widgets[typename]})
	neondebug.log('new widget metatable set.', 'new window')
	
	thisnewwidget.widgettype = typename
	thisnewwidget.parent = parent
	thisnewwidget.dontserialize={dontserialize=true,parameters=true,editparam=true,}
	neondebug.log('widgettype and dontserialize set.', 'new window')
	
	if thisnewwidget.firsttimeinit then
		neondebug.log('starting ' .. typename .. ' specific init.', 'new window')
		thisnewwidget:firsttimeinit()
		neondebug.log(typename .. ' specific init complete.', 'new window')
	else thisnewwidget:init()
	end
	
	return thisnewwidget
end -- local function newwidget ------------------------------------------------
local basewidget = {
	updatename = function(self, namevalue)
		self.longname = self.widgettype .. ': ' .. namevalue
		self.shortname = shortname[namevalue] or namevalue
		if self.callbacks then
			print'calling callbacks'
			for _, callback in ipairs(self.callbacks) do callback() end
		else print'no callbacks'
		end -- if self.callbacks
	end, -- updatename = function
	initlabel = function(self)
		self:updatename(self.datasource)
		if self.labeltype == 'none' then self.label = nil
		else self.label = self.shortname
		end -- if self.labeltype == 'none'
	end, -- initlabel = function
	labeleditor = function(self)
		local changed, newvalue
		text 'label:'
		for _, option in ipairs{'none', 'automatic', 'custom'} do
			changed, newvalue = imgui.RadioButton(option, self.labeltype == option)
			if changed then
				self.labeltype = option
				self:initlabel()
			end -- if changed
		end -- for _, option in ipairs(self.labeloptions)
		if self.labeltype == 'custom' then
			imgui.SameLine()
			changed, newvalue = imgui.InputText('##' .. self.id, self.label, 72)
			if changed then
				self.label = newvalue
				self:updatename(self.label)
			end
		end -- if self.labeltype == 'custom'
	end, -- labeleditor = function
	button = function(self, label, selected, tooltip)
		local clicked
		if selected then
			setactivebuttonstyle()
		else
			imgui.PushStyleColor('Button', .5, .5, .5, .3)
		end
		
		if imgui.Button(label)
		and not imgui.IsMouseDragging(0, huddata.dragthreshold)
		then clicked = true
		else clicked = false
		end
		
		if selected then imgui.PopStyleColor(2) end
		imgui.PopStyleColor()
		
		if tooltip and imgui.IsItemHovered() and not imgui.IsMouseDown(0) then
			-- print(utility.serialize(self))
			imgui.SetTooltip(tooltip)
		end
		return clicked
	end, -- button = function
	textcoloreditor = optionalparametereditor{
		param = 'textcolor',
		editlabel = 'custom text color',
		resetlabel = 'use default',
		editfunction = coloreditor('textcolor', 'text color'),
		defaultvalue = function() return huddata.defaulttextcolor end
	}, -- textcoloreditor = optionalparametereditor
	bgcoloreditor = optionalparametereditor{
		param = 'bgcolor',
		editlabel = 'custom background color',
		resetlabel = 'use default',
		editfunction = coloreditor('bgcolor', 'background color'),
		defaultvalue = function() return huddata.defaultbgcolor end
	}, -- bgcoloreditor = optionalparametereditor
	fontscaleeditor = optionalparametereditor{
		param = 'fontscale',
		editlabel = 'custom font scale',
		resetlabel = 'use default',
		editfunction = numbereditor('fontscale', 'font scale', 1, 6, .1),
		defaultvalue = function() return 1 end
	},
	togglesameline = booleaneditor('sameline', 'same line'),
	init = function(self)
		self.id = newid()
	end, -- init = function
} -- basewidget = {...}
basewidget.__index = basewidget
widgets.text = {
	labeltype = 'none',
	datasource = psodata.combolist.string[1],
	-- labeleditor = labeleditor('datasource'),
	-- labeltypeeditor = radiolist('labeltype', 'label', {{'none', 'none'}, {'automatic', 'automatic'}, {'custom', 'custom'}}),
	sourceeditor = combobox('datasource', psodata.combolist.string),
	init = function(self)
		basewidget.init(self)
		self:updatename(self.datasource)
	end,
	edit = function(self)
		self:labeleditor()
		-- if self:labeltypeeditor() then self:initname() end
		-- if self.labeltype == 'custom' then
			-- imgui.SameLine()
			-- if self:customlabeleditor() then self:updatename(self.label) end
		-- end
		
		imgui.Text 'value:' imgui.SameLine()
		if self:sourceeditor() then
			self:updatename(self.datasource)
			if self.labeltype == 'automatic' then self.label = self.shortname end
		end
		
		self:textcoloreditor()
		self:togglesameline()
	end, -- edit = function
	display = function(self)
		if self.sameline then imgui.SameLine() end
		if self.textcolor then imgui.PushStyleColor('text', unpack(self.textcolor)) end
			if self.label then imgui.Text(self.label) imgui.SameLine() end
			imgui.Text(psodata.get[self.datasource]())
		if self.textcolor then imgui.PopStyleColor() end
	end, -- display = function
} -- widgets['text'] = {...}
setmetatable(widgets.text, basewidget)
widgets['progress bar'] = {
	parameters =
		{
		'general', 'layout', 'bar color', 'text color',
		['general'] = {'barvalue', 'showvalue', 'showrange', 'overlaytext', 'scalebar',},
		['layout'] = {'sameline', 'size'},
		['bar color'] = {'bargradient'},
		['text color'] = {'textgradient'},
		},
	w = -1,
	h = -1,
	datasource = psodata.combolist.progress[1],
	showvalue = true,
	showrange = true,
	overlaytext = '',
	init = function(self)
		basewidget.init(self)
		self:updatename('datasource')
	end, -- init = function
	sourceeditor = combobox('datasource', psodata.combolist.progress),
	toggleshowvalue = booleaneditor('showvalue', 'show value'),
	toggleshowrange = booleaneditor('showrange', 'show range'),
	togglescalebar = booleaneditor('scalebar', 'scale progress bar'),
	toggledynamicbarcolor = booleaneditor('dynamicbarcolor', 'dynamic bar color'),
	edit = function(self)
		if self:sourceeditor() then self:updatename('datasource') end
		self:toggleshowvalue()
		if self.showvalue then self:toggleshowrange() end
		self:togglescalebar()
	end, -- edit = function
	editparam = {
		overlaytext = function(self)
			if not self.showvalue then
				editstring(self, 'overlaytext', 'overlay text')
			end
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
		}, -- editparam = {...}
	display = function(self)
		neondebug.log('begin progress bar.display...', 'add new widget to window')
		local data = psodata.get[self.datasource]()
		local barvalue = data[1] / data[2]
		if self.sameline then imgui.SameLine() end
		if self['dynamic bar color'] then self.barcolor =
				evaluategradient(self['bar gradient'], barvalue)
		end
		if self['dynamic text color'] then self.textcolor =
				evaluategradient(self['text gradient'], barvalue)
		end
		if self.barcolor then
			imgui.PushStyleColor('PlotHistogram', unpack(self.barcolor))
		end
		if self.textcolor then
			imgui.PushStyleColor('Text', unpack(self.textcolor))
		end
		
		local progress
		if self.scalebar then
			progress = barvalue
			if progress ~= progress then progress = 0 end
		else progress = 1
		end
		
		local text
		if self.showvalue then
			if self.showrange then
				text = data[1] .. '/' .. data[2]
			else text = data[1]
			end
		else text = self.overlaytext or ''
		end
		
		imgui.ProgressBar(progress, self.w, self.h, text)
		
		if self.textcolor then imgui.PopStyleColor() end
		if self.barcolor then imgui.PopStyleColor() end
		
		neondebug.log('end progress bar.display.', 'add new widget to window')
	end, -- display = function(self)
	} -- widgets['progress bar'] = {...}
setmetatable(widgets['progress bar'], basewidget)
widgets['item list'] = {
	parameters = {},
	
	processdrop = function(self)
	
	end,
	
	listitem = function(self, index)
	
	end,
	
	editparam = {},
	
	init = function(self)
	
	end,
	} -- widgets['item list'] = {...}
local widgetcombolist = utility.tablecombolist(widgets)
widgets.gradient = {
	
} -- widgets.gradient = {...}
widgets.window = {
	hidden = true,
	menutypes = {'anymenu', 'mainmenu', 'lowermenu', 'fullmenu'},
	
	showoptions = true,
	title = 'moo',
	enable = 'true',
	autoresize = true,
	allowmousemove = true,
	inlobby=true,
	showtitlebar = true,
	showscrollbar = true,
	w = 10,
	h = 10,
	['window option changed'] = true,
	titleeditor = stringeditor('title', 'window title'),
	toggletitlebar = flageditor('showtitlebar', 'show titlebar', 'NoTitleBar', 1, true),
	togglescrollbar = flageditor('showscrollbar', 'show scrollbar', 'NoScrollBar', 4, true),
	toggleautoresize = flageditor('autoresize', 'auto resize window to fit contents', 'AlwaysAutoResize', 5),
	togglemousemove = flageditor('allowmousemove', 'move window with mouse', 'NoMove', 3, true),
	togglemouseresize = flageditor('allowmouseresize', 'resize window with mouse', 'NoResize', 2, true),
	toggleenablewindow = booleaneditor('enable', 'enable window'),
	togglehidenotinfield = booleaneditor('notinfield', 'not in field'),
	togglehideinlobby = booleaneditor('inlobby', 'in lobby'),
	togglehideanymenu = booleaneditor('anymenu', 'any menu is open'),
	togglehidelowermenu = booleaneditor('lowermenu', 'lower screen menu is open'),
	togglehidemainmenu = booleaneditor('mainmenu', 'main menu is open'),
	togglehidefullmenu = booleaneditor('fullmenu', 'full screen menu is open'),
	
	editlayout = function(self)
		local dragfloatwidth = 36
		local labelsource, formatstr
		if huddata.showpixels then
			labelsource = self.layout
			formatstr = '%.0f'
		else
			labelsource = self
			formatstr = '%.2f'
		end -- if huddata.showpixels
		local step = 1
		local smallstep = .01
		local changed1, changed2
		
		imgui.PushItemWidth(dragfloatwidth)
		imgui.BeginGroup() -- edit xpos and width
			imgui.Text('x:')
			imgui.SameLine()
			-- imgui.PushItemWidth(dragfloatwidth)
			changed1, newvalue = imgui.DragFloat('##xpos' .. self.id, self.x, step, boundary.left, boundary.right, string.format(formatstr, labelsource.x))
			if changed1 then self.x = newvalue end
			imgui.SameLine()
			changed2, newvalue = imgui.DragFloat('##xfinetune' .. self.id, self.x, smallstep, boundary.left, boundary.right, '.01x')
			if changed2 then self.x = newvalue end
			if changed1 or changed2 then
				self:updatelayoutx()
				self['window option changed'] = true
			end
			
			if not self.autoresize then
				imgui.Text('w:')
				imgui.SameLine()
				-- imgui.PushItemWidth(dragfloatwidth)
				changed1, newvalue = imgui.DragFloat('##width' .. self.id, self.w, step, boundary.left, boundary.right, string.format(formatstr, labelsource.w))
				if changed1 then self.w = newvalue end
				imgui.SameLine()
				changed2, newvalue = imgui.DragFloat('##wfinetune' .. self.id, self.w, smallstep, boundary.left, boundary.right, '.01x')
				if changed2 then self.w = newvalue end
				if changed1 or changed2 then
					self:updatelayoutx()
					self:updatelayoutw()
					self['window option changed'] = true
				end -- if changed1 or changed2
			end -- if not self.autoresize
		imgui.EndGroup() -- edit xpos and width
		
		imgui.SameLine()
		
		imgui.BeginGroup() -- edit ypos and height
			imgui.Text('y:')
			imgui.SameLine()
			-- imgui.PushItemWidth(dragfloatwidth)
			changed1, newvalue = imgui.DragFloat('##ypos' .. self.id, self.y, step, boundary.left, boundary.right, string.format(formatstr, labelsource.y))
			if changed1 then self.y = newvalue end
			imgui.SameLine()
			changed2, newvalue = imgui.DragFloat('##yfinetune' .. self.id, self.y, smallstep, boundary.left, boundary.right, '.01x')
			if changed2 then self.y = newvalue end
			if changed1 or changed2 then
				self:updatelayouty()
				self['window option changed'] = true
			end
			
			if not self.autoresize then
				imgui.Text('h:')
				imgui.SameLine()
				-- imgui.PushItemWidth(dragfloatwidth)
				changed1, newvalue = imgui.DragFloat('##height' .. self.id, self.h, step, boundary.left, boundary.right, string.format(formatstr, labelsource.h))
				if changed1 then self.h = newvalue end
				imgui.SameLine()
				changed2, newvalue = imgui.DragFloat('##hfinetune' .. self.id, self.h, smallstep, boundary.left, boundary.right, '.01x')
				if changed2 then self.h = newvalue end
				if changed1 or changed2 then
					self:updatelayouty()
					self:updatelayouth()
					self['window option changed'] = true
				end -- if changed1 or changed2
			end -- if not self.autoresize
		imgui.EndGroup() -- edit ypos and height
		imgui.PopItemWidth()
	end,
	
	edit = function(self)
	-- button = function(self, label, selected, tooltip)
		if self.showoptions then
			if imgui.Button('edit window contents##' .. self.id) then
				self.showoptions = false
			end
			imgui.Separator()
			for group, _ in pairs(self.paramgroups) do
				local selected = group == self.selectedgroup
				local clicked = self:button(group, selected)
				if clicked then
					if selected then self.selectedgroup = nil
					else self.selectedgroup = group
					end
				end
				imgui.SameLine()
			end
			imgui.NewLine()
			imgui.Separator()
			if self.selectedgroup then self.paramgroups[self.selectedgroup](self) end
		else
			if imgui.Button('edit window options##' .. self.id) then
				self.showoptions = true
			end
			imgui.Separator()
			-- widgets['widget list'].edit(self['widget list'])
			self['widget list']:edit()
		end
	end, -- edit = function
	paramgroups = {
		general = function(self)
			self:titleeditor()
			self:toggleenablewindow()
		end, -- general = function
		layout = function(self)
			self:editlayout()
			self:toggletitlebar()
			self:togglescrollbar()
			if self:toggleautoresize() and not self.autoresize then self['window option changed'] = true end
			self:togglemousemove()
			if not self.autoresize then self:togglemouseresize() end
		end, -- layout = function
		['auto hide window'] = function(self)
			self:togglehidenotinfield()
			if not self.notinfield then self:togglehideinlobby() end
			self:togglehideanymenu()
			if not self.anymenu then
				self:togglehidelowermenu()
				if not self.lowermenu then
					self:togglehidemainmenu()
					self:togglehidefullmenu()
				end
			end
		end, -- ['auto hide window'] = function
		style = function(self)
			self:textcoloreditor()
			self:bgcoloreditor()
			self:fontscaleeditor()
		end, -- style = function
	},
	firsttimeinit = function(self)
		-- still need to actually initialize widget list (i think? this might be it)
		self['widget list'] = newwidget('widget list', self)
		self['window options'] = {'', 'NoResize', '', '', 'AlwaysAutoResize'}
		self:init()
	end, -- init = function(self)
	additemlist = widgetcombolist,
	init = function(self)
		neondebug.log('basewidget init', 'new window')
		basewidget.init(self)
		self.x = self.id * 5
		self.y = self.id * 5
		
		neondebug.log('init window: initializing widget list', 'new window')
		-- self['widget list'].changed = true
		restorewidget(self['widget list'])
		
		neondebug.log('init window: initializing window options', 'new window')
		-- updatewindowoption(self, not self.showtitlebar, 1, 'NoTitleBar')
		-- updatewindowoption(self, not self.allowmouseresize, 2, 'NoResize')
		-- updatewindowoption(self, not self.allowmousemove, 3, 'NoMove')
		-- updatewindowoption(self, not self.showscrollbar, 4, 'NoScrollBar')
		-- updatewindowoption(self, self.autoresize, 5, 'AlwaysAutoResize')
		
		neondebug.log('init window: initializing layout', 'new window')
		self.layout = {}
		-- self.layout.w = utility.scale(self.w, gamewindowwidth)
		-- self.layout.h = utility.scale(self.h, gamewindowheight)
		self:updatelayoutw()
		self:updatelayouth()
		self:updatelayoutx()
		self:updatelayouty()
		
		neondebug.log('init window: adding to dontserialize', 'new window')
		self.dontserialize['id'] = true
		-- self.dontserialize['window options'] = true
		self.dontserialize['layout'] = true
		self.dontserialize['show options'] = true
		
		-- neondebug.log('init window: setting up edit function', 'new window')
	end, -- restore = function(self)
	updatelayoutx = function(self)
		self.layout.x = utility.scale(self.x, gamewindowwidth, self.w)
		-- self['window option changed'] = true
	end,
	updatelayouty = function(self)
		self.layout.y = utility.scale(self.y, gamewindowheight, self.h)
		-- self['window option changed'] = true
	end,
	updatelayoutw = function(self)
		self.layout.w = utility.scale(self.w, gamewindowwidth)
		-- self['window option changed'] = true
	end,
	updatelayouth = function(self)
		self.layout.h = utility.scale(self.h, gamewindowheight)
		-- self['window option changed'] = true
	end,
	detectmouseresize = function(self)
		if self['window options'][2] ~= 'NoResize'
		and self['window options'][5] ~= 'AlwaysAutoResize' then
			-- neondebug.alwayslog('updating window size', 'add new widget to window')
			local neww, newh = imgui.GetWindowSize()
			if neww ~= self.layout.w then
				self.w = utility.unscale(neww, gamewindowwidth)
				self.layout.w = neww
				self:updatelayoutx()
			end -- if neww ~= self.layout.w
			if newh ~= self.layout.h then
				self.h = utility.unscale(newh, gamewindowheight)
				self.layout.h = newh
				self:updatelayouty()
			end -- if newh ~= self.layout.h
		end -- if self['window options'][2] ~= 'NoResize' and self['window options'][5] ~= 'AlwaysAutoResize'
	end, -- detectmouseresize = function
	detectmousemove = function(self)
		if self['window options'][3] ~= 'NoMove' then
			local newx, newy = imgui.GetWindowPos()
			local outofbounds = false
			if newx ~= self.layout.x then
				self.x = utility.bindnumber(
					utility.unscale(newx, gamewindowwidth, self.w),
					boundary.left, boundary.right)
				self:updatelayoutx()
				if newx ~= self.layout.x then outofbounds = true end
			end -- if newx ~= self.layout.x
			if newy ~= self.layout.y then
				self.y = utility.bindnumber(
					utility.unscale(newy, gamewindowheight, self.h),
					boundary.top, boundary.bottom)
				self:updatelayouty()
				if newy ~= self.layout.y then outofbounds = true end
			end -- if newy ~= self.layout.y
		if outofbounds then self['window option changed'] = true end
		end -- if self['window options'][3] ~= 'NoMove'
	end, -- detectmousemove = function
	display = function(self)
		if (self['inlobby'] and psodata.currentlocation() == 'lobby')
		or (self['notinfield'] and psodata.currentlocation() ~= 'field')
		or (not self.enable)
		--[[or psodata.currentlocation() == 'login']]
		then return end
		for menu, _ in pairs(psodata.getdata('menustate')) do
			if self[menu] then return end
		end
		
		if self['window option changed'] then
			imgui.SetNextWindowPos(self.layout.x, self.layout.y, 'Always')
			if self['window options'][5] ~= 'AlwaysAutoResize' then
				imgui.SetNextWindowSize(self.layout.w, self.layout.h, 'Always')
			end
			self['window option changed'] = false
		end
		
		local bgcolor = self.bgcolor
			-- or huddata.'background color']
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
			
			-- imgui.SetWindowFontScale(self['font scale'] or huddata.fontscale)
			
			for _, item in ipairs(self['widget list']) do
				item:display()
			end
			
		imgui.End()
		if bgcolor then imgui.PopStyleColor() end
	end,
	updatewindowoption = function(self, newvalue, optionindex, flag)
		if newvalue then
			self['window options'][optionindex] = flag
		else
			self['window options'][optionindex] = ''
		end
	end,
	} -- widgets['window'] = {...}
setmetatable(widgets.window, basewidget)
widgets['widget list'] = {
	changed = true,
	orientation = 'horizontal',
	additemlist = widgetcombolist,
	initdragtarget = function(self, width, height)
		-- self.dragtarget.top = y - huddata.dragtargetmargin
		-- self.dragtarget.bottom = y + height + huddata.dragtargetmargin
		self.dragtarget.top = - huddata.dragtargetmargin
		self.dragtarget.bottom = height + huddata.dragtargetmargin
		-- self.dragtarget.left = x - huddata.dragtargetmargin
		-- self.dragtarget.right = x + width + huddata.dragtargetmargin
		self.dragtarget.left = - huddata.dragtargetmargin
		self.dragtarget.right = width + huddata.dragtargetmargin
	end, -- initdragtarget = function
	calcdragdest = function(self, targetvalue)
		-- print('button centers: ' .. utility.serialize(self))
		local result = #self + 1
		for index = 1, #self do
			if targetvalue < self[index] then result = index break end
		end
		-- print('cursor: ' .. targetvalue .. ' | dest index: ' .. result)
		return result
	end, -- calcdragdest = function
	processdrop = function(self)
		if self.newitem then
			local newitem = newwidget(self.dragsource, self)
			newitem.callbacks = {function() self.changed = true end}
			self.selected = utility.listadd(self, newitem, self.dragdest, self.selected)
		else
			self.selected = utility.listmove(self, self.dragsource, self.dragdest, self.selected)
		end
		self.changed = true
	end, -- processdrop = function
	listitem = function(self, index)
		local selected = self.selected == index
		local item = self[index]
		if item:button(item.shortname .. '##' .. item.id, selected, self[index].longname) then
			if selected then self.selected = nil else self.selected = index end
		end
	end, -- listitem = function
	firsttimeinit = function(self)
		self.dragtarget = {}
		self.buttonedges = {5}
		self.buttoncenters = {}
		self.changed = true
		self:init()
	end, -- firsttimeinit = function
	init = function(self)
		basewidget.init(self)
		for _, item in ipairs(self) do
			restorewidget(item, self)
			item.callbacks = {function() self.changed = true end}
		end
	end, -- init = function
	edit = function(self)
		neondebug.alwayslog('begin list editor', 'add new widget to window')
		
		local dragtarget = self.dragtarget
		local lastitempos
		
		local offsetx, offsety = imgui.GetCursorScreenPos()
		
		neondebug.alwayslog('begin show item list', 'add new widget to window')
		if
			imgui.BeginChild('item list', -1,
				imgui.GetTextLineHeightWithSpacing() * 2, true)
		then
			if self.orientation == 'horizontal' then
				imgui.Dummy(0, 0)
			else
			
			end
			if self.changed then
				if self.orientation == 'horizontal' then
					lastitempos, _ = imgui.GetCursorPos() + 5
				else
				
				end
				self.itemedges = {lastitempos}
				self.itemcenters = {}
			end
			for index, item in ipairs(self) do
				if self.orientation == 'horizontal' then imgui.SameLine() end
				
				neondebug.alwayslog('showing list item ' .. index, 'add new widget to window')
				-- print('attempting to show list item: ' .. utility.serialize(self[index]))
				self:listitem(index)
				neondebug.alwayslog('successfully displayed list item', 'add new widget to window')
				
				if not self.dragsource
				and imgui.IsItemActive()
				and imgui.IsMouseDragging(0, huddata.dragthreshold)
				then
						self.dragsource = index
				end
				
				if self.changed then
					if self.orientation == 'horizontal' then
						local itemwidth
						itemwidth, _ = imgui.GetItemRectSize()
						table.insert(self.itemcenters, lastitempos + 8 + itemwidth / 2)
						lastitempos = lastitempos + itemwidth + 8
						table.insert(self.itemedges, lastitempos + 3)
					else -- assume self.orientation == 'vertical'
						-- figure this out once everything else is working
					end -- if self.orientation == 'horizontal'
				end -- if self.changed
				
			end -- for index, item in ipairs(self)
			
			if self.dragdest then
				local offset, _ = imgui.GetCursorPos()
				imgui.SameLine(self.itemedges[self.dragdest] - 7)
				imgui.Text('|')
			end
			
		end imgui.EndChild()
		
		neondebug.alwayslog('end show item list', 'add new widget to window')
		
		-- imgui.NewLine()
		-- for _, pos in ipairs(self.itemcenters) do
			-- imgui.SameLine(pos)
			-- imgui.Text('|')
		-- end
		
		-- imgui.NewLine()
		-- for _, pos in ipairs(self.itemedges) do
			-- imgui.SameLine(pos)
			-- imgui.Text('|')
		-- end
		
		if self.changed then
			self.changed = false
			if self.orientation == 'horizontal' then
				self:initdragtarget(imgui.GetItemRectSize())
			else -- assume self.orientation == 'vertical'
				-- figure this out once everything else is working
			end -- if self.orientation == 'horizontal'
			-- print(self.dragtarget.left)
			-- print(self.dragtarget.bottom)
			neondebug.log('dragtarget:\n\tleft: ' .. dragtarget.left .. '\n\tright: ' .. dragtarget.right .. '\n\ttop: ' .. dragtarget.top .. '\n\tbottom: ' .. dragtarget.bottom, 'add new widget to window')
		end -- if self.changed
		
		imgui.NewLine()
		for index, itemname in ipairs(self.additemlist) do
			imgui.SameLine()
			if imgui.Button(itemname .. '##newitem') and not self.dragactive then
				-- table.insert(self, newwidget(itemname))
				self.dragsource = itemname
				self.newitem = true
				self.dragdest = #self + 1
				-- self:processdrop()
				neondebug.log('added new widget: ' .. itemname, 'add new widget to window')
				-- self.changed = true
			elseif not self.dragsource
			and imgui.IsItemActive()
			and imgui.IsMouseDragging(0, huddata.dragthreshold)
			then
				self.dragsource = itemname
				self.newitem = true
				neondebug.log('started dragging new widget: ' .. itemname, 'add new widget to window')
			end
		end
		
		if self.dragsource then
			if imgui.IsMouseDown(0) then
				local mousex, mousey = imgui.GetMousePos()
				mousex = mousex - offsetx
				mousey = mousey - offsety
				
				if utility.iswithinrect(mousex, mousey, dragtarget) then
					if self.orientation == 'horizontal' then
						self.dragdest = self.calcdragdest(self.itemcenters, mousex)
						neondebug.log('dragdest: ' .. self.dragdest, 'add new widget to window')
					else -- assume orientation == 'vertical'
						-- figure this out once everything else is working
					end -- if self.orientation == 'horizontal'
				else
					self.dragdest = nil
				end -- if mouse position is within dragtarget
			else -- drag action ended
				if self.dragdest then
					self:processdrop()
					self.changed = true
				end
				self.newitem = nil
				self.dragactive = nil
				self.dragdest = nil
				self.dragsource = nil
			end -- if imgui.IsMouseDown(0)
		end -- if self.dragsource
		
		local deletewidget = false
		if self.selected then
			if imgui.BeginChild('list item editor', -1, -1, true) then
				if imgui.BeginPopup('confirmdeletewidget', {'NoTitleBar', 'NoResize', 'NoMove', 'NoScrollBar', 'AlwaysAutoResize'}) then
					imgui.Text('delete widget "' .. self[self.selected].longname .. '"?')
					if imgui.Button 'delete##deletewidget' then
						deletewidget = true
						imgui.CloseCurrentPopup()
					end
					imgui.SameLine()
					if imgui.Button 'cancel##deletewidget' then imgui.CloseCurrentPopup() end
				imgui.EndPopup() end
		
				if self == nil then print('self is nil') end
				
				if imgui.Button('delete widget') then
					imgui.OpenPopup('confirmdeletewidget')
				end
			
				self[self.selected]:edit()
			end imgui.EndChild()
		end -- if self.selected
		if deletewidget then
			table.remove(self, self.selected)
			self.selected = nil
		end
		
		neondebug.alwayslog('end list editor', 'add new widget to window')
	end, -- edit = function(self)
	display = function(self)
		for _, childwidget in ipairs(self['widget list']) do
			childwidget:display()
		end
	end, -- display = function
} -- widgets['widget list'] = {...}
setmetatable(widgets['widget list'], basewidget)
--------------------------------------------------------------------------------
local globaloptions = {
	slownumbereditor('longinterval', 'long interval', 1, 10, 1),
	numbereditor('offscreenx', 'allow offscreen x', 0, 50, 1),
	numbereditor('offscreeny', 'allow offscreen y', 0, 50, 1),
	numbereditor('inputtextwidth', 'width of imgui.InputText', 24, 420, 1),
	numbereditor('dragtargetmargin', 'extra space for target drag box', 0, 144, 1),
	slownumbereditor('dragthreshold', 'drag detection threshold', 2, 24, 1),
	booleaneditor('defaultautoresize', 'auto resize new windows'),
	optionalparametereditor{
		param = 'defaulttextcolor',
		editlabel = 'set default text color',
		resetlabel = 'reset',
		editfunction = coloreditor('defaulttextcolor', 'default text color'),
		defaultvalue = function() return {.8, .8, .8, 1} end,
	}, -- editdefaulttextcolor = optionalparametereditor{...}
	optionalparametereditor{
		param = 'defaultbgcolor',
		editlabel = 'set default background color',
		resetlabel = 'reset',
		editfunction = coloreditor('defaultbgcolor', 'default background color'),
		defaultvalue = function() return {.2, .2, .2, .5} end,
	}, -- editdefaultbgcolor = optionalparametereditor{...}
	basewidget.fontscaleeditor,
	booleaneditor('showpixels', 'show layout pixels', function()
		if huddata.showpixels then
			
		else
		
		end
	end)
} -- local globaloptions = {...}
local function presentglobaloptionswindow()
	imgui.SetNextWindowSize(500, 300, 'FirstUseEver')
	local success
	success, huddata['show global options window'] = imgui.Begin('global options', true)
		if not success then imgui.End() return end
		for optionname, optioneditor in pairs(globaloptions) do
			-- print('showing ' .. optionname)
			optioneditor(huddata)
		end
	imgui.End()
	-- return windowopen
end -- local function presentglobaloptionswindow -------------------------------
local mainmenuwidgets = {
	simpletogglebutton('show global options window', 'global options'),
	simpletogglebutton('show debug window', 'show debug window'),
} -- local mainmenuwidgets = {...}
local function presentmainwindow()
	neondebug.log('start presentmainwindow()', 'init.lua')
	
	imgui.SetNextWindowSize(600,300,'FirstUseEver')
	local success
	success, huddata['show main window'] = imgui.Begin('custom hud editor', true)
		if not success then
			imgui.End()
			neondebug.log('imgui.Begin() failed.', 'init.lua')
			return
		end
		
		neondebug.log('imgui.Begin() succeeded.', 'init.lua')
		
		imgui.BeginChild('window list and main menu', 150 * huddata.fontscale, -statusheight, true)
		
			for i = 1, #huddata.windowlist do
				local window = huddata.windowlist[i]
				local selected = huddata['selected window'] == i
				if window:button(window.title .. '##' .. i, selected) then
					if selected then huddata['selected window'] = nil
					else huddata['selected window'] = i
					end
				end
			end
			neondebug.log('displayed window list box', 'init.lua')
			
			imgui.Separator()
			
			if imgui.Button('add new window') then
				neondebug.log('attempting to add new window.', 'init.lua')
				table.insert(huddata.windowlist, newwidget('window'))
				neondebug.log('successfully added new window.', 'init.lua')
			end -- if imgui.Button('add new window')
			-- maybe make a pop-up dialog to enter title before adding window
			
			if imgui.BeginPopup('confirmdeletewindow', {'NoTitleBar', 'NoResize', 'NoMove', 'NoScrollBar', 'AlwaysAutoResize'}) then
				imgui.Text('delete window "' .. huddata.windowlist[huddata['selected window']].title .. '"?')
				if imgui.Button 'delete##deletewindow' then
					freeid(huddata.windowlist[huddata['selected window']].id)
					table.remove(huddata.windowlist, huddata['selected window'])
					huddata['selected window'] = nil
					imgui.CloseCurrentPopup()
				end
				imgui.SameLine()
				if imgui.Button 'cancel##deletewindow' then imgui.CloseCurrentPopup() end
				imgui.EndPopup()
			end
			
			if huddata['selected window'] and imgui.Button('delete window') then
				imgui.OpenPopup('confirmdeletewindow')
			end
			
			if imgui.Button('save') then
				utility.savetable('profile', huddata)
				status = os.date('%F | %T: profile and options saved')
				local delayfinished = os.time() + 10
				table.insert(tasks, function()
					if os.time() >= delayfinished then
						status = ''
						return true
					end
				end)
			end
			
			for _, button in ipairs(mainmenuwidgets) do button(huddata) end
			
		imgui.EndChild()
		
		imgui.SameLine()
		imgui.BeginChild('window editor', -1, -statusheight, true)
			if huddata['selected window'] then
				huddata.windowlist[huddata['selected window']]:edit()
			end -- if huddata['selected window']
		imgui.EndChild()
		
		imgui.BeginChild('status bar', -1, statusheight, true)
			imgui.Text(status)
		imgui.EndChild()
		
	imgui.End()
end -- local function presentmainwindow ----------------------------------------
local function loaddata()
	local neww, newh = psodata.getgamewindowsize()
	if neww > 0 then
		statusheight = imgui.GetTextLineHeightWithSpacing() * 2
		gamewindowwidth = neww
		gamewindowheight = newh
	
		huddata = utility.loadtable('profile')
		if huddata then
			neondebug.log('\'profile\' loaded')
			for _, window in ipairs(huddata.windowlist) do
				restorewidget(window)
			end
		else
			neondebug.log('load(\'profile\') failed')
			huddata = {longinterval = 1, offscreenx = 0, offscreeny = 0, fontscale = 1, inputtextwidth = 96, dragtargetmargin = 48, dragthreshold = 24, defaulttextcolor = {.8, .8, .8, 1}, defaultbgcolor = {0, 0, 0, .5}, defaultautoresize = true,}
			huddata.windowlist = {}
			-- huddata['show main window'] = true
			huddata['show window options'] = false
		end -- if huddata
		
		updatexboundary()
		updateyboundary()
		ready = true
		return true
	end -- if neww > 0
end -- local function loaddata--------------------------------------------------
table.insert(tasks, loaddata)
local function present()
	neondebug.log('start present()', 'init.lua')
	
	local now = os.time()
	local interval = huddata.longinterval or 1
	if #tasks > 0 and os.difftime(now, lasttime) >= interval then
		local taskindex = 1
		repeat
			if tasks[taskindex]() then
				table.remove(tasks, taskindex)
			else
				taskindex = taskindex + 1
			end
		until taskindex > #tasks
		lasttime = now
	end
	
	if not ready then return end
	
	psodata.retrievepsodata()
	neondebug.log('retrieved game data', 'init.lua')
	
	if huddata['show main window'] then
		presentmainwindow()
		neondebug.log('presented window list', 'init.lua')
	end
	if huddata['show debug window'] then
		huddata['show debug window'] = neondebug.present()
		neondebug.log('presented debug window', 'init.lua')
	end
	if huddata['show global options window'] then
		-- print 'showing global options'
		presentglobaloptionswindow()
	end
	for _, window in ipairs(huddata.windowlist) do
		neondebug.log('attempting to present window: ' .. window.title .. '...', 'init.lua')
		window:display()
		neondebug.log('...succeeded', 'init.lua')
	end
	
	neondebug.log('end present()', 'init.lua')
end -- local function present
local function init()
--	local pwd = io.popen([[dir 'addons\Custom HUD\core windows' /b]])
	-- local testDisplayList = {}
	-- for dir in pwd:lines() do
		-- testDisplayList[dir] = {command='showString', args={text=dir}}
		-- print('thing' .. dir .. ' end thing')
	-- end
	-- pwd:close()
		
	neondebug.log('starting first init process...', 'init.lua')
	
	psodata.setactive('player')
	psodata.setactive('meseta')
	psodata.setactive('monsterlist')
	psodata.setactive('xp')
	psodata.setactive('ata')
	psodata.setactive('party')
	psodata.setactive('flooritems')
	psodata.setactive('inventory')
	psodata.setactive('bank')
	psodata.setactive('sessiontime')
	neondebug.log('set up game huddata access.', 'init.lua')
	
	
	core_mainmenu.add_button('Dynamic HUD', function()
		huddata['show main window'] = not huddata['show main window']
		end)
	
	neondebug.log('first init finished.', 'init.lua')
	return
		{
		name = 'Custom HUD',
		version = '0.5',
		author = 'IzumiDaye',
		description = 'Build your own custom HUD',
		present = present,
		}
end -- local function init -----------------------------------------------------
--------------------------------------------------------------------------------
return {__addon = {init = init}}
