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

local function updatewindownames()
	windownames = {}
	for index, window in ipairs(huddata.windowlist) do
		windownames[index] = window['window title']
		windownames.longest = math.max(windownames.longest, #window['window title'])
	end
end

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
				local changed, newvalue = imgui.ListBox('##window list box', huddata['selected window'] or 0, windownames, #windownames)
			imgui.PopItemWidth()
			if changed then huddata['selected window'] = newvalue end
			
			if imgui.Button('window options') then
				huddata['show window options'] = not huddata['show window options']
			end
			
			if imgui.Button('add new window') then
				-- huddata.windowlist['new window'] = newwindow()
				-- windownames = utility.buildcombolist(huddata.windowlist)
			end -- if imgui.Button('add new window')
			-- maybe make a pop-up dialog to enter title before adding window
			
			if imgui.Button('delete window') then
				huddata.windowlist[huddata['selected window']] = nil
				huddata['selected window'] = nil
				updatewindownames()
			end
			-- definitely make a pop-up to confirm delete
			
			if imgui.Button('save') then
				utility.savetable('profile', huddata)
				utility.savetable('globaloptions', globaloptions)
			end
			
			checkbox(huddata, 'show debug window')
			
			-- widgetConfig.slownumber('global font scale', huddata, 'required', 1, 12, 0.1, '%.1f')
			
		imgui.EndGroup()
		
		imgui.SameLine()
		imgui.BeginChild('window editor', -1, -1, true)
			if huddata['selected window'] then
				huddata.windowlist[huddata['selected window']]:edit()
				-- if huddata['show window options'] then
					-- presentwindowoptions(huddata['selected window'])
				-- else
					-- presentwindoweditor(huddata['selected window'])
				-- end -- if huddata['show window options']
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
	for _, window in ipairs(huddata.windowlist) do
		neondebug.log('attempting to present window: ' .. window['window title'] .. '...', 5)
		window:display()
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
	else
		neondebug.log('load(\'profile\') failed')
		huddata = {}
		huddata.windowlist = {}

		huddata['show window list'] = true
		huddata['show window options'] = false
	end
	updatewindownames()
	
	globaloptions = utility.loadtable('globaloptions')
	if globaloptions then neondebug.log('global options loaded')
	else
		globaloptions = {longinterval = 1, allowoffscreenx = 0, allowoffscreeny = 0, fontscale = 1,}
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
