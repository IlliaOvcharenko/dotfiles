require "plugins"

local g = vim.g
local o = vim.opt
local map = vim.api.nvim_set_keymap

g.mapleader = "`"
o.timeoutlen = 3000
vim.cmd [[ let g:fzf_layout = { 'window': { 'width': 1.0, 'height': 0.5, 'relative': v:true, 'yoffset': 1.0 } } ]]

g.lightline = { colorscheme = "one" }

o.number = true
o.relativenumber = true

o.guicursor = "a:block"
o.syntax = "on"

o.tabstop = 4
o.softtabstop = 4
o.expandtab = true
o.shiftwidth = 4
o.autoindent = true

o.list = true

o.hlsearch = true
o.incsearch = true
o.ignorecase = true

o.termguicolors = true

o.hidden = true


o.laststatus = 2

o.colorcolumn = "100"

map("n", "'", ":Buffers<CR>", { silent = true, noremap = true })
map("n", ";", ":GFiles<CR>", { silent = true, noremap = true })
map("n", "\\", ":Ag<CR>", { silent = true, noremap = true })
-- map("n", "<leader>;", ":Files<CR>", { silent = true, noremap = true })
-- map("n", "<leader>\\", ":Ag<CR>", { silent = true, noremap = true })


map("v", "<c-/>", ":Commentary<cr>", { silent = true, noremap = true })
map("n", "<c-/>", "<s-v>:Commentary<cr>", { silent = true, noremap = true })
map("i", "<c-/>", "<esc><s-v>:Commentary<cr>i", { silent = true, noremap = true })
map("v", "<c-_>", ":Commentary<cr>", { silent = true, noremap = true })
map("n", "<c-_>", "<s-v>:Commentary<cr>", { silent = true, noremap = true })
map("i", "<c-_>", "<esc><s-v>:Commentary<cr>i", { silent = true, noremap = true })

vim.cmd("set noshowmode")

vim.cmd [[
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }
]]
-- vim.cmd [[
-- autocmd! FileType fzf
-- autocmd  FileType fzf set laststatus=0 noshowmode noruler
--   \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler
-- ]]

-- TODO not working in NVim
-- vim.api.nvim_create_user_command("W", [[execute 'w !sudo tee % > /dev/null' <bar> edit!]], {})
vim.api.nvim_create_user_command("Wqa", [[:wqa<CR>]], {})


function run_tmux_last_cmd()
    vim.cmd [[
        write
        silent execute ':!tmux send-keys -t top-right Up  Enter'
        redraw!
    ]]
end


map("n", "<leader>p", ":lua run_tmux_last_cmd()<CR>", { silent = true, noremap = true } )
map("i", "<leader>p", "<C-O>:lua run_tmux_last_cmd()<CR>", { silent = true, noremap = true } )

vim.cmd [[
let $VIRTUAL_ENV = $CONDA_PREFIX
]]

g["jedi#completions_command"] = "<C-p>"
-- g["jedi#use_tabs_not_buffers"] = 1
vim.cmd [[
autocmd FileType python setlocal completeopt-=preview
]]
g["jedi#show_call_signatures"] = 0
g["jedi#popup_on_dot"] = 0

map("i", "<c-space>", "<nop>", { silent = true, noremap = true })

