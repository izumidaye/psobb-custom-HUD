local basicWidgets = {}
basicWidgets.defaultParamValues = {
	textColor = {.8, .8, .8, 1},
	buttonSelectedColor = {.2, .5, 1, 1},
	buttonHoveredColor = {.3, .7, 1, 1},
	buttonActiveColor = {.5, .9, 1, 1},
}
basicWidgets.paramSet = {
	{name = 'textColor', type = 'color'},
}

function basicWidgets.text(text, textColor)
	local color = textColor or basicWidgets.state.textColor
	CustomHUD.logPcall(imgui.TextColored, 'basicWidgets.text(text, textColor)', color[1], color[2], color[3], color[4], text)
end -- function basicWidgets.text
function basicWidgets.toggleButton(label, selected)
	if selected then
		imgui.PushStyleColor('Button', .2, .5, 1, 1)
		imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
		imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
	end
	
	if selected then imgui.PopStyleColor(3) end
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
	-- usesGlobalOptions = true,
	persistent = true,
}
