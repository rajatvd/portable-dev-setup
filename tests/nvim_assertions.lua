local function check(condition, message)
  if not condition then
    error(message, 0)
  end
end

local function mapping(lhs, mode)
  return vim.fn.maparg(lhs, mode, false, true)
end

local function check_rhs(lhs, mode, expected, message)
  local value = mapping(lhs, mode)
  check(type(value) == "table" and value.rhs == expected, message)
end

check(vim.g.portable_dev_setup_loaded == 1, "init.vim did not finish")
check(vim.g.portable_dev_setup_lua_loaded == 1, "portable Lua setup did not finish")
check(vim.o.number, "number setting was not loaded")
check(vim.o.relativenumber, "relativenumber setting was not loaded")
check(vim.o.wrap, "wrap setting was not loaded")
check(vim.o.shiftwidth == 4, "shiftwidth setting was not loaded")
check(vim.o.scrolloff == 8, "scrolloff setting was not loaded")
check(vim.o.updatetime == 50, "updatetime setting was not loaded")
check(vim.o.cmdheight == 2, "cmdheight setting was not loaded")
check(vim.o.colorcolumn == "88", "colorcolumn setting was not loaded")
check(vim.o.guicursor == "", "guicursor setting was not loaded")
check(vim.o.undofile, "undo setting was not loaded")
check(not vim.o.swapfile and not vim.o.backup, "temporary-file settings were not loaded")
check(vim.o.background == "dark", "dark background setting was not retained")
check(vim.g.colors_name == "base16-atelierestuary", "required base16-atelierestuary colorscheme was not loaded")
check(vim.g.mapleader == " ", "leader was not loaded")

check_rhs("<Space>w", "n", ":write<CR>", "leader save mapping was not loaded")
check_rhs("<C-S>", "n", ":write<CR>", "control save mapping was not loaded")
check_rhs("jk", "i", "<Esc>", "insert escape mapping was not loaded")
check_rhs("<C-H>", "n", "<C-w>h", "window navigation mapping was not loaded")
check_rhs("H", "n", "^", "line-start mapping was not loaded")
check_rhs("J", "n", "<C-d>zz", "centered scroll mapping was not loaded")
check_rhs(";", "n", ":", "command mapping was not loaded")
local quickfix_map = mapping("<Space>l", "n")
check(type(quickfix_map) == "table" and quickfix_map.rhs:match("ToggleQuickfix"), "quickfix mapping was not loaded")

local telescope_map = mapping("<Space>f", "n")
check(type(telescope_map) == "table" and telescope_map.callback ~= nil, "Telescope mapping was not loaded")
local oil_map = mapping("<Space>e", "n")
check(type(oil_map) == "table" and oil_map.callback ~= nil, "Oil mapping was not loaded")
check_rhs("f", "n", "<Plug>(leap-forward)", "Leap forward mapping was not loaded")
check_rhs("F", "n", "<Plug>(leap-backward)", "Leap backward mapping was not loaded")
check_rhs("de", "n", "<Plug>Dsurround", "source surround mapping was not loaded")
check_rhs("<Space>gs", "n", ":Git<CR>", "fugitive mapping was not loaded")
check(mapping("gc", "n").rhs ~= "", "vim-commentary was not loaded")

local modules = {
  "cmp",
  "cmp_nvim_lsp",
  "cmp_buffer",
  "cmp_path",
  "luasnip",
  "cmp_luasnip",
  "plenary",
  "telescope",
  "oil",
  "leap",
  "which-key",
  "nvim-web-devicons",
}
for _, name in ipairs(modules) do
  local ok, value = pcall(require, name)
  check(ok and value ~= nil, name .. " module did not load")
end

check(vim.fn.exists(":Git") == 2, "vim-fugitive command was not loaded")
check(vim.fn.exists(":Telescope") == 2, "Telescope command was not loaded")
check(vim.fn.exists(":Oil") == 2, "Oil command was not loaded")
check(vim.fn.exists(":WhichKey") == 2, "Which-Key command was not loaded")
check(vim.fn.exists(":Mason") == 0, "Mason must not be present")
check(vim.fn.exists(":PlugInstall") == 0, "a plugin download command must not be present")

check(vim.g.portable_cmp_initialized == 1, "completion setup did not initialize")
check(vim.g.portable_telescope_initialized == 1, "Telescope setup did not initialize")
check(vim.g.portable_oil_initialized == 1, "Oil setup did not initialize")
check(vim.g.portable_leap_initialized == 1, "Leap setup did not initialize")
check(vim.g.portable_which_key_initialized == 1, "Which-Key setup did not initialize")
check(vim.g.portable_lsp_initialized == 1, "LSP setup did not initialize")
check(vim.g.portable_lsp_server_boundary == "host-provided", "LSP server boundary is not explicit")

local cmp = require("cmp")
local source_names = {}
for _, source in ipairs(cmp.get_config().sources) do
  source_names[source.name] = true
end
for _, name in ipairs({ "nvim_lsp", "luasnip", "buffer", "path" }) do
  check(source_names[name], "completion source is missing: " .. name)
end
check(type(cmp.get_config().snippet.expand) == "function", "snippet expansion is not configured")

local expected_missing = {
  python = "missing:pyright-langserver,pylsp",
  c = "missing:clangd",
  cpp = "missing:clangd",
  lua = "missing:lua-language-server",
}
for filetype, expected in pairs(expected_missing) do
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].filetype = filetype
  check(vim.b[bufnr].portable_lsp_status == expected, filetype .. " LSP absence was not handled cleanly")
  check(#vim.lsp.get_clients({ bufnr = bufnr }) == 0, filetype .. " unexpectedly started an LSP client")
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

local lsp_autocmds = vim.api.nvim_get_autocmds({ group = "portable_native_lsp", event = "FileType" })
local lsp_patterns = {}
for _, autocmd in ipairs(lsp_autocmds) do
  lsp_patterns[autocmd.pattern] = true
end
check(#lsp_autocmds == 4, "native LSP FileType boundary was not registered exactly once per language")
for _, filetype in ipairs({ "python", "c", "cpp", "lua" }) do
  check(lsp_patterns[filetype], "native LSP boundary is missing filetype: " .. filetype)
end

local runtime_files = {
  "plugin/commentary.vim",
  "plugin/fugitive.vim",
  "plugin/surround.vim",
  "colors/base16-atelier-estuary.vim",
}
for _, name in ipairs(runtime_files) do
  check(#vim.api.nvim_get_runtime_file(name, false) > 0, name .. " is absent from runtimepath")
end

vim.api.nvim_out_write("Expanded Neovim runtime assertions passed.\n")
