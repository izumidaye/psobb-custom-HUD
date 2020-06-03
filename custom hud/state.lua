--[[
Custom HUD - state
catherine s (izumidaye/neonluna)
2020-04-03
Responsible for saving and loading all persistent data used by Custom HUD.
]] ----------------------------------------------------------------------------

local interface, state, profile, openSavePopup, saveStatus, characterName, utility, translate do
	interface = {}
end
local CustomHUD = CustomHUD

function interface.get(fieldName)
	return state[fieldName]
end -- function interface.get
function interface.set(fieldName, newValue)
	state[fieldName] = newValue
end -- function interface.set
function interface.toggle(fieldName)
	state[fieldName] = not state[fieldName]
end -- function interface.toggle
function interface.setCharacter(newCharacterName)
	characterName = newCharacterName
	local profileFileName = 'custom hud.profile.' .. characterName
	local tempProfile = require(profileFileName)
	if tempProfile then
		profile = tempProfile
	end
end -- function interface.setCharacter
function interface.register(moduleName)
	local module = CustomHUD[moduleName]
	if not state[moduleName] then
		state[moduleName] = {}
		for paramName, paramDef in pairs(module.paramSet) do
			if paramDef.defaultValues then
				utility.copyIntoTable{
					source = paramDef.defaultValues,
					dest = state[moduleName]
				}
			else
				if type(paramDef.defaultValue) == 'table' then
					state[moduleName][paramName] = utility.copyTable(paramDef.defaultValue)
				else
					state[moduleName][paramName] = paramDef.defaultValue
				end -- if type(paramDef.defaultValue) == 'table'
			end -- if paramDef.defaultValues
		end -- for paramName, paramDef in pairs(module.paramSet)
	end -- if not state[moduleName]
	utility.copyIntoTable{source = state[moduleName], dest = module}
end -- function interface.register
local function saveString(fileName, stringToSave)
	local outputFile = io.open('addons/custom hud/' .. fileName .. '.lua', 'w')
	if outputFile then
		outputFile:write(stringToSave)
		outputFile:close()
		return true
	else
		return false
	end -- if outputFile
end -- local function saveString
local function loadState()
	-- print(type(pso.list_directory_files))
	-- local success, tempState = CustomHUD.logPcall(require, 'state / local function loadState / require(filename)', 'custom hud.profile.state')
	local success, tempState = pcall(require, 'custom hud.profile.state')
	if success then state = tempState end
	return success
end -- local function loadState
local function updateState()
	for moduleName, valueTable in pairs(state) do
		local module = CustomHUD[moduleName]
		for paramName, paramDef in pairs(module.paramSet) do
			if paramDef.members then
				for _, memberName in ipairs(paramDef.members) do
					valueTable[memberName] = module[memberName]
				end -- for _, memberName in ipairs(paramDef.members)
			elseif module[paramName] then
				valueTable[paramName] = module[paramName]
			end -- if paramDef.members
		end -- for paramName, paramDef in pairs(module.paramSet)
	end -- for moduleName, valueTable in pairs(state)
end -- local function updateState
local function saveState()
	updateState()
	local outputString = 'return\n' .. CustomHUD.serialize(state)
	if saveString('profile/state', outputString) then
		saveStatus = os.date('%F | %T\n' .. translate('message', 'saveSuccessful'))
	else
		saveStatus = translate('message', 'saveFailed')
	end
	openSavePopup = true
end -- local function saveState

local function showSaveStatusPopup()
	if openSavePopup then
		imgui.OpenPopup('saveStatus')
		openSavePopup = false
	end -- if openSavePopup
	if imgui.BeginPopup('saveStatus') then
		imgui.Text(saveStatus)
		if imgui.Button(translate('label', 'close')) then imgui.CloseCurrentPopup() end
	imgui.EndPopup() end
end -- local function showSaveStatusPopup
local menuItem = {name = 'save', activate = saveState, type = 'item'}
local registerWithMainWindow = {
	name = 'mainWindowAddSaveButton',
	description = 'add "save" button to main window',
	dependencies = {'mainWindow'},
	run = function()
		CustomHUD.mainWindow.addMenuItem{menuName = 'CustomHUD', menuItem = menuItem}
		return 'complete'
	end, -- run = function
} -- local registerWithMainWindow = {...}

function interface.init()
	utility = CustomHUD.utility
	translate = CustomHUD.translate
	if loadState() then
		CustomHUD.logMain'Successfully loaded saved profile.'
	else
		CustomHUD.logMain'Failed loading profile. Initializing new profile.'
		state = {}
	end
end -- function interface.init
return {
	name = 'state',
	module = interface,
	dependencies = {'utility', 'translate'},
	newTasks = {registerWithMainWindow},
	window = {name = 'saveStatusPopup', displayFunction = showSaveStatusPopup},
}
