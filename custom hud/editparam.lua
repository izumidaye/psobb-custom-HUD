local editparam = {}
local options = {
	inputtextwidth = -1,
	inputtextlength = 72,
	dragfloatwidth = 44,
} -- local options = {...}
local optioneditorargs = {
	-- args: {name=, type=, value=, args={}, callback=function()}
	{name = inputtextwidth, type = 'number', args = {24, 420, 1, .1, '%u'}},
	{name = inputtextlength, type = 'number', args = {24, 420, 1, .1, '%u'}},
	{name = dragfloatwidth, type = 'number', args = {24, 420, 1, .1, '%u'}},
} -- local optioneditorargs = {...} -------------------------------------------
local function getoptionvalue(optionname)
	return options[optionname]
end -- local function getoptionvalue ------------------------------------------
local function setoptionvalue(optionname, newvalue)
	options[optionname] = newvalue
end -- local function setoption -----------------------------------------------
local function registerglobaloptions()
	for _, option in ipairs(optioneditorargs) do
		option.set = setoptionvalue
		option.get = getoptionvalue
		customhud.globaloptions.add('editparam', option)
	end -- for _, option in ipairs(optioneditorargs)
	return {}
end -- local function registerglobaloptions -----------------------------------
local registerglobaloptionstask = {
	name = 'editparamglobaloptions',
	description = 'register global options for editparam',
	dependencies = {'globaloptions'},
	run = registerglobaloptions
} -- local registerglobaloptionstask = {...}

function editparam.string(param, value, label)
	-- if label then text(label) imgui.SameLine() end
	imgui.PushItemWidth(options.inputtextwidth)
		local changed, newvalue = customhud.logpcall(imgui.InputText, 'editparam.string(param, value, label)', '##' .. param, value, options.inputtextlength)
	imgui.PopItemWidth()
	return changed, newvalue
end -- function editparam.string ----------------------------------------------
function editparam.number(param, value, label, step, smallstep, min, max, formatstring)
	-- if label then text(label) imgui.SameLine() end
	imgui.PushItemWidth(options.dragfloatwidth)
	local changed1, newvalue1 = customhud.logcall(imgui.DragFloat, 'editparam.number(param, value, label, step, min, max, formatstring)', '##' .. param, value, step, min, max, string.format(formatstr, value))
	imgui.SameLine()
	local changed2, newvalue2 = customhud.logcall(imgui.DragFloat, 'editparam.number(param, value, label, step, min, max, formatstring) - finetune', '##finetune' .. param, value, smallstep, min, max, smallstep .. 'x')
	imgui.PopItemWidth()
	if changed1 then return changed1, newvalue1
	else return changed2, newvalue2
	end
end -- function editparam.number
function editparam.listselectone(list, selecteditem)

end -- function editparam.listselectone

-- task: {name=, description=, dependencies={}, run=function()<task body; everything else is metadata>}
return {
	name = 'editparam',
	module = editparam,
	newtasks = {registerglobaloptionstask}
} -- return {...}