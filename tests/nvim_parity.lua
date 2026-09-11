-- Isolated runtime regression checks. External/account callbacks below are explicitly instrumented.
local function check(value, message) if not value then error(message, 0) end end
local function map(key, mode) return vim.fn.maparg(key, mode or "n", false, true) end
local function fresh(ft)
  vim.cmd("enew!")
  if ft then vim.bo.filetype = ft end
  return vim.api.nvim_get_current_buf()
end
local config = require("portable.config")
check(not vim.o.expandtab and not vim.o.ignorecase, "source global indentation/search defaults")
check(vim.o.wrap and vim.o.showtabline == 2, "final wrap and airline tabline")
check(vim.g.airline_theme == "base16_atelier_estuary", "airline theme")
check(vim.api.nvim_get_hl(0, { name = "Normal" }).bg == 0x22221b, "actual Base16 palette")
for _, mode in ipairs({ "n", "v" }) do check(map("  y", mode).rhs == '"+y', "clipboard operator: " .. mode) end
check(map("Y  ").rhs == '"+Y', "clipboard line yank")
for _, key in ipairs({ "<Esc>", "jk", "kj" }) do
  local rhs = map(key, "t").rhs
  vim.bo.filetype = "fzf"
  check(vim.fn.eval(rhs) == vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "fzf terminal escape")
  vim.bo.filetype = ""
  check(vim.fn.eval(rhs) == vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "ordinary terminal escape")
end
for _, key in ipairs({ " r", "  R", " mb", " id", " sh", " ss", " s", " S", " ds", " ip", " sd", " sc", " gp", " b", " y", " /", " tl", " or", " os", " gi", " gc", " gP", " t", " T", " n", "  n", " sr", " su", " sx", "  T" }) do
  check(next(map(key)) ~= nil, "missing restored mapping: " .. key)
end
for _, command in ipairs({ "Files", "Buffers", "History", "Rg", "RG", "GGrep", "Make", "Copen", "Autoformat", "SendHere", "SendTo", "ThesisAI", "ARsyncDown", "ARsyncUp", "ARsyncUpDelete", "Octo", "Copilot", "Org", "MediaFiles", "PortableHealth", "TagbarToggle", "TestNearest", "TSPlaygroundToggle" }) do
  check(vim.fn.exists(":" .. command) == 2, "missing command: " .. command)
end
for _, module in ipairs({ "nvim-treesitter.configs", "nvim-treesitter.textobjects.select", "nvim-treesitter-playground", "leap-ast", "colorizer", "neodev", "luasnip-latex-snippets" }) do
  check(pcall(require, module), "missing dependency module: " .. module)
