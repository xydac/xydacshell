-- xydacshell — modern profile init.lua.
-- Small, opinionated Neovim config. Bootstraps lazy.nvim and a curated set
-- of plugins. On first launch, lazy.nvim clones itself and installs everything
-- (~30 MB, takes a minute). Subsequent launches are fast.
--
-- User customizations go in ~/.xydacshell/nvim.custom.lua — never overwritten.

--------------------------------------------------------------------------------
-- Leader keys (set before any plugin loads so their keymaps bind correctly).
--------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

--------------------------------------------------------------------------------
-- Options.
--------------------------------------------------------------------------------
local opt = vim.opt
opt.number         = true
opt.relativenumber = true
opt.mouse          = "a"
opt.autoindent     = true
opt.smartindent    = true
opt.expandtab      = true
opt.shiftwidth     = 2
opt.tabstop        = 2
opt.termguicolors  = true
opt.signcolumn     = "yes"
opt.splitright     = true
opt.splitbelow     = true
opt.ignorecase     = true
opt.smartcase      = true
opt.undofile       = true
opt.clipboard      = "unnamedplus"
opt.updatetime     = 250
opt.scrolloff      = 8
opt.incsearch      = true
opt.hlsearch       = true
opt.cursorline     = true
opt.wrap           = false

--------------------------------------------------------------------------------
-- Core keymaps (leader-agnostic ergonomic moves).
--------------------------------------------------------------------------------
local map = vim.keymap.set

-- Quick escape.
map("i", "jk", "<Esc>", { silent = true, desc = "Escape insert" })

-- Pane switching with Ctrl-hjkl (no leader needed).
map("n", "<C-h>", "<C-w>h", { silent = true, desc = "Window left"  })
map("n", "<C-j>", "<C-w>j", { silent = true, desc = "Window down"  })
map("n", "<C-k>", "<C-w>k", { silent = true, desc = "Window up"    })
map("n", "<C-l>", "<C-w>l", { silent = true, desc = "Window right" })

-- Buffer navigation with Tab.
map("n", "<Tab>",   ":bnext<CR>",     { silent = true, desc = "Next buffer"     })
map("n", "<S-Tab>", ":bprevious<CR>", { silent = true, desc = "Previous buffer" })

-- Clear search highlight.
map("n", "<leader>h", ":nohlsearch<CR>", { silent = true, desc = "Clear highlight" })

-- Save / quit.
map("n", "<leader>w", ":write<CR>", { silent = true, desc = "Save" })
map("n", "<leader>q", ":quit<CR>",  { silent = true, desc = "Quit" })

-- Strip trailing whitespace on save.
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

--------------------------------------------------------------------------------
-- Bootstrap lazy.nvim.
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- Plugins.
--------------------------------------------------------------------------------
require("lazy").setup({
  -- Colorscheme.
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "night" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Tree-sitter: syntax, indent, folding for every language we encounter.
  -- Pinned to `master` — the `main` branch is the in-progress v1 rewrite and
  -- removed the `.configs` module we depend on.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build  = ":TSUpdate",
    event  = { "BufReadPost", "BufNewFile" },
    opts   = {
      auto_install = true,
      highlight    = { enable = true },
      indent       = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- Fuzzy finder — uses the system fzf we install in the tools batch.
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", function() require("fzf-lua").files()      end, desc = "Find files"  },
      { "<leader>fg", function() require("fzf-lua").live_grep()  end, desc = "Live grep"   },
      { "<leader>fb", function() require("fzf-lua").buffers()    end, desc = "Buffers"     },
      { "<leader>fh", function() require("fzf-lua").help_tags()  end, desc = "Help tags"   },
      { "<leader>fr", function() require("fzf-lua").resume()     end, desc = "Resume pick" },
      { "<leader>fk", function() require("fzf-lua").keymaps()    end, desc = "Keymaps"     },
    },
    opts = {},
  },

  -- File explorer — edit a directory as a buffer. Saves like any buffer.
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    keys = {
      { "-",         "<cmd>Oil<cr>", desc = "Open parent directory" },
      { "<leader>e", "<cmd>Oil<cr>", desc = "Open directory"        },
    },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
    },
  },

  -- Statusline.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme                = "tokyonight",
        component_separators = "|",
        section_separators   = "",
        globalstatus         = true,
      },
    },
  },

  -- Leader-key discovery.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts  = { preset = "modern" },
  },

  -- Git gutter + hunks.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
    },
  },

  -- Nerd Font icons (installed by the modern-tools font offer).
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Brackets / quotes auto-close.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts  = {},
  },
}, {
  change_detection = { notify = false },
  install          = { missing = true },
  ui               = { border = "rounded" },
})

--------------------------------------------------------------------------------
-- User customizations — sacred, never overwritten by the installer.
--------------------------------------------------------------------------------
local custom = vim.fn.expand("$HOME/.xydacshell/nvim.custom.lua")
if vim.fn.filereadable(custom) == 1 then
  dofile(custom)
end
