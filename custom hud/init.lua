--[[
PSOBB Dynamic Info Addon
Catherine S (IzumiDaye/NeonLuna)
2018-10-05
]]

local core_mainmenu = require('core_mainmenu')
local neondebug = require('custom hud.neondebug')
local psodata = require('custom hud.psodata')
local utility = require('custom hud.utility')
local widget = require('custom hud.widget')
-- neondebug.update('this is a test', 'wow')
neondebug.enablelogging()

local replacements =
	{
	
	}

local requireddefaults =
	{
	['editindex'] = -1,
	}

-- local checkMemoryOffset = 0

local huddata
-- 'huddata' will be overwritten in init(), so initializing here doesn't work

local windownames

local usedids
local freedids

local function newid()
	local result
	if #freedids > 0 then
		result = table.remove(freedids, 1)
	else
		result = #usedids + 1
	end
	usedids[result] = true
	return result
end

local function freeid(id)
	table.insert(freedids, id)
	usedids[id] = nil
end

-- position and size values are stored as percentages; these functions scale those values based on the current game window size.
local function scalex(value, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return round((value / 100) * psodata.screenWidth * offset)
end

local function scaley(value, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return round((value / 100) * psodata.screenHeight * offset)
end

local function unscalex(value, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return value / psodata.screenWidth * 100 / offset
end

local function unscaley(value, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return value / psodata.screenHeight * 100 / offset
end

local function savetable(filename, tabletosave)
-- saves current HUD configuration to disk as a runnable lua script.
	
	local outputstring = 'return\n' .. utility.serialize(tabletosave)
	
	local file = io.open('addons/custom hud/' .. filename .. '.lua', 'w')
	if file then
		io.output(file)
		io.write(outputstring)
		io.close(file)
	end
end

local function loadtable(filename)
-- loads table from a lua file if the file returns a table when run
	local success, tabledata = pcall(require, 'custom hud.' .. filename)
	if success then return tabledata end
end

do --define widgetConfig functions

	widgetConfig.colorGradient = function(paramname, paramlist, req)
		local gradientList = paramlist[paramname]
		imgui.Text(paramname)
		imgui.SameLine()
		if req == 'optional' then
			if imgui.Button('clear##' .. paramname) then paramlist[paramname]=nil end
		end
		if not gradientList then
			imgui.SameLine()
			if imgui.Button('edit##' .. paramname) then
				paramlist[paramname] = {{0,{0, 0, 0, 1}},{1,{1, 1, 1, 1}}}
			end
		else -- not gradientList
			local addNew, addIndex = false, 1
			local deleteLevel, deleteIndex = false, 1
			local step = 0.01
			local gfs = paramlist['global font scale'] or 1
			-- imgui.PushItemWidth(40 * gfs)
			
			imgui.Text('Value >=')
			for i = 1,4 do
				imgui.SameLine((72 + (40 * (i - 1))) * gfs)
				imgui.Text(colorLabels[i])
			end
			-- if imgui.Button('Add##first') then
				-- addNew, addIndex = true, 1
			-- end
			
			imgui.PushItemWidth(32 * gfs)
			for index, colorLevel in ipairs(gradientList) do
				local minValue, maxValue
				local prevLevel = gradientList[index-1]
				local nextLevel = gradientList[index+1]
				if prevLevel then minValue = prevLevel[1] + step else minValue = 0 end
				if nextLevel then maxValue = nextLevel[1] - step else maxValue = 1 end
				
				if index > 1 and index < #gradientList then
					imgui.PushItemWidth(56 * gfs)
					local changed, newValue = imgui.DragFloat('##value' .. index .. paramname, colorLevel[1], step, minValue, maxValue, '%.2f')
					imgui.PopItemWidth()
					if changed then colorLevel[1] = newValue end
				else
					imgui.Text(colorLevel[1])
				end
				
				for i = 1,4 do
					imgui.SameLine((72 + (40 * (i - 1))) * gfs)
					local changed, newValue = imgui.DragFloat('##' .. index .. paramname .. colorLabels[i], colorLevel[2][i] * 255, 1, 0, 255, '%.0f')
					if changed then colorLevel[2][i] = newValue / 255 end
				end
				imgui.SameLine()
				imgui.ColorButton(unpack(colorLevel[2]))
				
				if index > 1 and index < #gradientList then
					imgui.SameLine(252 * gfs)
					if imgui.Button('Delete##' .. index) then
						deleteLevel, deleteIndex = true, index
					end
				end
				
				if index < #gradientList then
					imgui.SameLine(308 * gfs)
					if imgui.Button('Add After##' .. index) then
						addNew, addIndex = true, index+1
					end
				end
				
			end
			imgui.PopItemWidth()
			if addNew then
				local newLevel = {0, {}}
				local newColor = {0, 0, 0, 1}
				if addIndex == 1 then
					newLevel[1] = gradientList[1][1] + step
				elseif addIndex > #paramlist[paramname] then
					newLevel[1] = gradientList[#gradientList][1] - step
				else
					newLevel[1] = (gradientList[addIndex-1][1] + gradientList[addIndex][1]) / 2
					for i = 1, 4 do
						newColor[i] = (gradientList[addIndex-1][2][i] + gradientList[addIndex][2][i]) / 2
					end
				end
				newLevel[2] = newColor
				table.insert(gradientList, addIndex, newLevel)
			elseif deleteLevel then
				table.remove(gradientList, deleteIndex)
			end
		end -- if not gradientList
	end -- widgetConfig.colorGradient = function

	local compositeString0 = function(paramname, paramlist, req)
		local segmentList = paramlist[paramname]
		local anyChange = false
		imgui.Text(paramname)
		if req == 'optional' then
			imgui.SameLine()
			if segmentList then
				if imgui.Button('clear##' .. paramname) then
					paramlist[paramname]=nil
					anyChange = true
				end
			else -- segmentList == nil
				if imgui.Button('edit##' .. paramname) then
					paramlist[paramname] = newCompositeString()
					anyChange = true
					-- possible contents:
					-- 'whatever' - a string to be displayed
					-- {'function name', #zero fill} - pso paramlist to be displayed
				end -- if imgui.Button('edit##' .. paramname)
			end -- if segmentList
		end -- if req == 'optional'
		if not segmentList then return end
		local addString, addData, addIndex = false, false, 1
		local deleteSegment, deleteIndex = false, 1
		local gfs = huddata['global font scale'] or 1
		if imgui.Button('add string##first' .. paramname) then
			addString, addIndex = true, 1
		end
		imgui.SameLine()
		if imgui.Button('add paramlist##first' .. paramname) then
			addData, addIndex = true, 1
		end
		for index, segment in ipairs(segmentList) do
			if type(segment) == 'string' then
				imgui.PushItemWidth(150 * gfs)
				local changed, newValue = imgui.InputText('##static string' .. paramname .. index, segment, 100)
				imgui.PopItemWidth()
				if changed then
					segmentList[index] = newValue
					anyChange = true
				end
			else -- segment is not a string
				imgui.PushItemWidth(360)
				local changed, newValue = imgui.Combo('##string function' .. paramname .. index, dfNames['stringFunction'][segment[1]] or 1, dfNames['stringFunction'], #dfNames['stringFunction'])
				imgui.PopItemWidth()
				if changed then
					segment[1] = dfNames['stringFunction'][newValue]
					anyChange = true
				end
				imgui.SameLine()
				imgui.PushItemWidth(76)
				changed, newValue = imgui.InputInt('##padding' .. paramname .. index, segment[2])
				imgui.PopItemWidth()
				if changed then
					segment[2] = newValue
					anyChange = true
				end
			end -- if type(segment) == 'string'
			imgui.SameLine()
			if imgui.Button('delete##' .. paramname .. index) then
				deleteSegment, deleteIndex = true, index
			end
			-- if index < #segmentList then
				imgui.SameLine()
				if imgui.Button('add string after##' .. paramname .. index) then
					addString, addIndex = true, index + 1
				end
				imgui.SameLine()
				if imgui.Button('add paramlist after##' .. paramname .. index) then
					addData, addIndex = true, index + 1
				end
			-- end -- if index < #segmentList
		end -- for index, segment in ipairs(segmentList)
		if addString then
			table.insert(segmentList, addIndex, '')
			anyChange = true
		elseif addData then
			table.insert(segmentList, addIndex, {'Player Current HP', 0})
			anyChange = true
		elseif deleteSegment then
			table.remove(segmentList, deleteIndex)
			anyChange = true
		end
		if anyChange then
			compileCompositeString(segmentList)
		end
	end -- widgetConfig.composite = function

	local function newFormatList(sourceFunction)
		print(sourceFunction)
		local formatTable = {['list source function'] = sourceFunction}
		formatTable['format huddata'] = {['format string'] = ''}
		formatTable['field list'] = {}
		if psodata.listFields[sourceFunction] then
			formatTable['sub format table'] = nil
			formatTable['sub field table'] = nil
			formatTable['subtype edit index'] = nil
			-- formatTable['field combo list'] = utility.buildcombolist(psodata.listFields[sourceFunction])
			formatTable['field combo list'] = psodata.listFields[sourceFunction]
		else -- assume this sourceFunction has subtypes
			formatTable['sub format table'] = {}
			formatTable['sub field table'] = {}
			local subFields = psodata.listSubFields[sourceFunction]
			formatTable['subtype combo list'] = utility.buildcombolist(subFields)
			formatTable['subtype edit index'] = formatTable['subtype combo list'][1]
			for key, _ in pairs(subFields) do
				formatTable['sub format table'][key] = {['format string'] = ''}
				formatTable['sub field table'][key] = {}
			end -- for key, _ in pairs(subFields)
			-- formatTable['format huddata'] = ''
			-- formatTable['field list'] = {}
			-- formatTable['field combo list'] = utility.buildcombolist(psodata.listSubFields[sourceFunction][formatTable['subtype edit index']])
			formatTable['field combo list'] = psodata.listSubFields[sourceFunction][formatTable['subtype edit index']]
		end -- if psodata.listFields[sourceFunction]
		return formatTable
	end -- local function newFormatList

	widgetConfig['format list'] = function(paramname, paramlist, req)
		--[[
		'format list' is a collection of paramlist that specifies how to transform a row of fields in a table into a displayable string.
		components:
		+ list source function (list function) - used to look up the list of potential fields contained by our source paramlist table. if this exists as a key in psodata.listFields, then every item in the table has the same type, and the same list of fields. if not, then we assume that it is instead a key in psodata.listSubFields, and that items in this table each have one of several different types, and a list of fields corresponding with that type.
		+ format paramlist - first argument passed to string.format, and the list of static strings and field names that the format string is constructed from
		+ field list - list of which item fields are used, in order
		+ sub format table - used if source list has subtypes; format paramlist for each subtype
		+ sub field table - used if source list has subtypes; list of used fields for each subtype
		]]
		local formatTable = paramlist[paramname]
		if not formatTable then
			formatTable = newFormatList('Party Members')
			paramlist[paramname] = formatTable
		end
		local sourceFunction = formatTable['list source function']
		local subeditindex
		if formatTable['sub field table'] then
			subeditindex = formatTable['subtype edit index']
			local changed, newValue = imgui.Combo('##' .. paramname .. ' subtype combobox', formatTable['subtype combo list'][subeditindex], formatTable['subtype combo list'], #formatTable['subtype combo list'])
			if changed then
				-- formatTable['sub format list'][subeditindex] = formatTable['format string']
				-- formatTable['sub field list'][subeditindex] = formatTable['field list']
				subeditindex = formatTable['subtype combo list'][newValue]
				formatTable['subtype edit index'] = subeditindex
				-- formatTable['field combo list'] = utility.buildcombolist(psodata.listSubFields[sourceFunction][subeditindex])
				formatTable['field combo list'] = psodata.listSubFields[sourceFunction][subeditindex]
				formatTable['field list'] = formatTable['sub field table'][subeditindex]
				formatTable['format paramlist'] = formatTable['sub format table'][subeditindex]
			end -- if changed
		end -- if formatTable['sub field list']
		-- local usedFieldList, formatList
		local usedFieldList = formatTable['field list']
		local formatData = formatTable['format paramlist']
		local anyChange = false
		local addString, addField, addIndex = false, false, 1
		local deleteSegment, deleteIndex = false, 1
		local gfs = huddata['global font scale'] or 1
		if imgui.Button('add string##first' .. paramname) then
			addString, addIndex = true, 1
		end
		imgui.SameLine()
		if imgui.Button('add field##first' .. paramname) then
			addField, addIndex = true, 1
		end
		for index, segment in ipairs(formatData) do
			if type(segment) == 'string' then
				imgui.PushItemWidth(150 * gfs)
				local changed, newValue = imgui.InputText('##static string ' .. paramname .. index, segment, 100)
				imgui.PopItemWidth()
				if changed then
					formatData[index] = newValue
					anyChange = true
				end
			else -- segment is not a string
				imgui.PushItemWidth(160)
				local changed, newValue = imgui.Combo('##item field combobox ' .. paramname .. index, formatTable['field combo list'][segment[1]], formatTable['field combo list'], #formatTable['field combo list'])
				imgui.PopItemWidth()
				if changed then
					segment[1] = formatTable['field combo list'][newValue]
					anyChange = true
				end
				imgui.SameLine()
				imgui.PushItemWidth(76)
				changed, newValue = imgui.InputInt('##padding' .. paramname .. index, segment[2])
				imgui.PopItemWidth()
				if changed then
					segment[2] = newValue
					anyChange = true
				end
			end -- if type(segment) == 'string'
			imgui.SameLine()
			if imgui.Button('delete##' .. paramname .. index) then
				deleteSegment, deleteIndex = true, index
			end
			imgui.SameLine()
			if imgui.Button('add string after##' .. paramname .. index) then
				addString, addIndex = true, index + 1
			end
			imgui.SameLine()
			if imgui.Button('add field after##' .. paramname .. index) then
				addField, addIndex = true, index + 1
			end
		end -- for index, segment in ipairs(formatData)
		if addString then
			table.insert(formatData, addIndex, '')
			anyChange = true
		elseif addField then
			table.insert(formatData, addIndex, {formatTable['field combo list'][1], 0})
			anyChange = true
		elseif deleteSegment then
			table.remove(formatData, deleteIndex)
			anyChange = true
		end
		imgui.Text(paramname .. '\n' .. 'paramlist source:')
		imgui.SameLine()
		local changed, newValue = imgui.Combo('##' .. paramname .. ' source paramlist function combobox', dfNames['listFunction'][sourceFunction] or 1, dfNames['listFunction'], #dfNames['listFunction'])
		if changed then
			anyChange = true
			sourceFunction = dfNames['listFunction'][newValue]
			paramlist[paramname] = newFormatList(sourceFunction)
		end -- if changed
		if anyChange then
			formatData['format string'] = ''
			usedFieldList = {}
			for index, segment in ipairs(formatData) do
				if type(segment) == 'string' then
					formatData['format string'] = formatData['format string'] .. segment
				else
					formatData['format string'] = formatData['format string'] .. '%' .. segment[2] .. 's'
					table.insert(usedFieldList, segment[1])
				end -- if type(segment) == 'string'
			end -- for index, segment in ipairs(formatData)
			if formatTable['sub field table'] then
			-- print(subeditindex)
				formatTable['sub field table'][subeditindex] = usedFieldList
				formatTable['sub format table'][subeditindex]['format string'] = formatData['format string']
			else
				formatTable['field list'] = usedFieldList
			end -- if formatTable['sub field table')
		end -- if anyChange
	end -- widgetConfig['format list'] = function

end -- do -- define widgetConfig functions

local function showText(color, text)
	imgui.TextColored(color[1], color[2], color[3], color[4], text)
end

do --define widgets and widgetSpecs
	
	widgetSpecs['show formatted list'] = {['format table']={fl,o}, ['text color']={c,o}}
	widgetDefaults['show formatted list'] = {}
	widgets['show formatted list'] = function(window, a)
		local formatTable = a['format table']
		if not formatTable then return end
		local sourceFunction = formatTable['list source function']
		local sourceList = psodata.listFunction[sourceFunction]()
		local color = a['text color'] or window['textColor']
		local fieldList = formatTable['field list']
		local formatString = formatTable['format huddata']['format string']
		local subTypes = false
		-- local subFieldList, subFormatList = {}, {}
		if formatTable['sub field table'] then
			-- subFieldList = formatTable.subFieldList
			-- subFormatList = formatTable.subFormatList
			subTypes = true
		end
		for _, item in ipairs(sourceList) do
			if subTypes then
				-- print('trying to show a list which has subtypes')
				fieldList = formatTable['sub field table'][item['type']]
				formatString = formatTable['sub format table'][item['type']]['format string']
			-- else
				-- print('trying to show a list which does not have subtypes')
			end
			local itemData = {}
			local notEmpty = false
			for _, field in ipairs(fieldList) do
				if item[field] then
					table.insert(itemData, item[field])
				else
					table.insert(itemData, 0)
				end -- if item[field]
				notEmpty = true
			end -- for_, field in ipairs(fieldList)
			if notEmpty then
				showText(color, string.format(formatString, unpack(itemData)))
			end
		end -- for _, item in ipairs(sourceList)
	end -- widgets['show formatted list'] = function
	
end -- do --define widgets and widgetSpecs

local function presentWindow(windowname)
--[[
'window' attributes (*denotes required): list {*title, *id, *x, *y, *w, *h, enabled, openEditor, optionchanged, fontScale, textColor, transparent, *options, *displayList}
'options' format: list {noTitleBar, noResize, noMove, noScrollBar, AlwaysAutoResize}
'displayList': list of widgets contained in window
'item' format: list {command, args}
'args' format: arguments to be used with 'command'; program must ensure that 'args' are valid arguments for 'command'
]]
	local window = huddata.windowlist[windowname]
	if (window.hideLobby and (psodata.currentLocation() == 'lobby')) or (window.hideField and (psodata.currentLocation() ~= 'field'))--[[ or (psodata.currentLocation() == 'login')]] then return end
	for _, menu in ipairs(psodata.menuStates) do
		if psodata.get(menu) and window.hideMenuStates[menu] then return end
	end
	if window.optionchanged and psodata.screenWidth > 0 then
		imgui.SetNextWindowPos(scalex(window.x, window.w), scaley(window.y, window.h), 'Always')
		if window.options[5] ~= 'AlwaysAutoResize' then
			imgui.SetNextWindowSize(scalex(window.w), scaley(window.h), 'Always')
		end
	end
	
	imgui.Begin(windowname .. '###' .. window.id, true, window.options)
	
	if window.options[3] ~= 'NoMove' and not window.optionchanged then
		local newx, newy = imgui.GetWindowPos()
		if newx < 0 then
			newx = 0
		elseif newx + scalex(window.w) > psodata.screenWidth then
			newx = psodata.screenWidth - scalex(window.w)
		end
		window.x = unscalex(newx, window.w)
		window.y = unscaley(newy, window.h)
	end
	if window.options[2] ~= 'NoResize' then
		window.w = unscalex(imgui.GetWindowWidth())
		window.h = unscaley(imgui.GetWindowHeight())
	end
	
	local bgcolor = window['background color']
	if bgcolor then imgui.PushStyleColor('WindowBg', unpack(bgcolor)) end
	
	if huddata['global font scale'] then
		imgui.SetWindowFontScale(window.fontScale * huddata['global font scale'])
	else
		imgui.SetWindowFontScale(window.fontScale)
	end
	local fontScaleChanged = false
	
	for _, item in pairs(window.displayList) do
		if item.args.size then
			imgui.setWindowFontScale(item.args.size)
			fontScaleChanged = true
		elseif fontScaleChanged then
			imgui.setWindowFontScale(window.fontScale)
			fontScaleChanged = false
		end
		-- print(item.widgetType)
		mapcall(window, item)
		-- widgets[item.widgetType](window, item.args)
	end
	
	if bgcolor then imgui.PopStyleColor() end
		
	imgui.End()
	window.optionchanged = false
end -- local function presentWindow(windowname)

local function flagCheckBox(windowname, a)
	local window = huddata.windowlist[windowname]
	local opt = window.options
	if imgui.Checkbox(a.label .. '##' .. windowname, opt[a.index] == a.flag) then
		if opt[a.index] == a.flag then
			opt[a.index] = ''
		else
			opt[a.index] = a.flag
		end
		window.optionchanged = true
	end
end

local function checkbox(list, paramname)
	local changed, newvalue = imgui.Checkbox(paramname, list[paramname])
	if changed then list[paramname] = newvalue end
end

local function presentWindowEditor(windowname)
	local window = huddata.windowlist[windowname]
	local gfs = huddata['global font scale'] or 1
	imgui.SetWindowFontScale(gfs)
	
	local addNew, addIndex = false, 1
	local delete, deleteIndex = false, 1

	local changed, newValue = imgui.Combo('##new widget chooser for ' .. windowname, window.newWidgetType, widgetNames, table.getn(widgetNames))
	if changed then window.newWidgetType = newValue end
	
	imgui.NewLine()
	imgui.SameLine(312 * gfs + 48)
	if imgui.Button('Add##' .. windowname) then
		addNew, addIndex = true, 1
	end
	
	local dl = window.displayList
	local moveUp, moveDown
	for index, item in ipairs(dl) do
		imgui.PushID(index)
		moveUp, moveDown = false, false
		
		imgui.Text(item.widgetType)
		
		if index > 1 then
			imgui.SameLine(200 * gfs)
			if imgui.Button('Up') then moveUp = true end
		end
		
		if index < #dl then
			imgui.SameLine(214 * gfs + 12)
			if imgui.Button('Down') then moveDown = true end
		end
		
		imgui.SameLine(242 * gfs + 24)
		if imgui.Button('Edit') then
			if window.editindex == index then
				window.editindex = -1
			else
				window.editindex = index
			end
		end
		
		imgui.SameLine(270 * gfs + 36)
		if imgui.Button('Delete') then
			delete, deleteIndex = true, index
		end
		
		imgui.SameLine(312 * gfs + 48)
		if imgui.Button('Add After') then
			addNew, addIndex = true, index+1
		end
		
		if moveUp then
			dl[index-1], dl[index] = dl[index], dl[index-1]
		elseif moveDown then
			dl[index+1], dl[index] = dl[index], dl[index+1]
		end
		
		imgui.PopID()
		index = index + 1
	end -- for index, item in ipairs(dl)
	
	if delete then
		table.remove(dl, deleteIndex)
		if window.editindex and window.editindex >= deleteIndex then
			window.editindex = window.editindex - 1
		end
	elseif addNew and window.newWidgetType then
		local newWidget = {widgetType=widgetNames[window.newWidgetType], args={}}
		for name, value in pairs(widgetDefaults[newWidget.widgetType]) do
			-- if type(value) == 'function' then value = value() end
			newWidget.args[name] = value
		end
		table.insert(dl, addIndex, newWidget)
		if window.editindex and window.editindex >= addIndex then
			window.editindex = window.editindex + 1
		end
	end -- if delete
	
	if imgui.Button('window options') then
		if window.editindex == 0 then
			window.editindex = -1
		else
			window.editindex = 0
		end
	end -- if imgui.Button('window options')
	if window.editindex > 0 then
		imgui.NewLine()
		local item = window.displayList[window.editindex]
		imgui.Text(item.widgetType)
		
		for name, specargs in pairs(widgetSpecs[item.widgetType]) do
			imgui.Separator()
			if item.map and item.map[name] then
				widgetConfig[item.map[name][1]](name, item.map, specargs[2], true)
				imgui.SameLine()
				if imgui.Button('static value##' .. windowname .. name) then item.map[name] = nil end
			else
				widgetConfig[specargs[1]](name, item.args, specargs[2])
				if specargs[1] == 'string' or specargs[1] == 'number' or specargs[1] == 'boolean' then
					imgui.SameLine()
					if imgui.Button('dynamic value##' .. windowname .. name) then
						if not item.map then item.map = {} end
						local mapvaluetype = specargs[1] .. 'Function'
						item.map[name] = {mapvaluetype, dfNames[mapvaluetype][1]}
					end
				end -- if specargs[1] == 'string' or 'number' or 'boolean'
			end -- if item.map and item.map[name]
		end -- for name, specargs in pairs(widgetSpecs[item.widgetType])
	elseif window.editindex == 0 then
		imgui.NewLine()
		imgui.Text('Title:')
		imgui.SameLine()
		local newTitle, changed
		changed, newTitle = imgui.InputText('##Title', windowname, 30)
		if changed then
			if verifyNewwindowname(newTitle) then
				huddata.windowlist[windowname], huddata.windowlist[newTitle] = nil, huddata.windowlist[windowname]
				windowname = newTitle
			else -- invalid new window title
				imgui.SameLine()
				showText({1,0.25,0.25,1}, 'window name must be unique')
			end -- if verifyNewwindowname(newTitle)
		end -- if changed
		
		widgetConfig.boolean('enabled', window, true)
		
		-- for option, type in pairs(posoptions) do
			-- if widgetConfig[type](option, window, true, 0, 100, 0.01, '%.2f%%') then window.optionchanged = true end
		-- end -- for option, type in pairs(posoptions)
		local changed = false
		changed = widgetConfig.xpos('x', window, true, scalex(window.x, window.w)) or changed
		changed = widgetConfig.ypos('y', window, true, scaley(window.y, window.h)) or changed
		changed = widgetConfig.xpos('w', window, true, scalex(window.w)) or changed
		changed = widgetConfig.ypos('h', window, true, scaley(window.h)) or changed
		if changed then window.optionchanged = true end
		
		-- local changed1, changed2 = false, false
		
		
		widgetConfig.number('fontScale', window, 'required', 1, 12, 0.1, '%.1f')
		widgetConfig.color('textColor', window, 'required')
		widgetConfig.color('background color', window, 'optional')
		
		flagCheckBox(windowname, {label='no title bar', options=window.options, index=1, flag='NoTitleBar'})
		flagCheckBox(windowname, {label='no resize', options=window.options, index=2, flag='NoResize'})
		flagCheckBox(windowname, {label='no move', options=window.options, index=3, flag='NoMove'})
		flagCheckBox(windowname, {label='no scroll bar', options=window.options, index=4, flag='NoScrollBar'})
		flagCheckBox(windowname, {label='auto resize', options=window.options, index=5, flag='AlwaysAutoResize'})
		-- for i = 1, 5 do
			-- flagCheckBox(windowname, {label=flaglabels[i], options=window.options, index=i, flag=windowflags[i]})
		-- end -- for i = 1, 5
	
		imgui.NewLine()
		imgui.Text('hide window when:')
		for index, state in ipairs(psodata.menuStates) do
			widgetConfig.boolean(state, window.hideMenuStates, true)
		end
		if imgui.Checkbox('not in field##' .. windowname, window.hideField) then
			window.hideField = not window.hideField
		end
		if imgui.Checkbox('in lobby##' .. windowname, window.hideLobby) then
			window.hideLobby = not window.hideLobby
		end
	end -- if window.editindex
	
-- imgui.End()
end

local function newwindow()
	local uniqueid = newid()
	local offset = uniqueid * 5
	return
		{
		x=offset,
		y=offset,
		w=20,
		h=20,
		enabled=true,
		optionchanged=true,
		transparent=false,
		options={'', '', '', '', ''},
		hideLobby=true,
		hideField=true,
		hideMenuStates = {['full screen menu open']=true},
		widget = widget.new('widget list'),
		-- editindex=-1,
		-- newWidgetType=1,
		-- fontScale=1,
		-- textColor={1,1,1,1},
		}
end

local function presentwindowlist()

	imgui.SetNextWindowSize(600,300,'FirstUseEver')
	local success
	success, huddata['show window list'] = imgui.Begin('custom hud window list', true)
		if not success then
			imgui.End()
			return
		end
		
		imgui.BeginGroup()
		
			imgui.PushItemWidth(windownames.longest * 8 * gfs)
				local changed, newvalue = imgui.ListBox('##window list box', windownames[huddata['selected window']] or 0, windownames, #windownames)
			imgui.PopItemWidth()
			if changed then huddata['selected window'] = windownames[newvalue] end
			
			if imgui.Button('window options') then
				huddata['show window options'] = not huddata['show window options']
			end
			
			if imgui.Button('add new window') then
				huddata.windowlist['new window'] = newwindow()
				windownames = utility.buildcombolist(huddata.windowlist)
			end -- if imgui.Button('add new window')
			-- maybe make a pop-up dialog to enter title before adding window
			
			if imgui.Button('delete window') then
				huddata.windowlist[huddata['selected window']] = nil
				huddata['selected window'] = nil
				windownames = utility.buildcombolist(huddata.windowlist)
			end
			-- definitely make a pop-up to confirm delete
			
			if imgui.Button('save') then savetable('profile', huddata) end
			
			checkbox(huddata, 'show debug window')
			
			widgetConfig.slownumber('global font scale', huddata, 'required', 1, 12, 0.1, '%.1f')
			
		imgui.EndGroup()
		
		imgui.SameLine()
		imgui.BeginChild('window editor', -1, -1, true)
			if huddata['selected window'] then
				presentWindowEditor(huddata['selected window'])
			end
		imgui.EndChild()
		
	imgui.End()
end -- local function presentwindowlist()

local function present()
	neondebug.log('start present()', 5)
	
	psodata.retrievePsoData()
	neondebug.log('retrieved game huddata', 5)
	
	if huddata['show window list'] then
		presentwindowlist()
		neondebug.log('presented window list', 5)
	end
	if huddata['show debug window'] then
		huddata['show debug window'] = neondebug.present()
		neondebug.log('presented debug window', 5)
	end
	for windowname, window in pairs(huddata.windowlist) do
		if window.enabled then
			neondebug.log('attempting to present window: ' .. windowname .. '...', 5)
			presentWindow(windowname)
		end
		neondebug.log('...succeeded', 5)
	end
	
	neondebug.log('end present()', 5)
end

local function init()
--	local pwd = io.popen([[dir 'addons\Custom HUD\core windows' /b]])
	-- local testDisplayList = {}
	-- for dir in pwd:lines() do
		-- testDisplayList[dir] = {command='showString', args={text=dir}}
		-- print('thing' .. dir .. ' end thing')
	-- end
	-- pwd:close()
		
	neondebug.log('starting init process')
	
	psodata.init()
	neondebug.log('completed psodata.init()')
	widget.setdatasource(psodata)
	
	psodata.setActive('player')
	psodata.setActive('meseta')
	psodata.setActive('monsterList')
	psodata.setActive('xp')
	psodata.setActive('ata')
	psodata.setActive('party')
	psodata.setActive('floorItems')
	psodata.setActive('inventory')
	psodata.setActive('bank')
	psodata.setActive('sessionTime')
	neondebug.log('set up game huddata access')
	
	huddata = loadtable('profile')
	if huddata then
		neondebug.log('\'profile\' loaded')
		for _, window in pairs(huddata.windowlist) do
			window.optionchanged = true
			window.id = newid()
		end
		windownames = utility.buildcombolist(huddata.windowlist)
	else
		neondebug.log('load(\'profile\') failed')
		huddata = {}
		huddata.windowlist = {}

		huddata['global font scale'] = 1
		huddata['show window list'] = true
		huddata['show window options'] = false
	end
	
	local function mainMenuButtonHandler()
		huddata['show window list'] = not huddata['show window list']
	end

	core_mainmenu.add_button('Dynamic HUD', mainMenuButtonHandler)
	
	neondebug.log('init finished')
	return
		{
		name = 'Custom HUD',
		version = '0.5',
		author = 'IzumiDaye',
		description = 'Build your own custom HUD',
		present = present,
		}
end

return {__addon = {init = init}}
