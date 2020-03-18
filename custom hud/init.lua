--[[
psobb dynamic info addon
catherine s (izumidaye/neonluna)
2018-10-05
color presets based on this set: https://sashat.me/2017/01/11/list-of-20-simple-distinct-colors/
]]
--------------------------------------------------------------------------------
local core_mainmenu, neondebug, psodata, utility, shortname do
	core_mainmenu = require 'core_mainmenu'
	neondebug = require 'custom hud.neondebug'
	neondebug.enablelogging('error', 5)
	neondebug.enablelogging('main', 5)
	-- neondebug.enablelogging('instantgamecrash', 1)
	-- neondebug.enablelogging('listpicker2', 5)
	-- neondebug.enablelogging('updatename', 5)
	-- neondebug.enablelogging('layoutvalues')
	psodata = require 'custom hud.psodata'
	utility = require 'custom hud.utility'
	neondebug.log('finished require statements', 'main')
	shortname = {}
	 -- = require 'custom hud.language_english'
end
--------------------------------------------------------------------------------
local lasttime, huddata, status, freedids, takenids, tasks, boundary, dragtargetmargin do
	lasttime = os.time()
	huddata = {}
	status = ''
	freedids = {}
	takenids = {}
	tasks = {}
	boundary = {}
	dragtargetmargin = 48
end
local labeleditorlabel, labeltypelabels, colorlabels, gamewindowwidth, gamewindowheight, ready, statusheight, languagetable
local writelayoutvaluesthisframe, showstyleeditorwindow
--------------------------------------------------------------------------------
local function writelayoutvalues(location)
	if writelayoutvaluesthisframe then
		local layoutfunctions = {
			'GetContentRegionAvail',
			'GetContentRegionAvailWidth',
			'GetContentRegionMax',
			'GetCursorPos',
			'GetCursorPosX',
			'GetCursorPosY',
			'GetCursorScreenPos',
			'GetCursorStartPos',
			'GetFontSize',
			'GetItemRectMax',
			'GetItemRectMin',
			'GetItemRectSize',
			'GetItemsLineHeightWithSpacing',
			'GetTextLineHeight',
			'GetTextLineHeightWithSpacing',
			'GetTreeNodeToLabelSpacing',
			'GetWindowContentRegionMax',
			'GetWindowContentRegionMin',
			'GetWindowContentRegionWidth',
			'GetWindowHeight',
			'GetWindowPos',
			'GetWindowSize',
			'GetWindowWidth',
		} -- local layoutfunctions = {...}
		local layoutvalues = {location}
		for _, funcname in ipairs(layoutfunctions) do
			table.insert(layoutvalues, 'imgui.' .. funcname .. '(): ' .. utility.serialize{imgui[funcname]()})
		end -- for _, funcname in ipairs(layoutfunctions)
		table.insert(layoutvalues, '\n')
		neondebug.alwayslog(table.concat(layoutvalues, '\n'), 'layoutvalues')
	end -- if writelayoutvaluesthisframe
end -- local function writelayoutvalues
local function logpcall(f, desc, ...)
	local results = {pcall(f, ...)}
	local success = table.remove(results, 1)
	if not success then
		local errormsg = utility.serialize({desc, results, ...})
		print(errormsg)
		neondebug.alwayslog(errormsg, 'error')
	else
		return unpack(results)
	end -- if not success
end -- local function logpcall
local function generateid()
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
local function evaluategradient(levels, barvalue)
	-- local barvalue = value[1] / value[2]
	for index, level in ipairs(levels) do
		if barvalue >= level then return index end
	end -- for index, level in ipairs(levels)
	return #levels
end -- local function evaluategradient -----------------------------------------
local function updatexboundary() -- i don't think i actually want to allow objects even partially offscreen, so i will probably remove this
	boundary.left = 0-- - huddata.offscreenx
	boundary.right = 100-- + huddata.offscreenx
end -- local function updatexboundary ------------------------------------------
local function updateyboundary() -- i don't think i actually want to allow objects even partially offscreen, so i will probably remove this
	boundary.top = 0-- - huddata.offscreeny
	boundary.bottom = 100-- + huddata.offscreeny
end -- local function updateyboundary ------------------------------------------
local function lookup(category, name)
	local result = languagetable[category] and languagetable[category][name]
	if result == nil then
		print('no translation found for [' .. tostring(category) .. ':' .. tostring(name) .. ']')
		return '???'
	else
		return result
	end -- if result == nil
end -- local function lookup
local function searchparents(key, parents)
	for _, parent in ipairs(parents) do
		local value = parent[key]
		if key then return key end
	end -- for _, parent in ipairs(parents)
end -- local function parents
local function label(name)
	-- neondebug.log('looking up translation: label.' .. name, 'main')
	return lookup('label', name)
end -- local function label ----------------------------------------------------
local function text(textdata, color)
	color = color or huddata.defaulttextcolor
	logpcall(imgui.TextColored, 'text(textdata, color)', color[1], color[2], color[3], color[4], textdata)
end -- local function text -----------------------------------------------------
--------------------------------------------------------------------------------
local function stringeditor(param, hidelabel)
	neondebug.log('creating stringeditor ' .. param, 'main')
	local editorlabel
	if not hidelabel then editorlabel = label(param) end
	return function(data)
		local changed = false
		local newvalue, success
		if editorlabel then
			text(editorlabel)
			imgui.SameLine()
		end
		imgui.PushItemWidth(huddata.inputtextwidth or 0)
			changed, newvalue = logpcall(imgui.InputText, 'stringeditor(param)', '##' .. param, data[param], 72)
		imgui.PopItemWidth()
		if changed then data[param] = newvalue end
		return changed
	end -- return function
end -- local function editstring -----------------------------------------------
local function numbereditor(param, min, max, step, formatstr)
	formatstr = formatstr or '%f'
	neondebug.log('creating numbereditor ' .. param, 'main')
	local label = label(param)
	local function showdragfloats(data)
		local changed, newvalue = imgui.DragFloat('##' .. param, data[param], step, min, max, string.format(formatstr, data[param]))
		-- label, value, step, min, max, displayvalue (aka format)
		if changed then data[param] = newvalue end
		imgui.SameLine()
		changed, newvalue = imgui.DragFloat('##finetune' .. param, data[param], step / 10, min, max, step / 10 .. 'x')
		if changed then data[param] = newvalue end
		imgui.SameLine()
		changed, newvalue = imgui.DragFloat('##quick' .. param, data[param], step * 10, min, max, step * 10 .. 'x')
		if changed then data[param] = newvalue end
	end -- local function showdragfloats
	return function(data)
		imgui.Text(label .. ':')
		imgui.SameLine()
		imgui.PushItemWidth(44)
		logpcall(showdragfloats, {'numbereditor(param, min, max, step)', param, min, max, step}, data)
		imgui.PopItemWidth()
	end -- return function
end -- local function numbereditor -----------------------------------------------
local function slownumbereditor(param, min, max, step)
	neondebug.log('creating slownumbereditor ' .. param, 'main')
	local label = label(param)
	return function(data)
		imgui.Text(label)
		imgui.SameLine()
		imgui.PushItemWidth(96)
			local changed, newvalue = logpcall(imgui.InputFloat, {'slownumbereditor(param, min, max, step)', param, min, max, step}, '##' .. param, data[param], step, 1, 1, data[param])
		imgui.PopItemWidth()
		if changed then data[param] = utility.bindnumber(newvalue, min, max) end
	end
end -- local function editslownumber -------------------------------------------
local function booleaneditor(param)
	neondebug.log('creating booleaneditor ' .. param, 'main')
	local label = label(param)
	return function(data)
		local changed, newvalue = imgui.Checkbox(label, data[param])
		if changed then
			data[param] = newvalue
		end
		return changed
	end -- return function
end -- local function booleaneditor ----------------------------------------------
local function coloreditor(param)
	neondebug.log('creating coloreditor ' .. param, 'main')
	local label = label(param)
	local function showdragfloats(data)
		for i = 1, 4 do
			imgui.SameLine()
			local changed, newvalue = imgui.DragFloat('##' .. param .. i,
				data[param][i] * 255, 1, 0, 255, colorlabels[i] .. ':%.0f')
			if changed then data[param][i] = newvalue / 255 end
		end
	end -- local function showdragfloats
	neondebug.log('finished defining local function showdragfloats for ' .. param, 'main')
	return function(data)
		imgui.Text(label)
		imgui.PushItemWidth(40)
		logpcall(showdragfloats, {'coloreditor(param)', param}, data)
		imgui.PopItemWidth()
		imgui.SameLine()
		imgui.ColorButton(unpack(data[param]))
	end -- return function
end -- local function coloreditor
--[[local function gradienteditor(self, param)
	local label = label(param)
	return function(data)
	
	end -- return function
end -- local function editgradient ---------------------------------------------]]
local function flageditor(param, flag, index, invert)
	neondebug.log('creating flageditor ' .. param, 'main')
	local label = label(param)
	return function(data)
		local changed, newvalue = imgui.Checkbox(label, data[param])
		if changed then
			data[param] = newvalue
			if invert then newvalue = not newvalue end
			if newvalue then
				data.windowoptions[index] = flag
			else
				data.windowoptions[index] = ''
			end
		end -- if changed
		return changed
	end -- return function
end -- local function flageditor -------------------------------------------------
local function optionalparametereditor(arg)-- arg={param, editlabel, resetlabel, editfunction, defaultvalue}
	neondebug.log('creating optioanalparametereditor ' .. arg.param, 'main')
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
			if imgui.Button(editlabel) then
				data[param] = defaultvalue()
				if type(data[param]) == 'table' then data[param] = utility.listcopy(data[param]) end
			end
		end -- if data[param]
	end -- return function
end -- local function editoptionalparameter
local function setactivebuttonstyle()
	imgui.PushStyleColor('Button', .2, .5, 1, 1)
	imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
	imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
end -- local function setactivebuttonstyle
local function button(param)
	local label = label(param)
	return function(data)
		local newvalue
		if data[param] then setactivebuttonstyle() end
		newvalue = imgui.Button(label)
		if data[param] then imgui.PopStyleColor(3) end
		if newvalue then data[param] = not data[param] end
	end -- return function
