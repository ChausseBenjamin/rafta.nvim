local M = {}

local log = require 'lua.rafta.util.log'
local ui = require 'lua.rafta.view.ui'

---@class (exact) rafta.config
---@field logging rafta.log.config
---@field ui rafta.ui.config

---@param opts? rafta.config
M.setup = function(opts)
	opts = opts or {}
	log.setup(opts.logging)
	ui.setup(opts.ui)
end

return M
