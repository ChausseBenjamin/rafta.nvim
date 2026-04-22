local M = {}

local log = require 'rafta.util.log'
local startup = require 'rafta.startup'

---@class (exact) rafta.config
---@field logging rafta.log.config

---@param opts? rafta.config
M.setup = function(opts)
	opts = opts or {}
	log.setup(opts.logging)
	startup.setup()
end

return M
