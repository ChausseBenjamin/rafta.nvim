local M = {}

local log = require('rafta.util.log')

---@class (exact) rafta.config
---@field logging rafta.log.config

---@param opts? rafta.config
M.setup = function(opts)
	opts = opts or {}
	log.setup(opts.logging)
end

return M
