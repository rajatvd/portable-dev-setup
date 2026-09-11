local M = {}

M.server_specs = {
  python = {
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
    candidates = {
      { name = "pyright", cmd = { "pyright-langserver", "--stdio" }, settings = {
        pyright = { disableOrganizeImports = true }, python = { analysis = { ignore = { "*" } } },
      } },
      { name = "ruff", cmd = { "ruff", "server" } },
    },
  },
  c = {
    root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
    candidates = {
      { name = "clangd", cmd = { "clangd" } },
    },
  },
  cpp = {
    root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
    candidates = {
      { name = "clangd", cmd = { "clangd" } },
    },
  },
  lua = {
    root_markers = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".git" },
    candidates = {
      {
        name = "lua_ls",
        cmd = { "lua-language-server" },
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      },
    },
  },
}

M.server_specs.cuda = M.server_specs.cpp
for ft, spec in pairs({
  tex = { "texlab", { "texlab" }, { ".latexmkrc", "latexmkrc", ".git" } },
  plaintex = { "texlab", { "texlab" }, { ".latexmkrc", "latexmkrc", ".git" } },
  bib = { "texlab", { "texlab" }, { ".latexmkrc", "latexmkrc", ".git" } },
  vim = { "vimls", { "vim-language-server", "--stdio" }, { ".git" } },
  markdown = { "marksman", { "marksman", "server" }, { ".marksman.toml", ".git" } },
  html = { "html", { "vscode-html-language-server", "--stdio" }, { "package.json", ".git" } },
  mojo = { "mojo", { "mojo-lsp-server" }, { "Mojo.toml", "package.mojo", ".git" } },
}) do
  M.server_specs[ft] = { root_markers = spec[3], candidates = { { name = spec[1], cmd = spec[2] } } }
end

local function buffer_map(bufnr, keys, action, description)
  vim.keymap.set("n", keys, action, {
    buffer = bufnr,
    desc = "LSP: " .. description,
    silent = true,
  })
end

function M.on_attach(client, bufnr)
  buffer_map(bufnr, "<leader>R", vim.lsp.buf.rename, "Rename")
  buffer_map(bufnr, "<leader><leader>ca", vim.lsp.buf.code_action, "Code action")
  buffer_map(bufnr, "gd", vim.lsp.buf.definition, "Goto definition")
  buffer_map(bufnr, "gr", require("telescope.builtin").lsp_references, "Goto references")
  buffer_map(bufnr, "gI", vim.lsp.buf.implementation, "Goto implementation")
  buffer_map(bufnr, "<leader>D", vim.lsp.buf.type_definition, "Type definition")
  buffer_map(bufnr, "<leader>Ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace symbols")
  buffer_map(bufnr, "<leader>?", vim.lsp.buf.hover, "Hover documentation")
  buffer_map(bufnr, "gD", vim.lsp.buf.declaration, "Goto declaration")
  buffer_map(bufnr, "<leader>Wa", vim.lsp.buf.add_workspace_folder, "Workspace add folder")
  buffer_map(bufnr, "<leader>Wr", vim.lsp.buf.remove_workspace_folder, "Workspace remove folder")
  buffer_map(bufnr, "<leader>Wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, "Workspace list folders")

  pcall(vim.api.nvim_buf_create_user_command, bufnr, "Format", function()
    vim.lsp.buf.format({ bufnr = bufnr })
  end, { desc = "Format current buffer with LSP" })

  if client.name ~= "pyright" then
    buffer_map(bufnr, "<leader>a", function()
      if client.name ~= "texlab" and client.supports_method("textDocument/formatting") then
        vim.lsp.buf.format({ bufnr = bufnr })
      else
        vim.api.nvim_buf_call(bufnr, function() vim.cmd("Autoformat") end)
      end
    end, "Format buffer")
  end
end

local function project_root(bufnr, markers)
  local root = vim.fs.root(bufnr, markers)
  if root then
    return root
  end
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename ~= "" then
    return vim.fs.dirname(filename)
  end
  return vim.fn.getcwd()
end

local function start_for_buffer(args, capabilities)
  local spec = M.server_specs[vim.bo[args.buf].filetype]
  if not spec then
    return
  end

  local missing, started = {}, {}
  for _, candidate in ipairs(spec.candidates) do
    if vim.fn.executable(candidate.cmd[1]) == 1 then
      local id = vim.lsp.start({
        name = candidate.name,
        cmd = candidate.cmd,
        root_dir = project_root(args.buf, spec.root_markers),
        capabilities = capabilities,
        settings = vim.deepcopy(candidate.settings or {}),
        before_init = candidate.name == "lua_ls" and require("neodev.lsp").before_init or nil,
        on_attach = M.on_attach,
      }, { bufnr = args.buf, silent = true })
      table.insert(started, (id and "started:" or "failed:") .. candidate.name)
    else
      table.insert(missing, candidate.cmd[1])
    end
  end
  if #missing > 0 then table.insert(started, "missing:" .. table.concat(missing, ",")) end
  vim.b[args.buf].portable_lsp_status = table.concat(started, ";")
end

function M.setup()
  require("neodev").setup({ lspconfig = false })
  local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }
  for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, {
      texthl = sign.name,
      text = sign.text,
      numhl = "",
    })
  end

  vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
      focusable = true,
      style = "minimal",
      source = "always",
      header = "",
      prefix = "",
    },
  })

  local capabilities = require("cmp_nvim_lsp").default_capabilities(
    vim.lsp.protocol.make_client_capabilities()
  )

  local group = vim.api.nvim_create_augroup("portable_native_lsp", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = vim.tbl_keys(M.server_specs),
    callback = function(args)
      start_for_buffer(args, capabilities)
    end,
  })

  vim.g.portable_lsp_initialized = 1
  vim.g.portable_lsp_server_boundary = "host-provided"
end

return M
