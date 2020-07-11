local editList = {}
local dragAndDrop, detectDragStart, startDrag, updateDragDest, editParam
function editList.init()
	local CustomHUD = CustomHUD
	dragAndDrop = CustomHUD.dragAndDrop
	detectDragStart = CustomHUD.dragAndDrop.detectDragStart
	startDrag = CustomHUD.dragAndDrop.startDrag
	updateDragDest = CustomHUD.dragAndDrop.updateDragDest
	editParam = CustomHUD.editParam
end -- function editList.init

local function isRemapNeeded(editorState)
	local remap = false
	if editorState.remap then
		remap = true
	elseif dragAndDrop.dragActive and imgui.IsWindowHovered() then
		local cursorX, cursorY = imgui.GetCursorScreenPos()
		local windowW, windowH = imgui.GetWindowSize()
		if editorState.cursorX ~= cursorX
		or editorState.cursorY ~= cursorY
		or editorState.windowW ~= windowW
		or editorState.windowH ~= windowH
		then
			remap = true
			editorState.cursorX = cursorX
			editorState.cursorY = cursorY
			editorState.windowW = windowW
			editorState.windowH = windowH
		end -- if layout changed
	end -- if editorState.remap
	return remap
end -- local function isRemapNeeded
local function showAndMapItem(list, index, listItem)
	local editorState = list.editorState
	local x, y = imgui.GetCursorScreenPos()
	listItem(list, index)
	local w, h = imgui.GetItemRectSize()
	local itemPos = {x = x + (w / 2), y = y + (h / 2), w = w, h = h, index = index}
	if (not editorState.currentY) or editorState.currentY < y then
		table.insert(editorState.map, {y = y + (h / 2)})
		editorState.currentY = y
	end -- if (not editorState.currentY) or editorState.currentY < y
	table.insert(editorState.map[#editorState.map], itemPos)
end -- local function showAndMapItem
local function showDestIndicator(list)
	if dragAndDrop.destList == list then
		local indicatorX, indicatorY
		local realPos = {imgui.GetCursorScreenPos()}
		local destIndex = dragAndDrop.destIndex
		local item
		if destIndex <= #list then
			item = list[destIndex]
			-- imgui.SetCursorScreenPos(item.x - (item.w / 2), item.y - (item.h / 2))
			indicatorX = item.x - (item.w / 2)
			indicatorY = item.y - (item.h / 2)
			-- if item.sameLine then
				-- imgui.Text'|'
			-- else
				-- imgui.Separator()
			-- end -- if item.sameLine
		else -- destIndex > #list
			item = list[#list]
			if item.sameLine then
				-- imgui.SetCursorScreenPos(item.x + (item.w / 2), item.y - (item.h / 2))
				indicatorX = item.x - (item.w / 2)
				indicatorY = item.y - (item.h / 2)
				-- imgui.Text'|'
			else
				indicatorX = realPos[1]
				indicatorY = item.y + (item.h / 2)
				-- imgui.SetCursorScreenPos(realPos[1], item.y + (item.h / 2))
				-- imgui.Separator()
			end -- if item.sameLine
		end -- destIndex switch
		local offset = list.editorState.offset
		imgui.SetCursorPos(indicatorX - offset.x, indicatorY - offset.y)
		-- if item.sameLine then
			-- imgui.Text'|'
		-- else
			imgui.Separator()
		-- end -- if item.sameLine
		imgui.SetCursorScreenPos(unpack(realPos))
		imgui.Text('showing drop indicator at: (' .. indicatorX .. ', ' .. indicatorY .. ')')
	end -- if dragAndDrop.destList == list
end -- function showDestIndicator
function editList.edit(list)
	local editorState = list.editorState
	imgui.BeginGroup()
		local listItem = list.interface.listItem
		local remap = isRemapNeeded(editorState)
		if remap then
			editorState.map = {}
			editorState.currentY = nil
			local screenX, screenY = imgui.GetCursorScreenPos()
			editorState.dropZone = {left = screenX, top = screenY}
			local cursorX, cursorY = imgui.GetCursorPos()
			editorState.offset = {x = screenX - cursorX, y = screenY - cursorY}
		end
		for index, item in ipairs(list) do
			if remap then
				showAndMapItem(list, index, listItem)
			elseif listItem(list, index) and detectDragStart() then
				startDrag(list, index)
			end -- if remap
		end -- for index, item in ipairs(list)
		
		showDestIndicator(list)
	imgui.EndGroup()
	if remap then
		local w, h = imgui.GetItemRectSize()
		editorState.dropZone.right = editorState.dropZone.left + w
		editorState.dropZone.bottom = editorState.dropZone.top + h
		editorState.remap = nil
	end
	local x, y = imgui.GetMousePos()
	updateDragDest(list, x, y)
	imgui.Separator()
	if editorState.selected then
		editParam.editParamSet(list[editorState.selected])
	end -- if editorState.selected
	-- imgui.TextWrapped('editorState: ' .. CustomHUD.serialize(editorState))
	imgui.TextWrapped('dragAndDrop: ' .. CustomHUD.serialize(dragAndDrop))
end -- function editList.edit

return {
	name = 'editList',
	module = editList,
	dependencies = {'dragAndDrop', 'editParam'},
}