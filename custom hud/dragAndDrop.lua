local dragAndDrop = {}
local isMouseDragging
function dragAndDrop.init()
	isMouseDragging = imgui.IsMouseDragging
end -- function dragAndDrop.init

dragAndDrop.paramSet = {
	dragThreshold = {
		editor = 'number',
		-- optional = true,
		defaultValue = 24,
		args = {1, .2, 6, 72, '%u'},
		category = 'paramEditing',
	}, -- dragThreshold = {...},
} -- dragAndDrop.paramSet = {...}

function dragAndDrop.isMouseDragging()
	return isMouseDragging(0, dragAndDrop.dragThreshold)
end -- function dragAndDrop.isMouseDragging
function dragAndDrop.detectDragStart()
	return (not dragAndDrop.dragActive) and dragAndDrop.isMouseDragging()
end -- function dragAndDrop.detectDragStart
function dragAndDrop.startDrag(list, index)
	dragAndDrop.dragActive = true
	dragAndDrop.sourceIndex = index
	dragAndDrop.sourceList = list
end -- function dragAndDrop.startDrag
function dragAndDrop.endDrag()
	if dragAndDrop.destList and dragAndDrop.destIndex then
		if dragAndDrop.sourceList == dragAndDrop.destList then
			dragAndDrop.sourceList.interface.moveItem(dragAndDrop.sourceList, dragAndDrop.sourceIndex, dragAndDrop.destIndex)
		else
			local movingItem = dragAndDrop.sourceList.interface.removeItem(dragAndDrop.sourceList, dragAndDrop.sourceIndex)
			dragAndDrop.destList.interface.addItem(dragAndDrop.destList, dragAndDrop.destIndex, movingItem)
		end -- if dragAndDrop.sourceList == dragAndDrop.destList
	-- else
	end -- if dragAndDrop.destList and dragAndDrop.destIndex
	dragAndDrop.sourceList = nil
	dragAndDrop.sourceIndex = nil
	dragAndDrop.destList = nil
	dragAndDrop.destIndex = nil
	dragAndDrop.dragActive = false
end -- function dragAndDrop.endDrag
function mapMouseToList(list, x, y)
	-- local x, y = imgui.GetMousePos()
	local hoveredRow
	for i, row in ipairs(list.editorState.map) do
		if y < row.y then
			hoveredRow = row
			break
		end -- if y < row.y
	end -- for i, row in ipairs(map)
	if hoveredRow then
		local hoveredIndex
		for j, itemPos in ipairs(hoveredRow) do
			if x < itemPos.x then
				hoveredIndex = itemPos.index
				break
			end -- if x < itemPos.x
		end -- for j, itemPos in ipairs(row)
		return hoveredIndex or #hoveredRow
	else -- after last row
		return #list + 1
	end -- if hoveredRow
end -- function mapMouseToList
local function isWithinRect(x, y, rect)
	return (x > rect.left and x < rect.right) and (y > rect.top and y < rect.bottom)
end -- local function isWithinRect
function dragAndDrop.updateDragDest(list, x, y)
	if dragAndDrop.dragActive then
		if not imgui.IsMouseDown(0) then
			dragAndDrop.endDrag()
		-- elseif imgui.IsItemHovered() then
		elseif isWithinRect(x, y, list.editorState.dropZone) then
			print('valid drop zone')
			if list.contentType == dragAndDrop.sourceList.contentType then
				dragAndDrop.destList = list
				dragAndDrop.destIndex = mapMouseToList(list, x, y)
			end -- if list.contentType == dragAndDrop.sourceList.contentType
		elseif dragAndDrop.destList == list then
			-- this *was* hovered, but the mouse moved away.
			dragAndDrop.destList = nil
			dragAndDrop.destIndex = nil
		end -- if not imgui.IsMouseDown(0)
	end -- if dragAndDrop.dragActive
end -- function dragAndDrop.updateDragDest

return {
	name = 'dragAndDrop',
	module = dragAndDrop,
	usesGlobalOptions = true,
	persistent = true,
}