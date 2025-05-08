return {
	actions = {
		insert = function(date)
			return vim.api.nvim_put({ date:format("%Y-%m-%d") }, "c", true, true)
		end,
		echo = function(date)
			return vim.notify(date:format("%Y-%m-%d"), 2)
		end,
		open = function() end,
	},
	keys = {
		{
			"n",
			"q",
			function(self)
				self:close()
			end,
		},

		{
			"n",
			"<cr>",
			function(self)
				self:select()
			end,
		},
		{
			"n",
			">",
			function(self)
				self:forward()
			end,
		},
		{
			"n",
			"<",
			function(self)
				self:backward()
			end,
		},

		{
			"n",
			"h",
			function(self)
				self:cursor_left()
			end,
		},
		{
			"n",
			"l",
			function(self)
				self:cursor_right()
			end,
		},
		{
			"n",
			"j",
			function(self)
				self:cursor_down()
			end,
		},
		{
			"n",
			"k",
			function(self)
				self:cursor_up()
			end,
		},
	},
}
