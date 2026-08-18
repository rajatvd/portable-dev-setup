local M = {}

function M.setup()
  require("which-key").setup({})
  vim.g.portable_which_key_initialized = 1
end

return M
