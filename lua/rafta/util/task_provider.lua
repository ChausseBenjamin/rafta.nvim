local M = {}

local model = require('rafta.model')
local log = require('rafta.util.log')

---@class rafta.util.task-provider
---@field short_id fun(): integer
---@field title fun(): string|nil
---@field desc fun(): string|nil
---@field state fun(): string|nil
---@field priority fun(): integer|nil
---@field tags fun(): table|nil
---@field due_date fun(): string|nil
---@field do_date fun(): string|nil
---@field created fun(): string|nil
---@field modified fun(): string|nil
---@field recurrence fun(): rafta.model.task.data.recurrence

---@param src rafta.model.task|string
---@return rafta.util.task-provider?
M.new = function(src)
	if type(src) == 'table' then
		return M.new_table_provider(src)
	elseif type(src) == 'string' then
		return M.new_line_provider(src)
	else
		log.error('Unable to generate a task provider', {
			input = vim.inspect(src)
		})
		return
	end
end

---@param tbl rafta.model.task
---@return rafta.util.task-provider
M.new_table_provider = function(tbl)
	local S = { -- S for Service
		short_id      = function() return tbl.short_id end,
		title         = function() return (tbl.data and tbl.data.title) or nil end,
		desc          = function() return (tbl.data and tbl.data.desc) or nil end,
		state         = function() return (tbl.data and tbl.data.state) or nil end,
		priority      = function() return (tbl.data and tbl.data.priority) or nil end,
		tags          = function() return (tbl.data and tbl.data.tags) or nil end,
		due_date      = function() return (tbl.data and tbl.data.dueDate) or nil end,
		do_date       = function() return (tbl.data and tbl.data.doDate) or nil end,
		recurrence    = function() return (tbl.data and tbl.data.recurrence) or nil end,
		created_date  = function() return (tbl.Metadata and tbl.Metadata.createdOn) or nil end,
		modified_date = function() return (tbl.Metadata and tbl.Metadata.updatedOn) or nil end,
	}
	return S
end

---@param line string
---@return rafta.util.task-provider
M.new_line_provider = function(line)
	-- "/short_id state (priority) title"
	local short_id_s, state, priority_s, title =
			line:match("^/(%d+)%s+(%S+)%s+%((%d+)%)%s+(.+)$")

	local short_id = tonumber(short_id_s)
	local priority = tonumber(priority_s)

	-- lazy resolver (cached after first lookup)
	local task
	local function resolve()
		if task then
			return task
		end
		for _, t in ipairs(model.get_all().tasks) do
			if t.short_id == short_id then
				task = t
				break
			end
		end
		return task
	end

	local function field(path)
		local t = resolve()
		return t and t.data and t.data[path]
	end


	local S = {
		short_id   = function() return short_id end,
		state      = function() return state or (field('state')) end,
		priority   = function() return priority or (field('priority')) end,
		title      = function() return title or (field('title')) end,
		desc       = function() return field('desc') end,
		tags       = function() return field('data.tags') end,
		due_date   = function() return field('data.dueDate') end,
		do_date    = function() return field('data.doDate') end,
		created    = function() return field('Metadata.createdOn') end,
		modified   = function() return field('Metadata.updatedOn') end,
		recurrence = function() return field('data.recurrence') end,
	}

	return S
end

return M
