local utility = {}

function utility.compareIgnoreCase(a, b) return string.lower(a) < string.lower(b) end
function utility.copyIntoTable(args)
	for k, v in pairs(args.source) do
		if type(v) == 'table' then
			if not args.dest[k] then args.dest[k] = {} end
			utility.copyIntoTable{source = v, dest = args.dest[k]}
		else
			args.dest[k] = v
		end -- if type(v) == 'table'
	end
end -- function utility.copyIntoTable
function utility.copyTable(sourceTable)
	local newTable = {}
	for k, v in pairs(sourceTable) do
		if type(v) == 'table' then
			newTable[k] = utility.copyTable(v)
		else
			newTable[k] = v
		end -- if type(v) == 'table'
	end -- for k, v in pairs(sourceTable)
	return newTable
end -- function utility.copyTable

return {name = 'utility', module = utility}