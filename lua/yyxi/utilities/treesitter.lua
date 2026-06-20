local filetypes = require('yyxi.plugins.filetypes')

local M = {}

local QUERY_KINDS = { 'highlights', 'injections', 'indents', 'folds', 'textobjects' }

local function repository_root()
  local source = debug.getinfo(1, 'S').source
  local path = source:sub(1, 1) == '@' and source:sub(2) or source
  return vim.fn.fnamemodify(path, ':p:h:h:h:h')
end

local function source_manifest_path()
  return vim.fs.joinpath(repository_root(), 'source-manifest.json')
end

local function read_lockfile()
  local path = source_manifest_path()
  local content = table.concat(vim.fn.readfile(path), '\n')
  return vim.json.decode(content)
end

local function treesitter_metadata()
  local lock = read_lockfile()
  return lock.treesitter or {}
end

local function parser_metadata()
  local lock = read_lockfile()
  local languages = {}

  for _, source in pairs(lock.sources or {}) do
    local treesitter = source.treesitter or {}
    for language, parser in pairs(treesitter.parsers or {}) do
      languages[language] = parser
    end
  end

  return languages
end

function M.site_dir()
  local metadata = treesitter_metadata()
  return vim.fs.joinpath(repository_root(), metadata.runtimeSite or 'vendor/treesitter')
end

function M.languages()
  local languages = vim.tbl_keys(parser_metadata())
  table.sort(languages)
  return languages
end

function M.prepend_runtimepath()
  local site = M.site_dir()
  if not vim.tbl_contains(vim.opt.runtimepath:get(), site) then
    vim.opt.runtimepath:prepend(site)
  end
end

function M.register_filetypes()
  local treesitter_language = vim.treesitter and vim.treesitter.language
  local register = treesitter_language and treesitter_language.register
  if type(register) ~= 'function' then return end

  for language, aliases in pairs(filetypes.treesitter_language_aliases()) do
    pcall(register, language, aliases)
  end
end

function M.has_parser(language)
  if not language or language == '' then return false end

  local ok, loaded = pcall(vim.treesitter.language.add, language)
  return ok and loaded == true
end

function M.has_query(language, query)
  if not language or language == '' then return false end

  local ok, result = pcall(vim.treesitter.query.get, language, query)
  return ok and result ~= nil
end

local function query_files(language, query)
  if not language or language == '' then return {} end

  local ok, files = pcall(vim.treesitter.query.get_files, language, query)
  if not ok or type(files) ~= 'table' then return {} end

  return files
end

function M.info(buffer)
  local bufnr = buffer or vim.api.nvim_get_current_buf()
  local filetype = vim.bo[bufnr].filetype
  local language = vim.treesitter.language.get_lang(filetype)
  local loaded = M.has_parser(language)
  local info = {
    buffer = bufnr,
    filetype = filetype,
    language = language,
    parser_loaded = loaded,
    registered_filetypes = {},
    runtime_site = M.site_dir(),
    queries = {},
  }

  local get_filetypes = vim.treesitter
    and vim.treesitter.language
    and vim.treesitter.language.get_filetypes
  if loaded and type(get_filetypes) == 'function' then
    local ok, parser_filetypes = pcall(get_filetypes, language)
    if ok and type(parser_filetypes) == 'table' then
      info.registered_filetypes = parser_filetypes
    end
  end

  for _, query in ipairs(QUERY_KINDS) do
    info.queries[query] = query_files(language, query)
  end

  return info
end

function M.show_info() vim.print(M.info()) end

function M.foldexpr()
  local language = vim.treesitter.language.get_lang(vim.bo.filetype)
  if M.has_parser(language) and M.has_query(language, 'folds') then
    return vim.treesitter.foldexpr()
  end

  return '0'
end

function M.indentexpr()
  local language = vim.treesitter.language.get_lang(vim.bo.filetype)
  if M.has_parser(language) and M.has_query(language, 'indents') then
    local ok, indent = pcall(function() return require('nvim-treesitter').indentexpr() end)
    if ok then return indent end
  end

  return -1
end

function M.start_for_buffer(args)
  local buffer = args.buf
  local filetype = vim.bo[buffer].filetype
  local language = vim.treesitter.language.get_lang(filetype)

  if not M.has_parser(language) then return end

  if M.has_query(language, 'highlights') then pcall(vim.treesitter.start, buffer, language) end

  if M.has_query(language, 'folds') then
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = "v:lua.require'yyxi.utilities.treesitter'.foldexpr()"
  end

  if M.has_query(language, 'indents') then
    vim.bo[buffer].indentexpr = "v:lua.require'yyxi.utilities.treesitter'.indentexpr()"
  end
end

function M.setup()
  M.prepend_runtimepath()
  M.register_filetypes()

  local ok, nvim_treesitter = pcall(require, 'nvim-treesitter')
  ---@diagnostic disable-next-line: redundant-parameter
  if ok and nvim_treesitter.setup then nvim_treesitter.setup({ install_dir = M.site_dir() }) end

  vim.api.nvim_create_user_command('TSInfo', function() M.show_info() end, {
    desc = 'Show managed Tree-sitter parser and query info for the current buffer',
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('yyxi_treesitter', { clear = true }),
    callback = M.start_for_buffer,
  })
end

return M
