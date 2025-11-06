local M = {}
local log = require 'rafta.util.log'
local util = require 'rafta.util'

---@class (exact) rafta.ui.config.icons.state
---@field unspecified? string|'nil' # using nil will disable concealed text and show raw text
---@field pending? string
---@field ongoing? string
---@field done? string
---@field blocked? string

---@class (exact) rafta.ui.config.icons.info
---@field tags? string|'nil' # using nil will disable showing altogether
---@field planned? string
---@field due? string
---@field recurring? string

---@class (exact) rafta.ui.config.icons
---@field state? rafta.ui.config.icons.state
---@field info? rafta.ui.config.icons.info

---@alias RaftaColor 'Normal' | string | { fg: string, bg?: string, gui?: string } | integer | fun(n: integer): any

---@class (exact) rafta.ui.config.colors.info
---@field tags? RaftaColor
---@field planned? RaftaColor
---@field due? RaftaColor
---@field recurring? RaftaColor

---@class (exact) rafta.ui.config.colors
---@field state? RaftaColor
---@field no_priority? RaftaColor
---@field info? rafta.ui.config.colors.info
---@field priority? RaftaColor[] # array indexed by priority number

---@class (exact) rafta.ui.config
---@field icons? rafta.ui.config.icons
---@field colors? rafta.ui.config.colors

---@type rafta.ui.config
M.opts = {
	icons = {
		state = {
			-- using nil will disable concealed text and show raw text
			unspecified = '󱗽', -- '?'
			pending     = '', -- '.'
			ongoing     = '', -- '~'
			done        = '', -- 'x'
			blocked     = '󱋯', -- '!'
		},
		info  = {
			-- using nil for will disable showing altogether
			tags      = '󰓹',
			planned   = '󰥕',
			due       = '',
			recurring = '',
		},
	},
	colors = {
		-- single colors can be one of:
		-- - 'highlight_group_name'
		-- - { fg = '#rrggbb'
		-- - cterm_value(0-255)
		-- - 'color_name(red)', bg= '#rrggbb', gui='style' }
		state = 'Normal',
		no_priority = 'Normal',
		info = {
			tags      = '@attribute',
			planned   = '@comment.todo',
			due       = '@keyword',
			recurring = '@constant.builtin',
		},
		-- priority can also be
		-- `function(n) -> one of the accepted types`
		-- where n is the priority for which you want the returned color
		priority = {
			'@comment.error',  -- 1
			'@comment.warning', -- 2
			'@comment.note',   -- 3
			'@character.special', -- ...
		},
	}
}

---@param opts rafta.ui.config
M.setup = function(opts)
	util.populate_opts(M.opts, opts)
	log.debug('Initialized UI preferences')
end


return M
