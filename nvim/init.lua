-- Use the system clipboard for normal yank, delete, change, and put commands.
-- On a direct SSH connection there is no local clipboard executable, so use
-- OSC 52 to talk to the terminal on the client machine. Inside a remote tmux
-- session, Nvim's tmux provider handles both directions instead.
if vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
    vim.g.clipboard = vim.env.TMUX and "tmux" or "osc52"
end
vim.opt.clipboard = "unnamedplus"

-- Let ranger discover this editor through its tmux pane, even when the two
-- programs were started independently. Refresh on entry for nested editors.
if vim.env.TMUX and vim.env.TMUX_PANE then
    local pane = vim.env.TMUX_PANE
    local function register_tmux_server()
        if vim.v.servername ~= "" then
            vim.fn.system({ "tmux", "set-option", "-p", "-t", pane,
                "@nvim_server", vim.v.servername })
        end
    end
    vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
        callback = register_tmux_server,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            local server = vim.fn.system({ "tmux", "show-options", "-pqv", "-t", pane,
                "@nvim_server" }):gsub("\n$", "")
            if server == vim.v.servername then
                vim.fn.system({ "tmux", "set-option", "-pu", "-t", pane, "@nvim_server" })
            end
        end,
    })
end

-- Publish the RPC address for ranger; Rex's editor label selects the pane.
-- Use the same explicit cache path in ranger, independent of XDG settings.
if vim.env.REX_BLOCK and not vim.env.TMUX then
    local block = vim.env.REX_BLOCK
    local key = block:match("^block:([0-9a-f%-]+)$")
    if key then
        local directory = vim.fn.expand("~/.cache/rex-nvim")
        local path = directory .. "/" .. key .. ".json"
        local function register_rex_server()
            if vim.v.servername == "" then return end
            vim.fn.mkdir(directory, "p", 448) -- 0700 for a new directory
            local temporary = path .. "." .. vim.fn.getpid()
            local record = vim.fn.json_encode({
                block = block,
                address = vim.v.servername,
            })
            if vim.fn.writefile({ record }, temporary) == 0 then
                if vim.fn.rename(temporary, path) ~= 0 then
                    vim.fn.delete(temporary)
                end
            end
        end
        vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
            callback = register_rex_server,
        })
        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                local ok, lines = pcall(vim.fn.readfile, path)
                if not ok then return end
                local decoded, record = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
                if decoded and type(record) == "table" and record.address == vim.v.servername then
                    vim.fn.delete(path)
                end
            end,
        })
    end
end

require "plugins"

vim.lsp.config('pyright', {})
vim.lsp.enable('pyright')

vim.lsp.config('clangd', {})
vim.lsp.enable('clangd')

local g = vim.g
local o = vim.opt
local map = vim.api.nvim_set_keymap

o.shortmess:append("I")
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

-- Copy a file reference relative to Nvim's cwd, with a 1-based character column.
vim.keymap.set("n", "<leader>yl", function()
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == "" then
        vim.notify("Cannot copy location: buffer has no filename", vim.log.levels.WARN)
        return
    end

    local path = vim.fn.fnamemodify(filename, ":.")
    local location = string.format("%s:%d:%d", path, vim.fn.line("."), vim.fn.charcol("."))
    vim.fn.setreg("+", location, "v")
    vim.notify("Copied: " .. location)
end, { desc = "Yank file location to clipboard" })


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
vim.api.nvim_create_user_command("W", [[:w<CR>]], {})
vim.api.nvim_create_user_command("Wqa", [[:wqa<CR>]], {})


