---@class Calendar.date: osdateparam
---@field src? string original string for debug
---@field format? "asctime" | "rfc3339" ...
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
	params.format = format
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

return M
