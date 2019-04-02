--[[
PSOBB Dynamic Info Addon
Catherine S (IzumiDaye/NeonLuna)
2018-10-05
]]

local core_mainmenu = require('core_mainmenu')
local neondebug = require('custom hud.neondebug')
local psodata = require('custom hud.psodata')
local utility = require('custom hud.utility')
local widget = require('custom hud.widget')
local paramedit = require('custom hud.paramedit')
local default = require('custom hud.default')
local convert = require('custom hud.language_english')
-- neondebug.update('this is a test', 'wow')
neondebug.enablelogging()

local lasttime = os.time()

-- initialize values in init()
local huddata
local globaloptions
local windownames

local function detectgamewindowsize()
	local neww, newh = psodata.getgamewindowsize()
	if neww > 0 then
		widget.setgamewindowsize(neww, newh)
		return true
	end
end
local startuptasks = {detectgamewindowsize,}

local function checkbox(list, paramname)
	local changed, newvalue = imgui.Checkbox(paramname, list[paramname])
	if changed then list[paramname] = newvalue end
end

local function text(textdata, color)
	color = color or default('text color')
	imgui.TextColored(color[1], color[2], color[3], color[4], textdata)
end

local function textconstant(textdata, color)
	color = color or default('text color')
	imgui.TextColored(color[1], color[2], color[3], color[4], convert(textdata))
end

local function presentwindow(windowname)
--[[
'window' attributes (*denotes required): list {*title, *id, *x, *y, *w, *h, enabled, openEditor, optionchanged, fontScale, textColor, transparent, *options, *displayList}
'options' format: list {noTitleBar, noResize, noMove, noScrollBar, AlwaysAutoResize}
'displayList': list of widgets contained in window
'item' format: list {command, args}
'args' format: arguments to be used with 'command'; program must ensure that 'args' are valid arguments for 'command'
]]
	local window = huddata.windowlist[windowname]
	if (window.hideLobby and (psodata.currentLocation() == 'lobby')) or (window.hideField and (psodata.currentLocation() ~= 'field'))--[[ or (psodata.currentLocation() == 'login')]] then return end
	for _, menu in ipairs(psodata.menuStates) do
		if psodata.get(menu) and window.hideMenuStates[menu] then return end
	end
	if window.optionchanged and psodata.screenWidth > 0 then
		imgui.SetNextWindowPos(scalex(window.x, window.w), scaley(window.y, window.h), 'Always')
		if window.options[5] ~= 'AlwaysAutoResize' then
			imgui.SetNextWindowSize(scalex(window.w), scaley(window.h), 'Always')
		end
	end
	
	imgui.Begin(windowname .. '###' .. window.id, true, window.options)
	
	if window.options[3] ~= 'NoMove' and not window.optionchanged then
		local newx, newy = imgui.GetWindowPos()
		if newx < 0 then
			newx = 0
		elseif newx + scalex(window.w) > psodata.screenWidth then
			newx = psodata.screenWidth - scalex(window.w)
		end
		window.x = unscalex(newx, window.w)
		window.y = unscaley(newy, window.h)
	end
	if window.options[2] ~= 'NoResize' then
		window.w = unscalex(imgui.GetWindowWidth())
		window.h = unscaley(imgui.GetWindowHeight())
	end
	
	local bgcolor = window['background color']
	if bgcolor then imgui.PushStyleColor('WindowBg', unpack(bgcolor)) end
	
	if huddata['global font scale'] then
		imgui.SetWindowFontScale(window.fontScale * huddata['global font scale'])
	else
		imgui.SetWindowFontScale(window.fontScale)
	end
	local fontScaleChanged = false
	
	for _, item in pairs(window.displayList) do
		if item.args.size then
			imgui.setWindowFontScale(item.args.size)
			fontScaleChanged = true
		elseif fontScaleChanged then
			imgui.setWindowFontScale(window.fontScale)
			fontScaleChanged = false
		end
		-- print(item.widgetType)
		mapcall(window, item)
		-- widgets[item.widgetType](window, item.args)
	end
	
	if bgcolor then imgui.PopStyleColor() end
		
	imgui.End()
	window.optionchanged = false
end -- local function presentwindow(windowname)

