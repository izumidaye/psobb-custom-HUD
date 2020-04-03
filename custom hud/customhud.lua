customhud = {
	nilfunction = function() end,
	starttime = os.clock(),
}

function customhud.logmain(message)
	print('custom hud > ' .. message)
	customhud.logger.log(message, 'main')
end -- function customhud.logmain
function customhud.logpcall(f, desc, ...)
	local results = {pcall(f, ...)}
	local success = table.remove(results, 1)
	if not success then
		local errormsg = customhud.serialize({desc, results, ...})
		print(errormsg)
		customhud.logger.log(errormsg, 'error')
	else
		return unpack(results)
	end -- if not success
end -- function customhud.logpcall
function customhud.addmodule(name, newmodule)
	customhud[name] = newmodule
	customhud.logmain('loaded module [' .. name .. ']')
end -- function customhud.addmodule
function customhud.loadlanguage(languagename)
	local templanguagetable = require('custom hud.languages.' .. languagename)
	if templanguagetable then customhud.languagetable = templanguagetable end
end -- function customhud.loadlanguage
function customhud.init()
	customhud.tasks.add{
		name = 'loadlanguagetable',
		description = 'load language table',
		run = function() customhud.loadlanguage'english' end,
	} -- customhud.tasks.add{...}
	customhud.init = customhud.nilfunction
end -- function customhud.init
