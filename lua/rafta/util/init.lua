local M = {}

-- local function -> run once then cache the value
local function resolve_plugin_root()
	local source = debug.getinfo(2, "S").source:sub(2)
	-- NOTE: if this function/module moves, update hardcoded depth (`:h`)
	return vim.fn.fnamemodify(source, ":h:h:h:h")
end
M.plugin_root = resolve_plugin_root()

---Recursively merge user options into defaults.
---@generic T
---@param defaults T Default configuration table
---@param opts T? User-provided configuration table
---@return T
M.merge_opts = function(defaults, opts)
	if type(opts) ~= 'table' then
		return defaults
	end

	for k, v in pairs(opts) do
		if v ~= nil then
			if type(v) == 'table' and type(defaults[k]) == 'table' then
				defaults[k] = M.merge_opts(defaults[k], v)
			else
				defaults[k] = v
			end
		end
	end

	return defaults
end

return M
