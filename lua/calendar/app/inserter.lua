--- Cursor view

vim.keymap.set("i", "@", function()
	api.nvim_put({ "@" }, "c", true, true)
	-- vim.cmd.stopinsert()
	local cal = M.new({
		relative = "cursor",
		row = 1,
		col = 0,
	}, config.actions.insert)
	-- cal:open()
end)
