local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if fn.empty(fn.glob(install_path)) > 0 then
    packer_bootstrap = fn.system({
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/wbthomason/packer.nvim",
        install_path
    })
    vim.cmd [[packadd packer.nvim]]
end


-- TODO Require via pcall
local packer = require("packer")

packer.startup(function(use)
    use "wbthomason/packer.nvim"

    use {
        "sonph/onehalf",
        rtp = "vim",
        -- config = function() vim.cmd("colorscheme onehalfdark") end
        -- config = function() vim.cmd("colorscheme torte") end
    }
    use { "itchyny/lightline.vim" }

    use { "junegunn/fzf", run = ":call fzf#install()" }
    use { "junegunn/fzf.vim" }

    use { "Vimjas/vim-python-pep8-indent" }
    use { "tpope/vim-commentary" }
    use { "sheerun/vim-polyglot" }
    -- use { "davidhalter/jedi-vim" }
    use { "neovim/nvim-lspconfig" }

    use {
        "bluz71/vim-moonfly-colors",
        as = "moonfly",
        config = function() vim.cmd("colorscheme moonfly") end
    }

    use({
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    })

    -- use {
    --   "zbirenbaum/copilot.lua",
    --   cmd = "Copilot",
    --   event = "InsertEnter",
    --   config = function()
    --     require("copilot").setup({
    --       suggestion = {
    --         enabled = true,
    --         auto_trigger = false,
    --         trigger_on_accept = true,
    --         keymap = {
    --           accept = false,
    --           next = false,
    --           prev = false,
    --           dismiss = false,
    --           toggle_auto_trigger = false,
    --         },
    --       },
    --       panel = { enabled = false },
    --       nes = { enabled = false },
    --     })
    --   end,
    -- }

end)
