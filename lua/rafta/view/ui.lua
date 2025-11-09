local M = {}
local api = vim.api

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

---@alias RaftaColor 'Normal' | string | { fg: string, bg?: string, gui?: string } | integer

---@class rafta.ui.config.conceal
---@field short_id boolean
---@field priority boolean

---@class (exact) rafta.ui.config.colors.info
---@field tags? RaftaColor
---@field planned? RaftaColor
---@field due? RaftaColor
---@field recurring? RaftaColor

---@class (exact) rafta.ui.config.colors
---@field state? RaftaColor
---@field text? rafta.ui.config.colors.text
---@field info? rafta.ui.config.colors.info
---@field completed_override? RaftaColor

---@class (exact) rafta.ui.config.colors.text
---@field no_priority? RaftaColor
---@field priority? RaftaColor[] | { [number]: function } # array indexed by priority number or function

---@class (exact) rafta.ui.config
---@field conceal? rafta.ui.config.conceal
---@field icons? rafta.ui.config.icons
---@field colors? rafta.ui.config.colors

---@type rafta.ui.config
local defaults = {
	conceal = {
		short_id = true, -- Hides the id used for tasks internally (different from the server)
		priority = false, -- Hides priority to rely solely on syntax coloring
	},
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
		state = { -- applies color/formatting only to the icon (nil will folow text color)
			unspecified = 'Normal',
			pending     = 'Normal',
			ongoing     = 'Normal',
			done        = 'Normal',
			blocked     = 'Normal',
		},
		text = { -- includes priority and title text
			no_priority = 'Normal',
			priority    = {
				'@comment.error', -- 1
				'@comment.warning', -- 2
				'@comment.note',  -- 3
				'@character.special', -- ...
			},
		},
		info = {
			tags      = '@attribute',
			planned   = '@comment.todo',
			due       = '@keyword',
			recurring = '@constant.builtin',
		},
		-- completed tasks will use this as a theme linking to their current
		-- text setting for unset parameters.
		-- - `{ strikethrough = true }` would preserve the color but strike the  title
		-- - `{ link = 'Comment' }` wouldn't strike the task title but gray it out
		-- - `{}` would keep completed tasks identical to incomplete ones
		completed_override = { strikethrough = true, link = 'Comment' },
	}
}

---Generates a highlight group from a user provided color specification
---to ensure components calling the ui don't have 4 differents formats to deal
---with but always receives a properly generated higroup.
---@param input RaftaColor
---@param name string
M.gen_hlgroup = function(input, name)
	local hl_name = '@rafta.' .. name
	if type(input) == 'string' and vim.fn.hlexists(input) == 1 then
		log.debug('found valid hl group to link against', { contents = input, target = hl_name })
		api.nvim_set_hl(0, hl_name, { link = input })
	elseif type(input) == 'table' then
		log.debug('creating custom hl group from table', { contents = input, target = hl_name })
		api.nvim_set_hl(0, hl_name, input)
	elseif type(input) == 'number' then
		log.debug('creating custom hl group with ctermfg', { contents = input, target = hl_name })
		api.nvim_set_hl(0, hl_name, { ctermfg = input })
	else
		log.error('unable to generate hl_group from input, reverting to Normal', {
			contents = vim.inspect(input),
			target = hl_name,
		})
		api.nvim_set_hl(0, hl_name, { link = 'Normal' })
	end
	return hl_name
end


---@param opts rafta.ui.config
---@param ns_id integer
M.setup = function(opts)
	-- TODO: opts should be a local defaults variable
	-- The opts in the plugin should always be HiGroups owned by rafta
	-- (with links if necessary). This would ensure plugins calling the UI lib are
	-- garanteed to get HiGroups and don't have to parse stuff like fb/bg, cterm,
	-- etc...
	-- If a user provides a function for priority highlighting, this is what
	-- should be done:
	-- - If a function is provided, write an index-function metatable that
	--   creates and caches a newly created higroup at that index using the user
	--   provided function for generation
	-- - If a list of colors is given, the metatable-function should populate the
	--   list by going upwards in priority until a non-nil higroup is encountered.
	--   This way, if a user only sets colors for priority 1, 5, and 10, the
	--   metatable will set priority 1-4, 5-9, 10-infinity to their respective
	--   higroups.
	util.populate_opts(defaults, opts) -- <- overrides defaults in-place recursively

	M.icons = defaults.icons
	M.conceal = defaults.conceal
	M.colors = {
		state = {
			unspecified = M.gen_hlgroup(defaults.colors.state.unspecified, 'state.unspecified'),
			pending     = M.gen_hlgroup(defaults.colors.state.pending, 'state.pending'),
			ongoing     = M.gen_hlgroup(defaults.colors.state.ongoing, 'state.ongoing'),
			done        = M.gen_hlgroup(defaults.colors.state.done, 'state.done'),
			blocked     = M.gen_hlgroup(defaults.colors.state.blocked, 'state.blocked'),
		},
		info = {
			tags      = M.gen_hlgroup(defaults.colors.info.tags, 'info.tags'),
			planned   = M.gen_hlgroup(defaults.colors.info.planned, 'info.planned'),
			due       = M.gen_hlgroup(defaults.colors.info.due, 'info.due'),
			recurring = M.gen_hlgroup(defaults.colors.info.recurring, 'info.recurring'),
		},
		text = {
			no_priority = M.gen_hlgroup(defaults.colors.text.no_priority, 'text.no_priority'),
		}
	}

	-- Metatable for priority
	local priority = defaults.colors.text.priority

	if type(priority) ~= "table" and type(priority) ~= "function" then
		log.warn('invalid color configuration for priority, using fallback', {
			received_data = vim.inspect(priority)
		})
		priority = {
			M.gen_hlgroup({ link = M.colors.text.no_priority }, 'text.priority-1')
		}
	end

	if type(priority) == "function" then
		M.colors.text.priority = setmetatable({}, {
			__index = function(self, i)
				local user_result = priority(i)
				if not user_result then return nil end
				self[i] = M.gen_hlgroup(user_result, 'text.priority-' .. i)
				return self[i]
			end
		})
	else -- (can only happen when priority is a list)
		M.colors.text.priority = setmetatable({}, {
			__index = function(self, i)
				if i < 1 then
					self[i] = '@rafta.text.no_priority'
					return self[i]
				end

				local config = priority[i] ---@diagnostic disable-line
				if config then
					---@diagnostic disable-next-line: param-type-mismatch
					self[i] = M.gen_hlgroup(config, 'text.priority-' .. i)
					return self[i]
				end

				local prev = self[i - 1] or M.colors.text.no_priority
				self[i] = M.gen_hlgroup({ link = prev }, 'text.priority-' .. i)
				return self[i]
			end
		})
	end

	log.debug('initialized UI preferences')
end


return M
