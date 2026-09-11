" Native terminal transport; target state exists only for this editor session.
function! s:Send(lines) dict abort
  if jobwait([self.channel], 0)[0] != -1
    echoerr 'Terminal target exited; select a live target with :SendHere'
    return
  endif
  let text = join(a:lines, self.newline)
  if len(a:lines) > 1
    let text = self.begin . text . self.end
  else
    let text .= "\n"
  endif
  call chansend(self.channel, text)
endfunction

function! s:SelectTarget(buffer, kind) abort
  let channel = getbufvar(a:buffer, 'terminal_job_id', 0)
  if channel == 0
    echoerr 'Select a terminal buffer with :SendHere or :SendTo {buffer}'
    return
  endif
  let formats = {
        \ 'default': {'begin': '', 'end': "\n", 'newline': "\n"},
        \ 'ipy': {'begin': "\x1b[200~", 'end': "\x1b[201~\r\r\r", 'newline': "\n"},
        \ 'cling': {'begin': "{\n", 'end': "\n}\n", 'newline': "\n"}}
  if !has_key(formats, a:kind)
    echoerr 'SendHere kind must be default, ipy or cling'
    return
  endif
  let g:send_target = extend({'channel': channel, 'send': function('s:Send')}, formats[a:kind])
endfunction
command! -nargs=? SendHere call s:SelectTarget(bufnr(''), empty(<q-args>) ? 'default' : <q-args>)
command! -nargs=1 -complete=buffer SendTo call s:SelectTarget(bufnr(<q-args>), 'default')
nnoremap <leader>sh :SendHere ipy<CR>
nnoremap <silent> <Plug>SendLine <Cmd>lua require('portable.repl').send({vim.api.nvim_get_current_line()})<CR>
nnoremap <silent> <Plug>Send :set opfunc=v:lua.PortableSendOperator<CR>g@
xnoremap <silent> <Plug>Send :<C-u>lua require('portable.repl').send(require('portable.repl').selection(vim.fn.visualmode()))<CR>
lua _G.PortableSendOperator = function(mode) require('portable.repl').send(require('portable.repl').selection(mode)) end
nmap ss <Plug>SendLine
nmap s <Plug>Send
xmap s <Plug>Send
nmap S s$
