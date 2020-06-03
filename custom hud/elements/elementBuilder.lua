--[[
elementBuilder - builds, restores, or deconstructs instances of Element subclasses
dependencies: none
Catherine S (izumidaye [at] tutanota.com)
2020-03-26
]]

local elementBuilder = {}
local copyTable
function elementBuilder.init()
	copyTable = CustomHUD.utility.copyTable
end -- function elementBuilder.init

local freedIDs, takenIDs = {}, {}
local function generateID()
	local newID
	if #freedIDs > 0 then
		newID = table.remove(freedIDs, 1)
	else
		newID = #takenIDs + 1
	end -- if #freedIDs > 0
	takenIDs[newID] = true
	return newID
end -- local function generateID
local function freeID(IDtoFree)
	table.insert(freedIDs, IDtoFree)
	takenIDs[IDtoFree] = nil
end -- local function freeID

local function init(element, elementClass)
	setmetatable(element, elementClass)
	-- print('type(element.init): ' .. type(element.init))
	-- print('element metatable: ' .. utility.serialize(getmetatable(element), 0, true) .. '\nelementClass: ' .. utility.serialize(elementClass))
	-- print('after - element: ' .. utility.serialize(element, 0, true))
	element.ID = generateID()
end -- local function init
function elementBuilder.restore(element, elementClass)
	init(element, elementClass)
	-- element:init()
	element:restore()
end -- function elementBuilder.restore
local function evalOrCopy(defaultParamValue)
	local result
	if type(defaultParamValue) == 'function' then
		result = defaultParamValue()
	elseif type(defaultParamValue) == 'table' then
		result = copyTable(defaultParamValue)
	else
		result = defaultParamValue
	end -- defaultParamValue type switch
	return result
end -- local function evalOrCopy
local function initDefaultValues(element)
	for paramName, paramDef in pairs(element.paramSet) do
		if paramDef.defaultValue then
			element[paramName] = evalOrCopy(paramDef.defaultValue)
		end -- if paramDef.defaultValue
	end -- for paramName, paramDef in pairs(element.paramSet)
end -- local function initDefaultValues
function elementBuilder.create(elementClass)
	local element = {}
	element.typename = elementClass.typename
	init(element, elementClass)
	initDefaultValues(element)
	-- newelement.dontserialize={dontserialize=true, editparam=true, parent=true}
	-- element:firsttimeinit()
	-- element:init()
	return element
end -- function elementBuilder.create
function elementBuilder.delete(element)
	freeID(element.ID)
	-- table.remove(elementcontainer, elementindex)
end -- function elementBuilder.delete

return {
	name = 'elementBuilder',
	module = elementBuilder',
}