local neondebug = {}
local debuglist = {}

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