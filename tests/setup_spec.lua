local util = require 'rafta.util'
local eq = assert.are_same

describe('util.populate_opts', function()
	it('should use defaults when nothing is given', function()
		local defaults = {
			foo = 1,
			bar = '2',
			baz = { 3, 4, 5 }
		}
		eq(util.populate_opts(defaults, nil), defaults)
		eq(util.populate_opts(defaults, {}), defaults)
	end)

	it('should only populate overriden fields', function()
		local edit = { bar = true }
		local defaults = {
			foo = 1,
			bar = '2',
			baz = { 3, 4, 5 }
		}
		local result = {
			foo = 1,
			bar = true,
			baz = { 3, 4, 5 }
		}
		eq(util.populate_opts(defaults, edit), result)
	end)

	it('should create missing/new fields', function()
		local edit = { boink = 42 }
		local defaults = {
			foo = 1,
			bar = '2',
			baz = { 3, 4, 5 }
		}
		local result = {
			foo = 1,
			bar = '2',
			baz = { 3, 4, 5 },
			boink = 42
		}
		eq(util.populate_opts(defaults, edit), result)
	end)
end)
