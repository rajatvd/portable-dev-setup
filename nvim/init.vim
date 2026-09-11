let s:config_dir = stdpath('config')
lua require('portable.config').load()
execute 'source ' . fnameescape(s:config_dir . '/settings.vim')
packadd base16-atelierestuary
colorscheme base16-atelierestuary
execute 'source ' . fnameescape(s:config_dir . '/mappings.vim')
execute 'source ' . fnameescape(s:config_dir . '/plugin-config.vim')
for s:helper in ['toggle-term', 'messages-to-buffer', 'send-to-term', 'send-shape', 'insert-breakpoint']
  execute 'source ' . fnameescape(s:config_dir . '/custom/' . s:helper . '.vim')
endfor
lua require('portable').setup()
let g:portable_dev_setup_loaded = 1
