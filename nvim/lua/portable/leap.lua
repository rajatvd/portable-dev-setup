local M = {}

function M.setup()
  vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)", { silent = true, desc = "Leap forward" })
  vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)", { silent = true, desc = "Leap backward" })
  vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)", { silent = true, desc = "Leap from window" })
  vim.keymap.set({ "n", "x", "o" }, "f", "<Plug>(leap-forward)", { silent = true, desc = "Leap forward" })
  vim.keymap.set({ "n", "x", "o" }, "F", "<Plug>(leap-backward)", { silent = true, desc = "Leap backward" })
  vim.keymap.set({ "n", "x", "o" }, "m", function()
    local lang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
    if require("portable.config").parser(lang) then require("leap-ast").leap() end
  end)
  vim.g.portable_leap_initialized = 1
end

return M
