local Date = require("orgmode.objects.date")

local M = {
	win = nil,
	buf = nil,
	namespace = vim.api.nvim_create_namespace("calendar"),
	select_state = 0,
	date = Date.today(),
}

M.__index = M

local config = {
	actions = {
		insert_link = function(date)
			return date and vim.api.nvim_put({ date:format("%Y-%m-%d") }, "c", true, true)
		end,
		open_daily = function() end,
		echo_date = function(date)
			return date and vim.notify(date:format("%Y-%m-%d"), 2)
		end,
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
	},
}

local width = 36
local height = 14
local x_offset = 1 -- one border cell
local y_offset = 2 -- one border cell and one padding cell

function M.open(self, callback, opts)
	local get_window_opts = function()
		return {
			relative = "editor",
			width = width,
			height = height,
			style = "minimal",
			border = "double",
			row = opts.row,
			-- or vim.o.lines / 2 - (y_offset + height) / 2,
			col = opts.col,
			-- or vim.o.columns / 2 - (x_offset + width) / 2,
			title = self.title or "Calendar",
			title_pos = "center",
		}
	end

	self.prev_win = vim.api.nvim_get_current_win()
	self.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(self.buf, "orgcalendar")
	self.win = vim.api.nvim_open_win(self.buf, true, get_window_opts())

	vim.bo[self.buf].filetype = "calendar"

	local calendar_augroup = vim.api.nvim_create_augroup("calendar.nvim", { clear = true })

	-- vim.api.nvim_create_autocmd("BufWipeout", {
	-- 	buffer = self.buf,
	-- 	group = calendar_augroup,
	-- 	callback = function()
	-- 		self:close()
	-- 	end,
	-- 	once = true,
	-- })

	-- vim.api.nvim_create_autocmd("VimResized", {
	-- 	buffer = self.buf,
	-- 	group = calendar_augroup,
	-- 	callback = function()
	-- 		if self.win then
	-- 			vim.api.nvim_win_set_config(self.win, get_window_opts())
	-- 		end
	-- 	end,
	-- })
	--
	self:render()

	for _, map in ipairs(config.keys) do
		local mode, lhs, rhs = unpack(map)
		self:map(mode, lhs, rhs)
	end

	-- if self.clearable then
	-- 	vim.keymap.set("n", "r", function()
	-- 		return self:clear_date()
	-- 	end, map_opts)
	-- end
	-- vim.keymap.set("n", "t", function()
	-- 	self:set_time()
	-- end, map_opts)
	-- if self:has_time() then
	-- 	vim.keymap.set("n", "T", function()
	-- 		self:clear_time()
	-- 	end, map_opts)
	-- end
	-- self:jump_day()
	self.callback = callback or config.actions.echo_date
end

function M:map(mode, lhs, rhs)
	local map_opts = { buffer = self.buf, silent = true, nowait = true }
	vim.keymap.set(mode, lhs, function()
		rhs(self)
	end, map_opts)
end

function M:close()
	vim.api.nvim_buf_delete(self.buf, { force = true })
	self.win = nil
	self.buf = nil
	if self.callback then
		self.callback(nil)
		vim.api.nvim_set_current_win(self.prev_win)
		self.callback = nil
	end
end

function M.left_pad(time_part)
	return time_part < 10 and "0" .. time_part or time_part
end

function M:render_time()
	local l_pad = "               "
	local r_pad = "              "
	local hour_str = self:has_time() and M.left_pad(self.date.hour) or "--"
	local min_str = self:has_time() and M.left_pad(self.date.min) or "--"
	return l_pad .. hour_str .. ":" .. min_str .. r_pad
end

function M:has_time()
	return not self.date.date_only
end

local SelState = { DAY = 0, HOUR = 1, MIN_BIG = 2, MIN_SMALL = 3 }

---@return OrgDate?
function M:get_selected_date()
	if self.select_state ~= SelState.DAY then
		return self.date
	end
	local col = vim.fn.col(".")
	local char = vim.fn.getline("."):sub(col, col)
	local day = tonumber(vim.trim(vim.fn.expand("<cword>")))
	local line = vim.fn.line(".")
	vim.cmd([[redraw!]])
	if line < 3 or not char:match("%d") then
		-- return utils.echo_warning("Please select valid day number.", nil, false)
	end
	return self.date:set({
		day = day,
		date_only = self.date.date_only,
	})
end

function M:select()
	local selected_date
	if self.select_state == SelState.DAY then
		selected_date = self:get_selected_date()
	else
		selected_date = self.date:set({
			day = self.date.day,
			hour = self.date.hour,
			min = self.date.min,
			date_only = false,
		})
		self.select_state = SelState.DAY
	end
	local cb = self.callback
	self.callback = nil

	vim.cmd([[echon]])
	vim.api.nvim_win_close(0, true)
	vim.api.nvim_set_current_win(self.prev_win)
	return cb(selected_date)
