-- HM file for non-Nix systems
require("config.lazy")

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true

vim.g.mapleader = " "
vim.keymap.set("n", "<leader>cd", vim.cmd.Ex)
