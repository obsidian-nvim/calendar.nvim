local M = {}

local function to_timestamp(date)
   return os.time({
      year = date.year,
      month = date.month,
      day = date.day,
      hour = date.hour or 0,
      min = date.min or 0,
      sec = date.sec or 0,
   })
end

function M.asctime(date)
   return os.date("%a %b %d %H:%M:%S %Y", to_timestamp(date))
end

function M.rfc3339(date)
   return os.date("%Y-%m-%dT%H:%M:%S", to_timestamp(date))
end

function M.rfc2822(date)
   return os.date("%a, %d %b %Y %H:%M:%S %z", to_timestamp(date))
end

function M.w3cdtf(date)
   return os.date("%Y-%m-%d", to_timestamp(date))
end

return M
