function! InsertBreakpoint()
    let l:pos = getcurpos()
    execute "normal! Oimport ipdb; ipdb.set_trace() # fmt: skip\<Esc>"
    call cursor(l:pos[1]+1, l:pos[2])
endfunction

nnoremap <leader>id :call InsertBreakpoint()<CR>
