function! MessagesToBuffer()
	redir  => messages
	silent messages
	redir END
	new
	setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted nomodified
	silent put =messages
endfunction

nnoremap <leader>mb :call MessagesToBuffer()<CR>
