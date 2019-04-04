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
local default = require('custom hud.default')
local convert = require('custom hud.language_english')

-- neondebug.enablelogging('general')
-- neondebug.enablelogging('presentwindowlist')
-- neondebug.enablelogging('widget')
-- neondebug.enablelogging('save serialize')
-- neondebug.enablelogging('paramedit')
neondebug.enablelogging('add new widget to window')

local lasttime = os.time()

-- initialize values in init()
local huddata
local globaloptions
local windownames
local ready

local function loaddata()
	local neww, newh = psodata.getgamewindowsize()
	if neww > 0 then
		widget.setgamewindowsize(neww, newh)
		neondebug.log('game window size: ' .. neww .. 'x' .. newh, 5, 'widget')
	
		globaloptions = utility.loadtable('globaloptions')
		if globaloptions then neondebug.log('global options loaded')
		else
			globaloptions = {longinterval = 1, allowoffscreenx = 0, allowoffscreeny = 0, fontscale = 1,}
		end
		
		widget.init(psodata, globaloptions)
	
		huddata = utility.loadtable('profile')
		if huddata then
			neondebug.log('\'profile\' loaded')
			for _, window in ipairs(huddata.windowlist) do
				widget.restore(window)
			end
		else
			neondebug.log('load(\'profile\') failed')
			huddata = {}
			huddata.windowlist = {}

			-- huddata['show main window'] = true
			huddata['show window options'] = false
		end -- if huddata
		
		ready = true
		return true
	end -- if neww > 0
end -- local function loaddata

local startuptasks = {loaddata,}

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

local function presentmainwindow()
	neondebug.log('start presentmainwindow()', 'init.lua')
	
	imgui.SetNextWindowSize(600,300,'FirstUseEver')
	local success
	success, huddata['show main window'] = imgui.Begin('custom hud editor', true)
		if not success then
			imgui.End()
			return
			neondebug.log('imgui.Begin() failed.', 'init.lua')
		end
		
		neondebug.log('imgui.Begin() succeeded.', 'init.lua')
		
		imgui.BeginGroup()
		
			-- imgui.PushItemWidth(windownames.longest * 8 * gfs)
				-- local changed, newvalue = imgui.ListBox('##window list box', huddata['selected window'] or 0, windownames, #windownames)
			-- imgui.PopItemWidth()
			-- if changed then huddata['selected window'] = newvalue end
			
			for i = 1, #huddata.windowlist do
				local window = huddata.windowlist[i]
				if imgui.Button(window['window title'] .. '##' .. i) then
					if huddata['selected window'] == i then
						huddata['selected window'] = nil
					else
						huddata['selected window'] = i
					end
				end
			end
			neondebug.log('displayed window list box', 'init.lua')
			
			if imgui.Button('add new window') then
				neondebug.log('attempting to add new window.', 'init.lua')
				table.insert(huddata.windowlist, widget.new('window'))
				neondebug.log('successfully added new window.', 'init.lua')
			end -- if imgui.Button('add new window')
			-- maybe make a pop-up dialog to enter title before adding window
			
			if imgui.Button('delete window') then
				huddata.windowlist[huddata['selected window']] = nil
				huddata['selected window'] = nil
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
			end -- if huddata['selected window']
		imgui.EndChild()
		
	imgui.End()
end -- local function presentwindowlist()

local function present()
	neondebug.log('start present()', 'init.lua')
	
	local now = os.time()
	local interval
	if globaloptions then
		interval = globaloptions.longinterval
	else
		interval = 1
	end
	if #startuptasks > 0
	and os.difftime(now, lasttime) >= interval then
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
	
	if not ready then return end
	
	psodata.retrievepsodata()
	neondebug.log('retrieved game data', 'init.lua')
	
	if huddata['show main window'] then
		presentmainwindow()
		neondebug.log('presented window list', 'init.lua')
	end
	if huddata['show debug window'] then
		huddata['show debug window'] = neondebug.present()
		neondebug.log('presented debug window', 'init.lua')
	end
	for _, window in ipairs(huddata.windowlist) do
		neondebug.log('attempting to present window: ' .. window['window title'] .. '...', 'init.lua')
		window:display()
		neondebug.log('...succeeded', 'init.lua')
	end
	
	neondebug.log('end present()', 'init.lua')
end -- local function present

local function init()
--	local pwd = io.popen([[dir 'addons\Custom HUD\core windows' /b]])
	-- local testDisplayList = {}
	-- for dir in pwd:lines() do
		-- testDisplayList[dir] = {command='showString', args={text=dir}}
		-- print('thing' .. dir .. ' end thing')
	-- end
	-- pwd:close()
		
	neondebug.log('starting first init process...', 'init.lua')
	
	psodata.init()
	neondebug.log('completed psodata.init().', 'init.lua')
	
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
	neondebug.log('set up game huddata access.', 'init.lua')
	
	
	core_mainmenu.add_button('Dynamic HUD', function()
		huddata['show main window'] = not huddata['show main window']
		end)
	
	neondebug.log('first init finished.', 'init.lua')
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
