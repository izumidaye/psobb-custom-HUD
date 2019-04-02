local utility = {}

--------------------------------------------------------------------------------
utility.round = function(number, places)
-- rounds up if decimal >= .5 else rounds down
	if places then
		local mult = math.pow(10, places)
		return math.floor(number * mult + 0.5) / mult
	else
		return math.floor(number + 0.5)
	end
end -- utility.round = function
--------------------------------------------------------------------------------
utility.rounddown = function(number, places)
-- rounds down if decimal <= .5 else rounds up
	if places then
		local mult = math.pow(10, places)
		return math.ceil(number * mult - 0.5) / mult
	else
		return math.ceil(number - 0.5)
	end
end -- utility.rounddown = function
--------------------------------------------------------------------------------
utility.scale = function(value, range, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return round((value / 100) * range * offset)
end
--------------------------------------------------------------------------------
utility.unscale = function(value, range, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return value / range * 100 / offset
end
--------------------------------------------------------------------------------
utility.bindnumber = function(value, minimum, maximum)
	return math.min(math.max(minimum, value), maximum)
end
--------------------------------------------------------------------------------
utility.binarysearch = function(target, arrayfunc)
	local result
	local rangestart, rangeend = 1, #array
	repeat
		result = utility.round((rangestart + rangeend) / 2)
		if target >= arrayfunc(result) then
			rangestart = result
		else
			rangeend = result
		end -- if mousex < list.buttoncenters[dragdest]
	until rangestart + 1 == rangeend
	return rangestart
end -- utility.binarysearch = function
--------------------------------------------------------------------------------
utility.tablecombolist = function(sourcetable)
-- takes a string-indexed table, and returns an alphabetized index array with built-in reverse lookup.
	
	local resultlist = {}
	
	local longest = 12
	-- space needed when list is displayed in a combo box
	
	for key, item in pairs(sourcetable) do
		if not item.hidden then
			table.insert(resultlist, key)
			longest = math.max(longest, string.len(key))
		end
	end -- for key, _ in pairs(sourcetable)
	resultlist.longest = longest
	
	table.sort(resultlist, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
	for index, name in ipairs(resultlist) do
		resultlist[name] = index
	end
	
	return resultlist
end -- local function buildcombolist(sourcetable)
--------------------------------------------------------------------------------
utility.listmove = function(list, source, dest, selected)
	if source ~= dest and source + 1 ~= dest then
		table.insert(list, dest, list[source])
		if source < dest then
			table.remove(list, source)
			if selected and source < selected and selected < dest then
				return selected - 1
			end
		else
			table.remove(list, source + 1)
			if selected and dest < selected and selected < source then
				return selected + 1
			end
		end -- if source < dest
		if selected and selected == source then
			return dest
		else
			return selected
		end -- if selected and selected == source
	end -- making sure the destination is different from the source
end -- utility.listmove = function
--------------------------------------------------------------------------------
utility.addcombolist = function(sourcearray)
-- sort array and add reverse lookup
	table.sort(sourcearray, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
	for index, value in ipairs(sourcearray) do
		sourcearray[value] = index
		sourcearray.longest = math.max(sourcearray.longest, string.len(value))
	end
end
--------------------------------------------------------------------------------
utility.iswithinrect = function(point, rect)
	if
		point.x > rect.left
		and
		point.x < rect.right
		and
		point.y > rect.top
		and
		point.y < rect.bottom
	then
		return true
	else
		return false
	end
end
--------------------------------------------------------------------------------
do
-- convert entire table into a string, so it can be written to a file. recurses for nested tables.
	local serialize = {}
	utility.serialize = function(sourcedata, offset, excludekeys)
		return serialize[type(sourcedata)](sourcedata, offset)
	end
--------------------------------------------------------------------------------
	serialize['number'] = tostring
	serialize['boolean'] = tostring
	serialize['string'] = function(sourcedata)
		return string.format('\'%s\'', sourcedata)
	end
--------------------------------------------------------------------------------
	serialize['table'] = function(sourcedata, currentoffset)
		
		-- if sourcedata.serialize then return sourcedata:serialize(currentoffset) end
		
		currentoffset = currentoffset or 0
		local indent = string.rep(' ', currentoffset)
		-- indentation within nested tables
		
		local result = '{'
		local optionallinebreak = ''
		local tableending = '}'
		
		for key, value in pairs(sourcedata) do
			if type(value) == 'table'
				and not (sourcedata.dontserialize and sourcedata.dontserialize[key])
			then
				result = '\n' .. indent .. '{'
				optionallinebreak = '\n' .. indent
				tableending = '\n' .. indent .. '}'
				break
			end
		end -- for _, value in pairs(sourcedata)
		-- if sourcedata contains any tables, then put each element of sourcedata on a separate line, with proper indentation; if sourcedata contains no tables, then put all its elements on one line.
		
		for key, value in pairs(sourcedata) do
			if not (excludekeys and excludekeys[key]) then
				result = result .. optionallinebreak
				if type(key) ~= 'number' then
					result = result .. string.format('[%s]=', utility.serialize(key))
				end -- if type(key) == 'number'
				result = result .. utility.serialize(value, currentoffset + 2) .. ','
				-- recursion is fun! :)
			end
		end -- for key, value in pairs(sourcedata)
			
		return result .. tableending
	end -- serialize['table'] = function
end
--------------------------------------------------------------------------------
utility.savestring = function(filename, stringtosave)
	local file = io.open('addons/custom hud/' .. filename .. '.lua', 'w')
	if file then
		file:write(stringtosave)
		file:close()
		-- io.output(file)
		-- io.write(stringtosave)
		-- io.close(file)
	end
end -- utility.savestring = function
--------------------------------------------------------------------------------
utility.loadstring = function(filename)
	
end -- utility.loadstring = function
--------------------------------------------------------------------------------
utility.savetable = function(filename, tabletosave)
-- saves current HUD configuration to disk as a runnable lua script.
	local outputstring = 'return\n' .. utility.serialize(tabletosave)
	utility.savestring(filename, outputstring)
end -- utility.savetable = function
--------------------------------------------------------------------------------
utility.loadtable = function(filename)
-- loads table from a lua file if the file returns a table when run
	local success, tabledata = pcall(require, 'custom hud.' .. filename)
	if success then return tabledata end
end -- utility.loadtable = function
--------------------------------------------------------------------------------
return utility
