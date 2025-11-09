local M = {}
local cfg = require('rafta.util')

M.session_id = string.format("%04x", os.time() % 0xFFFF)

---@alias formatter fun(lvl: string, msg: string, xtras?: table<string, any>): string
---@alias logfunc fun(msg: string, xtras?: table<string, any>)

-- Reverse mapping from log-level (int) to names (string)
-- (over-engineered for learning purposes)
M._level_to_name = setmetatable({}, {
	__index = function(self, key)
		for name, num in pairs(vim.log.levels) do
			self[num] = name
			if num == key then
				return name
			end
		end
		-- fallback if key wasn't found
		self[key] = tostring(key)
		return self[key]
	end
})


---@class (exact) rafta.log.config
---@field path? string
---@field level? number
---@field formatter? formatter

---Log a message at the specified level.
---This is kep local/private to force the use of known log levels through other
---methods
---@param lvl number
---@param msg string
---@param xtras? table<string, any>
local log = function(lvl, msg, xtras)
	xtras = xtras or {}
	xtras.session_id = M.session_id
	if lvl < M.cfg.level then
		return
	end

	local lvl_str = M._level_to_name[lvl] or tostring(lvl)
	local formatted_msg

	local log_file = M.cfg.path and io.open(vim.fn.expand(M.cfg.path), 'a')

	if log_file then
		formatted_msg = M.cfg.formatter(lvl_str, msg, xtras)
		log_file:write(formatted_msg .. '\n')
		log_file:close()
		return
	elseif M.cfg.formatter == M.formatters.plain then
		-- By default, it's useful to know which plugins is notifying
		-- even if it's not the exact plain format
		formatted_msg = '(Rafta) ' .. M.formatters.plain(lvl_str, msg, xtras)
	else
		formatted_msg = M.cfg.formatter(lvl_str, msg, xtras)
	end
	vim.notify(formatted_msg, lvl)
end

---@type table<string, formatter>
M.formatters = {
	json = function(lvl, msg, xtras)
		local timestamp = os.date('%Y-%m-%d %H:%M:%S')
		local log_entry = {
			timestamp = timestamp,
			level = lvl,
			message = msg,
		}
		if xtras then
			for k, v in pairs(xtras) do
				log_entry[k] = v
			end
		end
		local ok, encoded = pcall(vim.json.encode, log_entry)
		if ok then
			return encoded
		else
			-- fallback: hardcoded json without the xtras
			return string.format(
				'{"timestamp":"%s", "level":"%s", "message":"%s"}',
				timestamp, lvl, msg
			)
		end
	end,
	plain = function(lvl, msg, xtras)
		local timestamp = os.date('%Y-%m-%d %H:%M:%S')
		local formatted_msg = string.format('[%s] %s: %s', timestamp, lvl, msg)
		if xtras then
			for k, v in pairs(xtras) do
				formatted_msg = formatted_msg .. string.format(' %s=%s', k, tostring(v))
			end
		end
		return formatted_msg
	end,
}

---@type rafta.log.config
M.cfg = {
	level = vim.log.levels.INFO,
	path = '~/.cache/nvim/rafta.nvim.log',
	formatter = M.formatters.plain,
}

---@type logfunc
M.trace = function(msg, xtras)
	log(vim.log.levels.TRACE, msg, xtras)
end
---@type logfunc
M.debug = function(msg, xtras)
	log(vim.log.levels.DEBUG, msg, xtras)
end
---@type logfunc
M.info = function(msg, xtras)
	log(vim.log.levels.INFO, msg, xtras)
end
---@type logfunc
M.warn = function(msg, xtras)
	log(vim.log.levels.WARN, msg, xtras)
end
---@type logfunc
M.error = function(msg, xtras)
	log(vim.log.levels.ERROR, msg, xtras)
end

---@param opts rafta.log.config Configuration requirements
M.setup = function(opts)
	M.cfg = cfg.populate_opts(M.cfg, opts)
	M.debug('logging initialized')
end

return M
