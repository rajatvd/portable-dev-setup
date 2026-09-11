local M = {}
function M.setup()
  if vim.b.portable_build_maps then return end
  vim.b.portable_build_maps = true
  local undo = {}
  if vim.b.undo_ftplugin and vim.b.undo_ftplugin ~= "" then table.insert(undo, vim.b.undo_ftplugin) end
  for key, command in pairs({ md = "Make!", mc = "Make! clean", mr = "Make! run", me = "Copen" }) do
    vim.keymap.set("n", "<leader>" .. key, ":" .. command .. "<CR>", { buffer = true, silent = true })
    table.insert(undo, "silent! execute 'nunmap <buffer> <leader>" .. key .. "'")
  end
  table.insert(undo, "unlet! b:portable_build_maps")
  vim.b.undo_ftplugin = table.concat(undo, " | ")
end
return M
