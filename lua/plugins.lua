-- --- Plugin list (vim-plug) ---
-- To install vim-plug:
--   curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
--     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
-- Then run :PlugInstall in Neovim

local Plug = vim.fn["plug#"]
vim.fn["plug#begin"]("~/.local/share/nvim/plugged")

-- File explorer
Plug("preservim/nerdtree")

-- Fuzzy finder
Plug("nvim-lua/plenary.nvim")
Plug("nvim-telescope/telescope.nvim")
Plug("nvim-telescope/telescope-fzf-native.nvim", { ["do"] = "make" })

-- Surround
Plug("tpope/vim-surround")

-- Highlighted yank
Plug("machakann/vim-highlightedyank")

-- Multiple cursors
Plug("mg979/vim-visual-multi")

-- Treesitter (syntax highlighting, code folding, text objects)
Plug("nvim-treesitter/nvim-treesitter", { ["do"] = ":TSUpdate" })

-- Toggle terminal
Plug("akinsho/toggleterm.nvim")

-- Auto-completion
Plug("hrsh7th/nvim-cmp")
Plug("hrsh7th/cmp-nvim-lsp")
Plug("hrsh7th/cmp-buffer")
Plug("hrsh7th/cmp-path")
Plug("L3MON4D3/LuaSnip")
Plug("saadparwaiz1/cmp_luasnip")

-- Git diff viewer
Plug("sindrets/diffview.nvim")

-- Git signs in gutter
Plug("lewis6991/gitsigns.nvim")

-- Statusline
Plug("nvim-lualine/lualine.nvim")
Plug("nvim-tree/nvim-web-devicons")

-- Colorscheme
Plug("catppuccin/nvim", { ["as"] = "catppuccin" })

vim.fn["plug#end"]()

-- --- Plugin config ---

-- Highlighted yank
vim.g.highlightedyank_highlight_duration = 100

-- NERDTree
vim.g.NERDTreeMapActivateNode = "l"
vim.g.NERDTreeMapJumpParent = "h"
vim.keymap.set("n", "<leader>e", "<cmd>NERDTreeFind<cr>")

-- Telescope
local ok_telescope, telescope = pcall(require, "telescope")
if ok_telescope then
  telescope.load_extension("fzf")
end

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
vim.keymap.set("n", "<leader>fs", "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>fp", function()
  require("telescope.builtin").find_files({
    cwd = vim.fn.expand("~/Projects"),
    attach_mappings = function(_, map)
      map("i", "<cr>", function(prompt_bufnr)
        local entry = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
        require("telescope.actions").close(prompt_bufnr)
        local filepath = vim.fn.expand("~/Projects") .. "/" .. entry[1]
        -- Find project root (nearest dir with go.mod, go.work, or .git)
        local dir = vim.fn.fnamemodify(filepath, ":h")
        while dir ~= "/" do
          for _, marker in ipairs({ "go.mod", "go.work", ".git" }) do
            if vim.fn.glob(dir .. "/" .. marker) ~= "" then
              vim.cmd("cd " .. vim.fn.fnameescape(dir))
              vim.cmd("edit " .. vim.fn.fnameescape(filepath))
              pcall(vim.cmd, "NERDTreeCWD")
              return
            end
          end
          dir = vim.fn.fnamemodify(dir, ":h")
        end
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
      end)
      return true
    end,
  })
end)

-- Toggleterm
local ok_tt, toggleterm = pcall(require, "toggleterm")
if ok_tt then
  toggleterm.setup({
    direction = "float",
    float_opts = { border = "rounded" },
  })
end

-- Auto-completion
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  local luasnip = require("luasnip")
  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "luasnip" },
    }, {
      { name = "buffer" },
      { name = "path" },
    }),
  })
end

-- Gitsigns
local ok_gs, gitsigns = pcall(require, "gitsigns")
if ok_gs then
  gitsigns.setup()
end

-- Lualine
local ok_ll, lualine = pcall(require, "lualine")
if ok_ll then
  lualine.setup({
    options = {
      theme = "catppuccin",
    },
    sections = {
      lualine_c = { { "filename", path = 2 } },
      lualine_z = { "%l/%L" },
    },
  })
end

-- Catppuccin (variants: catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha)
pcall(vim.cmd.colorscheme, "catppuccin-mocha")

-- Treesitter
local ok_ts, ts_config = pcall(require, "nvim-treesitter.config")
if ok_ts then
  ts_config.setup({
    ensure_installed = { "go", "gomod", "gosum", "lua", "vim", "vimdoc" },
  })
end

-- Enable treesitter highlighting for supported filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gosum", "lua", "vim" },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
