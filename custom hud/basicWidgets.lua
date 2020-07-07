local imgui = imgui
local basicWidgets = {}
basicWidgets.paramSet = {
	textColor = {
		editor = 'color',
		optional = true,
		defaultValue = {.8, .8, .8, 1},
		category = 'defaultColors',
	}, -- textColor = {...},
	buttonSelectedColor = {
		editor = 'color',
		optional = true,
		defaultValue = {.2, .5, 1, 1},
		category = 'defaultColors',
	}, -- buttonSelectedColor = {...},
	buttonHoveredColor = {
		editor = 'color',
		optional = true,
		defaultValue = {.3, .7, 1, 1},
		category = 'defaultColors',
	}, -- buttonHoveredColor = {...},
	buttonActiveColor = {
		editor = 'color',
		optional = true,
		defaultValue = {.5, .9, 1, 1},
		category = 'defaultColors',
	}, -- buttonActiveColor = {...},
} -- basicWidgets.paramSet = {...}

function basicWidgets.text(text, textColor)
	local color = textColor or basicWidgets.textColor
	CustomHUD.logPcall(imgui.TextColored, 'basicWidgets.text(text, textColor)', color[1], color[2], color[3], color[4], text)
end -- function basicWidgets.text
function basicWidgets.label(param)
	if param then
		basicWidgets.text(translate('label', param))
		imgui.SameLine()
	end -- if label
end -- function basicWidgets.label
function basicWidgets.toggleButton(label, selected)
	if selected then
		imgui.PushStyleColor('Button', unpack(basicWidgets.buttonSelectedColor))
		imgui.PushStyleColor('ButtonHovered', unpack(basicWidgets.buttonHoveredColor))
		imgui.PushStyleColor('ButtonActive', unpack(basicWidgets.buttonActiveColor))
	end
	local clicked = imgui.Button(label)
	if selected then imgui.PopStyleColor(3) end
	return clicked
end -- function basicWidgets.toggleButton

local registerGlobalOptions = {
	name = 'registerBasicWidgetsGlobalOptions',
	description = 'register basic widgets with global options',
	dependencies = {'globalOptions'},
	run = function()
		CustomHUD.globalOptions.register'basicWidgets'
		return 'complete'
	end, -- run = function
} -- local registerGlobalOptions = {...}
-- function basicWidgets.init()
	-- basicWidgets.state = CustomHUD.state.register('basicWidgets', defaultOptions)
-- end -- function basicWidgets.init
return {
	name = 'basicWidgets',
	module = basicWidgets,
	-- newTasks = {registerGlobalOptions},
	dependencies = {'state'},
	usesGlobalOptions = true,
	persistent = true,
}
