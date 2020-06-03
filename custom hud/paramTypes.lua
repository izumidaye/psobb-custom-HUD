local paramTypes = {}

paramTypes.hideWhen = {
	editor = 'hideConditions',
	optional = false,
	defaultValue = {fullMenu = true, mainMenu = true, inLobby = true},
} -- paramTypes.hideWhen = {...}
paramTypes.label = {
	editor = 'label',
	optional = true,
	defaultValue = 'automatic',
	notifyChanges = true,
} -- paramTypes.label = {...}
paramTypes.layout = {
	editor = 'layout',
	optional = false,
	members = {'x', 'y', 'w', 'h', 'layout'},
	defaultValues = {x = .5, y = .5, w = .33, h = .12, layout = {}},
} -- paramTypes.layout = {...}
paramTypes.manualSize = {defaultValue = {}}
paramTypes.sameLine = {
	editor = 'boolean',
	optional = true,
	defaultValue = false,
} -- paramTypes.sameLine = {...}
paramTypes.stringDataSource = {
	editor = 'dataSource',
	args = {'string'},
	defaultValue = 'playerhp',
	notifyChanges = true,
} -- paramTypes.stringDataSource = {...}
paramTypes.textColor = {
	editor = 'color',
	optional = true,
	defaultValue = {.8, .8, .8, 1},
} -- paramTypes.textColor = {...}
paramTypes.title = {
	editor = 'string',
	optional = true,
} -- paramTypes.title = {...}
paramTypes.windowFlagSet = {
	editor = 'windowFlagSet',
	optional = false,
	defaultValue = {'', 'NoResize', '', '', 'AlwaysAutoResize'},
} -- paramTypes.windowFlagSet = {...}

return {
	name = 'paramTypes',
	module = 'paramTypes',
}