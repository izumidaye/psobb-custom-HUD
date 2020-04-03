local displaylist = {}
local operations = {}

function operations.add(name, newfunction)
	displaylist[name] = {run = newfunction, enabled = false,}
	customhud.logmain('added [' .. name .. '] to displaylist')
end -- function operations.add
function operations.remove(name)
	displaylist[name] = nil
	customhud.logmain('removed [' .. name .. '] from displaylist')
end -- function operations.remove
function operations.toggle(name)
	if displaylist[name] then
		displaylist[name].enabled = not displaylist[name].enabled
	end -- if displaylist[name]
end -- function operations.toggle
local function run(name, displayfunction)
	customhud.logpcall(displayfunction.run, 'running display function [' .. name .. ']')
end -- local function run
function operations.runall()
	for name, displayfunction in pairs(displaylist) do
		if displayfunction.enabled then run(name, displayfunction) end
	end
end -- function operations.runall

return {name = 'displaylist', module = operations}