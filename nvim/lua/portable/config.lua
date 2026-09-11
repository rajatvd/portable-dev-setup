local M = { options = {} }

function M.load()
  local path = vim.env.NVIM_PORTABLE_LOCAL
  if not path or path == "" then path = vim.fn.stdpath("config"):gsub("/nvim$", "") .. "/nvim-local.lua" end
  if vim.fn.filereadable(path) == 1 then
    local ok, options = pcall(dofile, path)
    if ok and type(options) == "table" then
      M.options = options
    else
      -- Do not echo local source, paths, tokens or exception text.
      vim.notify("Neovim local config must return a table; configuration was not enabled", vim.log.levels.ERROR)
    end
  elseif vim.env.NVIM_PORTABLE_LOCAL and vim.env.NVIM_PORTABLE_LOCAL ~= "" then
    vim.notify("NVIM_PORTABLE_LOCAL is not readable; integrations remain disabled", vim.log.levels.WARN)
  end
  if M.options.parser_path then vim.opt.runtimepath:prepend(M.options.parser_path) end
  vim.api.nvim_create_user_command("PortableHealth", function()
    local lines = { "Optional integrations (configure nvim-local.lua; no values displayed):" }
    for _, name in ipairs({ "copilot", "octo", "git_completion", "org", "calendar", "repl", "tasks", "blocks", "media", "remote_sync", "notebooks", "markdown_preview" }) do
      table.insert(lines, name .. ": " .. (M.enabled(name) and "enabled" or "not configured"))
    end
    table.insert(lines, "Host dependencies (never installed by startup):")
    for _, exe in ipairs({ "fzf", "rg", "ctags", "clangd", "pyright-langserver", "ruff", "lua-language-server", "texlab", "vim-language-server", "marksman", "vscode-html-language-server", "mojo-lsp-server", "latexmk", "latexindent", "black", "prettier", "doq", "make", "gh", "node" }) do
      table.insert(lines, exe .. ": " .. (vim.fn.executable(exe) == 1 and "available" or "missing dependency"))
    end
    for _, lang in ipairs({ "c", "lua", "vim", "vimdoc", "query", "python", "latex", "markdown", "org" }) do
      local ok = pcall(vim.treesitter.language.add, lang)
      table.insert(lines, "parser " .. lang .. ": " .. (ok and "available" or "missing dependency"))
    end
    vim.api.nvim_echo({ { table.concat(lines, "\n") } }, true, {})
  end, {})
end

function M.enabled(name)
  return type(M.options[name]) == "table" and M.options[name].enabled == true
end

function M.need(name, keys)
  if not M.enabled(name) then
    vim.notify(name .. ": configure enabled=true in nvim-local.lua before use", vim.log.levels.WARN)
    return nil
  end
  local cfg = M.options[name]
  for _, key in ipairs(keys or {}) do
    if cfg[key] == nil or cfg[key] == "" then
      vim.notify(name .. ": configure " .. key .. " in nvim-local.lua", vim.log.levels.WARN)
      return nil
    end
  end
  return cfg
end

function M.executable(name)
  if vim.fn.executable(name) == 1 then return true end
  vim.notify("Missing host dependency: " .. name .. " (not installed automatically)", vim.log.levels.WARN)
  return false
end

function M.parser(lang)
  if pcall(vim.treesitter.language.add, lang) then return true end
  vim.notify("Missing " .. lang .. " parser: provision it on runtimepath or configure parser_path; no automatic installation", vim.log.levels.WARN)
  return false
end

return M
