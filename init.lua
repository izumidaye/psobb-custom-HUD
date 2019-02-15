--[[
PSOBB Dynamic Info Addon
Catherine S (IzumiDaye/NeonLuna)
2018-10-05
]]

local core_mainmenu = require("core_mainmenu")
local psodata = require("Custom HUD.psodata")

local colorLabels = {"red", "green", "blue", "alpha"}

local screenWidth = pso.read_u16(0x00A46C48)
local screenHeight = pso.read_u16(0x00A46C4A)

local data = {}
local dfNames = {}

data.windowList = {}
data.colorPalette = {}

local function compareString(string1, string2)
	return string.lower(string1) < string.lower(string2)
end

local function buildComboList(itemList)
	local resultList = {}
	local count = 1
	for key, _ in pairs(itemList) do
		table.insert(resultList, key)
		-- resultList[count] = key
		-- resultList[key] = count
		-- count = count + 1
	end
	table.sort(resultList, compareString)
	for index, name in ipairs(resultList) do
		resultList[name] = index
	end
	return resultList
end

local function addReverseLookup(sourceList)
	for key, value in ipairs(sourceList) do
		sourceList[value] = key
	end
end

local function serialize(sourceData, currentOffset)
	currentOffset = currentOffset or 0
	local indent = string.rep(" ", currentOffset)
	local dataType = type(sourceData)
	local result = ""
	if dataType == "number" then
		result = result .. sourceData
	elseif dataType == "string" then
		result = string.format("\"%s\"", sourceData)
	elseif dataType == "boolean" then
		if sourceData then
			result = "true"
		else
			result = "false"
		end
	elseif dataType == "table" then
		-- local containsTables = false
		local optionalLineBreak = ""
		local tableEnding = "}"
		result = result .. "{"
		for _, value in pairs(sourceData) do
			if type(value) == "table" then
				-- containsTables = true
				optionalLineBreak = "\n" .. indent
				tableEnding = "\n" .. indent .. "}"
			end
		end
		for key, value in pairs(sourceData) do
			if type(key) == "number" then
				key = ""
			else
				key = string.format("[%s]=", serialize(key))
			end
			result = result .. optionalLineBreak .. key .. serialize(value, currentOffset + 2) .. ","
		end
		result = result .. tableEnding
	end -- dataType switch
	return result
end -- local function serialize(sourceData)

local function save()
	local file = io.open("addons/Custom HUD/profile.lua", "w")
	if file then
		io.output(file)
		io.write("return")
		io.write(serialize(data))
		io.close(file)
	end
end

local function load()
	local dataLoaded, tempData = pcall(require, "Custom HUD.profile")
	if dataLoaded then data = tempData end
	return dataLoaded
end

local function compileCompositeString(sourceCS)
	local result = ""
	local functionList = {}
	for index, segment in ipairs(sourceCS) do
		if type(segment) == "string" then
			result = result .. segment
		else
			result = result .. "%" .. segment[2] .. "i"
			table.insert(functionList, segment[1])
		end
	end
	sourceCS.formatString = result
	sourceCS.functionList = functionList
end

local function newCompositeString()
	return {formatString = "", functionList = {}}
end

