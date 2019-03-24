local utility = require('custom hud.utility')
local paramtype = require('custom hud.paramtype')

local datasource

------------------------------------------------------------------------
local function combobox(data, key, combolist)
	imgui.PushItemWidth(8 + (8 * combolist.longest))
		local changed, newvalue = imgui.Combo('##' .. key, combolist[data[key]], combolist, #combolist)
	imgui.PopItemWidth()
	if changed then data[key] = combolist[newvalue] end
	return changed
end
------------------------------------------------------------------------
local function paramsourceeditor(self, paramname)
	
	local typedef = paramtype[paramname]
	
	if typedef.optional then
		if imgui.Button('clear##' .. paramname) then
			self[paramname] = nil
			self.map[paramname] = nil
		end
		imgui.SameLine()
	end
	
	if self.fieldcombolist then
		if typedef.fieldsource then
			imgui.Text('source:')
			imgui.SameLine()
			if self.map[paramname] then
				if combobox(self.map, paramname, self.fieldcombolist) and typedef.update then
					typedef.update(self)
				end
			else
				if imgui.Button('use list field##' .. paramname) then
					self.map[paramname] = self.fieldcombolist[1]
					if typedef.update then typedef.update(self) end
				end
			end -- if self.map[paramname]
			imgui.SameLine()
		end -- if typedef.fieldsource
		
	elseif typedef.functionsource then
		if self.map[paramname] then
			if combobox(self.map, paramname, datasource.combolist[typedef.datatype]) and typedef.update then
				typedef.update(self)
			end
		else
			if imgui.Button('use game data##' .. paramname) then
				self.map[paramname] = datasource.combolist[typedef.datatype][1]
				if typedef.update then typedef.update(self) end
			end
		end -- if self.map[paramname]
		imgui.SameLine()
	end -- if self.fieldcombolist
	
	if typedef.staticsource and self.map[paramname] then
		if imgui.Button('use static value##' .. paramname) then
			self.map[paramname] = nil
			self[paramname] = typedef.default()
			if typedef.update then typedef.update(self) end
		end
	end
	
end -- local function paramsourceeditor
------------------------------------------------------------------------
local paramedit = {}
------------------------------------------------------------------------
paramedit['string'] = function(self, paramname)
	imgui.Text(paramname)
	imgui.SameLine()
	local changed, newvalue =
		imgui.InputText('##' .. paramname, self[paramname], 72)
	if changed then
		self[paramname] = newvalue
		if paramtype[paramname].update then
			paramtype[paramname].update(self)
		end
	end
	
	paramsourceeditor(self, paramname)
end -- paramedit['string'] = function
------------------------------------------------------------------------
paramedit['number'] = function(self, paramname)
	local typedef = paramtype[paramname]
	local displayvalue
	if typedef.scale then
		displayvalue = utility.round(self[paramname] * typedef.scale)
		-- displayvalue = string.format
			-- {'%s', utility.round(self[paramname] * typedef.scale)}
			-- not sure if i need to convert to string
	else
		displayvalue = self[paramname]
	end -- if typedef.scale
	
	imgui.Text(paramname .. ':')
	imgui.SameLine()
	imgui.PushItemWidth(72)
		
		local changed, newvalue = imgui.DragFloat
			{
			'##' .. paramname,
			self[paramname],
			typedef.largestep,
			typedef.minimum,
			typedef.maximum,
			displayvalue
			}
		if changed then self[paramname] = newvalue end
		imgui.SameLine()
		
		changed, newvalue = imgui.DragFloat
			{
			'##finetune' .. paramname,
			self[paramname],
			typedef.smallstep,
			typedef.minimum,
			typedef.maximum,
			'fine tune'
			}
		if changed then self[paramname] = newvalue end
		
	imgui.PopItemWidth()
	
	paramsourceeditor(self, paramname)
end -- paramedit['number'] = function
------------------------------------------------------------------------
paramedit['slow number'] = function(self, paramname)
	local typedef = paramtype[paramname]
	
	imgui.Text(paramname)
	imgui.SameLine()
	
	imgui.PushItemWidth(96)
		local changed, newvalue = imgui.InputFloat
			{
			'##' .. paramname,
			data[paramname],
			typedef.step,
			1,
			1,
			data[paramname]
			}
	imgui.PopItemWidth()
	if changed then
		if newvalue < typedef.minimum then
			newvalue = typedef.minimum
		elseif newvalue > typedef.maximum then
			newvalue = typedef.maximum
		end
		self[paramname] = newvalue
	end
	
end -- paramedit['slow number'] = function
------------------------------------------------------------------------
paramedit['boolean'] = function(self, paramname)
	local typedef = paramtype[paramname]
	if typedef.disableif and self[typedef.disableif] then
		imgui.TextDisabled(paramname)
	else
		local changed, newvalue = imgui.Checkbox(paramname, self[paramname])
		if changed then self[paramname] = newvalue end
	end
	
	-- paramsourceeditor(self, paramname)
	-- no reason to use game data for a boolean parameter?
end -- paramedit['boolean'] = function
------------------------------------------------------------------------
paramedit['progress'] = function(self, paramname)
	imgui.Text(paramname)
	imgui.SameLine()
	
	paramsourceeditor(self, paramname)
end -- paramedit['progress'] = function
------------------------------------------------------------------------
local colorlabels = {'r', 'g', 'b', 'a'}
paramedit['color'] = function(self, paramname)
	imgui.Text(paramname)
	
	imgui.PushItemWidth(40)
		for i = 1, 4 do
			imgui.SameLine()
			local changed, newvalue = imgui.DragFloat
				{
				'##' .. paramname .. colorlabels[i],
				self[paramname][i] * 255,
				1,
				0,
				255,
				colorlabels[i] .. ':%.0f'
				}
			if changed then self[paramname][i] = newvalue / 255 end
		end
	imgui.PopItemWidth()
	
	imgui.SameLine()
	imgui.ColorButton(unpack(self[paramname]))
end -- paramedit['color'] = function
------------------------------------------------------------------------
paramedit['list'] = function(self, paramname)
	local list = self[paramname]
	local typedef = paramtype[paramname]
	-- local dragthisframe = false
	local lastitempos
	
	if list.changed then
		list.dragtarget.top, list.dragtarget.left =
			imgui.GetCursorScreenPos()
			
		lastitempos = list.dragtarget.left + 5
		
		local default = typedef.default()
		list.buttonedges = {}
		list.buttonedges[1] = list.dragtarget.left + default.buttonedges
		list.buttoncenters = default.buttoncenters
		
		list.dragtarget.top =
			list.dragtarget.top - typedef.dragtargetmargin
			
		list.dragtarget.left =
			list.dragtarget.left - typedef.dragtargetmargin
	end -- if list.changed
	
	if list.orientation == 'horizontal' then imgui.Dummy(0, 0) end
	for index, item in ipairs(list) do
		if list.orientation == 'horizontal' then imgui.SameLine() end
		
		if typedef.listitem(self, index, list.selected == index) then
			if list.selected == index then
				list.selected = nil
			else
				list.selected = index
			end -- if list.selected == index
		end -- if typedef.listitem
		
		if imgui.IsItemHovered() and not imgui.IsMouseDown(0) then
			imgui.SetTooltip(typedef.tooltip(self))
		end
		
		if list.changed then
			if list.orientation == 'horizontal' then
				local itemwidth, _ = imgui.GetItemRectSize()
				table.insert
					{list.buttoncenters, lastitempos + 8 + itemwidth / 2}
				lastitempos = lastitempos + itemwidth + 8
				table.insert(list.buttonedges, lastitempos + 3)
			else -- assume list.orientation == 'vertical'
				-- figure this out once everything else is working
			end -- if list.orientation == 'horizontal'
		end -- if list.changed
		
		if imgui.IsItemActive() and not list.dragsource then
			list.dragsource = index
		end
		
	end -- for index, item in ipairs(list)
	
	if list.changed then
		_, list.dragtarget.bottom = imgui.GetCursorScreenPos()
		list.dragtarget.bottom =
			list.dragtarget.bottom + typedef.dragtargetmargin
		list.changed = false
		if list.orientation == 'horizontal' then
			list.dragtarget.right =
				list.buttonedges[#list.buttonedges] + typedef.dragtargetmargin
		else -- assume list.orientation == 'vertical'
			-- figure this out once everything else is working
		end -- if list.orientation == 'horizontal'
	end -- if list.changed
	
	if list.dragsource then
		if imgui.IsMouseDown(0) then
			local mousex, mousey = imgui.GetMousePos()
			
			if iswithinrect({x=mousex, y=mousey}, list.dragtarget) then
				if list.orientation == 'horizontal' then
					list.dragdest = utility.binarysearch
						{mousex, list.buttoncenters}
				else
					-- figure this out once everything else is working
				end -- if list.orientation == 'horizontal'
			else
				list.dragdest = nil
			end -- if mouse position is within list.dragtarget
		elseif list.dragdest then
			list.selected = utility.listmove
				{list, list.dragsource, list.dragdest, list.selected}
			list.changed = true
			list.dragdest = nil
			list.dragsource = nil
		end -- if imgui.IsMouseDown(0)
	end -- if list.dragsource
	
	if list.selected then
		list[list.selected]:edit()
	end
	
end -- paramedit['list'] = function
------------------------------------------------------------------------
paramedit['color gradient'] = function(self, paramname)
	-- paramedit['color'](self, paramname)
end -- paramedit['color gradient'] = function
------------------------------------------------------------------------
paramedit['format table'] = function(self, paramname)

end -- paramedit['format table'] = function
------------------------------------------------------------------------
return paramedit