local function presentwindoweditor(windowname)
	local window = huddata.windowlist[windowname]
	local gfs = huddata['global font scale'] or 1
	imgui.SetWindowFontScale(gfs)
	
	local addNew, addIndex = false, 1
	local delete, deleteIndex = false, 1

	local changed, newValue = imgui.Combo('##new widget chooser for ' .. windowname, window.newWidgetType, widgetNames, table.getn(widgetNames))
	if changed then window.newWidgetType = newValue end
	
	imgui.NewLine()
	imgui.SameLine(312 * gfs + 48)
	if imgui.Button('Add##' .. windowname) then
		addNew, addIndex = true, 1
	end
	
	local dl = window.displayList
	local moveUp, moveDown
	for index, item in ipairs(dl) do
		imgui.PushID(index)
		moveUp, moveDown = false, false
		
		imgui.Text(item.widgetType)
		
		if index > 1 then
			imgui.SameLine(200 * gfs)
			if imgui.Button('Up') then moveUp = true end
		end
		
		if index < #dl then
			imgui.SameLine(214 * gfs + 12)
			if imgui.Button('Down') then moveDown = true end
		end
		
		imgui.SameLine(242 * gfs + 24)
		if imgui.Button('Edit') then
			if window.editindex == index then
				window.editindex = -1
			else
				window.editindex = index
			end
		end
		
		imgui.SameLine(270 * gfs + 36)
		if imgui.Button('Delete') then
			delete, deleteIndex = true, index
		end
		
		imgui.SameLine(312 * gfs + 48)
		if imgui.Button('Add After') then
			addNew, addIndex = true, index+1
		end
		
		if moveUp then
			dl[index-1], dl[index] = dl[index], dl[index-1]
		elseif moveDown then
			dl[index+1], dl[index] = dl[index], dl[index+1]
		end
		
		imgui.PopID()
		index = index + 1
	end -- for index, item in ipairs(dl)
	
	if delete then
		table.remove(dl, deleteIndex)
		if window.editindex and window.editindex >= deleteIndex then
			window.editindex = window.editindex - 1
		end
	elseif addNew and window.newWidgetType then
		local newWidget = {widgetType=widgetNames[window.newWidgetType], args={}}
		for name, value in pairs(widgetDefaults[newWidget.widgetType]) do
			-- if type(value) == 'function' then value = value() end
			newWidget.args[name] = value
		end
		table.insert(dl, addIndex, newWidget)
		if window.editindex and window.editindex >= addIndex then
			window.editindex = window.editindex + 1
		end
	end -- if delete
	
	if imgui.Button('window options') then
		if window.editindex == 0 then
			window.editindex = -1
		else
			window.editindex = 0
		end
	end -- if imgui.Button('window options')
	if window.editindex > 0 then
		imgui.NewLine()
		local item = window.displayList[window.editindex]
		imgui.Text(item.widgetType)
		
		for name, specargs in pairs(widgetSpecs[item.widgetType]) do
			imgui.Separator()
			if item.map and item.map[name] then
				widgetConfig[item.map[name][1]](name, item.map, specargs[2], true)
				imgui.SameLine()
				if imgui.Button('static value##' .. windowname .. name) then item.map[name] = nil end
			else
				widgetConfig[specargs[1]](name, item.args, specargs[2])
				if specargs[1] == 'string' or specargs[1] == 'number' or specargs[1] == 'boolean' then
					imgui.SameLine()
					if imgui.Button('dynamic value##' .. windowname .. name) then
						if not item.map then item.map = {} end
						local mapvaluetype = specargs[1] .. 'Function'
						item.map[name] = {mapvaluetype, dfNames[mapvaluetype][1]}
					end
				end -- if specargs[1] == 'string' or 'number' or 'boolean'
			end -- if item.map and item.map[name]
		end -- for name, specargs in pairs(widgetSpecs[item.widgetType])
	elseif window.editindex == 0 then
		imgui.NewLine()
		imgui.Text('Title:')
		imgui.SameLine()
		local newTitle, changed
		changed, newTitle = imgui.InputText('##Title', windowname, 30)
		if changed then
			if verifyNewwindowname(newTitle) then
				huddata.windowlist[windowname], huddata.windowlist[newTitle] = nil, huddata.windowlist[windowname]
				windowname = newTitle
			else -- invalid new window title
				imgui.SameLine()
				showText({1,0.25,0.25,1}, 'window name must be unique')
			end -- if verifyNewwindowname(newTitle)
		end -- if changed
		
		widgetConfig.boolean('enabled', window, true)
		
		-- for option, type in pairs(posoptions) do
			-- if widgetConfig[type](option, window, true, 0, 100, 0.01, '%.2f%%') then window.optionchanged = true end
		-- end -- for option, type in pairs(posoptions)
		local changed = false
		changed = widgetConfig.xpos('x', window, true, scalex(window.x, window.w)) or changed
		changed = widgetConfig.ypos('y', window, true, scaley(window.y, window.h)) or changed
		changed = widgetConfig.xpos('w', window, true, scalex(window.w)) or changed
		changed = widgetConfig.ypos('h', window, true, scaley(window.h)) or changed
		if changed then window.optionchanged = true end
		
		-- local changed1, changed2 = false, false
		
		
		widgetConfig.number('fontScale', window, 'required', 1, 12, 0.1, '%.1f')
		widgetConfig.color('textColor', window, 'required')
		widgetConfig.color('background color', window, 'optional')
		
		flagCheckBox(windowname, {label='no title bar', options=window.options, index=1, flag='NoTitleBar'})
		flagCheckBox(windowname, {label='no resize', options=window.options, index=2, flag='NoResize'})
		flagCheckBox(windowname, {label='no move', options=window.options, index=3, flag='NoMove'})
		flagCheckBox(windowname, {label='no scroll bar', options=window.options, index=4, flag='NoScrollBar'})
		flagCheckBox(windowname, {label='auto resize', options=window.options, index=5, flag='AlwaysAutoResize'})
		-- for i = 1, 5 do
			-- flagCheckBox(windowname, {label=flaglabels[i], options=window.options, index=i, flag=windowflags[i]})
		-- end -- for i = 1, 5
	
		imgui.NewLine()
		imgui.Text('hide window when:')
		for index, state in ipairs(psodata.menuStates) do
			widgetConfig.boolean(state, window.hideMenuStates, true)
		end
		if imgui.Checkbox('not in field##' .. windowname, window.hideField) then
			window.hideField = not window.hideField
		end
		if imgui.Checkbox('in lobby##' .. windowname, window.hideLobby) then
			window.hideLobby = not window.hideLobby
		end
	end -- if window.editindex
	
