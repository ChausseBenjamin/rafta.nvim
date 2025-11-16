local M = {}
local tmp = require('rafta.tmp')

---@class rafta.model.task
---@field short_id integer
---@field id rafta.model.task.id
---@field data rafta.model.task.data
---@field Metadata rafta.model.task.metadata

---@class rafta.model.task.id
---@field value string

---@class rafta.model.task.data
---@field title string
---@field desc string
---@field state 'PENDING'|'ONGOING'|'DONE'|'BLOCKED'|'UNSPECIFIED'
---@field priority integer
---@field recurrence table
---@field doDate string
---@field dueDate string
---@field tags string[]

---@class rafta.model.task.data.recurrence
---@field active boolean
---@field pattern string

---@class rafta.model.task.metadata
---@field createdOn string
---@field updatedOn string

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
