if vim.fn.has("nvim-0.12.0") == 0 then
  error("This configuration requires Neovim 0.12.0 or newer")
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

vim.api.nvim_create_user_command("Term", function()
  vim.cmd("botright 10split | terminal")
end, { desc = "Open terminal in a bottom split" })

vim.api.nvim_create_user_command("DO", "DiffviewOpen <args>", {
  nargs = "*",
  desc = "Open a Git diff view",
})
vim.api.nvim_create_user_command("DC", "DiffviewClose", {
  desc = "Close the Git diff view",
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
local lazy_commit = lock["lazy.nvim"] and lock["lazy.nvim"].commit

if type(lazy_commit) ~= "string" or #lazy_commit ~= 40 or not lazy_commit:match("^[0-9a-f]+$") then
  error("lazy-lock.json does not contain a valid lazy.nvim commit")
end

if not vim.uv.fs_stat(lazypath .. "/lua/lazy/init.lua") then
  error(
    "lazy.nvim is not installed. Run ./setup_nvim.sh from the nvim-config repository "
      .. "to install the locked plugin versions."
  )
end

local current_lazy_commit = vim.fn.system({ "git", "-C", lazypath, "rev-parse", "--verify", "HEAD" })
if vim.v.shell_error ~= 0 or vim.trim(current_lazy_commit) ~= lazy_commit then
  error(
    ("lazy.nvim is not at locked commit %s. Run ./setup_nvim.sh from the nvim-config repository."):format(
      lazy_commit
    )
  )
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  rocks = { enabled = false },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
  install = { colorscheme = { "onedark_dark" } },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
