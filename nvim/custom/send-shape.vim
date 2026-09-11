lua _G.PortableSendShape = require('portable.repl').shape
nnoremap <silent> <Plug>SendShapeLine <Cmd>lua require('portable.repl').shape('direct')<CR>
nnoremap <silent> <Plug>SendShape :set opfunc=v:lua.PortableSendShape<CR>g@
xnoremap <silent> <Plug>SendShape :<C-u>lua require('portable.repl').shape(vim.fn.visualmode())<CR>
nmap <leader>ss <Plug>SendShapeLine
nmap <leader>s <Plug>SendShape
xmap <leader>s <Plug>SendShape
nmap <leader>S <leader>s$
