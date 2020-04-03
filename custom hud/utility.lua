local utility = {}

function utility.compareignorecase(a, b) return string.lower(a) < string.lower(b) end

return {name = 'utility', module = utility}