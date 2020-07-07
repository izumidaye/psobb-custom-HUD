local CustomWindow = {}
CustomWindow.__index = CustomWindow

CustomWindow.paramSet = {'windowFlagSet', 'layout', 'title', 'hideWhen', 'manualSize'}
-- CustomWindow.childSet = {
	-- {name = 'contentList', className = 'WidgetSet'},
-- } -- CustomWindow.childSet = {...}

function CustomWindow:firstTimeInit()
	self.contentSet = {}
	self.shortName = self.title
	-- self.description = ''
end -- function CustomWindow:firstTimeInit

function CustomWindow:present()
	for _, element in ipairs(self.contentSet) do
		element:present()
	end -- for _, element in ipairs(self)
end -- function CustomWindow:present

return {
	name = 'CustomWindow',
	module = CustomWindow,
	inherits = 'Window',
}