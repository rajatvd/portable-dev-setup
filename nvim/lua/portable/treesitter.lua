local M = {}
function M.setup()
require 'nvim-treesitter.configs'.setup {
	ensure_installed = {},

	sync_install = false,

	auto_install = false,



	highlight = {
		enable = true,
		disable = function(lang, buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			if ok and stats and stats.size > max_filesize then
				return true
			end
		end,
		additional_vim_regex_highlighting = { "org" },
	},

	playground = {
		enable = true,
		disable = {},
		updatetime = 25,   -- Debounced time for highlighting nodes in the playground from source code
		persist_queries = false, -- Whether the query persists across vim sessions
		keybindings = {
			toggle_query_editor = 'o',
			toggle_hl_groups = 'i',
			toggle_injected_languages = 't',
			toggle_anonymous_nodes = 'a',
			toggle_language_display = 'I',
			focus_language = 'f',
			unfocus_language = 'F',
			update = 'R',
			goto_node = '<cr>',
			show_help = '?',
		},
	},

	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
				["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
			},
			selection_modes = {
				['@parameter.outer'] = 'v', -- charwise
				['@function.outer'] = 'V', -- linewise
				['@class.outer'] = '<c-v>', -- blockwise
			},
			include_surrounding_whitespace = true,
		},
		lsp_interop = {
			enable = true,
			border = 'none',
			floating_preview_opts = {},
			peek_definition_code = {
				["<leader>gd"] = "@function.outer",
				["<leader>gD"] = "@class.outer",
			},
		},
	},
}

vim.keymap.set("n", "<leader><leader>T", "<Cmd>TSPlaygroundToggle<CR>")
vim.g.portable_treesitter_initialized = 1
end
return M
