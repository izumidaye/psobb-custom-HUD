local utility = {}

utility.serialize = function(sourceData, currentOffset)
-- convert entire table into a string, so it can be written to a file. recurses for nested tables.
	
	currentOffset = currentOffset or 0
	local indent = string.rep(' ', currentOffset)
	-- indentation within nested tables
	
	local dataType = type(sourceData)
	local result = ''
	
	if dataType == 'number' then
		result = result .. sourceData
		
	elseif dataType == 'string' then
		result = string.format('\'%s\'', sourceData)
		
	elseif dataType == 'boolean' then
		if sourceData then
			result = 'true'
		else
			result = 'false'
		end
		
	elseif dataType == 'table' then
		
		local optionalLineBreak = ''
		local tableEnding = '}'
		result = result .. '{'
		local containsTable = false
		for _, value in pairs(sourceData) do
			if type(value) == 'table' then containsTable = true end
		end -- for _, value in pairs(sourceData)
		if containsTable then
			optionalLineBreak = '\n' .. indent
			tableEnding = '\n' .. indent .. '}'
		end -- if containsTable
		-- if sourceData contains any tables, then put each element of sourceData on a separate line, with proper indentation; if sourceData contains no tables, then put all its elements on one line.
		
		for key, value in pairs(sourceData) do
			if type(key) == 'number' then
				key = ''
			else -- not a number
				key = string.format('[%s]=', utility.serialize(key))
			end -- if type(key) == 'number'
			result = result .. optionalLineBreak .. key .. utility.serialize(value, currentOffset + 2) .. ','
			-- recursion is fun! :)
			
		end -- for key, value in pairs(sourceData)
		result = result .. tableEnding
		
	end -- dataType switch
	
	return result
end -- local function serialize(sourceData)

utility.buildcombolist = function(itemList)
-- takes a string-indexed table, and returns an alphabetized index array with built-in reverse lookup.
	
	local resultList = {}
	local count = 1
	local longest = 0
	-- space needed when list is displayed in a combo box
	
	for key, _ in pairs(itemList) do
		table.insert(resultList, key)
		-- if string.len(key) > longest then longest = string.len(key) end
		longest = math.max(longest, string.len(key))
	end -- for key, _ in pairs(itemList)
	resultList.longest = longest
	
	table.sort(resultList, function(string1, string2) return string.lower(string1) < string.lower(string2) end)
	for index, name in ipairs(resultList) do
		resultList[name] = index
	end
	
	return resultList
end -- local function buildComboList(itemList)

return utility