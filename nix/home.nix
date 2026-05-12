{ config, pkgs, ... }:

let
  symLink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/src/dotfiles/config/${path}";
in

{
  home.username = "nekrofrukt";
  home.homeDirectory = "/home/nekrofrukt";
  home.stateVersion = "25.11";

  imports = [
    ../config/bash/bash.nix
    ../config/nvim/nvim.nix
    ../config/ssh/ssh.nix
    ../config/git/git.nix
  ];
  
  home.packages = with pkgs; [
    _1password-gui
    brave
    btop-rocm
    fastfetch
    ghostty
    obsidian
    ranger
    spotify
    starship
    transmission_4-qt
    vlc

    # Languages
    go
    lua
    python315
    nodejs_25
    typescript

    # Fonts
    #jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-mono
    nerd-fonts.departure-mono
  ];

  home.file = {
    ".config/ghostty/config".source = ../config/ghostty/default;
    ".config/starship.toml".source = ../config/starship/starship.toml;
    ".config/gtk-4.0/gtk.css".source = ../config/gtk-4.0/gtk.css;
    ".config/gtk-4.0/settings.ini".source = ../config/gtk-4.0/settings.ini;
    ".config/mako/config".source = ../config/mako/config;

    # Symlinks
    ".config/fastfetch/config.jsonc".source = symLink "fastfetch/nixos.jsonc";
    ".config/fastfetch/minimal.jsonc".source = symLink "fastfetch/minimal.jsonc";
    ".config/fastfetch/utils.jsonc".source = symLink "fastfetch/utils.jsonc";
    ".config/ghostty/themes/".source = symLink "ghostty/themes/";
    ".config/waybar/config.jsonc".source = symLink "waybar/config.jsonc";
    ".config/waybar/style.css".source = symLink "waybar/style.css";
    ".config/rofi".source = symLink "rofi";
    ".config/niri".source = symLink "niri";
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