function run_tmux_last_cmd()
    local pane = vim.env.REX_BLOCK
    if pane then
        if vim.fn.executable("rex") ~= 1 then
            vim.notify("Rex CLI is not available", vim.log.levels.ERROR)
            return
        end

        -- Check on every invocation so pane-label shortcuts take effect immediately.
        local output = vim.fn.system({ "rex", "block", "inspect", "-s", pane, pane, "--json" })
        if vim.v.shell_error ~= 0 then
            vim.notify("Cannot inspect Rex pane: " .. output, vim.log.levels.ERROR)
            return
        end
        local ok, info = pcall(vim.json.decode, output)
        if not ok or type(info) ~= "table" or type(info.block) ~= "table" then
            vim.notify("Invalid Rex pane inspection response", vim.log.levels.ERROR)
            return
        end
        if info.block.label ~= "editor" then
            vim.notify("Label this Rex pane 'editor' first (Ctrl+B, then E)", vim.log.levels.WARN)
            return
        end

        vim.cmd("write")
        output = vim.fn.system({
            "rex", "send-key", "-s", pane,
            "-b", "runner", "up", "enter",
        })
        if vim.v.shell_error ~= 0 then
            vim.notify("Cannot rerun command in Rex runner: " .. output, vim.log.levels.ERROR)
        end
    elseif vim.env.TMUX then
        vim.cmd [[
            write
            silent execute ':!tmux send-keys -t top-right Up  Enter'
            redraw!
        ]]
    else
        vim.notify("Not running inside Rex or tmux", vim.log.levels.WARN)
    end
end


map("n", "<leader>p", ":lua run_tmux_last_cmd()<CR>", { silent = true, noremap = true } )
map("i", "<leader>p", "<C-O>:lua run_tmux_last_cmd()<CR>", { silent = true, noremap = true } )

vim.cmd [[
let $VIRTUAL_ENV = $CONDA_PREFIX
]]

-- g["jedi#completions_command"] = "<C-p>"
-- -- g["jedi#use_tabs_not_buffers"] = 1
-- vim.cmd [[
-- autocmd FileType python setlocal completeopt-=preview
-- ]]
-- g["jedi#show_call_signatures"] = 0
-- g["jedi#popup_on_dot"] = 0
-- inoremap <C-Space> <C-x><C-o>

-- lsp config
vim.cmd("set completeopt-=preview")
vim.cmd("set completeopt-=longest")
vim.cmd("set completeopt+=menu")
vim.cmd("set completeopt+=menuone")
vim.cmd("set completeopt+=noselect")
map("i", "<C-p>", "<C-x><C-o>", { noremap = true })
map("i", "<C-g>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap = true })
map("n", "<leader>d", "<C-]>", { noremap = true })
map("n", "<leader>r", "<Cmd>lua vim.lsp.buf.rename()<CR>", { noremap = true })
map("n", "<leader>s", "<Cmd>lua vim.diagnostic.open_float()<CR>", { noremap = true })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end

    -- Before 11.6 version it was
    -- client.server_capabilities.semanticTokensProvider = nil

    -- vim.bo[args.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
  end,
});

-- -- copilot config
-- map("i", "<C-h>", "<Cmd>Copilot suggestion accept<CR>", { silent = true, noremap = true })
-- map("i", "<C-j>", "<Cmd>Copilot suggestion next<CR>", { silent = true, noremap = true })
-- map("i", "<C-k>", "<Cmd>Copilot suggestion prev<CR>", { silent = true, noremap = true })
-- map("i", "<C-l>", "<Cmd>Copilot suggestion dismiss<CR>", { silent = true, noremap = true })

-- diable sign column for lsp diagnostic
vim.diagnostic.config({
  signs = false
})
map("n", "<leader>q", "<Cmd>lua vim.diagnostic.disable()<CR>", { noremap = true })
map("n", "<leader>w", "<Cmd>lua vim.diagnostic.enable()<CR>", { noremap = true })


map("i", "<c-space>", "<nop>", { silent = true, noremap = true })

-- just not use those keys to navigete
map("n", "<up>", "<nop>", { silent = true, noremap = true })
map("n", "<down>", "<nop>", { silent = true, noremap = true })
map("n", "<left>", "<nop>", { silent = true, noremap = true })
map("n", "<right>", "<nop>", { silent = true, noremap = true })

--do not twitch to begining of the line when type ::
vim.cmd("set cino+=L0kk")
