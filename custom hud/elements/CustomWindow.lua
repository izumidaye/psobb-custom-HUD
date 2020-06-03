local CustomWindow = {}

CustomWindow.paramSet = {'windowFlagSet', 'layout', 'title', 'hideWhen', 'manualSize'}
CustomWindow.childSet = {
	{name = 'contentList', className = 'WidgetList'},
} -- CustomWindow.childSet = {...}

function CustomWindow:present()
	for _, element in ipairs(self.contentList) do
		element:present()
	end -- for _, element in ipairs(self)
end -- function CustomWindow:present

return {
	name = 'CustomWindow',
	module = CustomWindow,
	inherits = 'Window',
}