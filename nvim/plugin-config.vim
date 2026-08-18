nnoremap <silent> <leader>gs :Git<CR>

let g:surround_no_mappings = 1
nmap de  <Plug>Dsurround
nmap ce  <Plug>Csurround
nmap cE  <Plug>CSurround
nmap ye  <Plug>Ysurround
nmap yE  <Plug>YSurround
nmap yee <Plug>Yssurround
nnoremap yEe <Plug>YSsurround
nnoremap yEE <Plug>YSsurround
xnoremap E   <Plug>VSurround
xnoremap gE  <Plug>VgSurround

augroup portable_commentary
  autocmd!
  autocmd FileType cpp setlocal commentstring=//\ %s
augroup END
