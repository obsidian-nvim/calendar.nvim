---@class Calendar.date: osdateparam
---@field src? string original string for debug
---@field format_string? "asctime" | "rfc3339" | "rfc2822" | "w3cdtf"
---@field date_only? boolean
---@field timestamp? integer
---@field wday? integer
---@field yday? integer
---@field isdst? boolean
local parser = require("calendar.date.parser")
local writer = require("calendar.date.writer")
local M = {}

local computed_keys = {
   timestamp = true,
   wday = true,
   yday = true,
   isdst = true,
}

local function normalize_osdate(date)
   return {
      year = date.year,
      month = date.month,
      day = date.day,
      hour = date.hour or 0,
      min = date.min or 0,
      sec = date.sec or 0,
   }
end

function M._get_timestamp(date)
   return os.time(normalize_osdate(date))
end

function M._to_osdate(date)
   return os.date("*t", M._get_timestamp(date))
end

local function invalidate_cache(date)
   date.timestamp = nil
   date.wday = nil
   date.yday = nil
   date.isdst = nil
end

local function parse_string(src)
   local date = parser.rfc3339(src)
   if date then
      return date, "rfc3339"
   end

   date = parser.rfc2822(src)
   if date then
      return date, "rfc2822"
   end

   date = parser.asctime(src)
   if date then
      return date, "asctime"
   end

   date = parser.W3CDTF(src)
   if date then
      date.date_only = true
      return date, "w3cdtf"
   end

   return nil
end

local function apply_date_only(date)
   if date.date_only then
      date.hour = 0
      date.min = 0
      date.sec = 0
   end
   return date
end

local function infer_date_only(date)
   if type(date.date_only) == "boolean" then
      return date.date_only
   end
   return date.hour == nil and date.min == nil and date.sec == nil
end

--- Three ways of initializing a Calendar.date
--- 1. date.new("2077-1-1"), any string that the date parser module can handle
--- 2. date.new({ year = 2077, month = 1, day = 1 }), |osdateparam|, at least a year, month, and day
--- 3. date.new(os.date("*t", integer))
---@param src osdateparam | string | Calendar.date | nil
---@return Calendar.date
function M.new(src)
   if getmetatable(src) == M then
      return src
   end

   local params
   local format

   if type(src) == "string" then
      params, format = parse_string(src)
   elseif type(src) == "table" then
      params = vim.deepcopy(src)
   else
      params = os.date("*t")
   end

   if not params or not params.year or not params.month or not params.day then
      params = os.date("*t")
   end

   params.date_only = infer_date_only(params)
   params = apply_date_only(params)
   params.src = type(src) == "string" and src or nil
   params.format_string = format

   invalidate_cache(params)
   return setmetatable(params, M)
end

function M.__index(self, key)
   local value = rawget(M, key)
   if value ~= nil then
      return value
   end

   if not computed_keys[key] then
      return nil
   end

   if key == "timestamp" then
      local ts = M._get_timestamp(self)
      rawset(self, "timestamp", ts)
      return ts
   end

   local osdate = M._to_osdate(self)
   rawset(self, "wday", osdate.wday)
   rawset(self, "yday", osdate.yday)
   rawset(self, "isdst", osdate.isdst)
   return rawget(self, key)
end

function M.__tostring(self)
   local format = 'Date("%s")'
   local src = self.src
   if not src then
      local writer_fn = self.format_string and writer[self.format_string] or nil
      if writer_fn then
         src = writer_fn(self)
      elseif self.date_only then
         src = writer.w3cdtf(self)
      else
         src = writer.rfc3339(self)
      end
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
   local date = M.new(os.date("*t"))
   date.date_only = true
   return apply_date_only(date)
end

---@param format string
function M:format(format)
   return os.date(format, self.timestamp)
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

   if month < 1 then
      month = 12 - month
   end

   if month > 12 then
      month = month - 12
   end

   return days_of[month]
end

---@param opts osdateparam
function M:set(opts)
   local copy = vim.deepcopy(self)
   for key, value in pairs(opts) do
      copy[key] = value
   end
   copy.date_only = infer_date_only(copy)
   copy = apply_date_only(copy)
   invalidate_cache(copy)
   return setmetatable(copy, M)
end

---@param opts osdateparam
function M:add(opts)
   opts = opts or {}
   local date = M._to_osdate(self)
   for opt, val in pairs(opts) do
      if opt == "week" then
         opt = "day"
         val = val * 7
      end
      date[opt] = date[opt] + val
   end
   if opts.month then
      date.day = math.min(date.day, _days_of_month(date))
   end
   local result = M.new(date)
   if self.date_only then
      result.date_only = true
      apply_date_only(result)
   end
   return result
end

---@param opts osdateparam
function M:subtract(opts)
   opts = opts or {}
   for opt, val in pairs(opts) do
      opts[opt] = -val
   end
   return self:add(opts)
end

---@param span string
---@return Calendar.date
function M:start_of(span)
   local opts = {
      day = { hour = 0, min = 0, sec = 0 },
      month = { day = 1, hour = 0, min = 0, sec = 0 },
      year = { month = 1, day = 1, hour = 0, min = 0, sec = 0 },
      hour = { min = 0, sec = 0 },
   }

   if span == "week" then
      return self:subtract({ day = self:get_isoweekday() - 1 }):start_of("day")
   end

   local new_attrs = opts[span]
   if not new_attrs then
      return self
   end

   return self:set(new_attrs)
end

function M:end_of(span)
   local opts = {
      day = { hour = 23, min = 59, sec = 59 },
      year = { month = 12, day = 31, hour = 23, min = 59, sec = 59 },
      hour = { min = 59, sec = 59 },
   }

   if span == "week" then
      return self:start_of("week"):add({ day = 6 }):end_of("day")
   end

   if span == "month" then
      return self:set({ day = _days_of_month(self) }):end_of("day")
   end

   local new_attrs = opts[span]
   if not new_attrs then
      return self
   end

   return self:set(new_attrs)
end

---@return Calendar.date
function M:last_day_of_month()
   return self:set({ day = _days_of_month(self) })
end

---@param weekday number
---@return number
local function convert_to_isoweekday(weekday)
   if weekday == 1 then
      return 7
   end
   return weekday - 1
end

---@return number
function M:get_weekday()
   return tonumber(self.wday) or 0
end

function M:get_isoweekday()
   local wday = tonumber(self.wday)
   assert(wday, "invalid weekday")
   return convert_to_isoweekday(wday)
end

---@return boolean
function M:has_time()
   return not self.date_only
end

---Range of dates, excluding date
---@param date Calendar.date
---@return Calendar.date[]
function M:get_range_until(date)
   local this = self
   local dates = {}
   local until_ts = date.timestamp

   while this.timestamp < until_ts do
      table.insert(dates, this)
      this = this:add({ day = 1 })
   end

   return dates
end

return M
