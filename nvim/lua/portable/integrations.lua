local M = {}
local config = require("portable.config")

function M.org()
  if M.org_ready then return true end
  local cfg = config.need("org", { "agenda_files", "notes_file" })
  if not cfg then return false end
  if not config.parser("org") then return false end
  vim.cmd("packadd orgmode")
  -- Upstream setup installs a grammar. Preflight its exact guard instead: never let setup download.
  local installer = require("orgmode.utils.treesitter.install")
  if installer.outdated() then
    vim.notify("Org needs a preprovisioned parser >= 1.3.4; automatic updates are disabled", vim.log.levels.WARN)
    return false
  end
  require("orgmode").setup({
    org_agenda_files = cfg.agenda_files,
    org_default_notes_file = cfg.notes_file,
    org_capture_templates = cfg.capture_templates or { t = { description = "Task", template = "* TODO %?\n  %u" } },
    mappings = { org = { org_refile = false, org_meta_return = false, org_insert_heading_respect_content = "<leader><CR>" } },
    org_blank_before_new_entry = { heading = false, plain_list_item = false },
  })
  vim.cmd("packadd org-bullets.nvim | packadd telescope-orgmode.nvim")
  require("org-bullets").setup()
  require("telescope").load_extension("orgmode")
  M.org_ready = true
  return true
end

function M.setup()
  for _, spec in ipairs({ { "<leader>oa", "agenda.prompt" }, { "<leader>oc", "capture.prompt" } }) do
    vim.keymap.set("n", spec[1], function() if M.org() then require("orgmode").action(spec[2]) end end)
  end
  for _, spec in ipairs({ { "<leader>or", "refile_heading" }, { "<leader>os", "search_headings" } }) do
    vim.keymap.set("n", spec[1], function()
      if M.org() then require("telescope").extensions.orgmode[spec[2]]() end
    end)
  end
  vim.api.nvim_create_user_command("Org", function(opts)
    if M.org() then require("orgmode").action(opts.args ~= "" and opts.args or "agenda.prompt") end
  end, { nargs = "?" })
  if config.enabled("org") then M.org() end

  for _, name in ipairs({ "Octo", "Copilot" }) do
    vim.api.nvim_create_user_command(name, function()
      if config.need(name:lower()) and config.executable(name == "Octo" and "gh" or "node") then
        vim.notify(name .. ": restart Neovim after providing its dependency", vim.log.levels.WARN)
      end
    end, { nargs = "*", bang = true })
  end
  vim.keymap.set("n", "<leader>gi", "<Cmd>Octo issue list<CR>")
  vim.keymap.set("n", "<leader>gc", "<Cmd>Octo issue create<CR>")
  vim.keymap.set("n", "<leader>gP", "<Cmd>Octo pr list<CR>")
  if config.enabled("octo") and config.executable("gh") then
    vim.api.nvim_del_user_command("Octo")
    vim.cmd("packadd octo.nvim")
    require("octo").setup(vim.tbl_deep_extend("force", require("portable.octo_options"), config.options.octo.options or {}))
    require("telescope").load_extension("octo")
  end
  if config.enabled("git_completion") and config.executable("git") then
    vim.cmd("packadd cmp-git")
    require("cmp_git").setup(vim.tbl_deep_extend("force", {
      github = { hosts = {}, issues = { state = "all" } },
    }, config.options.git_completion.options or {}))
  end
  if config.enabled("copilot") and config.executable("node") then
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_filetypes = config.options.copilot.filetypes or { markdown = true }
    vim.api.nvim_del_user_command("Copilot")
    vim.cmd("packadd copilot.vim")
    -- Source precedence: explicitly enabled Copilot owns insert Ctrl-J, not cmp.
    require("cmp").setup({ mapping = { ["<C-j>"] = require("cmp").config.disable } })
    vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false })
  end

  vim.api.nvim_create_user_command("MediaFiles", function()
    if not config.executable("fd") or not config.executable("chafa") then return end
    require("telescope").extensions.media_files.media_files()
  end, {})
  for _, name in ipairs({ "InstantMarkdownPreview", "InstantMarkdownStop" }) do
    vim.api.nvim_create_user_command(name, function()
      if not config.need("markdown_preview") or not config.executable("instant-markdown-d") then return end
      if vim.bo.filetype ~= "markdown" then
        vim.notify("Markdown preview requires a Markdown buffer", vim.log.levels.WARN)
        return
      end
      vim.cmd("packadd vim-instant-markdown")
      -- packadd does not replay FileType for the buffer that requested activation.
      vim.cmd("runtime! ftplugin/markdown/instant-markdown.vim")
      vim.cmd(name)
    end, {})
  end
  if config.enabled("notebooks") then
    vim.g.jupytext_fmt = "py"
    if config.executable("jupytext") then vim.cmd("packadd jupytext.vim") end
    vim.cmd("packadd jupyter_ascending.vim")
  end
end
return M
