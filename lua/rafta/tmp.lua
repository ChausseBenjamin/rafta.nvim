local M = {}
local log = require 'rafta.util.log'

local dump_data = ''

local dump_path = vim.fn.expand('~/Workspace/plugins/rafta.nvim/mini.json')
local dump_file, err = io.open(dump_path, 'r')
if err then
	log.error('Failed to open test/dump data: ' .. err)
else
	dump_data = dump_file:read('a')
	dump_file:close()
end

-- Decode JSON data and store in M.dump
if dump_data ~= '' then
	local success, decoded = pcall(vim.json.decode, dump_data)
	if success then
		M.dump = decoded
		vim.print(decoded)
	else
		log.error('Failed to decode JSON data: ' .. decoded)
		M.dump = {}
	end
else
	M.dump = {}
end

return M
