{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./dropbox.nix
    ];

  # NIRI, DM, X11 WINDOWING SYSTEM
  programs.niri.enable = true;
  services.displayManager.gdm.enable = true;
  services.xserver.enable = true;

  # NIRI SPECIFIC PKGS
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme   
    blueman
    #dconf-editor
    eog
    gnome-disk-utility
    gnome-software
    gnome-text-editor
    gnome-themes-extra
    mako
    nautilus
    nmgui
    rofi
    sushi
    swaybg
    swayidle
    swaylock
    #thunar
    waybar
    xcursor-themes
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    xwayland-satellite
  ];

  # FLATPAK
  services.flatpak.enable = true;

  # XFCE CONFIG
  #services.gvfs.enable = true; # <- this gives the full feature set for thunar
  #programs.xfconf.enable = true;
  #programs.dconf.enable = true; # <- add this after environment.systemPackages, otherwise it won't be found
  #https://discourse.nixos.org/t/changing-thunar-icon-theme/50178/9

  # DEPENDENCIES
  hardware.bluetooth.enable = true;
  security.polkit.enable = true;
  services.gvfs.enable = true;
  #services.dbus.enable = true; <- probably handeled by NixOS

  # POLKIT AGENT
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
