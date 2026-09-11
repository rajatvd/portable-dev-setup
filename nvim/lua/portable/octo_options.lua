return {
	default_remote = { "upstream", "origin" },
	ssh_aliases = {},
	reaction_viewer_hint_icon = "",
	user_icon = " ",
	timeline_marker = "",
	timeline_indent = "2",
	right_bubble_delimiter = "",
	left_bubble_delimiter = "",
	github_hostname = "",
	snippet_context_lines = 4,
	gh_env = {},
	timeout = 5000,
	ui = {
		use_signcolumn = true,
	},
	issues = {
		order_by = {
			field = "CREATED_AT",
			direction =
			"DESC"
		}
	},
	pull_requests = {
		order_by = {
			field = "CREATED_AT",
			direction =
			"DESC"
		},
		always_select_remote_on_create = false
	},
	file_panel = {
		size = 10,
		use_icons = true
	},
	mappings = {
		issue = {
			close_issue = { lhs = "<leader>ic", desc = "close issue" },
			reopen_issue = { lhs = "<leader>io", desc = "reopen issue" },
			list_issues = { lhs = "<leader>gi", desc = "list open issues on same repo" },
			reload = { lhs = "<C-r>", desc = "reload issue" },
			open_in_browser = { lhs = "<C-b>", desc = "open issue in browser" },
			copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
			add_assignee = { lhs = "<leader>aa", desc = "add assignee" },
			remove_assignee = { lhs = "<leader>ad", desc = "remove assignee" },
			create_label = { lhs = "<leader>Lc", desc = "create label" },
			add_label = { lhs = "<leader>La", desc = "add label" },
			remove_label = { lhs = "<leader>Ld", desc = "remove label" },
			goto_issue = { lhs = "<leader>gi", desc = "navigate to a local repo issue" },
			add_comment = { lhs = "<leader>ca", desc = "add comment" },
			delete_comment = { lhs = "<leader>cd", desc = "delete comment" },
			next_comment = { lhs = "]c", desc = "go to next comment" },
			prev_comment = { lhs = "[c", desc = "go to previous comment" },
		},
		pull_request = {
			checkout_pr = { lhs = "<leader>po", desc = "checkout PR" },
			merge_pr = { lhs = "<leader>pm", desc = "merge commit PR" },
			squash_and_merge_pr = { lhs = "<leader>psm", desc = "squash and merge PR" },
			list_commits = { lhs = "<leader>pc", desc = "list PR commits" },
			list_changed_files = { lhs = "<leader>pf", desc = "list PR changed files" },
			show_pr_diff = { lhs = "<leader>pd", desc = "show PR diff" },
			add_reviewer = { lhs = "<leader>va", desc = "add reviewer" },
			remove_reviewer = { lhs = "<leader>vd", desc = "remove reviewer request" },
			close_issue = { lhs = "<leader>ic", desc = "close PR" },
			reopen_issue = { lhs = "<leader>io", desc = "reopen PR" },
			list_issues = { lhs = "<leader>gi", desc = "list open issues on same repo" },
			reload = { lhs = "<C-r>", desc = "reload PR" },
			open_in_browser = { lhs = "<C-b>", desc = "open PR in browser" },
			copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
			goto_file = { lhs = "gf", desc = "go to file" },
			add_assignee = { lhs = "<leader>aa", desc = "add assignee" },
			remove_assignee = { lhs = "<leader>ad", desc = "remove assignee" },
			create_label = { lhs = "<leader>Lc", desc = "create label" },
			add_label = { lhs = "<leader>La", desc = "add label" },
			remove_label = { lhs = "<leader>Ld", desc = "remove label" },
			goto_issue = { lhs = "<leader>gi", desc = "navigate to a local repo issue" },
			add_comment = { lhs = "<leader>ca", desc = "add comment" },
			delete_comment = { lhs = "<leader>cd", desc = "delete comment" },
			next_comment = { lhs = "]c", desc = "go to next comment" },
			prev_comment = { lhs = "[c", desc = "go to previous comment" },
		},
		review_thread = {
			goto_issue = { lhs = "<leader>gi", desc = "navigate to a local repo issue" },
			add_comment = { lhs = "<leader>ca", desc = "add comment" },
			add_suggestion = { lhs = "<leader>sa", desc = "add suggestion" },
			delete_comment = { lhs = "<leader>cd", desc = "delete comment" },
			next_comment = { lhs = "]c", desc = "go to next comment" },
			prev_comment = { lhs = "[c", desc = "go to previous comment" },
			select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
			select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
			close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
		},
		submit_win = {
			approve_review = { lhs = "<C-a>", desc = "approve review" },
			comment_review = { lhs = "<C-m>", desc = "comment review" },
			request_changes = { lhs = "<C-r>", desc = "request changes review" },
			close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
		},
		review_diff = {
			next_thread = { lhs = "]t", desc = "move to next thread" },
			prev_thread = { lhs = "[t", desc = "move to previous thread" },
			select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
			select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
			close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
		},
		file_panel = {
			next_entry = { lhs = "j", desc = "move to next changed file" },
			prev_entry = { lhs = "k", desc = "move to previous changed file" },
			select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
			refresh_files = { lhs = "R", desc = "refresh changed files panel" },
			select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
			select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
			close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
		}
	},
	suppress_missing_scope = {
		projects_v2 = true,
	}

}
