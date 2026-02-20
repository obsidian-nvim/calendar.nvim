local M = require("calendar.date")

local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T = new_set()

T["new"] = new_set()

T["new"]["from string"] = function()
   local date = M.new("1977-01-01")
   eq(date.year, 1977)
   eq(date.month, 1)
   eq(date.day, 1)
end

T["new"]["from osdateparam"] = function()
   local date1 = M.new({
      year = 1977,
      month = 1,
      day = 1,
   })

   local int = os.time({
      year = 1977,
      month = 1,
      day = 1,
   })

   local date2 = M.new(os.date("*t", int))

   eq(date1, date2)
end

T["metamethods"] = new_set()

T["metamethods"]["__eq"] = function() end

T["metamethods"]["__tostring"] = function()
   local date = M.new("1977-01-01")
   eq(tostring(date), 'Date("1977-01-01")')
end

T["start_of"] = new_set()

T["start_of"] = function()
   local date = M.new({
      year = 1977,
      month = 1,
      day = 5,
   })
   local start_of_month = date:start_of("month")

   eq(date.day, 5)
   eq(start_of_month.day, 1)
end

T["end_of"] = new_set()

T["end_of"] = function()
   local date = M.new({
      year = 1977,
      month = 1,
      day = 5,
   })
   local end_of_month = date:end_of("month")

   eq(date.day, 5)
   eq(end_of_month.day, 31)
end

T["add/subtract"] = new_set()

T["add/subtract"]["day"] = function()
   local date = M.new("2020-02-28")
   local next_day = date:add({ day = 1 })
   local prev_day = date:subtract({ day = 1 })

   eq(next_day.day, 29)
   eq(next_day.month, 2)
   eq(prev_day.day, 27)
end

T["add/subtract"]["month clamps day"] = function()
   local date = M.new("2020-01-31")
   local next_month = date:add({ month = 1 })

   eq(next_month.month, 2)
   eq(next_month.day, 29)
end

T["lazy fields"] = new_set()

T["lazy fields"]["timestamp"] = function()
   local date = M.new({ year = 2020, month = 1, day = 1 })
   local ts = os.time({ year = 2020, month = 1, day = 1, hour = 0, min = 0, sec = 0 })

   eq(date.timestamp, ts)
end

T["lazy fields"]["weekday"] = function()
   local date = M.new("2020-01-01")
   local osdate = os.date("*t", os.time({ year = 2020, month = 1, day = 1, hour = 0, min = 0, sec = 0 }))

   eq(date:get_weekday(), osdate.wday)
end

T["range"] = new_set()

T["range"]["get_range_until"] = function()
   local start = M.new("2020-01-01")
   local finish = M.new("2020-01-04")
   local range = start:get_range_until(finish)

   eq(#range, 3)
   eq(range[1].day, 1)
   eq(range[3].day, 3)
end

return T
