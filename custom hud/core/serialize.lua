--[[
PSOBB Custom HUD
Catherine S (izumidaye/neonluna)
2020-04-21
Convert entire table into a string, formatted such that it can be read back and restored by the Lua interpreter. Recurses for nested tables. Due to the way Lua works, cannot restore function values.
]] ----------------------------------------------------------------------------
local serializeTypes = {}

function serialize(...)
	dataType = type(...)
	if serializeTypes[dataType] then
		local result = serializeTypes[dataType](...)
		return result
	else
		print('type: [' .. dataType .. '] not in serializeTypes.')
	end -- if serializeTypes[dataType]
end -- function serialize

serializeTypes.number = tostring
serializeTypes.boolean = tostring
serializeTypes['nil'] = tostring

function serializeTypes.string(sourceData)
	return string.format('\'%s\'', sourceData)
end -- function serializeTypes.string

function serializeTypes.table(sourceData, currentOffset, includeFunctions)
	-- if sourceData.serialize then return sourceData:serialize(currentOffset) end
	
	currentOffset = currentOffset or 0
	local indent = string.rep(' ', currentOffset)
	-- indentation within nested tables
	
	local result = '{'
	local optionalLineBreak = ''
	local tableEnding = '}'
	
	for key, value in pairs(sourceData) do
		if type(value) == 'table'
		and not (sourceData.dontSerialize and sourceData.dontSerialize[key])
		and not (key == '__index')
		then
			result = '\n' .. indent .. '{'
			optionalLineBreak = '\n' .. indent
			tableEnding = '\n' .. indent .. '}'
			break
		end
	end -- for key, value in pairs(sourceData)
	-- If sourcedata contains any tables, then put each element of sourcedata on a separate line, with proper indentation; if sourcedata contains no tables, then put all its elements on one line.
	
	for key, value in pairs(sourceData) do
		if not ((sourceData.dontSerialize and sourceData.dontSerialize[key])
		or key == '__index') then
			if type(value) == 'function' then
				if includeFunctions then
					result = result .. string.format("[%s]='function',", serialize(key))
				end
			else
				if type(key) ~= 'number' then
					-- result = result .. optionalLineBreak
					result = result .. string.format('[%s]=', serialize(key))
				end -- if type(key) == 'number'
				result = result .. serialize(value, currentOffset + 2) .. ','
			end -- if type(value) == 'function'
			-- Recursion is fun! :)
		end
	end -- for key, value in pairs(sourceData)
		
	return result .. tableEnding
end -- function serializeTypes.table

return {name = 'serialize', module = serialize}
