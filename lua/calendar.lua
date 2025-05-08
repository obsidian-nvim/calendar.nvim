-- Adapted from nvim-orgmode/orgmode
local Date = require("calendar.date")
local config = require("calendar.config")
local api, fn = vim.api, vim.fn

local M = {}

M.__index = M

---@param opts table
local function new_date(opts)
	local date = opts.date

	if type(date) == "function" then
		local line = api.nvim_get_current_line()
		local col = api.nvim_win_get_cursor(0)[2] -- 0-indexed
		return date(line, col)
	elseif type(date) == "table" then -- TODO: check if mt is Date obj
		return date
	else
		return Date.today()
	end
end

function M.new(opts, callback)
	opts = opts or {}
	return setmetatable({
		win = nil,
		buf = nil,
		namespace = api.nvim_create_namespace("calendar"),
		select_state = 0,
		date = new_date(opts),
		opts = opts,
		callback = callback or config.actions.echo_date,
	}, M)
end

local width = 36
local height = 14
local x_offset = 1 -- one border cell
local y_offset = 2 -- one border cell and one padding cell

function M:win_opts()
	local opts = self.opts
	return {
		relative = opts.relative or "editor",
		width = width,
		height = height,
		style = "minimal",
		border = "single",
		row = opts.row or vim.o.lines / 2 - (y_offset + height) / 2,
		col = opts.co or vim.o.columns / 2 - (x_offset + width) / 2,
		title = self.title or "Calendar",
		title_pos = "center",
	}
end

local function set_events(self)
	api.nvim_create_autocmd("VimResized", {
		buffer = self.buf,
		group = self.augroup,
		callback = function()
			if self.win then
				api.nvim_win_set_config(self.win, self:win_opts())
			end
		end,
	})
end

local function set_keys(self)
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
end

function M:jump_day()
	local search_day = (self.date or Date.today()):format("%d")
	fn.cursor(2, 1)
	fn.search(search_day, "W")
end

function M.open(self)
	self.prev_win = api.nvim_get_current_win()
	self.buf = api.nvim_create_buf(false, true)
	self.win = api.nvim_open_win(self.buf, true, self:win_opts())
	vim.bo[self.buf].filetype = "calendar" -- triggers all ftplugin options
	self:render()
	self.augroup = api.nvim_create_augroup("calendar.nvim", { clear = true })
	set_events(self)
	set_keys(self)
	self:jump_day()
end

function M:close()
	api.nvim_buf_delete(self.buf, { force = true })
	api.nvim_set_current_win(self.prev_win)
	self.win = nil
	self.buf = nil
end

function M:map(mode, lhs, rhs)
	local map_opts = { buffer = self.buf, silent = true, nowait = true }
	vim.keymap.set(mode, lhs, function()
		rhs(self)
	end, map_opts)
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
	local col = fn.col(".")
	local char = fn.getline("."):sub(col, col)
	local day = tonumber(vim.trim(fn.expand("<cword>")))
	local line = fn.line(".")
	vim.cmd([[redraw!]])
	if line < 3 or not char:match("%d") then
		return
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
	api.nvim_win_close(0, true)
	api.nvim_set_current_win(self.prev_win)
	return cb(selected_date)
end

function M:forward()
	self:_ensure_day()
	self.date = self.date:set({ day = 1 }):add({ month = vim.v.count1 })
	self:render()
	fn.cursor(2, 1)
	fn.search("01")
	self:render()
end

function M:backward()
	self.date = self.date:set({ day = 1 }):subtract({ month = vim.v.count1 }):last_day_of_month()
	self:render()
	fn.cursor(8, 0)
	fn.search([[\d\d]], "b")
	self:render()
end

local default_hint = {
	" [<] - prev month  [>] - next month",
	" [.] - today   [Enter] - select day",
}

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

	vim.list_extend(content, default_hint)

	-- TODO: redundant, since it's static data
	-- if self.clearable then
	-- 	table.insert(content, " [i] - enter date  [r] - clear date")
	-- else
	-- 	table.insert(content, " [i] - enter date")
	-- end

	api.nvim_buf_set_lines(self.buf, 0, -1, true, content)

	api.nvim_win_set_config(self.win, { height = #content })

	api.nvim_buf_clear_namespace(self.buf, self.namespace, 0, -1)

	vim.bo[self.buf].modifiable = false
end

function M:cursor_left()
	for _ = 1, vim.v.count1 do
		local line, col = fn.line("."), fn.col(".")
		local curr_line = fn.getline(".")
		local _, offset = curr_line:sub(1, col - 1):find(".*%d%d")
		if offset ~= nil then
			fn.cursor(line, offset)
		end
	end
	self.date = self:get_selected_date()
	self:render()
end

function M:cursor_right()
	for _ = 1, vim.v.count1 do
		local line, col = fn.line("."), fn.col(".")
		local curr_line = fn.getline(".")
		local offset = curr_line:sub(col + 1, #curr_line):find("%d%d")
		if offset ~= nil then
			fn.cursor(line, col + offset)
		end
	end
	self.date = self:get_selected_date()
	self:render()
end

function M:cursor_up()
	for _ = 1, vim.v.count1 do
		local line, col = fn.line("."), fn.col(".")
		if line > 9 then
			fn.cursor(line - 1, col)
			return
		end

		local prev_line = fn.getline(line - 1)
		local first_num = prev_line:find("%d%d")
		if first_num == nil then
			return
		end

		local move_to
		if first_num > col then
			move_to = first_num
		else
			move_to = col
		end
		fn.cursor(line - 1, move_to)
	end
	self.date = self:get_selected_date()
	self:render()
end

function M:cursor_down()
	for _ = 1, vim.v.count1 do
		local line, col = fn.line("."), fn.col(".")
		if line <= 1 then
			fn.cursor(line + 1, col)
			return
		end

		local next_line = fn.getline(line + 1)
		local _, last_num = next_line:find(".*%d%d")
		if last_num == nil then
			return
		end

		local move_to
		if last_num < col then
			move_to = last_num
		else
			move_to = col
		end
		fn.cursor(line + 1, move_to)
	end
	self.date = self:get_selected_date()
	self:render()
end

--- TODO: highlight
function M:hl() end

local cal = M.new()

cal:open()
