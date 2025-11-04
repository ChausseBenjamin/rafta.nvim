local M = {}

---Recursively merge user options into defaults.
---@generic T
---@param defaults T Default configuration table
---@param opts T? User-provided configuration table
---@return T
M.populate_opts = function(defaults, opts)
	if type(opts) ~= 'table' then
		return defaults
	end

	for k, v in pairs(opts) do
		if v ~= nil then
			if type(v) == 'table' and type(defaults[k]) == 'table' then
				defaults[k] = M.populate_opts(defaults[k], v)
			else
				defaults[k] = v
			end
		end
	end

	return defaults
end

return M
