local M = {}
local config = require("portable.config")

function M.tasks(markdown)
  local cfg = config.need("tasks", { markdown and "markdown" or "items" })
  if not cfg then return nil end
  return cfg[markdown and "markdown" or "items"]()
end

function M.quickfix(items)
  if not items then return end
  local result = {}
  for _, item in ipairs(items) do
    if type(item) == "table" then
      table.insert(result, item)
    elseif item ~= "" then
      local file, line, text = item:match("^(.-):(%d+):(.+)$")
      if file then table.insert(result, { filename = vim.fn.expand(file), lnum = tonumber(line), text = text }) end
    end
  end
  vim.fn.setqflist({}, "r", { title = "Tasks", items = result })
  vim.cmd("copen")
end

function M.task_float()
  local text = M.tasks(true)
  if not text then return end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].shiftwidth, vim.bo[buf].expandtab = 2, true
  vim.bo[buf].filetype = "none"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))
  vim.bo[buf].modifiable, vim.bo[buf].readonly = false, true
  local width, height = math.max(1, math.ceil(vim.o.columns * 0.9)), math.max(1, math.ceil(vim.o.lines * 0.6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = width, height = height,
    row = math.ceil((vim.o.lines - height) / 2), col = math.ceil((vim.o.columns - width) / 2),
    style = "minimal", border = "rounded",
  })
  vim.wo[win].foldmethod, vim.wo[win].foldenable, vim.wo[win].foldlevel = "indent", true, 1
end

function M.blocks(root)
  local cfg = config.need("blocks", { "begin_marker", "end_marker" })
  if not cfg then return end
  root = root ~= "" and root or cfg.root
  if not root or vim.fn.isdirectory(vim.fn.expand(root)) ~= 1 then
    vim.notify("ThesisAI needs an explicit directory argument or blocks.root", vim.log.levels.WARN)
    return
  end
  if not config.executable("rg") then return end
  local argv = { "rg", "--files", "--glob", cfg.glob or "**/*.tex" }
  for _, glob in ipairs(cfg.exclude or { "**/build/**", "**/reports/**" }) do
    vim.list_extend(argv, { "--glob", "!" .. glob })
  end
  vim.list_extend(argv, { "--", vim.fn.expand(root) })
  local files = vim.fn.systemlist(argv)
  if vim.v.shell_error > 1 then vim.notify("Marked-block file scan failed", vim.log.levels.ERROR); return end
  table.sort(files)
  local items = {}
  for _, filename in ipairs(files) do
    local ok, lines = pcall(vim.fn.readfile, filename)
    if ok then
      local first
      for number, line in ipairs(lines) do
        local marker = vim.trim(line)
        if marker == cfg.begin_marker then
          first = number
        elseif first and marker == cfg.end_marker then
          local preview = "empty block"
          for n = first + 1, number - 1 do
            if vim.trim(lines[n]) ~= "" then preview = vim.trim(lines[n]):sub(1, 140); break end
          end
          table.insert(items, { filename = filename, lnum = first, col = 1, end_lnum = number, end_col = 1,
            text = string.format("Block %d-%d: %s", first, number, preview) })
          first = nil
        end
      end
      if first then table.insert(items, { filename = filename, lnum = first, col = 1, text = "UNCLOSED block" }) end
    end
  end
  vim.fn.setqflist({}, "r", { title = "Marked text blocks", items = items })
  if #items > 0 then vim.cmd("copen") else vim.notify("No marked blocks found") end
end

function M.current_event()
  local cfg = config.need("calendar", { "file", "parse_timestamp" })
  if not cfg or not require("portable.integrations").org() then return end
  local document = require("orgmode.api").load(vim.fn.expand(cfg.file))
  local now = os.time()
  for _, headline in pairs(document.headlines) do
    if headline.level == 1 then
      local props = headline.properties or {}
      local first = props.starttime and cfg.parse_timestamp(props.starttime)
      local last = props.endtime and cfg.parse_timestamp(props.endtime)
      if first and last and first <= now and now <= last then
        vim.cmd.drop(vim.fn.fnameescape(vim.fn.expand(cfg.file)))
        vim.api.nvim_win_set_cursor(0, { headline.position.end_line, 0 })
        vim.cmd("normal! $")
        vim.cmd("startinsert!")
        return
      end
    end
  end
  vim.notify("No current event found")
end

