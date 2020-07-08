--[[
psobb dynamic info addon
catherine s (izumidaye/neonluna)
2018-10-05
]] ----------------------------------------------------------------------------
require 'custom hud.CustomHUD'
local CustomHUD = CustomHUD

local coreModules = {'serialize', 'logger', 'displayList', 'tasks'}
local function loadCoreModule(modulename)
	local tempmodule = CustomHUD.loadModule('core.' .. modulename)
	if tempmodule then
		CustomHUD[tempmodule.name] = tempmodule.module
		-- print('custom hud > loaded core module [' .. tempmodule.name .. ']')
		return true
	else
		print('custom hud > failed loading core module [' .. modulename .. ']')
		return false
	end -- if tempmodule
end -- local function loadCoreModule
local function loadAllCoreModules()
	local success = true
	for _, modulename in ipairs(coreModules) do
		success = success and loadCoreModule(modulename)
	end -- for _, modulename in ipairs(coremodules)
	return success
end -- local function loadAllCoreModules

local function present()
	CustomHUD.present()
end -- local function present
local addonCustomHUD = {
	name = 'custom hud',
	version = '0.6',
	author = 'izumidaye',
	description = 'build your own customized hud',
} -- local addonCustomHUD = {...}
local function init()
	-- customhud.displaylist['show startup progress window'] = showstartupprogresswindow
	local coreLoadTimeStart = os.clock()
	local success = loadAllCoreModules()
	local coreloadtimetaken = os.clock() - coreLoadTimeStart
	if success then
		CustomHUD.logger.enableLogging('psoGlobalTable')
		local psoGlobalTable = CustomHUD.serialize(pso, 0, true)
		CustomHUD.logger.log(psoGlobalTable, 'psoGlobalTable')
		local fontFiles = CustomHUD.serialize(pso.list_font_files())
		CustomHUD.logger.log(fontFiles, 'psoGlobalTable')
		CustomHUD.logger.enableLogging('error')
		CustomHUD.logger.enableLogging('main')
		CustomHUD.logger.enableLogging('startup')
		CustomHUD.logger.enableLogging('debug')
		CustomHUD.logger.log(string.format('loaded core modules %s in %.3fs', CustomHUD.serialize(coreModules), coreloadtimetaken), 'startup')
		addonCustomHUD.present = CustomHUD.present
		CustomHUD.init()
	else
		print'custom hud > startup failed - one or more core modules failed to load.'
		addonCustomHUD.present = CustomHUD.nilFunction
	end -- if success
	return addonCustomHUD
end -- local function init

return {__addon = {init = init}}
