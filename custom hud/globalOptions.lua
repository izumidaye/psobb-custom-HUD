-- semi-dependents: mainWindow, editParam, basicWidgets
local CustomHUD = CustomHUD
local globalOptions = {}
local compareIgnoreCase, editParam
function globalOptions.init()
	compareIgnoreCase = CustomHUD.utility.compareIgnoreCase
	editParam = CustomHUD.editParam
end -- function globalOptions.init

local function presentOption(category, paramName)
	local changed
	local paramDef = category[paramName]
	local container = CustomHUD[paramDef.container]
	-- local state = container.state
	if paramDef.args then
		changed = editParam[paramDef.type](container, paramName, unpack(paramDef.args))
	else
		changed = editParam[paramDef.type](container, paramName)
	end
	if changed and paramDef.callback then paramDef.callback() end
end -- local function presentOption
local function present()
	editParam.listSelectOne(globalOptions, 'selected', globalOptions, 'horizontal')
	if globalOptions.selected then
		local category = globalOptions[globalOptions.selected]
		for _, paramName in ipairs(category) do
			presentOption(category, paramName)
		end -- for _, optionname in ipairs(globaloptions[categoryname])
	end -- if globalOptions.selected
end -- local function present
local function presentCategoryList()
	
end -- local function presentCategoryList
function globalOptions.register(moduleName)
	local newCategory = false
	local modifiedCategories = {}
	for paramName, paramDef in pairs(CustomHUD[moduleName].paramSet) do
		if paramDef.edit then
			local category = paramDef.category
			if not globalOptions[category] then
				globalOptions[category] = {}
				table.insert(globalOptions, category)
				newCategory = true
			end -- if not globalOptions[category]
			paramDef.container = moduleName
			globalOptions[category][paramName] = paramDef
			table.insert(globalOptions[category], paramName)
			modifiedCategories[paramDef.category] = true
		end -- if paramDef.edit
	end -- for paramName, paramDef in pairs(CustomHUD[moduleName].paramSet)
	if newCategory then table.sort(globalOptions, compareIgnoreCase) end
	for category, _ in pairs(modifiedCategories) do
		table.sort(globalOptions[category], compareIgnoreCase)
	end -- for category, _ in pairs(modifiedCategories)
	-- if not globalOptions.selected then globalOptions.selected = moduleName end
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
		CustomHUD.mainWindow.addMenuItem{
			menuName = 'CustomHUD',
			menuItem = menuItem,
		} -- CustomHUD.mainWindow.addMenuItem{...}
		return 'complete'
	end, -- run = function
} -- local registerWithMainWindow = {...}

return {
	name = 'globalOptions',
	module = globalOptions,
	dependencies = {'state', 'utility', 'editParam'},
	newTasks = {registerWithMainWindow},
} -- return {...}