function M.timestamp(offset)
  local cfg = config.need("calendar", { "format_timestamp" })
  if not cfg then return "" end
  local now = os.time()
  local remainder = now % 900
  return cfg.format_timestamp(now + offset + (remainder > 0 and 900 - remainder or 0))
end

function M.sync_calendar(calendar, direction)
  local cfg = config.need("calendar", { "sync" })
  if cfg then cfg.sync(calendar, direction) end
end

function M.remote(direction)
  local cfg = config.need("remote_sync", { "local_path", "remote_path" })
  if not cfg or not config.executable("rsync") then return end
  local argv = { "rsync", "-avz" }
  vim.list_extend(argv, cfg.args or {})
  if direction == "upDelete" then table.insert(argv, "--delete") end
  table.insert(argv, "--")
  local local_path = vim.fn.expand(cfg.local_path):gsub("/$", "") .. "/"
  local remote_path = cfg.remote_path:gsub("/$", "") .. "/"
  vim.list_extend(argv, direction == "down" and { remote_path, local_path } or { local_path, remote_path })
  vim.system(argv, { text = true }, vim.schedule_wrap(function(result)
    vim.fn.setqflist({}, "r", { title = "Remote sync", lines = vim.split((result.stdout or "") .. (result.stderr or ""), "\n") })
    if result.code ~= 0 then vim.cmd("copen") end
    vim.notify("Remote sync " .. (result.code == 0 and "finished" or "failed"))
  end))
end

function M.render()
  local cfg = config.need("media", { "render_command", "video_path", "player_command" })
  if not cfg or not config.parser("python") then return end
  local node = vim.treesitter.get_node()
  local scene
  while node do
    if node:type() == "class_definition" then
      for child in node:iter_children() do
        if child:type() == "identifier" then scene = vim.treesitter.get_node_text(child, 0); break end
      end
      break
    end
    node = node:parent()
  end
  if not scene then vim.notify("No class definition found at cursor"); return end
  local file = vim.api.nvim_buf_get_name(0)
  local command = cfg.render_command(file, scene)
  if not config.executable(command[1]) then return end
  -- argv providers permit custom session/monitor/output policies without embedded shell interpolation.
  -- Repeating the source action interrupts the previous render/player, never unrelated sessions.
  M.render_generation = (M.render_generation or 0) + 1
  local generation = M.render_generation
  if M.render_job then M.render_job:kill(2) end
  if M.player_job then M.player_job:kill(2) end
  M.render_job, M.player_job = nil, nil
  M.render_job = vim.system(command, { text = true }, vim.schedule_wrap(function(result)
    if generation ~= M.render_generation then return end
    M.render_job = nil
    if result.code ~= 0 then vim.notify("Scene render failed; player was not started", vim.log.levels.ERROR); return end
    local player = cfg.player_command(cfg.video_path(file, scene))
    if config.executable(player[1]) then M.player_job = vim.system(player) end
  end))
end

function M.setup()
  _G.GetTodoList = function() return M.tasks(false) end
  _G.GetTodoMarkdown = function() return M.tasks(true) end
  _G.PopulateQuickfixList, _G.DisplayTodoMarkdown = M.quickfix, M.task_float
  _G.GotoCurrentEvent, _G.GetTimeWithOffset, _G.SyncOrgCal = M.current_event, M.timestamp, M.sync_calendar
  _G.RenderAndWatchCurrentScene = M.render
  vim.keymap.set("n", "<leader>t", function() M.quickfix(M.tasks(false)) end)
  vim.keymap.set("n", "<leader>T", M.task_float)
  vim.keymap.set("n", "<leader><leader>n", M.current_event)
  vim.keymap.set("n", "<leader>n", function()
    local cfg = config.need("org", { "scratch_file" })
    if cfg then vim.cmd.edit(vim.fn.fnameescape(vim.fn.expand(cfg.scratch_file))) end
  end)
  vim.api.nvim_create_user_command("ThesisAI", function(opts) M.blocks(opts.args) end, { nargs = "?", complete = "dir" })
  for name, direction in pairs({ ARsyncDown = "down", ARsyncUp = "up", ARsyncUpDelete = "upDelete" }) do
    vim.api.nvim_create_user_command(name, function() M.remote(direction) end, {})
  end
  for key, name in pairs({ sr = "ARsyncDown", su = "ARsyncUp", sx = "ARsyncUpDelete" }) do
    vim.keymap.set("n", "<leader>" .. key, "<Cmd>" .. name .. "<CR>")
  end
end
return M
