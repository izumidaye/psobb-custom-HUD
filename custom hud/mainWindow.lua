--[[
custom hud main window
catherine s (izumidaye/neonluna)
2020-04-03
]] ----------------------------------------------------------------------------
local mainWindow, state, menuBar, mainViews, translate, layoutScale do
	mainWindow = {}
	menuBar = {}
	mainViews = {}
end
mainWindow.defaultParamValues = {
	-- windowLayout = {x = .5, y = .5, w = .65, h = .65,},
	layout = {},
	x = 1,
	y = 0,
	w = .65,
	h = .65,
	manualSize = {},
	autoResize = false,
	showAllWhenActive = true,
	enabled = true,
} -- local defaultOptions = {...}
local function swapAutoSize()
	if state.autoResize then
		state.manualSize.w, state.manualSize.h = state.w, state.h
		state.dragActive = true
	else
		-- state.w, state.h = state.manualSize.w, state.manualSize.h
		state.x = layoutScale.fromX(state.layout.x, state.manualSize.w)
		state.y = layoutScale.fromY(state.layout.y, state.manualSize.h)
		state:setWidth(state.manualSize.w)
		state:setHeight(state.manualSize.h)
	end -- if state.autoResize
	-- state:updateLayout()
end -- local function swapAutoSize
mainWindow.paramSet = {
	{name = 'windowLayout', type = 'layout'},
	{name = 'autoResize', type = 'boolean', callback = swapAutoSize},
	{name = 'showAllWhenActive', type = 'boolean'},
} -- mainWindow.optionSet = {...}
function mainWindow.addMenuItem(menuName, menuItem)
	if not menuBar[menuName] then menuBar[menuName] = {} end
	table.insert(menuBar[menuName], menuItem)
end -- function mainWindow.addMenuItem
function mainWindow.addView(viewName, view)
	mainViews[viewName] = view
end -- function mainWindow.addView
function mainWindow.setActiveView(viewName)
	state.lastView, state.activeView = state.activeView, viewName
	print('set active view to: ' .. viewName)
end -- local function setActiveView
local function revertView()
	state.lastView, state.activeView = state.activeView, state.lastView
end -- local function revertView

local registerBbmodMenuButton = {
	name = 'registerBbmodMenuButton',
	description = 'register BBmod menu button',
	run = function()
		require 'core_mainmenu'.add_button('Custom HUD', toggleMainWindow)
		return 'complete'
	end, -- run = function
} -- local registerBbmodMenuButton = {...}
local registerMainWindowGlobalOptions = {
	name = 'registerMainWindowGlobalOptions',
	description = 'register main window with global options',
	dependencies = {'globalOptions'},
	run = function()
		CustomHUD.globalOptions.register'mainWindow'
		return 'complete'
	end,
} -- local registerMainWindowGlobalOptions
local function present()
	if not state.enabled then return end
	state:refreshLayout()
	-- imgui.SetNextWindowPos(layoutScale.toX(state.x, state.w), layoutScale.toY(state.y, state.h), 'Always')
	-- if not state.autoResize then
		-- imgui.SetNextWindowSize(layoutScale.toWidth(state.w), layoutScale.toHeight(state.h), 'Always')
	-- end -- if not state.autoResize
	local success
	local windowFlags = {'MenuBar'}
	if state.autoResize then table.insert(windowFlags, 'AlwaysAutoResize') end
	success, state.enabled = imgui.Begin(translate('windowTitle', 'mainWindow'), true, windowFlags)
	if not success then
		imgui.End()
		return
	end -- if not success
	
	if imgui.BeginMenuBar() then
	for menuName, menuBarItem in pairs(menuBar) do
		if menuBarItem.type == 'item' then
			if imgui.MenuItem(translate('label', menuBarItem.name)) then
				menuBarItem.activate()
			end -- if imgui.MenuItem(...)
		else
			if imgui.BeginMenu(menuName) then
				for _, menuItem in ipairs(menuBarItem) do
					-- print(CustomHUD.serialize(menuItem, 0, true))
					if imgui.MenuItem(translate('label', menuItem.name)) then
						menuItem.activate()
					end -- if imgui.MenuItem(...)
				end -- for _, menuItem in ipairs(menuBarItem)
			imgui.EndMenu() end
		end -- if menu.type == 'item'
	end -- for menuName, menu in pairs(menuBar)
	imgui.EndMenuBar() end
	
	state:detectMouseDrag()
	
	if state.activeView and mainViews[state.activeView] then
		imgui.Text(state.activeView)
		mainViews[state.activeView]()
	end -- if state.activeView and mainViews[state.activeView]
	
	imgui.End()
end -- local function present

local function toggleMainWindow() state.enabled = not state.enabled end
local function initLayout()
	state:setX(state.x)
	state:setY(state.y)
	state:setWidth(state.w)
	state:setHeight(state.h)
end -- local function initLayout(
function mainWindow.init()
	translate = CustomHUD.translate
	layoutScale = CustomHUD.layoutScale
	-- state = CustomHUD.state.register('mainWindow', defaultOptions)
	setmetatable(mainWindow.state, CustomHUD.Window)
	-- mainWindow.options = state
	state = mainWindow.state
	-- setmetatable(state, CustomHUD.Window)
	initLayout()
	require 'core_mainmenu'.add_button('Custom HUD', toggleMainWindow)
	CustomHUD.logger.log('finished mainWindow.init()', 'debug')
end -- function mainWindow.init
return {
	name = 'mainWindow',
	module = mainWindow,
	-- newTasks = {registerBbmodMenuButton,},
	window = {name = 'mainWindow', displayFunction = present},
	dependencies = {'state', 'layoutScale'},
	inherits = 'Window',
	usesGlobalOptions = true,
	persistent = true,
}
