local imgui = imgui
local editParam = {}
local paramTypes, toggleButton, text, translate, logPcall, xLimit, yLimit--, layoutScale
function editParam.init()
	local CustomHUD = CustomHUD
	paramTypes = CustomHUD.paramTypes
	toggleButton = CustomHUD.basicWidgets.toggleButton
	text = CustomHUD.basicWidgets.text
	basicWidgets = CustomHUD.basicWidgets
	translate = CustomHUD.translate
	logPcall = CustomHUD.logPcall
	xLimit = CustomHUD.gameWindowSize.w
	yLimit = CustomHUD.gameWindowSize.h
	editParam.widgetList = CustomHUD.widgetListEditor
	-- layoutScale = CustomHUD.layoutScale
end -- function editParam.init

editParam.paramSet = {
	inputTextWidth = {
		editor = 'number',
		optional = true,
		defaultValue = 0,
		args = {1, .1, 0, 420, '%u'},
		category = 'paramEditing',
	}, -- inputTextWidth = {...},
	inputTextLength = {
		editor = 'number',
		optional = true,
		defaultValue = 72,
		args = {1, .1, 24, 420, '%u'},
		category = 'paramEditing',
	}, -- inputTextLength = {...},
	dragFloatWidth = {
		editor = 'number',
		optional = true,
		defaultValue = 44,
		args = {1, .1, 36, 420, '%u'},
		category = 'paramEditing',
	}, -- dragFloatWidth = {...},
	colorComponentWidth = {
		editor = 'number',
		optional = true,
		defaultValue = 44,
		args = {1, .1, 36, 420, '%u'},
		category = 'paramEditing',
	}, -- colorComponentWidth = {...},
} -- editParam.paramSet = {...} --------------------------------------
local function showLabel(param)
	if param then
		text(translate('label', param))
		imgui.SameLine()
	end -- if label
end -- local function showLabel
function editParam.string(container, param)
	showLabel(param)
	imgui.PushItemWidth(editParam.inputTextWidth)
	local changed, newValue = logPcall(imgui.InputText, 'editparam.string(container, param)', '##' .. param, container[param], editParam.inputTextLength)
	imgui.PopItemWidth()
	if changed then container[param] = newValue end
	return changed
end -- function editparam.string ----------------------------------------------
function editParam.number(container, param, step, smallStep, min, max, formatString)
	local value = container[param]
	showLabel(param)
	imgui.PushItemWidth(editParam.dragFloatWidth)
	local changed1, newValue1 = logPcall(imgui.DragFloat, 'editParam.number(container, param, step, min, max, formatString)', '##' .. param, value, step, min, max, string.format(formatString, value))
	imgui.SameLine()
	local changed2, newValue2 = logPcall(imgui.DragFloat, 'editParam.number(container, param, step, min, max, formatString) - finetune', '##finetune' .. param, value, smallStep, min, max, smallStep .. 'x')
	imgui.PopItemWidth()
	if changed1 then
		container[param] = newValue1
	elseif changed2 then
		container[param] = newValue2
	end -- if changed1
	return changed1 or changed2
end -- function editParam.number
function editParam.listSelectOne(itemList, isSelected, callback, orientation)
	-- orientation defaults to vertical
	local changed = false
	imgui.BeginGroup()
		for i, itemName in ipairs(itemList) do
			-- print('i, itemName: ' .. i .. ', ' .. tostring(itemName))
			-- local selected = itemName == container[param]
			if toggleButton(translate('label', itemName), isSelected(i)) then
				callback(i)
			end -- toggleButton(translate('label', itemName), isSelected(i))
			if orientation == 'horizontal' then imgui.SameLine() end
		end -- for i, itemName in iter()
	imgui.EndGroup()
	-- return changed
end -- function editparam.listSelectOne
local function editLayoutParam(container, param, limit)
	local value = container[param]
	showLabel(param)
	imgui.PushItemWidth(editParam.dragFloatWidth)
	local changed1, newValue1 = logPcall(imgui.DragFloat, 'editParam.size(container, param, limit)', '##' .. param, value, .01, 0, 1, string.format('%.2f%%', value * 100))
	imgui.SameLine()
	local changed2, newValue2 = logPcall(imgui.DragFloat, 'editParam.size(container, param, limit) - fineTune', '##fineTune' .. param, value, .2 / limit, 0, 1, container.layout[param] .. 'px')
	imgui.PopItemWidth()
	if changed1 then
		return changed1, newValue1
	else
		return changed2, newValue2
	end -- if changed1
