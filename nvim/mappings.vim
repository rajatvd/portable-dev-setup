let mapleader = ' '
let maplocalleader = ' '

nnoremap <silent> <leader>w :write<CR>
nnoremap <silent> <leader>q :quit<CR>
inoremap jk <Esc>
inoremap kj <Esc>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

vnoremap < <gv
vnoremap > >gv

function! s:ToggleQuickfix() abort
  for window in getwininfo()
    if get(window, 'quickfix', 0) && !get(window, 'loclist', 0)
      cclose
      return
    endif
  endfor
  copen
endfunction

nnoremap <silent> <leader>l :<C-u>call <SID>ToggleQuickfix()<CR>
