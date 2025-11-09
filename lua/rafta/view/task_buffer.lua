---All buffers in which you can see and manipulate task states,title,priority
---Other task attributes such as dates, and tags are hinted at but not editable
local M = {}
local api = vim.api

local model = require 'rafta.model'
local extmarks = require 'rafta.view.extmarks'
local log = require 'rafta.util.log'

M.protocol = 'rafta://'

---@class view
---@field name string
---@field bufnr integer
---@field extmarks table<integer, integer> -- short_id -> extmark_id

---A table mapping buffer numbers to view objects
---@type table<integer, view>
-- for k, _ in ipairs(views) do
-- 	api.nvim_buf_delete(k, {})
-- end
local views = {}

M.opts = {
	buf_hidden = true, -- wether to show the task view buffers with `:ls`
	state_keys = {
		unspecified = '?',
		pending     = '.',
		ongoing     = '~',
		done        = 'x',
		blocked     = '!',

	}
}

M.new_view = function(name, tasks)
	local bufnr = api.nvim_create_buf(M.opts.buf_hidden, false)
	api.nvim_buf_set_option(bufnr, 'swapfile', false)
	local fullname = M.protocol

	if name and name ~= '' then
		fullname = fullname .. name
	else
		fullname = fullname .. 'view_' .. tostring(bufnr)
	end
	api.nvim_buf_set_name(bufnr, fullname)

	local ext_table = M.refresh_buffer(bufnr, tasks)

	views[bufnr] = {
		name = fullname,
		bufnr = bufnr,
		extmarks = ext_table,
	}

	return bufnr
end

M.view_all = function()
	local all = model.get_all()
	M.new_view(all.name, all.tasks)
end

M.refresh_buffer = function(bufnr, tasks)
	local lines = {}
	local ext_table = {}

	if tasks then
		for _, task in ipairs(tasks) do
			local short_id = task.short_id
			local state = (task.data and task.data.state and task.data.state:lower()) or 'unspecified'
			local task_char = M.opts.state_keys[state] or '?'
			local task_title = (task.data and task.data.title) or '<no title>'
			-- Hard cap is at 9999 right now, but I guess that's enough until I get
			-- some an angry PR from some random dude with over ten thousand tasks...
			-- Then, hexadecimal would reach 65 thousand while keeping 4 characters.
			lines[#lines + 1] = string.format("/%04d %s %s", short_id, task_char, task_title)
		end
	end

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	for i, task in ipairs(tasks) do
		local extmark_id = extmarks.set(bufnr, i - 1, task, nil)
		ext_table[task.short_id] = extmark_id
	end

	return ext_table
end

M.setup = function(opts)
	log.debug('initialized task_buffer')
end

return M
