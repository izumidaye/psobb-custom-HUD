local neondebug = require('custom hud.neondebug')
local utility = {}

local debugsave = function(message)
	neondebug.log(message, 'save serialize')
end

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
	neondebug.log('utility.scale(' .. value .. ', ' .. range .. ', ' .. offset .. ')', 5, 'widget')
	return utility.round((value / 100) * range * offset)
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
function utility.listadd(list, newitem, dest, selected)
	table.insert(list, dest, newitem)
	if selected and dest <= selected then
		return selected + 1
	else
		return selected
	end
end -- function utility.listadd
--------------------------------------------------------------------------------
utility.listmove = function(list, source, dest, selected)
	if source ~= dest and source + 1 ~= dest then
		print('insert ' .. dest)
		table.insert(list, dest, list[source])
		if source < dest then
			print('remove ' .. source)
			table.remove(list, source)
			if selected and source < selected and selected < dest then
				return selected - 1
			end
		else
			print('remove ' .. source + 1)
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
	return selected
end -- utility.listmove = function
--------------------------------------------------------------------------------
function utility.listcopy(source)
	local result = {}
	
	for key, value in pairs(source) do
		if type(value) == 'table' then
			result[key] = utility.listcopy(value)
		else
			result[key] = value
		end
	end
	
	return result
end
--------------------------------------------------------------------------------
function utility.listcopyinto(dest, source)
	for key, value in pairs(source) do
		if type(value) == 'table' then
			dest[key] = utility.listcopy(value)
		else
			dest[key] = value
		end
	end
end
--------------------------------------------------------------------------------
utility.addcombolist = function(sourcearray)
-- sort array and add reverse lookup
	table.sort(sourcearray, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
	if not sourcearray.longest then sourcearray.longest = 0 end
	for index, value in ipairs(sourcearray) do
		sourcearray[value] = index
		sourcearray.longest = math.max(sourcearray.longest, string.len(value))
	end
end
--------------------------------------------------------------------------------
utility.iswithinrect = function(x, y, rect)
	if x > rect.left and x < rect.right and y > rect.top and y < rect.bottom then
		return true
	else return false
	end
end
--------------------------------------------------------------------------------
do
-- convert entire table into a string, so it can be written to a file. recurses for nested tables.
	local serialize = {}
	utility.serialize = function(sourcedata, offset, excludekeys)
		debugsave 'begin serialize...'
		local result = serialize[type(sourcedata)](sourcedata, offset)
		debugsave 'serialize completed.'
		debugsave(result)
		return result
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
			if not ((sourcedata.dontserialize and sourcedata.dontserialize[key])
			or type(value) == 'function' ) then
				if type(key) ~= 'number' then
					-- result = result .. optionallinebreak
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
	debugsave 'savetable: begin...'
	local serializeddata = utility.serialize(tabletosave)
	if type(serializeddata) ~= 'string' then
		debugsave 'savetable: serialize() did not return a string.'
	end
	local outputstring = 'return\n' .. serializeddata
	debugsave 'savetable: serialize complete.'
	utility.savestring(filename, outputstring)
	debugsave 'savetable: complete.'
end -- utility.savetable = function
--------------------------------------------------------------------------------
utility.loadtable = function(filename)
-- loads table from a lua file if the file returns a table when run
	local success, tabledata = pcall(require, 'custom hud.' .. filename)
	if success then return tabledata end
end -- utility.loadtable = function
--------------------------------------------------------------------------------
return utility