end

---@private
function M:_ensure_day()
	if self.select_state ~= SelState.DAY then
		self:set_day()
	end
end

function M:forward()
	self:_ensure_day()
	self.date = self.date:set({ day = 1 }):add({ month = vim.v.count1 })
	self:render()
	vim.fn.cursor(2, 1)
	vim.fn.search("01")
	self:render()
end

function M:backward()
	self:_ensure_day()
	self.date = self.date:set({ day = 1 }):subtract({ month = vim.v.count1 }):last_day_of_month()
	self:render()
	vim.fn.cursor(8, 0)
	vim.fn.search([[\d\d]], "b")
	self:render()
end

function M:render()
	vim.bo[self.buf].modifiable = true

	local cal_rows = { {}, {}, {}, {}, {}, {} } -- the calendar rows
	local start_from_sunday = true
	-- local start_from_sunday = config.calendar_week_start_day == 0

	local weekday_row = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }

	if start_from_sunday then
		weekday_row = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
	end

	-- construct title (Month YYYY)
	local title = self.date:format("%B %Y")
	title = string.rep(" ", math.floor((width - title:len()) / 2)) .. title

	-- insert whitespace before first day of month
	local first_of_month = self.date:start_of("month")

	local end_of_month = self.date:end_of("month")
	local start_weekday = first_of_month:get_isoweekday()
	if start_from_sunday then
		start_weekday = first_of_month:get_weekday()
	end

	while start_weekday > 1 do
		table.insert(cal_rows[1], "  ")
		start_weekday = start_weekday - 1
	end

	-- insert dates into cal_rows
	local dates = first_of_month:get_range_until(end_of_month)
	local current_row = 1
	for _, day in ipairs(dates) do
		table.insert(cal_rows[current_row], day:format("%d"))
		if #cal_rows[current_row] % 7 == 0 then
			current_row = current_row + 1
		end
	end

	-- add spacing between the calendar cells
	local content = vim.tbl_map(function(item)
		return " " .. table.concat(item, "   ") .. " "
	end, cal_rows)

	-- put it all together
	table.insert(content, 1, " " .. table.concat(weekday_row, "  "))
	table.insert(content, 1, title)

	table.insert(content, self:render_time())
	table.insert(content, "")

	-- TODO: redundant, since it's static data
	table.insert(content, " [<] - prev month  [>] - next month")
	table.insert(content, " [.] - today   [Enter] - select day")
	if self.clearable then
		table.insert(content, " [i] - enter date  [r] - clear date")
	else
		table.insert(content, " [i] - enter date")
	end

	if self:has_time() or self.select_state ~= SelState.DAY then
		if self.select_state == SelState.DAY then
			table.insert(content, " [t] - enter time  [T] - clear time")
		else
			table.insert(content, " [d] - select day  [T] - clear time")
		end
	else
		table.insert(content, " [t] - enter time")
	end

	vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, content)
	vim.api.nvim_buf_clear_namespace(self.buf, M.namespace, 0, -1)

	vim.bo[self.buf].modifiable = false
end

function M:hl()
	-- if self.clearable then
	-- 	local range = Range:new({
	-- 		start_line = #content - 2,
	-- 		start_col = 0,
	-- 		end_line = #content - 2,
	-- 		end_col = 1,
	-- 	})
	-- 	colors.highlight({
	-- 		range = range,
	-- 		hlgroup = "Comment",
	-- 	}, self.buf)
	-- 	self:_apply_hl("Comment", #content - 3, 0, -1)
	-- end
	--
	-- if not self:has_time() then
	-- 	self:_apply_hl("Comment", 8, 0, -1)
	-- end
	--
	-- self:_apply_hl("Comment", #content - 4, 0, -1)
	-- self:_apply_hl("Comment", #content - 3, 0, -1)
	-- self:_apply_hl("Comment", #content - 2, 0, -1)
	-- self:_apply_hl("Comment", #content - 1, 0, -1)
	--
	-- for i, line in ipairs(content) do
	-- 	local from = 0
	-- 	local to, num
	--
	-- 	while true do
	-- 		from, to, num = line:find("%s(%d%d?)%s", from + 1)
	-- 		if from == nil then
	-- 			break
	-- 		end
	-- 		if from and to then
	-- 			local day = self.date:set({ day = num })
	-- 			self:on_render_day(day, {
	-- 				from = from,
	-- 				to = to,
	-- 				line = i,
	-- 			})
	-- 		end
	-- 	end
	-- end
	--
end

vim.keymap.set("n", "<Plug>ClendarOpen", function()
	M:open()
end)

vim.keymap.set("n", "<leader>id", function()
	M:open(config.actions.insert_link)
end)

vim.keymap.set("i", "@", function()
	local pos = vim.api.nvim_win_get_cursor(0)
	M:open(config.actions.insert_link, {
		row = pos[1] + 5,
		col = pos[2],
	})
end)
