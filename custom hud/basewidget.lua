basewidget = {}
basewidget.editparam = {}
		--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>--
		--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>--
		textcolor = function(self)
			if self.textcolor then editcolor(self, 'textcolor', 'text color') end
			local changed, enabled = optionalparamtoggle(self, 'textcolor', 'text color')
			if changed then
				if enabled then self.textcolor = {.8, .8, .8, 1}
				else self.textcolor = nil
				end
			end
		end,
		--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>--
		bgcolor = function(self)
			if self.bgcolor then editcolor(self, 'bgcolor', 'background color') end
			local changed, enabled = optionalparamtoggle(self, 'bgcolor', 'background color')
			if changed then
				if enabled then self.bgcolor = {.1, .1, .1, .5}
				else self.bgcolor = nil
				end
			end
		end,
		--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>--
		sameline = function(self)
			editboolean(self, 'sameline', textconstant'same line')
		end,
		--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>--
		textgradient = function(self)
			editboolean(self, 'dynamictextcolor', textconstant'dynamic text color')
			if self.dynamictextcolor then
				editgradient(self, 'textgradient', textconstant'text gradient')
			else
				self.editparam.textcolor(self)
			end
		end,
		--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>--
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	editparamgroup = function(self, group)
		-- neondebug.log('displaying parameter group: ' .. group, 5, 'widget')
		for _, param in ipairs(self.parameters[group]) do
			-- neondebug.log('displaying editor for ' .. group .. '.' .. param, 5, 'widget')
				self.editparam[param](self)
			-- neondebug.log('displayed ' .. group .. '.' .. param, 5, 'widget')
		end
		-- neondebug.log('done displaying parameter group: ' .. group, 5, 'widget')
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	edit = function(self)
		if self.parameters.all then editparamgroup(self, 'all')
		else
			imgui.NewLine()
			local selected
			for _, group in ipairs(self.parameters) do
				selected = self.selectedgroup == group
				imgui.SameLine()
				if self:button(group .. '##' .. (self.longname or self.id), selected) then
					if selected then self.selectedgroup = nil
					else self.selectedgroup = group
					end
				end
			end -- for _, group in ipairs(self.parameters)
			if self.selectedgroup then editparamgroup(self, self.selectedgroup) end
		end -- if self.parameters.all
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	button = function(self, label, selected, tooltip)
		if selected then
			imgui.PushStyleColor('Button', .2, .5, 1, 1)
			imgui.PushStyleColor('ButtonHovered', .3, .7, 1, 1)
			imgui.PushStyleColor('ButtonActive', .5, .9, 1, 1)
		else
			imgui.PushStyleColor('Button', .5, .5, .5, .3)
		end
		
		if imgui.Button(label)
		and not imgui.IsMouseDragging(0, globaloptions.dragthreshold)
		then return true end
		
		if selected then imgui.PopStyleColor(2) end
		imgui.PopStyleColor()
		
		if tooltip and imgui.IsItemHovered() and not imgui.IsMouseDown(0) then
			imgui.SetTooltip(self[index].longname)
		end
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	editdatasource = function(self, param, datatype)
		local changed = false
		if self.fieldcombolist then
			if self.map[param] then
				changed = combobox(self.map, param, self.fieldcombolist[datatype])
			elseif imgui.Button('use list field##' .. param) then
				changed = true
				self.map[param] = self.fieldcombolist[datatype][1]
			end
		else -- assume function source
			if self.map[param] then
				changed = combobox(self.map, param, datasource.combolist[datatype])
			elseif imgui.Button('use game data##' .. param) then
				changed = true
				self.map[param] = datasource.combolist[datatype][1]
			end
		end
		return changed
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	updatename = function(self, param)
		local newname = self.map[param] or self[param]
		self.longname = self.widgettype .. ': ' .. newname
		self.shortname = shortname[newname] or newname
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	editcolor = function(self, param, label)
		imgui.Text(textconstant(label))
		
		imgui.PushItemWidth(globaloptions.fontscale * 40)
			for i = 1, 4 do
				imgui.SameLine()
				local changed, newvalue = imgui.DragFloat(
					'##' .. param .. colorlabels[i], self[param][i] * 255, 1, 0,
					255, colorlabels[i] .. ':%.0f')
				if changed then self[param][i] = newvalue / 255 end
			end
		imgui.PopItemWidth()
		
		imgui.SameLine()
		imgui.ColorButton(unpack(self[param]))
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	editboolean = function(self, param, label)
		local changed, newvalue = imgui.Checkbox(label, self[param])
		if changed then self[param] = newvalue end
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	editstring = function(self, param, label)
		local changed = false
		local newvalue
		imgui.Text(label)
		imgui.SameLine()
		imgui.PushItemWidth(globaloptions.textinputwidth)
			changed, newvalue =
				imgui.InputText('##' .. param, self[param], 72)
		imgui.PopItemWidth()
		if changed then self[param] = newvalue end
		return changed
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	editgradient = function(self, param, label)

	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
	update = function(self, fieldlist)
		if self.fieldcombolist and fieldlist then
			for param, field in pairs(self.map) do self[param] = fieldlist[field] end
		elseif self.map then
			for param, datafunction in pairs(self.map) do
				self[param] = datasource.get[datafunction]()
			end
		end -- if self.fieldcombolist and fieldlist
	end,
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
widgets.widget.__index = widgets.widget
