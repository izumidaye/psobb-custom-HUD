local utility = require'custom hud.utility'
local psodata = require'custom hud.psodata'
--local translate = require('custom hud.translate')
--register text table - if the language is changed, update table values to the new language.

local text =
	{
	enable = '',
	disable = '',
	}
--------------------------------------------------------------------------------
local baseparam = {}
baseparam.__index = baseparam
--[[
	should be initialized with:
	value
	default
	label
	id
	optional
	parent(?)
]]
function baseparam:new(newparam)
	newparam.id = newid()
	setmetatable(newparam, self)
	
	if newparam.optional then
		newparam.enablebuttontext = text.enable .. newparam.label .. '##' .. newparam.id
		newparam.disablebuttontext = text.disable .. '##' .. newparam.id
	end
	
	return newparam
end
function baseparam:optionalparamtoggle()
	if self.optional then
		if self.value == nil  then
			if imgui.Button(self.enablebuttontext) then
				self.value = self.default
				return true
			end
		else
			imgui.SameLine()
			if imgui.Button(self.disablebuttontext) then
				self.value = nil
				return true
			end
		end
	end
end
local parameter = {}
--------------------------------------------------------------------------------
addparameter('layout')
-- value type: table (position and size, as percents)
-- extra attributes: pixellayout (position and size, in actual window coordinates), boundary (area of screen where windows are allowed to be, in percents), display (values to be displayed to user - user can choose percents or pixels)
local layoutelements = {'x', 'y', 'w', 'h'}
function parameter.layout:edit()
	local changed, newvalue = imgui.DragFloat('x##' .. self.id, self.value.x, .01, self.boundary.left, self.boundary.right, 'x')
	self:updatevalue(changed, newvalue, 'x')
	imgui.SameLine()
	changed, newvalue = imgui.InputFloat('##' .. self.id, self.value.x, .01, 1, 1, self.display.x)
	self:updatevalue(changed, newvalue, 'x', self.boundary.left, self.boundary.right)
	
	changed, newvalue = imgui.DragFloat('y##' .. self.id, self.value.y, .01, self.boundary.top, self.boundary.bottom, 'y')
	self:updatevalue(changed, newvalue, 'y')
	imgui.SameLine()
	changed, newvalue = imgui.InputFloat('##' .. self.id, self.value.y, .01, 1, 1, self.display.y)
	self:updatevalue(changed, newvalue, 'y', self.boundary.top, self.boundary.bottom)
	
	changed, newvalue = imgui.DragFloat('w##' .. self.id, self.value.w, .01, 1, self.boundary.width, 'w')
	self:updatevalue(changed, newvalue, 'w')
	imgui.SameLine()
	changed, newvalue = imgui.InputFloat('##' .. self.id, self.value.w, .01, 1, 1, self.display.w)
	self:updatevalue(changed, newvalue, 'w', 1, self.boundary.width)
	
	changed, newvalue = imgui.DragFloat('h##' .. self.id, self.value.h, .01, 1, self.boundary.height, 'h')
	self:updatevalue(changed, newvalue, 'h')
	imgui.SameLine()
	changed, newvalue = imgui.InputFloat('##' .. self.id, self.value.h, .01, 1, 1, self.display.h)
	self:updatevalue(changed, newvalue, 'h', 1, self.boundary.height)
end -- function parameter.layout:edit
function parameter.layout:updatevalue(changed, newvalue, element, minimum, maximum)
	if changed then
		if minimum and maximum then
			self.value[element] = utility.bindnumber(newvalue, minimum, maximum)
		else
			self.value[element] = newvalue
		end
		self.changed = true
		if element == 'x' then
			self.pixellayout.x =
				utility.scale(newvalue, psodata.screenwidth, self.value.w)
		elseif element == 'y' then
			self.pixellayout.y =
				utility.scale(newvalue, psodata.screenheight, self.value.h)
		elseif element == 'w' then
			self.pixellayout.w = utility.scale(newvalue, psodata.screenwidth)
		elseif element == 'h' then
			self.pixellayout.h = utility.scale(newvalue, psodata.screenheight)
		end
		if globaloptions.showlayoutpercents then
			self.display[element] = newvalue
		else
			self.display[element] = self.pixellayout[element]
		end
	end -- if changed then
end -- function parameter.layout:updatevalue
--------------------------------------------------------------------------------
local colorlabels = {'r', 'g', 'b', 'a'}
local function coloredit()
	imgui.Text(self.label)
	
	imgui.PushItemWidth(globaloptions.fontscale * 40)
		for i = 1, 4 do
			imgui.SameLine()
			local changed, newcolor = imgui.DragFloat(self.id .. i,
				self.value[i] * 255, 1, 0, 255, colorlabels[i] .. ':%.0f')
			if changed then self.value[i] = newcolor / 255 end
		end
	imgui.PopItemWidth()
	
	imgui.SameLine()
	imgui.ColorButton(unpack(self.value))
	
	self:optionalparamtoggle()
end
addparameter('color', coloredit)
--------------------------------------------------------------------------------
return parameter