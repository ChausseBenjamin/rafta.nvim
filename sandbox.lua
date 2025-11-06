-- vim.api.nvim_buf_delete(My_Buf, { force = true })
-- vim.print(vim.api.nvim_create_buf(true, false))

My_Buf = 29
vim.api.nvim_buf_set_lines(My_Buf, 0, -1, false, {
	tostring(math.random()),
	"󱗽 hello",
	" there",
	" general",
	" Kenobi",
	'󱋯 ' .. tostring(os.date('%Y-%m-%d %H:%M:%S'))
})

-- 󱍵 󰫌
-- 󰥕
-- 
-- 

-- vim.print(vim.api.nvim_create_namespace('ben_test'))
-- ns_id: 211

vim.api.nvim_buf_set_extmark(
--buf, ns_id, line, col
	My_Buf, 211, 4, 0, {
		id = 3,
		virt_text = {
			{ '󰓹 3 ', '@attribute' },
			{ '󰥕 ', '@comment.todo' },
			{ ' ', '@keyword' },
			{ ' ', '@constant.builtin' },
		},
		virt_text_pos = "eol_right_align",
	})

-- vim.print(My_Buf)