end
-- Opt packages must not run at startup, even when commands/bindings exist.
for _, module in ipairs({ "octo", "orgmode", "cmp_git" }) do check(package.loaded[module] == nil, "unconfigured account/file integration loaded: " .. module) end
check(vim.g.loaded_copilot == nil, "unconfigured Copilot loaded")
check(vim.fn.exists("#vimarsync") == 0, "implicit remote sync autocmds")
local ts = require("nvim-treesitter.configs")
check(vim.fn.exists("#NvimTreesitter-auto_install") == 0, "implicit parser downloads")
check(#ts.get_ensure_installed_parsers() == 0, "implicit parser provisioning")

-- Filetype scope, including a second buffer and a same-buffer filetype change.
local python = fresh("python")
check(vim.bo.expandtab, "stock Python indentation override")
check(map("m").buffer == 1 and map("m").rhs:find("Pythonsense", 1, true), "Python function motion")
check(map(" _").buffer == 1 and map(" mv").buffer == 1, "Python helpers must be buffer local")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "def first():", "    pass", "", "def second():", "    pass" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd("normal m")
check(vim.api.nvim_win_get_cursor(0)[1] == 4, "real Python next-function motion")

vim.bo.filetype = "text"
check(map(" mv").buffer ~= 1 and map("m").buffer ~= 1, "Python mapping leaked after filetype change")
for _, ft in ipairs({ "c", "cpp", "cuda", "c" }) do
  fresh(ft)
  for key, rhs in pairs({ md = ":Make!<CR>", mc = ":Make! clean<CR>", mr = ":Make! run<CR>", me = ":Copen<CR>" }) do
    check(map(" " .. key).buffer == 1 and map(" " .. key).rhs == rhs, "build map scope: " .. ft .. key)
  end
  if ft ~= "c" then check(vim.bo.commentstring == "// %s", "comment syntax: " .. ft) end
  vim.bo.filetype = "text"
  check(map(" md").buffer ~= 1, "build mapping leaked after filetype change: " .. ft .. " " .. vim.inspect(map(" md")))
end
for _, extension in ipairs({ "cu", "cuh" }) do
  vim.cmd("enew!")
  vim.cmd.edit(vim.env.HOME .. "/fixture." .. extension)
  check(vim.bo.filetype == "cuda" and vim.bo.commentstring == "// %s", "CUDA extension detection")
end
for _, ft in ipairs({ "tex", "markdown" }) do
  fresh(); vim.wo.wrap = false; vim.bo.filetype = ft
  check(vim.wo.wrap, "filetype wrap reassertion: " .. ft)
end
check(vim.g.vimtex_compiler_latexmk.out_dir == "build", "LaTeX output policy")
check(vim.g.vimtex_quickfix_mode == 0, "LaTeX quickfix policy")
check(vim.g.formatters_python[1] == "black" and vim.g.formatters_markdown[1] == "prettier", "formatter policy")
fresh()

-- Completion Tab must fall back after a word, not start a new menu.
local cmp, ls = require("cmp"), require("luasnip")
local visible, expandable, jumpable = cmp.visible, ls.expandable, ls.expand_or_jumpable
cmp.visible, ls.expandable, ls.expand_or_jumpable = function() return false end, function() return false end, function() return false end
vim.api.nvim_set_current_line("word")
vim.api.nvim_win_set_cursor(0, { 1, 3 })
local fell_back = false
cmp.get_config().mapping["<Tab>"].i(function() fell_back = true end)
check(fell_back, "Tab must fall back after text")
cmp.visible, ls.expandable, ls.expand_or_jumpable = visible, expandable, jumpable
check(cmp.get_config().mapping["<C-B>"].c ~= nil and cmp.get_config().mapping["<C-E>"].c ~= nil, "completion command-line modes")
local item = cmp.get_config().formatting.format({ source = { name = "git" } }, { kind = "Function" })
check(item.kind == "" and item.menu == "[Git]", "completion display policy")
ls.lsp_expand("hello ${1:world}")
check(vim.api.nvim_get_current_line():find("hello world", 1, true), "real snippet expansion")
ls.unlink_current()
fresh()

-- Actual custom buffer callbacks.
vim.api.nvim_set_current_line("    pass")
vim.api.nvim_win_set_cursor(0, { 1, 4 })
vim.fn.InsertBreakpoint()
check(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]:find("ipdb.set_trace()", 1, true), "breakpoint insertion")
check(vim.api.nvim_win_get_cursor(0)[1] == 2, "breakpoint cursor restoration")
vim.cmd('echom "synthetic message"')
vim.fn.MessagesToBuffer()
check(vim.bo.buftype == "nofile" and not vim.bo.buflisted and not vim.bo.swapfile, "messages scratch buffer")
check(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("synthetic message", 1, true), "message capture")
vim.cmd("close!")

-- Actual clipboard mapping with a synthetic provider (not clipboard hardware proof).
fresh()
local clipboard
vim.g.clipboard = {
  name = "fixture", cache_enabled = 0,
  copy = { ["+"] = function(lines) clipboard = lines end, ["*"] = function(lines) clipboard = lines end },
  paste = { ["+"] = function() return { clipboard or {}, "V" } end, ["*"] = function() return { clipboard or {}, "V" } end },
}
vim.api.nvim_set_current_line("clipboard fixture")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>  yy", true, false, true), "xt", false)
check(clipboard and clipboard[1] == "clipboard fixture", "clipboard key must invoke provider")
fresh()
vim.fn.setqflist({ { filename = "example.txt", lnum = 1, text = "example" } })
vim.cmd("copen")
check(map("<CR>").buffer == 1 and map("<CR>").rhs == "<CR>", "quickfix Enter override")
vim.cmd("cclose")

