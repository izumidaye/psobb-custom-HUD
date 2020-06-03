local logger = {}
local loggingEnabled = false
local timeout = {}
local timeoutLength = 5
local enabledTypes = {}
local startTime = os.clock()
logger.logs = {}

logger.loadLanguage = function(languagetable)
	windowtitle = languagetable.windowtitle.logger
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
local function timeStamp()
	local milliseconds = string.format('%.3f', os.clock() - startTime)
	return os.date('%T|' .. milliseconds .. '> ')
end
-- local function timeStamp() return os.clock() .. '> ' end
function logger.enableLogging(debugType, newTimeoutLength)
	enabledTypes[debugType] = true
	logger.logs[debugType] = {}
	table.insert(logger.logs, debugType)
	-- maybe sort logger.logs?
	timeoutLength = newTimeoutLength or timeoutLength
	loggingEnabled = true
	debugType = debugType or ''
	local logStartText = timeStamp() .. 'session log start\n'
	local file = io.open(buildFileName(debugType), 'w')
	if file then
		io.output(file)
		io.write(logStartText)
		io.close(file)
	end
	table.insert(logger.logs[debugType], logStartText)
	-- writeToLog('\n\n'.. timeStamp() .. 'session log start\n')
end -- function logger.enableLogging
function logger.alwaysLog(message, debugType)
	if loggingEnabled and enabledTypes[debugType] then
		writeToLog(timeStamp() .. message .. '\n', debugType)
	end
end -- function logger.alwaysLog
function logger.log(message, debugType)
	if loggingEnabled and enabledTypes[debugType] then
		if timeout[message] and os.time() < timeout[message] then
			-- too soon to log another message
			return
		else -- timeout expired; restart timeout
			writeToLog(timeStamp() .. message .. '\n', debugType)
			timeout[message] = os.time() + timeoutLength
		end
	end
end -- function logger.log

return {name = 'logger', module = logger}
