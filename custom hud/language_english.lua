local converter = {}
converter.conversiontable =
	{
	['parameter - widget name'] = 'widget name',
	['parameter - format table'] = 'format table',
	['parameter - text color'] = 'text color',
	['parameter - same line'] = 'same line',
	['parameter - display text'] = 'display text',
	['parameter - overlay text'] = 'overlay text',
	['parameter - label text'] = 'label text',
	['parameter - text color gradient'] = 'text color gradient',
	['parameter - text gradient index'] = 'text gradient index',
	['parameter - text gradient range'] = 'text gradient range',
	['parameter - progress color gradient'] = 'progress color gradient',
	['parameter - progress index'] = 'progress index',
	['parameter - progress range'] = 'progress range',
	['parameter - widget color'] = 'widget color',
	['parameter - scale progress bar'] = 'scale progress bar',
	['parameter - widget width'] = 'widget width',
	['parameter - widget height'] = 'widget height',
	
	['category - data'] = 'data',
	['category - style'] = 'style',
	['category - layout'] = 'layout',
	['category - miscellaneous'] = 'miscellaneous',
	['default value - string'] = 'taco cat spelled backwards is taco cat',
	['widget editor button - clear'] = 'clear',
	['widget editor label - source:'] = 'source:',
	['widget editor button - use list field'] = 'use list field',
	['widget editor button - use game data'] = 'use game data',
	['widget editor button - use static value'] = 'use static value',
	['widget type - text'] = 'text',
	['widget type - labeled value'] = 'labeled value',
	['widget type - progress bar'] = 'progress bar',
	['widget type - formatted table'] = 'formatted table',
	['debug - log start'] = 'session log start',
	['debug - window title'] = 'custom hud debug window',
	['debug - vague error message'] = 'something went wrong',
	['psodata - armor types'] = {'frame', 'barrier', 'unit'},
	['psodata - item types'] = {'weapon', 'armor', 'mag', 'tool', 'meseta'},
	['psodata - technique disk'] = 'technique disk',
	['psodata - weapon attributes'] = {'native', 'a. beast', 'machine', 'dark', 'hit'},
	['psodata - buff / debuff tech types'] = {[9]="S", [10]="D", [11]="J", [12]="Z"},
	['psodata - menu states'] = {'main menu open', 'lower screen menu open', 'full screen menu open', 'any menu open'},
	['psodata - item location: bank'] = 'bank',
	['psodata - item location: inventory'] = 'inventory',
	['psodata - unknown item name'] = '???',
	['psodata - item special none'] = 'none',
	['window option - title'] = 'title:',
	}

converter.convert = function(valuename)
	return converter.conversiontable[valuename] or valuename
end

return converter.convert
