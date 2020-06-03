--[[
task queue and handler
catherine s (izumidaye/neonluna)
2020-03-31
]] ----------------------------------------------------------------------------
-- task: {name=, description=, dependencies={}, run=function()<task body>}

local taskIndex, totalStartupTasks, taskQueue, tasks, RUNLENGTH do
	taskIndex = 1
	totalStartupTasks = 0
	taskQueue = {}
	tasks = {}
	RUNLENGTH = 1 / 30 * .1
end

local function showStartupWindow()
	local startupTasksCompleted = totalStartupTasks - #taskQueue
	local progress = startupTasksCompleted / totalStartupTasks
	local progressText = startupTasksCompleted .. '/' .. totalStartupTasks
	local windowTitle
	if CustomHUD.languageTable then
		windowTitle = CustomHUD.languageTable.windowTitle.startup
	else
		windowTitle = 'starting custom hud'
	end
	imgui.SetNextWindowSize(288,72,'Once')
	imgui.SetNextWindowFocus()
	if imgui.Begin(windowTitle .. '###startupProgress', nil, { 'NoCollapse', 'NoResize'}) then
		imgui.PushStyleColor('Text', 0, 0, 0, 1)
		imgui.PushStyleColor('PlotHistogram', 0.24, 0.71, 0.29, 1)
		imgui.ProgressBar(progress, -1, -1, progressText)
		imgui.PopStyleColor(2)
	end imgui.End()
	if startupTasksCompleted == totalStartupTasks then
		CustomHUD.displayList.remove'startupProgress'
	end -- if startuptaskscompleted == totalstartuptasks
end -- local function showStartupWindow
local function getDepStatus(dependency)
	if CustomHUD[dependency] then
		return 'ready'
	else
		if CustomHUD.brokenComponents[dependency] then
			return 'broken'
		else
			return 'not ready'
		end -- if CustomHUD.brokenComponents[dependency]
	end -- if CustomHUD[dependency]
end -- local function getDepStatus
local function processDepStatusTable(depStatusTable, task)
	local dependencyStatus = 'ready'
	for dependency, status in pairs(depStatusTable) do
		if status == 'broken' then
			CustomHUD.logger.log('task "' .. task.description .. '" depends on broken component: "' .. dependency .. '"', 'error')
			dependencyStatus = 'broken dependency'
		elseif status == 'not ready' and dependencyStatus ~= 'broken dependency' then
			CustomHUD.logger.log('task "' .. task.description .. '" dependency not yet loaded: "' .. dependency .. '"', 'startup')
			dependencyStatus = 'not ready'
		end -- if status == 'broken'
	end -- for dependency, status in pairs(depStatusTable)
	return dependencyStatus
end -- local function processDepStatusTable
local function areDependenciesMet(task)
	local depStatusTable = {}
	if task.dependencies then
		for _, dependency in ipairs(task.dependencies) do
			depStatusTable[dependency] = getDepStatus(dependency)
		end -- for _, dependency in ipairs(task.dependencies)
	end -- if task.dependencies
	if task.inherits then
		depStatusTable[task.inherits] = getDepStatus(task.inherits)
	end -- if task.inherits
	return processDepStatusTable(depStatusTable, task)
end -- local function areDependenciesMet
local function processWhenReady(result)
	tasks.add{
		name = result.name,
		description = 'process result: [' .. result.name .. '] when ready',
		dependencies = result.dependencies,
		inherits = result.inherits,
		run = function()
			CustomHUD.processTaskResult(result)
			return 'complete'
		end, -- run = function()
	} -- tasks.add{...}
end -- local function processWhenReady
local function run(task)
	local taskStartTime = os.clock()
	local result = CustomHUD.logPcall(task.run, task.description)
	local taskTimeTaken = os.clock() - taskStartTime
	CustomHUD.logger.log(string.format('task "%s" run in %.3fs.', task.description, taskTimeTaken), 'startup')
	return result
end -- local function run
local function tryNext(task)
	local dependencyStatus = areDependenciesMet(task)
	if dependencyStatus == 'ready' then
		local result = run(task)
		if type(result) == 'table' then
			processWhenReady(result)
			return 'complete'
		else
			return result
		end
	elseif dependencyStatus == 'not ready' then
		CustomHUD.logger.log('task "' .. task.description .. '" incomplete; dependencies unmet.', 'startup')
		return 'incomplete'
	elseif dependencyStatus == 'broken dependency' then
		CustomHUD.logger.log('task "' .. task.description .. '" failed; dependencies broken.', 'error')
		return 'failure'
	end -- if dependencyStatus == 'ready'
end -- local function tryNext
function tasks.add(newTask)
	table.insert(taskQueue, newTask)
	totalStartupTasks = totalStartupTasks + 1
end -- function tasks.add
function tasks.run()
	local frameStart = os.clock()
	while #taskQueue > 0 and os.clock() - frameStart < RUNLENGTH do
		local task = taskQueue[taskIndex]
		local result = tryNext(task)
		if result == 'complete' then
			table.remove(taskQueue, taskIndex)
		elseif result == 'incomplete' then
			taskIndex = taskIndex + 1
		elseif result == 'failure' then
			table.remove(taskQueue, taskIndex)
			CustomHUD.logger.log('task "' .. task.description .. '" failed.', 'error')
		elseif result == nil then
			table.remove(taskQueue, taskIndex)
			CustomHUD.logger.log('task "' .. task.description .. '" returned nil.', 'error')
		end -- if result == 'complete'
		if not taskQueue[taskIndex] then taskIndex = 1 end
	end -- while #taskQueue > 0 and os.clock() - frameStart < RUNLENGTH
end -- function tasks.run

tasks.add{
	name = 'startupProgressDisplayListRegister',
	description = 'add startupProgress window to displayList',
	dependencies = {'displayList'},
	run = function()
		CustomHUD.displayList.add{
			name = 'startupProgress',
			displayFunction = showStartupWindow
		}
		return 'complete'
	end, -- run = function
} -- tasks.add{...}
return {
	name = 'tasks',
	module = tasks,
--	window = {name = 'startupProgress', displayFunction = showStartupWindow}
}
