--[[
PSOBB Dynamic Info Addon
Catherine S (IzumiDaye/NeonLuna)
2018-10-05
]]

local core_mainmenu = require('core_mainmenu')
local neondebug = require('Custom HUD.neondebug')
local psodata = require('Custom HUD.psodata')
local utility = require('Custom HUD.utility')
local widget = require('Custom HUD.widget')
neondebug.update('this is a test', 'wow')
neondebug.enablelogging()

local replacements =
	{
	
	}

local requireddefaults =
	{
	['editIndex'] = -1,
	}

local colorLabels = {'r', 'g', 'b', 'a'}

-- local checkMemoryOffset = 0

local data
-- 'data' will be overwritten in init(), so initializing here doesn't work

local dfNames = {}
local windownames
local widgets = {}
local widgetSpecs = {}
local widgetDefaults = {}
local widgetNames = {}
local widgetConfig = {}

local function mapcall(window, item, fielddata)
	local a = item.args
	if item.map then
		for name, value in pairs(item.map) do
			if type(value) == 'string' then
				a[name] = fielddata[value]
			else
				a[name] = psodata[value[1]][value[2]]()
			end -- if type(value) == 'string'
		end -- for name, value in pairs(map)
	end -- if map
	widgets[item.widgetType](window, a)
end

