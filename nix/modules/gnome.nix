{ config, pkgs, ... }:

{
  # GNOME DESKTOP
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # X11 WINDOWING SYSTEM
  services.xserver.enable = true;

  # FLATPAK
  services.flatpak.enable = true;

  services.gnome.gnome-keyring.enable = true;

  # GNOME SPECIFIC PKGS
  environment.systemPackages = let
    ge = pkgs.gnomeExtensions;
  in with pkgs; [
    gnome-tweaks
    rofi

    # Extensions
    ge.app-menu-is-back
    ge.appindicator
    ge.blur-my-shell
    ge.forge
    ge.just-perfection
    ge.space-bar
    ge.system-monitor
    ge.user-themes
    ge.vicinae
  ];
}
