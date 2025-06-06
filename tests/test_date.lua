local M = require("calendar.date")

local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T = new_set()

T["new"] = new_set()

T["new"]["from string"] = function()
	local date = M.new("1977-1-1")
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
	local date = M.new("1977-1-1")
	eq(tostring(date), 'Date("1977-1-1")')
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

return T
