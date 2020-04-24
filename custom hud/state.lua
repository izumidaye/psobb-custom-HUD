--[[
Custom HUD - state
catherine s (izumidaye/neonluna)
2020-04-03
Responsible for saving and loading all persistent data used by Custom HUD.
]] ----------------------------------------------------------------------------

local interface, state, profile, characterName do
	interface = {}
end

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
	if not state[moduleName] then
		state[moduleName] = CustomHUD[moduleName].defaultParamValues
	end
	CustomHUD[moduleName].state = state[moduleName]
end -- function interface.register
local function saveString(fileName, stringToSave)
	local outputFile = io.open('addons/custom hud/' .. fileName .. '.lua', 'w')
	if outputFile then
		file:write(stringToSave)
		file:close()
	end -- if outputFile
end -- local function saveString
local function loadState()
	-- print(type(pso.list_directory_files))
	-- local success, tempState = CustomHUD.logPcall(require, 'state / local function loadState / require(filename)', 'custom hud.profile.state')
	local success, tempState = pcall(require, 'custom hud.profile.state')
	if success then state = tempState end
	return success
end -- local function loadState
local function saveState()
	local outputString = 'return\n' .. CustomHUD.serialize(state)
	saveString('profile/state', outputString)
end -- local function saveState

function interface.init()
	if loadState() then
		CustomHUD.logMain'Successfully loaded saved profile.'
	else
		CustomHUD.logMain'Failed loading profile. Initializing new profile.'
		state = {}
	end
end -- function interface.init
return {name = 'state', module = interface}