-- Real plugin contexts: inherited bindings stay inherited, rather than being duplicated in config.
require("oil").open(vim.env.HOME)
check(vim.wait(1000, function() return vim.bo.filetype == "oil" end), "Oil did not open")
check(not vim.wo.wrap and map("l").buffer == 1 and map("gx").buffer == 1 and map("g\\").buffer == 1, "Oil local/default behavior")
require("oil").close()
require("telescope.pickers").new({}, {
  prompt_title = "Synthetic picker",
  finder = require("telescope.finders").new_table({ results = { "one", "two" } }),
  sorter = require("telescope.config").values.generic_sorter({}),
}):find()
check(vim.wait(1000, function() return vim.bo.filetype == "TelescopePrompt" end), "Telescope did not open")
for _, key in ipairs({ "<Up>", "<Down>", "<PageUp>", "<PageDown>", "<Tab>", "<S-Tab>", "<M-q>" }) do
  check(map(key, "i").buffer == 1, "Telescope inherited key: " .. key)
end
require("telescope.actions").close(vim.api.nvim_get_current_buf())
vim.cmd("stopinsert")

-- Formatting callback proof is instrumented, not a connected language server.
local native, fallback = 0, 0
local format = vim.lsp.buf.format
vim.lsp.buf.format = function() native = native + 1 end
vim.api.nvim_create_user_command("Autoformat", function() fallback = fallback + 1 end, {})
for _, case in ipairs({ { "clangd", true, true }, { "texlab", true, false }, { "marksman", false, false }, { "pyright", false, nil } }) do
  local buf = fresh()
  require("portable.lsp").on_attach({ name = case[1], supports_method = function() return case[2] end }, buf)
  check(vim.fn.exists(":Format") == 2, "LSP buffer Format")
  local action = map(" a")
  if case[3] == nil then check(next(action) == nil, "pyright must not replace formatter binding") else action.callback() end
end
check(native == 1 and fallback == 2, "LSP / texlab / Autoformat dispatch")
vim.lsp.buf.format = format
fresh()

-- Dual Python server startup is instrumented; no executable/server is launched.
local start, executable_fn = vim.lsp.start, vim.fn.executable
local started = {}
vim.fn.executable = function(name)
  if name == "pyright-langserver" or name == "ruff" then return 1 end
  return executable_fn(name)
end
vim.lsp.start = function(spec)
  table.insert(started, spec)
  return #started
