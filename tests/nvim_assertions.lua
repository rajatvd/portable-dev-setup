local function check(condition, message)
  if not condition then
    error(message, 0)
  end
end

check(vim.g.portable_dev_setup_loaded == 1, "init.vim did not finish")
check(vim.o.number, "number setting was not loaded")
check(vim.o.relativenumber, "relativenumber setting was not loaded")
check(vim.o.shiftwidth == 4, "shiftwidth setting was not loaded")
check(vim.o.undofile, "undo setting was not loaded")
check(vim.g.mapleader == " ", "leader was not loaded")

local save_map = vim.fn.maparg("<Space>w", "n", false, true)
check(type(save_map) == "table" and save_map.rhs == ":write<CR>", "save mapping was not loaded")
check(vim.fn.exists(":Git") == 2, "vim-fugitive was not loaded")
check(vim.fn.maparg("gc", "n") ~= "", "vim-commentary was not loaded")
check(vim.fn.maparg("ys", "n") ~= "", "vim-surround was not loaded")

local runtime_files = {
  "plugin/commentary.vim",
  "plugin/fugitive.vim",
  "plugin/surround.vim",
}
for _, name in ipairs(runtime_files) do
  check(#vim.api.nvim_get_runtime_file(name, false) > 0, name .. " is absent from runtimepath")
end

vim.api.nvim_out_write("Neovim runtime assertions passed.\n")
