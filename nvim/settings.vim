syntax enable
filetype plugin indent on

set guicursor=
set number
set relativenumber
set hidden
set noerrorbells
set smartcase
set ignorecase
set incsearch
set nohlsearch
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set wrap
set scrolloff=8
set signcolumn=yes
set termguicolors
set updatetime=50
set completeopt=menuone,noinsert,noselect
set noshowmode
set cmdheight=2
set shortmess+=c
set colorcolumn=88
set noswapfile
set nobackup
set undofile
set background=dark

let s:undo_dir = stdpath('state') . '/undo'
call mkdir(s:undo_dir, 'p')
let &undodir = s:undo_dir

highlight ColorColumn ctermbg=0 guibg=lightgrey
