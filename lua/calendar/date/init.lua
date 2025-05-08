---@class Calendar.date: osdateparam
---@field src? string original string for debug
---@field format_string? "asctime" | "rfc3339" ...
local M = {}
M.__index = M

-- local parse = require("calendar.date.parser")
-- local writers = require"calendar.date.writer"
--
-- local writers = {
-- 	asctime = function(date)
-- 		return "1977-1-1"
-- 	end,
-- }

local write = function(date, format)
	if format == "asctime" then
		return os.date("%Y-%m-%d", os.time(date))
	end
end

---@param src string | osdateparam
---@return Calendar.date | osdateparam
---@return string
local parse = function(src)
	if type(src) == "table" then
		return src, ""
	end
	return {
		year = 1977,
		month = 1,
		day = 1,
	}, "asctime"
end

--- Three ways of initializing a Calendar.date
--- 1. date.new("2077-1-1"), any string that the date parser module can handle
--- 2. date.new({ year = 2077, month = 1, day = 1 }), |osdateparam|, at least a year, month, and day
--- 3. date.new(os.date("*t", integar))
---@param src osdateparam | string
---@return Calendar.date | osdateparam
function M.new(src)
	local params, format = parse(src)
	params.src = type(src) == "string" and src or nil
	params.format_string = format
	setmetatable(params, M)
	return params
end

function M.__tostring(self)
	local format = 'Date("%s")'
	local src
	if self.src then
		src = self.src
	else
		src = write(self, "asctime")
	end
	return format:format(src)
end

---@param rhs string | Calendar.date
---@return boolean
function M:__eq(rhs)
	local other = type(rhs) == "string" and M.new(rhs) or rhs
	return self.year == other.year and self.month == other.month and self.day == other.day
end

function M.today()
	return M.new(os.date("*t"))
end

---@param format string
function M:format(format)
	local int = os.time(self)
	return os.date(format, int)
end

function M:start_of(span)
	local opts = {
		day = { hour = 0, min = 0 },
		month = { day = 1, hour = 0, min = 0 },
		year = { month = 1, day = 1, hour = 0, min = 0 },
		hour = { min = 0 },
	}
	local new_attrs = opts[span]

	-- TODO: week
	local copy = vim.deepcopy(self)
	return vim.tbl_extend("force", copy, new_attrs)
end

function M:end_of(span)
	local opts = {
		day = { hour = 23, min = 59 },
		year = { month = 12, day = 31, hour = 23, min = 59 },
		hour = { min = 59 },
		month = { day = 29, hour = 23, min = 59 },
	}

	local new_attrs = opts[span]

	-- if span == "month" then
	-- 	local date = os_date(self.timestamp)
	-- 	return self:set({ day = OrgDate._days_of_month(date) }):end_of("day")
	-- end

	-- TODO: week
	local copy = vim.deepcopy(self)
	return vim.tbl_extend("force", copy, new_attrs)
end

return M
