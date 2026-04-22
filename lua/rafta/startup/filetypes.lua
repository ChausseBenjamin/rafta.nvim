local M = {}

local util = require 'rafta.util'

M.setup = function()
	vim.filetype.add({
		pattern = {
			['rafta:.*'] = 'Rafta'
		}
	})

	vim.treesitter.language.register("rafta", "Rafta")

	vim.api.nvim_create_autocmd("User", {
		pattern = "TSUpdate",
		callback = function()
			require("nvim-treesitter.parsers").rafta = {
				install_info = {
					path = util.plugin_root .. "/assets",
					generate = true,
					generate_from_json = false,
				},
			}
		end,
		once = true,
	})
end

return M
