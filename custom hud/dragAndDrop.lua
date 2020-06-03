local dragAndDrop = {}
local isMouseDragging
function dragAndDrop.init()
	isMouseDragging = imgui.isMouseDragging
end -- function dragAndDrop.init

dragAndDrop.paramSet = {
	dragThreshold = {
		edit = true,
		optional = true,
		type = 'number',
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
function mapMouseToList(list)
	local x, y = imgui.GetMousePos()
	local hoveredRow
	for i, row in ipairs(list.map) do
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
function dragAndDrop.updateDragDest(list, x, y)
	if dragAndDrop.dragActive
		if imgui.IsItemHovered()
		and list.contentType == dragAndDrop.sourceList.contentType
		then
			dragAndDrop.destList = list
			dragAndDrop.destIndex = mapMouseToList(list.editorState.map)
		else
			dragAndDrop.numberInactive = dragAndDrop.numberInactive + 1
		end -- if windowHovered, and if content types match
	end -- if dragActive
end -- function dragAndDrop.updateDragDest

return {
	name = 'dragAndDrop',
	module = dragAndDrop,
	usesGlobalOptions = true,
}