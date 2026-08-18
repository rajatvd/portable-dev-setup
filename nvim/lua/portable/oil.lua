local M = {}

function M.setup()
  local oil = require("oil")

  oil.setup({
    default_file_explorer = true,
    columns = { "icon" },
    buf_options = {
      buflisted = false,
      bufhidden = "hide",
    },
    win_options = {
      wrap = false,
      signcolumn = "no",
      cursorcolumn = false,
      foldcolumn = "0",
      spell = false,
      list = false,
      conceallevel = 3,
      concealcursor = "nvic",
    },
    delete_to_trash = false,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    cleanup_delay_ms = 2000,
    lsp_file_methods = {
      timeout_ms = 1000,
      autosave_changes = false,
    },
    constrain_cursor = "editable",
    experimental_watch_for_changes = false,
    keymaps = {
      ["g?"] = "actions.show_help",
      ["l"] = "actions.select",
      ["<C-s>"] = "actions.select_vsplit",
      ["<C-h>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["<C-p>"] = "actions.preview",
      ["<C-c>"] = "actions.close",
      ["<C-l>"] = "actions.refresh",
      ["h"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["gs"] = "actions.change_sort",
      ["g."] = "actions.toggle_hidden",
    },
    use_default_keymaps = true,
    view_options = {
      show_hidden = true,
      is_hidden_file = function(name)
        return vim.startswith(name, ".") and not vim.startswith(name, "..")
      end,
      is_always_hidden = function()
        return false
      end,
      natural_order = true,
      sort = {
        { "type", "asc" },
        { "name", "asc" },
      },
    },
    float = {
      padding = 2,
      border = "rounded",
    },
    preview = {
      border = "rounded",
    },
    progress = {
      border = "rounded",
    },
    keymaps_help = {
      border = "rounded",
    },
  })

  vim.keymap.set("n", "<leader>e", oil.open, {
    silent = true,
    desc = "Open parent directory",
  })
  vim.g.portable_oil_initialized = 1
end

return M
