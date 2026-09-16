-- Requires explicitly provisioned Python/Org parsers and synthetic local config from prove-runtime.sh.
local function check(value, message) if not value then error(message, 0) end end
check(require("portable.integrations").org_ready, "configured Org did not initialize")
check(package.loaded.orgmode ~= nil, "Org module unavailable")
check(vim.g.loaded_copilot == nil and package.loaded.octo == nil, "unconfigured account effect in optional proof")
local home = vim.env.HOME
vim.cmd.edit(home .. "/fixture.py")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "class Demo:", "    def animate(self, size=3):", "        return size" })
vim.bo.modified = false
vim.treesitter.get_parser(0, "python"):parse()
check(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, "real Python highlighting")
check(vim.fn.maparg("af", "o", false, true).buffer == 1, "parser textobject activation")
vim.api.nvim_win_set_cursor(0, { 3, 8 })
vim.cmd([[
function! OptionalCapture(lines) dict
  let g:optional_sent = a:lines
endfunction
let g:send_target = {'send': function('OptionalCapture')}
]])
require("portable.repl").defaults()
check(vim.g.optional_sent[1] == "size=3", "default argument extraction from real AST")
local config = require("portable.config")
vim.g.send_target = nil
-- Real file-backed marked-block scan; explicit synthetic root/markers, no default private discovery.
config.options.blocks = { enabled = true, begin_marker = "BEGIN-FIXTURE", end_marker = "END-FIXTURE" }
vim.fn.writefile({ "BEGIN-FIXTURE", "example block", "END-FIXTURE", "BEGIN-FIXTURE" }, home .. "/fixture.tex")
require("portable.workflows").blocks(home)
local qf = vim.fn.getqflist()
check(#qf == 2 and qf[1].lnum == 1 and qf[1].end_lnum == 3 and qf[2].text == "UNCLOSED block", "closed/unclosed marked-block navigation")
vim.cmd("cclose")
-- Real Org parser/API and navigation against a synthetic, explicitly configured calendar.
require("portable.workflows").current_event()
check(vim.api.nvim_buf_get_name(0) == home .. "/fixture.org", "calendar file navigation")
check(vim.api.nvim_win_get_cursor(0)[1] == 7, "current-event position")
vim.cmd("stopinsert")
check(vim.fn.maparg(" <CR>", "n", false, true).buffer == 1, "Org heading mapping")
check(require("telescope").extensions.orgmode.search_headings ~= nil, "Org picker extension")
local sources = {}
for _, source in ipairs(require("cmp").get_config().sources) do sources[source.name] = true end
check(sources.orgmode, "Org completion source")
vim.api.nvim_out_write("Provisioned Python/Org parser and local-provider proof passed.\n")
