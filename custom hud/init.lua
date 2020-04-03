--[[
psobb dynamic info addon
catherine s (izumidaye/neonluna)
2018-10-05
]] ----------------------------------------------------------------------------
require'custom hud.customhud'

local coremodules = {'serialize', 'logger', 'tasks', 'displaylist'}
local function loadcoremodule(modulename)
	local tempmodule = require('custom hud.core.' .. modulename)
	if tempmodule then
		customhud[tempmodule.name] = tempmodule.module
		-- print('custom hud > loaded core module [' .. tempmodule.name .. ']')
		return true
	else
		print('custom hud > failed loading core module [' .. modulename .. ']')
		return false
	end -- if tempmodule
end -- local function loadcoremodule
local function loadallcoremodules()
	local success = true
	for _, modulename in ipairs(coremodules) do
		success = success and loadcoremodule(modulename)
	end -- for _, modulename in ipairs(coremodules)
	return success
end -- local function loadallcoremodules
local function loadbasicmodules()
	for _, modulename in ipairs(modules) do
		customhud.tasks.addtask{
			name = modulename,
			description = 'load module [' .. modulename .. ']',
			run = function() return require('custom hud.' .. modulename) end,
		} -- customhud.tasks.addtask{...}
	end -- for _, modulename in ipairs(modules)
end -- local function loadbasicmodules

local function present()
	customhud.displaylist.runall()
	customhud.tasks.run()
end -- local function present
local customhudaddon = {
	name = 'custom hud',
	version = '0.6',
	author = 'izumidaye',
	description = 'build your own customized hud',
}
local function init()
	-- customhud.displaylist['show startup progress window'] = showstartupprogresswindow
	local coreloadstarttime = os.clock()
	local success = loadallcoremodules()
	local coreloadtimetaken = os.clock() - coreloadstarttime
	if success then
		customhud.logmain(string.format('successfully loaded core modules %s in %.3fs', customhud.serialize(coremodules), coreloadtimetaken))
		customhud.logger.enablelogging('error', 5)
		customhud.logger.enablelogging('main', 5)
		customhudaddon.present = present
		require'core_mainmenu'.add_button('custom hud', function()
			customhud.displaylist.toggle'mainwindow'
		end)
		customhud.init()
	else
		print'custom hud > startup failed - one or more core modules failed to load.'
		customhudaddon.present = customhud.nilfunction
	end
	return customhudaddon
end -- local function init

return {__addon = {init = init}}
