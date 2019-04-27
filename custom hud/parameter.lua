--local translate = require('custom hud.translate')
--register text table - if the language is changed, update table values to the new language.

local text =
	{
	enable = '',
	disable = '',
	}

local id =
	{
	taken = {},
	freed = {},

	new = function()
		local newid = next(id.freed)
		if newid then id.freed[newid] = nil else newid = #id.taken + 1 end
		id.taken[newid] = true
		return newid
	end,

	free = function(newfreeid)
		id.taken[newfreeid] = nil
		id.freed[newfreeid] = true
	end
	}

local parameter = {}

parameter.base =
	{
	optionalparamtoggle = function(self, label)
		if self.value == nil  then
			if imgui.Button(text.enable .. self.label .. self.id) then
				self.value = self.default
			end
		else
			imgui.SameLine()
			if imgui.Button(text.disable .. self.id) then self.value = nil end
		end
	end,
	value
	default
	label
	id -- should start with '##' for the purpose of being an imgui id.
	parent
	}

parameter.smallnumber =
	{
	minimum
	maximum
	step
	edit = function(self)
		if self.value then
			imgui.Text(self.label)
			imgui.SameLine()
			imgui.PushItemWidth(globaloptions.fontscale * 96)
				local changed, newvalue =
					imgui.InputFloat(self.id, self.value, self.step, 1, 1, '%.1f')
			imgui.PopItemWidth()
			if changed then
				self.value = math.max(self.minimum, math.min(newvalue, self.maximum))
			end
		end
		local changed, enabled = self:optionalparamtoggle()
		if changed then
			if enabled then self.fontscale = 1
			else self.fontscale = nil
			end
		end
	end
	}

return function(paramtype, newparam)
	newparam = newparam or {}
	setmetatable(newparam, {__index = parameter[paramtype]})
	return newparam
end