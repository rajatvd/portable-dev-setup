-- Copy outside the managed directory to ${XDG_CONFIG_HOME:-$HOME/.config}/nvim-local.lua.
-- Or set NVIM_PORTABLE_LOCAL to one trusted Lua file. The installer preserves that file.
-- This example does not enable anything, read documents, start processes, or access accounts.
return {
  -- Runtime directory containing parser/*.so (platform-specific, provisioned separately).
  -- parser_path = "/path/to/parser-runtime",
  copilot = { enabled = false }, -- host Node + separately authorized Copilot account
  octo = { enabled = false }, -- host gh + separately configured credentials; options = {} overrides plugin options
  git_completion = { enabled = false }, -- Git/issue completion may contact configured providers
  org = {
    enabled = false,
    -- agenda_files = { "/path/to/notes/*.org" },
    -- notes_file = "/path/to/inbox.org",
    -- scratch_file = "/path/to/scratch.org",
    -- capture_templates = { t = { description = "Task", template = "* TODO %?\n  %u" } },
  },
  calendar = {
    enabled = false,
    -- file = "/path/to/calendar.org",
    -- parse_timestamp = function(text) return an_epoch_in_seconds end,
    -- format_timestamp = function(epoch) return a_timestamp_with_your_timezone end,
    -- sync = function(calendar, direction) ... end, -- explicit local backend; never called at startup
  },
  repl = {
    enabled = false,
    -- command = { "ipython3" }, -- executable argv; may select an explicitly activated environment
    -- startup_lines = { "%load_ext autoreload", "%autoreload 2" },
    -- startup_delay_ms = 500,
  },
  tasks = {
    enabled = false,
    -- items = function() return { { filename = "example.txt", lnum = 1, text = "Example" } } end,
    -- markdown = function() return "# Tasks\n- Example" end,
  },
  blocks = {
    enabled = false,
    -- root = "/path/to/project", -- or pass an explicit directory to :ThesisAI
    -- begin_marker = "BEGIN-REVIEW", end_marker = "END-REVIEW",
    -- glob = "**/*.tex", exclude = { "**/build/**", "**/reports/**" },
  },
  media = {
    enabled = false,
    -- render_command = function(file, scene) return { "manim", "render", file, scene } end,
    -- video_path = function(file, scene) return your_output_path end,
    -- player_command = function(video) return { "mpv", "--loop-file=inf", "--", video } end,
    -- Providers can select local sessions/monitors/output layouts; no shell concatenation is required.
  },
  remote_sync = {
    enabled = false,
    -- local_path = "/path/to/local-directory",
    -- remote_path = "example.invalid:/path/to/remote-directory", -- configure your own destination/auth
    -- args = { "--exclude", ".git" },
  },
  latex = {
    -- viewer = "zathura", -- choose a viewer appropriate to your host
    -- focus_command = { "your-focus-tool", "your-terminal" },
  },
  notebooks = { enabled = false }, -- explicit Jupytext conversion / Jupyter Ascending; host tools required
  markdown_preview = { enabled = false }, -- host instant-markdown-d; preview server starts only on command
}
