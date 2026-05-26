local M = {
  config = {},
  handlers = {},
}

---@alias yyxi.lsp.fix.ClientName string
---@alias yyxi.lsp.fix.OrGroup yyxi.lsp.fix.ClientName[]
---@alias yyxi.lsp.fix.OrderStep yyxi.lsp.fix.ClientName | yyxi.lsp.fix.OrGroup
---@alias yyxi.lsp.fix.Status 'applied' | 'noop' | 'skipped' | 'failed'

---@class yyxi.lsp.fix.FiletypeConfig
---@field order yyxi.lsp.fix.OrderStep[]

---@class yyxi.lsp.fix.Config
---@field [string] yyxi.lsp.fix.FiletypeConfig

---@class yyxi.lsp.fix.Context
---@field bufnr integer
---@field client vim.lsp.Client

---@class yyxi.lsp.fix.Result
---@field status yyxi.lsp.fix.Status
---@field changed boolean
---@field message? string
---@field client_name? string
---@field handler_name? string

---@class yyxi.lsp.fix.RunResult: yyxi.lsp.fix.Result
---@field applied_count integer
---@field noop_count integer
---@field skipped_count integer
---@field failed_count integer

---@alias yyxi.lsp.fix.Handler fun(ctx: yyxi.lsp.fix.Context): yyxi.lsp.fix.Result

---@param status yyxi.lsp.fix.Status
---@param fields? { changed?: boolean, message?: string, client_name?: string, handler_name?: string }
---@return yyxi.lsp.fix.Result
local function result(status, fields)
  fields = fields or {}
  local changed = fields.changed
  if changed == nil then changed = status == 'applied' end

  return {
    status = status,
    changed = changed,
    message = fields.message,
    client_name = fields.client_name,
    handler_name = fields.handler_name,
  }
end

---@param status string?
---@return yyxi.lsp.fix.Status?
local function valid_status(status)
  if status == 'applied' or status == 'noop' or status == 'skipped' or status == 'failed' then
    return status
  end
  return nil
end

---@param client_name string
---@param handler_name? string
---@param res any
---@return yyxi.lsp.fix.Result
local function normalize_result(client_name, handler_name, res)
  if type(res) ~= 'table' then
    return result('failed', {
      message = 'fix handler returned a non-table result',
      client_name = client_name,
      handler_name = handler_name,
    })
  end

  local status = valid_status(res.status)
  if not status then
    return result('failed', {
      message = 'fix handler returned an invalid status',
      client_name = client_name,
      handler_name = handler_name,
    })
  end

  local changed = res.changed
  if changed == nil then changed = status == 'applied' end

  return {
    status = status,
    changed = changed,
    message = res.message,
    client_name = res.client_name or client_name,
    handler_name = res.handler_name or handler_name,
  }
end

---@param entry yyxi.lsp.fix.Result|yyxi.lsp.fix.RunResult
---@param status yyxi.lsp.fix.Status
---@param count_key 'applied_count'|'noop_count'|'skipped_count'|'failed_count'
---@return integer
local function count_for(entry, status, count_key)
  local nested_count = rawget(entry, count_key)
  if type(nested_count) == 'number' then return nested_count end
  return entry.status == status and 1 or 0
end

---@param results (yyxi.lsp.fix.Result|yyxi.lsp.fix.RunResult)[]
---@return yyxi.lsp.fix.RunResult
local function aggregate_results(results)
  local counts = {
    applied = 0,
    noop = 0,
    skipped = 0,
    failed = 0,
  }

  for _, entry in ipairs(results) do
    counts.applied = counts.applied + count_for(entry, 'applied', 'applied_count')
    counts.noop = counts.noop + count_for(entry, 'noop', 'noop_count')
    counts.skipped = counts.skipped + count_for(entry, 'skipped', 'skipped_count')
    counts.failed = counts.failed + count_for(entry, 'failed', 'failed_count')
  end

  local status ---@type yyxi.lsp.fix.Status
  if counts.applied > 0 then
    status = 'applied'
  elseif counts.failed > 0 then
    status = 'failed'
  elseif counts.noop > 0 then
    status = 'noop'
  else
    status = 'skipped'
  end

  return {
    status = status,
    changed = counts.applied > 0,
    applied_count = counts.applied,
    noop_count = counts.noop,
    skipped_count = counts.skipped,
    failed_count = counts.failed,
  }
end

---@param client vim.lsp.Client
---@param method string
---@param params table
---@param timeout_ms? integer
---@param bufnr? integer
---@return any?, string?
local function request_sync(client, method, params, timeout_ms, bufnr)
  local ok, response, reason = pcall(
    function() return client:request_sync(method, params, timeout_ms, bufnr) end
  )

  if not ok then return nil, tostring(response) end
  if response == nil then return nil, reason or 'request failed' end
  if response.err ~= nil then return nil, response.err.message or tostring(response.err) end

  return response.result, nil
