let mapleader = ' '
let maplocalleader = ' '

nnoremap <silent> <C-s> :write<CR>
nnoremap <silent> <leader>w :write<CR>
nnoremap <silent> <C-Q> :wq!<CR>
nnoremap <C-c> <Esc>
inoremap jk <Esc>
inoremap kj <Esc>
cnoremap jk <C-c>
cnoremap kj <C-c>
vnoremap <CR> <Esc>

vnoremap < <gv
vnoremap > >gv

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <CR> <C-w>w

augroup portable_quickfix
  autocmd!
  autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>
augroup END

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
nnoremap <silent> <leader>j :cnext<CR>zz
nnoremap <silent> <leader>k :cprev<CR>zz
nnoremap <leader>q <C-w>q
nnoremap <leader>o <C-w>o

tnoremap <expr> <Esc> &filetype ==# "fzf" ? "\<Esc>" : "\<C-\>\<C-n>"
tnoremap <expr> jk &filetype ==# "fzf" ? "\<Esc>" : "\<C-\>\<C-n>"
tnoremap <expr> kj &filetype ==# "fzf" ? "\<Esc>" : "\<C-\>\<C-n>"

map <M-l> <C-T>
map <M-h> <C-]>
noremap H ^
noremap L $
noremap J <C-d>zz
noremap K <C-u>zz
nnoremap <leader>6 <C-6>
nnoremap <leader>c :<Up>
nnoremap ; :
vnoremap ; :

" Clipboard provider is supplied by the host; no clipboard state is distributed.
nnoremap <leader><leader>y "+y
vnoremap <leader><leader>y "+y
nnoremap Y<leader><leader> "+Y
