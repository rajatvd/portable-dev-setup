local M = {}
local config = require("portable.config")

function M.run(name, args, bang)
  if not config.executable("fzf") then return end
  local output = vim.fn.system({ "fzf", "--version" })
  local major, minor = output:match("^(%d+)%.(%d+)")
  if not major or tonumber(major) == 0 and tonumber(minor) < 56 then
    vim.notify("Fuzzy search needs host fzf >= 0.56.0; no binary will be downloaded", vim.log.levels.WARN)
    return
  end
  if (name == "Files" or name == "Rg" or name == "RG") and not config.executable("rg") then return end
  if name == "GGrep" and not config.executable("git") then return end
  if not M.loaded then
    vim.cmd("packadd fzf | packadd fzf.vim")
    vim.cmd.source(vim.fn.stdpath("config") .. "/plug-configs/fzf.vim")
    M.loaded = true
  end
  -- User command text is passed as command arguments, never evaluated as Lua or shell code.
  vim.api.nvim_cmd({ cmd = name, args = args ~= "" and { args } or {}, bang = bang }, {})
end

function M.setup()
  for _, name in ipairs({ "Files", "Buffers", "History", "Rg", "RG", "GGrep" }) do
    vim.api.nvim_create_user_command(name, function(opts) M.run(name, opts.args, opts.bang) end, { nargs = "*", bang = true })
  end
  vim.keymap.set({ "n", "v", "o" }, "<leader>b", "<Cmd>Buffers<CR>")
  vim.keymap.set({ "n", "v", "o" }, "<leader>y", "<Cmd>History<CR>")
  vim.keymap.set("n", "<leader>/", "<Cmd>Rg<CR>")
end
return M
