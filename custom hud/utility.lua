local utility = {}

function utility.compareIgnoreCase(a, b) return string.lower(a) < string.lower(b) end

return {name = 'utility', module = utility}