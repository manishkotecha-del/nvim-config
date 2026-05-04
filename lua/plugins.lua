-- --- Bootstrap lazy.nvim ---
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = "open_default",
        },
        window = {
          mappings = {
            ["l"] = "open",
            ["h"] = "close_node",
          },
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = {},
    },
  },

  -- Surround
  "tpope/vim-surround",

  -- Multiple cursors
  "mg979/vim-visual-multi",

  -- Treesitter (syntax highlighting, code folding, text objects)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "go", "gomod", "gosum", "lua", "vim", "vimdoc", "typescript", "tsx", "javascript",
      })
    end,
  },

  -- Toggle terminal
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        direction = "float",
        float_opts = { border = "rounded" },
        auto_scroll = false,
      })
    end,
  },

  -- Auto-completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
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
    end,
  },

  -- Auto-pair brackets/quotes (must load after cmp to hook confirm_done)
  {
    "windwp/nvim-autopairs",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({ check_ts = true })
      local ok_cmp_ap, cmp_ap = pcall(require, "nvim-autopairs.completion.cmp")
      if ok_cmp_ap then
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp then
          cmp.event:on("confirm_done", cmp_ap.on_confirm_done())
        end
      end
    end,
  },

  -- Git diff viewer
  "sindrets/diffview.nvim",

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- LSP call hierarchy viewer (telescope is here only for telescope-hierarchy)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "jmacadie/telescope-hierarchy.nvim",
    },
    cmd = "Telescope",
    config = function()
      require("telescope").load_extension("hierarchy")
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin",
        },
        sections = {
          lualine_c = { { "filename", path = 2 } },
          lualine_z = { "%l/%L" },
        },
      })
    end,
  },

  -- Colorscheme (variants: catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      pcall(vim.cmd.colorscheme, "catppuccin-mocha")
    end,
  },
})

-- --- Non-plugin keymaps and config ---

vim.keymap.set("n", "<leader>e", "<cmd>Neotree reveal<cr>")

-- Snacks picker
local noise_excludes = { "**/*_test.go", "**/*_mock.go", "**/mock_*", "**/mocks/**", "**/mock/**" }

vim.keymap.set("n", "<leader>ff", function() Snacks.picker.files() end)
vim.keymap.set("n", "<leader>fF", function()
  Snacks.picker.files({ exclude = noise_excludes })
end)
vim.keymap.set("n", "<leader>fs", function() Snacks.picker.buffers() end)
vim.keymap.set("n", "<leader>fg", function() Snacks.picker.grep() end)
vim.keymap.set("n", "<leader>fG", function()
  Snacks.picker.grep({ exclude = noise_excludes })
end)

local function find_in_projects(opts)
  opts = opts or {}
  opts.cwd = vim.fn.expand("~/Projects")
  opts.confirm = function(picker, item)
    picker:close()
    if not item then return end
    local filepath = opts.cwd .. "/" .. item.file
    local dir = vim.fn.fnamemodify(filepath, ":h")
    while dir ~= "/" do
      for _, marker in ipairs({ "go.mod", "go.work", ".git", "package.json", "tsconfig.json", "jsconfig.json" }) do
        if vim.fn.glob(dir .. "/" .. marker) ~= "" then
          vim.cmd("cd " .. vim.fn.fnameescape(dir))
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          pcall(vim.cmd, "Neotree dir=" .. vim.fn.fnameescape(dir))
          return
        end
      end
      dir = vim.fn.fnamemodify(dir, ":h")
    end
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  end
  Snacks.picker.files(opts)
end

vim.keymap.set("n", "<leader>fp", function() find_in_projects() end)
vim.keymap.set("n", "<leader>fP", function()
  find_in_projects({ exclude = noise_excludes })
end)

vim.keymap.set("n", "<leader>ci", "<cmd>Telescope hierarchy incoming_calls<cr>")
vim.keymap.set("n", "<leader>co", "<cmd>Telescope hierarchy outgoing_calls<cr>")

-- Enable treesitter highlighting for supported filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gosum", "lua", "vim", "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
