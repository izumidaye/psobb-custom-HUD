local layoutScale = {}
local xLimit, yLimit

--[[
Layout values (x, y, width, height) are stored as values in the range [0, 1]
These values are converted to pixels at runtime in 2 cases:
1: when using the values to layout elements on-screen
2: when the user is editing them, the values will be simultaneously displayed in both formats

Width and height are simple to convert; simply multiply the stored value by the corresponding part of the game window's size
X and y values correspond to the top-left corner of an element, but are scaled such that a value of 1 places the element at the right or bottom edge of the screen, without going off the screen. Therefore, the element's width or height is needed to calculate the x or y pixel value.
]]
local function round(number, places)
-- rounds up if decimal >= .5 else rounds down
	if places then
		local mult = math.pow(10, places)
		return math.ceil(number * mult - 0.5) / mult
	else
		return math.ceil(number - 0.5)
	end
end -- local function round
local function limitNumber(number, min, max)
	return math.min(math.max(min, number), max)
end -- local function limitNumber
function layoutScale.toWidth(widthFraction)
	return round(widthFraction * xLimit)
end -- function layoutScale.toWidth
function layoutScale.fromWidth(width) return width / xLimit end
function layoutScale.toHeight(heightFraction)
	return round(heightFraction * yLimit)
end -- function layoutScale.toHeight
function layoutScale.fromHeight(height) return height / yLimit end
function layoutScale.toX(xFraction, widthFraction)
	local availableSpace = (1 - widthFraction) * xLimit
	return round(xFraction * availableSpace)
end -- function layoutScale.toX
function layoutScale.fromX(x, widthFraction)
	local availableSpace = round((1 - widthFraction) * xLimit)
	return limitNumber(x / availableSpace, 0, 1)
end
function layoutScale.toY(yFraction, heightFraction)
	local availableSpace = (1 - heightFraction) * yLimit
	return round(yFraction * availableSpace)
end -- function layoutScale.toY
function layoutScale.fromY(y, heightFraction)
	local availableSpace = round((1 - heightFraction) * yLimit)
	return limitNumber(y / availableSpace, 0, 1)
end

function layoutScale.init()
	xLimit = CustomHUD.gameWindowSize.w
	yLimit = CustomHUD.gameWindowSize.h
end
return {
	name = 'layoutScale',
	module = layoutScale,
	dependencies = {'gameWindowSize'},
}
