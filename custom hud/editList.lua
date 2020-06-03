local editList = {}
local dragAndDrop, detectDragStart, startDrag, editParam
function editList.init()
	dragAndDrop = CustomHUD.dragAndDrop
	detectDragStart = CustomHUD.dragAndDrop.detectDragStart
	startDrag = CustomHUD.dragAndDrop.startDrag
	editParam = CustomHUD.editParam
end -- function editList.init

local function justEdit(list)
end -- local function justEdit
local function editAndMap(list)
end -- local function editAndMap
local function isRemapNeeded(editorState)
	local remap = false
	if dragAndDrop.dragActive and imgui.IsWindowHovered() then
		if editorState.remap then
			remap = true
		else
			local cursorX, cursorY = imgui.GetCursorScreenPos()
			local windowW, windowH = imgui.GetWindowSize()
			if editorState.cursorX ~= cursorX
			or editorState.cursorY ~= cursorY
			or editorState.windowW ~= windowW
			or editorState.windowH ~= windowH
			then
				remap = true
			end -- if layout changed
		end -- if editorState.remap
	end -- if dragAndDrop.dragActive and imgui.IsWindowHovered()
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
function showDestIndicator(list)
	if dragAndDrop.destList == list then
		local realPos = {imgui.GetCursorScreenPos()}
		local destIndex = dragAndDrop.destIndex
		if destIndex <= #list then
			local item = list[1]
			imgui.SetCursorScreenPos(item.x - (item.w / 2), item.y - (item.h / 2))
			if item.sameLine then
				imgui.Text'|'
			else
				imgui.Separator()
			end -- if item.sameLine
		else -- destIndex > #list
			local item = list[#list]
			if item.sameLine then
				imgui.SetCursorScreenPos(item.x + (item.w / 2), item.y - (item.h / 2))
				imgui.Text'|'
			else
				imgui.SetCursorScreenPos(realPos.x, item.y + (item.h / 2))
				imgui.Separator()
			end -- if item.sameLine
		end -- destIndex switch
		imgui.SetCursorScreenPos(unpack(realPos))
	end -- if dragAndDrop.destList == list
end -- function showDestIndicator
function editList.edit(list)
	imgui.BeginGroup()
		local listEditor = editParam[list.type]
		local remap = isRemapNeeded(list.editorState)
		if remap then editorState.map = {} end
		for index, item in ipairs(list) do
			if remap then
				showAndMapItem(list, index, listEditor.listItem)
			elseif listEditor.listItem(list, index) and detectDragStart() then
				startDrag(list, index)
			end -- if remap
		end -- for index, item in ipairs(list)
		
	imgui.EndGroup()
	if remap then editorState.remap = nil end
	
	dragAndDrop.updateDragDest(list)
end -- function editList.edit

return {
	name = 'editList',
	module = editList,
	dependencies = {'dragAndDrop', 'editParam'},
}