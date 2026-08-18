local M = {}

M.server_specs = {
  python = {
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
    candidates = {
      { name = "pyright", cmd = { "pyright-langserver", "--stdio" } },
      { name = "pylsp", cmd = { "pylsp" } },
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

local function buffer_map(bufnr, keys, action, description)
  vim.keymap.set("n", keys, action, {
    buffer = bufnr,
    desc = "LSP: " .. description,
    silent = true,
  })
end

local function on_attach(client, bufnr)
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

  if client.supports_method("textDocument/formatting") then
    buffer_map(bufnr, "<leader>a", function()
      vim.lsp.buf.format({ bufnr = bufnr })
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

  local missing = {}
  local selected
  for _, candidate in ipairs(spec.candidates) do
    if vim.fn.executable(candidate.cmd[1]) == 1 then
      selected = candidate
      break
    end
    table.insert(missing, candidate.cmd[1])
  end

  if not selected then
    vim.b[args.buf].portable_lsp_status = "missing:" .. table.concat(missing, ",")
    return
  end

  local client_id = vim.lsp.start({
    name = selected.name,
    cmd = selected.cmd,
    root_dir = project_root(args.buf, spec.root_markers),
    capabilities = capabilities,
    settings = selected.settings,
    on_attach = on_attach,
  }, {
    bufnr = args.buf,
    silent = true,
  })

  if client_id then
    vim.b[args.buf].portable_lsp_status = "started:" .. selected.name
  else
    vim.b[args.buf].portable_lsp_status = "failed:" .. selected.name
  end
end

function M.setup()
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
    pattern = { "python", "c", "cpp", "lua" },
    callback = function(args)
      start_for_buffer(args, capabilities)
    end,
  })

  vim.g.portable_lsp_initialized = 1
  vim.g.portable_lsp_server_boundary = "host-provided"
end

return M