local widgetConfig = {}
do --define widgetConfig functions

	widgetConfig.string = function(argName, item, req)
		imgui.Text(argName)
		imgui.SameLine()
		if req == "optional" then
			if imgui.Button("clear##" .. argName) then item.args[argName]=nil end
			imgui.SameLine()
		end
		local displayValue = item.args[argName] or ""
		local changed, newValue = imgui.InputText("##" .. argName, displayValue, 100)
		if changed then item.args[argName]=newValue end
	end

	--number == integer unless it turns out I need floats too
	widgetConfig.number = function(argName, item, req, minValue, maxValue)
		minValue = minValue or 0
		maxValue = maxValue or 0
		if req == "optional" then
			if imgui.Button("clear##" .. argName) then item.args[argName]=nil end
			imgui.SameLine()
		end
		local displayValue = item.args[argName] or 1
		local changed, newValue = imgui.DragFloat("##" .. argName, displayValue, 1, minValue, maxValue, argName .. ": %.0f")
		if changed then item.args[argName]=newValue end
	end

	widgetConfig.boolean = function(argName, item, req)
		if req == "optional" then
			if imgui.Button("clear##" .. argName) then item.args[argName]=nil end
			imgui.SameLine()
		end
		local displayValue = item.args[argName] or false
		local changed, newValue = imgui.Checkbox(argName, displayValue)
		if changed then item.args[argName] = newValue end
	end

	local dataFunction = function(argName, item, req, fType)
		imgui.Text(argName)
		imgui.SameLine()
		if req == "optional" then
			if imgui.Button("clear##" .. argName) then item.args[argName]=nil end
			imgui.SameLine()
		end
		local changed, newValue = imgui.Combo("##" .. argName, dfNames[fType][item.args[argName]] or 1, dfNames[fType], #dfNames[fType])
		if changed then item.args[argName] = dfNames[fType][newValue] end
	end
	
	widgetConfig.stringFunction = function(argName, item, req)
		dataFunction(argName, item, req, "stringFunction")
	end

	widgetConfig.listFunction = function(argName, item, req)
		dataFunction(argName, item, req, "listFunction")
	end

	widgetConfig.booleanFunction = function(argName, item, req)
		dataFunction(argName, item, req, "booleanFunction")
	end

	widgetConfig.progressFunction = function(argName, item, req)
		dataFunction(argName, item, req, "progressFunction")
	end

	widgetConfig.xpos = function(argName, item, req)
		widgetConfig.number(argName, item, req, 0, screenWidth)
	end
	
	widgetConfig.ypos = function(argName, item, req)
		widgetConfig.number(argName, item, req, -1, screenHeight)
	end
	
	widgetConfig.color = function(argName, item, req)
		imgui.Text(argName)
		imgui.SameLine()
		if req == "optional" then
			if imgui.Button("clear##" .. argName) then item.args[argName]=nil end
			imgui.SameLine()
		end
		if not item.args[argName] then
			if imgui.Button("edit##" .. argName) then
				item.args[argName] = {0.5, 0.5, 0.5, 1}
			end
		else
			local gfs = data["global font scale"] or 1
			imgui.PushItemWidth(64 * gfs)
			for i = 1,4 do
				imgui.SameLine()
				local changed, newValue = imgui.DragFloat("##" .. argName .. colorLabels[i], item.args[argName][i] * 255, 1, 0, 255, colorLabels[i] .. ":%.0f")
				if changed then item.args[argName][i] = newValue / 255 end
			end
			imgui.PopItemWidth()
			imgui.SameLine()
			imgui.ColorButton(unpack(item.args[argName]))
		end
	end
	
	widgetConfig.colorGradient = function(argName, item, req)
		local gradientList = item.args[argName]
		imgui.Text(argName)
		imgui.SameLine()
		if req == "optional" then
			if imgui.Button("clear##" .. argName) then item.args[argName]=nil end
		end
		if not gradientList then
			imgui.SameLine()
			if imgui.Button("edit##" .. argName) then
				item.args[argName] = {{0,{0, 0, 0, 1}},{1,{1, 1, 1, 1}}}
			end
		else -- not gradientList
			local addNew, addIndex = false, 1
			local deleteLevel, deleteIndex = false, 1
			local step = 0.01
			local gfs = data["global font scale"] or 1
			-- imgui.PushItemWidth(40 * gfs)
			
			imgui.Text("Value >=")
			for i = 1,4 do
				imgui.SameLine((72 + (40 * (i - 1))) * gfs)
				imgui.Text(colorLabels[i])
			end
			-- if imgui.Button("Add##first") then
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
					local changed, newValue = imgui.DragFloat("##value" .. index .. argName, colorLevel[1], step, minValue, maxValue, "%.2f")
					imgui.PopItemWidth()
					if changed then colorLevel[1] = newValue end
				else
					imgui.Text(colorLevel[1])
				end
				
				for i = 1,4 do
					imgui.SameLine((72 + (40 * (i - 1))) * gfs)
					local changed, newValue = imgui.DragFloat("##" .. index .. argName .. colorLabels[i], colorLevel[2][i] * 255, 1, 0, 255, "%.0f")
					if changed then colorLevel[2][i] = newValue / 255 end
				end
				imgui.SameLine()
				imgui.ColorButton(unpack(colorLevel[2]))
				
				if index > 1 and index < #gradientList then
					imgui.SameLine(252 * gfs)
					if imgui.Button("Delete##" .. index) then
						deleteLevel, deleteIndex = true, index
					end
				end
				
				if index < #gradientList then
					imgui.SameLine(308 * gfs)
					if imgui.Button("Add After##" .. index) then
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
				elseif addIndex > #item.args[argName] then
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

	widgetConfig.compositeString = function(argName, item, req)
		local segmentList = item.args[argName]
		local anyChange = false
		imgui.Text(argName)
		if req == "optional" then
			imgui.SameLine()
			if segmentList then
				if imgui.Button("clear##" .. argName) then
					item.args[argName]=nil
					anyChange = true
				end
			else -- segmentList == nil
				if imgui.Button("edit##" .. argName) then
					item.args[argName] = newCompositeString()
					anyChange = true
					-- possible contents:
					-- "whatever" - a string to be displayed
					-- {"function name", #zero fill} - pso data to be displayed
				end -- if imgui.Button("edit##" .. argName)
			end -- if segmentList
		end -- if req == "optional"
		if not segmentList then return end
		local addString, addData, addIndex = false, false, 1
		local deleteSegment, deleteIndex = false, 1
		local gfs = data["global font scale"] or 1
		if imgui.Button("add string##first" .. argName) then
			addString, addIndex = true, 1
		end
		imgui.SameLine()
		if imgui.Button("add data##first" .. argName) then
			addData, addIndex = true, 1
		end
		for index, segment in ipairs(segmentList) do
			if type(segment) == "string" then
				imgui.PushItemWidth(150 * gfs)
				local changed, newValue = imgui.InputText("##static string" .. argName .. index, segment, 100)
				imgui.PopItemWidth()
				if changed then
					segmentList[index] = newValue
					anyChange = true
				end
			else -- segment is not a string
				imgui.PushItemWidth(360)
				local changed, newValue = imgui.Combo("##string function" .. argName .. index, dfNames["stringFunction"][segment[1]] or 1, dfNames["stringFunction"], #dfNames["stringFunction"])
				imgui.PopItemWidth()
				if changed then
					segment[1] = dfNames["stringFunction"][newValue]
					anyChange = true
				end
				imgui.SameLine()
				imgui.PushItemWidth(76)
				changed, newValue = imgui.InputInt("##padding" .. argName .. index, segment[2])
				imgui.PopItemWidth()
				if changed then
					segment[2] = newValue
					anyChange = true
				end
			end -- if type(segment) == "string"
			imgui.SameLine()
			if imgui.Button("delete##" .. argName .. index) then
				deleteSegment, deleteIndex = true, index
			end
			-- if index < #segmentList then
				imgui.SameLine()
				if imgui.Button("add string after##" .. argName .. index) then
					addString, addIndex = true, index + 1
				end
				imgui.SameLine()
				if imgui.Button("add data after##" .. argName .. index) then
					addData, addIndex = true, index + 1
				end
			-- end -- if index < #segmentList
		end -- for index, segment in ipairs(segmentList)
		if addString then
			table.insert(segmentList, addIndex, "")
			anyChange = true
		elseif addData then
			table.insert(segmentList, addIndex, {"Player Current HP", 0})
			anyChange = true
		elseif deleteSegment then
			table.remove(segmentList, deleteIndex)
			anyChange = true
		end
		if anyChange then
			compileCompositeString(segmentList)
		end
	end -- widgetConfig.compositeString = function

	local function newFormatList(sourceFunction)
		print(sourceFunction)
		local formatTable = {['list source function'] = sourceFunction}
		formatTable['format data'] = {['format string'] = ''}
		formatTable['field list'] = {}
		if psodata.listFields[sourceFunction] then
			formatTable['sub format table'] = nil
			formatTable['sub field table'] = nil
			formatTable['subtype edit index'] = nil
			-- formatTable['field combo list'] = buildComboList(psodata.listFields[sourceFunction])
			formatTable['field combo list'] = psodata.listFields[sourceFunction]
		else -- assume this sourceFunction has subtypes
			formatTable['sub format table'] = {}
			formatTable['sub field table'] = {}
			local subFields = psodata.listSubFields[sourceFunction]
			formatTable['subtype combo list'] = buildComboList(subFields)
			formatTable['subtype edit index'] = formatTable['subtype combo list'][1]
			for key, _ in pairs(subFields) do
				formatTable['sub format table'][key] = {['format string'] = ''}
				formatTable['sub field table'][key] = {}
			end -- for key, _ in pairs(subFields)
			-- formatTable['format data'] = ''
			-- formatTable['field list'] = {}
			-- formatTable['field combo list'] = buildComboList(psodata.listSubFields[sourceFunction][formatTable['subtype edit index']])
			formatTable['field combo list'] = psodata.listSubFields[sourceFunction][formatTable['subtype edit index']]
		end -- if psodata.listFields[sourceFunction]
		return formatTable
	end -- local function newFormatList

	widgetConfig['format list'] = function(argName, item, req)
		--[[
		'format list' is a collection of data that specifies how to transform a row of fields in a table into a displayable string.
		components:
		+ list source function (list function) - used to look up the list of potential fields contained by our source data table. if this exists as a key in psodata.listFields, then every item in the table has the same type, and the same list of fields. if not, then we assume that it is instead a key in psodata.listSubFields, and that items in this table each have one of several different types, and a list of fields corresponding with that type.
		+ format data - first argument passed to string.format, and the list of static strings and field names that the format string is constructed from
		+ field list - list of which item fields are used, in order
		+ sub format table - used if source list has subtypes; format data for each subtype
		+ sub field table - used if source list has subtypes; list of used fields for each subtype
		]]
		local formatTable = item.args[argName]
		if not formatTable then
			formatTable = newFormatList('Party Members')
			item.args[argName] = formatTable
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
				-- formatTable['field combo list'] = buildComboList(psodata.listSubFields[sourceFunction][subEditIndex])
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
			item.args[argName] = newFormatList(sourceFunction)
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
	local s = "string"
	local n = "number"
	local x = "xpos" -- x-axis position or size
	local y = "ypos"
	local c = "color"
	local cg = "colorGradient"
	local b = "boolean"
	local df = "dataFunction"
	local o = "optional"
	local r = "required"
]]

end

local widgets = {}
local widgetSpecs = {}
local widgetDefaults = {}
local widgetNames = {}

local function showText(color, text)
	imgui.TextColored(color[1], color[2], color[3], color[4], text)
end

local function recursiveShowList(list, color, currentOffset, offsetStep)
	local indent = string.rep(" ", currentOffset)
	for name, value in pairs(list) do
		-- print("name: " .. name)
		if name ~= "fields" then
			if type(value) == "table" then
				showText(color, indent .. name .. ":")
				recursiveShowList(value, color, currentOffset + offsetStep, offsetStep)
			elseif type(value) == "boolean" then
				local boolString = "false"
				if value then boolString = "true" end
				showText(color, indent .. name .. ": " .. boolString)
			else -- type(value) is not a table or a boolean
				showText(color, indent .. name .. ": " .. value)
			end -- type(value) switch
		end -- if name ~= "fields"
	end -- for name, value in pairs(list)
end -- local function recursiveShowList

do --define widgets and widgetSpecs
	local s = "string"
	local n = "number"
	local x = "xpos" -- x-axis position or size
	local y = "ypos"
	local c = "color"
	local cg = "colorGradient"
	local b = "boolean"
	local sf = "stringFunction"
	local lf = "listFunction"
	local bf = "booleanFunction"
	local pf = "progressFunction"
	local o = "optional"
	local r = "required"
	local cs = "compositeString"
	local fl = "format list"
	-- local sfl = "stringFunctionList"
	
	widgetSpecs.showString = {color={c,o}, sameLine={b,o}, text={s,r}}
	widgetDefaults.showString = {text=""}
	widgets.showString = function(window, a)
		local color = a.color or window.textColor
		if a.sameLine then imgui.SameLine() end
		local text = a.text or ""
		showText(color, text)
	end
	
	widgetSpecs.showList = {sourceFunction={lf,r}}
	widgetDefaults.showList = {sourceFunction="Inventory Items"}
	widgets.showList = function(window, a)
		local color = window.textColor
		local functionReference = psodata.listFunctions[a.sourceFunction]
		recursiveShowList(functionReference(), window.textColor, 0, 2)
	end -- widgets.showAllData = function
	
	widgetSpecs['show formatted list'] = {['format table']={fl,o}, ['text color']={c,o}}
	widgetDefaults['show formatted list'] = {}
	widgets['show formatted list'] = function(window, a)
		local formatTable = a['format table']
		if not formatTable then return end
		local sourceFunction = formatTable['list source function']
		local sourceList = psodata.listFunctions[sourceFunction]()
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
				end -- ir item[field]
				notEmpty = true
			end -- for_, field in ipairs(fieldList)
			if notEmpty then
				local debugString = ''
				-- for attribute, value in pairs(item) do
					-- if type(value) == 'string' or type(value) == 'number' then
						-- debugString = debugString .. attribute .. ': ' .. value .. ' |'
					-- end
				-- end
				-- print(debugString)
				showText(color, string.format(formatString, unpack(itemData)))
			else
				-- print('emptiness!!!')
			end
		end -- for _, item in ipairs(sourceList)
	end -- widgets['show formatted list'] = function
	
	widgetSpecs.showMemValue = {sourceFunction={sf,r}, sameLine={b,o}}
	widgetDefaults.showMemValue = {sourceFunction="Player HP: Current/Maximum"}
	widgets.showMemValue = function(window, a)
		a.text = psodata.stringFunctions[a.sourceFunction]()
		widgets.showString(window, a)
	end
	
	-- local function renderCompositeString(sourceCS)
	-- end

	widgetSpecs["Show Composite String"] = {sourceCS={cs,o}, color={c,o}, sameLine={b,o}}
	widgetDefaults["Show Composite String"] = {}
	widgets["Show Composite String"] = function(window, a)
		if a.sourceCS then
			local functionResults = {}
			for index, name in ipairs(a.sourceCS.functionList) do
				functionResults[index] = psodata.stringFunctions[name]()
			end
			-- sourceCS.displayString = 
			-- renderCompositeString(a.sourceCS)
			local color = a.color or window.textColor
			showText(color, string.format(a.sourceCS.formatString, unpack(functionResults)))
		end
	end
	
	widgetSpecs.progressBar = {progressFunction={pf,r}, barGradient={cg,o}, barColor={c,o}, showFullBar={b,o}, overlayFunction={sf,o}, overlay={s,o}, textColor={c,o}, width={x,o}, height={y,o}}
	widgetDefaults.progressBar = {progressFunction="Player HP"}
	widgets.progressBar = function(window, a)
		local progress = psodata.progressFunctions[a.progressFunction]()
		local gfs = data["global font scale"] or 1
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
		
		local overlay = ""
		if a.overlayFunction then
			overlay = psodata.stringFunctions[a.overlayFunction]()
		elseif a.overlay then
			overlay = a.overlay
		end
		
		imgui.PushStyleColor("PlotHistogram", unpack(barColor))
		if a.textColor then
			imgui.PushStyleColor("Text", unpack(a.textColor))
		end
		imgui.ProgressBar(progress, a.width or -1, (a.height or 15) * gfs, overlay)
		if a.textColor then imgui.PopStyleColor() end
		imgui.PopStyleColor()
	end -- widgets.progressBar = function
	
	local count = 1
	for name, _ in pairs(widgets) do
		widgetNames[count] = name
		count = count + 1
	end
	widgetNames = buildComboList(widgets)

end -- do --define widgets and widgetSpecs

local function verifyNewWindowName(newName)
	return newName and (not data.windowList[newName])
end

local newWindowCount = 0
local function presentWindowList()
	imgui.SetNextWindowSize(600,300,"FirstUseEver")
	local success
	success, data["show window list"] = imgui.Begin("Custom HUD Window List", true, "AlwaysAutoResize")
	local gfs = data["global font scale"] or 1
	imgui.SetWindowFontScale(gfs)
	local delete, deleteWindow
	for windowName, window in pairs(data.windowList) do
		imgui.TextColored(1, 1, 1, 1, windowName)
		imgui.SameLine(200 * gfs)
		if imgui.Button("Show/Hide##" .. windowName) then window.enabled = not window.enabled end
		imgui.SameLine(280 * gfs)
		if imgui.Button("Options##" .. windowName) then window.openOptions = not window.openOptions end
		imgui.SameLine(344 * gfs)
		if imgui.Button("Window Editor##" .. windowName) then
			window.openEditor = not window.openEditor
		end
		imgui.SameLine(456 * gfs)
		if imgui.Button("Delete Window##" .. windowName) then
			delete = true
			deleteWindow = windowName
		end
	end -- for windowName, window in pairs(data.windowList)
	-- local newTitle, changed
	-- changed, newTitle = imgui.InputText("##newWindowTitle", "", 30)
	-- imgui.SameLine()
	if imgui.Button("Add New Window") then
		-- local windowListSize = 0
		-- for _, _ in pairs(data.windowList) do
			-- windowListSize = windowListSize + 1
		-- end
		local offset = newWindowCount * 36
		newWindowCount = newWindowCount + 1
		data.windowList["new window " .. (newWindowCount)] = {thisIsNew=true, x=offset, y=offset, w=200, h=200, enabled=true, openOptions=false, openEditor=false, newWidgetType=1, optionsChanged=false, fontScale=1, textColor={1,1,1,1}, transparent=false, options={"", "", "", "", ""}, displayList={{widgetType="showString", args={text="Kittens!!"}}}}
	end
	imgui.SameLine()
	if imgui.Button("Save Configuration") then save() end
	
	if delete then
		data.windowList[deleteWindow] = nil
	end
	imgui.End()
end

local function presentWindow(windowName)
--[[
"window" attributes (*denotes required): list {*title, *id, *x, *y, *w, *h, enabled, openOptions, openEditor, optionsChanged, fontScale, textColor, transparent, *options, *displayList}
"options" format: list {noTitleBar, noResize, noMove, noScrollBar, AlwaysAutoResize}
"displayList": list of display "item"s
"item" format: list {command, args}
"args" format: arguments to be used with "command"; program must ensure that "args" are valid arguments for "command"
]]
	local window = data.windowList[windowName]
	if window.optionsChanged or window.thisIsNew then
		window.thisIsNew = nil
		imgui.SetNextWindowPos(window.x - (window.w / 2), window.y - (window.h / 2), "Always")
		if not (window.options[5] == "AlwaysAutoResize") then
			imgui.SetNextWindowSize(window.w, window.h, "Always")
		end
	end
	local transparentWindow = window.transparent
	if transparentWindow then imgui.PushStyleColor("WindowBg", 0, 0, 0, 0) end
	
	imgui.Begin(windowName, nil, window.options)
	if data["global font scale"] then
		imgui.SetWindowFontScale(window.fontScale * data["global font scale"])
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
		widgets[item.widgetType](window, item.args)
	end
		
	imgui.End()
	
	window.optionsChanged = false
	if transparentWindow then imgui.PopStyleColor() end
end

local function flagCheckBox(windowName, a)
	local window = data.windowList[windowName]
	local opt = window.options
	if imgui.Checkbox(a.label .. "##" .. windowName, opt[a.index] == a.flag) then
		if opt[a.index] == a.flag then
			opt[a.index] = ""
		else
			opt[a.index] = a.flag
		end
		window.optionsChanged = true
	end
end

local function presentOptions(windowName)
	-- "options" format: list {noTitleBar, noResize, noMove, noScrollBar, AlwaysAutoResize}
	local window = data.windowList[windowName]
	imgui.SetNextWindowSize(400, 600, "FirstUseEver")
	local success
	success, window.openOptions = imgui.Begin(windowName .. " Options", true, "AlwaysAutoResize")
	if data["global font scale"] then
		imgui.SetWindowFontScale(data["global font scale"])
		imgui.PushItemWidth(150 * data["global font scale"])
	else
		imgui.PushItemWidth(150)
	end
	local changed = false

	changed, window.x = imgui.DragFloat("##X" .. windowName, window.x, 1.0, 0, screenWidth, "X: %.0f")
	if changed then window.optionsChanged = true end
	
	imgui.SameLine()
	changed, window.y = imgui.DragFloat("##Y" .. windowName, window.y, 1.0, 0, screenHeight, "Y: %.0f")
	if changed then window.optionsChanged = true end
	
	changed, window.w = imgui.DragFloat("##W" .. windowName, window.w, 1.0, 0, screenWidth, "Width: %.0f")
	if changed then window.optionsChanged = true end
	
	imgui.SameLine()
	changed, window.h = imgui.DragFloat("##H" .. windowName, window.h, 1.0, 0, screenHeight, "Height: %.0f")
	if changed then window.optionsChanged = true end
	imgui.PopItemWidth()
	
	changed, window.fontScale = imgui.DragFloat("##WFS" .. windowName, window.fontScale, 0.01, 0.5, 15.0, "Font Scale: %1.2f")
	if changed then window.optionsChanged = true end
	
	flagCheckBox(windowName, {label="No Title Bar",options=window.options,index=1,flag="NoTitleBar"})
	
	flagCheckBox(windowName, {label="No Resize",options=window.options,index=2,flag="NoResize"})
	
	flagCheckBox(windowName, {label="No Move",options=window.options,index=3,flag="NoMove"})
	
	flagCheckBox(windowName, {label="No Scroll Bar",options=window.options,index=4,flag="NoScrollbar"})
	
	flagCheckBox(windowName, {label="Always Auto Resize",options=window.options,index=5,flag="AlwaysAutoResize"})
	
	imgui.End()
end

local function presentWindowEditor(windowName)
	local window = data.windowList[windowName]
	imgui.SetNextWindowSize(400, 600, "FirstUseEver")
	local success
	success, window.openEditor = imgui.Begin("Window Editor: " .. windowName .. "##Window Editor", true, "AlwaysAutoResize")
	local gfs = data["global font scale"] or 1
	imgui.SetWindowFontScale(gfs)
	
	widgets.showString(window, {text="Title:"})
	imgui.SameLine()
	local newTitle, changed
	changed, newTitle = imgui.InputText("##Title", windowName, 30)
	if changed then
		if verifyNewWindowName(newTitle) then
			data.windowList[windowName], data.windowList[newTitle] = nil, data.windowList[windowName]
			windowName = newTitle
		else
			imgui.SameLine()
			showText({1,0.25,0.25,1}, 'window name must be unique')
		end
	end
	
	local addNew, addIndex = false, 1
	local delete, deleteIndex = false, 1

	imgui.NewLine()
	imgui.SameLine(312 * gfs + 48)
	if imgui.Button("Add##" .. windowName) then
		addNew, addIndex = true, 1
	end
	
	local dl = window.displayList
	local moveUp, moveDown
	for index, item in ipairs(dl) do
		imgui.PushID(index)
		moveUp, moveDown = false, false
		
		widgets.showString(window, {newLine=true,text=item.widgetType})
		
		if index > 1 then
			imgui.SameLine(200 * gfs)
			if imgui.Button("Up") then moveUp = true end
		end
		
		if index < #dl then
			imgui.SameLine(214 * gfs + 12)
			if imgui.Button("Down") then moveDown = true end
		end
		
		imgui.SameLine(242 * gfs + 24)
		if imgui.Button("Edit") then
			if window.editIndex == index then
				window.editIndex = nil
			else
				window.editIndex = index
			end
		end
		
		imgui.SameLine(270 * gfs + 36)
		if imgui.Button("Delete") then
			delete, deleteIndex = true, index
		end
		
		imgui.SameLine(312 * gfs + 48)
		if imgui.Button("Add After") then
			addNew, addIndex = true, index+1
		end
		
		if moveUp then
			dl[index-1], dl[index] = dl[index], dl[index-1]
		elseif moveDown then
			dl[index+1], dl[index] = dl[index], dl[index+1]
		end
		
		imgui.PopID()
		index = index + 1
	end
	
	local changed, newValue = imgui.Combo("##new widget chooser for " .. windowName, window.newWidgetType, widgetNames, table.getn(widgetNames))
	if changed then window.newWidgetType = newValue end
	
	if delete then
		table.remove(dl, deleteIndex)
		if window.editIndex and window.editIndex >= deleteIndex then
			window.editIndex = window.editIndex - 1
		end
	elseif addNew and window.newWidgetType then
		local newWidget = {widgetType=widgetNames[window.newWidgetType], args={}}
		for name, value in pairs(widgetDefaults[newWidget.widgetType]) do
			-- if type(value) == "function" then value = value() end
			newWidget.args[name] = value
		end
		table.insert(dl, addIndex, newWidget)
		if window.editIndex and window.editIndex >= addIndex then
			window.editIndex = window.editIndex + 1
		end
	end
	
imgui.End()
-- done! *****add/remove items
-- done - but maybe this should be done outside of widget list loop? *****reorder items
-- done! *****button to access widget editor
end

local function presentItemEditor(windowName)
	--"item" format: list {command, args}
	local window = data.windowList[windowName]
	imgui.SetNextWindowSize(400, 600, "FirstUseEver")
	local success, keepOpen
	local item = window.displayList[window.editIndex]
	success, keepOpen = imgui.Begin("Item Editor: " .. windowName .. "." .. item.widgetType .. "##Item Editor", true)
	if not keepOpen then window.editIndex = nil end
	if not (keepOpen and success) then return end
	local gfs = data["global font scale"] or 1
	imgui.SetWindowFontScale(gfs)
	
	widgets.showString(window, {newLine=true,text=item.widgetType})
	--next: display list of command's arguments, names and values
	--then: make them editable, and validate before modifying window data
	
	for name, args in pairs(widgetSpecs[item.widgetType]) do
		imgui.Separator()
		widgetConfig[args[1]](name,item,args[2])
	end
	
	imgui.End()
end

local function presentColorPalette(windowName)
	local window = data.windowList[windowName]
	-- imgui.ColorButton(unpack(colorLevel[2]))
end -- local function presentColorPalette

local function present()
	psodata.retrievePsoData()
	if data["show window list"] then presentWindowList() end
	for windowName, window in pairs(data.windowList) do
		if window.enabled then presentWindow(windowName) end
		if window.openOptions then presentOptions(windowName) end
		if window.openEditor then presentWindowEditor(windowName) end
		if window.editIndex then
			presentItemEditor(windowName)
		end
	end
end

local function init()
--	local pwd = io.popen([[dir "addons\Custom HUD\core windows" /b]])
	-- local testDisplayList = {}
	-- for dir in pwd:lines() do
		-- testDisplayList[dir] = {command="showString", args={text=dir}}
		-- print("thing" .. dir .. " end thing")
	-- end
	-- pwd:close()
		
	
	psodata.init()
	dfNames["stringFunction"] = buildComboList(psodata.stringFunctions)
	dfNames["listFunction"] = buildComboList(psodata.listFunctions)
	dfNames["booleanFunction"] = buildComboList(psodata.booleanFunctions)
	dfNames["progressFunction"] = buildComboList(psodata.progressFunctions)
	psodata.setActive("player")
	psodata.setActive("meseta")
	psodata.setActive("monsterList")
	psodata.setActive("xp")
	psodata.setActive("ata")
	psodata.setActive("party")
	psodata.setActive("floorItems")
	-- psodata.setActive("inventory")
	psodata.setActive("bank")
	psodata.setActive("sessionTime")
	
	if not load() then
		data.windowList["Test Window"] = {x=500, y=300, w=200, h=200, enabled=true, openOptions=false, openEditor=false, newWidgetType=1, optionsChanged=false, fontScale=1, textColor={1,1,1,1}, transparent=false, options={"", "", "", "", ""}, displayList={{widgetType="showString", args={text="Kittens!!"}}}}

		data.windowList["French Fries"] = {x=800, y=100, w=200, h=200, enabled=true, openOptions=false, openEditor=false, newWidgetType=1, optionsChanged=false, fontScale=1, textColor={1,1,1,1}, transparent=false, options={"", "", "", "", ""}, displayList={{widgetType="showString", args={text="Muffins!!"}},{widgetType="showMemValue", args={sourceFunction="Player HP: Current/Maximum"}}}}

		data["global font scale"] = 1
		data["show window list"] = true
	end
	
	for _, window in pairs(data.windowList) do
		window.thisIsNew = true
	end
	
	local function mainMenuButtonHandler()
		data["show window list"] = not data["show window list"]
		print("did the thing")
	end

	core_mainmenu.add_button("Dynamic HUD", mainMenuButtonHandler)
	
	return
	{
		name = "Custom HUD",
		version = "0.2",
		author = "IzumiDaye",
		description = "Build your own custom HUD",
		present = present,
	}
end

return
{
	__addon =
	{
		init = init
	}
}
