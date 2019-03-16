local utility = {}

utility.serialize = function(sourcedata, currentoffset)
-- convert entire table into a string, so it can be written to a file. recurses for nested tables.
	
	currentoffset = currentoffset or 0
	local indent = string.rep(' ', currentoffset)
	-- indentation within nested tables
	
	local datatype = type(sourcedata)
	local result = ''
	
	if datatype == 'number' then
		result = result .. sourcedata
		
	elseif datatype == 'string' then
		result = string.format('\'%s\'', sourcedata)
		
	elseif datatype == 'boolean' then
		if sourcedata then
			result = 'true'
		else
			result = 'false'
		end
		
	elseif datatype == 'table' then
		
		local optionallinebreak = ''
		local tableending = '}'
		result = result .. '{'
		local containstable = false
		for _, value in pairs(sourcedata) do
			if type(value) == 'table' then containstable = true end
		end -- for _, value in pairs(sourcedata)
		if containstable then
			optionallinebreak = '\n' .. indent
			tableending = '\n' .. indent .. '}'
		end -- if containstable
		-- if sourcedata contains any tables, then put each element of sourcedata on a separate line, with proper indentation; if sourcedata contains no tables, then put all its elements on one line.
		
		for key, value in pairs(sourcedata) do
			if type(key) == 'number' then
				key = ''
			else -- not a number
				key = string.format('[%s]=', utility.serialize(key))
			end -- if type(key) == 'number'
			result = result .. optionallinebreak .. key .. utility.serialize(value, currentoffset + 2) .. ','
			-- recursion is fun! :)
			
		end -- for key, value in pairs(sourcedata)
		result = result .. tableending
		
	end -- datatype switch
	
	return result
end -- local function serialize(sourcedata)

utility.buildcombolist = function(itemlist)
-- takes a string-indexed table, and returns an alphabetized index array with built-in reverse lookup.
	
	local resultlist = {}
	
	local longest = 12
	-- space needed when list is displayed in a combo box
	
	for key, _ in pairs(itemlist) do
		table.insert(resultlist, key)
		longest = math.max(longest, string.len(key))
	end -- for key, _ in pairs(itemlist)
	resultlist.longest = longest
	
	table.sort(resultlist, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
	for index, name in ipairs(resultlist) do
		resultlist[name] = index
	end
	
	return resultlist
end -- local function buildcombolist(itemlist)

return utility