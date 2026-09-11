let g:term_buf = 0
let g:term_win = 0
function! TermToggle(width) abort
  if win_gotoid(g:term_win)
    hide
    return
  endif
  botright vnew
  execute 'vertical resize ' . (a:width == 0 ? winwidth(0) * 2 : a:width)
  if bufexists(g:term_buf) && getbufvar(g:term_buf, '&buftype') ==# 'terminal'
    execute 'buffer ' . g:term_buf
  else
    call termopen(&shell, {'detach': 0})
    let g:term_buf = bufnr('')
  endif
  setlocal nonumber norelativenumber signcolumn=no
  let g:term_win = win_getid()
endfunction
nnoremap <leader>r :call TermToggle(55)<CR>
nnoremap <leader><leader>R :call TermToggle(0)<CR>
