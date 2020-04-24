local displayList = {}
local interface = {}

function interface.add(newWindow)
	displayList[newWindow.name] = newWindow.displayFunction
	CustomHUD.logMain('added [' .. newWindow.name .. '] to displaylist')
end -- function interface.add
function interface.remove(name)
	displayList[name] = nil
	CustomHUD.logMain('removed [' .. name .. '] from displaylist')
end -- function interface.remove
function interface.runAll()
	for name, displayFunction in pairs(displayList) do
		CustomHUD.logPcall(displayFunction, 'running display function [' .. name .. ']')
	end
end -- function interface.runall

return {name = 'displayList', module = interface,}