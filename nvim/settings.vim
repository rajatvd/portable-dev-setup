syntax enable
filetype plugin indent on

set number
set relativenumber
set hidden
set smartcase
set ignorecase
set incsearch
set nohlsearch
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nowrap
set scrolloff=5
set signcolumn=yes
set termguicolors
set updatetime=200
set completeopt=menuone,noinsert,noselect
set noswapfile
set nobackup
set undofile

let s:undo_dir = stdpath('state') . '/undo'
call mkdir(s:undo_dir, 'p')
let &undodir = s:undo_dir

silent! colorscheme habamax
