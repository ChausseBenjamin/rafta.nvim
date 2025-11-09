local M = {}
local tmp = require('rafta.tmp')

M.get_all = function()
	return { name = "all-tasks", tasks = tmp.dump.tasks }
end

return M
