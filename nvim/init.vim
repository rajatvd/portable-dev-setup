let s:config_dir = stdpath('config')
execute 'source ' . fnameescape(s:config_dir . '/settings.vim')
execute 'source ' . fnameescape(s:config_dir . '/mappings.vim')
execute 'source ' . fnameescape(s:config_dir . '/plugin-config.vim')
lua require('portable').setup()
packadd base16-atelierestuary
colorscheme base16-atelierestuary
let g:portable_dev_setup_loaded = 1
