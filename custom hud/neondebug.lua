local neondebug = {}
local debuglist = {}
local loggingenabled = false
local timeout = {}
local timeoutlength = 5
local enabledtypes = {}

local function buildfilename(debugtype)
	return os.date('addons/custom hud/log %F ') .. debugtype .. '.txt'
end

local function writetolog(text, debugtype)
	debugtype = debugtype or ''
	local file = io.open(buildfilename(debugtype), 'a')
	if file then
		io.output(file)
		io.write(text)
		io.close(file)
	end
end

local function timestamp() return os.date('%T> ') end

neondebug.enablelogging = function(debugtype, newtimeoutlength)
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
end

neondebug.alwayslog = function(message, debugtype)
	if loggingenabled and enabledtypes[debugtype] then
		writetolog(timestamp() .. message .. '\n', debugtype)
	end
end

neondebug.log = function(message, debugtype)
	if loggingenabled and enabledtypes[debugtype] then
		if timeout[message] and os.time() < timeout[message] then
			-- too soon to log another message
			return
		else -- timeout expired; restart timeout
			writetolog(timestamp() .. message .. '\n', debugtype)
			timeout[message] = os.time() + timeoutlength
		end
	end
end

neondebug.update = function(key, value)
-- don't use integer keys! those are reserved for ordering the list.
	-- if value then value = ': ' .. value else value = '' end
	value = value or ''
	if not debuglist[key] then table.insert(debuglist, key) end
	debuglist[key] = value
end

neondebug.present = function()
	imgui.SetNextWindowSize(600, 300, 'FirstUseEver')
	local stayopen
	_, stayopen = imgui.Begin('Custom HUD Debug Window', true, 'AlwaysAutoResize')
	-- local gfs = data['global font scale'] or 1
	-- imgui.SetWindowFontScale(gfs)
	
	for _, k in ipairs(debuglist) do
		if debuglist[k] then
			imgui.Text(k .. ': ' .. debuglist[k])
		else
			print('something went wrong')
		end
	end
	
	-- local changed, newValue = imgui.InputInt('##checkMemoryOffset', checkMemoryOffset)
	-- imgui.SameLine()
	-- if changed then checkMemoryOffset = newValue end
	-- showText({1,1,1,1}, '+' .. checkMemoryOffset .. ': ' .. pso.read_u32(0x00A97F44 + checkMemoryOffset))
	
	imgui.End()
	return stayopen
end

return neondebug
