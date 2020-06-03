local Window = {}
Window.__index = Window
local imgui = imgui
local layoutScale

Window.paramSet = {
	title = {
		edit = true,
		optional = true,
		type = 'string',
		category = 'general',
	}, -- title = {...},
	layout = {
		edit = true,
		optional = false,
		type = 'layout',
		members = {'x', 'y', 'w', 'h', 'layout'},
		defaultValues = {x = 1, y = 1, w = .33, h = .12, layout = {}},
		category = 'layout',
	}, -- layout = {...},
	manualSize = {
		edit = false,
		defaultValue = {},
	}, -- manualSize = {...},
	windowFlagSet = {
		edit = true,
		optional = false,
		type = 'windowFlagSet',
		defaultValue = {'', 'NoResize', '', '', 'AlwaysAutoResize'},
		category = 'layout',
	}, -- windowFlagSet = {...},
	hideWhen = {
		edit = true,
		optional = false,
		type = 'hideConditions',
		defaultValue = {fullMenu = true, mainMenu = true, inLobby = true},
		category = 'hideConditions',
	}, -- hideWhen = {...},
} -- Window.paramSet = {...}

function Window:swapAutoSize()
	local manualSize = self.manualSize
	if self.autoResize then
		manualSize.w = self.w
		manualSize.h = self.h
		self.dragActive = true
	else
		self.x = layoutScale.fromX(self.layout.x, manualSize.w)
		self.y = layoutScale.fromY(self.layout.y, manualSize.h)
		self:setWidth(manualSize.w)
		self:setHeight(manualSize.h)
	end -- if self.autoResize
end -- function Window:swapAutoSize
function Window:initLayout()
	self:setX(self.x)
	self:setY(self.y)
	self:setWidth(self.w)
	self:setHeight(self.h)
end -- function Window:initLayout(
function Window:refreshLayout()
	if self.layout.positionChanged then
		imgui.SetNextWindowPos(self.layout.x, self.layout.y, 'Always')
		self.layout.positionChanged = nil
	end -- if self.positionChanged
	if self.layout.sizeChanged then
		imgui.SetNextWindowSize(self.layout.w, self.layout.h, 'Always')
		self.layout.sizeChanged = nil
	end -- if self.sizeChanged
end -- function Window:refreshLayout
function Window:setPositionFromState()
	imgui.SetNextWindowPos(layoutScale.toX(self.x, self.w), layoutScale.toY(self.y, self.h), 'Always')
end -- function Window:setPositionFromState
function Window:setSizeFromState()
	imgui.SetNextWindowSize(layoutScale.toWidth(self.w), layoutScale.toHeight(self.h), 'Always')
end -- function Window:setSizeFromState
function Window:detectMouseResize()
	-- if self.windowFlagSet[2] ~= 'NoResize' and self.windowFlagSet[5] ~= 'AlwaysAutoResize' then
		local newW, newH = imgui.GetWindowSize()
		newW = layoutScale.fromWidth(newW)
		newH = layoutScale.fromHeight(newH)
		if self.w ~= newW then self.w = newW end
		if self.h ~= newH then self.h = newH end
	-- end -- if self.windowFlagSet[2] ~= 'NoResize' and self.windowFlagSet[5] ~= 'AlwaysAutoResize' 
end -- function Window:detectMouseResize
function Window:detectMouseMove()
	local newX, newY = imgui.GetWindowPos()
	newX = layoutScale.fromX(newX, self.w)
	newY = layoutScale.fromY(newY, self.h)
	if self.x ~= newX then self.x = newX end
	if self.y ~= newY then self.y = newY end
end -- function Window.detectMouseMove
function Window:detectMouseDrag()
	if self.dragActive then
		if not imgui.IsMouseDown(0) then
			self:updateLayout()
			self.dragActive = nil
		end -- if not imgui.IsMouseDown
	else
		if imgui.IsMouseDown(0) then
			local newW, newH = imgui.GetWindowSize()
			local newX, newY = imgui.GetWindowPos()
			if newW ~= self.layout.w
				or newH ~= self.layout.h
				or newX ~= self.layout.x
				or newY ~= self.layout.y
			then
				self.dragActive = true
			end -- if position or size changed
		end -- if imgui.IsMouseDown(0)
	end -- if self.dragActive
end -- function Window:detectMouseDrag
function Window:setX(newX)
	self.x = newX
	self.layout.x = layoutScale.toX(newX, self.w)
	self.layout.positionChanged = true
end -- function Window:setX
function Window:setY(newY)
	self.y = newY
	self.layout.y = layoutScale.toY(newY, self.h)
	self.layout.positionChanged = true
end -- function Window:setY
function Window:setWidth(newW)
	self.w = newW
	self.layout.w = layoutScale.toWidth(newW)
	self.layout.sizeChanged = true
	self:setX(self.x)
end -- function Window:setWidth
function Window:setHeight(newH)
	self.h = newH
	self.layout.h = layoutScale.toHeight(newH)
	self.layout.sizeChanged = true
	self:setY(self.y)
end -- function Window:setHeight
function Window:updateLayout()
	CustomHUD.logger.log('updating window layout', 'debug')
	local newW, newH = imgui.GetWindowSize()
	if self.layout.w ~= newW then
		self.layout.w = newW
		self.w = layoutScale.fromWidth(newW)
	end -- self.layout.w ~= newW
	if self.layout.h ~= newH then
		self.layout.h = newH
		self.h = layoutScale.fromHeight(newH)
	end -- if self.layout.h ~= newH
	
	local newX, newY = imgui.GetWindowPos()
	local newScaledX = layoutScale.fromX(newX, self.w)
	if self.x ~= newScaledX then self:setX(newScaledX) end
	local newScaledY = layoutScale.fromY(newY, self.h)
	if self.y ~= newScaledY then self:setY(newScaledY) end
end -- function Window:updateLayout

function Window.init()
	layoutScale = CustomHUD.layoutScale
end -- function Window.init
return {
	name = 'Window',
	module = Window,
	dependencies = {'layoutScale'},
}