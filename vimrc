"--------------------------------------------------------------------------------------------------
" Plugins set-up

set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'preservim/nerdtree'
Plugin 'davidhalter/jedi-vim'
Plugin 'Vimjas/vim-python-pep8-indent'
Plugin 'sheerun/vim-polyglot'
Bundle 'sonph/onehalf', {'rtp': 'vim/'}
Plugin 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plugin 'junegunn/fzf.vim'
Plugin 'itchyny/lightline.vim'
Plugin 'junegunn/goyo.vim'
Plugin 'tpope/vim-commentary'

"Plugin 'nathanaelkane/vim-indent-guides'
"Plugin 'psliwka/vim-smoothie'
"Plugin  'ojroques/vim-oscyank'
"Plugin 'kyazdani42/nvim-web-devicons'
"Plugin 'romgrk/barbar.nvim'
"Plugin 'vim-airline/vim-airline'
"Plugin 'vim-airline/vim-airline-themes'
" ...

call vundle#end()
filetype plugin indent on

"--------------------------------------------------------------------------------------------------




"--------------------------------------------------------------------------------------------------
" General editor settings

" enable syntax highlighting
" syntax enable
let g:python_highlight_all = 1
syntax on
set t_Co=256

" show line numbers
"set number
set number relativenumber
set nu rnu

" set tabs to have 4 spaces
set ts=4

" indent when moving to the next line while writing code
set autoindent

" expand tabs into spaces
set expandtab

" when using the >> or << commands, shift lines by 4 spaces
set shiftwidth=4

" show a visual line under the cursor's current line
"set cursorline

" show the matching part of the pair for [] {} and ()
"set showmatch

" highlight search
set hlsearch
set incsearch

" ignore case during search
set ignorecase


" always show tabline
set showtabline=2

" set up ruller
set colorcolumn=100
highlight ColorColumn ctermbg=0 guibg=lightgrey

" enable block cursor
set guicursor=

" enable colors
set termguicolors

" langmap for ukrainian lang
set langmap=ФИСВУАПРШОЛДЬТЩЗЙКІЫЕГМЦЧНЯЖЮХЇфисвуапршолдьтщзйкыіегмцчняжюхї;ABCDEFGHIJKLMNOPQRSSTUVWXYZ:>{}abcdefghijklmnopqrsstuvwxyz\;.[]

" bindings for system clipboard, vim should be compiled with +clipboard (install gvim to get it)
" TODO fix with ssh
vmap <C-c> "+y
map <C-v> "+p

" bindigs for code commenting
vmap <C-_> gc
nmap <C-_> <S-v>gc
imap <C-_> <Esc><S-v>gci

" set W command to save with sudo
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!

" add command allias (always hit the shift during save)
command! Wqa :wqa<cr>

" set buffers hidden by default
set hidden

" binding to repeat last command in tmux window
function TmuxPaneRepeat()
    write
    silent execute ':!tmux send-keys -t top-right Up  Enter'
    redraw!
endfunction

nmap <C-p> :call TmuxPaneRepeat()<cr>
imap <C-p> <C-O>:call TmuxPaneRepeat()<cr>


" TODO tabline setup
"let bufferline = get(g:, 'bufferline', {})
"let bufferline.icons = v:false
"let bufferline.closable = v:false

"--------------------------------------------------------------------------------------------------




"--------------------------------------------------------------------------------------------------
" NerdTree settings

map <F3> :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
autocmd BufWinEnter * silent NERDTreeMirror
let NERDTreeWinSize=20

"--------------------------------------------------------------------------------------------------




"--------------------------------------------------------------------------------------------------
" Jedi settings

" Jedi use current conda env
let $VIRTUAL_ENV = $CONDA_PREFIX

let g:jedi#popup_on_dot = 0
autocmd FileType python setlocal completeopt-=preview
let g:jedi#use_tabs_not_buffers = 1
let g:jedi#show_call_signatures = 0

"--------------------------------------------------------------------------------------------------



"--------------------------------------------------------------------------------------------------
"  FZF settings

map ; :Files<CR>
let g:fzf_layout = { 'down': '~40%' }

"--------------------------------------------------------------------------------------------------




"--------------------------------------------------------------------------------------------------
" Theme

colorscheme onehalfdark

" Set indents visible
" set lcs+=space:·
set list
hi SpecialKey guifg=lightred


"--------------------------------------------------------------------------------------------------




"--------------------------------------------------------------------------------------------------
" Statusline

" Airline
"let g:airline_theme='onehalfdark'

" Lightline
let g:lightline = {
    \ 'colorscheme': 'wombat',
    \ }
set laststatus=2
function! MyLightLinePercent()
  if &ft !=? 'nerdtree'
    return line('.') * 100 / line('$') . '%'
  else
    return ''
  endif
endfunction
function! MyLightLineLineInfo()
  if &ft !=? 'nerdtree'
    return line('.').':'. col('.')
  else
    return ''
  endif
endfunction
let g:lightline.component_function = {
    \ 'percent': 'MyLightLinePercent',
    \ 'lineinfo': 'MyLightLineLineInfo'
    \ } 

"--------------------------------------------------------------------------------------------------