-- imgui.End()
end

local function presentwindowoptions(windowid)
	local thiswindow = huddata.windowlist[windowid]
	textconstant('window option - title')
	local changed, newvalue = imgui.InputText
		{'##title', thiswindow['title'], default('inputtext buffer size')}
	if changed then thiswindow['title'] = newvalue end
end

local function addwindow(newtitle)
	local newid = getuniqueid()
	local offset = newid * 5
	huddata.windowlist[newid] =
		{
		-- ['general'] = {['title']
		title = newtitle,
		x=offset,
		y=offset,
		w=20,
		h=20,
		enabled=true,
		optionchanged=true,
		transparent=false,
		options={'', '', '', '', ''},
		hideLobby=true,
		hideField=true,
		hideMenuStates = {['full screen menu open']=true},
		widget = widget.new('widget list'),
		fontScale=1,
		[stringconstant['parameter - text color']] = default('text color'),
		}
end

local function presentwindowlist()

	imgui.SetNextWindowSize(600,300,'FirstUseEver')
	local success
	success, huddata['show window list'] = imgui.Begin('custom hud window list', true)
		if not success then
			imgui.End()
			return
		end
		
		imgui.BeginGroup()
		
			imgui.PushItemWidth(windownames.longest * 8 * gfs)
				local changed, newvalue = imgui.ListBox('##window list box', windownames[huddata['selected window']] or 0, windownames, #windownames)
			imgui.PopItemWidth()
			if changed then huddata['selected window'] = windownames[newvalue] end
			
			if imgui.Button('window options') then
				huddata['show window options'] = not huddata['show window options']
			end
			
			if imgui.Button('add new window') then
				huddata.windowlist['new window'] = newwindow()
				windownames = utility.buildcombolist(huddata.windowlist)
			end -- if imgui.Button('add new window')
			-- maybe make a pop-up dialog to enter title before adding window
			
			if imgui.Button('delete window') then
				huddata.windowlist[huddata['selected window']] = nil
				huddata['selected window'] = nil
				windownames = utility.buildcombolist(huddata.windowlist)
			end
			-- definitely make a pop-up to confirm delete
			
			if imgui.Button('save') then
				utility.savetable('profile', huddata)
				utility.savetable('globaloptions', globaloptions)
			end
			
			checkbox(huddata, 'show debug window')
			
			widgetConfig.slownumber('global font scale', huddata, 'required', 1, 12, 0.1, '%.1f')
			
		imgui.EndGroup()
		
		imgui.SameLine()
		imgui.BeginChild('window editor', -1, -1, true)
			if huddata['selected window'] then
				if huddata['show window options'] then
					presentwindowoptions(huddata['selected window'])
				else
					presentwindoweditor(huddata['selected window'])
				end -- if huddata['show window options']
			end -- if huddata['selected window']
		imgui.EndChild()
		
	imgui.End()
end -- local function presentwindowlist()

local function present()
	neondebug.log('start present()', 5)
	
	local now = os.time()
	if #startuptasks > 0
	and os.difftime(now, lasttime) >= globaloptions.longinterval then
		local taskindex = 1
		repeat
			if startuptasks[taskindex]() then
				startuptasks[taskindex] = nil
			else
				taskindex = taskindex + 1
			end
		until taskindex > #startuptasks
		lasttime = now
	end
	
	psodata.retrievepsodata()
	neondebug.log('retrieved game data', 5)
	
	if huddata['show window list'] then
		presentwindowlist()
		neondebug.log('presented window list', 5)
	end
	if huddata['show debug window'] then
		huddata['show debug window'] = neondebug.present()
		neondebug.log('presented debug window', 5)
	end
	for _, window in pairs(huddata.windowlist) do
		if window.enabled then
			neondebug.log('attempting to present window: ' .. windowname .. '...', 5)
			presentwindow(windowname)
		end
		neondebug.log('...succeeded', 5)
	end
	
	neondebug.log('end present()', 5)
end -- local function present

local function init()
--	local pwd = io.popen([[dir 'addons\Custom HUD\core windows' /b]])
	-- local testDisplayList = {}
	-- for dir in pwd:lines() do
		-- testDisplayList[dir] = {command='showString', args={text=dir}}
		-- print('thing' .. dir .. ' end thing')
	-- end
	-- pwd:close()
		
	neondebug.log('starting init process')
	
	huddata = utility.loadtable('profile')
	if huddata then
		neondebug.log('\'profile\' loaded')
		for _, window in pairs(huddata.windowlist) do
			window.optionchanged = true
			window.id = newid()
		end
		windownames = utility.buildcombolist(huddata.windowlist)
	else
		neondebug.log('load(\'profile\') failed')
		huddata = {}
		huddata.windowlist = {}

		huddata['show window list'] = true
		huddata['show window options'] = false
	end
	
	globaloptions = utility.loadtable('globaloptions')
	if globaloptions then neondebug.log('global options loaded')
	else
		globaloptions = {longinterval = 1, allowoffscreenx = 0, allowoffscreeny = 0}
	end
	
	psodata.init()
	neondebug.log('completed psodata.init()')
	
	psodata.setactive('player')
	psodata.setactive('meseta')
	psodata.setactive('monsterlist')
	psodata.setactive('xp')
	psodata.setactive('ata')
	psodata.setactive('party')
	psodata.setactive('flooritems')
	psodata.setactive('inventory')
	psodata.setactive('bank')
	psodata.setactive('sessiontime')
	neondebug.log('set up game huddata access')
	
	widget.init(psodata, globaloptions)
	
	
	-- local function mainMenuButtonHandler()
		-- huddata['show window list'] = not huddata['show window list']
	-- end

	core_mainmenu.add_button('Dynamic HUD', function()
		huddata['show window list'] = not huddata['show window list']
		end)
	
	neondebug.log('init finished')
	return
		{
		name = 'Custom HUD',
		version = '0.5',
		author = 'IzumiDaye',
		description = 'Build your own custom HUD',
		present = present,
		}
end

return {__addon = {init = init}}
