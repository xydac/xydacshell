-- xydacshell — modern profile init.lua.
-- Small, no plugin manager, sensible defaults.
-- Preserves the classic leader key (backtick) so muscle memory carries over.

-- Leader: backtick (same as classic).
vim.g.mapleader = "`"
vim.g.maplocalleader = "`"

-- Basics.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 250
vim.opt.scrolloff = 8

-- Search ergonomics.
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Pane switching (parity with classic).
vim.keymap.set("n", "<leader><Left>",  "<C-w>h", { silent = true })
vim.keymap.set("n", "<leader><Down>",  "<C-w>j", { silent = true })
vim.keymap.set("n", "<leader><Up>",    "<C-w>k", { silent = true })
vim.keymap.set("n", "<leader><Right>", "<C-w>l", { silent = true })

-- Buffer navigation.
vim.keymap.set("n", "<Tab>",   ":bnext<CR>",     { silent = true })
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", { silent = true })

-- Quick escape.
vim.keymap.set("i", "jk", "<Esc>", { silent = true })

-- Strip trailing whitespace on save.
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Source user customizations if present. Mirrors vimrc.custom from classic.
local custom = vim.fn.expand("$HOME/.xydacshell/nvim.custom.lua")
if vim.fn.filereadable(custom) == 1 then
  dofile(custom)
end
