{ config, pkgs, ... }:

{
  # COSMIC DE
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # GNOME DEPENDENCIES
  environment.systemPackages = with pkgs; [
    gnome-shell-extensions
    gnomeExtensions.appindicator
  ];
}
