local TextValue = {}

TextValue.params = {'stringDataSource', 'label', 'textColor', 'sameLine'}

local logPcall, showLabel, showText, pushStyleColor, popStyleColor, sameLine, getData
function TextValue.init()
	logPcall = CustomHUD.logPcall
	showLabel = CustomHUD.basicWidgets.label
	showText = imgui.Text
	pushStyleColor = imgui.PushStyleColor
	popStyleColor = imgui.PopStyleColor
	sameLine = imgui.SameLine
	getData = psoData.get.string
end -- function TextValue.init

local function protectedPresent(self)
	if self.label then showLabel(param) end
	showText(getData[self.dataSource]())
end -- local function protectedPresent
function TextValue:present()
	sameLine()
	if self.textColor then pushStyleColor('text', unpack(self.textColor)) end
	logPcall(protectedPresent, 'TextValue:protectedPresent()', self)
	if self.textColor then popStyleColor() end
end -- function TextValue:present

return {
	name = 'TextValue',
	widget = TextValue,
	dependencies = {'basicWidgets'},
}