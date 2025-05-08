--- Big view

vim.keymap.set("n", "<leader>id", function()
	local cal = M.new({}, config.actions.insert)
	cal:open()
end)
