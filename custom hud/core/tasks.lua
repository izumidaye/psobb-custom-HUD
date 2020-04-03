--[[
task queue and handler
catherine s (izumidaye/neonluna)
2020-03-31
]] ----------------------------------------------------------------------------
-- task: {name=, description=, dependencies={}, run=function()<task body; everything else is metadata>}

local taskindex, totalstartuptasks, taskqueue, tasks, RUNLENGTH do
	taskindex = 1
	totalstartuptasks = 0
	taskqueue = {}
	tasks = {}
	RUNLENGTH = 1 / 30 * .1
end

local function showstartupprogresswindow()
	local startuptaskscompleted = totalstartuptasks - #taskqueue
	local progress = startuptaskscompleted / totalstartuptasks
	local progresstext = startuptaskscompleted .. '/' .. totalstartuptasks
	local windowtitle
	if customhud.languagetable then
		windowtitle = customhud.languagetable.windowtitle.startup
	else
		windowtitle = 'starting custom hud'
	end
	imgui.SetNextWindowSize(288,72,'Once')
	if imgui.Begin(windowtitle, nil, {'NoCollapse', 'NoResize'}) then
		imgui.PushStyleColor('Text', 0, 0, 0, 1)
		imgui.PushStyleColor('PlotHistogram', 0.24, 0.71, 0.29, 1)
		imgui.ProgressBar(progress, -1, -1, progresstext)
		imgui.PopStyleColor(2)
	end imgui.End()
	if startuptaskscompleted == totalstartuptasks then
		customhud.removedisplayfunction'show startup progress window'
	end -- if startuptaskscompleted == totalstartuptasks
end -- local function showstartupprogresswindow
local function aredependenciesmet(task)
	local dependenciesmet = true
	if task.dependencies then
		for _, dependency in ipairs(task.dependencies) do
			if not customhud[dependency] then
				customhud.logmain('task "' .. task.description .. '" dependency not met: "' .. dependency .. '"')
				dependenciesmet = false
			end
		end -- for _, dependency in ipairs(task.dependencies)
	end -- if task.dependencies
	return dependenciesmet
end -- local function aredependenciesmet
local function processresult(result)
	if result.newtasks then
		for _, newtask in ipairs(result.newtasks) do
			customhud.addtask(newtask)
		end -- for _, newtask in ipairs(result.newtasks)
	end -- if result.newtasks
	
	if result.module then
		customhud.addmodule(result.name, result.module)
	end -- if result.modules
	
	if result.displayfunctions then
		for name, displayfunction in pairs(result.displayfunctions) do
			customhud.adddisplayfunction(name, displayfunction)
		end -- for name, displayfunction in pairs(result.displayfunctions)
	end -- if result.displayfunctions
end -- local function processresult
local function processwhenready(result)
	customhud.addtask{
		name = result.name,
		description = 'process result for task [' .. result.name .. '] when dependencies are met',
		run = function()
			if aredependenciesmet(result) then
				processresult(result)
				return true
			end -- if aredependenciesmet(result)
		end, -- run = function
	} -- customhud.addtask{...}
end -- local function processwhenready
local function trynexttask()
	local task = taskqueue[taskindex]
	if aredependenciesmet(task) then
		local taskstarttime = os.clock()
		local result = customhud.logpcall(task.run, task.description)
		local tasktimetaken = os.clock() - taskstarttime
		if result then
			customhud.logmain(string.format('task "%s" completed successfully in %.3fs.', task.description, tasktimetaken))
			table.remove(taskqueue, taskindex)
			if result.dependencies then
				customhud.addtask(processwhenready(result))
			else -- result has no dependencies
				processresult(result)
			end -- if result.dependencies
		end -- if result
	else -- task dependencies not met
		customhud.logmain('task "' .. task.description .. '" incomplete.')
		taskindex = taskindex + 1
	end -- if aredependenciesmet(task)
end -- local function trynexttask
tasks.add = function(newtask)
	table.insert(taskqueue, newtask)
	totalstartuptasks = totalstartuptasks + 1
end
tasks.run = function()
	-- local attemptedtask = false
	local framestart = os.clock()
	while #taskqueue > 0 and os.clock() - framestart < RUNLENGTH do
		-- attemptedtask = true
		trynexttask()
	end -- while #taskqueue > 0 and os.clock() - framestart < RUNLENGTH
	if not taskqueue[taskindex] then taskindex = 1 end
	-- frame1 = frame2
end -- local function runtasks

return {name = 'tasks', module = tasks}
