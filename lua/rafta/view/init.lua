--- Handles spawning views (either in splits of floating windows
--- Also orchestrates orderly startup of sub-modules related to the view
local M = {}

local api = vim.api

local log = require 'rafta.util.log'
local extmarks = require 'rafta.view.extmarks'
local ui = require 'rafta.view.ui'
local tb = require 'rafta.view.task_buffer'

local namespace = 'rafta'
local namespace_id = api.nvim_create_namespace(namespace)

M.setup = function(opts)
	ui.setup(opts.ui)
	extmarks.setup(namespace_id)
	tb.setup({})
	log.debug('all view components initialized')

	-- For testing populate a buffer with all rafta tasks
	tb.view_all()
end


return M
