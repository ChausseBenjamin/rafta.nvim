local M = {}
local tmp = require('rafta.tmp')

-- TODO: grab that from from the grpc bridge
local cache = tmp.dump.tasks

M.get_all = function()
	return { name = "all-tasks", tasks = cache }
end

M.get_subset = function(name, filter)
	local subset = {}
	for _, task in ipairs(cache) do
		if filter(task) then
			table.insert(subset, task)
		end
		return { name = name, tasks = subset }
	end
end

return M
