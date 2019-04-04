local utility = require('custom hud.utility')
local updatewindowoption = utility.updatewindowoption
local paramtype = require('custom hud.paramtype')
local typedef = paramtype.typedef
local datatype = paramtype.datatype
local default = require('custom hud.default')
local id = require('custom hud.id')
local neondebug = require('custom hud.neondebug')

local datasource = {}
local globaloptions
local widget = {}
local gamewindowwidth, gamewindowheight
local boundary
--------------------------------------------------------------------------------
local function updatename(self, paramname)
	local newname = self.map[paramname] or self[paramname]
	self['long name'] = self.widgettype .. ': ' .. newname
	self['short name'] = datasource.shortname[newname] or newname
end -- local function updatename
--------------------------------------------------------------------------------
local function combobox(data, key, combolist)
	imgui.PushItemWidth(8 + (8 * combolist.longest))
		local changed, newvalue = imgui.Combo('##' .. key, combolist[data[key]], combolist, #combolist)
	imgui.PopItemWidth()
	if changed then data[key] = combolist[newvalue] end
	return changed
end
--------------------------------------------------------------------------------
local function paramsourceeditor(self, paramname)
	-- neondebug.log('begin paramsourceditor for: ' .. paramname, 5, 'paramedit')
	
	local typedef = typedef(paramname)
	
	if typedef.optional then
		-- neondebug.log('edit ' .. paramname .. ': clear optional value button', 5, 'paramedit')
		imgui.SameLine()
		if imgui.Button('clear##' .. paramname) then
			self[paramname] = nil
			self.map[paramname] = nil
		end
	else
		-- neondebug.log('edit ' .. paramname .. ': not optional.', 5, 'paramedit')
	end
	
	if self.fieldcombolist then
		if typedef.fieldsource then
			-- neondebug.log('edit ' .. paramname .. ': field source', 5, 'paramedit')
			imgui.SameLine()
			imgui.Text('source:')
			imgui.SameLine()
			if self.map[paramname] then
				-- neondebug.log('edit ' .. paramname .. ': field combo box', 5, 'paramedit')
				if combobox(self.map, paramname, self.fieldcombolist)
				and typedef.updatename then
					updatename(self, paramname)
				end
			else
				-- neondebug.log('edit ' .. paramname .. ': \'use list field\' button', 5, 'paramedit')
				if imgui.Button('use list field##' .. paramname) then
					self.map[paramname] = self.fieldcombolist[1]
					if typedef.updatename then updatename(self, paramname) end
				end
			end -- if self.map[paramname]
		else
			-- neondebug.log('edit ' .. paramname .. ': no field source.', 5, 'paramedit')
		end -- if typedef.fieldsource
		
	elseif typedef.functionsource then
		-- neondebug.log('edit ' .. paramname .. ': function source editor', 5, 'paramedit')
		imgui.SameLine()
		if self.map[paramname] then
			if combobox(self.map, paramname, datasource.combolist[typedef.datatype]) and typedef.updatename then
				updatename(self, paramname)
			end
		else
			if imgui.Button('use game data##' .. paramname) then
				self.map[paramname] = datasource.combolist[typedef.datatype][1]
				if typedef.updatename then updatename(self, paramname) end
			end
		end -- if self.map[paramname]
	else
		-- neondebug.log('edit ' .. paramname .. ': no function source.', 5, 'paramedit')
	end -- if self.fieldcombolist
	
	if typedef.staticsource and self.map[paramname] then
		-- neondebug.log('edit ' .. paramname .. ': \'use static value\' button', 5, 'paramedit')
		if imgui.Button('use static value##' .. paramname) then
			self.map[paramname] = nil
			self[paramname] = typedef.default()
			if typedef.updatename then updatename(self, paramname) end
		end
	end
	
	-- neondebug.log('edit ' .. paramname .. ': paramsourceeditor end.', 5, 'paramedit')
end -- local function paramsourceeditor
--------------------------------------------------------------------------------
local parameditor = {}
--------------------------------------------------------------------------------
parameditor['string'] = function(self, paramname)
	-- neondebug.log('begin string edit: ' .. paramname, 5, 'paramedit')
	imgui.Text(paramname)
	imgui.SameLine()
	local changed, newvalue =
		imgui.InputText('##' .. paramname, self[paramname], 72)
	if changed then
		self[paramname] = newvalue
		if typedef(paramname).updatename then
			updatename(self, paramname)
		end
	end
	
	paramsourceeditor(self, paramname)
	
	-- neondebug.log('edit string ' .. paramname .. ': end', 5, 'paramedit')
end -- parameditor['string'] = function
--------------------------------------------------------------------------------
parameditor['number'] = function(self, paramname)
	local thistype = typedef(paramname)
	local displayvalue
	if thistype.scale then
		displayvalue = utility.round(self[paramname] * thistype.scale)
		-- displayvalue = string.format
			-- {'%s', utility.round(self[paramname] * thistype.scale)}
			-- not sure if i need to convert to string
	else
		displayvalue = self[paramname]
	end -- if thistype.scale
	
	imgui.Text(paramname .. ':')
	imgui.SameLine()
	imgui.PushItemWidth(72)
		
		local changed, newvalue = imgui.DragFloat
			{
			'##' .. paramname,
			self[paramname],
			thistype.largestep,
			thistype.minimum,
			thistype.maximum,
			displayvalue
			}
		if changed then self[paramname] = newvalue end
		imgui.SameLine()
		
		changed, newvalue = imgui.DragFloat
			{
			'##finetune' .. paramname,
			self[paramname],
			thistype.smallstep,
			thistype.minimum,
			thistype.maximum,
			'fine tune'
			}
		if changed then self[paramname] = newvalue end
		
	imgui.PopItemWidth()
	
	paramsourceeditor(self, paramname)
end -- parameditor['number'] = function
--------------------------------------------------------------------------------
parameditor['slow number'] = function(self, paramname)
	neondebug.log('edit ' .. paramname .. ': begin slow number editor', 5, 'paramedit')
	
	local thistype = typedef(paramname)
	if thistype then
		neondebug.log('edit ' .. paramname .. ': typedef found.', 5, 'paramedit')
	else
		neondebug.log('edit ' .. paramname .. ': typedef not found.', 5, 'paramedit')
	end
	
	imgui.Text(paramname)
	neondebug.log('edit ' .. paramname .. ': displayed label.', 5, 'paramedit')
	imgui.SameLine()
	
	imgui.PushItemWidth(96)
		local changed, newvalue = imgui.InputFloat('##' .. paramname,
			self[paramname], thistype.step, 1, 1, thistype.displayformat)
	imgui.PopItemWidth()
	neondebug.log('edit ' .. paramname .. ': displayed imgui.InputFloat(...)', 5, 'paramedit')
	if changed then
		if newvalue < thistype.minimum then
			newvalue = thistype.minimum
		elseif newvalue > thistype.maximum then
			newvalue = thistype.maximum
		end
		self[paramname] = newvalue
	end
	
	neondebug.log('edit ' .. paramname .. ': end slow number editor', 5, 'paramedit')
end -- parameditor['slow number'] = function
--------------------------------------------------------------------------------
parameditor['boolean'] = function(self, paramname)
	local thistype = typedef(paramname)
	-- if thistype.disableif and self[thistype.disableif] then
		-- imgui.TextDisabled(paramname)
	-- else
		local changed, newvalue = imgui.Checkbox(paramname, self[paramname])
		if changed then
			self[paramname] = newvalue
			if thistype.update then thistype.update(self) end
		end
	-- end
	
	-- paramsourceeditor(self, paramname)
	-- no reason to use game data for a boolean parameter?
end -- parameditor['boolean'] = function
--------------------------------------------------------------------------------
parameditor['progress'] = function(self, paramname)
	imgui.Text(paramname)
	imgui.SameLine()
	
	paramsourceeditor(self, paramname)
end -- parameditor['progress'] = function
--------------------------------------------------------------------------------
local colorlabels = {'r', 'g', 'b', 'a'}
parameditor['color'] = function(self, paramname)
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
end -- parameditor['color'] = function
--------------------------------------------------------------------------------
local function calcdragdest(targetlist, targetvalue)
	for index = 1, #targetlist do
		if targetvalue < targetlist[index] then return index end
	end
	return #targetlist + 1
end

parameditor['list'] = function(self, paramname)
	local list = self[paramname]
	local thistype = typedef(paramname)
	-- local dragthisframe = false
	local lastitempos
	
	if list.changed then
		list.dragtarget.top, list.dragtarget.left =
			imgui.GetCursorScreenPos()
			
		lastitempos = list.dragtarget.left + 5
		
		local default = default(paramname)
		list.buttonedges = {}
		list.buttonedges[1] = list.dragtarget.left + default.buttonedges[1]
		list.buttoncenters = default.buttoncenters
		
		list.dragtarget.top =
			list.dragtarget.top - thistype.dragtargetmargin
			
		list.dragtarget.left =
			list.dragtarget.left - thistype.dragtargetmargin
	end -- if list.changed
	
	if imgui.BeginChild('item list##' .. self.id, -1, 20, true) then
		if list.orientation == 'horizontal' then imgui.Dummy(0, 0) end
		for index, item in ipairs(list) do
			if list.orientation == 'horizontal' then imgui.SameLine() end
			
			if thistype.listitem(self, index, list.selected == index) then
				if list.selected == index then
					list.selected = nil
				else
					list.selected = index
				end -- if list.selected == index
			end -- if thistype.listitem
			
			if imgui.IsItemHovered() and not imgui.IsMouseDown(0) then
				imgui.SetTooltip(thistype.tooltip(self))
			end
			
			if list.changed then
				if list.orientation == 'horizontal' then
					local itemwidth, _ = imgui.GetItemRectSize()
					table.insert(list.buttoncenters, lastitempos + 8 + itemwidth / 2)
					lastitempos = lastitempos + itemwidth + 8
					table.insert(list.buttonedges, lastitempos + 3)
				else -- assume list.orientation == 'vertical'
					-- figure this out once everything else is working
				end -- if list.orientation == 'horizontal'
			end -- if list.changed
			
			if imgui.IsItemActive() and not list.dragsource then
				list.dragsource = index
			end
			
		end -- for index, item in ipairs(list)
	end imgui.EndChild()
	
	if list.changed then
		_, list.dragtarget.bottom = imgui.GetCursorScreenPos()
		list.dragtarget.bottom =
			list.dragtarget.bottom + thistype.dragtargetmargin
		list.changed = false
		if list.orientation == 'horizontal' then
			list.dragtarget.right =
				list.buttonedges[#list.buttonedges] + thistype.dragtargetmargin
		else -- assume list.orientation == 'vertical'
			-- figure this out once everything else is working
		end -- if list.orientation == 'horizontal'
		neondebug.log('dragtarget:\n\tleft: ' .. list.dragtarget.left .. '\n\tright: ' .. list.dragtarget.right .. '\n\ttop: ' .. list.dragtarget.top .. '\n\tbottom: ' .. list.dragtarget.bottom, 'add new widget to window')
	end -- if list.changed
	
	imgui.NewLine()
	for index, itemname in ipairs(self.additemlist) do
		imgui.SameLine()
		imgui.Button(itemname .. '##' .. self.id)
		if imgui.IsItemActive() and not list.dragsource then
			list.dragsource = itemname
			list.newitem = true
			neondebug.log('started dragging new widget: ' .. itemname, 'add new widget to window')
		end
	end
	
	if list.dragsource then
		if imgui.IsMouseDown(0) then
			local mousex, mousey = imgui.GetMousePos()
			
			if utility.iswithinrect({x=mousex, y=mousey}, list.dragtarget) then
				if list.orientation == 'horizontal' then
					list.dragdest = calcdragdest(list.buttoncenters, mousex)
					neondebug.log('dragdest: ' .. list.dragdest, 'add new widget to window')
				else
					-- figure this out once everything else is working
				end -- if list.orientation == 'horizontal'
			else
				list.dragdest = nil
			end -- if mouse position is within list.dragtarget
		else
			if list.dragdest then
				if list.newitem then
					neondebug.log('adding ' .. list.dragsource .. ' at list index ' .. list.dragdest, 'add new widget to window')
					list.selected = utility.listadd(list, widget.new(list.dragsource),
						list.dragdest, list.selected)
					list.newitem = false
				else
				list.selected = utility.listmove(list, list.dragsource, list.dragdest,
					list.selected)
				end
				list.changed = true
			end
			list.dragdest = nil
			list.dragsource = nil
		end -- if imgui.IsMouseDown(0)
	end -- if list.dragsource
	
	if list.selected then
		list[list.selected]:edit()
	end
	
end -- parameditor['list'] = function
--------------------------------------------------------------------------------
parameditor['color gradient'] = function(self, paramname)
	-- parameditor['color'](self, paramname)
end -- parameditor['color gradient'] = function
--------------------------------------------------------------------------------
parameditor['format table'] = function(self, paramname)

end -- parameditor['format table'] = function
--------------------------------------------------------------------------------
parameditor['window position and size'] = function(self, param)
	
end
--------------------------------------------------------------------------------
local function paramedit(self, param)
	parameditor[datatype(param)](self, param)
end
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
		['general'] = {'display value', 'show range', 'same line',},
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
		['bar color'] = {'dynamic bar color', 'bar color', 'bar gradient',},
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
widget.combolist = utility.tablecombolist(widgets)
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
		}, -- parameters = {...}
	
	firsttimeinit = function(self)
		-- still need to actually initialize widget list (i think? this might be it)
		self['widget list'] = default('widget list')
		
		self:init()
	end, -- init = function(self)
	
	additemlist = widget.combolist,
	
	init = function(self)
		self['widget list'].changed = true
		
		self.id = id.new()
		
		self['window options'] = {}
		updatewindowoption(self, not self['show titlebar'], 1, 'NoTitleBar')
		updatewindowoption(self, not self['resize with mouse'], 2, 'NoResize')
		updatewindowoption(self, not self['move with mouse'], 3, 'NoMove')
		updatewindowoption(self, not self['show scrollbar'], 4, 'NoScrollBar')
		updatewindowoption(self, self['auto resize'], 5, 'AlwaysAutoResize')
		
		self.layout = {}
		self.layout.w = utility.scale(self['position and size'].w, gamewindowwidth)
		self.layout.h = utility.scale(self['position and size'].h, gamewindowheight)
		self:updatelayoutx()
		self:updatelayouty()
		
		self.dontserialize['id'] = true
		self.dontserialize['window options'] = true
		self.dontserialize['layout'] = true
		self.dontserialize['show options'] = true
		
		local basicedit = self.edit
		self.edit = function(self)
			if self['show options'] then
				if imgui.Button('edit window contents' .. '##' .. self.id) then
					self['show options'] = false
				end
				basicedit(self)
			else
				if imgui.Button('edit window options' .. '##' .. self.id) then
					self['show options'] = true
				end
				paramedit(self, 'widget list')
			end -- if self['show options']
		end -- self.edit = function(self)
	end, -- restore = function(self)
	
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
		if (self['in lobby'] and datasource.currentlocation() == 'lobby')
		or (self['not in field'] and datasource.currentlocation() ~= 'field')
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
			
			imgui.SetWindowFontScale(self['font scale'] or globaloptions.fontscale)
			
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
local function editparamgroup(self, group, label)
	if imgui.TreeNode((label or group) .. '##' .. self.id) then
		-- neondebug.log('displaying parameter group: ' .. group, 5, 'widget')
		for _, param in ipairs(self.parameters[group]) do
			-- neondebug.log('displaying editor for ' .. group .. '.' .. param, 5, 'widget')
			if not (typedef(param).hideif and typedef(param).hideif(self)) then
				if self[param] ~= nil then
					paramedit(self, param)
				else
					if imgui.Button('edit ' .. param) then
						self[param] = default(param)
					end
				end
			end
			-- neondebug.log('displayed ' .. group .. '.' .. param, 5, 'widget')
		end
		-- neondebug.log('done displaying parameter group: ' .. group, 5, 'widget')
		imgui.TreePop()
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
function widget.restore(self)
	setmetatable(self, {__index = widgets[self.widgettype]})
	self.edit = edit
	self.dontserialize = default('dontserialize')
	if self.init then self:init() end
end
--------------------------------------------------------------------------------
widget.new = function(typename, fieldcombolist)
	-- neondebug.log('creating widget of type: ' .. typename, 5)
	
	local newwidget = {}
	setmetatable(newwidget, {__index = widgets[typename]})
	-- neondebug.log('new widget metatable set.', 5)
	
	newwidget.widgettype = typename
	newwidget.edit = edit
	newwidget.dontserialize = default('dontserialize')
	newwidget.fieldcombolist = fieldcombolist
	newwidget.map = {}
	-- neondebug.log('widgettype, edit, dontserialize, fieldcombolist, and map set.', 5)
	
	-- neondebug.log('beginning generic parameter initialization loop.', 5)
	for _, groupname in ipairs(newwidget.parameters) do
		for _, param in ipairs(newwidget.parameters[groupname]) do
			
			-- neondebug.log('next parameter: ' .. param, 5)
			
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
				
				-- neondebug.log(param .. ' initialized to default: ' .. utility.serialize(newwidget[param]), 5, 'widget')
				
			end -- if not thistype.optional
		end -- for _, param in ipairs(newwidget.parameters[groupname])
	end -- for _, groupname in ipairs(newwidget.parameters)
	-- neondebug.log('completed generic parameter initialization loop.', 5)
	
	if newwidget.firsttimeinit then
		-- neondebug.log('starting ' .. typename .. ' specific init.', 5)
		newwidget:firsttimeinit()
		-- neondebug.log(typename .. ' specific init complete.', 5, 'widget')
	end
	
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
	boundary = {}
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