end
fresh("python")
check(#started == 2 and started[1].name == "pyright" and started[2].name == "ruff", "Python servers must be complementary")
check(started[1].settings.pyright.disableOrganizeImports and started[1].settings.python.analysis.ignore[1] == "*", "Python analysis policy")
vim.lsp.start, vim.fn.executable = start, executable_fn
fresh()

-- Source-compatible send_target fixture: shape and controls do not touch a real interpreter.
vim.cmd([[
function! ParityCapture(lines) dict
  let g:parity_sent = a:lines
endfunction
let g:send_target = {'send': function('ParityCapture')}
]])
vim.api.nvim_set_current_line("tensor")
require("portable.repl").shape("direct")
check(vim.g.parity_sent[1] == "(tensor).shape if hasattr(tensor, 'shape') else len(tensor)", "shape sender")
_G.SendCtrlD(); check(vim.g.parity_sent[1] == "\004", "REPL Ctrl-D")
_G.SendCtrlC(); check(vim.g.parity_sent[1] == "\003", "REPL Ctrl-C")
vim.g.send_target = nil

-- Real terminal creation/reuse in isolated HOME; no shell startup files or REPL accounts.
fresh()
vim.fn.TermToggle(55)
local terminal, window = vim.g.term_buf, vim.g.term_win
check(vim.bo.buftype == "terminal" and terminal > 0, "first toggle must create a terminal")
check(not vim.wo.number and not vim.wo.relativenumber, "terminal local options")
vim.cmd("SendHere ipy")
check(vim.g.send_target.channel == vim.b.terminal_job_id and vim.g.send_target["end"] == "\27[201~\r\r\r", "terminal target selection and IPython framing")
vim.fn.TermToggle(55)
check(not vim.api.nvim_win_is_valid(window), "terminal hide")
vim.fn.TermToggle(55)
check(vim.g.term_buf == terminal, "terminal buffer reuse")
vim.fn.jobstop(vim.b.terminal_job_id)
vim.cmd("close!")
vim.api.nvim_buf_delete(terminal, { force = true })
vim.g.send_target = nil

-- Diagnostics must be visible and no external process may run when unconfigured.
local notifications, effects = {}, 0
local notify, system = vim.notify, vim.system
vim.notify = function(message) table.insert(notifications, message) end
vim.system = function() effects = effects + 1; error("unexpected external action") end
require("portable.workflows").current_event()
require("portable.workflows").render()
require("portable.workflows").remote("up")
require("portable.workflows").blocks("")
require("portable.workflows").tasks(false)
require("portable.repl").start()
vim.cmd("Octo issue list"); vim.cmd("Copilot status"); vim.cmd("Rg")
check(effects == 0 and #notifications >= 9, "unconfigured integrations must diagnose without effects")

-- Configured provider and argument-boundary proof, using synthetic data only.
config.options.tasks = { enabled = true, items = function() return { "fixture.txt:2:example", "", "broken", "second.txt:3:second" } end,
  markdown = function() return "# Tasks\n- example" end }
require("portable.workflows").quickfix(require("portable.workflows").tasks(false))
check(#vim.fn.getqflist() == 2, "task list should skip malformed/empty items")
vim.cmd("cclose")
require("portable.workflows").task_float()
check(vim.bo.readonly and not vim.bo.modifiable and vim.wo.foldmethod == "indent", "task floating view")
vim.cmd("close!")
local executable = config.executable
config.executable = function() return true end
config.options.remote_sync = { enabled = true, local_path = "fixture source", remote_path = "example.invalid:fixture destination" }
local argv
vim.system = function(args) argv = args; return {} end
require("portable.workflows").remote("upDelete")
check(argv[3] == "--delete" and argv[4] == "--" and argv[5] == "fixture source/" and argv[6] == "example.invalid:fixture destination/", "rsync argv boundary")
config.options.calendar = { enabled = true, format_timestamp = function(epoch) return epoch end }
local now = os.time()
local rounded = require("portable.workflows").timestamp(3600)
check(rounded >= now + 3600 and rounded <= now + 4500 and rounded % 900 == 0, "calendar quarter-hour rounding")

-- Account setup tables and Ctrl-J precedence: pack/network setup is deliberately stubbed.
local cmd, load_extension = vim.cmd, require("telescope").load_extension
local loaded_octo, loaded_git = package.loaded.octo, package.loaded.cmp_git
local octo_options
package.loaded.octo = { setup = function(options) octo_options = options end }
package.loaded.cmp_git = { setup = function() end }
vim.cmd = function(text) check(text:find("packadd", 1, true), "unexpected instrumented command") end
require("telescope").load_extension = function() end
config.options.octo, config.options.copilot = { enabled = true }, { enabled = true }
require("portable.integrations").setup()
check(octo_options.mappings.issue.close_issue.lhs == "<leader>ic", "Octo issue actions")
check(octo_options.mappings.pull_request.merge_pr.lhs == "<leader>pm", "Octo review actions")
check(map("<C-j>", "i").expr == 1 and map("<C-j>", "i").rhs:find("copilot#Accept", 1, true), "Copilot Ctrl-J precedence")
vim.cmd, require("telescope").load_extension = cmd, load_extension
package.loaded.octo, package.loaded.cmp_git = loaded_octo, loaded_git
vim.notify, vim.system, config.executable = notify, system, executable
config.options = {}
vim.api.nvim_out_write("Neovim parity regressions passed (account/process callbacks instrumented; terminal and buffers real).\n")