local function editlist(list, fieldsavailable)
	local dragthisframe = false
	local cursorpos = 5
	if not list.buttonedges then list.buttonedges = {8} end
	if not list.buttoncenters then list.buttoncenters = {} end
	list.rowtop = imgui.GetCursorPosY() - 48
	imgui.Dummy(0, 0)
	imgui.SameLine()
	for index, item in ipairs(list) do
		if index > 1 then imgui.SameLine() end
		local name, tooltip
		if item.widgetType then
			if item.widgetType == 'showString' then
				name = "'" .. item.args['text'] .. "'"
			elseif item.widgetType == 'showMemValue' then
				name = psodata.shortname[item.args['sourceFunction']]
				tooltip = item.args['sourceFunction']
			elseif item.widgetType == 'progressBar' then
				name = psodata.shortname[item.args['progressFunction']] .. ' -'
				tooltip = item.args['progressFunction'] .. ' progress bar'
			end
		else
			name = item[2]
		end -- if item.widgetType
		
		if list.selected == index then
			imgui.PushStyleColor('Button', .2, .5, 1, 1)
			imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
			imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
			if imgui.Button(name .. '##' .. index) then list.selected = nil end
			imgui.PopStyleColor()
			imgui.PopStyleColor()
			imgui.PopStyleColor()
		else
			imgui.PushStyleColor('Button', .5, .5, .5, .3)
			if imgui.Button(name .. '##' .. index) then list.selected = index end
			imgui.PopStyleColor()
		end -- if list.selected == index
		
		-- if imgui.Selectable(name .. '##' .. index, list.selected == index) then
			-- if list.selected == index then
				-- list.selected = nil
			-- else
				-- list.selected = index
			-- end
		-- end
		
		if #list.buttoncenters < #list then
			local itemwidth, _ = imgui.GetItemRectSize()
			list.buttoncenters[index] = cursorpos + 8 + itemwidth / 2
			cursorpos = cursorpos + itemwidth + 8
			list.buttonedges[index + 1] = cursorpos + 3
		end
		
		if imgui.IsItemActive() then
			dragthisframe = true
			list.dragx, list.dragy = imgui.GetMousePos()
			local winx, winy = imgui.GetWindowPos()
			list.dragx = list.dragx - winx
			list.dragy = list.dragy - winy
			list.dragsource = index
		end
		
		-- if tooltip and imgui.IsItemHovered() then
		if tooltip and imgui.IsItemHovered() and (not imgui.IsMouseDown(0)) then
			imgui.SetTooltip(tooltip)
		end
	end -- for index, item in ipairs(list)
	
	list.rowbottom = imgui.GetCursorPosY() + 48
	
	if dragthisframe then
		if not list.dragactive then -- drag start
			list.dragstartx, list.dragstarty = list.dragx, list.dragy
			list.dragactive = true
		end
		list.dragdest = 1
		for index, pos in ipairs(list.buttoncenters) do
			if list.dragx > pos then
				list.dragdest = index + 1
			else
				break
			end -- if list.dragx > pos
		end -- for index, pos in ipairs(list.buttoncenters)
		if list.dragy < list.rowtop or list.dragy > list.rowbottom or list.dragx < -48 or list.dragx > list.buttonedges[#list.buttonedges] + 48 then
			list.dragdest = nil
			print('out of bounds')
		end
	else
		if list.dragactive then -- drag end
			if list.dragdest then
				if ((list.dragsource ~= list.dragdest) and (list.dragsource + 1 ~= list.dragdest)) then
					local newpos
					if list.dragsource < list.dragdest then
						table.insert(list, list.dragdest, list[list.dragsource])
						table.remove(list, list.dragsource)
						newpos = list.dragdest - 1
					else
						table.insert(list, list.dragdest, list[list.dragsource])
						table.remove(list, list.dragsource + 1)
						newpos = list.dragdest
					end
					
					if list.selected then
						if list.dragsource == list.selected then
							list.selected = newpos
						elseif list.dragsource < list.selected
						and list.selected < list.dragdest then
							list.selected = list.selected - 1
						elseif list.dragsource > list.selected
						and list.selected >= list.dragdest then
							list.selected = list.selected + 1
						end
					end
					
					list.buttonedges = nil
					list.buttoncenters = nil
				end -- if list.dragdest would actually move the button
			end -- if list.dragdest
			list.dragactive = nil
			list.dragdest = nil
			list.dragsource = nil
		end -- if list.dragactive
	end
	
	if list.dragdest and math.abs(list.dragx - list.dragstartx) > 12 then
		imgui.SameLine(list.buttonedges[list.dragdest])
		imgui.Text('|')
	end -- if list.dragdest
	-- for index, offset in ipairs(list.buttonedges) do
		-- if index > 1 then
			-- imgui.SameLine(offset)
		-- end
		-- imgui.Text('|')
	-- end
	-- imgui.NewLine()
	-- for index, offset in ipairs(list.buttoncenters) do
		-- imgui.SameLine(offset)
		-- imgui.Text('|')
	-- end
	if list.selected then
		local item = list[list.selected]
		for name, specargs in pairs(widgetSpecs[item.widgetType]) do
			imgui.Spacing()
			if item.map and item.map[name] then
				if fieldsavailable then
					
				else
					widgetConfig[item.map[name][1]](name, item.map, specargs[2], true)
				end
				imgui.SameLine()
				if imgui.Button('static value##' .. name) then item.map[name] = nil end
			else
				widgetConfig[specargs[1]](name, item.args, specargs[2])
				if specargs[1] == 'string' or specargs[1] == 'number' or specargs[1] == 'boolean' then
					imgui.SameLine()
					if fieldsavailable then
					
					else
						if imgui.Button('dynamic value##' .. name) then
							if not item.map then item.map = {} end
							local mapvaluetype = specargs[1] .. 'Function'
							item.map[name] = {mapvaluetype, dfNames[mapvaluetype][1]}
						end
					end -- if fieldsavailable
				end -- if specargs[1] == 'string' or 'number' or 'boolean'
			end -- if item.map and item.map[name]
		end -- for name, specargs in pairs(widgetSpecs[item.widgetType])
	end -- if list.selected
end -- local function editlist

local function showlist(window, list, fielddata)
	
	for index, item in ipairs(list) do
		if index > 1 then imgui.SameLine() end
		if item.widgetType then
			mapcall(window, item)
		elseif item[1] == 'field' then
			imgui.Text(fielddata[item[2]])
		else
			-- if not item[2] then print(serialize(item)) end
			imgui.Text(item[2])
		end
	end -- for index, item in ipairs(list)
	
end -- local function showlist

local function round(number, places)
	local mult
	if places then mult = math.pow(10, places) else mult = 1 end
	return math.floor(number * mult + 0.5) / mult
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

local function save()
-- saves current HUD configuration to disk as a runnable lua script.
	
	local outputdata = 'return\n' .. utility.serialize(data)
	
	local file = io.open('addons/Custom HUD/profile.lua', 'w')
	if file then
		io.output(file)
		io.write(outputdata)
		io.close(file)
	end
end

local function load()
-- loads saved HUD configuration from disk.

	local dataLoaded, tempData = pcall(require, 'Custom HUD.profile')
	if dataLoaded then
		neondebug.log('profile loaded')
		data = tempData
		for _, window in pairs(data.windowList) do
			window.optionchanged = true
			if not window.editIndex then window.editIndex = -1 end
		end
		windownames = utility.buildcombolist(data.windowList)
	end
	return dataLoaded
end

local function compileCompositeString(sourceCS)
	local result = ''
	local functionList = {}
	for index, segment in ipairs(sourceCS) do
		if type(segment) == 'string' then
			result = result .. segment
		else -- we're assuming it's a function then
			result = result .. '%' .. segment[2] .. 'i'
			table.insert(functionList, segment[1])
		end -- if type(segment) == 'string'
	end -- for index, segment in ipairs(sourceCS)
	sourceCS.formatString = result
	sourceCS.functionList = functionList
end

local function newCompositeString()
	return {formatString = '', functionList = {}}
end

do --define widgetConfig functions

	widgetConfig.string = function(argName, data, req)
		imgui.Text(argName)
		imgui.SameLine()
		if req == 'optional' then
			if imgui.Button('clear##' .. argName) then data[argName]=nil end
			imgui.SameLine()
		end
		local displayValue = data[argName] or ''
		local changed, newValue = imgui.InputText('##' .. argName, displayValue, 100)
		if changed then data[argName]=newValue end
	end

	widgetConfig.number = function(argName, data, req, minValue, maxValue, step, format, displayValue)
		minValue = minValue or 0
		maxValue = maxValue or 1
		format = format or ': %.0f'
		step = step or 1
		if req == 'optional' then
			if imgui.Button('clear##' .. argName) then data[argName]=nil end
			imgui.SameLine()
		end
		local editValue = data[argName] or 1
		displayValue = displayValue or editValue
		displayValue = string.format(format, displayValue)
		imgui.Text(argName .. ':')
		imgui.SameLine()
		imgui.PushItemWidth(64)
		local changed, changed2, newValue
		changed, newValue = imgui.DragFloat('##' .. argName, editValue, 1, minValue, maxValue, displayValue)
		if changed then data[argName]=newValue end
		imgui.SameLine()
		imgui.PopItemWidth()
		imgui.PushItemWidth(72)
		changed2, newValue = imgui.DragFloat('##finetune' .. argName, editValue, step, minValue, maxValue, 'fine tune')
		if changed2 then data[argName] = newValue end
		imgui.PopItemWidth()
		return changed or changed2
	end
	
	widgetConfig.slownumber = function(argName, data, req, minValue, maxValue, step, format)
		minValue = minValue or 0
		maxValue = maxValue or 1
		format = format or '%.1f'
		step = step or 1
		if req == 'optional' then
			if imgui.Button('clear##' .. argName) then data[argName]=nil end
			imgui.SameLine()
		end
		imgui.Text(argName)
		imgui.SameLine()
		imgui.PushItemWidth(96)
		local changed, newValue = imgui.InputFloat('##' .. argName, data[argName], step, 1, 1, format)
		imgui.PopItemWidth()
		if changed then
			if newValue < minValue then
				newValue = minValue
			elseif newValue > maxValue then
				newValue = maxValue
			end
			data[argName] = newValue
		end
	end

	widgetConfig.xpos = function(argName, data, req, displayvalue)
		return widgetConfig.number(argName, data, req, 0, 100, 0.01, '%u', displayvalue)
	end
	
	widgetConfig.ypos = function(argName, data, req, displayvalue)
		return widgetConfig.number(argName, data, req, 0, 100, 0.01, '%u', displayvalue)
	end
	
	widgetConfig.boolean = function(argName, data, req)
		if req == 'optional' then
			if imgui.Button('clear##' .. argName) then data[argName]=nil end
			imgui.SameLine()
		end
		local displayValue = data[argName] or false
		local changed, newValue = imgui.Checkbox(argName, displayValue)
		if changed then data[argName] = newValue end
		-- return changed
	end

	local dataFunction = function(argName, data, req, fType, mapformat)
		imgui.Text(argName)
		imgui.SameLine()
		-- if req == 'optional' then
			-- if imgui.Button('clear##' .. argName) then data[argName]=nil end
			-- imgui.SameLine()
		-- end
		imgui.PushItemWidth(8 + (8 * dfNames[fType].longest))
		local displayvalue
		if mapformat then
			displayvalue = dfNames[fType][data[argName][2]]
		else
			displayvalue = dfNames[fType][data[argName]] or 1
		end
		local changed, newValue = imgui.Combo('##' .. argName, displayvalue, dfNames[fType], #dfNames[fType])
		imgui.PopItemWidth()
		if changed then
			if mapformat then
				data[argName] = {fType, dfNames[fType][newValue]}
			else
				data[argName] = dfNames[fType][newValue]
			end
		end
	end -- local dataFunction = function
	
	widgetConfig.stringFunction = function(argName, data, req, mapformat)
		dataFunction(argName, data, req, 'stringFunction', mapformat)
	end

	widgetConfig.numberFunction = function(argName, data, req, mapformat)
		dataFunction(argName, data, req, 'numberFunction', mapformat)
	end

	widgetConfig.listFunction = function(argName, data, req)
		dataFunction(argName, data, req, 'listFunction')
	end

	widgetConfig.booleanFunction = function(argName, data, req, mapformat)
		dataFunction(argName, data, req, 'booleanFunction', mapformat)
	end

	widgetConfig.progressFunction = function(argName, data, req)
		dataFunction(argName, data, req, 'progressFunction')
	end

	widgetConfig.color = function(argName, data, req)
		imgui.Text(argName)
		imgui.SameLine()
		if data[argName] and req == 'optional' then
			if imgui.Button('clear##' .. argName) then data[argName]=nil end
			imgui.SameLine()
		end
		if not data[argName] then
			if imgui.Button('edit##' .. argName) then
				data[argName] = {0.5, 0.5, 0.5, 1}
			end
		else
			local gfs = data['global font scale'] or 1
			imgui.PushItemWidth(40 * gfs)
			for i = 1,4 do
				imgui.SameLine()
				local changed, newValue = imgui.DragFloat('##' .. argName .. colorLabels[i], data[argName][i] * 255, 1, 0, 255, colorLabels[i] .. ':%.0f')
				if changed then data[argName][i] = newValue / 255 end
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.ColorButton(unpack(data[argName]))
		end
	end
	
	widgetConfig.colorGradient = function(argName, data, req)
		local gradientList = data[argName]
		imgui.Text(argName)
		imgui.SameLine()
		if req == 'optional' then
			if imgui.Button('clear##' .. argName) then data[argName]=nil end
		end
		if not gradientList then
			imgui.SameLine()
			if imgui.Button('edit##' .. argName) then
				data[argName] = {{0,{0, 0, 0, 1}},{1,{1, 1, 1, 1}}}
			end
		else -- not gradientList
			local addNew, addIndex = false, 1
			local deleteLevel, deleteIndex = false, 1
			local step = 0.01
			local gfs = data['global font scale'] or 1
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
					local changed, newValue = imgui.DragFloat('##value' .. index .. argName, colorLevel[1], step, minValue, maxValue, '%.2f')
					imgui.PopItemWidth()
					if changed then colorLevel[1] = newValue end
				else
					imgui.Text(colorLevel[1])
				end
				
				for i = 1,4 do
					imgui.SameLine((72 + (40 * (i - 1))) * gfs)
					local changed, newValue = imgui.DragFloat('##' .. index .. argName .. colorLabels[i], colorLevel[2][i] * 255, 1, 0, 255, '%.0f')
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
				elseif addIndex > #data[argName] then
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

	widgetConfig.composite = function(argname, data)
		-- imgui.BeginChild(argname .. 'editor', -1, 0, true)
		imgui.Text(argname)
		editlist(data[argname])
		-- imgui.EndChild()
	end

	local compositeString0 = function(argName, data, req)
		local segmentList = data[argName]
		local anyChange = false
		imgui.Text(argName)
		if req == 'optional' then
			imgui.SameLine()
			if segmentList then
				if imgui.Button('clear##' .. argName) then
					data[argName]=nil
					anyChange = true
				end
			else -- segmentList == nil
				if imgui.Button('edit##' .. argName) then
					data[argName] = newCompositeString()
					anyChange = true
					-- possible contents:
					-- 'whatever' - a string to be displayed
					-- {'function name', #zero fill} - pso data to be displayed
				end -- if imgui.Button('edit##' .. argName)
			end -- if segmentList
		end -- if req == 'optional'
		if not segmentList then return end
		local addString, addData, addIndex = false, false, 1
		local deleteSegment, deleteIndex = false, 1
		local gfs = data['global font scale'] or 1
		if imgui.Button('add string##first' .. argName) then
			addString, addIndex = true, 1
		end
		imgui.SameLine()
		if imgui.Button('add data##first' .. argName) then
			addData, addIndex = true, 1
		end
		for index, segment in ipairs(segmentList) do
			if type(segment) == 'string' then
				imgui.PushItemWidth(150 * gfs)
				local changed, newValue = imgui.InputText('##static string' .. argName .. index, segment, 100)
				imgui.PopItemWidth()
				if changed then
					segmentList[index] = newValue
					anyChange = true
				end
			else -- segment is not a string
				imgui.PushItemWidth(360)
				local changed, newValue = imgui.Combo('##string function' .. argName .. index, dfNames['stringFunction'][segment[1]] or 1, dfNames['stringFunction'], #dfNames['stringFunction'])
				imgui.PopItemWidth()
				if changed then
					segment[1] = dfNames['stringFunction'][newValue]
					anyChange = true
				end
				imgui.SameLine()
				imgui.PushItemWidth(76)
				changed, newValue = imgui.InputInt('##padding' .. argName .. index, segment[2])
				imgui.PopItemWidth()
				if changed then
					segment[2] = newValue
					anyChange = true
				end
			end -- if type(segment) == 'string'
			imgui.SameLine()
			if imgui.Button('delete##' .. argName .. index) then
				deleteSegment, deleteIndex = true, index
			end
			-- if index < #segmentList then
				imgui.SameLine()
				if imgui.Button('add string after##' .. argName .. index) then
					addString, addIndex = true, index + 1
				end
				imgui.SameLine()
				if imgui.Button('add data after##' .. argName .. index) then
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
		formatTable['format data'] = {['format string'] = ''}
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
			-- formatTable['format data'] = ''
			-- formatTable['field list'] = {}
			-- formatTable['field combo list'] = utility.buildcombolist(psodata.listSubFields[sourceFunction][formatTable['subtype edit index']])
			formatTable['field combo list'] = psodata.listSubFields[sourceFunction][formatTable['subtype edit index']]
		end -- if psodata.listFields[sourceFunction]
		return formatTable
	end -- local function newFormatList

	widgetConfig['format list'] = function(argName, data, req)
		--[[
		'format list' is a collection of data that specifies how to transform a row of fields in a table into a displayable string.
		components:
		+ list source function (list function) - used to look up the list of potential fields contained by our source data table. if this exists as a key in psodata.listFields, then every item in the table has the same type, and the same list of fields. if not, then we assume that it is instead a key in psodata.listSubFields, and that items in this table each have one of several different types, and a list of fields corresponding with that type.
		+ format data - first argument passed to string.format, and the list of static strings and field names that the format string is constructed from
		+ field list - list of which item fields are used, in order
		+ sub format table - used if source list has subtypes; format data for each subtype
		+ sub field table - used if source list has subtypes; list of used fields for each subtype
		]]
		local formatTable = data[argName]
		if not formatTable then
			formatTable = newFormatList('Party Members')
			data[argName] = formatTable
		end
		local sourceFunction = formatTable['list source function']
		local subEditIndex
		if formatTable['sub field table'] then
			subEditIndex = formatTable['subtype edit index']
			local changed, newValue = imgui.Combo('##' .. argName .. ' subtype combobox', formatTable['subtype combo list'][subEditIndex], formatTable['subtype combo list'], #formatTable['subtype combo list'])
			if changed then
				-- formatTable['sub format list'][subEditIndex] = formatTable['format string']
				-- formatTable['sub field list'][subEditIndex] = formatTable['field list']
				subEditIndex = formatTable['subtype combo list'][newValue]
				formatTable['subtype edit index'] = subEditIndex
				-- formatTable['field combo list'] = utility.buildcombolist(psodata.listSubFields[sourceFunction][subEditIndex])
				formatTable['field combo list'] = psodata.listSubFields[sourceFunction][subEditIndex]
				formatTable['field list'] = formatTable['sub field table'][subEditIndex]
				formatTable['format data'] = formatTable['sub format table'][subEditIndex]
			end -- if changed
		end -- if formatTable['sub field list']
		-- local usedFieldList, formatList
		local usedFieldList = formatTable['field list']
		local formatData = formatTable['format data']
		local anyChange = false
		local addString, addField, addIndex = false, false, 1
		local deleteSegment, deleteIndex = false, 1
		local gfs = data['global font scale'] or 1
		if imgui.Button('add string##first' .. argName) then
			addString, addIndex = true, 1
		end
		imgui.SameLine()
		if imgui.Button('add field##first' .. argName) then
			addField, addIndex = true, 1
		end
		for index, segment in ipairs(formatData) do
			if type(segment) == 'string' then
				imgui.PushItemWidth(150 * gfs)
				local changed, newValue = imgui.InputText('##static string ' .. argName .. index, segment, 100)
				imgui.PopItemWidth()
				if changed then
					formatData[index] = newValue
					anyChange = true
				end
			else -- segment is not a string
				imgui.PushItemWidth(160)
				local changed, newValue = imgui.Combo('##item field combobox ' .. argName .. index, formatTable['field combo list'][segment[1]], formatTable['field combo list'], #formatTable['field combo list'])
				imgui.PopItemWidth()
				if changed then
					segment[1] = formatTable['field combo list'][newValue]
					anyChange = true
				end
				imgui.SameLine()
				imgui.PushItemWidth(76)
				changed, newValue = imgui.InputInt('##padding' .. argName .. index, segment[2])
				imgui.PopItemWidth()
				if changed then
					segment[2] = newValue
					anyChange = true
				end
			end -- if type(segment) == 'string'
			imgui.SameLine()
			if imgui.Button('delete##' .. argName .. index) then
				deleteSegment, deleteIndex = true, index
			end
			imgui.SameLine()
			if imgui.Button('add string after##' .. argName .. index) then
				addString, addIndex = true, index + 1
			end
			imgui.SameLine()
			if imgui.Button('add field after##' .. argName .. index) then
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
		imgui.Text(argName .. '\n' .. 'data source:')
		imgui.SameLine()
		local changed, newValue = imgui.Combo('##' .. argName .. ' source data function combobox', dfNames['listFunction'][sourceFunction] or 1, dfNames['listFunction'], #dfNames['listFunction'])
		if changed then
			anyChange = true
			sourceFunction = dfNames['listFunction'][newValue]
			data[argName] = newFormatList(sourceFunction)
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
			-- print(subEditIndex)
				formatTable['sub field table'][subEditIndex] = usedFieldList
				formatTable['sub format table'][subEditIndex]['format string'] = formatData['format string']
			else
				formatTable['field list'] = usedFieldList
			end -- if formatTable['sub field table')
		end -- if anyChange
	end -- widgetConfig['format list'] = function

--[[
	local s = 'string'
	local n = 'number'
	local x = 'xpos' -- x-axis position or size
	local y = 'ypos'
	local c = 'color'
	local cg = 'colorGradient'
	local b = 'boolean'
	local df = 'dataFunction'
	local o = 'optional'
	local r = 'required'
]]

end -- do -- define widgetConfig functions

local function showText(color, text)
	imgui.TextColored(color[1], color[2], color[3], color[4], text)
end

local function recursiveShowList(list, color, currentOffset, offsetStep)
	local indent = string.rep(' ', currentOffset)
	for name, value in pairs(list) do
		-- print('name: ' .. name)
		if name ~= 'fields' then
			if type(value) == 'table' then
				showText(color, indent .. name .. ':')
				recursiveShowList(value, color, currentOffset + offsetStep, offsetStep)
			elseif type(value) == 'boolean' then
				local boolString = 'false'
				if value then boolString = 'true' end
				showText(color, indent .. name .. ': ' .. boolString)
			else -- type(value) is not a table or a boolean
				showText(color, indent .. name .. ': ' .. value)
			end -- type(value) switch
		end -- if name ~= 'fields'
	end -- for name, value in pairs(list)
end -- local function recursiveShowList

do --define widgets and widgetSpecs
	local s = 'string'
	local n = 'number'
	local x = 'xpos' -- x-axis position or size
	local y = 'ypos'
	local c = 'color'
	local cg = 'colorGradient'
	local b = 'boolean'
	local sf = 'stringFunction'
	local lf = 'listFunction'
	local bf = 'booleanFunction'
	local pf = 'progressFunction'
	local cs = 'composite'
	local fl = 'format list'
	
	local o = 'optional'
	local r = 'required'
	
	widgetSpecs.showString = {color={c,o}, sameLine={b,o,false}, text={s,r,false}}
	widgetDefaults.showString = {text=''}
	widgets.showString = function(window, a)
		local color = a.color or window.textColor
		if a.sameLine then imgui.SameLine() end
		local text = a.text or ''
		showText(color, text)
	end
	
	widgetSpecs['show formatted list'] = {['format table']={fl,o}, ['text color']={c,o}}
	widgetDefaults['show formatted list'] = {}
	widgets['show formatted list'] = function(window, a)
		local formatTable = a['format table']
		if not formatTable then return end
		local sourceFunction = formatTable['list source function']
		local sourceList = psodata.listFunction[sourceFunction]()
		local color = a['text color'] or window['textColor']
		local fieldList = formatTable['field list']
		local formatString = formatTable['format data']['format string']
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
	
	widgetSpecs.showMemValue = {sourceFunction={sf,r}, sameLine={b,o,false}}
	widgetDefaults.showMemValue = {sourceFunction='Player HP: Current/Maximum'}
	widgets.showMemValue = function(window, a)
		a.text = psodata.stringFunction[a.sourceFunction]()
		widgets.showString(window, a)
	end
	
	-- widgetSpecs['Show Composite String'] = {sourceCS={cs,o}, color={c,o}, sameLine={b,o}}
	-- widgetDefaults['Show Composite String'] = {}
	-- widgets['Show Composite String'] = function(window, a)
		-- if a.sourceCS then
			-- local functionResults = {}
			-- for index, name in ipairs(a.sourceCS.functionList) do
				-- functionResults[index] = psodata.stringFunction[name]()
			-- end
			-- local color = a.color or window.textColor
			-- showText(color, string.format(a.sourceCS.formatString, unpack(functionResults)))
		-- end
	-- end
	
	widgetSpecs['Show Composite String'] = {sourceCS={cs,o}, color={c,o}, sameLine={b,o,false}}
	widgetDefaults['Show Composite String'] = {}
	widgets['Show Composite String'] = function(window, a)
		showlist(window, a.sourceCS)
	end
	
	widgetSpecs['Show Composite String 0'] = {sourceCS={cs,o}, color={c,o}, sameLine={b,o,false}}
	widgetDefaults['Show Composite String 0'] = {}
	widgets['Show Composite String 0'] = function(window, a)
		if a.sourceCS then
			-- local indent = 0
			for index = 1, #a.sourceCS do
				local segment = a.sourceCS[index]
				if index > 1 then
					imgui.SameLine(0, 0)
				end
				if type(segment) == 'string' then
					imgui.Text(segment)
				else
					imgui.Text(string.format('%' .. segment[2] .. 's', psodata.stringFunction[segment[1]]()))
				end -- if type(segment) == 'string'
			end -- for _, segment in ipairs (composite)
		end -- if a.sourceCS
	end -- widgets['Show Composite String'] = function(window, a)
	
	widgetSpecs.progressBar = {progressFunction={pf,r,true}, barGradient={cg,o}, barColor={c,o}, showFullBar={b,o,false}, overlayFunction={sf,o}, overlay={s,o,true}, textColor={c,o}, width={x,o}, height={y,o}}
	widgetDefaults.progressBar = {progressFunction='Player HP'}
	widgets.progressBar = function(window, a)
		local width, height = -1, -1
		if a.width then width = scalex(a.width) end
		if a.height then height = scaley(a.height) end
		
		print(a.progressFunction)
		local progress = psodata.progressFunction[a.progressFunction]()
		if progress ~= progress then progress = 0 end
		local gfs = data['global font scale'] or 1
		local barColor = {0.5, 0.5, 0.5, 1}
		if a.barGradient then
			-- local i = 1
			-- while a.barGradient[i] do
				-- local e = a.barGradient[i]
				-- if progress >= e[1] then
					-- barColor = e[2]
				-- end
				-- i = i + 1
			-- end
			for i, colorLevel in ipairs(a.barGradient) do
				if progress >= colorLevel[1] then barColor = colorLevel[2] end
			end
		elseif a.barColor then
			barColor = a.barColor
		end -- if a.barGradient
		if a.showFullBar then progress = 1 end
		
		local overlay = ''
		if a.overlayFunction then
			overlay = psodata.stringFunction[a.overlayFunction]()
		elseif a.overlay then
			overlay = a.overlay
		end
		
		imgui.PushStyleColor('PlotHistogram', unpack(barColor))
		if a.textColor then
			imgui.PushStyleColor('Text', unpack(a.textColor))
		end
		imgui.ProgressBar(progress, width, height, overlay)
		if a.textColor then imgui.PopStyleColor() end
		imgui.PopStyleColor()
	end -- widgets.progressBar = function
	
	local count = 1
	for name, _ in pairs(widgets) do
		widgetNames[count] = name
		count = count + 1
	end
	widgetNames = utility.buildcombolist(widgets)

end -- do --define widgets and widgetSpecs

local function verifyNewwindowname(newName)
	return newName and (not data.windowList[newName])
end

local function presentWindow(windowname)
--[[
'window' attributes (*denotes required): list {*title, *id, *x, *y, *w, *h, enabled, openEditor, optionchanged, fontScale, textColor, transparent, *options, *displayList}
'options' format: list {noTitleBar, noResize, noMove, noScrollBar, AlwaysAutoResize}
'displayList': list of display 'item's
'item' format: list {command, args}
'args' format: arguments to be used with 'command'; program must ensure that 'args' are valid arguments for 'command'
]]
	local window = data.windowList[windowname]
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
	
	imgui.Begin(windowname, true, window.options)
	
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
	
	if data['global font scale'] then
		imgui.SetWindowFontScale(window.fontScale * data['global font scale'])
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
	local window = data.windowList[windowname]
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

local function presentWindowEditor(windowname)
	local window = data.windowList[windowname]
	local gfs = data['global font scale'] or 1
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
			if window.editIndex == index then
				window.editIndex = -1
			else
				window.editIndex = index
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
		if window.editIndex and window.editIndex >= deleteIndex then
			window.editIndex = window.editIndex - 1
		end
	elseif addNew and window.newWidgetType then
		local newWidget = {widgetType=widgetNames[window.newWidgetType], args={}}
		for name, value in pairs(widgetDefaults[newWidget.widgetType]) do
			-- if type(value) == 'function' then value = value() end
			newWidget.args[name] = value
		end
		table.insert(dl, addIndex, newWidget)
		if window.editIndex and window.editIndex >= addIndex then
			window.editIndex = window.editIndex + 1
		end
	end -- if delete
	
	if imgui.Button('window options') then
		if window.editIndex == 0 then
			window.editIndex = -1
		else
			window.editIndex = 0
		end
	end -- if imgui.Button('window options')
	if window.editIndex > 0 then
		imgui.NewLine()
		local item = window.displayList[window.editIndex]
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
	elseif window.editIndex == 0 then
		imgui.NewLine()
		imgui.Text('Title:')
		imgui.SameLine()
		local newTitle, changed
		changed, newTitle = imgui.InputText('##Title', windowname, 30)
		if changed then
			if verifyNewwindowname(newTitle) then
				data.windowList[windowname], data.windowList[newTitle] = nil, data.windowList[windowname]
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
	end -- if window.editIndex
	
-- imgui.End()
end

local function presentColorPalette(windowname)
	local window = data.windowList[windowname]
	-- imgui.ColorButton(unpack(colorLevel[2]))
end -- local function presentColorPalette

local function presentWindowList()
	imgui.SetNextWindowSize(600,300,'FirstUseEver')
	local success
	success, data['show window list'] = imgui.Begin('Custom HUD Window List', true)
	
	-- local changed, newValue = imgui.InputInt('##checkMemoryOffset', checkMemoryOffset)
	-- imgui.SameLine()
	-- if changed then checkMemoryOffset = newValue end
	-- showText({1,1,1,1}, '+' .. checkMemoryOffset .. ': ' .. pso.read_u32(0x00A97F44 + checkMemoryOffset))
	
	widgetConfig.boolean('show debug window', data, true)
	
	local gfs = 1 -- data['global font scale'] or 1
	imgui.SetWindowFontScale(gfs)
	widgetConfig.slownumber('global font scale', data, 'required', 1, 12, 0.1, '%.1f')
	
	imgui.BeginGroup()
	
	imgui.PushItemWidth(windownames.longest * 8 * gfs)
	local changed, newValue = imgui.ListBox('##window list box', windownames[data['selected window']] or 0, windownames, table.getn(windownames))
	imgui.PopItemWidth()
	if changed then data['selected window'] = windownames[newValue] end
	
	if imgui.Button('add new window') then
		local uniqueid = 0
		repeat
			uniqueid = uniqueid + 1
		until data.windowList['new window ' .. uniqueid] == nil
		local offset = uniqueid * 5
		data.windowList['new window ' .. uniqueid] =
			{
			x=offset,
			y=offset,
			w=20,
			h=20,
			enabled=true,
			editIndex=-1,
			newWidgetType=1,
			optionchanged=true,
			fontScale=1,
			textColor={1,1,1,1},
			transparent=false,
			options={'', '', '', '', ''},
			hideLobby=true,
			hideField=true,
			hideMenuStates = {['full screen menu open']=true},
			displayList={}
			}
		windownames = utility.buildcombolist(data.windowList)
	end -- if imgui.Button('add new window')
	if imgui.Button('delete window') then
		data.windowList[data['selected window']] = nil
		data['selected window'] = nil
		windownames = utility.buildcombolist(data.windowList)
	end
	
	if imgui.Button('save') then save() end
	
	imgui.EndGroup()
	
	imgui.SameLine()
	imgui.BeginChild('window editor', -1, -1, true)
	if data['selected window'] then
		presentWindowEditor(data['selected window']) end
	imgui.EndChild()
	
	imgui.End()
end -- local function presentWindowList()

local function present()
	neondebug.log('start present()', 5)
	
	psodata.retrievePsoData()
	neondebug.log('retrieved game data', 5)
	
	if data['show window list'] then
		presentWindowList()
		neondebug.log('presented window list', 5)
	end
	if data['show debug window'] then
		data['show debug window'] = neondebug.present()
		neondebug.log('presented debug window', 5)
	end
	for windowname, window in pairs(data.windowList) do
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
	
	-- dfNames['stringFunction'] = utility.buildcombolist(psodata.stringFunction)
	-- dfNames['numberFunction'] = utility.buildcombolist(psodata.numberFunction)
	-- dfNames['listFunction'] = utility.buildcombolist(psodata.listFunction)
	-- dfNames['booleanFunction'] = utility.buildcombolist(psodata.booleanFunction)
	-- dfNames['progressFunction'] = utility.buildcombolist(psodata.progressFunction)
	
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
	neondebug.log('set up game data access')
	
	if not load() then
		neondebug.log('load() failed')
		data = {}
		data.windowList = {}
		-- data.windowList['Test Window'] = {x=500, y=300, w=200, h=200, enabled=true, openOptions=false, openEditor=false, newWidgetType=1, optionchanged=true, fontScale=1, textColor={1,1,1,1}, transparent=false, options={'', '', '', '', ''}, displayList={{widgetType='showString', args={text='Kittens!!'}}}}

		-- data.windowList['French Fries'] = {x=800, y=100, w=200, h=200, enabled=true, openOptions=false, openEditor=false, newWidgetType=1, optionchanged=true, fontScale=1, textColor={1,1,1,1}, transparent=false, options={'', '', '', '', ''}, displayList={{widgetType='showString', args={text='Muffins!!'}},{widgetType='showMemValue', args={sourceFunction='Player HP: Current/Maximum'}}}}

		data['global font scale'] = 1
		data['show window list'] = true
	end
	
	-- for windowname, window in pairs(data.windowList) do
		-- print(windowname)
		-- imgui.SetWindowPos(windowname, scalex(window.x, window.w), scaley(window.y, window.h), 'FirstUseEver')
		-- imgui.SetWindowSize(windowname, scalex(window.w), scaley(window.h), 'FirstUseEver')
	-- end
	
	local function mainMenuButtonHandler()
		data['show window list'] = not data['show window list']
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