end

---@param client_name yyxi.lsp.fix.ClientName
---@param handlers yyxi.lsp.fix.Handler[]
function M.register(client_name, handlers)
  local registered = {}
  for index, handler in ipairs(handlers) do
    registered[index] = handler
  end
  M.handlers[client_name] = registered
end

---@param config? yyxi.lsp.fix.Config
function M.setup(config) M.config = vim.tbl_deep_extend('force', M.config, config or {}) end

---@param bufnr? integer
---@return integer
local function resolve_bufnr(bufnr)
  if bufnr == nil or bufnr == 0 then return vim.api.nvim_get_current_buf() end
  return bufnr
end

---@param bufnr integer
---@return string
local function filetype(bufnr) return vim.api.nvim_get_option_value('filetype', { buf = bufnr }) end

---@param bufnr integer
---@return yyxi.lsp.fix.OrderStep[]
local function order_for_buffer(bufnr)
  local entry = M.config[filetype(bufnr)]
  if type(entry) == 'table' and type(entry.order) == 'table' then return entry.order end
  return {}
end

---@param bufnr integer
---@return vim.lsp.Client[]
local function attached_clients(bufnr)
  local get_clients = vim.lsp.get_clients
  if get_clients then return get_clients({ bufnr = bufnr }) end

  ---@diagnostic disable-next-line: deprecated
  return vim.lsp.get_active_clients({ bufnr = bufnr })
end

---@param bufnr integer
---@return table<string, vim.lsp.Client>
local function clients_by_name(bufnr)
  local clients = {}

  for _, client in ipairs(attached_clients(bufnr)) do
    if client and type(client.name) == 'string' and clients[client.name] == nil then
      clients[client.name] = client
    end
  end

  return clients
end

---@param bufnr integer
---@return integer
local function changedtick(bufnr) return vim.api.nvim_buf_get_changedtick(bufnr) end

---@param ctx yyxi.lsp.fix.Context
---@param action_kind string
---@param diagnostics? lsp.Diagnostic[]
---@return lsp.CodeActionParams
local function code_action_params(ctx, action_kind, diagnostics)
  local last_line = math.max(vim.api.nvim_buf_line_count(ctx.bufnr) - 1, 0)
  local offset_encoding = ctx.client.offset_encoding or 'utf-16'

  return {
    textDocument = vim.lsp.util.make_text_document_params(ctx.bufnr),
    range = vim.lsp.util._make_line_range_params(ctx.bufnr, 0, last_line, offset_encoding),
    context = {
      only = { action_kind },
      diagnostics = diagnostics or {},
    },
  }
end

---@param edit lsp.WorkspaceEdit
---@param offset_encoding string
---@return true?, string?
local function apply_workspace_edit(edit, offset_encoding)
  local ok, err = pcall(vim.lsp.util.apply_workspace_edit, edit, offset_encoding)
  if not ok then return nil, tostring(err) end
  return true, nil
end

---@param command lsp.Command
---@param ctx yyxi.lsp.fix.Context
---@param timeout_ms? integer
---@return true?, string?
local function execute_command(command, ctx, timeout_ms)
  local _, err =
    request_sync(ctx.client, 'workspace/executeCommand', command, timeout_ms, ctx.bufnr)
  if err then return nil, err end
  return true, nil
end

---@param action lsp.Command|lsp.CodeAction
---@return lsp.Command?
local function command_from_action(action)
  local command = action.command
  if type(command) == 'table' then
    ---@cast command lsp.Command
    return command
  end
  if type(command) == 'string' then
    return {
      title = action.title or command,
      command = command,
      arguments = action.arguments,
    }
  end
  return nil
end

---@param client_name yyxi.lsp.fix.ClientName
---@param client vim.lsp.Client?
---@return yyxi.lsp.fix.RunResult
local function run_client(client_name, client, bufnr)
  if client == nil then
    return aggregate_results({ result('skipped', { client_name = client_name }) })
  end

  local handlers = M.handlers[client_name]
  if type(handlers) ~= 'table' or vim.tbl_isempty(handlers) then
    return aggregate_results({ result('skipped', { client_name = client_name }) })
  end

  local results = {}
  local ctx = {
    bufnr = bufnr,
    client = client,
  }

  for index, handler in ipairs(handlers) do
    local handler_name = string.format('%s[%d]', client_name, index)
    local ok, handler_result = pcall(handler, ctx)
    if not ok then
      table.insert(
        results,
        result('failed', {
          message = tostring(handler_result),
          client_name = client_name,
          handler_name = handler_name,
        })
      )
    else
      table.insert(results, normalize_result(client_name, handler_name, handler_result))
    end
  end

  return aggregate_results(results)
