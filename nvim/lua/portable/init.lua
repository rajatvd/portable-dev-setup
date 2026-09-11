local M = {}
function M.setup()
  require("nvim-web-devicons").setup({ default = true })
  require("portable.oil").setup()
  require("portable.completion").setup()
  require("portable.lsp").setup()
  require("portable.telescope").setup()
  require("portable.fuzzy").setup()
  require("portable.leap").setup()
  require("portable.treesitter").setup()
  require("portable.which_key").setup()
  require("portable.integrations").setup()
  require("colorizer").setup()
  require("portable.repl").setup()
  require("portable.workflows").setup()
  vim.g.portable_dev_setup_lua_loaded = 1
end
return M
