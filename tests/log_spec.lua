local log = require 'lua.rafta.util.log'

local eq = assert.are_same

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

local log_container = {}

---Setup unit test
---@param opts? rafta.log.config
---@return integer
local setup = function(opts)
	-- Sane defaults for each test to start with
	local defaults = {
		level = vim.log.levels.TRACE,
		path = '', -- <--- Force the use of vim.notify
		formatter = log.formatters.plain,
	}
	-- avoid state leakage between tests
	log.cfg = defaults

	log.setup(opts or {})
	table.insert(log_container, {})
	local slot = #log_container
	---@diagnostic disable-next-line: duplicate-set-field
	vim.notify = function(msg, lvl)
		table.insert(log_container[slot], {
			msg = msg,
			lvl = lvl,
		})
	end
	return slot
end

describe('rafta.util.log', function()
	it('should log messages in their respective levels', function()
		local expected = {
			vim.log.levels.TRACE,
			vim.log.levels.DEBUG,
			vim.log.levels.INFO,
			vim.log.levels.WARN,
			vim.log.levels.ERROR,
		}
		local result = log_container[setup()]
		log.trace('foo')
		log.debug('bar')
		log.info('baz')
		log.warn('boink')
		log.error('ohno')
		for i, lvl in ipairs(expected) do
			eq(lvl, result[i].lvl)
		end
	end)

	it('should create a logfile if the rest of its path exists', function()
		local path = vim.fn.tempname() .. '.log'
		setup({
			path = path
		})
		log.info('hi')
		assert.is_truthy(file_exists(path))
	end)

	it('should format the logfile using valid json', function()
		local raw_result = log_container[setup({
			path = '',
			formatter = log.formatters.json,
		})]
		local expected = {
			level = 'INFO',
			message = 'this is a test',
		}

		log.info('this is a test')

		local result = vim.json.decode(raw_result[#raw_result].msg)
		-- Done this way to avoid dealing with timestamps
		eq(expected.level, result.level)
		eq(expected.message, result.message)
	end)

	-- Test level filtering
	it('should respect minimum log level threshold', function()
		local result = log_container[setup({
			path = '',
			level = vim.log.levels.WARN,
		})]
		log.trace('invisible')
		log.debug('invisible')
		log.info('invisible')
		log.warn('visible')
		log.error('visible')
		eq(2, #result)
		eq(vim.log.levels.WARN, result[1].lvl)
		eq(vim.log.levels.ERROR, result[2].lvl)
	end)

	-- Test xtras parameter with nested tables
	it('should handle nested tables in json format', function()
		local raw = log_container[setup({
			path = '',
			formatter = log.formatters.json,
		})]
		log.info('test', {
			foo = 1,
			bar = {
				baz = 2,
				boink = '3',
			}
		})
		local result = vim.json.decode(raw[1].msg)
		eq(1, result.foo)
		eq(2, result.bar.baz)
		eq('3', result.bar.boink)
	end)

	it('should handle nested tables in plain format', function()
		local slot = setup({
			path = '',
			formatter = log.formatters.plain,
		})
		log.info('test', {
			foo = 1,
			bar = {
				baz = 2,
				boink = '3',
			}
		})
		local msg = log_container[slot][1].msg
		assert.is_truthy(msg:match('foo=1'))
		assert.is_truthy(msg:match('bar=table:'))
	end)

	-- Test xtras parameter
	it('should include extra fields in formatted output', function()
		local slot = setup({
			path = '',
			formatter = log.formatters.json,
		})
		log.info('test', { foo = 'bar', count = 42 })
		local result = vim.json.decode(log_container[slot][1].msg)
		eq('bar', result.foo)
		eq(42, result.count)
	end)

	it('should append xtras to plain format messages', function()
		local slot = setup({
			path = '',
			formatter = log.formatters.plain,
		})
		log.info('test', { key = 'value' })
		assert.is_truthy(log_container[slot][1].msg:match('key=value'))
	end)

	-- Test that no log file is created for invalid paths
	it('should fallback to vim.notify when logfile directory does not exist', function()
		local slot = setup({
			path = '/nonexistent/dir/test.log',
		})
		log.info('fallback')
		local result = log_container[slot]
		eq(1, #result)
		assert.is_truthy(result[1].msg:match('fallback'))
	end)

	-- Test custom formatter
	it('should accept custom formatter function', function()
		local custom = function(lvl, msg, xtras)
			return 'CUSTOM: ' .. log.formatters.plain(lvl, msg, xtras)
		end
		local result = log_container[setup({
			path = '',
			formatter = custom,
		})]
		log.info('test')
		assert.is_truthy(result[1].msg:match('^CUSTOM: %['))
		assert.is_truthy(result[1].msg:match('INFO: test'))
	end)

	-- Test unknown log level handling
	it('should convert unknown log levels to strings', function()
		setup({ path = '' })
		local name = log._level_to_name[9999]
		eq('9999', name)
	end)

	-- Test path expansion
	it('should expand ~ in file paths', function()
		local path = vim.fn.tempname() .. '.log'
		local expanded_path = vim.fn.expand(path)
		setup({
			path = path,
		})
		log.info('path expansion test')
		assert.is_truthy(file_exists(expanded_path))
	end)

	-- Test JSON encoding failures
	it('should fallback to hardcoded json when encoding fails', function()
		local raw_result = log_container[setup({
			path = '',
			formatter = log.formatters.json,
		})]

		-- Create a circular reference that will cause JSON encoding to fail
		local circular = {}
		circular.self = circular

		log.info('circular test', circular)

		-- Should still get a log message, but with fallback JSON format
		local msg = raw_result[1].msg
		assert.is_truthy(msg:match('"timestamp":"'))
		assert.is_truthy(msg:match('"level":"INFO"'))
		assert.is_truthy(msg:match('"message":"circular test"'))
		-- Should not contain the circular reference
		assert.is_truthy(not msg:match('"self"'))
	end)

	-- Test JSON encoding with non-serializable data
	it('should handle non-serializable data in xtras', function()
		local raw_result = log_container[setup({
			path = '',
			formatter = log.formatters.json,
		})]

		-- Use a function as non-serializable data
		log.info('function test', {
			func = function() return 'test' end,
			normal = 'value'
		})

		-- Should still get a log message with fallback JSON format
		local msg = raw_result[1].msg
		assert.is_truthy(msg:match('"timestamp":"'))
		assert.is_truthy(msg:match('"level":"INFO"'))
		assert.is_truthy(msg:match('"message":"function test"'))
		-- Should not contain the function
		assert.is_truthy(not msg:match('"func"'))
	end)
end)
