local api = vim.api
local M = require("calendar")
local config = require("calendar.config")
--- Cursor view

vim.keymap.set("i", "@", function()
   api.nvim_put({ "@" }, "c", true, true)

   vim.cmd.stopinsert()
   local cal = M.new({
      relative = "cursor",
      row = 1,
      col = 0,
      border = "none",
   }, function()
      config.actions.insert()
      -- vim.cmd.startinsert()
   end)
   cal:open()
end)
