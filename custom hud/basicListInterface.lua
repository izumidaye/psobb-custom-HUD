local basicListInterface = {}
local dragAndDrop, isMouseDragging, toggleButton, isItemHovered, isItemActive, isMouseDown, setTooltip, sameLine
function basicListInterface.init()
	local CustomHUD = CustomHUD
	local imgui = imgui
	-- dragAndDrop = CustomHUD.dragAndDrop
	isMouseDragging = CustomHUD.dragAndDrop.isMouseDragging
	toggleButton = CustomHUD.basicWidgets.toggleButton
	isItemHovered = imgui.IsItemHovered
	isItemActive = imgui.IsItemActive
	isMouseDown = imgui.IsMouseDown
	setTooltip = imgui.SetTooltip
	sameLine = imgui.SameLine
end -- function basicListInterface.init

function basicListInterface.listItem(list, index)
	local selected = list.editorState.selected == index
	local item = list[index]
	if toggleButton(item.shortName .. '##' .. item.ID, selected)
	and not isMouseDragging() then
		list.editorState.selected = index
	end -- if toggleButton and not isMouseDragging
	
	if isItemHovered() and not isMouseDown(0) and item.description then
		setTooltip(item.description)
	end -- if  isItemHovered() and not isMouseDown(0)
	local itemActive = isItemActive()
	if item.sameLine then sameLine() end
	
	return itemActive
end -- function basicListInterface.listItem
function basicListInterface.addItem(list, index, newItem)
	table.insert(list, index, newItem)
	if list.editorState.selected and index <= list.editorState.selected then
		list.editorState.selected = list.editorState.selected + 1
	end -- if list.selected and index <= list.selected
end -- function basicListInterface.addItem
function basicListInterface.removeItem(list, index)
	local removedItem = table.remove(list, index) -- change this to move to 'trash' or something
	if list.editorState.selected then
		if list.editorState.selected == index then
			list.editorState.selected = nil
		elseif index < list.editorState.selected then
			list.editorState.selected = list.editorState.selected - 1
		end -- if list.selected == index
	end -- if list.selected
	return removedItem
end -- function basicListInterface.removeItem
function basicListInterface.moveItem(list, sourceIndex, destIndex)
	local sourceOffset = 0
	local selectionOffset = 0
	if destIndex < sourceIndex then sourceOffset = 1 end
	table.insert(list, destIndex, list[sourceIndex])
	table.remove(list, sourceIndex + sourceOffset)
	print('moved list item from ' .. sourceIndex .. ' to ' .. destIndex)
	if list.editorState.selected then
		local selected = list.editorState.selected
		if destIndex < selected and selected < sourceIndex then
			selectionOffset = 1
		elseif sourceIndex < selected and selected < destIndex then
			selectionOffset = -1
		end
		list.editorState.selected = selected + selectionOffset
	end -- if list.editorState.selected
end -- function basicListInterface.moveItem

return {
	name = 'basicListInterface',
	module = basicListInterface,
	dependencies = {'basicWidgets', 'dragAndDrop'},
}