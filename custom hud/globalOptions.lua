-- semi-dependents: mainWindow, editParam, basicWidgets
local globalOptions, interface, compareIgnoreCase, editParam do
	globalOptions = {}
	interface = {}
end

local function presentOption(container, paramIndex)
	local changed, newValue
	local paramDef = container.paramSet[paramIndex]
	local state = container.state
	if paramDef.args then
		changed = editParam[paramDef.type](state, paramDef.name, unpack(paramDef.args))
	else
		changed = editParam[paramDef.type](state, paramDef.name)
	end
	if changed and paramDef.callback then paramDef.callback() end
end -- local function presentOption
local function present()
	if selectedCategory then
		local category = globalOptions[selectedCategory]
		for i = 1, #category.paramSet do
			presentOption(category, i)
		end -- for _, optionname in ipairs(globaloptions[categoryname])
	end -- if selectedCategory
end -- local function present
local function presentCategoryList()
	
end -- local function presentCategoryList
function interface.register(moduleName)
	globalOptions[moduleName] = CustomHUD[moduleName]
	table.insert(globalOptions, moduleName)
	table.sort(globalOptions, CustomHUD.utility.compareignorecase)
	if not selectedCategory then selectedCategory = moduleName end
end -- function globalOptions.register

local menuItem = {
	name = 'globalOptions',
	activate = function()
		CustomHUD.mainWindow.setActiveView('globalOptions')
	end -- activate = function
} -- menuItem = {...}
local registerWithMainWindow = {
	name = 'registerGlobalOptionsWithMainWindow',
	description = 'register global options with main window',
	dependencies = {'mainWindow'},
	run = function()
		CustomHUD.mainWindow.addView('globalOptions', present)
		CustomHUD.mainWindow.addMenuItem('CustomHUD', menuItem)
		return 'complete'
	end, -- run = function
} -- local registerWithMainWindow = {...}

function interface.init()
	-- globalOptions = CustomHUD.state.register('globalOptions')
	compareIgnoreCase = CustomHUD.utility.compareIgnoreCase
	editParam = CustomHUD.editParam
end -- function interface.init
return {
	name = 'globalOptions',
	module = interface,
	newTasks = {registerWithMainWindow},
	dependencies = {'state', 'utility', 'editParam'},
} -- return {...}
