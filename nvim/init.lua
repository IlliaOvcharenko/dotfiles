require "plugins"

local g = vim.g

g.mapleader = " "
-- g.fzf_layout = { right = "~40%" }
-- g.fzf_layout = { down = "~40%" }
vim.cmd [[ let g:fzf_layout = { 'window': { 'width': 1.0, 'height': 0.5, 'relative': v:true, 'yoffset': 1.0 } } ]]

g.lightline = { colorscheme = "one" }
-- g.fzf_colors = { border = }

local o = vim.opt

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


o.laststatus=2
-- o.laststatus = 0

-- o.noshowmode = true
-- o.noshowmode = true

local map = vim.api.nvim_set_keymap
map("n", "'", ":Buffers<CR>", { silent = true, noremap = true })
map("n", ";", ":Files<CR>", { silent = true, noremap = true })
map("n", "\\", ":Ag<CR>", { silent = true, noremap = true })
-- map("n", "<leader>;", ":Files<CR>", { silent = true, noremap = true })
-- map("n", "<leader>\\", ":Ag<CR>", { silent = true, noremap = true })

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
