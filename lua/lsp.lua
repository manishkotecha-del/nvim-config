-- --- LSP server configs (vim.lsp.config, Neovim 0.11+) ---

-- Go (gopls)
-- Install: go install golang.org/x/tools/gopls@latest
-- Extend LSP capabilities with completion support
local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
local capabilities = ok_cmp_lsp and cmp_lsp.default_capabilities() or nil

vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
  capabilities = capabilities,
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

vim.lsp.enable("gopls")

-- TypeScript / JavaScript (ts_ls)
-- Install: npm install -g typescript typescript-language-server
vim.lsp.config("ts_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  capabilities = capabilities,
})

vim.lsp.enable("ts_ls")

-- Hover popup settings
vim.o.winborder = "rounded"
vim.diagnostic.config({ float = { border = "rounded" } })

-- --- LSP keymaps (set when a client attaches to a buffer) ---
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
    vim.keymap.set("n", "grr", "<cmd>Telescope lsp_references<cr>", opts)
    vim.keymap.set("n", "gri", "<cmd>Telescope lsp_implementations<cr>", opts)
    vim.keymap.set("n", "grt", "<cmd>Telescope lsp_type_definitions<cr>", opts)
    vim.keymap.set("n", "<leader>grr", function()
      require("telescope.builtin").lsp_references({
        file_ignore_patterns = { "_test%.go$", "_mock%.go$", "/mock_", "/mocks/", "/mock/" },
      })
    end, opts)
    vim.keymap.set("n", "<leader>gri", function()
      require("telescope.builtin").lsp_implementations({
        file_ignore_patterns = { "_test%.go$", "_mock%.go$", "/mock_", "/mocks/", "/mock/" },
      })
    end, opts)
    vim.keymap.set("n", "<leader>id", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>ie", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "<leader>ge", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
  end,
})

-- --- Format on save (goimports via gopls) ---
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local client = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })[1]
    if not client then return end

    -- Organize imports
    local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
        end
      end
    end

    -- Format
    vim.lsp.buf.format({ async = false })
  end,
})
