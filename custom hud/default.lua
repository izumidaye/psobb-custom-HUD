local defaultvalue = {}

defaultvalue['color'] = function() return {.5, .5, .5, 1} end

defaultvalue['text color'] = function() return {.8, .8, .8, 1} end

defaultvalue['background color'] = function() return {.1, .1, .1, .5} end

defaultvalue['inputtext buffer size'] = 72

return function(valuename)
	if type(defaultvalue[valuename]) == 'function' then
		return defaultvalue[valuename]()
	else
		return defaultvalue[valuename]
	end
end