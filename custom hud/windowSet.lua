local windowSet = {}
local editList, restoreElement, createElement, CustomWindow, paramTypes
local function restoreWindows(set)
	for _, window in ipairs(set) do
		restoreElement(window)
	end -- for _, window in ipairs(set)
	set.interface = CustomHUD.basicListInterface
end -- local function restoreWindows
function windowSet.init()
	editList = CustomHUD.editList.edit
	restoreElement = CustomHUD.elementBuilder.restore
	createElement = CustomHUD.elementBuilder.create
	CustomWindow = CustomHUD.CustomWindow
	paramTypes = CustomHUD.paramTypes
	restoreWindows(windowSet.generalSet)
end -- function windowSet.init

windowSet.paramSet = {
	useCharacterSpecificWindowSet = {
		editor = 'boolean',
		defaultValue = false,
		callback = nil,
		category = 'general',
	}, -- characterSpecific = {...}
	generalSet = {
		-- editor = 'list',
		listItemClass = 'CustomWindow',
		defaultValue = {editorState = {}}
	},
} -- windowSet.paramSet = {...}
windowSet.characterParamSet = {
	characterSet = {defaultValue = {editorState = {}}},
} -- windowSet.characterParamSet = {...}

local function editElement(element)
	
end -- local function editElement
local function present()
	editList(windowSet.generalSet)
-- character-specific window list
	if windowSet.generalSet.editorState.selected then
	end
-- add / remove window
-- window presets
	if imgui.Button'add window' then
		table.insert(windowSet.generalSet, createElement(CustomWindow))
		windowSet.generalSet.editorState.remap = true
	end -- if imgui.Button'add window'
end -- local function present

local registerWithMainWindow = {
	name = 'registerMainEditorWithMainWindow',
	description = 'register main editor view with main window',
	dependencies = {'mainWindow'},
	run = function()
		local setActiveView = CustomHUD.mainWindow.setActiveView
		local menuItem = {
			name = 'mainEditor',
			activate = function() setActiveView('mainEditor') end
		} -- local menuItem = {...}
		CustomHUD.mainWindow.addView('mainEditor', present)
		CustomHUD.mainWindow.addMenuItem{
			menuName = 'CustomHUD',
			menuItem = menuItem
		} -- CustomHUD.mainWindow.addMenuItem{...}
		return 'complete'
	end, -- run = function
} -- local registerWithMainWindow = {...}

return {
	name = 'windowSet',
	module = windowSet,
	usesGlobalOptions = true,
	persistent = true,
	dependencies = {'editList', 'basicListInterface', 'elementBuilder', 'CustomWindow', 'paramTypes'},
	newTasks = {registerWithMainWindow},
}