end

---@param step yyxi.lsp.fix.OrderStep
---@param bufnr integer
---@param clients table<string, vim.lsp.Client>
---@return yyxi.lsp.fix.RunResult
local function run_step(step, bufnr, clients)
  if type(step) == 'string' then return run_client(step, clients[step], bufnr) end

  if type(step) ~= 'table' or not vim.islist(step) then
    return aggregate_results({ result('skipped') })
  end

  local results = {}
  for _, client_name in ipairs(step) do
    local entry = run_client(client_name, clients[client_name], bufnr)
    table.insert(results, entry)
    if entry.status == 'applied' or entry.status == 'noop' then
      return aggregate_results(results)
    end
  end

  return aggregate_results(results)
end

---@param params lsp.ExecuteCommandParams
---@param timeout_ms? integer
---@return yyxi.lsp.fix.Result
function M.execute_workspace_command(ctx, params, timeout_ms)
  local before = changedtick(ctx.bufnr)
  local _, err = request_sync(ctx.client, 'workspace/executeCommand', params, timeout_ms, ctx.bufnr)

  if err then return result('failed', { message = err, client_name = ctx.client.name }) end

  local after = changedtick(ctx.bufnr)
  if after ~= before then return result('applied', { client_name = ctx.client.name }) end
  return result('noop', { client_name = ctx.client.name, changed = false })
end

---@param action_kind string
---@param timeout_ms? integer|lsp.Diagnostic[]
---@param diagnostics? lsp.Diagnostic[]
---@return yyxi.lsp.fix.Result
function M.execute_code_action_kind(ctx, action_kind, timeout_ms, diagnostics)
  local resolved_timeout_ms = timeout_ms
  if type(timeout_ms) == 'table' and diagnostics == nil then
    diagnostics = timeout_ms
    resolved_timeout_ms = nil
  end
  ---@cast resolved_timeout_ms integer|nil

  if ctx.client.supports_method and not ctx.client:supports_method('textDocument/codeAction') then
    return result('skipped', { client_name = ctx.client.name, changed = false })
  end

  local before = changedtick(ctx.bufnr)
  local actions, err = request_sync(
    ctx.client,
    'textDocument/codeAction',
    code_action_params(ctx, action_kind, diagnostics),
    resolved_timeout_ms,
    ctx.bufnr
  )

  if err then
    return result('failed', { message = err, client_name = ctx.client.name, changed = false })
  end
  if type(actions) ~= 'table' or vim.tbl_isempty(actions) then
    return result('skipped', { client_name = ctx.client.name, changed = false })
  end
  if not vim.islist(actions) then
    return result(
      'failed',
      { message = 'code action request returned a non-list result', client_name = ctx.client.name }
    )
  end

  local attempted = false
  local offset_encoding = ctx.client.offset_encoding or 'utf-16'

  for _, action in ipairs(actions) do
    if type(action) ~= 'table' then
      return result('failed', {
        message = 'code action request returned a non-table action',
        client_name = ctx.client.name,
      })
    end

    if action.disabled == nil then
      local command = command_from_action(action)
      if action.edit ~= nil or command ~= nil then attempted = true end

      if action.edit ~= nil then
        local _, apply_error = apply_workspace_edit(action.edit, offset_encoding)
        if apply_error then
          return result('failed', { message = apply_error, client_name = ctx.client.name })
        end
      end

      if command ~= nil then
        local _, command_error = execute_command(command, ctx, resolved_timeout_ms)
        if command_error then
          return result('failed', { message = command_error, client_name = ctx.client.name })
        end
      end
    end
  end

  if not attempted then
    return result('skipped', { client_name = ctx.client.name, changed = false })
  end

  local after = changedtick(ctx.bufnr)
  if after ~= before then return result('applied', { client_name = ctx.client.name }) end
  return result('noop', { client_name = ctx.client.name, changed = false })
end

---@param bufnr? integer
---@return yyxi.lsp.fix.RunResult
function M.fix(bufnr)
  bufnr = resolve_bufnr(bufnr)

  local order = order_for_buffer(bufnr)
  if vim.tbl_isempty(order) then return aggregate_results({ result('skipped') }) end

  local clients = clients_by_name(bufnr)
  local results = {}
  for _, step in ipairs(order) do
    table.insert(results, run_step(step, bufnr, clients))
  end

  return aggregate_results(results)
end

return M
