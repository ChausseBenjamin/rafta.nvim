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
		-- - { fg = '#rrggbb', bg = '#rrggbb' }
		-- - cterm_value(0-255)
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
				{ fg = '#c8938e', bg = nil },
				{ fg = '#b9a793', bg = nil },
				{ fg = '#a6ba99', bg = nil },
				{ fg = '#a1be9e', bg = nil },
				{ fg = '#9cc2a4', bg = nil },
				{ fg = '#9bc8b1', bg = nil },
				{ fg = '#99cebf', bg = nil },
				{ fg = '#a0d7b1', bg = nil },
				{ fg = '#a5e1a2', bg = nil },
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
	-- Create a local copy of defaults to avoid modifying the global defaults
	local config = vim.deepcopy(defaults)
	util.populate_opts(config, opts) -- <- overrides config in-place recursively

	M.icons = config.icons
	M.conceal = config.conceal
	M.colors = {
		state = {
			unspecified = M.gen_hlgroup(config.colors.state.unspecified, 'state.unspecified'),
			pending     = M.gen_hlgroup(config.colors.state.pending, 'state.pending'),
			ongoing     = M.gen_hlgroup(config.colors.state.ongoing, 'state.ongoing'),
			done        = M.gen_hlgroup(config.colors.state.done, 'state.done'),
			blocked     = M.gen_hlgroup(config.colors.state.blocked, 'state.blocked'),
		},
		info = {
			tags      = M.gen_hlgroup(config.colors.info.tags, 'info.tags'),
			planned   = M.gen_hlgroup(config.colors.info.planned, 'info.planned'),
			due       = M.gen_hlgroup(config.colors.info.due, 'info.due'),
			recurring = M.gen_hlgroup(config.colors.info.recurring, 'info.recurring'),
		},
		text = {
			no_priority = M.gen_hlgroup(config.colors.text.no_priority, 'text.no_priority'),
		},
		completed_override = M.gen_hlgroup(config.colors.completed_override, 'text.completed')
	}

	-- Metatable for priority
	local priority = config.colors.text.priority

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
		-- Extract user-provided priorities from the original opts
		local user_priorities = {}
		if opts and opts.colors and opts.colors.text and opts.colors.text.priority then
			for k, v in pairs(opts.colors.text.priority) do
				if type(k) == 'number' then
					user_priorities[k] = v
				end
			end
		end

		-- If no user priorities provided, use defaults
		if next(user_priorities) == nil then
			for k, v in pairs(config.colors.text.priority) do
				if type(k) == 'number' then
					user_priorities[k] = v
				end
			end
		end

		-- Sort user priorities to find nearest lower one efficiently
		local sorted_user_priorities = {}
		for k in pairs(user_priorities) do
			table.insert(sorted_user_priorities, k)
		end
		table.sort(sorted_user_priorities)

		-- Pre-create user-provided priority highlight groups
		local priority_table = {}
		for k, v in pairs(user_priorities) do
			priority_table[k] = M.gen_hlgroup(v, 'text.priority-' .. k)
			log.debug('Created priority hl group', { k = k, v = v, result = priority_table[k] })
		end

		M.colors.text.priority = setmetatable(priority_table, {
			__index = function(self, i)
				-- Cache check - if already computed, return it
				if rawget(self, i) then
					return rawget(self, i)
				end

				if i < 1 then
					self[i] = '@rafta.text.no_priority'
					return self[i]
				end

				-- Find the nearest lower user-provided priority
				local nearest_lower = nil
				for j = #sorted_user_priorities, 1, -1 do
					if sorted_user_priorities[j] < i then
						nearest_lower = sorted_user_priorities[j]
						break
					end
				end

				if nearest_lower then
					-- Get the content of the nearest lower user-provided priority
					local target_hl_name = '@rafta.text.priority-' .. nearest_lower
					local target_content = api.nvim_get_hl(0, { name = target_hl_name })

					-- If the target is a link, preserve the link structure
					if target_content.link then
						self[i] = M.gen_hlgroup({ link = target_content.link }, 'text.priority-' .. i)
					else
						-- Create a new hl group with the same content (not a link)
						self[i] = M.gen_hlgroup(target_content, 'text.priority-' .. i)
					end
				else
					-- No lower user priority found, link to no_priority
					self[i] = M.gen_hlgroup({ link = M.colors.text.no_priority }, 'text.priority-' .. i)
				end

				return self[i]
			end
		})
	end

	log.debug('initialized UI preferences')
end


return M
