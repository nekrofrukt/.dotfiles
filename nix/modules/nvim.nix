{ config, pkgs, ... }:

{
  home.file = {
    ".config/nvim/lua/config/lazy.lua".source = ./lazy.lua;
    ".config/nvim/lua/plugins/colors.lua".source = ./plugins/colors.lua;
    ".config/nvim/lua/plugins/telescope.lua".source = ./plugins/telescope.lua;
    #".config/nvim/lua/plugins/lsp.lua".source = ./plugins/lsp.lua;
    #".config/nvim/lua/plugins/treesitter.lua".source = ./plugins/treesitter.lua;
  };

  programs.neovim = {
    enable = true;

    withPython3 = true;
    withRuby = true;

    extraPackages = with pkgs; [
      fzf
      luajitPackages.luarocks
      wl-clipboard

      # Lang servers
      gopls
      javascript-typescript-langserver
      lua-language-server
      nixd
      pyright
    ];

    initLua = ''
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
    '';
  };
}
