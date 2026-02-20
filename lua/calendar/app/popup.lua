local Calendar = require("calendar")

local M = {}

function M.open(opts)
   opts = opts or {}
   local cal = Calendar.new(opts)
   cal:open()
   return cal
end

-- local Date = require("calendar.date")
-- local cal = M.open()
-- cal:set_hl(Date.new("2026-02-20"), "ErrorMsg")

return M
