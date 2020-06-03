--[[
custom hud main window
catherine s (izumidaye/neonluna)
2020-04-03
]] ----------------------------------------------------------------------------
local mainWindow, menuBar, mainViews, translate, layoutScale do
	mainWindow = {}
	menuBar = {}
	mainViews = {}
end
local function toggleMainWindow()
	mainWindow.enabled = not mainWindow.enabled
end -- local function toggleMainWindow
function mainWindow.init()
	translate = CustomHUD.translate
	layoutScale = CustomHUD.layoutScale
	-- setmetatable(mainWindow, CustomHUD.Window)
	mainWindow:initLayout()
	require 'core_mainmenu'.add_button('Custom HUD', toggleMainWindow)
	CustomHUD.logger.log('finished mainWindow.init()', 'debug')
end -- function mainWindow.init

local function swapAutoSize()
	mainWindow:swapAutoSize()
end -- local function swapAutoSize
mainWindow.paramSet = {
	windowLayout = {
		edit = true,
		optional = false,
		type = 'layout',
		members = {'x', 'y', 'w', 'h', 'layout'},
		defaultValues = {x = 1, y = 0, w = .65, h = .65, layout = {}},
		category = 'mainWindow',
	}, -- layout = {...},
	manualSize = {
		edit = false,
		defaultValue = {},
	}, -- manualSize = {...},
	enabled = {
		edit = false,
		defaultValue = true,
	}, -- enabled = {...},
	autoResize = {
		edit = true,
		optional = false,
		type = 'boolean',
		defaultValue = false,
		callback = swapAutoSize,
		category = 'mainWindow',
	}, -- autoResize = {...},
	showAllWhenActive = {
		edit = true,
		optional = false,
		type = 'boolean',
		defaultValue = true,
		category = 'mainWindow',
	}, -- showAllWhenActive = {...},
} -- mainWindow.paramSet = {...}

function mainWindow.addMenuItem(args)
	if args.menuName then
		if not menuBar[args.menuName] then menuBar[args.menuName] = {} end
		table.insert(menuBar[args.menuName], args.menuItem)
	else
		table.insert(menuBar, args.menuItem)
	end -- if args.menuName
end -- function mainWindow.addMenuItem
function mainWindow.addView(viewName, view)
	mainViews[viewName] = view
end -- function mainWindow.addView
function mainWindow.setActiveView(viewName)
	mainWindow.lastView = mainWindow.activeView
	mainWindow.activeView = viewName
	print('set active view to: ' .. viewName)
end -- local function setActiveView
local function revertView()
	mainWindow.lastView = mainWindow.activeView
	mainWindow.activeView = mainWindow.lastView
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
	if not mainWindow.enabled then return end
	mainWindow:refreshLayout()
	local success
	local windowFlags = {'MenuBar'}
	if mainWindow.autoResize then table.insert(windowFlags, 'AlwaysAutoResize') end
	success, mainWindow.enabled = imgui.Begin(translate('windowTitle', 'mainWindow'), true, windowFlags)
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
	
	mainWindow:detectMouseDrag()
	
	if mainWindow.activeView and mainViews[mainWindow.activeView] then
		imgui.Text(mainWindow.activeView)
		mainViews[mainWindow.activeView]()
	end -- if mainWindow.activeView and mainViews[mainWindow.activeView]
	
	imgui.End()
end -- local function present

return {
	name = 'mainWindow',
	module = mainWindow,
	-- newTasks = {registerBbmodMenuButton,},
	usesGlobalOptions = true,
	persistent = true,
	inherits = 'Window',
	window = {name = 'mainWindow', displayFunction = present},
	dependencies = {'state', 'layoutScale'},
}
