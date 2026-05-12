{ config, pkgs, inputs, ... }:

{
  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Home-Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = { inherit inputs; };

    users = {
      "nekrofrukt" = import ../home.nix;
    };
  };

  # Tailscale
  services.tailscale.enable = true;

  # Swapfile
  swapDevices = [ {
    device = "/swapfile";
    size = 4096;
  } ];

  # System generations limit in boot loader
  boot.loader.systemd-boot.configurationLimit = 5;

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    dates = [ "monthly" ];
    options = "--delete-older-than 14d";
  };
}
