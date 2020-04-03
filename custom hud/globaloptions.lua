local globaloptions = {}
local interface = {}
local selectedcategory

local function presentoption(option)
	local changed, newvalue
	if option.args then
		changed, newvalue = customhud.editparam[option.type](option.name, option.get(), option.label, unpack(option.args))
	else
		changed, newvalue = customhud.editparam[option.type](option.name, option.get(), option.label)
	end
	if changed then option.set(newvalue) end
end -- local function presentoption
function interface.present()
	if selectedcategory then
		local category = globaloptions[selectedcategory]
		for _, optionname in ipairs(category) do
			presentoption(category[optionname])
		end -- for _, optionname in ipairs(globaloptions[categoryname])
	end -- if selectedcategory
end -- local function present
local function presentcategorylist()
	
end -- local function presentcategorylist
local function compareoptions(option1, option2)
	return string.lower(option1) < string.lower(option2)
end -- local function compareoptions
local function addcategory(categoryname)
	globaloptions[categoryname] = {}
	table.insert(globaloptions, categoryname)
	table.sort(globaloptions, customhud.utility.compareignorecase)
end -- local function addcategory
function interface.add(categoryname, args)
	-- args: {name=, type=, value=, args={}, callback=function()}
	if not globaloptions[categoryname] then addcategory(categoryname) end
	local category = globaloptions[categoryname]
	if category[args.name] then
		category[args.name].get = args.get
		category[args.name].set = args.set
	else
		category[args.name] = args
		table.insert(category, args.name)
		table.sort(category, customhud.utility.compareignorecase)
	end -- if globaloptions[category][args.name]
end -- function globaloptions.add

return {name = 'globaloptions', module = interface, dependencies = {'editparam', 'utility'}}
