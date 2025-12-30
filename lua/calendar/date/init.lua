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

---@return boolean
local function _is_leap_year(year)
   return year % 400 == 0 or (year % 100 ~= 0 and year % 4 == 0)
end

---@return number
local function _days_of_february(year)
   return _is_leap_year(year) and 29 or 28
end

---@param date osdate
---@return number
local function _days_of_month(date)
   local days_of = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
   local month = date.month

   if month == 2 then
      return _days_of_february(date.year)
   end

   if month >= 1 and month <= 12 then
      return days_of[month]
   end

   -- In case the month goes below or above the threshold (via adding or subtracting)
   -- We need to adjust it to be within the range of 1-12
   -- by either adding or subtracting
   if month < 1 then
      month = 12 - month
   end

   if month > 12 then
      month = month - 12
   end

   return days_of[month]
end

function M:end_of(span)
   -- TODO: week
   local opts = {
      day = { hour = 23, min = 59 },
      year = { month = 12, day = 31, hour = 23, min = 59 },
      hour = { min = 59 },
      month = { day = 29, hour = 23, min = 59 },
   }

   local new_attrs = opts[span]

   if span == "month" then
      local new_date = vim.deepcopy(self)
      new_date.day = _days_of_month(self)
      return new_date
   end

   local copy = vim.deepcopy(self)
   return vim.tbl_extend("force", copy, new_attrs)
end

---@param opts osdateparam
function M:set(opts)
   local copy = vim.deepcopy(self)
   return vim.tbl_extend("force", copy, opts)
end

-- ---@param opts OrgDateSetOpts
-- ---@return OrgDate
-- function OrgDate:set(opts)
-- 	local data = {
-- 		day = self.day,
-- 		month = self.month,
-- 		year = self.year,
-- 		hour = self.hour,
-- 		min = self.min,
-- 		date_only = self.date_only,
-- 		type = self.type,
-- 		range = self.range,
-- 		active = self.active,
-- 		adjustments = self.adjustments,
-- 		is_date_range_start = self.is_date_range_start,
-- 		is_date_range_end = self.is_date_range_end,
-- 		related_date = self.related_date,
-- 	}
--
-- 	if type(opts.date_only) == "boolean" then
-- 		data.date_only = opts.date_only
-- 	end
--
-- 	for key, value in pairs(opts) do
-- 		data[key] = value
-- 	end
--
-- 	if self.timestamp_end then
-- 		local range_diff = self.timestamp_end - self.timestamp
-- 		local timestamp = os.time(data)
-- 		data.timestamp_end = timestamp + range_diff
-- 	end
--
-- 	return OrgDate:new(data)
-- end

return M
