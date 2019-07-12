basewidget = {}
basewidget.editparam = {}
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
	update = function(self, fieldlist)
		if self.fieldcombolist and fieldlist then
			for param, field in pairs(self.map) do self[param] = fieldlist[field] end
		elseif self.map then
			for param, datafunction in pairs(self.map) do
				self[param] = datasource.get[datafunction]()
			end
		end -- if self.fieldcombolist and fieldlist
	end,
widgets.widget.__index = widgets.widget