end -- local function listbutton
local function togglebutton(callback, isactive)
	local label = label(param)
	return function()
		local active = isactive()
		if active then setactivebuttonstyle() end
		
		if imgui.Button(label) then callback() end
		
		if active then imgui.PopStyleColor(3) end
	end -- return function
end -- local function togglebutton
local function simpletogglebutton(param)
	local label = label(param)
	if label == nil then print('translation for [' .. param .. '] not found.') return end
	return function(data)
		local active = data[param]
		if active then
			imgui.PushStyleColor('Button', .2, .5, 1, 1)
			imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
			imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
		end
		
		local clicked = logpcall(imgui.Button, {'simpletogglebutton(param)', param}, label)
		if clicked then data[param] = not data[param] end
		
		if active then imgui.PopStyleColor(3) end
	end -- return function
end -- local function togglebutton ---------------------------------------------
local function listbutton(param, value)
	local label = lookup('psodata', value)
	return function(data)
		local clicked
		local active = data[param] == value
		if active then setactivebuttonstyle() end
			clicked = logpcall(imgui.Button, {'listbutton(param, value)', param, value}, label)
		if active then imgui.PopStyleColor(3) end
		if clicked then
			if active then data[param] = nil
			else data[param] = value
			end -- if active
		end -- if success and clicked
		-- if not success then print('protected button call (' .. value .. ') errored!') end
		return clicked
	end -- return function
end -- local function listbutton
local function listbutton2(param, value, labeltype) -- just like listbutton, but clicking an active button doesn't do data[param] = nil
	local label = lookup(labeltype, value)
	return function(data)
		local clicked
		local active = data[param] == value
		if active then setactivebuttonstyle() end
			clicked = logpcall(imgui.Button, {'listbutton(param, value)', param, value}, label)
		if active then imgui.PopStyleColor(3) end
		if clicked then data[param] = value end
		-- if not success then print('protected button call (' .. value .. ') errored!') end
		return clicked
	end -- return function
end -- local function listbutton2
local function listpicker(param, combolist, popupid)
	local label = label(param)
	local buttonlist = {}
	local clicked
	for _, value in ipairs(combolist) do
		table.insert(buttonlist, listbutton(param, value))
	end -- for _, key in ipairs(orderlist)
	local function showpopup(data)
		text(label)
		imgui.Separator()
		for _, button in ipairs(buttonlist) do
			clicked = clicked or button(data)
			-- if button(data) then imgui.CloseCurrentPopup() end
		end
	end -- local function showpopup
	return function(data)
		clicked = false
		if imgui.BeginPopup(popupid) then
			logpcall(showpopup, {'listpicker(param, combolist, popupid)', param, combolist, popupid}, data)
			if clicked then imgui.CloseCurrentPopup() end
			imgui.EndPopup()
		end -- if imgui.BeginPopup
		return clicked
	end -- return function
end -- local function listpicker
local function listpicker2(param, combolist, popupid)
	local label = label(param)
	local buttonlist = {}
	local orderlist = {}
	local clicked = false
	for category, list in pairs(combolist) do
		if type(list) == 'table' then
			table.insert(orderlist, category)
			buttonlist[category] = {}
			for _, value in ipairs(list) do
				table.insert(buttonlist[category], listbutton(param, value))
				-- neondebug.alwayslog('added button ' .. value .. ' to listpicker2 ' .. param .. ' in category ' .. category, 'listpicker2')
			end -- for key, _ in pairs(combolist)
		end -- if type(list) == 'table'
	end -- for category, list in pairs(combolist)
	utility.tablesort(orderlist)
	neondebug.log('initialized listpicker2 popup for ' .. param .. '.\norderlist contents: ' .. utility.serialize(orderlist) .. '\nbuttonlist contents: ' .. utility.serialize(buttonlist), 'listpicker2')
	local function showpopup2(data)
		neondebug.log('showing listpicker2 popup for ' .. param .. '.\norderlist contents: ' .. utility.serialize(orderlist) .. '\nbuttonlist contents: ' .. utility.serialize(buttonlist), 'listpicker2')
		text(label)
		-- imgui.NewLine()
		for _, category in ipairs(orderlist) do
			imgui.BeginGroup()
				neondebug.log('showing category ' .. category .. ' in listpicker2 ' .. param, 'listpicker2')
				text(category)
				for index, button in ipairs(buttonlist[category]) do
					clicked = clicked or button(data)
					neondebug.log('showed button ' .. index .. ' in listpicker2 ' .. param, 'listpicker2')
				end -- for _, button in ipairs(buttonlist[category])
			imgui.EndGroup()
			imgui.SameLine()
		end -- for _, category in ipairs(orderlist)
	end -- local function showpopup2
	return function(data)
		clicked = false
		if imgui.BeginPopup(popupid) then
			-- neondebug.log('showing listpicker2 popup ' .. popupid, 'listpicker2')
			logpcall(showpopup2, {'listpicker2(param, combolist, popupid)', param, combolist, popupid}, data)
			if clicked then
				-- clicked = false
				imgui.CloseCurrentPopup()
			end
			imgui.EndPopup()
		end -- if imgui.BeginPopup
		return clicked
	end -- return function
