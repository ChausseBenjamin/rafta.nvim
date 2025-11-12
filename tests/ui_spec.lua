local api = vim.api
local eq = assert.are_same
local ui = require 'rafta.view.ui'

describe('rafta.view.ui', function()
	it('should generate hl-groups for all supported color formats', function()
		local cases = {
			linked_group = {
				input = 'Comment',
				expected = {
					name = '@rafta.linked_group',
					contents = { link = 'Comment' },
				}
			},
			custom_color = {
				input = { bg = '#222d32', fg = '#b7416e' },
				expected = {
					name = '@rafta.custom_color',
					contents = { bg = 2239794, fg = 12009838 },
				}
			},
			cterm_value = {
				input = 123,
				expected = {
					name = '@rafta.cterm_value',
					contents = { ctermfg = 123 },
				}
			},
		}
		for name, scenario in pairs(cases) do
			ui.gen_hlgroup(scenario.input, name)
			local result = api.nvim_get_hl(0, {
				name = scenario.expected.name
			})
			eq(scenario.expected.contents, result,
				'failed to parse a' .. name .. 'upon receiving: ' .. vim.inspect(scenario.input)
			)
		end
	end)

	it('should interpolate hl-groups from incomplete priority list', function()
		local input = function(n)
			if n <= 4 then
				return { fg = '#bada55', bg = '#222d32' }
			elseif n <= 9 then
				return 42
			else
				return 'Comment'
			end
		end
		local opts = { colors = { text = { priority = input } } }
		ui.setup(opts)

		local expectations = {
			range_1_4 = {
				indexes = { 1, 2, 3, 4 },
				contents = { fg = 12245589, bg = 2239794 },
			},
			range_5_9 = {
				indexes = { 5, 6, 7, 8, 9 },
				contents = { ctermfg = 42 },
			},
			range_10_plus = {
				indexes = { 10, 11, 12, 13, 14 },
				contents = { link = 'Comment' },
			}
		}
		for k, v in pairs(expectations) do
			for _, i in ipairs(v.indexes) do
				local result = api.nvim_get_hl(0, { name = ui.colors.text.priority[i] })
				eq(v.contents, result,
					'Test expects the following for ' .. k .. ': ' .. vim.inspect(v.contents)
				)
			end
		end
	end)

	it('should generate hl-groups from a priority function', function()
		local input = function(n)
			if n % 2 == 0 then
				return 69
			else
				return 'Comment'
			end
		end
		local opts = { colors = { text = { priority = input } } }
		ui.setup(opts)

		local expectations = {
			uneven = {
				indexes = { 1, 3, 5, 7, 9, 11, 13 },
				contents = { link = 'Comment' },
			},
			even = {
				indexes = { 2, 4, 6, 8, 10, 12, 14 },
				contents = { ctermfg = 69 },
			}
		}
		for k, v in pairs(expectations) do
			for _, i in ipairs(v.indexes) do
				local result = api.nvim_get_hl(0, { name = ui.colors.text.priority[i] })
				eq(v.contents, result,
					'Test expects the following for an ' .. k .. 'priority: ' .. vim.inspect(v.contents)
				)
			end
		end
	end)
end)
