-- Currently, nothing related to the model or the bridge are implemented
-- This file load test data the same way grpcurl on all tasks would get you.
-- This way I can start prototyping the UX before even implementing the bridge.

local M = {}

local log = require 'rafta.util.log'

-- Read dump data
local dump_data = ''
local dump_path = vim.fn.expand('~/Workspace/plugins/rafta.nvim/mini.json')
local dump_file, err = io.open(dump_path, 'r')
if err then
	log.error('Failed to open test/dump data: ' .. err)
elseif dump_file then
	dump_data = dump_file:read('a')
	dump_file:close()
end

-- Decode JSON and assign short_id
if dump_data ~= '' then
	local success, decoded = pcall(vim.json.decode, dump_data)
	if success then
		if decoded.tasks then
			for i, task in ipairs(decoded.tasks) do
				-- Short ids serve two purposes:
				-- 1. UUID are too long when they show (are not concealed)
				-- 2. Tasks created offline don't have an id provided by the server
				--    Since short_ids are client-side, modifications to offline tasks
				--    can still be tracked until a connection is established
				task.short_id = i - 1
			end
		end
		M.dump = decoded
	else
		log.error('Failed to decode JSON data: ' .. decoded)
		M.dump = {}
	end
else
	M.dump = {}
end

return M
