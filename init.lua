-- --- General settings ---
vim.o.showmode = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.number = true
vim.o.cursorline = true
vim.o.scrolloff = 5
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
      vim.cmd("silent! write")
    end
  end,
})

vim.g.mapleader = " "

vim.o.title = true
vim.o.titlestring = "%{fnamemodify(getcwd(), ':t')}"

-- --- Pure vim mappings (from .ideavimrc) ---
vim.keymap.set("n", "U", "<C-r>")
vim.keymap.set("n", "Y", "y$")
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set({ "n", "v", "x" }, "J", "5j")
vim.keymap.set({ "n", "v", "x" }, "K", "5k")
vim.keymap.set({ "n", "v" }, "<leader>p", '"0p')
vim.keymap.set({ "n", "v" }, "<leader>P", '"0P')
vim.keymap.set("v", "y", "ygv<Esc>")
vim.keymap.set("v", "<leader>c", '"+y')

-- --- Diffview ---
vim.keymap.set("n", "<leader>dv", "<cmd>DiffviewOpen<cr>")
vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>")
vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory %<cr>")

-- --- LSP mappings (set on attach, see lua/lsp.lua) ---

-- --- Terminal ---
vim.keymap.set({"n", "t"}, "<leader>gt", "<cmd>ToggleTerm<cr>")
vim.keymap.set("n", "<leader>gg", function()
  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new({
    cmd = "lazygit",
    hidden = true,
    direction = "float",
    float_opts = { width = vim.o.columns, height = vim.o.lines, border = "none" },
  })
  lazygit:toggle()
end)

-- --- Debugger (requires nvim-dap plugin) ---
-- vim.keymap.set("n", "<leader>b", function() require("dap").toggle_breakpoint() end)
-- vim.keymap.set("n", "<leader>d", function() require("dap").continue() end)

-- --- Load modules ---
require("plugins")
require("lsp")
