local M = {}

function M.setup()
  require("nvim-web-devicons").setup({ default = true })
  require("portable.completion").setup()
  require("portable.telescope").setup()
  require("portable.oil").setup()
  require("portable.leap").setup()
  require("portable.which_key").setup()
  require("portable.lsp").setup()
  vim.g.portable_dev_setup_lua_loaded = 1
end

return M
