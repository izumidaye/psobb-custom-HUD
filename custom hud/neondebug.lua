local neondebug = {}
local debuglist = {}
local loggingenabled = false
local timeout = {}

local function writetolog(text)
	local file = io.open('addons/Custom HUD/log' .. os.date('%F') .. '.txt', 'a')
	if file then
		io.output(file)
		io.write(text)
		io.close(file)
	end
end

local function timestamp() return os.date('%T> ') end

neondebug.enablelogging = function()
	loggingenabled = true
	writetolog('\n\n'.. timestamp() .. 'session log start\n')
end

neondebug.log = function(message, timeoutlength)
	if timeoutlength then
		if timeout[message] and os.time() < timeout[message] then
			-- too soon to log another message
			return
		else -- timeout expired; restart timeout
			timeout[message] = os.time() + timeoutlength
		end
	end
	
	if loggingenabled then writetolog(timestamp() .. message .. '\n') end
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
	
	imgui.End()
	return stayopen
end

return neondebug
