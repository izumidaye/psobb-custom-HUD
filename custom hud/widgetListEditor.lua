local widgetListEditor = {}
local dragAndDrop, toggleButton, isItemHovered, isItemActive, isMouseDown, setTooltip, sameLine
function widgetListEditor.init()
	dragAndDrop = CustomHUD.dragAndDrop
	toggleButton = CustomHUD.basicWidgets.toggleButton
	isItemHovered = imgui.IsItemHovered
	isItemActive = imgui.IsItemActive
	isMouseDown = imgui.IsMouseDown
	setTooltip = imgui.SetTooltip
	sameLine = imgui.SameLine
end -- function widgetListEditor.init

function widgetListEditor.listItem(list, index)
	local selected = list.editorState.selected == index
	local item = list[index]
	if toggleButton(item.shortName .. '##' .. item.id, selected)
	and not dragAndDrop.isMouseDragging() then
		list.editorState.selected = index
	end -- if toggleButton and not isMouseDragging
	
	if isItemHovered() and not isMouseDown(0) then
		setTooltip(item.description)
	end -- if  isItemHovered() and not isMouseDown(0)
	local itemActive = isItemActive()
	if item.sameLine then sameLine() end
	
	return itemActive
end -- function widgetListEditor.listItem
function widgetListEditor.addItem(list, index, newItem)
	table.insert(list, index, newItem)
	if list.editorState.selected and index <= list.editorState.selected then
		list.editorState.selected = list.editorState.selected + 1
	end -- if list.selected and index <= list.selected
end -- function widgetListEditor.addItem
function widgetListEditor.removeItem(list, index)
	table.remove(list, index) -- change this to move to 'trash' or something
	if list.editorState.selected then
		if list.editorState.selected == index then
			list.editorState.selected = nil
		elseif index < list.editorState.selected then
			list.editorState.selected = list.editorState.selected - 1
		end -- if list.selected == index
	end -- if list.selected
end -- function widgetListEditor.removeItem
function widgetListEditor.moveItem(list, sourceIndex, destIndex)
	local sourceOffset = 0
	local selectionOffset = 0
	if destIndex < sourceIndex then sourceOffset = 1 end
	if destIndex < list.editorState.selected and list.editorState.selected < sourceIndex then
		selectionOffset = 1
	elseif sourceIndex < list.editorState.selected and list.editorState.selected < destIndex then
		selectionOffset = -1
	end
	table.insert(list, destIndex, list[sourceIndex])
	table.remove(list, sourceIndex + sourceOffset)
	list.editorState.selected = list.editorState.selected + selectionOffset
end -- function widgetListEditor.moveItem

return {
	name = 'widgetListEditor',
	module = widgetListEditor,
	dependencies = {'basicWidgets', 'dragAndDrop'},
}