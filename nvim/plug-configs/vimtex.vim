let g:vimtex_quickfix_mode = 0
let g:vimtex_compiler_latexmk = {
      \ 'out_dir': 'build',
      \ 'options': ['-pdf', '-interaction=nonstopmode', '-synctex=1', '-file-line-error'],
      \}
" Viewer and reverse-search focus are explicit host choices; no fixed toolchain PATH.
lua << EOF
local cfg = require('portable.config').options.latex or {}
if cfg.viewer then vim.g.vimtex_view_method = cfg.viewer end
if cfg.viewer_options then vim.g.vimtex_view_general_options = cfg.viewer_options end
if cfg.focus_command then
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('portable_tex_focus', { clear = true }),
    pattern = 'VimtexEventViewReverse',
    callback = function()
      if require('portable.config').executable(cfg.focus_command[1]) then
        vim.system(cfg.focus_command)
      end
    end,
  })
end
EOF
augroup portable_text_wrap
  autocmd!
  autocmd FileType tex,markdown setlocal wrap
augroup END
let maplocalleader = ' '
