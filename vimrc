set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" add all your plugins here (note older versions of Vundle
" used Bundle instead of Plugin)

Plugin 'preservim/nerdtree'
Plugin 'davidhalter/jedi-vim'
Plugin 'Vimjas/vim-python-pep8-indent'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'sheerun/vim-polyglot'
Bundle 'sonph/onehalf', {'rtp': 'vim/'}
Plugin 'nathanaelkane/vim-indent-guides'
"Plugin 'psliwka/vim-smoothie'
"Plugin  'ojroques/vim-oscyank'
" ...

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required


" GENERAL SETTINGS

" enable syntax highlighting
" syntax enable

" show line numbers
set number

" set tabs to have 4 spaces
set ts=4

" indent when moving to the next line while writing code
set autoindent

" expand tabs into spaces
set expandtab

" when using the >> or << commands, shift lines by 4 spaces
set shiftwidth=4

" show a visual line under the cursor's current line
" set cursorline

" show the matching part of the pair for [] {} and ()
" set showmatch


map <F3> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
autocmd BufWinEnter * silent NERDTreeMirror
let NERDTreeWinSize=20


syntax on
set t_Co=256
"set cursorline
"colorscheme onehalflight
"let g:airline_theme='onehalfdark'
let g:python_highlight_all = 1

"let g:indent_guides_enable_on_vim_startup = 1
let $VIRTUAL_ENV = $CONDA_PREFIX

let g:jedi#popup_on_dot = 0
autocmd FileType python setlocal completeopt-=preview
let g:jedi#use_tabs_not_buffers = 1

" set up ruller
set colorcolumn=100
highlight ColorColumn ctermbg=0 guibg=lightgrey

let g:jedi#show_call_signatures = 0

set clipboard=unnamedplus

"autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | OSCYankReg " | endif
