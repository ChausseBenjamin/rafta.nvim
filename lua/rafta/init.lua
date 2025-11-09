local M = {}

local log = require 'rafta.util.log'
local view = require 'rafta.view'

---@class (exact) rafta.config
---@field logging rafta.log.config
---@field ui rafta.ui.config

---@param opts? rafta.config
M.setup = function(opts)
	opts = opts or {}
	log.setup(opts.logging)
	view.setup({
		ui = opts.ui
	})
end

return M