end -- local function listpicker2
local function combobox(param, combolist)
	return function(data)
		local changed = false
		local newvalue, success
		imgui.PushItemWidth(8 + (8 * combolist.longest))
			changed, newvalue = logpcall(imgui.Combo, {'combobox(param, combolist)', param, combolist}, '##' .. param, combolist[data[param]], combolist, #combolist)
		imgui.PopItemWidth()
		if changed then data[param] = combolist[newvalue] end
		return changed
	end -- return function
end -- local function combobox -------------------------------------------------
--------------------------------------------------------------------------------
local widgets = {}
local lists = {}
local function initwidget(widget, widgetclass)
	setmetatable(widget, widgetclass)
	-- print('type(widget.init): ' .. type(widget.init))
	-- print('widget metatable: ' .. utility.serialize(getmetatable(widget), 0, true) .. '\nwidgetclass: ' .. utility.serialize(widgetclass))
	-- print('after - widget: ' .. utility.serialize(widget, 0, true))
	widget.id = generateid()
end -- local function initwidget
local function restorewidget(widget, widgetclass)
	initwidget(widget, widgetclass)
	widget:init()
	widget:restore()
end -- local function restorewidget --------------------------------------------
local function createwidget(widgetclass)
	local newwidget = {}
	newwidget.typename = widgetclass.typename
	initwidget(newwidget, widgetclass)
	-- newwidget.dontserialize={dontserialize=true, editparam=true, parent=true}
	newwidget:firsttimeinit()
	newwidget:init()
	return newwidget
end -- local function createwidget ------------------------------------------------
local basewidget = {
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	firsttimeinit = function(self) end,
	init = function(self)
		self:updatename()
	end,
	restore = function(self) end,
	initeditors = function(self)
		-- in this method, 'self' refers to a widget class, not an instance
		self.textcoloreditor = optionalparametereditor{
			param = 'textcolor',
			editlabel = label('edittextcolor'),
			resetlabel = label('resetparam'),
			editfunction = coloreditor'textcolor',
			defaultvalue = function() return huddata.defaulttextcolor end
		} -- self.textcoloreditor = optionalparametereditor{...}
		self.bgcoloreditor = optionalparametereditor{
			param = 'bgcolor',
			editlabel = label'editbgcolor',
			resetlabel = label'resetparam',
			editfunction = coloreditor'bgcolor',
			defaultvalue = function() return huddata.defaultbgcolor end
		} -- self.bgcoloreditor = optionalparametereditor{...}
		self.fontscaleeditor = optionalparametereditor{
			param = 'fontscale',
			editlabel = label('editfontscale'),
			resetlabel = label('resetparam'),
			editfunction = numbereditor('fontscale', 1, 6, .1),
			defaultvalue = function() return 1 end
		} -- self.fontscaleeditor = optionalparametereditor{...}
		self.togglesameline = booleaneditor'sameline'
		local labeleditorbuttons = {
			listbutton2('labeltype', 'none', 'label'),
			listbutton2('labeltype', 'automatic', 'label'),
			listbutton2('labeltype', 'custom', 'label'),
		} -- local labeleditorbuttons = {...}
		local labeleditorlabel = languagetable.label.labeleditor
		local customlabeleditor = stringeditor('label', true)
		self.labeleditor = function(data)
			text(labeleditorlabel)
			for _, labeleditorbutton in ipairs(labeleditorbuttons) do
				imgui.SameLine()
				if labeleditorbutton(data) then data:initlabel() end
			end -- for _, button in ipairs(labeleditorbuttons)
			if data.labeltype == 'custom' then
				imgui.SameLine()
				if customlabeleditor(data) then data:updatename(data.label) end
			end -- if self.labeltype == 'custom'
		end -- self.labeleditor = function
		-- self:updatelabel()
	end, -- initeditors = function
	updatename = function(self, namevalue)
		namevalue = namevalue or lookup('psodata', self.datasource)
		self.longname = label(self.typename) .. ':\n' .. namevalue
		-- self.longname = languagetable.label[self.typename]
		-- if self.longname == nil then print('translation for [' .. tostring(self.typename) .. '] not found.') return end
		local oldshortname = self.shortname or 'nothing'
		self.shortname = lookup('short', self.datasource)
		if huddata.showwidgettype then self.shortname = lookup('short', self.typename) .. ': ' .. self.shortname end
		neondebug.log('changed widget name ' .. oldshortname .. ' to ' .. self.shortname, 'updatename')
	end, -- updatename = function
	initlabel = function(self)
		self:updatename()
		if self.labeltype == 'none' then self.label = nil
		else self.label = lookup('psodata', self.datasource)
		end -- if self.labeltype == 'none'
		-- neondebug.log('initialized label for widget ' .. self.widgetname .. ':' .. self.label, 'updatename')
	end, -- initlabel = function
	updatelabel = function(self)
		if self.labeltype == 'custom' then self:updatename(self.label)
		else self:initlabel()
		end
		-- neondebug.log('updated label for widget ' .. self.widgetname .. ':' .. self.label, 'updatename')
	end, -- updatelabel = function
--[[	labeleditor = function(self)
		local changed, newvalue
		text(labeleditorlabel)
		for _, option in ipairs{'none', 'automatic', 'custom'} do
			changed, newvalue = imgui.RadioButton(labeltypelabels[option] .. '##' .. self.id, self.labeltype == option)
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
	end, -- labeleditor = function]]
	updatelayoutw = function(self)
		self.layout.w = utility.scale(self.w, gamewindowwidth)
	end,
	updatelayouth = function(self)
		self.layout.h = utility.scale(self.h, gamewindowheight)
	end,
	button = function(self, label, selected, tooltip)
		local clicked
		if selected then
			setactivebuttonstyle()
		else
			imgui.PushStyleColor('Button', .5, .5, .5, .3)
		end
		
		local clicked = logpcall(imgui.Button, {'basewidget.button(self, label, selected, tooltip)', self, label, selected, tooltip}, label)
		clicked = clicked and not imgui.IsMouseDragging(0, huddata.dragthreshold)
		-- if imgui.Button(label)
		-- and not imgui.IsMouseDragging(0, huddata.dragthreshold)
		-- then clicked = true
		-- else clicked = false
		-- end
		
		if selected then imgui.PopStyleColor(2) end
		imgui.PopStyleColor()
		
		if tooltip and imgui.IsItemHovered() and not imgui.IsMouseDown(0) then
			-- print(utility.serialize(self))
			imgui.SetTooltip(tooltip)
		end
		return clicked
	end, -- button = function
	dontserialize = {longname = true, shortname = true, dontserialize = true, editparam = true, parent = true, id = true},
} -- basewidget = {...}
basewidget.__index = basewidget
widgets.textvalue = {
	typename = 'textvalue',
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	--[[ creating a textvalue:
		+ new:
		+ restore:
			* updatelabel
		+ both:
	]]
	-- init = function(self)
		-- basewidget.init(self)
		-- self:updatelabel()
	-- end,
	initeditors = function(self)
		-- in this method, 'self' refers to a widget class, not an instance
		self.sourceeditor = listpicker2('datasource', psodata.get.string, self.sourceeditorid)
		-- self:updatelabel()
	end, -- initeditors = function
	labeltype = 'none',
	datasource = psodata.get.string.character[1],
	editsource = true,
	sourceeditorid = 'textsourcepicker',
	edit = function(self)
		self:labeleditor()
		self:textcoloreditor()
		self:togglesameline()
		if self:sourceeditor() then self:updatelabel() end
		if imgui.Button('data source') then self.editsource = true end
		if self.editsource then imgui.OpenPopup(self.sourceeditorid) self.editsource = false end
	end, -- edit = function
	protecteddisplay = function(self)
		if self.label then text(self.label) imgui.SameLine() end
		imgui.Text(psodata.get.string[self.datasource]())
	end, -- protecteddisplay = function
	display = function(self)
		if self.sameline then imgui.SameLine() end
		if self.textcolor then imgui.PushStyleColor('text', unpack(self.textcolor)) end
		logpcall(self.protecteddisplay, 'widgets.textvalue:display()', self)
		if self.textcolor then imgui.PopStyleColor() end
	end, -- display = function
} -- widgets.textvalue = {...}
widgets.time = {

} -- widgets.time = {...}
widgets.xprate = {

} -- widgets.xprate = {...}
widgets.progressbar = {
	typename = 'progressbar',
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	--[[
	creating a progressbar:
		+ new:
			* init self.layout
			* update layout w & h
		+ restore:
		+ both:
	]]
	-- init = function(self)
		-- basewidget.init(self)
		-- self:updatename(self.datasource)
	-- end, -- init = function
	firsttimeinit = function(self)
		self.barcolor = utility.listcopy(huddata.defaultprogressbarcolor)
		self.textcolor = utility.listcopy(huddata.defaulttextcolor)
		self.bargradient = createwidget(lists.gradient)
		self.layout = {}
		-- self:updatelayoutw()
		-- self:updatelayouth()
	end, -- firsttimeinit = function
	init = function(self)
		self:updatename()
		self:updatelayoutw()
		self:updatelayouth()
	end, -- init = function
	restore = function(self)
		restorewidget(self.bargradient, lists.gradient)
		-- self.bargradient:init()
	end, -- restore = function
	initeditors = function(self)
		-- in this method, 'self' refers to a widget class, not an instance
		self.sourceeditor = listpicker('datasource', psodata.get.progress, self.sourceeditorid)
		self.toggleshowvalue = booleaneditor'showvalue'
		self.toggleshowrange = booleaneditor'showrange'
		self.togglescalebar = booleaneditor'scalebar'
		-- self.togglefillwindow = booleaneditor'fillwindow'
		self.toggledynamicbarcolor = booleaneditor'dynamicbarcolor'
		self.editcolor = coloreditor'barcolor'
		-- self:updatelabel()
	end, -- initeditors = function
	w = .1,
	h = .02,
	datasource = psodata.get.progress[1],
	showvalue = true,
	showrange = true,
	editsource = true,
	sourceeditorid = 'progresssourcepicker',
	labeltype = 'none',
	edit = function(self)
		-- if self:sourceeditor() then self:updatename('datasource') end
		self:toggleshowvalue()
		if self.showvalue then self:toggleshowrange() end
		self:labeleditor()
		self:togglescalebar()
		-- if #self.parent == 1 then self:togglefillwindow() end
		self:toggledynamicbarcolor()
		if self.dynamicbarcolor then
			self.bargradient:edit()
		else
			self:editcolor()
		end
		-- print(utility.serialize(self))
		if self:sourceeditor() then self:updatelabel() end
		if imgui.Button('data source') then self.editsource = true end
		if self.editsource then imgui.OpenPopup(self.sourceeditorid) self.editsource = false end
		self:editsize()
	end, -- edit = function
	protectededitsize = function(self)
		-- need to set this up to use language table once i can see how it looks
		-- local dragfloatwidth = 36
		local width = self.w * gamewindowwidth
		local height = self.h * gamewindowheight
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
		
		text'w:'
		imgui.SameLine()
		-- imgui.PushItemWidth(dragfloatwidth)
		changed1, newvalue = imgui.DragFloat('##width' .. self.id, width, huddata.bigstep, 0, gamewindowwidth, string.format('%.0f', width))
		if changed1 then self.w = newvalue / gamewindowwidth end
		imgui.SameLine()
		changed2, newvalue = imgui.DragFloat('##wfinetune' .. self.id, width, huddata.smallstep, 0, gamewindowwidth, 'slow')
		if changed2 then self.w = newvalue / gamewindowwidth end
		-- if changed1 or changed2 then self:updatelayoutw() end
		
		imgui.SameLine()
		text'h:'
		imgui.SameLine()
		-- imgui.PushItemWidth(dragfloatwidth)
		changed1, newvalue = imgui.DragFloat('##height' .. self.id, height, huddata.bigstep, 0, gamewindowheight, string.format('%.0f', height))
		if changed1 then self.h = newvalue / gamewindowheight end
		imgui.SameLine()
		changed2, newvalue = imgui.DragFloat('##hfinetune' .. self.id, height, huddata.smallstep, 0, gamewindowheight, 'slow')
		if changed2 then self.h = newvalue / gamewindowheight end
		-- if changed1 or changed2 then self:updatelayouth() end
	end, -- protectededitsize = function
	editsize = function(self)
		local dragfloatwidth = 36
		imgui.PushItemWidth(dragfloatwidth)
		logpcall(self.protectededitsize, 'widgets.progressbar:editsize()', self)
		imgui.PopItemWidth()
	end, -- editsize = function
	editparam = {
		bargradient = function(self)
			editboolean(self, 'dynamicbarcolor', 'dynamic bar color')
			if self.dynamicbarcolor then
				self.gradient:edit()
			else
				-- self.editparam.barcolor(self)
			end
		end,
		size = function(self)
		
		end,
		}, -- editparam = {...}
	display = function(self)
		local barcolor, textcolor
		local data = psodata.get.progress[self.datasource]()
		local barvalue = data[1] / data[2]
		if self.sameline then imgui.SameLine() end
		
		local progress
		if barvalue == barvalue then
			if self.scalebar then
				progress = barvalue
			else
				progress = 1
			end -- if self.scalebar
		else
			barvalue, progress = 1, 1
		end -- if barvalue == barvalue
		
		if self.dynamicbarcolor then
			local colorindex = evaluategradient(self.bargradient.levels, barvalue)
			barcolor = self.bargradient[colorindex]
			-- imgui.PushStyleColor('PlotHistogram', unpack(evaluategradient(self.bargradient, barvalue)))
		elseif self.barcolor then
			barcolor = self.barcolor
			-- imgui.PushStyleColor('PlotHistogram', unpack(self.barcolor))
		-- else
			-- barcolor = huddata.defaultprogressbarcolor
		end
		
		if self.dynamictextcolor then
			textcolor = evaluategradient(self.textgradient, barvalue)
			-- imgui.PushStyleColor('Text', unpack(evaluategradient(self.textgradient, barvalue)))
		elseif self.textcolor then
			textcolor = self.textcolor
			-- imgui.PushStyleColor('Text', unpack(self.textcolor))
		-- else
			-- textcolor = huddata.defaulttextcolor
		end
		
		local text
		if self.showvalue then
			if self.showrange then
				text = data[1] .. '/' .. data[2]
			else text = data[1]
			end
		else text = ''
		end
		if self.label then text = self.label .. ': ' .. text end
		
		imgui.PushStyleColor('Text', unpack(textcolor))
		imgui.PushStyleColor('PlotHistogram', unpack(barcolor))
		
		logpcall(imgui.ProgressBar, 'widgets.progressbar:display()', progress, self.w * gamewindowwidth, self.h * gamewindowheight, text)
		
		imgui.PopStyleColor(2)
		-- if self.dynamictextcolor or self.textcolor then imgui.PopStyleColor() end
		-- if self.dynamicbarcolor or self.barcolor then imgui.PopStyleColor() end
	end, -- display = function(self)
} -- widgets.progressbar = {...}
widgets.list = {
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	--[[
	creating a list:
		+ new:
		+ restore:
		+ both:
	]]

} -- widgets.list = {...}
widgets.itemlist = {
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	--[[
	creating an itemlist:
		+ new:
		+ restore:
		+ both:
	]]

} -- widgets.itemlist = {...}
local widgetcombolist = utility.tablecombolist(widgets)
local customwindow = {
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	--[[
	creating a customwindow:
		+ new:
		+ restore:
		+ both:
	]]
	firsttimeinit = function(self)
		self.windowoptions = {'', 'NoResize', '', '', 'AlwaysAutoResize'}
		self.layout = {}
		self.widgetlist = createwidget(lists.widgetlist)
		self.x = self.id * 5
		self.y = self.id * 5
		self.title = 'new window ' .. #huddata.windowlist + 1
	end, -- firsttimeinit = function
	init = function(self)
		self:updatelayoutw()
		self:updatelayouth()
		self:updatelayoutx()
		self:updatelayouty()
	end, -- init = function
	restore = function(self)
		-- self.widgetlist:init()
		restorewidget(self.widgetlist, lists.widgetlist)
	end, -- restore = function
	hidden = true,
	menutypes = {'anymenu', 'mainmenu', 'lowermenu', 'fullmenu'},
	
	showoptions = false,
	title = 'moo',
	enable = 'true',
	autoresize = true,
	allowmousemove = true,
	inlobby=true,
	showtitlebar = true,
	showscrollbar = true,
	w = 10,
	h = 10,
	windowoptionchanged = true,
	initeditors = function(self)
		self.titleeditor = stringeditor'title'
		self.toggletitlebar = flageditor('showtitlebar', 'NoTitleBar', 1, true)
		self.togglescrollbar = flageditor('showscrollbar', 'NoScrollBar', 4, true)
		self.toggleautoresize = flageditor('autoresize', 'AlwaysAutoResize', 5)
		self.togglemousemove = flageditor('allowmousemove', 'NoMove', 3, true)
		self.togglemouseresize = flageditor('allowmouseresize', 'NoResize', 2, true)
		self.toggleenablewindow = booleaneditor'enable'
		self.togglehidenotinfield = booleaneditor'notinfield'
		self.togglehideinlobby = booleaneditor'inlobby'
		self.togglehideanymenu = booleaneditor'anymenu'
		self.togglehidelowermenu = booleaneditor'lowermenu'
		self.togglehidemainmenu = booleaneditor'mainmenu'
		self.togglehidefullmenu = booleaneditor'fullmenu'
	end, -- initeditors = function --------------------------------------
	editlayout = function(self)
		local dragfloatwidth = 36
		local labelsource, formatstr, changed1, changed2, success
		if huddata.showpixels then
			labelsource = self.layout
			formatstr = '%.0f'
		else
			labelsource = self
			formatstr = '%.2f'
		end -- if huddata.showpixels
		local step = 1
		local smallstep = .01
		
		imgui.PushItemWidth(dragfloatwidth)
		imgui.BeginGroup() -- edit xpos and width
			text'x:'
			imgui.SameLine()
			-- imgui.PushItemWidth(dragfloatwidth)
			changed1, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), x', '##xpos' .. self.id, self.x, step, boundary.left, boundary.right, string.format(formatstr, labelsource.x))
			if changed1 then self.x = newvalue end
			imgui.SameLine()
			changed2, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), x fine', '##xfinetune' .. self.id, self.x, smallstep, boundary.left, boundary.right, '.01x')
			if changed2 then self.x = newvalue end
			if changed1 or changed2 then
				self:updatelayoutx()
				self.windowoptionchanged = true
			end
			
			if not self.autoresize then
				text'w:'
				imgui.SameLine()
				-- imgui.PushItemWidth(dragfloatwidth)
				changed1, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), w', '##width' .. self.id, self.w, step, boundary.left, boundary.right, string.format(formatstr, labelsource.w))
				if changed1 then self.w = newvalue end
				imgui.SameLine()
				changed2, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), w fine', '##wfinetune' .. self.id, self.w, smallstep, boundary.left, boundary.right, '.01x')
				if changed2 then self.w = newvalue end
				if changed1 or changed2 then
					self:updatelayoutx()
					self:updatelayoutw()
					self.windowoptionchanged = true
				end -- if changed1 or changed2
			end -- if not self.autoresize
		imgui.EndGroup() -- edit xpos and width
		
		imgui.SameLine()
		
		imgui.BeginGroup() -- edit ypos and height
			text'y:'
			imgui.SameLine()
			-- imgui.PushItemWidth(dragfloatwidth)
			changed1, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), y', '##ypos' .. self.id, self.y, step, boundary.left, boundary.right, string.format(formatstr, labelsource.y))
			if changed1 then self.y = newvalue end
			imgui.SameLine()
			changed2, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), y fine', '##yfinetune' .. self.id, self.y, smallstep, boundary.left, boundary.right, '.01x')
			if changed2 then self.y = newvalue end
			if changed1 or changed2 then
				self:updatelayouty()
				self.windowoptionchanged = true
			end
			
			if not self.autoresize then
				text'h:'
				imgui.SameLine()
				-- imgui.PushItemWidth(dragfloatwidth)
				changed1, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), h', '##height' .. self.id, self.h, step, boundary.left, boundary.right, string.format(formatstr, labelsource.h))
				if changed1 then self.h = newvalue end
				imgui.SameLine()
				changed2, newvalue = logpcall(imgui.DragFloat, 'customwindow:editlayout(), h fine', '##hfinetune' .. self.id, self.h, smallstep, boundary.left, boundary.right, '.01x')
				if changed2 then self.h = newvalue end
				if changed1 or changed2 then
					self:updatelayouty()
					self:updatelayouth()
					self.windowoptionchanged = true
				end -- if changed1 or changed2
			end -- if not self.autoresize
		imgui.EndGroup() -- edit ypos and height
		imgui.PopItemWidth()
	end, -- editlayout = function ---------------------------------------
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
			self.widgetlist:edit()
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
			if self:toggleautoresize() and not self.autoresize then self.windowoptionchanged = true end
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
	-- additemlist = widgetcombolist,
	updatelayoutx = function(self)
		self.layout.x = utility.scale(self.x, gamewindowwidth, self.w)
	end,
	updatelayouty = function(self)
		self.layout.y = utility.scale(self.y, gamewindowheight, self.h)
	end,
	detectmouseresize = function(self)
		if self.windowoptions[2] ~= 'NoResize' and self.windowoptions[5] ~= 'AlwaysAutoResize' then
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
		end -- if self.windowoptions[2] ~= 'NoResize' and self.windowoptions[5] ~= 'AlwaysAutoResize'
	end, -- detectmouseresize = function
	detectmousemove = function(self)
		if self.windowoptions[3] ~= 'NoMove' then
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
		if outofbounds then self.windowoptionchanged = true end
		end -- if self.windowoptions[3] ~= 'NoMove'
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
		
		if self.windowoptionchanged then
			imgui.SetNextWindowPos(self.layout.x, self.layout.y, 'Always')
			if self.windowoptions[5] ~= 'AlwaysAutoResize' then
				imgui.SetNextWindowSize(self.layout.w, self.layout.h, 'Always')
			end
			self.windowoptionchanged = false
		end
		
		local bgcolor = self.bgcolor
			-- or huddata['background color']
		if bgcolor then
			imgui.PushStyleColor('WindowBg', unpack(bgcolor))
		end
		
		local success
		success, self.enable = imgui.Begin(self.title .. '###' .. self.id, true,
			self.windowoptions)
			if not success then
				imgui.End()
				return
			end
			
			self:detectmouseresize()
			self:detectmousemove()
			
			-- imgui.SetWindowFontScale(self['font scale'] or huddata.fontscale)
			
			for _, item in ipairs(self.widgetlist) do
				logpcall(item.display, 'customwindow:display()', item)
			end
			
		imgui.End()
		if bgcolor then imgui.PopStyleColor() end
	end,
	updatewindowoption = function(self, newvalue, optionindex, flag)
		if newvalue then self.windowoptions[optionindex] = flag
		else self.windowoptions[optionindex] = ''
		end -- if newvalue
	end, -- updatewindowoption = function
} -- widgets.customwindow = {...}
setmetatable(customwindow, basewidget)
customwindow.__index = customwindow
local baselist = {
	--[[ creating a list
	+ new:
		* allocate memory (= {})
		* set list type
	+ restore:
	+ both:
		* setup inheritance
	]]
	firsttimeinit = function(self)
		self.dragtarget = {}
		self.buttonedges = {5}
		self.buttoncenters = {}
	end, -- firsttimeinit = function
	init = function(self) self.changed = true end,
	restore = function(self) end,
	changed = true,
	orientation = 'horizontal',
	listheight = 36,
	initeditors = function(self)
		-- in this method, 'self' refers to a widget class, not an instance
		local horizontalbutton = listbutton('orientation', 'horizontal', 'label')
		local verticalbutton = listbutton('orientation', 'vertical', 'label')
		self.chooseorientation = function(data)
			horizontalbutton(data)
			imgui.SameLine()
			verticalbutton(data)
		end -- self.chooseorientation = function
	end, -- initeditors = function
	initdragtarget = function(self, width, height)
		-- neondebug.log('initdragtarget - width: ' .. width .. ' | height: ' .. height, 'layoutvalues')
		self.dragtarget.top = -dragtargetmargin
		self.dragtarget.bottom = height + dragtargetmargin
		self.dragtarget.left = -dragtargetmargin
		self.dragtarget.right = width + dragtargetmargin
	end, -- initdragtarget = function
	calcdragdest = function(positions, targetvalue)
		local result = #positions + 1
		for index = 1, #positions do
			if targetvalue < positions[index] then result = index break end
		end
		return result
	end, -- calcdragdest = function
	showitemcenters = function(self)
		if self.orientation == 'horizontal' then
			imgui.NewLine()
			-- imgui.Dummy(0, 0)
			-- imgui.SetCursorPosX(0)
			for _, pos in ipairs(self.itemcenters) do
				imgui.SameLine(pos)
				text'|'
			end -- for _, pos in ipairs(self.itemcenters)
		else -- self.orientation is assumed to be 'vertical'
			local currentposy = imgui.GetCursorPosY()
			for _, pos in ipairs(self.itemcenters) do
				imgui.SetCursorPosY(pos)
				imgui.Separator()
			end -- for _, pos in ipairs(self.itemcenters)
			imgui.SetCursorPosY(currentposy)
		end -- if self.orientation == 'horizontal'
	end, -- showitemcenters = function
	showitemedges = function(self)
		if self.orientation == 'horizontal' then
			imgui.NewLine()
			for _, pos in ipairs(self.itemedges) do
				imgui.SameLine(pos)
				text'|'
			end -- for _, pos in ipairs(self.itemedges)
		else -- self.orientation is assumed to be 'vertical'
			local currentposy = imgui.GetCursorPosY()
			for _, pos in ipairs(self.itemedges) do
				imgui.SetCursorPosY(pos)
				imgui.Separator()
			end -- for _, pos in ipairs(self.itemedges)
			imgui.SetCursorPosY(currentposy)
		end -- if self.orientation == 'horizontal'
	end, -- showitemedges = function
	detectdragstart = function(self, itemactive)
		return itemactive and not self.dragsource and imgui.IsMouseDragging(0, huddata.dragthreshold)
	end, -- detectdragstart = function
	dragend = function(self)
				if self.dragdest then
					self:processdrop()
					self.changed = true
				end
				self.newitem = nil
				self.dragactive = nil
				self.dragdest = nil
				self.dragsource = nil
	end, -- dragend = function
	showadditemlist = function(self) end,
	showadditempopup = function(self) end,
	showitemeditor = function(self) end,
	edit = function(self)
		self.changed = true
		writelayoutvalues('start baselist.edit()')
		local lastitempos
		local windowoffsetx, windowoffsety = imgui.GetCursorScreenPos() -- need these to reconcile relative and absolute coordinates
		local editoroffsetx, editoroffsety = imgui.GetCursorPos()
		-- local currentx, currenty = imgui.GetCursorPos()
		-- offsetx = offsetx - currentx
		-- offsety = offsety - currenty
		-- local framewidth, frameheight
		-- if self.orientation == 'horizontal' then
			-- framewidth = -1
			-- frameheight = imgui.GetTextLineHeightWithSpacing() + self.listheight
		-- else -- self.orientation is assumed to be 'vertical'
			-- i think i might just decide to not put lists in a frame...
		-- end -- if self.orientation == 'horizontal'
		
		imgui.BeginGroup()
			writelayoutvalues('baselist.edit: start imgui.BeginGroup()')
		-- if imgui.BeginChild('item list', framewidth, frameheight, true) then
		-- this won't work with vertical layout because of size values
		
			if self.orientation == 'horizontal' then
				imgui.Dummy(0, 0)
				imgui.SameLine()
				writelayoutvalues('after imgui.Dummy()')
				-- imgui.SameLine(12)
			end
			-- not sure why i need this?  - it might be to make space for the drop target indicator.
			
			if self.changed then
				if self.orientation == 'horizontal' then
					self.spacing = imgui.GetCursorStartPos() * .75
					lastitempos = imgui.GetCursorPosX() - self.spacing
				else -- self.orientation is assumed to be 'vertical'
					lastitempos = imgui.GetCursorPosY() - 2.5
				end
				self.itemedges = {lastitempos}
				self.itemcenters = {}
			end
			-- initialize itemcenters and itemedges
			
			for index, item in ipairs(self) do
				if self:detectdragstart(self:listitem(index)) then self.dragsource = index end
				if self.orientation == 'horizontal' then imgui.SameLine() end
				writelayoutvalues('list item: ' .. index)
				-- display one list item and detect when drag starts
				
				if self.changed then
					local itemwidth, itemheight = imgui.GetItemRectSize()
					if self.orientation == 'horizontal' then
						-- if itemheight > self.listheight then self.listheight = itemheight end
						local currentpos = imgui.GetCursorPosX()
						table.insert(self.itemcenters, (currentpos + self.itemedges[#self.itemedges]) / 2)
						table.insert(self.itemedges, currentpos - self.spacing)
					else -- assume self.orientation == 'vertical'
						local currentpos = imgui.GetCursorPosY()
						table.insert(self.itemcenters, (currentpos + self.itemedges[#self.itemedges]) / 2)
						-- lastitempos = lastitempos + itemheight + 4
						table.insert(self.itemedges, currentpos)
					end -- if self.orientation == 'horizontal'
				end -- if self.changed
				-- add entries to itemcenters and itemedges for current item
				
			end -- for index, item in ipairs(self)
			
			if self.dragdest then
				if self.orientation == 'horizontal' then
					local offset, _ = imgui.GetCursorPos()
					imgui.SameLine(self.itemedges[self.dragdest])
					text'|'
				else -- self.orientation is assumed to be 'vertical'
					local currentposy = imgui.GetCursorPosY()
					imgui.SetCursorPosY(self.itemedges[self.dragdest])
					imgui.Separator()
					imgui.SetCursorPosY(currentposy)
				end -- if self.orientation == 'horizontal'
			end
			-- show where drag item will go if mouse is released now
			-- this is horizontal layout specific
			
		imgui.EndGroup()
		writelayoutvalues('after imgui.EndGroup()')
		-- end imgui.EndChild() -- end item list
		
		if self.changed then
			-- self.changed = false
			self:initdragtarget(imgui.GetItemRectSize())
		end -- if self.changed
		-- setup drop zone; layout recalculation done
		
		-- imgui.SameLine()
		-- self:showitemcenters()
		writelayoutvalues('after showitemcenters()')
		-- self:showitemedges()
		
		self:showadditemlist()
		
		if self.dragsource then
			if imgui.IsMouseDown(0) then
				local mousex, mousey = imgui.GetMousePos()
				mousex = mousex - windowoffsetx
				mousey = mousey - windowoffsety
				
				if utility.iswithinrect(mousex, mousey, self.dragtarget) then
					if self.orientation == 'horizontal' then
						self.dragdest = self.calcdragdest(self.itemcenters, mousex + editoroffsetx)
					else -- assume orientation == 'vertical'
						self.dragdest = self.calcdragdest(self.itemcenters, mousey + editoroffsety)
					end -- if self.orientation == 'horizontal'
				else
					self.dragdest = nil
				end -- if mouse position is within dragtarget
			else -- drag action ended
				self:dragend()
			end -- if imgui.IsMouseDown(0)
		end -- if self.dragsource
		-- recalculate drag target, or complete drag action
		
		self:showitemeditor()
		
	end, -- edit = function(self)
	edithorizontal = function(self)
		-- self.changed = true
		local windowoffsetx, windowoffsety = imgui.GetCursorScreenPos() -- need these to reconcile relative and absolute coordinates
		local editoroffsetx, editoroffsety = imgui.GetCursorPos()
		
		imgui.BeginGroup()
		
			imgui.Dummy(0, 0)
			imgui.SameLine()
			writelayoutvalues('after imgui.Dummy()')
			-- not sure why i need this?  - it might be to make space for the drop target indicator.
			
			if self.changed then
				self.spacing = imgui.GetCursorStartPos() * .75
				self.itemedges = {imgui.GetCursorPosX() - self.spacing}
				self.itemcenters = {}
			end
			-- initialize itemcenters and itemedges
			
			for index, item in ipairs(self) do
				if self:detectdragstart(self:listitem(index)) then self.dragsource = index end
				imgui.SameLine()
				writelayoutvalues('list item: ' .. index)
				-- display one list item and detect when drag starts
				
				if self.changed then
					local currentpos = imgui.GetCursorPosX()
					table.insert(self.itemcenters, (currentpos + self.itemedges[#self.itemedges]) / 2)
					table.insert(self.itemedges, currentpos - self.spacing)
				end -- if self.changed
				-- add entries to itemcenters and itemedges for current item
				
			end -- for index, item in ipairs(self)
			
			if self.dragdest then
				local offset, _ = imgui.GetCursorPos()
				imgui.SameLine(self.itemedges[self.dragdest])
				text'|'
			end
			-- show where drag item will go if mouse is released now
			
		imgui.EndGroup()
		
		if self.changed then
			self.changed = false
			self:initdragtarget(imgui.GetItemRectSize())
		end -- if self.changed
		-- setup drop zone; layout recalculation done
		
		-- imgui.SameLine()
		-- self:showitemcenters()
		-- self:showitemedges()
		
		self:showadditemlist()
		
		if self.dragsource then
			if imgui.IsMouseDown(0) then
				local mousex, mousey = imgui.GetMousePos()
				mousex = mousex - windowoffsetx
				mousey = mousey - windowoffsety
				
				if utility.iswithinrect(mousex, mousey, self.dragtarget) then
					self.dragdest = self.calcdragdest(self.itemcenters, mousex + editoroffsetx)
				else self.dragdest = nil
				end -- if mouse position is within dragtarget
			else -- drag action ended
				self:dragend()
			end -- if imgui.IsMouseDown(0)
		end -- if self.dragsource
		-- recalculate drag target, or complete drag action
		
		-- self:showitemeditor()
	end, -- edithorizontal = function(self)
	editvertical = function(self)
		local windowoffsetx, windowoffsety = imgui.GetCursorScreenPos() -- need these to reconcile relative and absolute coordinates
		local editoroffsetx, editoroffsety = imgui.GetCursorPos()
		
		imgui.BeginGroup()
		
			if self.changed then
				self.itemedges = {imgui.GetCursorPosY() - 2.5}
				self.itemcenters = {}
			end
			-- initialize itemcenters and itemedges
			
			for index, item in ipairs(self) do
				if self:detectdragstart(self:listitem(index)) then self.dragsource = index end
				-- display one list item and detect when drag starts
				
				if self.changed then
					local currentpos = imgui.GetCursorPosY()
					table.insert(self.itemcenters, (currentpos + self.itemedges[#self.itemedges]) / 2)
					table.insert(self.itemedges, currentpos)
				end -- if self.changed
				-- add entries to itemcenters and itemedges for current item
				
			end -- for index, item in ipairs(self)
			
			if self.dragdest then
				local currentposy = imgui.GetCursorPosY()
				imgui.SetCursorPosY(self.itemedges[self.dragdest])
				imgui.Separator()
				imgui.SetCursorPosY(currentposy)
			end
			-- show where drag item will go if mouse is released now
			
		imgui.EndGroup()
		
		if self.changed then
			self.changed = false
			self:initdragtarget(imgui.GetItemRectSize())
		end -- if self.changed
		-- setup drop zone; layout recalculation done
		
		-- imgui.SameLine()
		-- self:showitemcenters()
		-- self:showitemedges()
		
		-- self:showadditemlist()
		
		if self.dragsource then
			if imgui.IsMouseDown(0) then
				local mousex, mousey = imgui.GetMousePos()
				mousex = mousex - windowoffsetx
				mousey = mousey - windowoffsety
				
				if utility.iswithinrect(mousex, mousey, self.dragtarget) then
					self.dragdest = self.calcdragdest(self.itemcenters, mousey + editoroffsety)
				else self.dragdest = nil
				end -- if mouse position is within dragtarget
			else -- drag action ended
				self:dragend()
			end -- if imgui.IsMouseDown(0)
		end -- if self.dragsource
		-- recalculate drag target, or complete drag action
		
		-- self:showitemeditor()
	end, -- editvertical = function(self)
} -- local baselist = {...}
baselist.__index = baselist
lists.widgetlist = {
	--[[ creating a list
	+ new:
		* allocate memory (= {})
		* set list type
	+ restore:
	+ both:
		* setup inheritance
	]]
	--[[
	creating a widgetlist:
		+ new:
		+ restore:
		+ both:
	]]
	additemlist = {'textvalue', 'progressbar',},
	init = function(self)
		for _, item in ipairs(self) do
			restorewidget(item, widgets[item.typename])
			-- widgets[item.typename]:init(item)
			-- item.callbacks = {function() self.changed = true end}
		end
	end, -- init = function
	processdrop = function(self)
		if self.newitem then
			local newitem = createwidget(self.dragsource)
			-- newitem.callbacks = {function() self.changed = true end}
			-- self.selected = utility.listadd(self, newitem, self.dragdest, self.selected)
			table.insert(self, self.dragdest, newitem)
			self.selected = self.dragdest
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
		return imgui.IsItemActive()
	end, -- listitem = function
	showadditemlist = function(self)
		-- show list of  widget types that can be added to the list, and detect when one is clicked or dragged.
		imgui.NewLine()
		for index, itemname in ipairs(self.additemlist) do
			imgui.SameLine()
			if imgui.Button(itemname .. '##newitem') and not self.dragactive then
				self.dragsource = widgets[itemname]
				self.newitem = true
				self.dragdest = #self + 1
			elseif self:detectdragstart(imgui.IsItemActive()) then
				self.dragsource = widgets[itemname]
				self.newitem = true
			end -- if imgui.Button(itemname .. '##newitem') and not self.dragactive
		end -- for index, itemname in ipairs(self.additemlist)
	end, -- showadditemlist = function
	showadditempopup = function(self)
		-- show list of  widget types that can be added to the list, and detect when one is clicked or dragged.
		if imgui.Button(label'addnewwidget') then imgui.OpenPopup'newwidgetpopup' end
		if imgui.BeginPopup'newwidgetpopup' then
			for index, itemname in ipairs(self.additemlist) do
				if imgui.Button(itemname .. '##newitem') and not self.dragactive then
					self.dragsource = widgets[itemname]
					self.newitem = true
					self.dragdest = #self + 1
				elseif self:detectdragstart(imgui.IsItemActive()) then
					self.dragsource = widgets[itemname]
					self.newitem = true
				end -- if imgui.Button(itemname .. '##newitem') and not self.dragactive
			end -- for index, itemname in ipairs(self.additemlist)
		imgui.EndPopup() end
	end, -- showadditempopup = function
	showitemeditor = function(self)
		local deletewidget = false
		if self.selected then
			if imgui.BeginChild('list item editor', -1, -1, true) then
				if imgui.BeginPopup('confirmdeletewidget' .. self.id, {'NoTitleBar', 'NoResize', 'NoMove', 'NoScrollBar', 'AlwaysAutoResize'}) then
					text(label'deletewidget' .. ' "' .. self[self.selected].longname .. '"?')
					if imgui.Button (languagetable.label.delete .. '##deletewidget') then
						deletewidget = true
						imgui.CloseCurrentPopup()
					end
					imgui.SameLine()
					if imgui.Button (languagetable.label.cancel .. '##deletewidget') then imgui.CloseCurrentPopup() end
				imgui.EndPopup() end
		
				if self == nil then print('self is nil') end
				
				if imgui.Button('delete widget') then
					imgui.OpenPopup('confirmdeletewidget' .. self.id)
				end
			
				self[self.selected]:edit()
			end imgui.EndChild()
		end -- if self.selected
		if deletewidget then
			table.remove(self, self.selected)
			self.selected = nil
		end -- if deletewidget
	end, -- showitemeditor = function
	display = function(self)
		for _, childwidget in ipairs(self.widgetlist) do
			childwidget:display()
		end
	end, -- display = function
} -- widgets.widgetlist = {...}
characterviewmodel = {
	additemlist = {},
	editparams = function(self)
		-- datasource editor
	end, -- editparams = function
	display = function(self)
	
	end, -- display = function
} -- rowviewmodel = {...}
setmetatable(characterviewmodel, {__index = function(self, key)
	local value = searchparents(key, {basewidget, lists.widgetlist})
	self[key] = value
	return value
end})
lists.gradient = {
	--[[ creating a widget
	+ new:
		* allocate memory (= {})
	+ restore:
	+ both:
		* setup inheritance
		* generate id
	]]
	--[[
	creating a gradient:
		+ new:
			* start with sensible minimal default values - .66 green, 0 red
		+ restore:
		+ both:
	]]
	firsttimeinit = function(self)
		baselist.firsttimeinit(self)
		self[1] = {.25, .75, .3, 1}
		self[2] = {.75, 0, 0, 1}
		self.levels = {.66, 0}
	end, -- firsttimeinit = function
	computepressure = function(self, startpoint, endpoint)
		local gapstart = startpoint
		-- local gapend = startpoint + 1
		-- local pressurelevels = {}
		local gapsize, gappressure
		local pressuresum = 0
		repeat
			gapsize = self.levels[gapstart] - self.levels[gapstart + 1]
			gappressure = huddata.minimumgradientlevelseparation - gapsize
			-- table.insert(pressurelevels, gappressure)
			pressuresum = pressuresum + gappressure
			gapstart = gapstart + 1
		until gapstart == endpoint
		-- for _, pressurelevel in ipairs(pressurelevels) do
			-- pressuresum = pressuresum + pressurelevel
		-- end -- for _, pressurelevel in ipairs(pressurelevels)
		-- return pressuresum / #pressurelevels
		return pressuresum
	end, -- computelevelpressure = function
	distributealllevelsevenly = function(self)
		local spacing = 1 / (1 - #self )
		local index = 1
		for level = 1, 0, spacing do
			self.levels[index] = level
			index = index + 1
		end -- for level = 1, 0, spacing
	end, -- distributealllevelsevenly = function
	separatelevels = function(self, startpoint)
		if startpoint == 0 or startpoint == #self then
			-- easy, just push away from the beginning or end.
		else
			-- tricky - figure out where there's lower pressure, and push in that direction - or in both, if there's low pressure in both directions.
		end -- if startpoint == 0 or startpoint == #self
	end, -- separatelevels = function
	-- maximumgradientlevels = 6, minimumgradientlevelseparation = .05
	processdrop = function(self)
		if not self.newitem then
			-- when *moving* a color/level, give the user the option of either deleting the old level and creating a new one at the destination, or moving only the color, shifting other colors over relative to the levels, and leaving the levels as they are.
			self.selected = utility.listmove(self, self.dragsource, self.dragdest, self.selected)
		else--if #self < huddata.maximumgradientlevels then -- if not self.newitem
			if self.dragdest == #self + 1 then
				-- if self.levels[#self] == 0 then
					-- self.levels[#self] = self.levels[#self - 1] / 2
				-- end -- if self.levels[#self] == 0
				-- table.insert(self, self.newitem)
				table.insert(self.levels, #self, self.levels[#self - 1] / 2)
			elseif self.dragdest == 1 then
				if self.levels[1] == 1 then
					self.levels[1] = (1 + self.levels[2]) / 2
				end -- if self.levels[1] == 1
				-- table.insert(self, 1, self.newitem)
				table.insert(self.levels, 1, 1)
			else
				-- table.insert(self, self.dragdest, self.newitem)
				table.insert(self.levels, self.dragdest, (self.levels[self.dragdest - 1] + self.levels[self.dragdest]) / 2)
			end -- if self.dragdest == #self
			-- when the user chooses to add a new color/level at the end (past 0) or at the beginning, if the first level is 1, then automatically create a new level between the one being replaced and the next one, and just shift over the one being replaced
			
			-- probably should limit a gradient to a specific maximum number of levels - but this could easily be a global option that could be changed.
			-- also, enforce a minimum distance between levels - again, this amount should be a customizable global option.
			-- these two things are maybe less important than i thought, and the second one is a pain in the ass to implement.
			
		-- self.selected = utility.listadd(self, newitem, self.dragdest, self.selected)
			table.insert(self, self.dragdest, utility.listcopy(self.dragsource))
			self.selected = self.dragdest
		end -- if not self.newitem
		self.changed = true
	end, -- processdrop = function
	listitem = function(self, index)
		local minlevel, maxlevel
		if index == 1 then maxlevel = 1
		else maxlevel = self.levels[index - 1] - .01
		end -- if index == 1
		if index == #self then minlevel = 0
		else minlevel = self.levels[index + 1] + .01
		end -- if index == #self
		
		imgui.BeginGroup()
		imgui.PushID(self.id .. index)
		local clicked = logpcall(imgui.ColorButton, {'lists.gradient:listitem(index)', index}, unpack(self[index])) -- should activate color editor when clicked
		imgui.PopID()
		local active = imgui.IsItemActive()
		if clicked then
			if self.selected == index then self.selected = nil else self.selected = index end
		end -- if clicked
		imgui.PushItemWidth(36)
		local changed, newvalue = logpcall(imgui.DragFloat, 'lists.gradient:listitem(index)', '##level' .. self.id .. index, self.levels[index], .001, minlevel, maxlevel, string.format('%.1f', self.levels[index]))
		imgui.PopItemWidth()
		if changed then self.levels[index] = newvalue end
		--slownumbereditor (level)
		imgui.EndGroup()
		return active
	end, -- listitem = function
	showadditemlist = function(self)
		local itemwidth
		for index, presetcolor in ipairs(huddata.presetcolors) do
			imgui.PushID(self.id .. index)
			local clicked = logpcall(imgui.ColorButton, 'lists.gradient:showadditemlist() - preset color button',unpack(presetcolor))
			imgui.PopID()
			if not itemwidth then itemwidth, _ = imgui.GetItemRectSize() end
			if clicked and not self.dragactive then
				if self.selected then
					self[self.selected] = utility.listcopy(presetcolor)
				end -- if self.selected
			elseif self:detectdragstart(imgui.IsItemActive()) then
				self.dragsource = presetcolor
				self.newitem = true
			end -- if imgui.ColorButton(unpack(presetcolor)) and not self.dragactive
			imgui.SameLine()
			local windowposx = imgui.GetWindowPos()
			local cursorposx = imgui.GetCursorPosX()
			local availwidth = imgui.GetContentRegionAvailWidth()
			if availwidth < itemwidth then imgui.NewLine() end
			-- if cursorposx - windowposx + itemwidth > availwidth then imgui.NewLine() end
			neondebug.log('imgui.GetCursorPosX(): ' .. cursorposx .. '\nitemwidth: ' .. itemwidth .. '\nimgui.GetContentRegionAvailWidth(): ' .. availwidth, 'main')
		end -- for index, presetcolor in ipairs(huddata.presetcolors)
		imgui.NewLine()
	end, -- showadditemlist = function
	showitemeditor = function(self)
		local deletelevel = false
		if self.selected then
			if imgui.BeginChild('color level editor', -1, 36, true) then
				imgui.PushID'selectedcolorbutton'
				logpcall(imgui.ColorButton, 'lists.gradient:showitemeditor() - selected level colorbutton', unpack(self[self.selected]))
				imgui.PopID()
				imgui.SameLine()
				for i = 1, 4 do
					imgui.PushItemWidth(36)
					local changed, newvalue = logpcall(imgui.DragFloat, 'lists.gradient:showitemeditor() - color component dragfloat', '##coloredit' .. self.id .. i, self[self.selected][i] * 255, 1, 0, 255, colorlabels[i] .. ':%.0f')
					imgui.PopItemWidth()
					if changed then self[self.selected][i] = newvalue / 255 end
					imgui.SameLine()
				end -- for i = 1, 4
				
				if self.selected > 1 and self.selected < #self and imgui.Button(label'deletecolorlevel') then
					imgui.OpenPopup('confirmdeletecolorlevel' .. self.id)
				end
				
				if imgui.BeginPopup('confirmdeletecolorlevel' .. self.id, {'NoTitleBar', 'NoResize', 'NoMove', 'NoScrollBar', 'AlwaysAutoResize'}) then
					local levelpercent = string.format('%.1f%%%%', self.levels[self.selected] * 100)
					local colordesc = {}
					for i = 1, 4 do colordesc[i] = tonumber(string.format('%u', self[self.selected][i] * 255)) end
					text(label'deletecolorlevel' .. ' (' .. levelpercent .. ')?\n')
					imgui.PushID'deletecolorlevelpreview'
						logpcall(imgui.ColorButton, 'lists.gradient:showitemeditor() - deletelevel colorbutton', unpack(self[self.selected]))
					imgui.PopID()
					imgui.SameLine()
					text(utility.serialize(colordesc ))
					if imgui.Button(label'delete' .. '##deletecolorlevel') then
						deletelevel = true
						imgui.CloseCurrentPopup()
					end -- if imgui.Button(label'delete' .. '##deletecolorlevel')
					imgui.SameLine()
					if imgui.Button(label'cancel' .. '##deletecolorlevel') then imgui.CloseCurrentPopup() end
				imgui.EndPopup() end
				
			end imgui.EndChild()
		end -- if self.selected
		if deletelevel then
			table.remove(self, self.selected)
			table.remove(self.levels, self.selected)
			self.selected = nil
		end -- if deletelevel
	end, -- showitemeditor = function
} -- widgets.gradient = {...}
for _, widgetclass in pairs(widgets) do
	setmetatable(widgetclass, basewidget)
	widgetclass.__index = widgetclass
end -- for _, widgetclass in pairs(widgets)
for _, listclass in pairs(lists) do
	setmetatable(listclass, baselist)
	listclass.__index = listclass
end -- for _, listclass in pairs(lists)
--------------------------------------------------------------------------------
local globaloptions = {}
local function initglobaloptions()
	globaloptions = {
		booleaneditor'compactmainwindow',
		coloreditor'defaultprogressbarcolor',
		booleaneditor'showwidgettype',
		-- booleaneditor'autoeditnewwidgets',
		-- slownumbereditor('longinterval', 1, 10, 1), -- this might be completely pointless...
		-- numbereditor('offscreenx', 0, 50, 1),
		-- numbereditor('offscreeny', 0, 50, 1),
		numbereditor('inputtextwidth', 24, 420, 1, '%u'),
		-- numbereditor('dragtargetmargin', 0, 144, 1, '%u'),
		slownumbereditor('dragthreshold', 2, 24, 1),
		booleaneditor'defaultautoresize',
		optionalparametereditor{
			param = 'defaulttextcolor',
			editlabel = 'set default text color',
			resetlabel = 'reset',
			editfunction = coloreditor'defaulttextcolor',
			defaultvalue = function() return {.8, .8, .8, 1} end,
		}, -- editdefaulttextcolor = optionalparametereditor{...}
		optionalparametereditor{
			param = 'defaultbgcolor',
			editlabel = 'set default background color',
			resetlabel = 'reset',
			editfunction = coloreditor'defaultbgcolor',
			defaultvalue = function() return {.2, .2, .2, .5} end,
		}, -- editdefaultbgcolor = optionalparametereditor{...}
		-- basewidget.fontscaleeditor,
		-- booleaneditor'showpixels',
		numbereditor('smallstep', .01, 1, .01, '%.2f'),
		numbereditor('bigstep', 1, 50, 1, '%.0f'),
	} -- globaloptions = {...}
end -- local function initglobaloptions
local function presentglobaloptionswindow()
	imgui.SetNextWindowSize(500, 300, 'FirstUseEver')
	local success
	success, huddata.showglobaloptions = imgui.Begin('global options', true)
		if not success then imgui.End() return end
		for index, optioneditor in ipairs(globaloptions) do
			neondebug.log('showing global option # ' .. index, 'main')
			optioneditor(huddata)
		end
	imgui.End()
	-- return windowopen
end -- local function presentglobaloptionswindow -------------------------------
local mainmenuwidgets = {}
local statuspopup
local function showstatuspopup()
	if statuspopup then
		imgui.OpenPopup'statuspopup'
		statuspopup = false
	end
	if imgui.BeginPopup'statuspopup' then
		text(status)
		if imgui.Button(label'close') then imgui.CloseCurrentPopup() end
	imgui.EndPopup() end -- if imgui.BeginPopup'statuspopup'
end -- local function showstatuspopup
local function saveprofile()
	utility.savetable('profile', huddata)
	status = os.date('%F | %T\n' .. lookup('message', 'savesuccessful'))
	statuspopup = true
end -- local function saveprofile
local function showsavebutton()
	if imgui.Button(label'saveprofile') then saveprofile() end
	showstatuspopup()
end -- local function showsavebutton
local mainmenu
local function initmainmenu()
	mainmenu = {
		{label'saveprofile', saveprofile},
		{label'showglobaloptions', function()
			huddata.showglobaloptions = not huddata.showglobaloptions
		end},
		{label'showdebugwindow', function()
			huddata.showdebugwindow = not huddata.showdebugwindow
		end},
		{label'showstyleeditor', function()
			showstyleeditorwindow = not showstyleeditorwindow
		end},
	} -- mainmenu = {...}
end -- local function initmainmenu
local function initmainmenuwidgets()
	mainmenuwidgets = {
		simpletogglebutton('showglobaloptions'),
		simpletogglebutton('showdebugwindow'),
		showsavebutton,
	} -- mainmenuwidgets = {...}
end -- local function initmainmenuwidgets
local function changefocus(newfocus)
	huddata.previousfocus, huddata.focus = huddata.focus, newfocus
end -- local function changefocus
local function revertfocus()
	huddata.focus, huddata.previousfocus = huddata.previousfocus, huddata.focus
end -- local function revertfocus
local function showmainmenu()
	if imgui.Button(label'addnewwindow') then
		table.insert(huddata.windowlist, createwidget(customwindow))
		huddata.selectedwindow = #huddata.windowlist
		imgui.OpenPopup'namenewwindow'
	end -- if imgui.Button('add new window')
	if imgui.BeginPopup'namenewwindow' then
		text(label'newwindow')
		huddata.windowlist[huddata.selectedwindow]:titleeditor()
		if imgui.Button(label'ok') then imgui.CloseCurrentPopup() end
	imgui.EndPopup() end
end -- local function showmainmenu ---------------------------------------------
local function showdeletewindowbutton()
	if huddata.selectedwindow and imgui.Button(label'deletewindow') then
		imgui.OpenPopup('confirmdeletewindow')
	end
	if imgui.BeginPopup'confirmdeletewindow' then
		imgui.Text(label'deletewindow' .. ' "' .. huddata.windowlist[huddata.selectedwindow].title .. '"?')
		if imgui.Button(label'delete' .. '##deletewindow') then
			freeid(huddata.windowlist[huddata.selectedwindow].id)
			table.remove(huddata.windowlist, huddata.selectedwindow)
			huddata.selectedwindow = nil
			imgui.CloseCurrentPopup()
		end -- if imgui.Button(label'delete' .. '##deletewindow')
		imgui.SameLine()
		if imgui.Button 'cancel##deletewindow' then imgui.CloseCurrentPopup() end
	imgui.EndPopup() end
end -- local function showdeletewindowbutton -----------------------------------
local function showwindowlist()
	for i = 1, #huddata.windowlist do
		local window = huddata.windowlist[i]
		local selected = huddata.selectedwindow == i
		if window:button(window.title .. '##' .. i, selected) then
			if selected then huddata.selectedwindow = nil
			else huddata.selectedwindow = i
			end -- if selected
		end -- if window:button
	end -- for i = 1, #huddata.windowlist
	if imgui.Button(label'addnewwindow') then
		table.insert(huddata.windowlist, createwidget(customwindow))
	end -- if imgui.Button(label'addnewwindow')
end -- local function showwindowlist -------------------------------------------
local function presentmainwindow()
	neondebug.alwayslog('start presentmainwindow()', 'instantgamecrash')
	imgui.SetNextWindowSize(600,300,'FirstUseEver')
	neondebug.alwayslog('successfully called imgui.SetNextWindowSize(...)', 'instantgamecrash')
	local success
	success, huddata.showmainwindow = imgui.Begin('custom hud editor', true)
		if not success then
			imgui.End()
			return
		end
		neondebug.alwayslog('main window imgui.Begin success', 'instantgamecrash')
		if imgui.BeginChild('window list and main menu', 150 * huddata.fontscale, -1, true) then
			showwindowlist()
			neondebug.alwayslog('showed window list', 'instantgamecrash')
			
			imgui.Separator()
			
			showstatuspopup()
			
			for _, item in ipairs(mainmenu) do
				if imgui.Button(item[1]) then item[2]() end
			end -- for _, item in mainmenu
			neondebug.alwayslog('showed main menu buttons', 'instantgamecrash')
			
			-- writelayoutvalues = false
			writelayoutvaluesthisframe = imgui.Button'write layout values'
			
		end imgui.EndChild()
		neondebug.alwayslog('showed window list and main menu', 'instantgamecrash')
		imgui.SameLine()
		imgui.BeginChild('window editor', -1, -1, true)
		neondebug.alwayslog('start window editor', 'instantgamecrash')
			if huddata.selectedwindow then
				huddata.windowlist[huddata.selectedwindow]:edit()
			end -- if huddata.selectedwindow
		imgui.EndChild()
		neondebug.alwayslog('showed window editor', 'instantgamecrash')
		
		-- imgui.BeginChild('status bar', -1, statusheight, true)
			-- imgui.Text(status)
		-- imgui.EndChild()
	imgui.End()
	neondebug.alwayslog('end presentmainwindow()', 'instantgamecrash')
end -- local function presentmainwindow ----------------------------------------
local function presentmainwindowcompact()
	imgui.SetNextWindowSize(400,300,'FirstUseEver')
	local success
	success, huddata.showmainwindow = imgui.Begin('custom hud editor', true, {'MenuBar'})
	if success then
		if imgui.BeginMenuBar() then
			if imgui.BeginMenu(label'customhud') then
				for _, item in ipairs(mainmenu) do
					if imgui.MenuItem(item[1]) then item[2]() end
				end -- for _, item in mainmenu
			imgui.EndMenu() end
			if imgui.BeginMenu(label'windowlist', #huddata.windowlist > 0) then
				for i = 1, #huddata.windowlist do
					local window = huddata.windowlist[i]
					local selected = huddata.selectedwindow == i
					if imgui.MenuItem(window.title .. '##' .. i, nil, selected) then
						if selected then huddata.selectedwindow = nil
						else huddata.selectedwindow = i
						end -- if selected
					end -- if imgui.MenuItem
				end -- for i = 1, #huddata.windowlist
				imgui.Separator()
			imgui.EndMenu() end -- window list
		imgui.EndMenuBar() end
		showstatuspopup()
		if imgui.BeginChild("selected window's widget list", huddata.sidebarwidth or 150 * huddata.fontscale, -1, true) then
			imgui.Separator()
			if huddata.selectedwindow then
			 huddata.windowlist[huddata.selectedwindow].widgetlist:editvertical()
			 huddata.windowlist[huddata.selectedwindow].widgetlist:showadditempopup()
			end -- if huddata.selectedwindow
		end -- if imgui.BeginChild("window list and selected window's widget list" ...)
		imgui.EndChild()
	end -- if success
	imgui.End()
end -- local function presentmainwindowcompact ---------------------------------
local function presentfirsttimedialog()
	if not huddata.selectedlanguage then
		createwidget(customwindow)
	end
end -- local function presentfirsttimedialog
local function loadlanguage()
	initglobaloptions()
	neondebug.log('finished initglobaloptions()', 'main')
	initmainmenu()
	neondebug.log('finished initmainmenuwidgets()', 'main')
	-- labeleditorlabel = languagetable.label.label
	-- labeltypelabels = languagetable.label.labeltypes
	colorlabels = languagetable.label.rgba
	neondebug.log('successfully loaded label tables (labeleditor, labeltypes, colors)', 'main')
	basewidget:initeditors()
	neondebug.log('finished basewidget:initeditors()', 'main')
	customwindow:initeditors()
	neondebug.log('finished customwindow:initeditors()', 'main')
	for widgetname, widget in pairs(widgets) do
		widget:initeditors()
		neondebug.log('finished ' .. widgetname .. ':initeditors()', 'main')
	end -- for _, widget in pairs(widgets)
end -- local function loadlanguage
local function initnewprofile()
	huddata = {windowlist = {}, showmainwindow = true, showwidgettype = true, --[[dragtargetmargin = 48, longinterval = 1, autoeditnewwidgets = true, offscreenx = 0, offscreeny = 0, ]]fontscale = 1, inputtextwidth = 96, dragthreshold = 24, defaulttextcolor = {.8, .8, .8, 1}, defaultbgcolor = {0, 0, 0, .5}, defaultprogressbarcolor = {.2, .2, 1, 1}, defaultautoresize = true, bigstep = 5, smallstep = .2, maximumgradientlevels = 6, minimumgradientlevelseparation = .05}
	huddata.presetcolors = {{0.5, 0, 0, 1, }, {1, 0, 0, 1, }, {0.9, 0.1, 0.29, 1, }, {0.98, 0.75, 0.75, 1, }, {0.67, 0.43, 0.16, 1, }, {0.96, 0.51, 0.19, 1, }, {1, 0.84, 0.71, 1, }, {0.5, 0.5, 0, 1, }, {1, 0.88, 0.1, 1, }, {1, 0.98, 0.78, 1, }, {0.24, 0.71, 0.29, 1, }, {0.82, 0.96, 0.24, 1, }, {0, 1, 0, 1, }, {0.67, 1, 0.76, 1, }, {0, 0.5, 0.5, 1, }, {0.27, 0.94, 0.94, 1, }, {0, 0, 0.5, 1, }, {0, 0, 1, 1, }, {0, 0.51, 0.78, 1, }, {0.57, 0.12, 0.71, 1, }, {0.94, 0.2, 0.9, 1, }, {0.9, 0.75, 1, 1, }, {0, 0, 0, 1, }, {0.5, 0.5, 0.5, 1, }, {1, 1, 1, 1, },}-- huddata.presetcolors = {...}
end -- local function initnewprofile
local function loaddata()
	neondebug.log('starting loaddata()', 'main')
	
	local neww, newh = psodata.getgamewindowsize()
	if neww > 0 then
		neondebug.log('successfully retrieved window size', 'main')
		statusheight = imgui.GetTextLineHeightWithSpacing() * 2
		gamewindowwidth = neww
		gamewindowheight = newh
		
		neondebug.log('attempting to load languagetable...', 'main')
		languagetable = require'custom hud.languages.english'
		loadlanguage()
		neondebug.log('successfully loaded languagetable', 'main')
		
		-- huddata = utility.loadtable('profile')
		huddata = logpcall(require, 'loaddata() - attempting to load saved profile', 'custom hud.profile')
		if huddata then
			neondebug.log('successfully loaded saved profile', 'main')
			for _, window in ipairs(huddata.windowlist) do
				restorewidget(window, customwindow)
				-- window.init(thiswindow)
			end
		else
			neondebug.log('no saved profile found; initializing new profile', 'main')
			initnewprofile()
		end -- if huddata
		
		updatexboundary()
		updateyboundary()
		ready = true
		return true
	end -- if neww > 0
	neondebug.log('finished loaddata()', 'main')
end -- local function loaddata--------------------------------------------------
table.insert(tasks, loaddata)
local function present()
	neondebug.log('starting present()', 'main')
	
	local now = os.time()
	neondebug.log('retrieved current system time', 'main')
	
	local interval = huddata.longinterval or 1
	
	neondebug.log('starting tasks loop', 'main')
	if #tasks > 0 and os.difftime(now, lasttime) >= interval then
		local taskindex = 1
		repeat
			neondebug.log('attempting task index ' .. taskindex, 'main')
			if tasks[taskindex]() then
				table.remove(tasks, taskindex)
			else
				taskindex = taskindex + 1
			end
		until taskindex > #tasks
		lasttime = now
	end
	neondebug.log('finished tasks loop', 'main')
	
	if not ready then return end
	
	psodata.retrievepsodata()
	neondebug.log('finished psodata.retrievepsodata()', 'main')
	
	if huddata.showmainwindow then
		if huddata.compactmainwindow then
			presentmainwindowcompact()
		else
			presentmainwindow()
		end -- if huddata.compactmainwindow
	end -- if huddata.showmainwindow
	neondebug.log('showed main window (or not) successfully', 'main')
	if huddata.showdebugwindow then
		huddata.showdebugwindow = neondebug.present()
	end
	neondebug.log('showed debug window (or not) successfully', 'main')
	if huddata.showglobaloptions then
		presentglobaloptionswindow()
	end
	neondebug.log('showed global options window (or not) successfully', 'main')
	if showstyleeditorwindow then imgui.ShowStyleEditor() end
	for _, window in ipairs(huddata.windowlist) do
		window:display()
	end
	neondebug.log('finished displaying window list; finished present()', 'main')
end -- local function present
local function dirtest()
	local pwd = io.popen([[dir "addons\custom hud" /b]])
	for dir in pwd:lines() do
		print(dir)
	end
	pwd:close()
end -- local function dirtest
local function init()
	-- dirtest()
	neondebug.log('starting init()', 'main')
	
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
	
	
	core_mainmenu.add_button('custom hud', function()
		huddata.showmainwindow = not huddata.showmainwindow
		end)
	
	-- local actuallythere = utility.tablecombolist(imgui)
	-- utility.savestring(os.date('imgui functions available %F '), utility.serialize(actuallythere))
	
	neondebug.log('finished init(), returning', 'main')
	return
		{
		name = 'custom hud',
		version = '0.6',
		author = 'izumidaye',
		description = 'build your own customized hud',
		present = present,
		}
end -- local function init -----------------------------------------------------
--------------------------------------------------------------------------------
return {__addon = {init = init}}
