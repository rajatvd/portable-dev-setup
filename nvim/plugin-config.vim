let g:pydocstring_doq_path = "doq"
for s:config in ['airline', 'surround', 'vim-autoformat', 'vimtex', 'vim-instant-markdown']
  execute 'source ' . fnameescape(stdpath('config') . '/plug-configs/' . s:config . '.vim')
endfor
nnoremap <silent> <leader>gs :Git<CR>
nnoremap <silent> <leader>gp :Git push<CR>
augroup portable_filetypes
  autocmd!
  autocmd BufRead,BufNewFile *.cu,*.cuh setfiletype cuda
  autocmd BufRead,BufNewFile *.mojo,*.🔥 setfiletype mojo
  autocmd FileType cuda,cpp setlocal commentstring=//\ %s
augroup END
