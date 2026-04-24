--- Most of this setup is to minimize internet bandwith installing
--- dependencies despite the sandboxed environment. Makefile provides
--- data paths from the host to grab and load into the sandbox from there.
local joinpath = vim.fs.joinpath
local host_nvim_dir = vim.env.HOST_XDG_DATA_HOME
local deps = {
	plugins = {
		["plenary.nvim"] = {
			user = "nvim-lua",
		},
		["nvim-treesitter"] = {
			user = "nvim-treesitter",
		},
	},
	sources = {
		-- Preferred: vim.pack directory the host machine
		{ path = joinpath(host_nvim_dir, "nvim", "site", "pack", "core", "opt"), offline = true },
		-- Where the CI pipeline clones the dependencies
		{ path = joinpath(vim.uv.cwd(), ".."),                                   offline = true },
		-- Last resort: online
		{ path = "https://github.com",                                           offline = false },
	},
}

for name, spec in pairs(deps.plugins) do
	local installed = false
	for _, src in ipairs(deps.sources) do
		if installed then break end
		local full
		if src.offline then
			full = joinpath(src.path, name)
			if vim.fn.isdirectory(full) ~= 1 then
				goto continue
			end
		else
			full = table.concat({ src.path, spec.user, name }, "/")
			vim.notify('Fetching from online: ' .. full, vim.log.levels.WARN)
		end
		local success, err = pcall(function()
			vim.pack.add({
				{ src = full, name = name }
			}, { confirm = false })
		end)
		if success then
			installed = true
		else
			vim.print('Failed to install ' .. name .. ' from ' .. full .. ': ' .. (err or 'unknown error'))
		end
		::continue::
	end
end


vim.opt.runtimepath:append(".")
-- vim.opt.runtimepath:append("../plenary.nvim")

vim.cmd("runtime plugin/plenary.vim")
vim.cmd("runtime plugin/load_rafta.lua")
