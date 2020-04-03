-- convert entire table into a string, so it can be written to a file. recurses for nested tables.
local serializetypes = {}

function serialize(...)
	-- debugsave 'begin serialize...'
	-- print(type(sourcedata))
	local result = serializetypes[type(...)](...)
	-- debugsave 'serialize completed.'
	-- debugsave(result)
	return result
end -- function serialize

serializetypes.number = tostring
serializetypes.boolean = tostring

function serializetypes.string(sourcedata)
	return string.format('\'%s\'', sourcedata)
end -- function serializetypes.string

function serializetypes.table(sourcedata, currentoffset, includefunctions)
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
					result = result .. string.format("[%s]='function',", serialize(key))
				end
			else
				if type(key) ~= 'number' then
					-- result = result .. optionallinebreak
					result = result .. string.format('[%s]=', serialize(key))
				end -- if type(key) == 'number'
				result = result .. serialize(value, currentoffset + 2) .. ','
			end -- if type(value) == 'function'
			-- recursion is fun! :)
		end
	end -- for key, value in pairs(sourcedata)
		
	return result .. tableending
end -- function serializetypes.table

return {name = 'serialize', module = serialize}
