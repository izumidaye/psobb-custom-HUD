local logView = {}
local listSelectOne, logs
local function present()
	listSelectOne(logView, 'selected', logs, 'horizontal')
	if imgui.BeginChild('logView') then
		if logView.selected then
			for _, textLine in ipairs(logs[logView.selected]) do
				imgui.Text(textLine)
			end -- for _, textLine in ipairs(logs[logView.selected])
		end -- if logView.selected
	end imgui.EndChild()
end -- local function present
function logView.init()
	listSelectOne = CustomHUD.editParam.listSelectOne
	logs = CustomHUD.logger.logs
	CustomHUD.mainWindow.addView('logView', present)
	local setActiveView = CustomHUD.mainWindow.setActiveView
	CustomHUD.mainWindow.addMenuItem{
		menuName = 'CustomHUD',
		menuItem = {
			name = 'logView',
			activate = function() setActiveView('logView') end,
		}, -- menuItem = {...},
	} -- CustomHUD.mainWindow.addMenuItem{...}
end -- function logView.init

return {
	name = 'logView',
	module = logView,
	dependencies = {'mainWindow', 'editParam'},
}