end -- local function editLayoutParam
function editParam.layout(container, param)
	local changed, newValue
	local anychange = false
	
	changed, newValue = editLayoutParam(container, 'x', (1 - container.w) * xLimit)
	if changed then
		container:setX(newValue)
		anychange = true
	end
	imgui.SameLine()
	changed, newValue = editLayoutParam(container, 'y', (1 - container.h) * yLimit)
	if changed then
		container:setY(newValue)
		anychange = true
	end
	
	if not container.autoResize then
		changed, newValue = editLayoutParam(container, 'w', xLimit)
		if changed then
			container:setWidth(newValue)
			anychange = true
		end
		imgui.SameLine()
		changed, newValue = editLayoutParam(container, 'h', yLimit)
		if changed then
			container:setHeight(newValue)
			anychange = true
		end
	end -- if not container.autoResize
	return anychange
end -- function editParam.layout
function editParam.boolean(container, param)
	local label = translate('label', param)
	local changed, newValue = imgui.Checkbox(label, container[param])
	if changed then container[param] = newValue end
	return changed
end -- function editParam.boolean
local function editWindowFlag(param, value, flag, invert)
	local newValue
	local label = translate('label', param)
	local checked = value == flag
	if invert then checked = not checked end
	local changed, newChecked = imgui.Checkbox(label, checked)
	if changed then
		if invert then newChecked = not newChecked end
		if newChecked then
			newValue = flag
		else
			newValue = ''
		end -- if newChecked
	end -- if changed
	return changed, newValue
end -- local function editWindowFlag
function editParam.windowFlagSet(container)
	local changed, newValue
	local anychange = false
	local windowFlagSet = container.windowFlagSet
	
	changed, newValue = editWindowFlag('showTitleBar', windowFlagSet[1], 'NoTitleBar', true)
	if changed then
		windowFlagSet[1] = newValue
		anychange = true
	end
	
	changed, newValue = editWindowFlag('showScrollBar', windowFlagSet[4],'NoScrollBar', true)
	if changed then
		windowFlagSet[4] = newValue
		anychange = true
	end
	
	changed, newValue = editWindowFlag('autoResize', windowFlagSet[5], 'AlwaysAutoResize')
	if changed then
		windowFlagSet[5] = newValue
		anychange = true
	end
	
	changed, newValue = editWindowFlag('allowMouseMove', windowFlagSet[3], 'NoMove', true)
	if changed then
		windowFlagSet[3] = newValue
		anychange = true
	end
	
	if not windowFlagSet[5] == 'AlwaysAutoResize' then
		changed, newValue = editWindowFlag('allowMouseResize', windowFlagSet[2], 'NoResize', true)
		if changed then
			windowFlagSet[2] = newValue
			anychange = true
		end
	end -- if not windowFlagSet[5] == 'AlwaysAutoResize'
	return anychange
end -- editParam.windowFlagSet
function editParam.color(container, param)
	showLabel(param)
	imgui.PushItemWidth(editParam.colorComponentWidth)
		for i = 1, 4 do
			imgui.SameLine()
			local changed, newValue = imgui.DragFloat('##' .. param .. i, container[param][i] * 255, 1, 0, 255, translate('label', 'rgba')[i] .. ':%.0f')
			if changed then container[param][i] = newValue / 255 end
		end -- for i = 1, 4
	imgui.PopItemWidth()
	imgui.SameLine()
	imgui.ColorButton(unpack(container[param]))
end -- function editParam.color

local function genericEdit(container, param)
	local changed
	local paramDef = container.paramSet[param] or paramTypes[param]
	if paramDef.editor == nil then return end
	if paramDef.args then
		changed = editParam[paramDef.editor](container, param, unpack(paramDef.args))
	else
		changed = editParam[paramDef.editor](container, param)
	end -- if paramDef.args
	if changed and paramDef.callback then paramDef.callback() end
end -- local function genericEdit
function editParam.editParamSet(container)
	local paramSet = container.paramSet
	if paramSet.categories then
		local function isSelected(i) return container.selected == i end
		local function callback(i) container.selected = i end
		editParam.listSelectOne(paramSet, isSelected, callback, 'horizontal')
		imgui.Separator()
		if container.selected then
			-- local changed
			-- local paramDef = paramSet[param]
			-- if paramDef.editor == nil then return end
			-- local type = paramSet[param].listItemClass
			genericEdit(container, container.selected)
		end -- if container.selected
	else
		for name, def in pairs(paramSet) do
			local paramName
			if type(def) == 'string' then
				paramName = def
			else
				paramName = name
			end -- if type(def) == 'string'
			genericEdit(container, paramName)
		end -- for name, def in pairs(paramSet)
	end -- if paramSet.categories
end -- function editParam.editParamSet

return {
	name = 'editParam',
	module = editParam,
	dependencies = {
		'state',
		'basicWidgets',
		'translate',
		'gameWindowSize',
		'paramTypes',
		-- 'widgetListEditor',
	}, -- dependencies = {...},
	usesGlobalOptions = true,
	persistent = true,
} -- return {...}