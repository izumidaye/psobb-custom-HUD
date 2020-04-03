local logger = {}
local loggingenabled = false
local timeout = {}
local timeoutlength = 5
local enabledtypes = {}
local starttime = os.clock()

logger.loadlanguage = function(languagetable)
	windowtitle = languagetable.windowtitle.logger
end -- logger.loadlanguage
local function buildfilename(debugtype)
	return os.date('addons/custom hud/log/%F ') .. debugtype .. '.txt'
end -- local function buildfilename
local function writetolog(text, debugtype)
	debugtype = debugtype or ''
	local file = io.open(buildfilename(debugtype), 'a')
	if file then
		io.output(file)
		io.write(text)
		io.close(file)
	end
end -- local function writetolog
local function timestamp()
	local milliseconds = string.format('%.3f', os.clock() - starttime)
	return os.date('%T|' .. milliseconds .. '> ')
end
-- local function timestamp() return os.clock() .. '> ' end
logger.enablelogging = function(debugtype, newtimeoutlength)
	enabledtypes[debugtype] = true
	timeoutlength = newtimeoutlength or timeoutlength
	loggingenabled = true
	debugtype = debugtype or ''
	local file = io.open(buildfilename(debugtype), 'w')
	if file then
		io.output(file)
		io.write(timestamp() .. 'session log start\n')
		io.close(file)
	end
	-- writetolog('\n\n'.. timestamp() .. 'session log start\n')
end -- logger.enablelogging = function
logger.alwayslog = function(message, debugtype)
	if loggingenabled and enabledtypes[debugtype] then
		writetolog(timestamp() .. message .. '\n', debugtype)
	end
end -- logger.alwayslog = function
logger.log = function(message, debugtype)
	if loggingenabled and enabledtypes[debugtype] then
		if timeout[message] and os.time() < timeout[message] then
			-- too soon to log another message
			return
		else -- timeout expired; restart timeout
			writetolog(timestamp() .. message .. '\n', debugtype)
			timeout[message] = os.time() + timeoutlength
		end
	end
end -- logger.log = function

return {name = 'logger', module = logger}
