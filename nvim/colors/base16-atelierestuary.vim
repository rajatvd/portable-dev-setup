let s:source = globpath(&runtimepath, 'colors/base16-atelier-estuary.vim', 0, 1)
if empty(s:source)
  let g:colors_name = ''
  throw 'portable-dev-setup: missing required base16-atelier-estuary colorscheme source'
endif
execute 'source ' . fnameescape(s:source[0])
if get(g:, 'colors_name', '') !=# 'base16-atelier-estuary'
  throw 'portable-dev-setup: base16-atelier-estuary colorscheme did not initialize'
endif
let g:colors_name = 'base16-atelierestuary'
