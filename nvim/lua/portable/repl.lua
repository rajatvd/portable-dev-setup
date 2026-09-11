local M = {}
local config = require("portable.config")

function M.send(lines)
  if vim.g.send_target == nil then
    vim.notify("Target terminal not set. Run :SendHere or :SendTo first.", vim.log.levels.WARN)
    return false
  end
  -- Retain the source's public send_target protocol for host-supplied targets.
  vim.g.portable_send_lines = lines
  local ok = pcall(vim.cmd, "call g:send_target.send(g:portable_send_lines)")
  vim.g.portable_send_lines = nil
  if not ok then vim.notify("Terminal send failed; select a live target with :SendHere", vim.log.levels.ERROR) end
  return ok
end

function M.selection(mode)
  local visual = mode == "v" or mode == "V" or mode == "\22"
  local first = vim.api.nvim_buf_get_mark(0, visual and "<" or "[")
  local last = vim.api.nvim_buf_get_mark(0, visual and ">" or "]")
  if first[1] == 0 or last[1] == 0 then return {} end
  if mode == "line" or mode == "V" then
    return vim.api.nvim_buf_get_lines(0, first[1] - 1, last[1], false)
  end
  local endline = vim.api.nvim_buf_get_lines(0, last[1] - 1, last[1], false)[1] or ""
  return vim.api.nvim_buf_get_text(0, first[1] - 1, first[2], last[1] - 1, math.min(last[2] + 1, #endline), {})
end

function M.shape(mode)
  local lines = mode == "direct" and { vim.api.nvim_get_current_line() } or M.selection(mode)
  local expression = table.concat(lines, "\n")
  return M.send({ "(" .. expression .. ").shape if hasattr(" .. expression .. ", 'shape') else len(" .. expression .. ")" })
end

function M.defaults()
  if not config.parser("python") then return end
  local node = vim.treesitter.get_node()
  while node and node:type() ~= "function_definition" do node = node:parent() end
  local lines = {}
  if node then
    for child in node:iter_children() do
      if child:type() == "parameters" then
        for parameter in child:iter_children() do
          if parameter:type() == "default_parameter" then
            table.insert(lines, vim.treesitter.get_node_text(parameter, 0))
          end
        end
      end
    end
  end
  if #lines == 0 then vim.notify("No default arguments found."); return end
  M.send(lines)
end

function M.start()
  local cfg = config.need("repl", { "command" })
  if not cfg then return end
  if type(cfg.command) ~= "table" or not config.executable(cfg.command[1]) then return end
  local original = vim.api.nvim_get_current_win()
  vim.cmd("botright vnew")
  local job = vim.fn.termopen(cfg.command, { detach = 0 })
  if job <= 0 then vim.notify("REPL process failed to start", vim.log.levels.ERROR); return end
  vim.g.term_buf, vim.g.term_win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.cmd("setlocal nonumber norelativenumber signcolumn=no | SendHere ipy")
  vim.api.nvim_set_current_win(original)
  if cfg.startup_lines and #cfg.startup_lines > 0 then
    -- No guessed activation alias, session name, plotting backend or magics.
    vim.defer_fn(function() M.send(cfg.startup_lines) end, cfg.startup_delay_ms or 500)
  end
end

function M.setup()
  _G.Send_Default_Arguments_Python = M.defaults
  _G.StartIPythonRepl = M.start
  _G.GetCurrentVenv = function() return vim.env.VIRTUAL_ENV end
  _G.GetCurrentCondaEnv = function() return vim.env.CONDA_DEFAULT_ENV end
  _G.SendCtrlD = function() M.send({ "\004" }) end
  _G.SendCtrlC = function() M.send({ "\003" }) end
  vim.keymap.set("n", "<leader>ip", M.start)
  vim.keymap.set("n", "<leader>ds", M.defaults)
  vim.keymap.set("n", "<leader>sd", _G.SendCtrlD)
  vim.keymap.set("n", "<leader>sc", _G.SendCtrlC)
end
return M
