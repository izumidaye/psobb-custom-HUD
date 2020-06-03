CustomHUD = {
	nilFunction = function() end,
	startTime   = os.clock(),
	brokenComponents = {},
	widgets = {},
}
local CustomHUD = CustomHUD
local components = {
	'state',
	'utility',
	'Window',
	'basicWidgets',
	'psoData',
	'layoutScale',
	'editParam',
	'globalOptions',
	'mainWindow',
	'logView',
}
local callbacks = {}

function CustomHUD.logMain(message)
	-- print('custom hud > ' .. message)
	CustomHUD.logger.log(message, 'main')
end -- function CustomHUD.logMain
function CustomHUD.logPcall(f, desc, ...)
	local results = {pcall(f, ...)}
	local success = table.remove(results, 1)
	if not success then
		local errorMessage = CustomHUD.serialize({desc, results, ...})
		print(errorMessage)
		CustomHUD.logger.log(errorMessage, 'error')
	else
		return unpack(results)
	end -- if not success
end -- function CustomHUD.logPcall
function CustomHUD.loadModule(moduleName)
	local tempModule = CustomHUD.logPcall(require, 'CustomHUD.loadModule/require(moduleName)', 'custom hud.' .. moduleName)
	if tempModule == nil then
		CustomHUD.brokenComponents[moduleName] = true
		return 'failure'
	else
		return tempModule
	end -- if tempModule == nil
end -- function CustomHUD.loadModule
function CustomHUD.addModule(name, newModule)
	CustomHUD[name] = newModule
	local moduleFields = {}
	for fieldName, _ in pairs(newModule) do
		table.insert(moduleFields, fieldName)
	end -- for fieldName, _ in newModule
	CustomHUD.logMain('loaded module [' .. name .. ']')
	CustomHUD.logger.alwaysLog('loaded module [' .. name .. ']', 'startup')
	CustomHUD.logger.alwaysLog('fields: ' .. CustomHUD.serialize(moduleFields), 'startup')
end -- function CustomHUD.addModule
function CustomHUD.addWidget(name, newWidget)
	CustomHUD.widgets[name] = newWidget
	CustomHUD.logMain('loaded widget [' .. name .. ']')
end -- function CustomHUD.addWidget
function CustomHUD.registerCallback(eventName, callback)
	if not callbacks[eventName] then callbacks[eventName] = {} end
	table.insert(callbacks[eventName], callback)
end -- function CustomHUD.registerCallback
function CustomHUD.event(eventName, ...)
if callbacks[eventName] then
	for _, callback in pairs(callbacks[eventName]) do
		callback(...)
	end -- for _, callback in pairs(callbacks[eventName])
end -- if callbacks[eventName]
end -- function CustomHUD.event
function CustomHUD.addToGlobalOptions(moduleName)
	CustomHUD.tasks.add{
		name = moduleName .. 'GlobalOptionsRegister',
		description = 'register ' .. moduleName .. ' with globalOptions',
		dependencies = {'globalOptions'},
		run = function()
			CustomHUD.globalOptions.register(moduleName)
			return 'complete'
		end, -- run = function
	} -- CustomHUD.tasks.add{...}
end -- function CustomHUD.addToGlobalOptions
function CustomHUD.processTaskResult(result)
	if result.newTasks then
		for _, newTask in ipairs(result.newTasks) do
			CustomHUD.tasks.add(newTask)
		end
	end -- if result.newTasks
	
	if result.window then
		CustomHUD.displayList.add(result.window)
	end -- if result.displayFunctions
	
	if result.module then
		CustomHUD.addModule(result.name, result.module)
		
		if result.persistent then CustomHUD.state.register(result.name) end
		
		if result.inherits then
			setmetatable(result.module, CustomHUD[result.inherits])
		end -- if result.inherits
		
		if result.usesGlobalOptions then
			CustomHUD.addToGlobalOptions(result.name)
		end -- if result.usesGlobalOptions
		
		if result.module.init then result.module.init() end
	end -- if result.module
	
	if result.widget then
		CustomHUD.addWidget(result.name, result.widget)
		if result.widget.init then result.widget.init() end
	end -- if result.widget
end -- function CustomHUD.processTaskResult
function CustomHUD.loadLanguage(languageName)
	if not CustomHUD.languageTable then
		CustomHUD.languageTable = {}
	end
	local tempLanguageTable = require('custom hud.languages.' .. languageName)
	if tempLanguageTable then
		for categoryName, category in pairs(tempLanguageTable) do
			CustomHUD.languageTable[categoryName] = category
		end -- for categoryName, category in pairs(tempLanguageTable)
		return 'complete'
	else
		return 'incomplete'
	end -- if tempLanguageTable
end -- function CustomHUD.loadLanguage
function CustomHUD.translate(category, name)
	local result
	if CustomHUD.languageTable[category] then
		result = CustomHUD.languageTable[category][name]
		if not result then
			result = name .. ' not found'
		end -- if result
	else
		result = 'category ' .. category .. ' not found'
	end -- if languageTable[category]
	return result
end -- function CustomHUD.translate
local function registerComponentLoaderTasks()
	for _, moduleName in ipairs(components) do
		CustomHUD.tasks.add{
			name = moduleName,
			description = 'load module [' .. moduleName .. ']',
			run = function()
				return CustomHUD.loadModule(moduleName)
			end,
		} -- customhud.tasks.addtask{...}
	end -- for _, moduleName in ipairs(modules)
end -- local function registerComponentLoaderTasks
function CustomHUD.init()
	CustomHUD.tasks.add{
		name = 'loadLanguageTable',
		description = 'load language table',
		run = function() return CustomHUD.loadLanguage 'english' end,
	} -- CustomHUD.tasks.add{loadLanguageTable...}
	-- CustomHUD.init = CustomHUD.nilFunction
	registerComponentLoaderTasks()
end -- function CustomHUD.init
function CustomHUD.present()
	CustomHUD.displayList.runAll()
	CustomHUD.tasks.run()
end -- function CustomHUD.present
