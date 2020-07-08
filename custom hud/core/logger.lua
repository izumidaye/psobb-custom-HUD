local logger = {}
local loggingEnabled, enabledTypes
local loggingEnabled = false
local enabledTypes = {}
local startTime = os.clock()
local windowTitle = ''
logger.logs = {}

logger.loadLanguage = function(languageTable)
	windowTitle = languageTable.windowTitle.logger
end -- logger.loadLanguage
local function buildFileName(debugType)
	return os.date('addons/custom hud/log/%F ') .. debugType .. '.txt'
end -- local function buildFileName
local function writeToLog(text, debugType)
	debugType = debugType or ''
	local file = io.open(buildFileName(debugType), 'a')
	if file then
		io.output(file)
		io.write(text)
		io.close(file)
	end
	table.insert(logger.logs[debugType], text)
end -- local function writeToLog
local function timeStampString()
	local milliseconds = string.format('%.3f', os.clock() - startTime)
	return os.date('%T|' .. milliseconds .. '> ')
end
-- local function timeStampString() return os.clock() .. '> ' end
function logger.enableLogging(debugType)
	enabledTypes[debugType] = true
	logger.logs[debugType] = {}
	table.insert(logger.logs, debugType)
	-- maybe sort logger.logs?
	loggingEnabled = true
	debugType = debugType or ''
	local logStartText = timeStampString() .. 'session log start\n'
	local file = io.open(buildFileName(debugType), 'w')
	if file then
		io.output(file)
		io.write(logStartText)
		io.close(file)
	end
	table.insert(logger.logs[debugType], logStartText)
	-- writeToLog('\n\n'.. timeStampString() .. 'session log start\n')
end -- function logger.enableLogging
function logger.log(message, debugType)
	if loggingEnabled and enabledTypes[debugType] then
		writeToLog(timeStampString() .. message .. '\n', debugType)
	end
end -- function logger.log

return {name = 'logger', module = logger}
