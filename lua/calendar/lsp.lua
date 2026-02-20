local M = {}

local ms = vim.lsp.protocol.Methods

---@class CalendarLspContext
---@field bufnr integer
---@field winid integer?
---@field calendar Calendar?
---@field date Calendar.date?
---@field day_key string?

---@alias CalendarLspHoverHandler fun(params: lsp.HoverParams, ctx: CalendarLspContext, callback: fun(err?: lsp.ResponseError, result: lsp.Hover|nil))
---@alias CalendarLspDefinitionHandler fun(params: lsp.DefinitionParams, ctx: CalendarLspContext, callback: fun(err?: lsp.ResponseError, result: lsp.Location|lsp.Location[]|lsp.LocationLink[]|nil))
---@alias CalendarLspReferencesHandler fun(params: lsp.ReferenceParams, ctx: CalendarLspContext, callback: fun(err?: lsp.ResponseError, result: lsp.Location[]|nil))
---@alias CalendarLspDocumentSymbolHandler fun(params: lsp.DocumentSymbolParams, ctx: CalendarLspContext, callback: fun(err?: lsp.ResponseError, result: lsp.DocumentSymbol[]|lsp.SymbolInformation[]|nil))
---@alias CalendarLspCodeActionHandler fun(params: lsp.CodeActionParams, ctx: CalendarLspContext, callback: fun(err?: lsp.ResponseError, result: lsp.CodeAction[]|lsp.Command[]|nil))

---@class CalendarLspOpts
---@field enabled? boolean
---@field hover? CalendarLspHoverHandler
---@field definition? CalendarLspDefinitionHandler
---@field references? CalendarLspReferencesHandler
---@field documentSymbol? CalendarLspDocumentSymbolHandler
---@field codeAction? CalendarLspCodeActionHandler

local function get_bufnr(params)
   if params and params.textDocument and params.textDocument.uri then
      return vim.uri_to_bufnr(params.textDocument.uri)
   end
   return vim.api.nvim_get_current_buf()
end

---@param params lsp.TextDocumentPositionParams|lsp.CodeActionParams|lsp.DocumentSymbolParams|lsp.ReferenceParams|lsp.InitializeParams|nil
---@return CalendarLspContext
local function build_context(params)
   local bufnr = get_bufnr(params)
   if not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = vim.api.nvim_get_current_buf()
   end
   local calendar = vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].calendar_instance or nil
   local date = calendar and calendar:get_selected_date() or nil
   local winid = vim.fn.bufwinid(bufnr)
   if winid == -1 then
      winid = nil
   end
   return {
      bufnr = bufnr,
      winid = winid,
      calendar = calendar,
      date = date,
      day_key = date and date:format("%Y-%m-%d") or nil,
   }
end

local function notify_error(method, err)
   vim.notify(("[calendar-ls] %s handler failed: %s"):format(method, err), vim.log.levels.ERROR)
end

local function call_handler(method, handler, params, callback, empty_result)
   if not handler then
      return callback(nil, empty_result)
   end
   local ctx = build_context(params)
   local ok, err = pcall(handler, params, ctx, callback)
   if not ok then
      notify_error(method, err)
      return callback(nil, empty_result)
   end
end

---@param opts CalendarLspOpts
---@return lsp.InitializeResult
local function build_initialize_result(opts)
   ---@type lsp.ServerCapabilities
   local capabilities = {
      hoverProvider = opts.hover ~= nil,
      definitionProvider = opts.definition ~= nil,
      referencesProvider = opts.references ~= nil,
      documentSymbolProvider = opts.documentSymbol ~= nil,
      codeActionProvider = opts.codeAction ~= nil,
   }

   return {
      capabilities = capabilities,
      serverInfo = {
         name = "nvim-calendar-ls",
         version = "0.1.0",
      },
   }
end

---@param opts CalendarLspOpts
---@return table<vim.lsp.protocol.Method, fun(params: table, callback: fun(err: lsp.ResponseError?, result: any), config: table|nil)>
local function build_handlers(opts)
   return setmetatable({
      [ms.initialize] = function(_, callback)
         callback(nil, build_initialize_result(opts))
      end,
      [ms.textDocument_hover] = function(params, callback)
         return call_handler(ms.textDocument_hover, opts.hover, params, callback, nil)
      end,
      [ms.textDocument_definition] = function(params, callback)
         return call_handler(ms.textDocument_definition, opts.definition, params, callback, {})
      end,
      [ms.textDocument_references] = function(params, callback)
         return call_handler(ms.textDocument_references, opts.references, params, callback, {})
      end,
      [ms.textDocument_documentSymbol] = function(params, callback)
         return call_handler(ms.textDocument_documentSymbol, opts.documentSymbol, params, callback, {})
      end,
      -- [ms.textDocument_codeAction] = function(params, callback)
      --    return call_handler(ms.textDocument_codeAction, opts.codeAction, params, callback, {})
      -- end,
   }, {
      __index = function()
         return function(_, callback)
            callback(nil, nil)
         end
      end,
   })
end

---@param bufnr integer
---@param opts CalendarLspOpts
---@return integer?
function M.attach(bufnr, opts)
   if not opts or opts.enabled == false then
      return nil
   end

   local handlers = build_handlers(opts)
   local capabilities = vim.lsp.protocol.make_client_capabilities()

   ---@type vim.lsp.ClientConfig
   local lsp_config = {
      name = "nvim-calendar-ls",
      capabilities = capabilities,
      offset_encoding = "utf-8",
      cmd = function()
         return {
            request = function(method, ...)
               local ok = pcall(handlers[method], ...)
               return ok
            end,
            notify = function(method, ...)
               local ok = pcall(handlers[method], ...)
               return ok
            end,
            is_closing = function() end,
            terminate = function() end,
         }
      end,
      init_options = {},
   }

   local ok, client_id = pcall(vim.lsp.start, lsp_config, { bufnr = bufnr, silent = true })
   if not ok then
      vim.notify("[calendar-ls] failed to start: " .. client_id, vim.log.levels.ERROR)
      return nil
   end

   return client_id
end

return M
