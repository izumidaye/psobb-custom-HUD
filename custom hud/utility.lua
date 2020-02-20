-- local neondebug = require 'custom hud.neondebug'

local debugsave = function(message)
	-- neondebug.log(message, 'save serialize')
end

local utility = {}
function utility.round(number, places)
-- rounds up if decimal >= .5 else rounds down
	if places then
		local mult = math.pow(10, places)
		return math.floor(number * mult + 0.5) / mult
	else
		return math.floor(number + 0.5)
	end
end -- function utility.round
function utility.rounddown(number, places)
-- rounds down if decimal <= .5 else rounds up
	if places then
		local mult = math.pow(10, places)
		return math.ceil(number * mult - 0.5) / mult
	else
		return math.ceil(number - 0.5)
	end
end -- function utility.rounddown
function utility.scale(value, range, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	-- neondebug.log('utility.scale(' .. value .. ', ' .. range .. ', ' .. offset .. ')', 5, 'widget')
	return utility.round((value / 100) * range * offset)
end -- function utility.scale
function utility.unscale(value, range, offset)
	if offset then
		offset = 1 - offset / 100
	else
		offset = 1
	end
	return value / range * 100 / offset
end -- function utility.unscale
function utility.bindnumber(value, minimum, maximum)
	return math.min(math.max(minimum, value), maximum)
end -- function utility.bindnumber
function utility.binarysearch(target, arrayfunc)
	-- i think i decided to do things differently, and that this function isn't used
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
end -- function utility.binarysearch
function utility.tablesort(sourcetable)
	table.sort(sourcetable, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
end -- function utility.tablesort
function utility.tablecombolist(sourcetable)
-- takes a string-indexed table, and returns an alphabetized index array with built-in reverse lookup.
	
	local resultlist = {}
	local longest = 12 -- space needed when list is displayed in a combo box
	
	for key, item in pairs(sourcetable) do
		if type(item) == 'table' and not item.hidden then -- i don't think i'm using the 'hidden' flag anymore, i'm just making sure that stuff that needs to be hidden (i think it was only used by widgets) isn't added to the sourcetable until after i call utility.tablecombolist
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
end -- function utility.tablecombolist
function utility.listadd(list, newitem, dest, selected)
	table.insert(list, dest, newitem)
	if selected and dest <= selected then
		return selected + 1
	else
		return selected
	end
end -- function utility.listadd
function utility.listmove(list, source, dest, selected)
	local newselected = selected
	if source ~= dest and source + 1 ~= dest then
		-- print('insert ' .. dest)
		table.insert(list, dest, list[source])
		if source < dest then
			-- print('remove ' .. source)
			table.remove(list, source)
			if selected and source < selected and selected < dest then
				-- return selected - 1
				newselected = selected - 1
			elseif selected == source then
				-- return dest
				newselected = dest - 1
			end
		else
			-- print('remove ' .. source + 1)
			table.remove(list, source + 1)
			if selected and dest <= selected and selected < source then
				-- return selected + 1
				newselected = selected + 1
			elseif selected == source then
				-- return dest
				newselected = dest
			end
		end -- if source < dest
	end -- making sure the destination is different from the source
	-- print('move: {source = ' .. source .. ', dest = ' .. dest .. ', selected = ' .. selected .. ', newselected = ' .. newselected .. '}')
	return newselected
end -- function utility.listmove
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
end -- function utility.listcopy
function utility.listcopyinto(dest, source)
	for key, value in pairs(source) do
		if type(value) == 'table' then
			dest[key] = utility.listcopy(value)
		else
			dest[key] = value
		end
	end
end -- function utility.listcopyinto
function utility.addcombolist(sourcearray)
-- sort array and add reverse lookup
	table.sort(sourcearray, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
	if not sourcearray.longest then sourcearray.longest = 0 end
	for index, value in ipairs(sourcearray) do
		sourcearray[value] = index
		sourcearray.longest = math.max(sourcearray.longest, string.len(value))
	end
end -- function utility.addcombolist
function utility.iswithinrect(x, y, rect)
	if x > rect.left and x < rect.right and y > rect.top and y < rect.bottom then
		return true
	else return false
	end
end -- function utility.iswithinrect
do -- serialize functions
-- convert entire table into a string, so it can be written to a file. recurses for nested tables.
	local serialize = {}
	function utility.serialize(sourcedata, offset, excludekeys, includefunctions)
		debugsave 'begin serialize...'
		-- print(type(sourcedata))
		local result = serialize[type(sourcedata)](sourcedata, offset, includefunctions)
		debugsave 'serialize completed.'
		debugsave(result)
		return result
	end -- function utility.serialize
	serialize.number = tostring
	serialize.boolean = tostring
	function serialize.string(sourcedata)
		return string.format('\'%s\'', sourcedata)
	end -- function serialize.string
	function serialize.table(sourcedata, currentoffset, includefunctions)
		-- if sourcedata.serialize then return sourcedata:serialize(currentoffset) end
		
		currentoffset = currentoffset or 0
		local indent = string.rep(' ', currentoffset)
		-- indentation within nested tables
		
		local result = '{'
		local optionallinebreak = ''
		local tableending = '}'
		
		for key, value in pairs(sourcedata) do
			if type(value) == 'table' and not (sourcedata.dontserialize and sourcedata.dontserialize[key])
			and not (key == '__index')
			then
				result = '\n' .. indent .. '{'
				optionallinebreak = '\n' .. indent
				tableending = '\n' .. indent .. '}'
				break
			end
		end -- for key, value in pairs(sourcedata)
		-- if sourcedata contains any tables, then put each element of sourcedata on a separate line, with proper indentation; if sourcedata contains no tables, then put all its elements on one line.
		
		for key, value in pairs(sourcedata) do
			if not ((sourcedata.dontserialize and sourcedata.dontserialize[key])
			or key == '__index') then
				if type(value) == 'function' then
					if includefunctions then
						result = result .. string.format("[%s]='function',", utility.serialize(key))
					end
				else
					if type(key) ~= 'number' then
						-- result = result .. optionallinebreak
						result = result .. string.format('[%s]=', utility.serialize(key))
					end -- if type(key) == 'number'
					result = result .. utility.serialize(value, currentoffset + 2) .. ','
				end -- if type(value) == 'function'
				-- recursion is fun! :)
			end
		end -- for key, value in pairs(sourcedata)
			
		return result .. tableending
	end -- function serialize.table
end -- serialize functions
function utility.showfunctionnames(list)
	local result = '{'
	for key, value in pairs(list) do
		if type(value) == 'function' then result = result .. key .. ', ' end
	end -- for key, value in pairs(list)
	result = result .. '}'
	return result
end -- function utility.showfunctionnames
function utility.savestring(filename, stringtosave)
	local file = io.open('addons/custom hud/' .. filename .. '.lua', 'w')
	if file then
		file:write(stringtosave)
		file:close()
		-- io.output(file)
		-- io.write(stringtosave)
		-- io.close(file)
	end
end -- function utility.savestring
function utility.loadstring(filename)
	
end -- function utility.loadstring
function utility.savetable(filename, tabletosave)
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
end -- function utility.savetable
function utility.loadtable(filename)
-- loads table from a lua file if the file returns a table when run
	local success, tabledata = pcall(require, 'custom hud.' .. filename)
	if success then return tabledata end
end -- function utility.loadtable

return utility
