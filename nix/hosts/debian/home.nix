{ config, pkgs, ... }:

let
  symLink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/dotfiles/config/${path}";
in

{
  home.username = "nekrofrukt";
  home.homeDirectory = "/home/nekrofrukt";
  home.stateVersion = "25.11";

  imports = [
    ~/src/dotfiles/config/nvim/nvim.nix
    ~/src/dotfiles/config/ssh/ssh.nix
    ~/src/dotfiles/config/git/git.nix
  ];

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-mono
  ];

  home.file = {
    ".bashrc".source = ~/src/dotfiles/config/bash/bashrc_debian;
    ".config/ghostty/config".source = ~/src/dotfiles/config/ghostty/default;
    ".config/starship.toml".source = ~/src/dotfiles/config/starship/starship.toml;
    ".config/gtk-4.0/gtk.css".source = ~/src/dotfiles/config/gtk-4.0/gtk.css;
    ".config/gtk-4.0/settings.ini".source = ~/src/dotfiles/config/gtk-4.0/settings.ini;

    # Symlinks
    ".config/fastfetch/config.jsonc".source = symLink "fastfetch/debian.jsonc";
    ".config/fastfetch/minimal.jsonc".source = symLink "fastfetch/minimal.jsonc";
    ".config/fastfetch/utils.jsonc".source = symLink "fastfetch/utils.jsonc";
    ".config/ghostty/themes/".source = symLink "ghostty/themes/";
    ".config/sway/".source = symLink "sway/";
    ".config/rofi/".source = symLink "rofi/";
    ".config/waybar/".source = symLink "waybar/";
    ".config/mako/".source = symLink "mako/";
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nekrofrukt/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
